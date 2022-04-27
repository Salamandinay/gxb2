local BaseWindow = import(".BaseWindow")
local TimeCloisterAchievementDetailWindow = class("TimeCloisterAchievementDetailWindow", BaseWindow)
local AwardItem = class("ProbabilityRender", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local achTable = xyd.tables.timeCloisterAchTable
local achTypeTable = xyd.tables.timeCloisterAchTypeTable

function TimeCloisterAchievementDetailWindow:ctor(name, params)
	self.achieve_id = params.achieve_id
	self.achieve_type = params.achieve_type
	self.value = params.value

	BaseWindow.ctor(self, name, params)
end

function TimeCloisterAchievementDetailWindow:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function TimeCloisterAchievementDetailWindow:getUIComponent()
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

function TimeCloisterAchievementDetailWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.labelDes.text = __("ACTIVITY_NEWBEE_LESSON_TEXT03")
	local start_id = xyd.tables.timeCloisterAchTypeTable:getStart(self.achieve_type)
	local end_id = xyd.tables.timeCloisterAchTypeTable:getEnd(self.achieve_type)
	local ids = {}

	for i = start_id, end_id do
		table.insert(ids, {
			achieve_id = i,
			value = self.value,
			has_got = i < self.achieve_id or self.achieve_id == 0
		})
	end

	self.wrapContent:setInfos(ids, {})
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
	local completeValue = achTable:getCompleteValue(self.data.achieve_id)
	local dataValue = self.data.value
	local achieve_type = self.parent.achieve_type
	local style = achTypeTable:getStyle(achieve_type)

	if style == 2 then
		local start_id = achTypeTable:getStart(achieve_type)
		local start_complete = achTable:getCompleteValue(start_id)
		completeValue = completeValue - (start_complete - 1)

		if tonumber(completeValue) < tonumber(dataValue) then
			dataValue = dataValue - (start_complete - 1)
		end
	end

	self.progress.value = dataValue / completeValue
	self.progressLabel.text = dataValue .. " / " .. completeValue

	if xyd.Global.lang ~= "zh_tw" then
		self.labelReadyNum.fontSize = 16
	end

	self.labelReadyNum.text = xyd.stringFormat(achTable:getDesc(self.data.achieve_id), completeValue)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awardData = achTable:getAwards(self.data.achieve_id)

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

		item:setChoose(self.data.has_got)
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()
end

return TimeCloisterAchievementDetailWindow
