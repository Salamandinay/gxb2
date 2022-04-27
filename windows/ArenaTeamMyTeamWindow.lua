local BaseWindow = import(".BaseWindow")
local ArenaTeamMyTeamWindow = class("ArenaTeamMyTeamWindow", BaseWindow)
local ArenaTeamMyTeamItem = class("ArenaTeamMyTeamItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamMyTeamWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfo_ = xyd.models.arenaTeam:getMyTeamInfo()
end

function ArenaTeamMyTeamWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	xyd.models.arenaTeam:reqApplyList()
end

function ArenaTeamMyTeamWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.labelTeamName_ = mainGroup:ComponentByName("labelTeamName_", typeof(UILabel))
	self.labelID_ = mainGroup:ComponentByName("labelID_", typeof(UILabel))
	local infoGroup = mainGroup:NodeByName("infoGroup").gameObject
	self.labelForce_ = infoGroup:ComponentByName("labelForce_", typeof(UILabel))
	self.groupMain_ = infoGroup:NodeByName("groupMain_").gameObject
	self.btnGroup = mainGroup:NodeByName("btnGroup").gameObject
	self.btnDissolve_ = self.btnGroup:NodeByName("btnDissolve_").gameObject
	self.btnDissolve_LabelDisplay = self.btnDissolve_:ComponentByName("button_label", typeof(UILabel))
	self.btnApply_ = self.btnGroup:NodeByName("btnApply_").gameObject
	self.btnApply_LabelDisplay = self.btnApply_:ComponentByName("button_label", typeof(UILabel))
	self.btnApply_RedIcon = self.btnApply_:ComponentByName("redIcon", typeof(UISprite))
	self.btnSubmit_ = self.btnGroup:NodeByName("btnSubmit_").gameObject
	self.btnSubmit_LabelDisplay = self.btnSubmit_:ComponentByName("button_label", typeof(UILabel))
end

function ArenaTeamMyTeamWindow:layout()
	self.btnSubmit_LabelDisplay.text = __("SUBMIT")
	self.btnApply_LabelDisplay.text = __("APPLY")

	self.btnApply_RedIcon:SetActive(false)

	self.btnDissolve_LabelDisplay.text = __("DISSOLVE")
	self.labelTeamName_.text = self.teamInfo_.team_name
	self.labelTitle.text = __("ARENA_TEAM_MY_TEAM_WINDOW")
	self.labelID_.text = "ID " .. tostring(self.teamInfo_.team_id)

	self:initTeam()
end

function ArenaTeamMyTeamWindow:initTeam()
	NGUITools.DestroyChildren(self.groupMain_.transform)

	self.teamInfo_ = xyd.models.arenaTeam:getMyTeamInfo()
	local leaderID = self.teamInfo_.leader_id
	local players = self.teamInfo_.players
	local i = 0

	while i < 3 do
		local info = players[i + 1]
		local item = nil

		if info then
			item = ArenaTeamMyTeamItem.new(self.groupMain_)

			item:setInfo(info, leaderID)
		else
			item = ArenaTeamMyTeamItem.new(self.groupMain_)

			item:setInfo(nil, leaderID)
		end

		i = i + 1
	end

	self.labelForce_.text = self.teamInfo_.power

	self:showBtn()
	self.groupMain_:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamMyTeamWindow:showBtn()
	local playerIds = self.teamInfo_.player_ids or {}

	if self.teamInfo_.leader_id ~= xyd.Global.playerID then
		self.btnSubmit_:SetActive(false)
		self.btnDissolve_:SetActive(false)
		self.btnApply_:SetActive(false)
	elseif #playerIds < 3 then
		self.btnSubmit_:SetActive(false)
	else
		self.btnSubmit_:SetActive(true)
		self.btnDissolve_:SetActive(true)
		self.btnApply_:SetActive(true)
	end

	self.btnGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamMyTeamWindow:registerEvent()
	ArenaTeamMyTeamWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnApply_, self, self.onApplyTouch)
	xyd.setDarkenBtnBehavior(self.btnDissolve_, self, self.onDissolveTouch)
	xyd.setDarkenBtnBehavior(self.btnSubmit_, self, self.onSubmitTouch)
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_ACCEPT, handler(self, self.onAccept))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_REMOVE_MEMBER, handler(self, self.onRemoveMember))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_QUIT, handler(self, self.onQuit))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_TRANSFER_LEADER, handler(self, self.onChangeLeader))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_APPLY_LIST, handler(self, self.updateRedPoint))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_REFUSE_APPLY, handler(self, self.updateRedPoint))
end

