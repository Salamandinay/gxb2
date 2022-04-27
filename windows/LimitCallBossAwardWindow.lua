local BaseWindow = import(".BaseWindow")
local LimitCallBossAwardWindow = class("LimitCallBossAwardWindow", BaseWindow)
local AwardItem = class("awardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function LimitCallBossAwardWindow:ctor(name, params)
	LimitCallBossAwardWindow.super.ctor(self, name, params)
end

function LimitCallBossAwardWindow:initWindow()
	LimitCallBossAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	LimitCallBossAwardWindow.super.register(self)
end

function LimitCallBossAwardWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.topLabel1 = groupAction:ComponentByName("topGroup/topLabel1", typeof(UILabel))
	self.topLabel2 = groupAction:ComponentByName("topGroup/topLabel2", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.awardItem = groupAction:NodeByName("scroller/award_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem, AwardItem, self)
end

function LimitCallBossAwardWindow:initUIComponent()
	self.titleLabel_.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")
	self.topLabel1.text = __("GACHA_LIMIT_BOSS_LABEL_1")
	self.topLabel2.text = __("GACHA_LIMIT_BOSS_LABEL_2")
	local ids = xyd.tables.activityLimitBossAwardTable:getIds()

	self.wrapContent:setInfos(ids, {})
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)

	self.awardItem = nil
end

function AwardItem:initUI()
	local go = self.go
	self.numLabel = go:ComponentByName("numLabel_", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
end

function AwardItem:updateInfo()
	self.id = self.data
	local ids = xyd.tables.activityLimitBossAwardTable:getIds()
	local numStr = xyd.getRoughDisplayNumber(xyd.tables.activityLimitBossAwardTable:getDamage(self.id))

	if self.id < #ids then
		numStr = numStr .. "~" .. xyd.getRoughDisplayNumber(xyd.tables.activityLimitBossAwardTable:getDamage(self.id + 1))
	else
		numStr = numStr .. "~"
	end

	self.numLabel.text = numStr
	local awards = xyd.tables.activityLimitBossAwardTable:getReward(self.id)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local award = awards[i]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.5925925925925926,
			uiRoot = self.itemGroup,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView
		})
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return LimitCallBossAwardWindow
