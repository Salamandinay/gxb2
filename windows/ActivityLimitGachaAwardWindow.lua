local BaseWindow = import(".BaseWindow")
local ActivityLimitGachaAwardWindow = class("ActivityLimitGachaAwardWindow", BaseWindow)
local CountDown = import("app.components.CountDown")

function ActivityLimitGachaAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityLimitGachaAwardWindow:initWindow()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.TIME_LIMIT_CALL)
	self.tab = {}
	self.item = {}
	self.curIndex = 0

	self:getUIComponent()
	ActivityLimitGachaAwardWindow.super.initWindow(self)
	self:layout()
	self:onTab(self:getMaxIndex())
	self:registEvent()
end

function ActivityLimitGachaAwardWindow:getUIComponent()
	local go = self.window_.transform
	self.mainGroup = go:NodeByName("main").gameObject
	self.timerGroup = self.mainGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.itemAddGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemNum = self.itemAddGroup:ComponentByName("label", typeof(UILabel))
	self.plusBtn = self.itemAddGroup:ComponentByName("plusIcon", typeof(UISprite)).gameObject
	self.tipLabel = self.mainGroup:ComponentByName("tipLabel", typeof(UILabel))
	self.buttomGroup = self.mainGroup:NodeByName("buttomGroup").gameObject
	self.itemGroup = self.buttomGroup:NodeByName("itemGroup").gameObject
	self.navGroup = self.buttomGroup:NodeByName("navGroup").gameObject

	for i = 1, self.navGroup.transform.childCount do
		self.tab[i] = self.navGroup:NodeByName("tab" .. i).gameObject
	end

	self.itemCell = go:NodeByName("activity_limit_gacha_award_item").gameObject

	self.itemCell:SetActive(false)

	for i = 1, 6 do
		local item = NGUITools.AddChild(self.itemGroup, self.itemCell)
		self.item[i] = item
	end

	self.bottomLabel = self.mainGroup:ComponentByName("bottomLabel", typeof(UILabel))
end

function ActivityLimitGachaAwardWindow:layout()
	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END")
	self.itemNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2)
	self.tipLabel.text = __("ITEM_RECYCLE_TIPS")
end

function ActivityLimitGachaAwardWindow:getMaxIndex()
	local times = self.activityData.detail.shop_times

	for i = 1, 5 do
		local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(i)

		for j = 1, #ids do
			if times[ids[j]] <= 0 then
				return i
			end
		end
	end

	return 5
end

function ActivityLimitGachaAwardWindow:refresh()
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self.curIndex)

	self.bottomLabel:SetActive(true)

	if self.curIndex == self:getMaxIndex() then
		if self.curIndex < 5 then
			self.bottomLabel.text = __("GACHA_LIMIT_EXCHANGE_NEXT")
		else
			self.bottomLabel:SetActive(false)
		end
	elseif self:getMaxIndex() < self.curIndex then
		self.bottomLabel.text = __("GACHA_LIMIT_EXCHANGE_TIPS")
	else
		self.bottomLabel:SetActive(false)
	end

	for i = #ids + 1, 6 do
		self.item[i]:SetActive(false)
	end

	local maxIndex = self:getMaxIndex()

	for i = 1, #ids do
		self.item[i]:SetActive(true)

		local iconGroup = self.item[i]:NodeByName("iconGroup").gameObject
		local label = self.item[i]:ComponentByName("label", typeof(UILabel))
		local btn = self.item[i]:NodeByName("btn").gameObject
		local icon = btn:ComponentByName("icon", typeof(UISprite))
		local btnLabel = btn:ComponentByName("label", typeof(UILabel))
		local redMark = btn:ComponentByName("redMark", typeof(UISprite))
		local newImg = self.item[i]:NodeByName("newImg").gameObject
		local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(ids[i])
		local awards = xyd.tables.activityLimitExchangeAwardTable:getAward(ids[i])
		local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(ids[i])

		NGUITools.DestroyChildren(iconGroup.transform)

		local itemIcon = xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			isShowSelected = false,
			itemID = awards[1],
			num = awards[2],
			uiRoot = iconGroup,
			scale = Vector3(1, 1, 1),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if awards[1] == 7204 then
			newImg:SetActive(true)
		else
			newImg:SetActive(false)
		end

		local times = self.activityData.detail.shop_times[ids[i]]
		label.text = __("BUY_GIFTBAG_LIMIT", limit - times)

		xyd.setUISpriteAsync(icon, nil, "icon_" .. cost[1] .. "_small")

		btnLabel.text = cost[2]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			redMark:SetActive(false)
		elseif limit - times <= 0 then
			redMark:SetActive(false)
		elseif maxIndex < self.curIndex then
			redMark:SetActive(false)
		elseif ids[i] == xyd.tables.activityLimitExchangeAwardTable:getLastID() and self.activityData:getUpdateTime() - xyd.getServerTime() > 86400 then
			redMark:SetActive(false)
		else
			redMark:SetActive(true)
		end

		if limit - times <= 0 then
			xyd.applyChildrenGrey(btn)

			btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		else
			xyd.applyChildrenOrigin(btn)

			btn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
		end

		UIEventListener.Get(btn).onClick = handler(self, function ()
			self:onBuy(ids[i])
		end)
	end

	self:waitForFrame(1, function ()
		if #ids == 5 then
			self.item[4]:SetLocalPosition(-105, -123, 0)
			self.item[5]:SetLocalPosition(105, -123, 0)
		else
			self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
		end
	end, nil)
