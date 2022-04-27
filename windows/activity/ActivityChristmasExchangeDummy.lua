local ActivityChristmasExchangeDummy = class("ActivityChristmasExchangeDummy", import(".ActivityContent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")
local HeroIcon = import("app.components.HeroIcon")
local BuyItemClass = class("buyItemClass", import("app.components.CopyComponent"))
local ExchangeItemClass = class("ExchangeItemClass", import("app.components.CopyComponent"))

function ExchangeItemClass:ctor(go, parent)
	self.parent_ = parent

	ExchangeItemClass.super.ctor(self, go)

	self.canExchange = false
end

function ExchangeItemClass:initUI()
	local goTrans = self.go.transform
	self.costButterNum_ = goTrans:ComponentByName("costButterNum", typeof(UILabel))
	self.exchangeBtn_ = goTrans:NodeByName("exchangeBtn").gameObject
	self.exchangeBtnLabel_ = goTrans:ComponentByName("exchangeBtn/label", typeof(UILabel))
	self.inputTouch_ = goTrans:NodeByName("inputRoot/touchGroup").gameObject
	self.plusImg_ = goTrans:NodeByName("inputRoot/plusImg").gameObject
	self.inputNumLabel_ = goTrans:ComponentByName("inputRoot/labelNum", typeof(UILabel))
	self.iconContainer_ = goTrans:NodeByName("inputRoot/iconContainer").gameObject
	self.redPoint_ = goTrans:NodeByName("inputRoot/redPointImg").gameObject
	self.iconContainer2_ = goTrans:NodeByName("iconContainer2").gameObject
	UIEventListener.Get(self.exchangeBtn_).onClick = handler(self, self.onTouchExchange)
	UIEventListener.Get(self.inputTouch_).onClick = handler(self, self.onTouchInput)
	self.exchangeBtnLabel_.text = __("ACTIVITY_DOLL_EXCHANGE_BUTTON")
end

function ExchangeItemClass:onTouchExchange()
	if self.canExchange and self.butterOk_ then
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_DOLL_EXCHANGE_TIPS"), function (yes)
			if yes then
				local msg = messages_pb.activity_christmas_exchange_req()
				msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY

				table.insert(msg.partner_ids, self.materialList[1].partnerID)
				xyd.Backend.get():request(xyd.mid.ACTIVITY_CHRISTMAS_EXCHANGE, msg)

				self.parent_.exchangeShowID = self.showID
				self.parent_.removePartnerID = self.materialList[1].partnerID
				self.materialList = {}
			end
		end)
	else
		xyd.alertTips(__("SHELTER_NOT_ENOUGH_MATERIAL"))
	end
end

function ExchangeItemClass:onTouchInput()
	self.tempMaterialList = {}
	self.tempOptionalList = {}

	for i = 1, #self.materialList do
		table.insert(self.tempMaterialList, self.materialList[i])
	end

	for i = 1, #self.optionalList do
		table.insert(self.tempOptionalList, self.optionalList[i])
	end

	local windowParams = {
		needNum = 1,
		noDebris = true,
		confirmCallback = function (optionalList, materialList)
			self:confirmCallback(optionalList, materialList)
		end,
		selectCallback = function ()
		end,
		optionalList = self.tempOptionalList,
		materialList = self.tempMaterialList
	}

	xyd.WindowManager.get():openWindow("activity_shelter_mission_select_window", windowParams)
end

