local cjson = require("cjson")
local BaseWindow = import(".BaseWindow")
local CountDown = import("app.components.CountDown")
local ActivitySimulationGachaExchangeWindow = class("ActivitySimulationGachaExchangeWindow", BaseWindow)
local HeroIconItem = class("HeroIconItem", import("app.components.CopyComponent"))
local FREE_RECORD_ITEM_NUM = 2
local RECORD_TEXT = {
	__("ACTIVITY_SIMULATION_GACHA_TEXT08"),
	__("ACTIVITY_SIMULATION_GACHA_TEXT09"),
	__("ACTIVITY_SIMULATION_GACHA_TEXT10"),
	__("ACTIVITY_SIMULATION_GACHA_TEXT11"),
	__("ACTIVITY_SIMULATION_GACHA_TEXT12")
}

function HeroIconItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.icon = self.go:NodeByName("icon").gameObject
	self.iconBg = self.go:ComponentByName("iconBg", typeof(UISprite))
end

function HeroIconItem:setInfo(params)
	params.uiRoot = self.icon

	xyd.getItemIcon(params)

	if xyd.tables.partnerTable:getStar(params.itemID) >= 5 then
		self.iconBg:SetActive(true)
	else
		self.iconBg:SetActive(false)
	end
end

function ActivitySimulationGachaExchangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)
end

function ActivitySimulationGachaExchangeWindow:initWindow()
	self:getUIComponent()
	ActivitySimulationGachaExchangeWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivitySimulationGachaExchangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	local groupRecord = groupAction:ComponentByName("groupRecord", typeof(UISprite))

	for i = 1, 5 do
		self["itemRecord" .. i] = groupRecord:NodeByName("itemRecord" .. i).gameObject
		self["bgRecord" .. i] = groupRecord:ComponentByName("itemRecord" .. i, typeof(UISprite))
		self["labelRecord" .. i] = self["itemRecord" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["recordLine" .. i] = self["itemRecord" .. i]:ComponentByName("imgLine", typeof(UISprite))
		self["scrollerRecord" .. i] = self["itemRecord" .. i]:ComponentByName("scroller", typeof(UIScrollView))
		self["iconRecord" .. i] = self["scrollerRecord" .. i]:NodeByName("groupIcon").gameObject
		self["tipRecord" .. i] = self["itemRecord" .. i]:ComponentByName("labelTip", typeof(UILabel))
		self["recordLock" .. i] = self["itemRecord" .. i]:NodeByName("imgLock").gameObject
		self["dragRecord" .. i] = self["itemRecord" .. i]:NodeByName("drag").gameObject
	end

	local resItem = groupAction:ComponentByName("resItem", typeof(UISprite))
	self.resNum = resItem:ComponentByName("num", typeof(UILabel))
	self.resPlus = resItem:NodeByName("plus").gameObject
	self.btnExchange = groupAction:NodeByName("btnExchange").gameObject
	self.labelExchange = self.btnExchange:ComponentByName("labelExchange", typeof(UILabel))
	self.iconItem = winTrans:NodeByName("iconItem").gameObject

	self.iconItem:SetActive(false)
end

function ActivitySimulationGachaExchangeWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_SIMULATION_GACHA_TEXT30")
	self.labelExchange.text = __("ACTIVITY_SIMULATION_GACHA_TEXT14")
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SIMULATION_GACHA_COIN)

	for i = 1, 5 do
		self["labelRecord" .. i].text = RECORD_TEXT[i]
		self["tipRecord" .. i].text = __("ACTIVITY_SIMULATION_GACHA_TEXT13")
	end

	self:update()
end

