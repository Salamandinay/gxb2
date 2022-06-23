local cjson = require("cjson")
local BaseWindow = import(".BaseWindow")
local ActivitySimulationGachaRecordWindow = class("ActivitySimulationGachaRecordWindow", BaseWindow)
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
	self.iconRecommoned = self.go:NodeByName("iconRecommoned").gameObject
end

function HeroIconItem:setInfo(params)
	params.uiRoot = self.icon

	xyd.getItemIcon(params)

	if xyd.tables.partnerTable:getStar(params.itemID) >= 5 then
		self.iconBg:SetActive(true)
	else
		self.iconBg:SetActive(false)
	end

	if xyd.tables.partnerRecommendSimulationTable:checkIsRecommend(params.itemID) then
		self.iconRecommoned:SetActive(true)
	else
		self.iconRecommoned:SetActive(false)
	end
end

function ActivitySimulationGachaRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)
end

function ActivitySimulationGachaRecordWindow:initWindow()
	self:getUIComponent()
	ActivitySimulationGachaRecordWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivitySimulationGachaRecordWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
	local groupMain = groupAction:ComponentByName("groupMain", typeof(UISprite))
	self.labelTip = groupMain:ComponentByName("labelTip", typeof(UILabel))
	self.itemResult = groupMain:ComponentByName("itemResult", typeof(UISprite))
	self.labelResult = self.itemResult:ComponentByName("labelDesc", typeof(UILabel))
	self.scrollerResult = self.itemResult:ComponentByName("scroller", typeof(UIScrollView))
	self.iconResult = self.scrollerResult:NodeByName("groupIcon").gameObject

	for i = 1, 5 do
		self["itemRecord" .. i] = groupMain:NodeByName("itemRecord" .. i).gameObject
		self["bgRecord" .. i] = groupMain:ComponentByName("itemRecord" .. i, typeof(UISprite))
		self["labelRecord" .. i] = self["itemRecord" .. i]:ComponentByName("labelDesc", typeof(UILabel))
		self["recordLine" .. i] = self["itemRecord" .. i]:ComponentByName("imgLine", typeof(UISprite))
		self["scrollerRecord" .. i] = self["itemRecord" .. i]:ComponentByName("scroller", typeof(UIScrollView))
		self["iconRecord" .. i] = self["scrollerRecord" .. i]:NodeByName("groupIcon").gameObject
		self["tipRecord" .. i] = self["itemRecord" .. i]:ComponentByName("labelTip", typeof(UILabel))
		self["recordPlus" .. i] = self["itemRecord" .. i]:NodeByName("imgPlus").gameObject
		self["recordLock" .. i] = self["itemRecord" .. i]:NodeByName("imgLock").gameObject
		self["dragRecord" .. i] = self["itemRecord" .. i]:NodeByName("drag").gameObject

		self["tipRecord" .. i]:SetActive(false)
	end

	self.iconItem = winTrans:NodeByName("iconItem").gameObject

	self.iconItem:SetActive(false)
end

function ActivitySimulationGachaRecordWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_SIMULATION_GACHA_TEXT31")
	self.labelTip.text = __("ACTIVITY_SIMULATION_GACHA_TEXT06")
	self.labelResult.text = __("ACTIVITY_SIMULATION_GACHA_TEXT05")

	for i = 1, 5 do
		self["labelRecord" .. i].text = RECORD_TEXT[i]
	end

	self:update()
end

function ActivitySimulationGachaRecordWindow:update()
	NGUITools.DestroyChildren(self.iconResult.transform)

	if self.activityData.detail.tmp_slot then
		table.sort(self.activityData.detail.tmp_slot, function (a, b)
			if xyd.tables.partnerTable:getStar(a) == xyd.tables.partnerTable:getStar(b) then
				return b < a
			else
				return xyd.tables.partnerTable:getStar(b) < xyd.tables.partnerTable:getStar(a)
			end
		end)

		for i = 1, #self.activityData.detail.tmp_slot do
			local params = {
				noWays = true,
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.7962962962962963,
				isShowSelected = false,
				itemID = self.activityData.detail.tmp_slot[i],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollerResult,
				callback = function ()
				end
			}
			local go = NGUITools.AddChild(self.iconResult, self.iconItem)
			local tmpItem = HeroIconItem.new(go, self)

			tmpItem:setInfo(params)
		end

		self.iconResult:GetComponent(typeof(UILayout)):Reposition()
		self.scrollerResult:ResetPosition()
	end

	if self.activityData.detail.tmp_slot and #self.activityData.detail.tmp_slot > 0 then
		self.labelResult.text = __("ACTIVITY_SIMULATION_GACHA_TEXT05")
	else
		self.labelResult.text = __("ACTIVITY_SIMULATION_GACHA_TEXT29")
	end

	for i = 1, 5 do
		NGUITools.DestroyChildren(self["iconRecord" .. i].transform)

		if self.activityData.detail.slots[i] then
			xyd.setUISpriteAsync(self["bgRecord" .. i], nil, "9gongge17")
			xyd.setUISpriteAsync(self["recordLine" .. i], nil, "activity_simulation_gacha_line1")
			self["recordLock" .. i]:SetActive(false)

			if #self.activityData.detail.slots[i] == 0 then
				self["recordPlus" .. i]:SetActive(true)
				self["dragRecord" .. i]:SetActive(false)
			else
				self["recordPlus" .. i]:SetActive(false)
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
			self["recordPlus" .. i]:SetActive(false)
			self["dragRecord" .. i]:SetActive(false)
		end
	end
end

function ActivitySimulationGachaRecordWindow:recordItemClickCallback(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if not self.activityData.detail.slots[index] then
		local cost = xyd.tables.miscTable:split2Cost("activity_simulation_gacha_10_entrepot_pay", "value", "|#")[math.max(#self.activityData.detail.slots, 2) - FREE_RECORD_ITEM_NUM + 1]

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alertYesNo(__("ACTIVITY_SIMULATION_GACHA_TEXT17", cost[2], __("ACTIVITY_SIMULATION_GACHA_TEXT2" .. math.max(#self.activityData.detail.slots, 2) + 2)), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
					type = 4
				}))
			end
		end)
	else
		if not self.activityData.detail.tmp_slot then
			return
		end

		xyd.alertYesNo(#self.activityData.detail.slots[index] > 0 and __("ACTIVITY_SIMULATION_GACHA_TEXT15") or __("ACTIVITY_SIMULATION_GACHA_TEXT16"), function (yes)
			if yes then
				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA, cjson.encode({
					type = 2,
					index = index
				}))
				xyd.db.misc:setValue({
					value = 0,
					key = "activity_simulation_gacha_flashback"
				})
			end
		end)
	end
end

function ActivitySimulationGachaRecordWindow:register()
	ActivitySimulationGachaRecordWindow.super.register(self)

	UIEventListener.Get(self.helpBtn.gameObject).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_SIMULATION_GACHA_TEXT07"
		})
	end

	for i = 1, 5 do
		UIEventListener.Get(self["itemRecord" .. i].gameObject).onClick = function ()
			self:recordItemClickCallback(i)
		end

		UIEventListener.Get(self["dragRecord" .. i].gameObject).onClick = function ()
			self:recordItemClickCallback(i)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SIMULATION_GACHA then
			return
		end

		self:update()
	end)
end

return ActivitySimulationGachaRecordWindow