function ExchangeItemClass:confirmCallback(optionalList, materialList)
	self.optionalList = {}
	self.materialList = {}

	for i = 1, #optionalList do
		table.insert(self.optionalList, optionalList[i])
	end

	for i = 1, #materialList do
		table.insert(self.materialList, materialList[i])
	end

	self.inputNumLabel_.text = #self.materialList .. "/1"

	if #self.materialList >= 1 then
		self.container1:setInfo({
			scale = 0.7037037037037037,
			tableID = self.materialList[1].tableID,
			star = self.star_
		})
		self.container1:showGroup()
		self.container1:setOrigin()

		local needTableID = tostring(self.materialList[1].tableID) .. tostring(self.materialList[1].awake)
		needTableID = tonumber(needTableID)
		local getId = xyd.tables.activityExchangeDummyExchangeTable:getAward(needTableID)[1]

		self.container2:setInfo({
			num = 50,
			scale = 0.7962962962962963,
			noClick = false,
			itemID = getId
		})
		self.container2:showGroup()
		self.container2:setOrigin()

		self.canExchange = true
		self.inputNumLabel_.color = Color.New2(1583978239)

		self.plusImg_:SetActive(false)
		self.redPoint_:SetActive(false)
	else
		self.inputNumLabel_.color = Color.New2(3360838399.0)

		self.container1:setInfo({
			scale = 0.7037037037037037,
			tableID = self.simpleTableID,
			star = self.star_
		})
		self.container1:setGrey()
		self.container1:removeGroup()
		self.container2:setInfo({
			scale = 0.7962962962962963,
			noClick = true,
			num = 50,
			itemID = self.simpleTableID,
			star = self.star_
		})
		self.container2:setGrey()
		self.container2:showDebris()
		self.container2:removeGroup()

		self.canExchange = false

		self.plusImg_:SetActive(true)
		self:updateRedPoint()
	end
end

function ExchangeItemClass:setInfo(params)
	self.showID = params.showID

	if self.showID == 1 then
		self.simpleTableID = 765001
		self.star_ = 10
	elseif self.showID == 2 then
		self.simpleTableID = 665001
		self.star_ = 9
	else
		self.simpleTableID = 665001
		self.star_ = 6
	end

	self.idList = {}

	for _, id in ipairs(params.idList) do
		self.idList[id] = true
	end

	self.cost = params.cost
	self.optionalList = {}
	self.materialList = {}

	self:initOptionalList()
	self:layout()
end

function ExchangeItemClass:initOptionalList()
	local puppetList = xyd.models.slot:getPuppetPartner()

	for _, partnerId in ipairs(puppetList) do
		local partnerInfo = xyd.models.slot:getPartner(partnerId)

		if partnerInfo then
			local needTableID = tostring(partnerInfo.tableID) .. tostring(partnerInfo.awake)
			needTableID = tonumber(needTableID)

			if self.idList[needTableID] then
				table.insert(self.optionalList, partnerInfo)
			end
		end
	end

	self:updateRedPoint()
end

function ExchangeItemClass:layout()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.DUMMY_BUTTERFLY) < self.cost[2] then
		self.costButterNum_.color = Color.New2(3360838399.0)
		self.butterOk_ = false
	else
		self.costButterNum_.color = Color.New2(1583978239)
		self.butterOk_ = true
	end

	self.costButterNum_.text = self.cost[2]
	self.inputNumLabel_.text = "0/1"
	self.inputNumLabel_.color = Color.New2(3360838399.0)

	if not self.container2 then
		self.container2 = HeroIcon.new(self.iconContainer2_)
	end

	self.container2:setInfo({
		scale = 0.7962962962962963,
		noClick = true,
		num = 50,
		itemID = self.simpleTableID,
		star = self.star_
	})
	self.container2:showDebris()
	self.container2:removeGroup()
	self.container2:setGrey()

	if not self.container1 then
		self.container1 = HeroIcon.new(self.iconContainer_)
	end

	self.container1:setInfo({
		scale = 0.7037037037037037,
		tableID = self.simpleTableID,
		star = self.star_
	})
	self.container1:removeGroup()
	self.container1:setGrey()
	self.plusImg_:SetActive(true)
end

function ExchangeItemClass:updateButterNum()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.DUMMY_BUTTERFLY) < self.cost[2] then
		self.costButterNum_.color = Color.New2(3360838399.0)
		self.butterOk_ = false
	else
		self.costButterNum_.color = Color.New2(1583978239)
		self.butterOk_ = true
	end
