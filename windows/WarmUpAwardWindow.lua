local BaseWindow = import(".BaseWindow")
local WarmUpAwardWindow = class("WarmUpAwardWindow", BaseWindow)
local WarmUpAwardItem = class("ProbabilityRender", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityWarmCardAwardTable = xyd.tables.activityWarmCardAwardTable

function WarmUpAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.count = params.count
end

function WarmUpAwardWindow:initWindow()
	WarmUpAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function WarmUpAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("mainGroup/awardScroller", typeof(UIScrollView))
	self.awardGroup = groupAction:NodeByName("mainGroup/awardScroller/awardGroup").gameObject
	self.awardItem = groupAction:NodeByName("mainGroup/awardScroller/warm_up_award_item").gameObject
	local wrapContent = self.awardGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.awardItem, WarmUpAwardItem, self)
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function WarmUpAwardWindow:layout()
	self:addTitle()

	local awardInfo = {}
	local ids = ActivityWarmCardAwardTable:getIds()

	for i, _ in pairs(ids) do
		table.insert(awardInfo, {
			id = ids[i],
			count = self.count
		})
	end

	self.wrapContent:setInfos(awardInfo, {})
end

function WarmUpAwardItem:ctor(go, parent)
	WarmUpAwardItem.super.ctor(self, go, parent)
end

function WarmUpAwardItem:initUI()
	local go = self.go
	self.labelReadyNum = go:ComponentByName("labelReadyNum", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))

	self:setDragScrollView()
end

function WarmUpAwardItem:updateInfo()
	self.id = self.data.id
	self.count = self.data.count

	self:setProgress()

	self.labelReadyNum.text = __("ACTIVITY_WARMUP_PACK_PRE_TEXT", ActivityWarmCardAwardTable:getAmount(self.id))

	if self.awardGroup.transform.childCount == 0 then
		local awardData = ActivityWarmCardAwardTable:getAwards(self.id)
		local item = xyd.getItemIcon({
			scale = 0.7,
			not_show_ways = true,
			uiRoot = self.awardGroup,
			itemID = awardData[1],
			num = awardData[2]
		})

		item:setDragScrollView(self.scrollView)
	end
end

function WarmUpAwardItem:setProgress()
	local maxNum = ActivityWarmCardAwardTable:getAmount(self.id)
	self.progress.value = self.count / maxNum
	self.progressLabel.text = self.count .. " / " .. tostring(maxNum)
end

return WarmUpAwardWindow
