local ActivityGraduateGiftbag = class("ActivityGraduateGiftbag", import(".ActivityContent"))
local GiftbagItem = class("GiftbagItem")
local cjson = require("cjson")
local gTable = xyd.tables.activityGraduateGiftbagTable

function ActivityGraduateGiftbag:ctor(parentGo, params, parent)
	ActivityGraduateGiftbag.super.ctor(self, parentGo, params, parent)
end

function ActivityGraduateGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_graduate_giftbag"
end

function ActivityGraduateGiftbag:initUI()
	self:getUIComponent()
	ActivityGraduateGiftbag.super.initUI(self)
	self:layout()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityGraduateGiftbag:getUIComponent()
	local go = self.go
	self.textLogo = go:ComponentByName("textLogo", typeof(UISprite))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.timeGroup = go:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.scroller_panel = go:ComponentByName("scroller", typeof(UIPanel))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.giftbagItem = go:NodeByName("giftbag_item").gameObject

	self.giftbagItem:SetActive(false)

	self.topArrow = go:NodeByName("Panel/topArrow").gameObject
	self.botArrow = go:NodeByName("Panel/botArrow").gameObject
end

function ActivityGraduateGiftbag:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "agg_text_" .. xyd.Global.lang)

	self.labelEnd.text = __("END")

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_GRADUATE_HELP"
		})
	end

	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration < 0 then
		self.timeGroup:SetActive(false)
	else
		local timeCount = import("app.components.CountDown").new(self.labelTime)

		timeCount:setInfo({
			function ()
				xyd.WindowManager.get():closeWindow("activity_window")
			end,
			duration = duration
		})
	end

	self.giftBagItemList = {}
	local itemsList = gTable:getItemsList()

	for _, item in pairs(itemsList) do
		local temp = NGUITools.AddChild(self.groupContent, self.giftbagItem)
		item.scrollerView = self.scroller
		local giftbagItem = GiftbagItem.new(temp, item)

		table.insert(self.giftBagItemList, giftbagItem)
	end

	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()

		local d = self:getMoveDistance(#self.giftBagItemList)

		self.scroller:MoveRelative(Vector3(0, d, 0))
	end)

	self.scroller.onDragMoving = handler(self, self.onDragMoving)
end

function ActivityGraduateGiftbag:getMoveDistance(nums)
	local d = 0
	local delta = self.activityData.detail_.score - 6

	if delta > 0 then
		d = delta * 244
		local h = self.scroller:GetComponent(typeof(UIPanel)).height
		local maxMove = nums * 244 - h

		if d > maxMove then
			d = maxMove
		end
	end

	return d
end

function ActivityGraduateGiftbag:onDragMoving()
	local topDelta = -293 - self.scroller_panel.clipOffset.y
	local topNum = math.floor(topDelta / 244 + 0.5)
	local topArrow = false

	for i = 1, topNum do
		topArrow = topArrow or self.giftBagItemList[i].hasFreeAward
	end

	self.topArrow:SetActive(topArrow)

	local nums = #self.giftBagItemList
	local botDelta = nums * 244 - self.scroller_panel.height - topDelta
	local botNum = math.floor(botDelta / 244 + 0.5)
	local botArrow = false

	for i = nums - botNum + 1, nums do
		botArrow = botArrow or self.giftBagItemList[i].hasFreeAward
	end

	self.botArrow:SetActive(botArrow)
end

function ActivityGraduateGiftbag:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG then
		return
	end

	local detail = cjson.decode(event.data.detail)

	xyd.models.itemFloatModel:pushNewItems(detail.items)
end

function ActivityGraduateGiftbag:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	for _, item in ipairs(self.giftBagItemList) do
		if item.info.giftBagId == giftBagID then
			item.buyTimes = item.buyTimes + 1

			item:setBuyGroup(item.buyTimes)
		end
	end
end

function GiftbagItem:ctor(go, info)
	self.go = go
	self.info = info

	self:getUIComponent()
	self:layout()
	self:register()
end