end

function ExchangeItemClass:updateRedPoint()
	self.redPoint_:SetActive(#self.optionalList >= 1)
end

function BuyItemClass:ctor(go, parent)
	self.parent_ = parent

	BuyItemClass.super.ctor(self, go)
	self.go:SetActive(false)
end

function BuyItemClass:initUI()
	BuyItemClass.super.initUI(self)

	local goTrans = self.go.transform
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnNum_ = goTrans:ComponentByName("buyBtn/costNum", typeof(UILabel))
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/tipsLabel", typeof(UILabel))
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.mask_ = goTrans:NodeByName("buyBtn/mask").gameObject
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onClickBuy)

	if xyd.Global.lang then
		self.buyBtnLabel_.width = 80
	end
end

function BuyItemClass:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.id = info.id
	self.buyTimes = info.buyTimes
	self.index = info.index
	self.limitTime = info.limit
	self.cost = xyd.tables.activityExchangeDummyBuyTable:getCost(self.id)
	self.award = xyd.tables.activityExchangeDummyBuyTable:getAward(self.id)

	self:layout()
end

function BuyItemClass:layout()
	local limitTime = self.limitTime
	self.leftTime = limitTime - self.buyTimes

	if limitTime > 0 then
		if self.leftTime <= 0 then
			self.leftTime = limitTime - self.buyTimes

			xyd.applyChildrenGrey(self.buyBtn_)
			self.mask_:SetActive(true)

			self.leftTime = 0
		else
			xyd.applyChildrenOrigin(self.buyBtn_)
			self.mask_:SetActive(false)
		end

		self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.leftTime)
	else
		self.limitLabel_.text = __("ACTIVITY_DOLL_BUY_UNLIMIT")

		self.mask_:SetActive(false)
	end

	self.buyBtnLabel_.text = __("BUY2")
	self.buyBtnNum_.text = self.cost[2]
	local params = {
		scale = 0.9074074074074074,
		uiRoot = self.itemRoot_,
		itemID = self.award[1],
		num = self.award[2],
		dragScrollView = self.parent_.gropuBuyScrollView_
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	else
		self.itemIcon_:setInfo(params)
	end
end

function BuyItemClass:onClickBuy()
	local isBatch = xyd.tables.activityExchangeDummyBuyTable:getIsBatch(self.id)

	if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1])))
	elseif not isBatch or isBatch ~= 1 then
		local timeStamp = xyd.db.misc:getValue("dummy_exchange_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "dummy_exchange",
				callback = function (yes)
					local data = require("cjson").encode({
						num = 1,
						award_id = self.index
					})
					local msg = messages_pb.get_activity_award_req()
					msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY
					msg.params = data

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

					self.parent_.onBuyIndex = self.index
					self.parent_.onButNum = 1
				end
			})
		else
			local data = require("cjson").encode({
				num = 1,
				award_id = self.index
			})
			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

			self.parent_.onBuyIndex = self.index
			self.parent_.onButNum = 1
		end
	else
		local params = {
			notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
			hasMaxMin = true,
			titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
			buyType = self.award[1],
			buyNum = self.award[2],
			costType = self.cost[1],
			costNum = self.cost[2]
		}

		function params.purchaseCallback(_, num)
			local timeStamp = xyd.db.misc:getValue("dummy_exchange_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "dummy_exchange",
					callback = function (yes)
						local data = require("cjson").encode({
							award_id = self.index,
							num = num
						})
						local msg = messages_pb.get_activity_award_req()
						msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY
						msg.params = data

						xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

						self.parent_.onBuyIndex = self.index
						self.parent_.onButNum = num
					end
				})
			else
				local data = require("cjson").encode({
					award_id = self.index,
					num = num
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.EXCHANGE_DUMMY
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				self.parent_.onBuyIndex = self.index
				self.parent_.onButNum = num
			end
		end

		params.limitNum = math.floor(xyd.models.backpack:getItemNumByID(self.cost[1]) / self.cost[2])
		params.eventType = xyd.event.GET_ACTIVITY_AWARD

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function ActivityChristmasExchangeDummy:ctor(parentGO, params, parent)
	ActivityChristmasExchangeDummy.super.ctor(self, parentGO, params, parent)
end

function ActivityChristmasExchangeDummy:getPrefabPath()
	return "Prefabs/Windows/activity/activity_christmas_exchange_dummy"
end

function ActivityChristmasExchangeDummy:initUI()
	ActivityChristmasExchangeDummy.super.initUI(self)
	self:getUIComponent()
	self:updatePos()
	self:initNav()
	self:updateCost()
	self:layout()
	self:register()
end

function ActivityChristmasExchangeDummy:layout()
	self.btnMakeLabel_.text = __("ACTIVITY_DOLL_MAKE_TITLE")

	xyd.setUITextureByNameAsync(self.logoImg_, "activity_dummy_exchange_logo_" .. xyd.Global.lang)
end

function ActivityChristmasExchangeDummy:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_DOLL_HELP"
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ACTIVITY_CHRISTMAS_EXCHANGE, handler(self, self.onExchange))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateCost))

	UIEventListener.Get(self.btnMakeIcon_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_christmas_make_butterfly_window", {})
	end
end

function ActivityChristmasExchangeDummy:updateCost()
	self.costItemNum_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DUMMY_BUTTERFLY)