end

function ActivityLimitGachaAwardWindow:refreshBtnRedMark()
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self.curIndex)
	local maxIndex = self:getMaxIndex()
	local lastID = xyd.tables.activityLimitExchangeAwardTable:getLastID()

	for i = 1, #ids do
		local btn = self.item[i]:NodeByName("btn").gameObject
		local redMark = btn:ComponentByName("redMark", typeof(UISprite))
		local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(ids[i])
		local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(ids[i])
		local times = self.activityData.detail.shop_times[ids[i]]

		if ids[i] ~= lastID or self.activityData:getUpdateTime() - xyd.getServerTime() < 86400 then
			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				redMark:SetActive(false)
			elseif limit - times <= 0 then
				redMark:SetActive(false)
			elseif maxIndex < self.curIndex then
				redMark:SetActive(false)
			else
				redMark:SetActive(true)
			end
		else
			redMark:SetActive(false)
		end
	end
end

function ActivityLimitGachaAwardWindow:onBuy(index)
	local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(index)
	local tab = xyd.tables.activityLimitExchangeAwardTable:getTab(index)

	if self:getMaxIndex() < tab then
		xyd.alertTips(__("GACHA_LIMIT_EXCHANGE_UNLOCK"))
	elseif xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
	elseif index ~= xyd.tables.activityLimitExchangeAwardTable:getLastID() then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				local msg = messages_pb.limit_gacha_shop_req()
				msg.activity_id = xyd.ActivityID.TIME_LIMIT_CALL
				msg.table_id = index

				xyd.Backend.get():request(xyd.mid.LIMIT_GACHA_SHOP, msg)

				self.onBuyIndex = index
				self.onButNum = 1

				self.activityData:setButNum(self.onButNum)
			end
		end)
	else
		local params = {
			notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
			hasMaxMin = true,
			titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
			buyType = xyd.tables.activityLimitExchangeAwardTable:getAward(index)[1],
			buyNum = xyd.tables.activityLimitExchangeAwardTable:getAward(index)[2],
			costType = xyd.tables.activityLimitExchangeAwardTable:getCost(index)[1],
			costNum = xyd.tables.activityLimitExchangeAwardTable:getCost(index)[2],
			purchaseCallback = function (_, num)
				local msg = messages_pb.limit_gacha_shop_req()
				msg.activity_id = xyd.ActivityID.TIME_LIMIT_CALL
				msg.table_id = index
				msg.num = num

				xyd.Backend.get():request(xyd.mid.LIMIT_GACHA_SHOP, msg)

				self.onBuyIndex = index
				self.onButNum = num

				self.activityData:setButNum(self.onButNum)
			end,
			limitNum = xyd.tables.activityLimitExchangeAwardTable:getLimit(index) - self.activityData.detail.shop_times[index],
			eventType = xyd.event.LIMIT_GACHA_SHOP
		}

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function ActivityLimitGachaAwardWindow:registEvent()
	for i = 1, self.navGroup.transform.childCount do
		UIEventListener.Get(self.tab[i]).onClick = handler(self, function ()
			self:onTab(i)
		end)
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.itemNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2)

		self:refreshBtnRedMark()
	end)
	self.eventProxy_:addEventListener(xyd.event.LIMIT_GACHA_SHOP, function (event)
		local award = xyd.tables.activityLimitExchangeAwardTable:getAward(self.onBuyIndex)
		local items = {}

		table.insert(items, {
			item_id = award[1],
			item_num = award[2] * self.onButNum
		})

		local skins = {}

		if xyd.tables.itemTable:getType(award[1]) == xyd.ItemType.SKIN then
			table.insert(skins, award[1])
		end

		if #skins > 0 then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = skins,
				callback = function ()
					xyd.models.itemFloatModel:pushNewItems(items)
				end
			})
		else
			xyd.models.itemFloatModel:pushNewItems(items)
		end

		self.onBuyIndex = nil
		self.onButNum = nil

		self:refresh()
	end)

	UIEventListener.Get(self.plusBtn).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.LIMIT_GACHA_AWARD_ICON2,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.itemAddGroup).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.LIMIT_GACHA_AWARD_ICON2,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON2),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityLimitGachaAwardWindow:onTab(index)
	if index ~= self.curIndex then
		for i = 1, self.navGroup.transform.childCount do
			if i == index then
				self.tab[i]:NodeByName("chosen"):SetActive(true)
			else
				self.tab[i]:NodeByName("chosen"):SetActive(false)
			end
		end

		self.curIndex = index

		self:refresh()
	end
end

return ActivityLimitGachaAwardWindow
