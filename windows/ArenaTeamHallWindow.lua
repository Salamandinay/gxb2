local BaseWindow = import(".BaseWindow")
local ArenaTeamHallWindow = class("ArenaTeamHallWindow", BaseWindow)
local ArenaTeamHallItem = class("ArenaTeamHallItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamHallWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.teamInfos_ = {}
	self.applyID_ = 0
end

function ArenaTeamHallWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	xyd.models.arenaTeam:getRecommendTeams()
	xyd.models.arenaTeam:reqInviteTeams()
end

function ArenaTeamHallWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	self.labelTitle = mainGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.groupNone_ = mainGroup:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.scroller_ = mainGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.groupMain_ = mainGroup:NodeByName("scroller_/groupMain_").gameObject
	local groupBot = mainGroup:NodeByName("groupBot").gameObject
	self.btnCreate_ = groupBot:NodeByName("btnCreate_").gameObject
	self.btnCreate_LabelDisplay = self.btnCreate_:ComponentByName("button_label", typeof(UILabel))
	self.btnInvite_ = groupBot:NodeByName("btnInvite_").gameObject
	self.btnInvite_RedPoint = self.btnInvite_:NodeByName("redPoint").gameObject
	self.btnInvite_LabelDisplay = self.btnInvite_:ComponentByName("button_label", typeof(UILabel))
	self.btnRefresh_ = groupBot:NodeByName("btnRefresh_").gameObject
	self.btnRefresh_LabelDisplay = self.btnRefresh_:ComponentByName("button_label", typeof(UILabel))
	local groupTop = mainGroup:NodeByName("groupTop").gameObject
	self.textEdit_ = groupTop:NodeByName("textEdit_").gameObject
	self.editLabel = self.textEdit_:ComponentByName("editLabel", typeof(UILabel))
	self.editLabel.text = ""

	self.editLabel:SetActive(false)

	self.promptDisplay = self.textEdit_:ComponentByName("promptDisplay", typeof(UILabel))
	self.numberKeyBoard = groupTop:NodeByName("number_keyboard").gameObject

	for i = 0, 9 do
		self["btn" .. tostring(i) .. "_"] = self.numberKeyBoard:NodeByName("btn" .. tostring(i) .. "_").gameObject
	end

	self.btnOK_ = self.numberKeyBoard:NodeByName("btnOK_").gameObject
	self.btnC_ = self.numberKeyBoard:NodeByName("btnC_").gameObject
	self.displayBg1 = self.numberKeyBoard:NodeByName("displayBg1").gameObject
	self.btnApply_ = groupTop:NodeByName("btnApply_").gameObject
	self.btnApply_LabelDisplay = self.btnApply_:ComponentByName("button_label", typeof(UILabel))

	self.numberKeyBoard:SetActive(false)
end

function ArenaTeamHallWindow:layout()
	self.btnApply_LabelDisplay.text = __("APPLY")
	self.btnCreate_LabelDisplay.text = __("ARENA_TEAM_CREATE")
	self.btnInvite_LabelDisplay.text = __("ARENA_TEAM_INVITE")
	self.btnRefresh_LabelDisplay.text = __("REFRESH")
	self.promptDisplay.text = __("INPUT_ID")
	self.labelTitle.text = __("ARENA_TEAM_HALL_WINDOW")
	self.labelNoneTips_.text = __("ARENA_TEAM_NO_TEAM")
end

function ArenaTeamHallWindow:registerEvent()
	ArenaTeamHallWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnCreate_, self, handler(self, self.onCreateTouch))
	xyd.setDarkenBtnBehavior(self.btnApply_, self, handler(self, self.onApplyTouch))
	xyd.setDarkenBtnBehavior(self.btnInvite_, self, handler(self, self.onInviteTouch))
	xyd.setDarkenBtnBehavior(self.btnRefresh_, self, handler(self, self.onRefreshTouch))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_RECOMMEND_TEAMS, handler(self, self.onGetRecommendTeams))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_GET_INVITE_TEAMS, handler(self, self.updateRedPoint))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_REFUSE_INVITATION, handler(self, self.updateRedPoint))
	self.eventProxy_:addEventListener(xyd.event.ARENA_TEAM_APPLY_TEAM, handler(self, self.onApplyTeam))

	for i = 0, 9 do
		local btn = self["btn" .. tostring(i) .. "_"]

		xyd.setDarkenBtnBehavior(btn, self, function ()
			self:onNum(i)
		end)
	end

	xyd.setDarkenBtnBehavior(self.btnOK_, self, function ()
		self:onOk()
	end)
	xyd.setDarkenBtnBehavior(self.btnC_, self, function ()
		self:onC()
	end)

	UIEventListener.Get(self.displayBg1).onClick = handler(self, self.onOk)
	UIEventListener.Get(self.textEdit_).onClick = handler(self, self.showKeyboard)
end

function ArenaTeamHallWindow:showKeyboard()
	self.numberKeyBoard:SetActive(true)
end

