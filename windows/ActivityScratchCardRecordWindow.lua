local BaseWindow = import(".BaseWindow")
local ActivityScratchCardRecordWindow = class("ActivityScratchCardRecordWindow", BaseWindow)
local ActivityScratchCardRecordWindowItem = class("ActivityScratchCardRecordWindowItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityScratchCardRecordWindow:ctor(name, params)
	ActivityScratchCardRecordWindow.super.ctor(self, name, params)

	self.records_ = params.records
end

function ActivityScratchCardRecordWindow:initWindow()
	ActivityScratchCardRecordWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	ActivityScratchCardRecordWindow.super.register(self)
end

function ActivityScratchCardRecordWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.rewardItem = groupAction:NodeByName("scroller/record_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.rewardItem, ActivityScratchCardRecordWindowItem, self)
	self.groupNone_ = groupAction:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
end

function ActivityScratchCardRecordWindow:initUIComponent()
	self.titleLabel.text = __("ACTIVITY_SCRATCH_RECORD")

	if not self.records_ or #self.records_ == 0 then
		self.labelNoneTips_.text = __("TOWER_RECORD_TIP_1")

		self.groupNone_:SetActive(true)
		self.itemGroup:SetActive(false)
	else
		self.itemGroup:SetActive(true)
		self.wrapContent:setInfos(self.records_, {})
	end
end

function ActivityScratchCardRecordWindowItem:ctor(go, parent)
	ActivityScratchCardRecordWindowItem.super.ctor(self, go, parent)
end

function ActivityScratchCardRecordWindowItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.extraGroup = go:NodeByName("awardGroup/extraGroup").gameObject
	self.rightArrow = self.awardGroup:NodeByName("rightArrow").gameObject
end

function ActivityScratchCardRecordWindowItem:updateInfo()
	self.items_ = self.data.items
	self.awards_ = self.data.awards

	for i = 1, #self.items_ do
		local item = self["item" .. i]
		local data = self.items_[i]
		local params = {
			scale = 0.7,
			uiRoot = self.itemGroup,
			itemID = data.item_id,
			num = data.item_num,
			dragScrollView = self.parent.scrollView
		}

		if not item then
			self["item" .. i] = xyd.getItemIcon(params)
		else
			item:setInfo(params)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.extraGroup.transform)
	self.awardGroup:SetActive(false)

	if self.awards_ and #self.awards_ > 0 and self.awards_[1].item_id and self.awards_[1].item_id > 0 then
		self.awardGroup:SetActive(true)

		for i = 1, #self.awards_ do
			local data = self.awards_[i]

			xyd.getItemIcon({
				scale = 0.7,
				uiRoot = self.extraGroup,
				itemID = data.item_id,
				num = data.item_num,
				dragScrollView = self.parent.scrollView
			})
		end

		if #self.awards_ == 1 then
			self.rightArrow:X(55)
		elseif #self.awards_ == 2 then
			self.rightArrow:X(140)
		end

		self.extraGroup:GetComponent(typeof(UILayout)):Reposition()
	end
end

return ActivityScratchCardRecordWindow
