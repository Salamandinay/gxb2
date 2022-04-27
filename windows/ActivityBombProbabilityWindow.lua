local BaseWindow = import(".BaseWindow")
local ActivityBombProbabilityWindow = class("ActivityBombProbabilityWindow", BaseWindow)
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityBombProbabilityItem = class("ActivityBombProbabilityItem", import("app.common.ui.FixedMultiWrapContentItem"))

function ActivityBombProbabilityItem:ctor(go, parent)
	ActivityBombProbabilityItem.super.ctor(self, go, parent)
end

function ActivityBombProbabilityItem:initUI()
	local go = self.go
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.label = go:ComponentByName("label", typeof(UILabel))
end

function ActivityBombProbabilityItem:updateInfo()
	local icon = xyd.getItemIcon({
		show_has_num = true,
		itemID = self.data.award[1],
		num = self.data.award[2],
		uiRoot = self.groupIcon,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		scale = Vector3(1, 1, 1)
	})
	self.label.text = self.data.probability * 100 .. "%"
end

function ActivityBombProbabilityWindow:ctor(name, params)
	ActivityBombProbabilityWindow.super.ctor(self, name, params)
end

function ActivityBombProbabilityWindow:initWindow()
	ActivityBombProbabilityWindow.super.initWindow(self)
	self:getUIComponent()
	self:initData()
	self:initLayout()
	self:registerEvent()
end

function ActivityBombProbabilityWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction").gameObject
	self.labelTitle = winTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scroller = winTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroller, wrapContent, self.itemCell, ActivityBombProbabilityItem, self)
end

function ActivityBombProbabilityWindow:initData()
	local ids = xyd.tables.activityBombMakeTable:getIds()
	self.params = {}

	for _, id in ipairs(ids) do
		table.insert(self.params, {
			id = id,
			award = xyd.tables.activityBombMakeTable:getAward(id),
			probability = xyd.tables.activityBombMakeTable:getProbability(id)
		})
	end
end

function ActivityBombProbabilityWindow:initLayout()
	self.labelTitle.text = __("ALTAR_PREVIEW_TEXT")

	table.sort(self.params, function (a, b)
		return b.id < a.id
	end)
	self.wrapContent:setInfos(self.params, {})
end

function ActivityBombProbabilityWindow:registerEvent()
	ActivityBombProbabilityWindow.super.register(self)
end

return ActivityBombProbabilityWindow
