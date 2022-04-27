local BaseWindow = import(".BaseWindow")
local ActivityTaskMailAwardWindow = class("ActivityTaskMailAwardWindow", BaseWindow)
local AwardItem = class("ProbabilityRender", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityTaskMailAwardWindow:ctor(name, params)
	self.titleText = params.titleText or ""
	self.tipsText = params.tipsText
	self.taskList = params.taskList

	ActivityTaskMailAwardWindow.super.ctor(self, name, params)
end

function ActivityTaskMailAwardWindow:initWindow()
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityTaskMailAwardWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.labelDes = groupAction:ComponentByName("labelDes", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("mainGroup/scrollView", typeof(UIScrollView))
	self.awardGroup = groupAction:NodeByName("mainGroup/scrollView/awardGroup").gameObject
	self.awardItem = groupAction:NodeByName("mainGroup/itemRoot").gameObject
	local wrapContent = self.awardGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem, AwardItem, self)
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
end

function ActivityTaskMailAwardWindow:initUIComponent()
	self.labelTitle.text = self.titleText
	self.labelDes.text = self.tipsText

	self.wrapContent:setInfos(self.taskList, {})
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

	self.itemList = {}
end

function AwardItem:updateInfo()
	self.labelReadyNum.text = self.data.des
	local awardData = self.data.awards
	local len = math.max(#self.itemList, #awardData)

	for i = 1, len do
		if awardData[i] then
			local award = awardData[i]

			if not self.itemList[i] then
				self.itemList[i] = xyd.getItemIcon({
					scale = 0.6296296296296297,
					not_show_ways = true,
					show_has_num = true,
					uiRoot = self.awardGroup,
					itemID = award[1],
					num = award[2],
					dragScrollView = self.parent.scrollView,
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			else
				self.itemList[i]:SetActive(true)
				self.itemList[i]:setInfo({
					not_show_ways = true,
					show_has_num = true,
					scale = 0.6296296296296297,
					itemID = award[1],
					num = award[2],
					dragScrollView = self.parent.scrollView,
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end

			if self.data.isAwarded == 1 then
				self.itemList[i]:setChoose(true)
			else
				self.itemList[i]:setChoose(false)
			end
		elseif self.itemList[i] then
			self.itemList[i]:SetActive(false)
		end
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()

	local num = math.min(self.data.complete, self.data.count)
	self.progress.value = num / self.data.complete
	self.progressLabel.text = num .. "/" .. self.data.complete
end

return ActivityTaskMailAwardWindow
