local BaseWindow = import(".BaseWindow")
local FriendTeamBossTeamEditWindow = class("FriendTeamBossTeamEditWindow", BaseWindow)

function FriendTeamBossTeamEditWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "FriendTeamBossTeamEditWindowSkin"
end

function FriendTeamBossTeamEditWindow:initWindow()
	BaseWindow.initWindow(self)

	self.teamInfo = xyd.models.friendTeamBoss:getTeamInfo()

	self:getUIComponent()
	self:layout()
	self:register()
end

function FriendTeamBossTeamEditWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.labelTitle_ = content:ComponentByName("labelTitle_", typeof(UILabel))
	self.flagImg = content:ComponentByName("flagImg", typeof(UISprite))
	local editGroup = content:NodeByName("editGroup").gameObject
	self.labelName = editGroup:ComponentByName("labelName", typeof(UILabel))
	self.btnEdit = editGroup:NodeByName("btnEdit").gameObject
	self.btnSure_ = content:NodeByName("btnSure_").gameObject
	self.btnSureLabel = self.btnSure_:ComponentByName("button_label", typeof(UILabel))
end

function FriendTeamBossTeamEditWindow:layout()
	self.labelTitle_.text = __("Edit_Name")

	self:setTeamName(self.teamInfo.team_name)
	self:setFlag(self.teamInfo.team_icon)

	self.btnSureLabel.text = __("SURE")
end

function FriendTeamBossTeamEditWindow:setFlag(id)
	xyd.setUISpriteAsync(self.flagImg, nil, xyd.tables.friendTeamBossIconTable:getIcon(id))

	self.flagID = id
end

function FriendTeamBossTeamEditWindow:setTeamName(text)
	self.labelName.text = text
end

function FriendTeamBossTeamEditWindow:register()
	FriendTeamBossTeamEditWindow.super.register(self)

	UIEventListener.Get(self.btnEdit).onClick = function ()
		self:onClickEditName()
	end

	UIEventListener.Get(self.flagImg.gameObject).onClick = function ()
		self:onClickFlag()
	end

	UIEventListener.Get(self.btnSure_).onClick = function ()
		self:onClickSure()
	end
end

function FriendTeamBossTeamEditWindow:onClickEditName()
	xyd.WindowManager.get():openWindow("friend_team_boss_edit_name_window")
end

function FriendTeamBossTeamEditWindow:onClickFlag()
	xyd.WindowManager.get():openWindow("friend_team_boss_flag_window")
end

function FriendTeamBossTeamEditWindow:onClickSure()
	if xyd.getServerTime() - xyd.models.friendTeamBoss:getTeamInfo().last_modify_time < tonumber(xyd.tables.miscTable:getVal("govern_team_modify_interval")) then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_MODIFY_LIMIT"))

		return
	end

	if self.labelName.text == self.teamInfo.team_name and self.flagID == self.teamInfo.team_icon then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	xyd.models.friendTeamBoss:reqModifyTeamInfo(nil, self.labelName.text, self.flagID)
	xyd.WindowManager.get():closeWindow(self.name_)
end

return FriendTeamBossTeamEditWindow
