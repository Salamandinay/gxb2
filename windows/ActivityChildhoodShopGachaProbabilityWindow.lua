local BaseWindow = import(".BaseWindow")
local ActivityChildhoodShopGachaProbabilityWindow = class("ActivityChildhoodShopGachaProbabilityWindow", BaseWindow)

function ActivityChildhoodShopGachaProbabilityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityChildhoodShopGachaProbabilityWindow:initWindow()
	self:getUIComponent()
	ActivityChildhoodShopGachaProbabilityWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityChildhoodShopGachaProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.groupExtra = self.groupMain:NodeByName("groupExtra").gameObject
	self.labelExtra = self.groupExtra:ComponentByName("labelExtra", typeof(UILabel))
	self.extraAward = self.groupExtra:NodeByName("extraAward").gameObject
	self.groupNormal = self.groupMain:NodeByName("groupNormal").gameObject
	self.labelNormal = self.groupNormal:ComponentByName("labelNormal", typeof(UILabel))
	self.scroller = self.groupNormal:ComponentByName("scroller", typeof(UIScrollView))
	self.normalAward = self.scroller:NodeByName("normalAward").gameObject
	self.probItem = winTrans:NodeByName("probItem").gameObject
end

function ActivityChildhoodShopGachaProbabilityWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelExtra.text = __("ACTIVITY_CHILDREN_GAMBLE_TEXT01")
	self.labelNormal.text = __("ACTIVITY_CHILDREN_GAMBLE_TEXT02")
	local extraAwardData = xyd.tables.miscTable:split2Cost("activity_children_gamble_award", "value", "#")
	local extraAwardWeight = xyd.tables.miscTable:getNumber("activity_children_gamble_weight", "value")
	local go = NGUITools.AddChild(self.extraAward, self.probItem.gameObject)
	local icon = go:NodeByName("icon").gameObject
	local labelProb = go:ComponentByName("labelProb", typeof(UILabel))

	xyd.getItemIcon({
		show_has_num = true,
		showGetWays = false,
		notShowGetWayBtn = true,
		itemID = extraAwardData[1],
		num = extraAwardData[2],
		uiRoot = icon,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	labelProb.text = extraAwardWeight .. "%"
	local normalAwardDropbox = xyd.tables.miscTable:getNumber("activity_children_gamble_dropbox", "value")
	local info = xyd.tables.dropboxShowTable:getIdsByBoxId(normalAwardDropbox)
	local all_weight = info.all_weight
	local list = info.list

	for _, id in ipairs(list) do
		local weight = xyd.tables.dropboxShowTable:getWeight(id)
		local data = xyd.tables.dropboxShowTable:getItem(id)
		local go = NGUITools.AddChild(self.normalAward, self.probItem.gameObject)
		local icon = go:NodeByName("icon").gameObject
		local labelProb = go:ComponentByName("labelProb", typeof(UILabel))

		xyd.getItemIcon({
			showGetWays = false,
			noWays = true,
			notShowGetWayBtn = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			uiRoot = icon,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.scroller
		})

		labelProb.text = math.ceil(weight * 1000000 / all_weight) / 10000 .. "%"
	end

	self.normalAward:GetComponent(typeof(UIGrid)):Reposition()
	self.scroller:ResetPosition()
end

function ActivityChildhoodShopGachaProbabilityWindow:register()
	ActivityChildhoodShopGachaProbabilityWindow.super.register(self)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end
end

return ActivityChildhoodShopGachaProbabilityWindow
