local BaseWindow = import(".BaseWindow")
local ArenaTeamInvitationWindow = class("ArenaTeamInvitationWindow", BaseWindow)
local ArenaTeamInvitationItem = class("ArenaTeamInvitationItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamInvitationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfos_ = {}
end

function ArenaTeamInvitationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamInvitationWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.groupTop = mainGroup:NodeByName("groupTop").gameObject
	self.labelNum_ = self.groupTop:ComponentByName("labelNum_", typeof(UILabel))
	self.btnDelAll_ = self.groupTop:NodeByName("btnDelAll_").gameObject
	self.btnDelAll_LabelDisplay = self.btnDelAll_:ComponentByName("button_label", typeof(UILabel))
	self.groupNone_ = mainGroup:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.groupMain_ = mainGroup:NodeByName("scroller_/groupMain_").gameObject
end

function ArenaTeamInvitationWindow:layout()
	self.btnDelAll_LabelDisplay.text = __("ARENA_TEAM_DEL_ALL")
	self.labelTitle.text = __("ARENA_TEAM_INVITATION_WINDOW")
	self.labelNum_.text = __("ARENA_TEAM_INVITATION_1", 0)
	self.labelNoneTips_.text = __("ARENA_TEAM_NO_INVITATION")
end

function ArenaTeamInvitationWindow:registerEvent()
	ArenaTeamInvitationWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnDelAll_, self, self.onDelAllTouch)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_INVITE_TEAMS, handler(self, self.initList))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_ACCEPT_INVITATION, handler(self, self.acceptInvation))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_REFUSE_INVITATION, handler(self, self.initList))
end

function ArenaTeamInvitationWindow:onDelAllTouch()
	local teamIDs = {}
	local list = xyd.models.arenaTeam:getInviteTeams()

	for i = 1, #list do
		table.insert(teamIDs, list[i].team_id)
	end

	xyd.models.arenaTeam:refuseInvitation(teamIDs)
end

function ArenaTeamInvitationWindow:acceptInvation()
	xyd.WindowManager.get():closeWindow(self.name_)
	xyd.WindowManager.get():closeWindow("arena_team_hall_window")
	xyd.WindowManager.get():openWindow("arena_team_my_team_window", {})
end

function ArenaTeamInvitationWindow:playOpenAnimation(callback)
	local call = nil

	function call()
		if callback then
			callback()
		end

		self:initList()
	end

	BaseWindow.playOpenAnimation(self, call)
end

function ArenaTeamInvitationWindow:initList()
	NGUITools.DestroyChildren(self.groupMain_.transform)

	local list = xyd.models.arenaTeam:getInviteTeams()

	for i = 1, #list do
		local item = ArenaTeamInvitationItem.new(self.groupMain_)

		item:setInfo(list[i])
	end

	self.labelNum_.text = __("ARENA_TEAM_INVITATION_1", #list)

	if #list <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
		self.groupMain_:GetComponent(typeof(UIGrid)):Reposition()
	end
end

function ArenaTeamInvitationWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)
	NGUITools.DestroyChildren(self.groupMain_.transform)
end

function ArenaTeamInvitationItem:ctor(parentGO)
	ArenaTeamInvitationItem.super.ctor(self, parentGO)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamInvitationItem:getPrefabPath()
	return "Prefabs/Components/arena_team_hall_item"
end

function ArenaTeamInvitationItem:getUIComponent()
	local go = self.go
	local mainGroup = go:NodeByName("mainGroup").gameObject
	local infoGroup = mainGroup:NodeByName("infoGroup").gameObject
	self.labelName_ = infoGroup:ComponentByName("labelName_", typeof(UILabel))
	self.labelForce_ = infoGroup:ComponentByName("labelForce_", typeof(UILabel))
	self.groupTeam_ = mainGroup:NodeByName("groupTeam_").gameObject

	for i = 1, 3 do
		self["groupMember" .. tostring(i)] = self.groupTeam_:NodeByName("groupMember" .. tostring(i)).gameObject
	end

	self.labelNeedForce_ = mainGroup:ComponentByName("labelNeedForce_", typeof(UILabel))
	self.labelNeedForceNum_ = mainGroup:ComponentByName("labelNeedForceNum_", typeof(UILabel))
	self.groupTouch_ = mainGroup:NodeByName("groupTouch_").gameObject
	self.btnApply_ = mainGroup:NodeByName("btnApply_").gameObject
	self.btnApply_LabelDisplay = self.btnApply_:ComponentByName("button_label", typeof(UILabel))
	self.groupInvite_ = mainGroup:NodeByName("groupInvite_").gameObject
	self.btnRefuse_ = self.groupInvite_:NodeByName("btnRefuse_").gameObject
	self.btnSure_ = self.groupInvite_:NodeByName("btnSure_").gameObject
end

function ArenaTeamInvitationItem:layout()
	self.btnApply_LabelDisplay.text = __("APPLY")
	self.labelNeedForce_.text = __("ARENA_TEAM_NEED_FORCE")

	self.groupInvite_:SetActive(true)
	self.btnApply_:SetActive(false)
	self.groupTouch_:SetActive(true)
end

function ArenaTeamInvitationItem:registerEvent()
	UIEventListener.Get(self.groupTouch_).onClick = handler(self, self.onTouch)

	xyd.setDarkenBtnBehavior(self.btnRefuse_, self, self.onRefuseTouch)
	xyd.setDarkenBtnBehavior(self.btnSure_, self, self.onSureTouch)
end

function ArenaTeamInvitationItem:onTouch()
	xyd.WindowManager.get():openWindow("arena_team_formations_window", {
		player_id = self.data_.leader_id
	})
end

function ArenaTeamInvitationItem:initTeamIcons()
	local playerInfos = self.data_.player_infos or {}
	local i = 0

	while i < #playerInfos do
		local group = self["groupMember" .. tostring(i + 1)]
		local playerIcon = PlayerIcon.new(group)
		local info = {
			avatarID = playerInfos[i + 1].avatar_id,
			lev = playerInfos[i + 1].lev,
			avatar_frame_id = playerInfos[i + 1].avatar_frame_id
		}

		playerIcon:setInfo(info)

		local isLeader = self.data_.leader_id == playerInfos[i + 1].player_id

		playerIcon:setCaptain(isLeader)

		i = i + 1
	end
end

function ArenaTeamInvitationItem:setInfo(data)
	self.data_ = data

	self:updateLayout()
end

function ArenaTeamInvitationItem:updateLayout()
	self.labelName_.text = self.data_.team_name
	self.labelForce_.text = self.data_.power or "0"
	self.labelNeedForceNum_.text = self.data_.need_power or "0"

	self:initTeamIcons()
end

function ArenaTeamInvitationItem:onRefuseTouch()
	xyd.models.arenaTeam:refuseInvitation({
		self.data_.team_id
	})
end

function ArenaTeamInvitationItem:onSureTouch()
	xyd.models.arenaTeam:acceptInvitation(self.data_.team_id)

	local wnd = xyd.WindowManager.get():getWindow("arena_team_invitation_window")

	if wnd then
		wnd:initList()
	end

	local wnd2 = xyd.WindowManager.get():getWindow("arena_team_hall_window")

	if wnd2 then
		wnd2:updateRedPoint()
	end
end

return ArenaTeamInvitationWindow
