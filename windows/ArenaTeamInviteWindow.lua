local BaseWindow = import(".BaseWindow")
local ArenaTeamInviteWindow = class("ArenaTeamInviteWindow", BaseWindow)
local ArenaTeamInviteItem = class("ArenaTeamInviteItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamInviteWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfos_ = {}
end

function ArenaTeamInviteWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamInviteWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.groupNone_ = mainGroup:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.scroller_ = mainGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupMain_ = mainGroup:NodeByName("scroller_/groupMain_").gameObject
end

function ArenaTeamInviteWindow:layout()
	self.labelTitle.text = __("ARENA_TEAM_INVITE_WINDOW")
	self.labelNoneTips_.text = __("ARENA_TEAM_NONE_1")
end

function ArenaTeamInviteWindow:registerEvent()
	ArenaTeamInviteWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_INVITE_PLAYERS, handler(self, self.initList))
end

function ArenaTeamInviteWindow:onDelAllTouch()
end

function ArenaTeamInviteWindow:playOpenAnimation(callback)
	local call = nil

	function call()
		if callback then
			callback()
		end

		xyd.models.arenaTeam:getInvitePlayers()
	end

	BaseWindow.playOpenAnimation(self, call)
end

function ArenaTeamInviteWindow:initList(event)
	local list = event.data.players or {}

	for i = 1, #list do
		local item = ArenaTeamInviteItem.new(self.groupMain_)

		item:setInfo(list[i], self.scroller_)
	end

	self.groupMain_:GetComponent(typeof(UIGrid)):Reposition()

	if #list <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end
end

function ArenaTeamInviteWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)
	NGUITools.DestroyChildren(self.groupMain_.transform)
end

function ArenaTeamInviteItem:ctor(parentGO)
	ArenaTeamInviteItem.super.ctor(self, parentGO)
	self:registerEvent()
end

function ArenaTeamInviteItem:initUI()
	ArenaTeamInviteItem.super.initUI(self)

	local go = self.go
	local mainGroup = go:NodeByName("mainGroup").gameObject
	self.groupIcon_ = mainGroup:NodeByName("groupIcon_").gameObject
	local levGroup = mainGroup:NodeByName("levGroup").gameObject
	self.labeLev_ = levGroup:ComponentByName("labeLev_", typeof(UILabel))
	self.labelName_ = mainGroup:ComponentByName("labelName_", typeof(UILabel))
	self.labelForce_ = mainGroup:ComponentByName("labelForce_", typeof(UILabel))
	self.groupTouch_ = mainGroup:NodeByName("groupTouch_").gameObject
	self.groupApply_ = mainGroup:NodeByName("groupApply_").gameObject
	self.btnRefuse_ = self.groupApply_:NodeByName("btnRefuse_").gameObject
	self.btnSure_ = self.groupApply_:NodeByName("btnSure_").gameObject
	self.groupInvite_ = mainGroup:NodeByName("groupInvite_").gameObject
	self.btnInvite_ = self.groupInvite_:NodeByName("btnInvite_").gameObject
	self.btnInvite_LabelDisplay = self.btnInvite_:ComponentByName("button_label", typeof(UILabel))
end

function ArenaTeamInviteItem:getPrefabPath()
	return "Prefabs/Components/arena_team_apply_item"
end

function ArenaTeamInviteItem:setInfo(info, parentScroll)
	self.data_ = info
	self.parentScroll = parentScroll

	self:layout()
end

function ArenaTeamInviteItem:layout()
	self.labelName_.text = self.data_.player_name
	self.labeLev_.text = self.data_.lev
	self.labelForce_.text = self.data_.power

	NGUITools.DestroyChildren(self.groupIcon_.transform)

	local playerIcon = PlayerIcon.new(self.groupIcon_)
	local info = {
		avatarID = self.data_.avatar_id,
		avatar_frame_id = self.data_.avatar_frame_id
	}

	playerIcon:setInfo(info)
	self.groupApply_:SetActive(false)
	self.groupInvite_:SetActive(true)

	self.btnInvite_LabelDisplay.text = __("ARENA_TEAM_INVITE")

	if self.parentScroll then
		xyd.setDragScrollView(self.groupTouch_, self.parentScroll)
	end
end

function ArenaTeamInviteItem:registerEvent()
	UIEventListener.Get(self.groupTouch_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("arena_team_formation_window", {
			hideBtn = true,
			player_id = self.data_.player_id
		})
	end)

	xyd.setDarkenBtnBehavior(self.btnInvite_, self, self.onInviteTouch)
end

function ArenaTeamInviteItem:onInviteTouch()
	xyd.setUISpriteAsync(self.btnInvite_:GetComponent(typeof(UISprite)), nil, "white_btn_60_60", function ()
	end)

	self.btnInvite_LabelDisplay.text = __("ARENA_TEAM_HAS_INVITE")
	self.btnInvite_LabelDisplay.color = Color.New2(1012112383)
	self.btnInvite_LabelDisplay.effectColor = Color.New2(4294967295.0)

	xyd.setTouchEnable(self.btnInvite_, false)
	xyd.models.arenaTeam:inviteMember(self.data_.player_id)
end

return ArenaTeamInviteWindow