function ActivitySimulationGachaExchangeWindow:update()
	for i = 1, 5 do
		NGUITools.DestroyChildren(self["iconRecord" .. i].transform)

		if self.activityData.detail.slots[i] then
			if self.chooseIndex and self.chooseIndex == i then
				xyd.setUISpriteAsync(self["bgRecord" .. i], nil, "activity_simulation_gacha_item2")
			else
				xyd.setUISpriteAsync(self["bgRecord" .. i], nil, "9gongge17")
			end

			xyd.setUISpriteAsync(self["recordLine" .. i], nil, "activity_simulation_gacha_line1")
			self["recordLock" .. i]:SetActive(false)

			if #self.activityData.detail.slots[i] == 0 then
				self["tipRecord" .. i]:SetActive(true)
				self["dragRecord" .. i]:SetActive(false)
			else
				self["tipRecord" .. i]:SetActive(false)
				self["dragRecord" .. i]:SetActive(true)
			end

			table.sort(self.activityData.detail.slots[i], function (a, b)
				if xyd.tables.partnerTable:getStar(a) == xyd.tables.partnerTable:getStar(b) then
					return b < a
				else
					return xyd.tables.partnerTable:getStar(b) < xyd.tables.partnerTable:getStar(a)
				end
			end)

			local exist5Star = false

			for j = 1, #self.activityData.detail.slots[i] do
				if xyd.tables.partnerTable:getStar(self.activityData.detail.slots[i][j]) >= 5 then
					exist5Star = true

					break
				end
			end

			if exist5Star then
				self["scrollerRecord" .. i].padding = Vector3(0, 0)
			else
				self["scrollerRecord" .. i].padding = Vector3(7, 0)
			end

			for j = 1, #self.activityData.detail.slots[i] do
				local params = {
					noWays = true,
					showGetWays = false,
					notShowGetWayBtn = true,
					show_has_num = true,
					scale = 0.7962962962962963,
					isShowSelected = false,
					itemID = self.activityData.detail.slots[i][j],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					dragScrollView = self["scrollerRecord" .. i],
					callback = function ()
						self:recordItemClickCallback(i)
					end
				}
				local go = NGUITools.AddChild(self["iconRecord" .. i], self.iconItem)
				local tmpItem = HeroIconItem.new(go, self)

				tmpItem:setInfo(params)
			end

			self["iconRecord" .. i]:GetComponent(typeof(UILayout)):Reposition()
			self["scrollerRecord" .. i]:ResetPosition()
		else
			xyd.setUISpriteAsync(self["bgRecord" .. i], nil, "activity_simulation_gacha_item3")
			xyd.setUISpriteAsync(self["recordLine" .. i], nil, "activity_simulation_gacha_line2")
			self["recordLock" .. i]:SetActive(true)
			self["dragRecord" .. i]:SetActive(false)
			self["tipRecord" .. i]:SetActive(false)
		end
	end
end

function ActivitySimulationGachaExchangeWindow:recordItemClickCallback(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.chooseIndex == index then
		return
	end

	if self.activityData.detail.slots[index] and #self.activityData.detail.slots[index] == 0 then
		return
	end

	if not self.activityData.detail.slots[index] then
		local cost = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_entrepot_pay", "value", "|#")[#self.activityData.detail.slots - FREE_RECORD_ITEM_NUM + 1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alertYesNo(__("ACTIVITY_SIMULATION_GACHA_TEXT17", cost[2], __("ACTIVITY_SIMULATION_GACHA_TEXT2" .. #self.activityData.detail.slots + 2)), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
					type = 4
				}))
			end
		end)
	else
		xyd.setUISpriteAsync(self["bgRecord" .. index], nil, "activity_simulation_gacha_item2")

		if self.chooseIndex then
			xyd.setUISpriteAsync(self["bgRecord" .. self.chooseIndex], nil, "9gongge17")
		end

		self.chooseIndex = index
	end
end

function ActivitySimulationGachaExchangeWindow:register()
	ActivitySimulationGachaExchangeWindow.super.register(self)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SIMULATION_GACHA_TEXT18"
		})
	end

	UIEventListener.Get(self.resPlus.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_simulation_gacha_giftbag_window")
	end

	UIEventListener.Get(self.btnExchange.gameObject).onClick = function ()
		if not self.chooseIndex then
			xyd.alertTips(__("ACTIVITY_SIMULATION_GACHA_TEXT20"))

			return
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_entrepot_cost", "value", "#")

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local timeStamp = xyd.db.misc:getValue("activity_simulation_gacha_exchange_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
			xyd.openWindow("gamble_tips_window", {
				type = "activity_simulation_gacha_exchange",
				text = __("ACTIVITY_SIMULATION_GACHA_TEXT28", __("ACTIVITY_SIMULATION_GACHA_TEXT2" .. self.chooseIndex + 1)),
				callback = function ()
					if xyd.models.slot:getCanSummonNum() < 10 then
						xyd.openWindow("partner_slot_increase_window")

						return
					end

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
						type = 3,
						index = self.chooseIndex
					}))
					self.activityData:setExchangeIndex(self.chooseIndex)
				end
			})
		else
			if xyd.models.slot:getCanSummonNum() < 10 then
				xyd.openWindow("partner_slot_increase_window")

				return
			end

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
				type = 3,
				index = self.chooseIndex
			}))
			self.activityData:setExchangeIndex(self.chooseIndex)
		end
	end

	for i = 1, 5 do
		UIEventListener.Get(self["itemRecord" .. i].gameObject).onClick = function ()
			self:recordItemClickCallback(i)
		end

		UIEventListener.Get(self["dragRecord" .. i].gameObject).onClick = function ()
			self:recordItemClickCallback(i)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.SIMULATION_GACHA_COIN)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SIMULATION_GACHA then
			return
		end

		local detail = cjson.decode(event.data.detail)

		if detail.type == 3 then
			self.chooseIndex = nil
		end

		self:update()
	end)
end

return ActivitySimulationGachaExchangeWindow
