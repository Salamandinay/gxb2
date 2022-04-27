local BaseWindow = import(".BaseWindow")
local FriendTeamBossTeamFormationWindow = class("FriendTeamBossTeamFormationWindow", BaseWindow)
local FriendTeamBossTeamFormationItem = class("FriendTeamBossTeamFormationItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function FriendTeamBossTeamFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.friendTeamBoss
end

function FriendTeamBossTeamFormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local data = self.params_

	if data.team_id then
		self.model_:reqOtherTeamInfo(data.team_id)
	elseif data.player_id then
		self.model_:reqInfo(data.player_id)
	end

	self.labelFormation.text = __("DEFFORMATION")

	self:registerEvent()
end

function FriendTeamBossTeamFormationWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("groupAction").gameObject
	self.btnBack = mainGroup:NodeByName("btnBack").gameObject
	self.teamName = mainGroup:ComponentByName("teamName", typeof(UILabel))
	self.guild = mainGroup:ComponentByName("guild", typeof(UILabel))
	self.labelFormation = mainGroup:ComponentByName("labelFormation", typeof(UILabel))
	self.serverInfo = mainGroup:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverGroup/serverId", typeof(UILabel))
	self.powerGroup = mainGroup:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	self.container = mainGroup:NodeByName("container").gameObject
end

function FriendTeamBossTeamFormationWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.FRIEND_TEAM_BOSS_GET_TEAM_DETAIL, self.onGetData, self)
	self.eventProxy_:addEventListener(xyd.event.GET_FRIEND_TEAM_BOSS_INFO, self.onGetData, self)
	xyd.setDarkenBtnBehavior(self.btnBack, self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function FriendTeamBossTeamFormationWindow:onGetData(event)
	local data = event.data

	if not data.team_info then
		return
	end

	self.teamName.text = __("FRIEND_TEAM_BOSS_TEAM_NAME", data.team_info.team_name)

	self.serverInfo:SetActive(false)

	local infos = data.team_info.arena_defence_info
	local leaderId = data.team_info.leader_id

	for i = 1, #infos do
		local info = infos[i]
		local item = FriendTeamBossTeamFormationItem.new(self.container)
		local isCaptain = leaderId == infos[i].player_id

		item:setInfo(info, i, nil, isCaptain)
	end

	self.powerGroup:SetActive(false)
	self.container:GetComponent(typeof(UILayout)):Reposition()
end

function FriendTeamBossTeamFormationItem:ctor(parentGO)
	FriendTeamBossTeamFormationItem.super.ctor(self, parentGO)
end

function FriendTeamBossTeamFormationItem:getPrefabPath()
	return "Prefabs/Components/arena_team_formation_item"
end

function FriendTeamBossTeamFormationItem:initUI()
	FriendTeamBossTeamFormationItem.super.initUI(self)

	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.pIconGroup = go:NodeByName("pIconGroup").gameObject
	self.pIcon = PlayerIcon.new(self.pIconGroup)
	self.teamImg = go:ComponentByName("teamImg", typeof(UISprite))
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	local infoGroup = go:NodeByName("infoGroup").gameObject
	local heroGroup1 = infoGroup:NodeByName("heroGroup1").gameObject
	local heroGroup2 = infoGroup:NodeByName("heroGroup2").gameObject

	for i = 1, 2 do
		local group = heroGroup1:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["hero" .. tostring(i)] = HeroIcon.new(group)
	end

	for i = 3, 6 do
		local group = heroGroup2:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["hero" .. tostring(i)] = HeroIcon.new(group)
	end

	self.cover1 = infoGroup:NodeByName("cover1").gameObject
	self.cover2 = infoGroup:NodeByName("cover2").gameObject

	self.cover1:SetActive(false)
	self.cover2:SetActive(false)
end

function FriendTeamBossTeamFormationItem:setInfo(params, index, hide, isCaptain)
	hide = false
	self.data = params
	self.playerName.text = self.data.player_name

	xyd.setUISpriteAsync(self.teamImg, nil, "arena_3v3_t" .. tostring(index))
	self.pIcon:setInfo({
		avatar_id = self.data.avatar_id,
		lev = self.data.lev,
		avatar_frame_id = self.data.avatar_frame_id
	})

	local petID = 0

	if self.data and self.data.pet then
		petID = self.data.pet.pet_id
	end

	if isCaptain then
		self.pIcon:setCaptain(true)
	end

	if hide then
		self.cover1:SetActive(true)
		self.cover2:SetActive(true)
	else
		for i = 1, #params.partners do
			local np = Partner.new()

			np:populate(params.partners[i])
			self["hero" .. tostring(i)]:setInfo(np:getInfo(), petID)
			self["hero" .. tostring(i)]:SetActive(true)
		end

		for i = #params.partners + 1, 6 do
			self["hero" .. tostring(i)]:SetActive(false)
		end
	end
end

return FriendTeamBossTeamFormationWindow
