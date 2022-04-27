local ArenaFormationWindow = import(".ArenaFormationWindow")
local FriendTeamBossSingleFormationWindow = class("FriendTeamBossSingleFormationWindow", ArenaFormationWindow)

function FriendTeamBossSingleFormationWindow:ctor(name, params)
	ArenaFormationWindow.ctor(self, name, params)
end

function FriendTeamBossSingleFormationWindow:register()
	ArenaFormationWindow.register(self)

	UIEventListener.Get(self.btnKick).onClick = function ()
		self:onTouchKick()
	end
end

function FriendTeamBossSingleFormationWindow:onTouchKick()
	if xyd.models.friendTeamBoss:checkInFight() then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_IN_FIGHT"))

		return
	end

	if xyd.models.friendTeamBoss:getSelfInfo().weekly_kickout_times <= 0 then
		xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_KICK_LIMIT"))

		return
	end

	local params = {
		alertType = xyd.AlertType.CONFIRM,
		message = __("FRIEND_TEAM_BOSS_KICK_CONFIRM", xyd.models.friendTeamBoss:getSelfInfo().weekly_kickout_times),
		callback = function (yes)
			if yes then
				xyd.models.friendTeamBoss:kickOutPlayer(self.player_id)
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end
	}

	xyd.alert(params.alertType, params.message, params.callback)
end

function FriendTeamBossSingleFormationWindow:initWindow()
	ArenaFormationWindow.initWindow(self)
	self.btnShield:SetActive(false)

	if xyd.models.friendTeamBoss:getTeamInfo().leader_id == xyd.models.selfPlayer:getPlayerID() then
		self.btnKick:SetActive(true)
	else
		self.btnKick:SetActive(false)
	end

	self.btnDelFriend_:SetActive(false)

	self.btnKickLabel.text = __("FRIEND_TEAM_BOSS_KICKOUT_TEAM")
end

return FriendTeamBossSingleFormationWindow
