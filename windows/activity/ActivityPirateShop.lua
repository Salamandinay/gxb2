local ActivityPirateShop = class("ActivityPirateShop", import(".ActivityContent"))
local cjson = require("cjson")
local PirateShopItem = class("PirateShopItem", import("app.components.CopyComponent"))
local PirateSingleItem = class("PirateShopItem", import("app.components.CopyComponent"))

function PirateShopItem:ctor(go, parent)
	self.parent_ = parent
	self.shopItemList_ = {}

	PirateShopItem.super.ctor(self, go)
end

function PirateShopItem:initUI()
	PirateShopItem.super.initUI(self)
	self:getUIComponent()
end

function PirateShopItem:getUIComponent()
	local goTrans = self.go.transform
	self.goWidget = self.go:GetComponent(typeof(UIWidget))
	self.titleLayout = goTrans:ComponentByName("titleBg", typeof(UILayout))
	self.label1 = goTrans:ComponentByName("titleBg/label1", typeof(UILabel))
	self.label2 = goTrans:ComponentByName("titleBg/label2", typeof(UILabel))
	self.shopItemGrid = goTrans:ComponentByName("shopItemGrid", typeof(UIGrid))
	self.shopItem = goTrans:NodeByName("shopItem").gameObject
end

function PirateShopItem:setInfo(ids, unLockValue, buy_times, unlock_item_times, index)
	self.label1.text = __("ACTIVITY_PIRATE_BOX" .. index)

	if unlock_item_times < unLockValue then
		self.label2.gameObject:SetActive(true)

		self.label2.text = __("ACTIVITY_PIRATE_SHOP_TEXT06", unlock_item_times, unLockValue)
	else
		self.label2.gameObject:SetActive(false)
	end

	self.titleLayout:Reposition()
	table.sort(ids)

	self.index_ = index

	for idx, id in ipairs(ids) do
		if not self.shopItemList_[idx] then
			local newRoot = NGUITools.AddChild(self.shopItemGrid.gameObject, self.shopItem)

			newRoot:SetActive(true)

			self.shopItemList_[idx] = PirateSingleItem.new(newRoot, self)
		end

		self.shopItemList_[idx]:setInfo(id, buy_times[id], unLockValue <= unlock_item_times)
	end

	self.shopItemGrid:Reposition()

	self.goWidget.height = math.floor((#ids + 1) / 3) * 210 + 44
end

function PirateSingleItem:ctor(go, parent)
	self.parent_ = parent

	PirateSingleItem.super.ctor(self, go)
end

function PirateSingleItem:initUI()
	PirateSingleItem.super.initUI(self)
	self:getUIComponent()
end

function PirateSingleItem:getUIComponent()
	local goTrans = self.go.transform
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.overBtn_ = goTrans:NodeByName("overBtn").gameObject
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.overBtnLabel_ = goTrans:ComponentByName("overBtn/label", typeof(UILabel))
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.itemRoot = goTrans:NodeByName("itemRoot").gameObject
	self.lockImg = goTrans:NodeByName("lockImg").gameObject
	self.lockLabel = goTrans:ComponentByName("lockImg/lockLabel", typeof(UILabel))
	self.lockLabel.text = __("DATES_TEXT15")
	self.buyBtnLabel_.text = __("BUY")
	self.overBtnLabel_.text = __("MIDAS_TEXT08")
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onClickBuy)
end

function PirateSingleItem:setInfo(id, buy_times, is_unLock)
	if not is_unLock then
		self.lockImg:SetActive(true)
	else
		self.lockImg:SetActive(false)
	end

	self.buy_times_ = buy_times
	self.id_ = id
	local awardItem = xyd.tables.activityPirateShopAwardTable:getAward(id)
	local cost = xyd.tables.activityPirateShopAwardTable:getCost(id)
	local limit = xyd.tables.activityPirateShopAwardTable:getLimit(id)

	if limit <= buy_times then
		self.overBtn_:SetActive(true)
		self.buyBtn_:SetActive(false)
		self.limitLabel_.gameObject:SetActive(false)
	else
		self.buyBtn_:SetActive(true)
		self.overBtn_:SetActive(false)

		self.overBtnLabel_.text = __("MIDAS_TEXT08")
		self.buyBtnLabel_.text = cost[2]
		self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", limit - buy_times)
	end

	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			scale = 0.7777777777777778,
			uiRoot = self.itemRoot,
			itemID = awardItem[1],
			num = awardItem[2],
			dragScrollView = self.parent_.parent_.shopScrollView_
		})
	else
		self.itemIcon:setInfo({
			scale = 0.7777777777777778,
			uiRoot = self.itemRoot,
			itemID = awardItem[1],
			num = awardItem[2],
			dragScrollView = self.parent_.parent_.shopScrollView_
		})
	end
end