function GiftbagItem:getUIComponent()
	local go = self.go
	self.heroNode = go:NodeByName("heroNode").gameObject
	self.mask_1 = self.heroNode:NodeByName("mask").gameObject
	self.completedIcon = go:ComponentByName("completedIcon", typeof(UISprite))
	self.completedImg = go:ComponentByName("completedImg", typeof(UISprite))
	local groupFree = go:NodeByName("groupFree").gameObject
	self.freeItemGroup = groupFree:NodeByName("itemGroup").gameObject
	self.getBtn = groupFree:NodeByName("getBtn").gameObject
	self.getLabel = self.getBtn:ComponentByName("getLabel", typeof(UILabel))
	self.mask_2 = groupFree:NodeByName("mask").gameObject
	local groupBuy = go:NodeByName("groupBuy").gameObject
	self.buyItemGroup = groupBuy:NodeByName("itemGroup").gameObject
	self.labelVipExp = groupBuy:ComponentByName("labelVipExp", typeof(UILabel))
	self.labelLimit = groupBuy:ComponentByName("labelLimit", typeof(UILabel))
	self.btnCharge = groupBuy:NodeByName("btnCharge").gameObject
	self.chargeLabel = self.btnCharge:ComponentByName("chargeLabel", typeof(UILabel))
	self.mask_3 = groupBuy:NodeByName("mask_3").gameObject
	self.buyBtn = groupBuy:NodeByName("buyBtn").gameObject
	self.costIcon = self.buyBtn:ComponentByName("costIcon", typeof(UISprite))
	self.buyLabel = self.buyBtn:ComponentByName("buyLabel", typeof(UILabel))
	self.mask_4 = groupBuy:NodeByName("mask_4").gameObject
end

function GiftbagItem:layout()
	local detail = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG).detail_
	local partnerId = xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[1]
	local tableID = partnerId
	local awake = 0

	if self.info.star >= 6 and self.info.star < 10 then
		tableID = xyd.tables.partnerTable:getShenxueTableId(partnerId)
		awake = self.info.star - 6
	elseif self.info.star >= 10 then
		tableID = xyd.tables.partnerTable:getStar10(partnerId)
		awake = self.info.star - 10
	end

	local heroIcon = xyd.getItemIcon({
		notChangeStar = true,
		scale = 0.9074074074074074,
		noClickSelected = true,
		itemID = tableID,
		uiRoot = self.heroNode,
		star = self.info.star,
		dragScrollView = self.info.scrollerView,
		callback = function ()
			xyd.WindowManager.get():openWindow("partner_info", {
				noWays = false,
				table_id = tableID,
				awake = awake
			})
		end
	})

	if detail.score < self.info.star then
		for i = 1, 4 do
			self["mask_" .. i]:SetActive(true)
		end

		xyd.setUISpriteAsync(self.completedIcon, nil, "agg_icon_uncompleted", nil, , true)
		xyd.setUISpriteAsync(self.completedImg, nil, "agg_img_uncompleted")
		xyd.setTouchEnable(self.getBtn, false)
		xyd.setTouchEnable(self.btnCharge, false)
		xyd.setTouchEnable(self.buyBtn, false)

		self.hasFreeAward = false
	else
		for i = 1, 4 do
			self["mask_" .. i]:SetActive(false)
		end

		if self.info.star < detail.score then
			xyd.setUISpriteAsync(self.completedImg, nil, "agg_img_completed")
		else
			xyd.setUISpriteAsync(self.completedImg, nil, "agg_img_uncompleted")
		end

		xyd.setUISpriteAsync(self.completedIcon, nil, "agg_icon_completed", nil, , true)

		self.hasFreeAward = true
	end

	if self.info.star == gTable:getMaxStar() then
		self.completedImg:SetActive(false)
	end

	self.getTimes = detail.awarded[self.info.freeId]

	self:setFreeGroup(self.getTimes)

	if self.info.giftBagId ~= 0 then
		self.secondBtn = self.btnCharge
		self.secondBtnLabel = self.chargeLabel

		self.buyBtn:SetActive(false)

		local charges = detail.charges

		for _, item in ipairs(charges) do
			if item.table_id == self.info.giftBagId then
				self.buyTimes = item.buy_times

				break
			end
		end
	else
		self.secondBtn = self.buyBtn
		self.secondBtnLabel = self.buyLabel

		self.btnCharge:SetActive(false)

		self.buyTimes = detail.awarded[self.info.costId]
	end

	self:setBuyGroup(self.buyTimes)
