local BaseWindow = import(".BaseWindow")
local ArenaTeamFormationWindow = class("ArenaTeamFormationWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local Partner = import("app.models.Partner")

function ArenaTeamFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.hideBtn = false
	self.player_id = params.player_id
	self.hideBtn = params.hideBtn

	xyd.models.arenaTeam:reqEnemyInfo(self.player_id)
end

function ArenaTeamFormationWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject

	self.closeBtn:SetActive(false)

	local pIconGroup = mainGroup:NodeByName("pIconGroup").gameObject
	self.pIcon = PlayerIcon.new(pIconGroup)

	self.pIcon:SetActive(false)

	self.playerName = mainGroup:ComponentByName("playerName", typeof(UILabel))
	self.labelGroup1 = mainGroup:NodeByName("labelGroup1").gameObject
	self.labelText01 = self.labelGroup1:ComponentByName("labelText01", typeof(UILabel))
	self.labelId = self.labelGroup1:ComponentByName("labelId", typeof(UILabel))
	self.labelGroup2 = mainGroup:NodeByName("labelGroup2").gameObject
	self.labelText02 = self.labelGroup2:ComponentByName("labelText02", typeof(UILabel))
	self.labelGuild = self.labelGroup2:ComponentByName("labelGuild", typeof(UILabel))
	self.groupSignature_ = mainGroup:NodeByName("groupSignature_").gameObject
	self.labelSignature_ = self.groupSignature_:ComponentByName("labelSignature_", typeof(UILabel))
	self.labelFormation = mainGroup:ComponentByName("labelFormation", typeof(UILabel))
	self.powerGroup = mainGroup:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	local heros1 = mainGroup:NodeByName("heros1").gameObject

	for i = 1, 2 do
		self["heroGroup" .. tostring(i)] = heros1:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["hero" .. tostring(i)] = HeroIcon.new(self["heroGroup" .. tostring(i)])

		self["hero" .. tostring(i)]:SetActive(false)
	end

	local heros2 = mainGroup:NodeByName("heros2").gameObject

	for i = 3, 6 do
		self["heroGroup" .. tostring(i)] = heros2:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["hero" .. tostring(i)] = HeroIcon.new(self["heroGroup" .. tostring(i)])

		self["hero" .. tostring(i)]:SetActive(false)
	end

	self.btnGroup = mainGroup:NodeByName("btnGroup").gameObject
	self.btnDelMember_ = self.btnGroup:NodeByName("btnDelMember_").gameObject
	self.btnDelMember_LabelDisplay = self.btnDelMember_:ComponentByName("button_label", typeof(UILabel))
	self.btnChangeLeader_ = self.btnGroup:NodeByName("btnChangeLeader_").gameObject
	self.btnChangeLeader_LabelDisplay = self.btnChangeLeader_:ComponentByName("button_label", typeof(UILabel))
	self.btnAddFriend_ = mainGroup:NodeByName("btnAddFriend_").gameObject
	self.btnDelFriend_ = mainGroup:NodeByName("btnDelFriend_").gameObject
end

function ArenaTeamFormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()

	self.labelFormation.text = __("DEFFORMATION")
	self.btnChangeLeader_LabelDisplay.text = __("ARENA_TEAM_CHANGE_LEADER")
	self.btnDelMember_LabelDisplay.text = __("ARENA_TEAM_DEL_MEMBER")

	self:updateFriend()
end

function ArenaTeamFormationWindow:registerEvent()
	ArenaTeamFormationWindow.super.register(self)
	xyd.setDarkenBtnBehavior(self.btnAddFriend_, self, self.onAddFriendTouch)
	xyd.setDarkenBtnBehavior(self.btnDelFriend_, self, self.onDelFriendTouch)
	xyd.setDarkenBtnBehavior(self.btnDelMember_, self, self.onDelMemberTouch)
	xyd.setDarkenBtnBehavior(self.btnChangeLeader_, self, self.onChangeLeaderTouch)
	self.eventProxy_:addEventListener(xyd.event.FRIEND_APPLY, handler(self, self.onApply))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_DELETE, handler(self, self.onDelFriend))
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_OTHER_TEAM_INFO, handler(self, self.onGetData))

	UIEventListener.Get(self.groupSignature_).onClick = self.createReportBtn
end

function ArenaTeamFormationWindow:onGetData(event)
	local teamInfo = event.data.team_info

	if teamInfo then
		self.leaderID = teamInfo.leader_id
	end

	self.data = event.data.arena_info

	if self.data then
		self:initData()
		self:showBtn()
	end
end