function ArenaTeamHallWindow:onC()
	self.editLabel.text = ""

	self.promptDisplay:SetActive(true)
	self.editLabel:SetActive(false)
end

function ArenaTeamHallWindow:onOk()
	self.numberKeyBoard:SetActive(false)
end

function ArenaTeamHallWindow:onNum(num)
	self.editLabel:SetActive(true)
	self.promptDisplay:SetActive(false)

	if #self.editLabel.text <= 0 then
		self.editLabel.text = tostring(num)
	elseif #self.editLabel.text >= 9 then
		return
	else
		local cur_num = tonumber(self.editLabel.text)

		if cur_num == 0 then
			self.editLabel.text = tostring(num)
		else
			self.editLabel.text = self.editLabel.text .. tostring(num)
		end
	end
end

function ArenaTeamHallWindow:onCreateTouch()
	xyd.WindowManager.get():openWindow("arena_team_create_window", {})
end

function ArenaTeamHallWindow:onApplyTeam(event)
	local id = event.data.team_id

	if id == self.applyID_ then
		self.applyID_ = 0

		xyd.alert(xyd.AlertType.TIPS, __("ARENA_TEAM_APPLY_SUCCESS"))
	end
end

function ArenaTeamHallWindow:updateRedPoint()
	local invitations = xyd.models.arenaTeam:getInviteTeams()

	if invitations[1] then
		self.btnInvite_RedPoint:SetActive(true)
	else
		self.btnInvite_RedPoint:SetActive(false)
	end
end

function ArenaTeamHallWindow:onApplyTouch()
	local teamID = tonumber(self.editLabel.text)

	if not teamID then
		xyd.alert(xyd.AlertType.TIPS, __("INPUT_NULL"))

		return
	end

	self.applyID_ = teamID

	xyd.models.arenaTeam:applyTeam(teamID)
end

function ArenaTeamHallWindow:onInviteTouch()
	xyd.WindowManager.get():openWindow("arena_team_invitation_window", {})
end

function ArenaTeamHallWindow:onRefreshTouch()
	xyd.models.arenaTeam:getRecommendTeams()
end

function ArenaTeamHallWindow:onGetRecommendTeams(event)
	self.teamInfos_ = event.data.team_infos

	self:initList()
end

function ArenaTeamHallWindow:playOpenAnimations(callback)
	local call = nil

	function call()
		if callback then
			callback()
		end

		self:initList()
	end

	BaseWindow.playOpenAnimations(self, call)
end

function ArenaTeamHallWindow:initList()
	local list = {}

	NGUITools.DestroyChildren(self.groupMain_.transform)

	for i = 1, #self.teamInfos_ do
		local item = ArenaTeamHallItem.new(self.groupMain_)
		local info = self.teamInfos_[i]

		item:setInfo(info)
		xyd.setDragScrollView(item.go, self.scroller_)
	end

	local layout = self.groupMain_:GetComponent(typeof(UIGrid))

	layout:Reposition()

	if #self.teamInfos_ <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end
end

function ArenaTeamHallWindow:willClose(params, skipAnimation, force)
	BaseWindow.willClose(self, params, skipAnimation, force)
	NGUITools.DestroyChildren(self.groupMain_.transform)
end

function ArenaTeamHallItem:ctor(parentGO)
	ArenaTeamHallItem.super.ctor(self, parentGO)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ArenaTeamHallItem:getPrefabPath()
	return "Prefabs/Components/arena_team_hall_item"
end

function ArenaTeamHallItem:getUIComponent()
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
end

function ArenaTeamHallItem:layout()
	self.btnApply_LabelDisplay.text = __("APPLY")
	self.labelNeedForce_.text = __("ARENA_TEAM_NEED_FORCE")

	self.groupInvite_:SetActive(false)
end

function ArenaTeamHallItem:setInfo(data)
	self.data_ = data

	self:updateLayout()
end

function ArenaTeamHallItem:updateLayout()
	self.labelName_.text = self.data_.team_name
	self.labelForce_.text = self.data_.power or "0"
	self.labelNeedForceNum_.text = self.data_.need_power or "0"

	self:initTeamIcons()
end

function ArenaTeamHallItem:initTeamIcons()
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

function ArenaTeamHallItem:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnApply_, self, self.onApplyTouch)

	UIEventListener.Get(self.go).onClick = handler(self, self.onTouch)
end

function ArenaTeamHallItem:onTouch()
	xyd.WindowManager.get():openWindow("arena_team_formations_window", {
		player_id = self.data_.leader_id
	})
end

function ArenaTeamHallItem:onApplyTouch()
	xyd.models.arenaTeam:applyTeam(self.data_.team_id)

	local btn_sprite = self.btnApply_:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(btn_sprite, nil, "white_btn_60_60", function ()
	end)

	self.btnApply_LabelDisplay.color = Color.New2(1012112383)
	self.btnApply_LabelDisplay.effectColor = Color.New2(4294967295.0)
	self.btnApply_LabelDisplay.text = __("HAS_APPLY")

	xyd.setTouchEnable(self.btnApply_, false)
end

return ArenaTeamHallWindow
