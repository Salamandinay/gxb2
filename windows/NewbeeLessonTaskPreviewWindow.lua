local BaseWindow = import(".BaseWindow")
local NewbeeLessonTaskPreviewWindow = class("NewbeeLessonTaskPreviewWindow", BaseWindow)
local AwardItem = class("ProbabilityRender", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local nTable = xyd.tables.activityNewbeeLessonTable

function NewbeeLessonTaskPreviewWindow:ctor(name, params)
	self.activityID = params.activityID

	BaseWindow.ctor(self, name, params)
end

function NewbeeLessonTaskPreviewWindow:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function NewbeeLessonTaskPreviewWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelDes = groupAction:ComponentByName("labelDes", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("mainGroup/scrollView", typeof(UIScrollView))
	self.awardGroup = groupAction:NodeByName("mainGroup/scrollView/awardGroup").gameObject
	self.awardItem = groupAction:NodeByName("mainGroup/scrollView/warm_up_award_item").gameObject
	local wrapContent = self.awardGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem, AwardItem, self)
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function NewbeeLessonTaskPreviewWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelDes.text = __("ACTIVITY_NEWBEE_LESSON_TEXT03")
	local missionList = nTable:getAccumulateTaskByType(self.params_.type)
	local awards = xyd.models.activity:getActivity(self.activityID).detail_.awards

	table.sort(missionList, function (a, b)
		if awards[a] == awards[b] then
			return a < b
		else
			return awards[a] == 0
		end
	end)
	self.wrapContent:setInfos(missionList, {})
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)
end

function AwardItem:initUI()
	local go = self.go
	self.labelReadyNum = go:ComponentByName("labelReadyNum", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))

	self:setDragScrollView()
end

function AwardItem:updateInfo()
	local detail = xyd.models.activity:getActivity(self.parent.activityID).detail_
	self.labelReadyNum.text = nTable:getDesc(self.data)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awardData = nTable:getAward(self.data)

	for i = 1, #awardData do
		local award = awardData[i]
		local item = xyd.getItemIcon({
			scale = 0.7037037037037037,
			not_show_ways = true,
			show_has_num = true,
			uiRoot = self.awardGroup,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if detail.awards[self.data] == 1 then
			item:setChoose(true)
		else
			item:setChoose(false)
		end
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()

	local completeValue = nTable:getCompleteValue(self.data)
	self.progress.value = detail.values[self.data] / completeValue
	self.progressLabel.text = detail.values[self.data] .. " / " .. completeValue
end

return NewbeeLessonTaskPreviewWindow