end

function ActivityChristmasExchangeDummy:getUIComponent()
	local goTrans = self.go.transform
	self.bgImg_ = goTrans:NodeByName("bg").gameObject
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UITexture))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.costItemNum_ = goTrans:ComponentByName("bottomGroup/costGroup/costNum", typeof(UILabel))
	self.costItem_ = goTrans:NodeByName("bottomGroup/costGroup").gameObject
	self.btnMakeIcon_ = goTrans:NodeByName("btnMakeIcon").gameObject
	self.btnMakeLabel_ = goTrans:ComponentByName("btnMakeIcon/label", typeof(UILabel))
	self.navRoot_ = goTrans:NodeByName("bottomGroup/nav").gameObject
	self.groupBuy_ = goTrans:NodeByName("bottomGroup/groupBuy").gameObject
	local simpleBuyItem = goTrans:NodeByName("buy_simple_item").gameObject

	simpleBuyItem:SetActive(false)

	self.groupBuyWarp_ = goTrans:ComponentByName("bottomGroup/groupBuy/warpContent", typeof(MultiRowWrapContent))
	self.gropuBuyScrollView_ = self.groupBuy_:GetComponent(typeof(UIScrollView))
	self.wrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.gropuBuyScrollView_, self.groupBuyWarp_, simpleBuyItem, BuyItemClass, self)
	self.groupExhchange_ = goTrans:NodeByName("bottomGroup/groupExchange").gameObject

	for i = 1, 3 do
		self["exchangeItemRoot" .. i] = self.groupExhchange_:NodeByName("exchangeItem" .. i).gameObject
	end
end

function ActivityChristmasExchangeDummy:updatePos()
	local p_height = self.go:GetComponent(typeof(UIWidget)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	self.bgImg_.transform:Y(60 - 0.33707865168539325 * (p_height - 869))
	self.logoImg_.transform:Y(0 - 0.16853932584269662 * (p_height - 869))
	self.costItem_.transform:Y(553 + 0.25280898876404495 * (p_height - 869))
	self.btnMakeIcon_.transform:Y(-0.4606741573033708 * (p_height - 869) - 259)
end

function ActivityChristmasExchangeDummy:initNav()
	local index = 2
	local labelStates = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.navRoot_, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)

	self.tab:setTexts({
		__("ACTIVITY_DOLL_BUY"),
		__("ACTIVITY_DOLL_EXCHANGE_TITLE")
	})
	self.tab:setTabActive(1, true)
end

