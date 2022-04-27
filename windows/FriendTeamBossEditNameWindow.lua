local PersonEditNameWindow = import(".PersonEditNameWindow")
local FriendTeamBossEditNameWindow = class("FriendTeamBossEditNameWindow", PersonEditNameWindow)

function FriendTeamBossEditNameWindow:layout()
	self.labelTitle_.text = __("PERSON_EDIT_NAME")
	self.labelDesc_.text = __("PERSON_EDIT_TIPS1")
	self.btnSureLabel.text = __("SURE")

	print("--------------------------------------")

	self.textInput_.defaultText = __("PERSON_EDIT_TIPS2")

	self.cost:SetActive(false)
	self.btnSureLabel:X(0)
end

function FriendTeamBossEditNameWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.btnSure_).onClick = function ()
		self:onEdit()
	end

	self.eventProxy_:addEventListener(xyd.event.MODIFY_FRIEND_TEAM_BOSS_TEAM_INFO, handler(self, self.onSuccess))
end

function FriendTeamBossEditNameWindow:onEdit()
	if self:checkValid() then
		if xyd.getServerTime() - xyd.models.friendTeamBoss:getTeamInfo().last_modify_time < tonumber(xyd.tables.miscTable:getVal("govern_team_modify_interval")) then
			xyd.alert(xyd.AlertType.TIPS, __("FRIEND_TEAM_BOSS_MODIFY_LIMIT"))

			return
		end

		local wnd = xyd.WindowManager.get():getWindow("friend_team_boss_team_edit_window")

		if wnd then
			wnd:setTeamName(self.editLabel.text)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end
end

return FriendTeamBossEditNameWindow