function ArenaTeamFormationWindow:showBtn()
	self.btnChangeLeader_:SetActive(true)
	self.btnDelMember_:SetActive(true)

	if xyd.Global.playerID == self.leaderID then
		if xyd.Global.playerID == self.player_id then
			self.btnChangeLeader_:SetActive(false)
			self.btnDelMember_:SetActive(true)

			self.btnDelMember_LabelDisplay.text = __("ARENA_TEAM_QUIT")
		else
			self.btnChangeLeader_:SetActive(true)
			self.btnDelMember_:SetActive(true)
		end
	elseif xyd.Global.playerID == self.player_id then
		self.btnChangeLeader_:SetActive(false)
		self.btnDelMember_:SetActive(true)

		self.btnDelMember_LabelDisplay.text = __("ARENA_TEAM_QUIT")
	else
		self.btnChangeLeader_:SetActive(false)
		self.btnDelMember_:SetActive(false)
	end

	if self.hideBtn then
		self.btnChangeLeader_:SetActive(false)
		self.btnDelMember_:SetActive(false)
	end
end

function ArenaTeamFormationWindow:onChangeLeaderTouch()
	xyd.alert(xyd.AlertType.YES_NO, __("ARENA_TEAM_TRANSFER_LEADER"), function (yes)
		if yes then
			xyd.models.arenaTeam:changeTeamLeader(self.player_id)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end)
end

function ArenaTeamFormationWindow:onDelMemberTouch()
	if xyd.Global.playerID == self.leaderID then
		xyd.models.arenaTeam:removeMember(self.player_id)
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		xyd.alert(xyd.AlertType.YES_NO, __("ARENA_TEAM_QUIT_TEAM"), function (yes)
			if yes then
				xyd.models.arenaTeam:quit()
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end)
	end
end

function ArenaTeamFormationWindow:onApply()
	xyd.alert(xyd.AlertType.TIPS, __("FRIEND_APPLY_SUCCESS"))
	xyd.WindowManager.get():closeWindow(self.name_)
end

function ArenaTeamFormationWindow:onDelFriend()
	xyd.alert(xyd.AlertType.TIPS, __("FRIEND_DELETE_SUCCESS"))
	self:updateFriend()
end

function ArenaTeamFormationWindow:onAddFriendTouch()
	local flag = true
	local tips = ""

	if xyd.models.friend:checkIsFriend(self.player_id) then
		flag = false
		tips = __("PLAYER_IS_FRIEND")
	elseif xyd.models.friend:isFullFriends() then
		flag = false
		tips = __("SELF_MAX_FRIENDS")
	end

	if tips ~= "" then
		xyd.alert(xyd.AlertType.TIPS, tips)
	end

	if flag then
		xyd.models.friend:applyFriend(self.player_id)
	end
end

function ArenaTeamFormationWindow:onDelFriendTouch()
	if xyd.models.friend:checkIsFriend(self.player_id) then
		xyd.alert(xyd.AlertType.YES_NO, __("FRIEND_DEL_FRIEND"), function (yes)
			if yes then
				xyd.models.friend:delFriend(self.player_id)
				xyd.WindowManager.get():closeWindow(self.name_)
			end
		end)
	end
end

function ArenaTeamFormationWindow:initData()
	local data = self.data
	self.playerName.text = data.player_name
	self.labelText01.text = "ID"
	self.labelId.text = data.player_id

	if data.guild_name and data.guild_name ~= "" then
		self.labelText02.text = __("GUILD_TEXT12")
		self.labelGuild.text = data.guild_name
	else
		self.labelText02:SetActive(false)
		self.labelGuild:SetActive(false)
	end

	self.pIcon:SetActive(true)
	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev,
		avatar_frame_id = data.avatar_frame_id
	})

	local power = 0
	local petID = 0

	if data and data.pet then
		petID = data.pet.pet_id
	end

	local i = 1

	while i <= #data.partners do
		local pos = data.partners[i].pos
		local partner = Partner.new()

		partner:populate(data.partners[i])

		local partnerInfo = partner:getInfo()

		dump(partnerInfo)

		partnerInfo.noClick = true

		self["hero" .. tostring(pos)]:setInfo(partnerInfo, petID)
		self["hero" .. tostring(pos)]:SetActive(true)

		power = power + data.partners[i].power
		i = i + 1
	end

	if not data or not data.signature or #data.signature <= 0 then
		self.labelSignature_.text = __("PERSON_SIGNATURE_TEXT_4")
	else
		self.labelSignature_.text = data.signature
	end

	self.power.text = tostring(power)

	self.powerGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamFormationWindow:updateFriend()
	if self.player_id == xyd.Global.playerID then
		self.btnDelFriend_:SetActive(false)
		self.btnAddFriend_:SetActive(false)
	end

	if xyd.models.friend:checkIsFriend(self.player_id) then
		self.btnDelFriend_:SetActive(true)
		self.btnAddFriend_:SetActive(false)
	elseif self.player_id ~= xyd.Global.playerID then
		self.btnAddFriend_:SetActive(true)
		self.btnDelFriend_:SetActive(false)
	end
end

function ArenaTeamFormationWindow:creatReportBtn()
end

function ArenaTeamFormationWindow:showReport(flag)
	if flag == nil then
		flag = false
	end

	if not self.reportBtn then
		return
	end

	self.reportBtn:SetActive(flag)
end

return ArenaTeamFormationWindow