function PirateSingleItem:onClickBuy()
	local cost = xyd.tables.activityPirateShopAwardTable:getCost(self.id_)
	local limit = xyd.tables.activityPirateShopAwardTable:getLimit(self.id_)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	local max_num = math.min(limit - self.buy_times_, math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]))
	local award = xyd.tables.activityPirateShopAwardTable:getAward(self.id_)

	xyd.WindowManager.get():openWindow("item_buy_window", {
		hide_min_max = false,
		item_no_click = false,
		cost = cost,
		max_num = max_num,
		itemParams = {
			itemID = award[1],
			num = award[2]
		},
		buyCallback = function (num)
			if self.parent_.parent_.activityData:getEndTime() <= xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			local allNeedNum = cost[2] * num
			local timeStamp = xyd.db.misc:getValue("pirate_shop_time_stamp")

			local function buyFunction()
				local params = cjson.encode({
					award_id = self.id_,
					num = num
				})
				self.parent_.parent_.tempItem = {
					item_id = self.id_,
					award_num = num
				}

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE_SHOP, params)
			end

			if not timeStamp or not xyd.isSameDay(timeStamp, xyd.getServerTime()) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "pirate_shop",
					callback = buyFunction,
					text = __("ACTIVITY_PIRATE_SHOP_TEXT04", allNeedNum)
				})
			else
				buyFunction()
			end
		end,
		maxCallback = function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))
		end
	})
end

function ActivityPirateShop:ctor(parentGO, params)
	dump(params, "params")

	self.curSelect_ = params.nav_num or 1
	self.missionItems_ = {}
	self.shopItems_ = {}

	ActivityPirateShop.super.ctor(self, parentGO, params)
end

function ActivityPirateShop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_pirate_shop"
end

function ActivityPirateShop:initUI()
	ActivityPirateShop.super.initUI(self)

	if self.activityData and self.activityData.select and self.activityData.select > 0 then
		self.curSelect_ = self.activityData.select
		self.activityData.detail.select = nil
	end

	self:getUIComponent()
	self:register()
	self:updateNav()
	self:updateContent()
	self:updateRed()
end

function ActivityPirateShop:register()
	UIEventListener.Get(self.nav1_).onClick = function ()
		self:onClickNav(1)
	end

	UIEventListener.Get(self.nav2_).onClick = function ()
		self:onClickNav(2)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_PIRATE_SHOP_TEXT05"
		})
	end

	UIEventListener.Get(self.itemContent_).onClick = function ()
		local params = {
			select = 329,
			activity_type = 2
		}

		xyd.goToActivityWindowAgain(params)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateRed))
end

function ActivityPirateShop:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)

	if data.activity_id == xyd.ActivityID.ACTIVITY_PIRATE_SHOP and self.tempItem and self.tempItem.item_id then
		local id = self.tempItem.item_id
		local index = self.tempItem.index
		self.tempItem = nil

		self:updateShopInfo()
	end
end