function ActivityChristmasExchangeDummy:updateNav(index)
	if index == 2 then
		self:initExchangeItems()
	else
		self:updateBuyItems()
	end

	self.groupBuy_:SetActive(index == 1)
	self.groupExhchange_:SetActive(index == 2)
end

function ActivityChristmasExchangeDummy:updateBuyItems()
	local keepPosition = true

	if not self.buyItems_ then
		self:sortBuyItems()

		keepPosition = false

		self.wrap_:setInfos(self.buyItems_, {
			keepPosition = keepPosition
		})
		self.gropuBuyScrollView_:ResetPosition()
	else
		self.wrap_:setInfos(self.buyItems_, {
			keepPosition = keepPosition
		})
	end
end

function ActivityChristmasExchangeDummy:sortBuyItems()
	local buyTimes = self.activityData.detail.buy_times
	self.buyItems_ = {}
	local ids = xyd.tables.activityExchangeDummyBuyTable:getIDs()

	for idx, id in ipairs(ids) do
		local limit = xyd.tables.activityExchangeDummyBuyTable:getLimit(id)

		table.insert(self.buyItems_, {
			id = id,
			buyTimes = buyTimes[idx],
			index = idx,
			limit = limit
		})
	end

	table.sort(self.buyItems_, function (infoA, infoB)
		local leftTimeA = infoA.limit - infoA.buyTimes
		local leftTimeB = infoB.limit - infoB.buyTimes
		local weightA = infoA.id
		local weightB = infoB.id

		if leftTimeB == 0 and infoB.limit ~= 0 then
			weightB = weightB + 100
		end

		if leftTimeA == 0 and infoA.limit ~= 0 then
			weightA = weightA + 100
		end

		return weightB > weightA
	end)
end

function ActivityChristmasExchangeDummy:initExchangeItems()
	local idlistByShow = xyd.tables.activityExchangeDummyExchangeTable:getShowIds()

	for i = 1, 3 do
		if not self["exchangeItem" .. i] then
			local exchangeItem = ExchangeItemClass.new(self["exchangeItemRoot" .. i], self)
			self["exchangeItem" .. i] = exchangeItem
			local params = {
				showID = i,
				idList = idlistByShow[i],
				cost = xyd.tables.activityExchangeDummyExchangeTable:getCostByShow(i)
			}

			exchangeItem:setInfo(params)
		end
	end
end

function ActivityChristmasExchangeDummy:onGetAward(event)
	if self.onBuyIndex and self.onButNum then
		self.activityData.detail.buy_times[self.onBuyIndex] = self.activityData.detail.buy_times[self.onBuyIndex] + self.onButNum

		for _, info in ipairs(self.buyItems_) do
			if info.index == self.onBuyIndex then
				info.buyTimes = info.buyTimes + self.onButNum
			end
		end

		local award = xyd.tables.activityExchangeDummyBuyTable:getAward(self.onBuyIndex)
		local items = {}

		table.insert(items, {
			item_id = award[1],
			item_num = award[2] * self.onButNum
		})
		xyd.models.itemFloatModel:pushNewItems(items)

		self.onBuyIndex = nil
		self.onButNum = nil

		self:updateBuyItems()
	end

	self:updateCost()
end

function ActivityChristmasExchangeDummy:onExchange(event)
	local items = event.data.items

	xyd.models.itemFloatModel:pushNewItems(items)

	for i = 1, 3 do
		if self.exchangeShowID and i == self.exchangeShowID then
			self["exchangeItem" .. self.exchangeShowID]:layout()
			self["exchangeItem" .. self.exchangeShowID]:updateRedPoint()

			self.exchangeShowID = nil
		elseif self["exchangeItem" .. i] then
			self["exchangeItem" .. i]:updateButterNum()
		end
	end

	if self.removePartnerID then
		xyd.models.slot:delPartners({
			self.removePartnerID
		})

		self.removePartnerID = nil
	end

	self:updateCost()
end

return ActivityChristmasExchangeDummy