end

function GiftbagItem:setFreeGroup(getTimes)
	if not self.freeItemList then
		self.freeItemList = {}
		local freeAwards = gTable:getAwards(self.info.freeId)

		for _, data in ipairs(freeAwards) do
			local item = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.freeItemGroup,
				itemID = data[1],
				num = data[2],
				dragScrollView = self.info.scrollerView
			})

			table.insert(self.freeItemList, item)
		end
	end

	local limitTimes = 1

	if getTimes >= limitTimes then
		for _, item in ipairs(self.freeItemList) do
			item:setChoose(true)
		end

		xyd.applyChildrenGrey(self.getBtn)
		xyd.setTouchEnable(self.getBtn, false)

		self.getLabel.text = __("ALREADY_GET_PRIZE")
		self.hasFreeAward = false
	else
		self.getLabel.text = __("GET2")
	end
end

function GiftbagItem:setBuyGroup(buyTimes)
	if not self.buyItemList then
		self.buyItemList = {}
		local awarads = nil

		if self.info.giftBagId ~= 0 then
			self.labelVipExp.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.info.giftBagId) .. " VIP EXP"
			self.secondBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.info.giftBagId) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.info.giftBagId)
			local giftId = xyd.tables.giftBagTable:getGiftID(self.info.giftBagId)
			awarads = xyd.tables.giftTable:getAwards(giftId)
		else
			awarads = gTable:getAwards(self.info.costId)
			local cost = gTable:getCost(self.info.costId)
			self.secondBtnLabel.text = cost[2]

			xyd.setUISpriteAsync(self.costIcon, nil, "icon" .. cost[1])
			self.labelVipExp:SetActive(false)
		end

		for _, data in ipairs(awarads) do
			if data[1] ~= xyd.ItemID.VIP_EXP then
				local item = xyd.getItemIcon({
					scale = 0.7037037037037037,
					uiRoot = self.buyItemGroup,
					itemID = data[1],
					num = data[2],
					dragScrollView = self.info.scrollerView
				})

				table.insert(self.buyItemList, item)
			end
		end
	end

	local limitTimes = nil

	if self.info.costId then
		limitTimes = gTable:getLimitTimes(self.info.costId)
	else
		limitTimes = gTable:getLimitTimes(self.info.freeId)
	end

	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limitTimes - buyTimes)

	if limitTimes <= buyTimes then
		for _, item in ipairs(self.buyItemList) do
			item:setChoose(true)
		end

		xyd.applyChildrenGrey(self.secondBtn)
		xyd.setTouchEnable(self.secondBtn, false)

		self.secondBtnLabel.text = __("ALREADY_BUY")
	end
end

function GiftbagItem:register()
	UIEventListener.Get(self.getBtn).onClick = function ()
		local params = cjson.encode({
			id = tonumber(self.info.freeId)
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG, params)

		self.getTimes = self.getTimes + 1

		self:setFreeGroup(self.getTimes)
	end

	if self.info.giftBagId ~= 0 then
		UIEventListener.Get(self.btnCharge).onClick = function ()
			xyd.SdkManager.get():showPayment(self.info.giftBagId)
		end
	end

	if self.info.costId then
		UIEventListener.Get(self.buyBtn).onClick = function ()
			local cost = gTable:getCost(self.info.costId)

			if tonumber(cost[2]) <= xyd.models.backpack:getItemNumByID(tonumber(cost[1])) then
				xyd.alert(xyd.AlertType.YES_NO, __("DAILY_QUIZ_BUY_TIPS_2", cost[2]), function (yes)
					if yes then
						local params = cjson.encode({
							id = tonumber(self.info.costId)
						})

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG, params)

						self.buyTimes = self.buyTimes + 1

						self:setBuyGroup(self.buyTimes)
					end
				end)
			else
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
			end
		end
	end
end

return ActivityGraduateGiftbag
