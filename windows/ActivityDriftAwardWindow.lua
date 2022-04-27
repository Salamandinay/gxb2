local BaseWindow = import(".BaseWindow")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ActivityDriftAwardWindow = class("ActivityDriftAwardWindow", BaseWindow)
local ActivityDriftAwardItem = class("ActivityDriftAwardItem", import("app.common.ui.FixedWrapContentItem"))

function ActivityDriftAwardWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.point = params.point
end

function ActivityDriftAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityDriftAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.title = groupAction:ComponentByName("title", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.numLabel = groupAction:ComponentByName("numGroup/label", typeof(UILabel))
	self.label = groupAction:ComponentByName("label", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("scroll", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("iconGroup", typeof(UIWrapContent))
	local itemCell = groupAction:NodeByName("activity_drift_award_item").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemCell, ActivityDriftAwardItem, self)
end

function ActivityDriftAwardWindow:layout()
	self.numLabel.text = self.point
	self.title.text = __("ACTIVITY_LAFULI_DRIFT_AWARD")
	self.label.text = __("ACTIVITY_LAFULI_DRIFT_ROUND", math.floor(self.point / 300))
	local ids = xyd.tables.activityDriftAwardTable:getIDs()
	local awards = {}

	for i = 1, #ids do
		table.insert(awards, {
			awards = xyd.tables.activityDriftAwardTable:getAwards(ids[i]),
			point = xyd.tables.activityDriftAwardTable:getPoint(ids[i]),
			curPoint = self.point
		})
	end

	table.sort(awards, function (a, b)
		local maxPoint = xyd.tables.activityDriftAwardTable:getPoint(xyd.tables.activityDriftAwardTable:getIDs()[#xyd.tables.activityDriftAwardTable:getIDs()])

		if a.point <= math.fmod(a.curPoint, maxPoint) == (b.point <= math.fmod(b.curPoint, maxPoint)) then
			return a.point < b.point
		else
			return math.fmod(a.curPoint, maxPoint) < a.point
		end
	end)
	self.wrapContent:setInfos(awards, {})
end

function ActivityDriftAwardWindow:register()
	BaseWindow.register(self)
end

function ActivityDriftAwardItem:ctor(go, parent)
	ActivityDriftAwardItem.super.ctor(self, go, parent)

	self.parent = parent
end

function ActivityDriftAwardItem:initUI()
	local go = self.go
	self.progressBar_ = go:ComponentByName("progressBar_", typeof(UIProgressBar))
	self.progressLabel = self.progressBar_:ComponentByName("progressLabel", typeof(UILabel))
	self.descLabel = go:ComponentByName("labelTitle", typeof(UILabel))
	self.itemsGroup = go:ComponentByName("itemsGroup", typeof(UILayout))
end

function ActivityDriftAwardItem:updateInfo()
	local max = self.data.point
	local cur = self.data.curPoint
	local awards = self.data.awards
	local maxPoint = xyd.tables.activityDriftAwardTable:getPoint(xyd.tables.activityDriftAwardTable:getIDs()[#xyd.tables.activityDriftAwardTable:getIDs()])
	max = max + math.floor(cur / maxPoint) * maxPoint
	self.progressBar_.value = cur <= max and cur / max or 1
	self.progressLabel.text = (cur <= max and cur or max) .. "/" .. max
	self.descLabel.text = __("ACTIVITY_LAFULI_DRIFT_POINT", max)

	NGUITools.DestroyChildren(self.itemsGroup.transform)

	for i = 1, #awards do
		local icon = xyd.getItemIcon({
			show_has_num = true,
			showGetWays = false,
			itemID = awards[i][1],
			num = awards[i][2],
			uiRoot = self.itemsGroup.gameObject,
			scale = Vector3(0.7, 0.7, 1),
			dragScrollView = self.parent.scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if max <= cur then
			icon:setChoose(true)
		end
	end

	self.itemsGroup:Reposition()
end

return ActivityDriftAwardWindow
