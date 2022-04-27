local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ActivityLimitGachaAward = class("ActivityLimitGachaAward", ActivityContent)

function ActivityLimitGachaAward:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityLimitGachaAward:getPrefabPath()
	return "Prefabs/Windows/activity/activity_limit_gacha_award"
end

function ActivityLimitGachaAward:initUI()
	self.tab = {}
	self.item = {}

	self:getUIComponent()
	ActivityContent.initUI(self)

	self.curIndex = 0

	self:layout()
	self:onTab(self:getMaxIndex())
	self:registEvent()
end

function ActivityLimitGachaAward:resizeToParent()
	ActivityContent.resizeToParent(self)

	local height = self.parentWidget.height

	self.buttomGroup:Y(-680 - (height - 867) * 0.88)
	self.itemGroup:Y(23 - (height - 867) * 0.05)
	self.buttomLabel:Y(270 - (height - 867) * 0.03)

	if xyd.Global.lang == "de_de" then
		local timeBg = self.go:ComponentByName("main/timeBg_", typeof(UISprite))
		timeBg.width = 255

		timeBg:X(-210)
		self.timerGroup:X(-210)
	end
end

function ActivityLimitGachaAward:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("main").gameObject
	self.helpBtn = self.mainGroup:NodeByName("helpBtn").gameObject
	self.textImg = self.mainGroup:ComponentByName("textImg", typeof(UITexture))
	self.timerGroup = self.mainGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.itemAddGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemNum = self.itemAddGroup:ComponentByName("label", typeof(UILabel))
	self.itemGetBtn = self.itemAddGroup:NodeByName("btn").gameObject
	self.buttomGroup = self.mainGroup:NodeByName("buttomGroup").gameObject
	self.itemGroup = self.buttomGroup:NodeByName("itemGroup").gameObject
	self.navGroup = self.buttomGroup:NodeByName("navGroup").gameObject

	for i = 1, self.navGroup.transform.childCount do
		self.tab[i] = self.navGroup:NodeByName("tab" .. i).gameObject
	end

	self.buttomLabel = self.buttomGroup:ComponentByName("buttomLabel", typeof(UILabel))
	self.itemCell = go:NodeByName("activity_limit_gacha_award_item").gameObject

	self.itemCell:SetActive(false)

	for i = 1, 6 do
		local item = NGUITools.AddChild(self.itemGroup, self.itemCell)
		self.item[i] = item
	end
end

function ActivityLimitGachaAward:layout()
	xyd.setUITextureByNameAsync(self.textImg, "activity_limit_exchange_award_" .. xyd.Global.lang, true)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("END")
	self.itemNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON)
end

function ActivityLimitGachaAward:getMaxIndex()
	local times = self.activityData.detail.buy_times

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

function ActivityLimitGachaAward:refresh()
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self.curIndex)

	self.buttomLabel:SetActive(true)

	if self.curIndex == self:getMaxIndex() then
		if self.curIndex < 5 then
			self.buttomLabel.text = __("GACHA_LIMIT_EXCHANGE_NEXT")
		else
			self.buttomLabel:SetActive(false)
		end
	elseif self:getMaxIndex() < self.curIndex then
		self.buttomLabel.text = __("GACHA_LIMIT_EXCHANGE_TIPS")
	else
		self.buttomLabel:SetActive(false)
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
		local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(ids[i])
		local awards = xyd.tables.activityLimitExchangeAwardTable:getAward(ids[i])
		local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(ids[i])

		NGUITools.DestroyChildren(iconGroup.transform)

		local itemIcon = xyd.getItemIcon({
			show_has_num = true,
			itemID = awards[1],
			num = awards[2],
			uiRoot = iconGroup,
			scale = Vector3(0.9, 0.9, 1)
		})
		local times = self.activityData.detail.buy_times[ids[i]]
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
			self.item[4]:SetLocalPosition(-109, -102, 0)
			self.item[5]:SetLocalPosition(104, -102, 0)
		else
			self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
		end
	end, nil)
end

function ActivityLimitGachaAward:refreshBtnRedMark()
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self.curIndex)
	local maxIndex = self:getMaxIndex()
	local lastID = xyd.tables.activityLimitExchangeAwardTable:getLastID()

	for i = 1, #ids do
		local btn = self.item[i]:NodeByName("btn").gameObject
		local redMark = btn:ComponentByName("redMark", typeof(UISprite))
		local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(ids[i])
		local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(ids[i])
		local times = self.activityData.detail.buy_times[ids[i]]

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

function ActivityLimitGachaAward:refreshTitleRedMark()
	local flag = false

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.LIMIT_GACHA_AWARD, function ()
		local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self:getMaxIndex())
		local lastID = xyd.tables.activityLimitExchangeAwardTable:getLastID()

		for i = 1, #ids do
			local id = ids[i]
			local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(id)

			if limit > 0 and (id ~= lastID or self.activityData:getUpdateTime() - xyd.getServerTime() < 86400) and self.activityData.detail.buy_times[id] < xyd.tables.activityLimitExchangeAwardTable:getLimit(id) then
				local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(id)

				if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
					flag = true
				end
			end
		end

		self.activityData.redMarkState = flag
	end)
	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_AWARD, flag)
end

function ActivityLimitGachaAward:onBuy(index)
	local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(index)
	local tab = xyd.tables.activityLimitExchangeAwardTable:getTab(index)

	if self:getMaxIndex() < tab then
		xyd.alertTips(__("GACHA_LIMIT_EXCHANGE_UNLOCK"))
	elseif xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
	elseif index ~= xyd.tables.activityLimitExchangeAwardTable:getLastID() then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
			if yes then
				local data = require("cjson").encode({
					award_id = index
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.LIMIT_GACHA_AWARD
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				self.onBuyIndex = index
				self.onButNum = 1
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
				local data = require("cjson").encode({
					award_id = index,
					num = num
				})
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.LIMIT_GACHA_AWARD
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				self.onBuyIndex = index
				self.onButNum = num
			end,
			limitNum = xyd.tables.activityLimitExchangeAwardTable:getLimit(index) - self.activityData.detail.buy_times[index],
			eventType = xyd.event.GET_ACTIVITY_AWARD
		}

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function ActivityLimitGachaAward:registEvent()
	UIEventListener.Get(self.helpBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "GACHA_LIMIT_EXCHANGE_HELP"
		})
	end)
	UIEventListener.Get(self.itemGetBtn).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.LIMIT_GACHA_AWARD_ICON
		})
	end)

	for i = 1, self.navGroup.transform.childCount do
		UIEventListener.Get(self.tab[i]).onClick = handler(self, function ()
			self:onTab(i)
		end)
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.itemNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_AWARD_ICON)

		self:refreshBtnRedMark()
		self:refreshTitleRedMark()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if self.onBuyIndex and self.onButNum then
			self.activityData.detail.buy_times[self.onBuyIndex] = self.activityData.detail.buy_times[self.onBuyIndex] + self.onButNum
			local award = xyd.tables.activityLimitExchangeAwardTable:getAward(self.onBuyIndex)
			local items = {}

			table.insert(items, {
				item_id = award[1],
				item_num = award[2] * self.onButNum
			})
			xyd.models.itemFloatModel:pushNewItems(items)

			self.onBuyIndex = nil
			self.onButNum = nil

			self:refresh()
			self:refreshTitleRedMark()
		end
	end)
end

function ActivityLimitGachaAward:onTab(index)
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

return ActivityLimitGachaAward
