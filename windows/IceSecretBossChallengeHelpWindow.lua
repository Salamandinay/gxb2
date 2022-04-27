local BaseWindow = import(".BaseWindow")
local IceSecretBossChallengeHelpWindow = class("SettingUpCommunityWindow", BaseWindow)
local AwardItem = class("awardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function IceSecretBossChallengeHelpWindow:ctor(name, params)
	IceSecretBossChallengeHelpWindow.super.ctor(self, name, params)
end

function IceSecretBossChallengeHelpWindow:initWindow()
	IceSecretBossChallengeHelpWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	IceSecretBossChallengeHelpWindow.super.register(self)
end

function IceSecretBossChallengeHelpWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.tipsLabel_ = groupAction:ComponentByName("tipsLabel_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.awardItem = groupAction:NodeByName("scroller/award_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.awardItem, AwardItem, self)
end

function IceSecretBossChallengeHelpWindow:initUIComponent()
	self.titleLabel_.text = __("MAIL_AWAED_TEXT")
	self.desLabel_.text = __("ACTIVITY_ICE_SECRET_BOSS_HELP")
	self.tipsLabel_.text = __("ACTIVITY_ICE_SECRET_BOSS_TEXT04")
	local ids = xyd.tables.activityIceSecretBossRewardTable:getIds()

	self.wrapContent:setInfos(ids, {})
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)

	self.awardItem = nil
end

function AwardItem:initUI()
	local go = self.go
	self.hurtLabel_ = go:ComponentByName("hurtLabel_", typeof(UILabel))
	self.numLabel = go:ComponentByName("numLabel", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.hurtLabel_.text = __("ACTIVITY_ICE_SECRET_BOSS_TEXT05")
end

function AwardItem:updateInfo()
	self.id = self.data
	self.numLabel.text = xyd.tables.activityIceSecretBossRewardTable:getDamage(self.id)
	local award = xyd.tables.activityIceSecretBossRewardTable:getReward(self.id)
	local params = {
		scale = 0.8,
		uiRoot = self.itemGroup,
		itemID = award[1],
		num = award[2]
	}

	if not self.awardItem then
		self.awardItem = xyd.getItemIcon(params)
	else
		self.awardItem:setInfo(params)
	end
end

return IceSecretBossChallengeHelpWindow