function ArenaTeamMyTeamWindow:onApplyTouch()
	xyd.WindowManager.get():openWindow("arena_team_apply_window", {})
end

function ArenaTeamMyTeamWindow:updateRedPoint()
	local list = xyd.models.arenaTeam:getApplyList()
	local flag = false

	if list and #list > 0 then
		flag = true
	end

	self.btnApply_RedIcon:SetActive(flag)
end

function ArenaTeamMyTeamWindow:onDissolveTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("ARENA_TEAM_DISSOLVE"), function (yes)
		if yes then
			xyd.models.arenaTeam:dissolveTeam()
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function ArenaTeamMyTeamWindow:onAccept()
	self:initTeam()
	self:updateRedPoint()
end

function ArenaTeamMyTeamWindow:onRemoveMember()
	self:initTeam()
end

function ArenaTeamMyTeamWindow:onChangeLeader()
	self:initTeam()
end

function ArenaTeamMyTeamWindow:onQuit()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ArenaTeamMyTeamWindow:onSubmitTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("ARENA_TEAM_SUBMIT"), function (yes)
		if yes then
			xyd.models.arenaTeam:joinTeam()
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function ArenaTeamMyTeamItem:ctor(parentGo)
	ArenaTeamMyTeamItem.super.ctor(self, parentGo)
	self:getUIComponent()
	self:registerEvent()
end

function ArenaTeamMyTeamItem:getUIComponent()
	local go = self.go
	local mainGroup = go:NodeByName("mainGroup").gameObject
	self.bg_ = mainGroup:ComponentByName("bg_", typeof(UISprite))
	self.labelTop_ = mainGroup:ComponentByName("labelTop_", typeof(UILabel))
	self.groupPlayer_ = mainGroup:NodeByName("groupPlayer_").gameObject
	self.groupIcon_ = self.groupPlayer_:NodeByName("groupIcon_").gameObject
	self.captainImg = self.groupIcon_:ComponentByName("captainImg", typeof(UISprite))
	self.labelForce_ = self.groupPlayer_:ComponentByName("labelForce_", typeof(UILabel))
	self.groupNone_ = mainGroup:NodeByName("groupNone_").gameObject
end

function ArenaTeamMyTeamItem:getPrefabPath()
	return "Prefabs/Components/arena_team_my_team_item"
end

function ArenaTeamMyTeamItem:setInfo(playerInfo, leaderID)
	self.playerInfo_ = playerInfo
	self.leaderID = leaderID

	self:layout()
end

function ArenaTeamMyTeamItem:layout()
	if self.playerInfo_ then
		self.groupPlayer_:SetActive(true)
		self.groupNone_:SetActive(false)

		self.labelTop_.text = self.playerInfo_.player_name
		self.labelForce_.text = self.playerInfo_.power
		local playerIcon = PlayerIcon.new(self.groupIcon_)
		local info = {
			avatarID = self.playerInfo_.avatar_id,
			lev = self.playerInfo_.lev,
			avatar_frame_id = self.playerInfo_.avatar_frame_id,
			callback = function ()
				xyd.WindowManager.get():openWindow("arena_team_formation_window", {
					player_id = self.playerInfo_.player_id
				})
			end
		}

		playerIcon:setInfo(info)
		self.captainImg:SetActive(false)

		if self.leaderID == self.playerInfo_.player_id then
			self.captainImg:SetActive(true)
		end

		if self.playerInfo_.player_id == xyd.Global.playerID then
			xyd.setUISpriteAsync(self.bg_, nil, "9gongge35", function ()
			end)
		else
			xyd.setUISpriteAsync(self.bg_, nil, "9gongge34", function ()
			end)
		end
	else
		self.groupPlayer_:SetActive(false)
		self.groupNone_:SetActive(true)

		self.labelTop_.text = __("ARENA_TEAM_WAITTING")
	end
end

function ArenaTeamMyTeamItem:registerEvent()
	if not self.playerInfo_ then
		UIEventListener.Get(self.groupNone_).onClick = handler(self, self.onInviteTouch)
	end
end

function ArenaTeamMyTeamItem:onInviteTouch()
	xyd.WindowManager.get():openWindow("arena_team_invite_window", {})
end

return ArenaTeamMyTeamWindow
