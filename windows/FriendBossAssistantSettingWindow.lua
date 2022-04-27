local BaseWindow = import(".BaseWindow")
local FriendBossAssistantSettingWindow = class("FriendBossAssistantSettingWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function FriendBossAssistantSettingWindow:ctor(name, params)
	self.friendSharedPartnerTotalNum = 3

	BaseWindow.ctor(self, name, params)

	self.skinName = "FriendBossAssistantSettingWindowSkin"
end

function FriendBossAssistantSettingWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initMyAssistantIcon()
	self:initFriendAssistantIcon()
	self:registerEvent()
end

function FriendBossAssistantSettingWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.myAssistantTitleLabel = groupAction:ComponentByName("groupTopTips/myAssistantTitleLabel", typeof(UILabel))
	self.friendsAssistantTitleLabel = groupAction:ComponentByName("groupDownTips/friendsAssistantTitleLabel", typeof(UILabel))
	self.myAssistantIcon = groupAction:NodeByName("myAssistantIconGroup/myAssistantIcon").gameObject
	self.friendAssistantIcon0 = groupAction:NodeByName("friendAssistantIconGroup0/friendAssistantIcon0").gameObject
	self.friendAssistantIcon1 = groupAction:NodeByName("friendAssistantIconGroup1/friendAssistantIcon1").gameObject
	self.friendAssistantIcon2 = groupAction:NodeByName("friendAssistantIconGroup2/friendAssistantIcon2").gameObject
	self.myAssistNumLabel = groupAction:ComponentByName("myAssistNumLabel", typeof(UILabel))
	self.friendAssistantLabel0 = groupAction:ComponentByName("friendAssistantLabel0", typeof(UILabel))
	self.friendAssistantLabel1 = groupAction:ComponentByName("friendAssistantLabel1", typeof(UILabel))
	self.friendAssistantLabel2 = groupAction:ComponentByName("friendAssistantLabel2", typeof(UILabel))
	self.awardBtn = groupAction:NodeByName("groupTitle/awardBtn").gameObject
	self.labelWinTitle = groupAction:ComponentByName("groupTitle/labelWinTitle", typeof(UILabel))
end

function FriendBossAssistantSettingWindow:addTitle()
end

function FriendBossAssistantSettingWindow:layout()
	self:initTitleLabel()
	self:initAssistantLabel()
end

function FriendBossAssistantSettingWindow:initTitleLabel()
	self.myAssistantTitleLabel.text = __("MY_ASSISTANT")
	self.friendsAssistantTitleLabel.text = __("FRIEND_ASSISTANT")
	self.labelWinTitle.text = __("SETTING_ASSISTANT")
end

function FriendBossAssistantSettingWindow:initAssistantLabel()
	self.myAssistNumLabel.text = tostring(__("THIS_WEEK_ASSIST_NUM")) .. ":"
end

function FriendBossAssistantSettingWindow:initMyAssistantIcon()
	self:updateMyAssistantIcon()
end

function FriendBossAssistantSettingWindow:updateMyAssistantIcon()
	local mySharedPartnerInfo = xyd.models.friend:getMySharedPartner()

	if mySharedPartnerInfo == nil or mySharedPartnerInfo.shared_partner == nil then
		return
	end

	if mySharedPartnerInfo.shared_partner.table_id == nil and mySharedPartnerInfo.shared_partner.tableID == nil then
		return
	end

	local mySharedPartner = Partner.new()

	NGUITools.DestroyChildren(self.myAssistantIcon.transform)
	mySharedPartner:populate(mySharedPartnerInfo.shared_partner)

	local mySharedPartnerIcon = HeroIcon.new(self.myAssistantIcon)
	mySharedPartner.noClick = true
	mySharedPartnerIcon.isUnique = true

	mySharedPartnerIcon:setInfo(mySharedPartner)

	local sharedTimes = xyd.models.friend:getSharedTimes()
	self.myAssistNumLabel.text = tostring(__("THIS_WEEK_ASSIST_NUM")) .. ":" .. tostring(sharedTimes)
end

function FriendBossAssistantSettingWindow:initFriendAssistantIcon()
	self:updateFriendAssistantIcon()
end

function FriendBossAssistantSettingWindow:updateFriendAssistantIcon()
	local i = 0

	while i < self.friendSharedPartnerTotalNum do
		local isRemove = true
		local playerId = tonumber(xyd.db.misc:getValue("selectedPartnerPlayerId" .. tostring(i)))

		if playerId ~= nil and playerId ~= -1 then
			local friendSharedPartnerInfo = xyd.models.friend:getPlayerSharedPartner(playerId)

			if friendSharedPartnerInfo ~= nil then
				local friendAssistantIcon = HeroIcon.new(self["friendAssistantIcon" .. tostring(i)])
				local friendSharedPartner = Partner.new()

				friendSharedPartner:populate(friendSharedPartnerInfo.shared_partner)

				friendSharedPartner.noClick = true
				friendSharedPartner.isUnique = true

				friendAssistantIcon:setInfo(friendSharedPartner)

				self["friendAssistantLabel" .. tostring(i)].text = friendSharedPartnerInfo.player_name
				isRemove = false
			end
		end

		if isRemove == true then
			NGUITools.DestroyChildren(self["friendAssistantIcon" .. tostring(i)].transform)

			self["friendAssistantLabel" .. tostring(i)].text = ""
		end

		i = i + 1
	end
end

function FriendBossAssistantSettingWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_SHARED_PARTNER, handler(self, self.onGetFriendSharedPartner))
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendBossInfo))

	UIEventListener.Get(self.friendAssistantIcon0.gameObject).onClick = handler(self, self.friendAssistantSettingResponse)
	UIEventListener.Get(self.friendAssistantIcon1.gameObject).onClick = handler(self, self.friendAssistantSettingResponse)
	UIEventListener.Get(self.friendAssistantIcon2.gameObject).onClick = handler(self, self.friendAssistantSettingResponse)
	UIEventListener.Get(self.myAssistantIcon.gameObject).onClick = handler(self, self.myAssistantSettingResponse)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, self.onFriendAssistAward)
end

function FriendBossAssistantSettingWindow:onGetFriendSharedPartner(event)
	self:updateFriendAssistantIcon()
end

function FriendBossAssistantSettingWindow:onGetFriendBossInfo(event)
	self:updateMyAssistantIcon()
end

function FriendBossAssistantSettingWindow:onFriendAssistAward()
	xyd.WindowManager.get():openWindow("friend_boss_assist_award_window")
end

function FriendBossAssistantSettingWindow:myAssistantSettingResponse()
	xyd.WindowManager.get():openWindow("friend_boss_my_assistant_setting_window")
end

function FriendBossAssistantSettingWindow:friendAssistantSettingResponse()
	xyd.WindowManager.get():openWindow("friend_boss_friend_assistant_setting_window")
end

return FriendBossAssistantSettingWindow