function ActivityPirateShop:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.bottomIcon_ = goTrans:NodeByName("iconImg").gameObject
	self.navGroup_ = goTrans:NodeByName("navGroup").gameObject
	self.nav1_ = self.navGroup_:NodeByName("nav1").gameObject
	self.nav1Select_ = self.navGroup_:NodeByName("nav1/selectImg").gameObject
	self.nav1Label_ = self.navGroup_:ComponentByName("nav1/label", typeof(UILabel))
	self.navRed_ = self.navGroup_:NodeByName("nav1/redPoint").gameObject
	self.nav2_ = self.navGroup_:NodeByName("nav2").gameObject
	self.nav2Select_ = self.navGroup_:NodeByName("nav2/selectImg").gameObject
	self.nav2Label_ = self.navGroup_:ComponentByName("nav2/label", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.shopGroup_ = goTrans:NodeByName("shopGroup").gameObject
	self.itemContent_ = self.shopGroup_:NodeByName("itemContent").gameObject
	self.resItemLabel_ = self.shopGroup_:ComponentByName("itemContent/labelNum", typeof(UILabel))
	self.singleItem_ = self.shopGroup_:NodeByName("singleItem").gameObject
	self.shopScrollView_ = self.shopGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.shopLayout_ = self.shopGroup_:ComponentByName("scrollView/layout", typeof(UILayout))
	self.missionGroup_ = goTrans:NodeByName("missionGroup").gameObject
	self.missionScrollView_ = self.missionGroup_:ComponentByName("scrollView", typeof(UIScrollView))
	self.missionLayout_ = self.missionGroup_:ComponentByName("scrollView/layout", typeof(UILayout))
	self.missionItem_ = self.missionGroup_:NodeByName("missionItem").gameObject
	self.nav1Label_.text = __("ACTIVITY_PIRATE_SHOP_TEXT03")
	self.nav2Label_.text = __("ACTIVITY_PIRATE_SHOP_TEXT01")

	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_pirate_shop_logo_" .. xyd.Global.lang, nil, , true)

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" then
		self.nav1Label_.fontSize = 22
		self.nav2Label_.fontSize = 22
	end
end

function ActivityPirateShop:onClickNav(index)
	if self.curSelect_ == index then
		return
	end

	self.curSelect_ = index

	self:updateNav()
	self:updateContent()
end

function ActivityPirateShop:updateRed()
	self.navRed_:SetActive(xyd.models.backpack:getItemNumByID(xyd.ItemID.PIRATE_SHOP_ITEM) >= 50)
end

function ActivityPirateShop:updateNav()
	if self.curSelect_ == 1 then
		self.nav1Select_:SetActive(true)
		self.nav2Select_:SetActive(false)

		self.nav1Label_.color = Color.New2(4294967295.0)
		self.nav2Label_.color = Color.New2(3924024575.0)
		self.nav1Label_.effectColor = Color.New2(3467345407.0)
		self.nav2Label_.effectColor = Color.New2(2573749759.0)
	else
		self.nav2Select_:SetActive(true)
		self.nav1Select_:SetActive(false)

		self.nav2Label_.color = Color.New2(4294967295.0)
		self.nav1Label_.color = Color.New2(3924024575.0)
		self.nav2Label_.effectColor = Color.New2(3467345407.0)
		self.nav1Label_.effectColor = Color.New2(2573749759.0)
	end
end

function ActivityPirateShop:updateContent()
	if self.curSelect_ == 1 then
		self.shopGroup_:SetActive(true)
		self.missionGroup_:SetActive(false)

		local isReset = true

		if not self.isFirstInitShop then
			self.isFirstInitShop = true
		else
			isReset = false
		end

		self:updateShopInfo(isReset)
	else
		self.shopGroup_:SetActive(false)
		self.missionGroup_:SetActive(true)
		self:updateMissionInfo()
	end
end

function ActivityPirateShop:updateMissionInfo()
	local missions = self.activityData.detail.missions

	for i = 1, #missions do
		local mission_info = missions[i]
		local mission_id = mission_info.mission_id

		if not self.missionItems_[mission_id] then
			local newRoot = NGUITools.AddChild(self.missionLayout_.gameObject, self.missionItem_)

			newRoot:SetActive(true)

			self.missionItems_[mission_id] = newRoot
			local missionProgress = newRoot:ComponentByName("progressBar", typeof(UIProgressBar))
			local missionLabel = newRoot:ComponentByName("progressBar/progressLabel", typeof(UILabel))
			local missionImg = newRoot:ComponentByName("iconImg", typeof(UISprite))
			local missionItemGrid = newRoot:ComponentByName("itemGrid", typeof(UIGrid))
			local completeValue = xyd.tables.activityPirateMissionTable:getCompleteValue(mission_id)
			local awardItems = xyd.tables.activityPirateMissionTable:awards(mission_id)
			local value = mission_info.value

			if completeValue <= value or mission_info.is_awarded == 1 or mission_info.is_complete == 1 then
				value = completeValue
			end

			missionLabel.text = value .. "/" .. completeValue
			missionProgress.value = value / completeValue
			local iconImg = xyd.tables.activityPirateMissionTable:getNeedItem(mission_id)

			xyd.setUISpriteAsync(missionImg, nil, "icon_" .. iconImg, nil, , true)

			for index, itemInfo in ipairs(awardItems) do
				local icon = xyd.getItemIcon({
					scale = 0.7037037037037037,
					uiRoot = missionItemGrid.gameObject,
					itemID = itemInfo[1],
					num = itemInfo[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					dragScrollView = self.missionScrollView_
				})

				icon:setChoose(mission_info.is_awarded == 1)
			end

			missionItemGrid:Reposition()
		end
	end

	if not self.isFirstInitMission then
		self.isFirstInitMission = true

		self.missionScrollView_:ResetPosition()
	end
end

function ActivityPirateShop:updateShopInfo(reset)
	self.resItemLabel_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PIRATE_SHOP_ITEM)
	local shopList, unLockList = xyd.tables.activityPirateShopAwardTable:getUnlockList()
	local unlock_item_times = self.activityData.detail.unlock_item_times
	local buy_times = self.activityData.detail.buy_times

	for index, unLockValue in pairs(unLockList) do
		local ids = shopList[unLockValue]

		if not self.shopItems_[index] then
			local newRoot = NGUITools.AddChild(self.shopLayout_.gameObject, self.singleItem_)

			newRoot:SetActive(true)

			self.shopItems_[index] = PirateShopItem.new(newRoot, self)

			self.shopItems_[index]:setInfo(ids, unLockValue, buy_times, unlock_item_times, index)
		else
			self.shopItems_[index]:setInfo(ids, unLockValue, buy_times, unlock_item_times, index)
		end

		if index == 1 or index == #unLockList then
			self.shopLayout_:Reposition()
		end
	end

	if reset then
		self.shopScrollView_:ResetPosition()
	end
end

return ActivityPirateShop
