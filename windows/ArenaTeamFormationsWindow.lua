local BaseWindow = import(".BaseWindow")
local ArenaTeamFormationsWindow = class("ArenaTeamFormationsWindow", BaseWindow)
local ArenaTeamFormationItem = class("ArenaTeamFormationItem", import("app.components.BaseComponent"))
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamFormationsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.arenaTeam
	self.params = params
end

function ArenaTeamFormationsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self.model_:reqEnemyInfo(self.params.player_id)

	self.labelFormation.text = __("DEFFORMATION")

	self:registerEvent()
end

function ArenaTeamFormationsWindow:getUIComponent()
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

function ArenaTeamFormationsWindow:registerEvent()
	ArenaTeamFormationsWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_OTHER_TEAM_INFO, handler(self, self.onGetData))
	xyd.setDarkenBtnBehavior(self.btnBack, self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ArenaTeamFormationsWindow:onGetData(event)
	local data = event.data

	if not data.team_info then
		return
	end

	self.teamName.text = data.team_info.team_name
	local leaderId = data.team_info.leader_id
	local serverId = data.team_info.server_id

	for i = 1, #data.team_info.players do
		local player = data.team_info.players[i]

		if player.player_id == leaderId then
			serverId = player.server_id
		end
	end

	self.serverId.text = xyd.getServerNumber(serverId)

	NGUITools.DestroyChildren(self.container.transform)

	for i = 1, #data.team_info.players do
		local info = data.team_info.players[i]
		local item = ArenaTeamFormationItem.new(self.container)
		local isCaptain = data.team_info.leader_id == data.team_info.players[i].player_id

		if tonumber(i) == 3 then
			item:setInfo(info, i, true, isCaptain)
		else
			item:setInfo(info, i, nil, isCaptain)
		end
	end

	self.container:GetComponent(typeof(UILayout)):Reposition()

	self.power.text = data.team_info.power

	self.powerGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamFormationsWindow:willClose(params)
	NGUITools.DestroyChildren(self.container.transform)
	BaseWindow.willClose(self, params)
end

function ArenaTeamFormationItem:ctor(parentGO)
	ArenaTeamFormationItem.super.ctor(self, parentGO)
end

function ArenaTeamFormationItem:getPrefabPath()
	return "Prefabs/Components/arena_team_formation_item"
end

function ArenaTeamFormationItem:initUI()
	ArenaTeamFormationItem.super.initUI(self)

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

		self["hero" .. tostring(i)]:SetActive(false)
	end

	for i = 3, 6 do
		local group = heroGroup2:NodeByName("heroGroup" .. tostring(i)).gameObject
		self["hero" .. tostring(i)] = HeroIcon.new(group)

		self["hero" .. tostring(i)]:SetActive(false)
	end

	self.cover1 = infoGroup:NodeByName("cover1").gameObject
	self.cover2 = infoGroup:NodeByName("cover2").gameObject
end

function ArenaTeamFormationItem:setInfo(params, index, hide, isCaptain)
	self.data = params
	self.playerName.text = params.player_name

	xyd.setUISpriteAsync(self.teamImg, nil, "arena_3v3_t" .. tostring(index), function ()
	end)
	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id
	})

	local petID = 0

	if params and params.pet then
		petID = params.pet.pet_id
	end

	if isCaptain and isCaptain ~= 0 then
		self.pIcon:setCaptain(true)
	end

	if hide and hide ~= 0 then
		self.cover1:SetActive(true)
		self.cover2:SetActive(true)
	else
		for i = 1, #params.partners do
			local np = Partner.new()

			np:populate(params.partners[i])
			self["hero" .. tostring(i)]:setInfo(np:getInfo(), petID)
			self["hero" .. tostring(i)]:SetActive(true)
		end

		self.cover1:SetActive(false)
		self.cover2:SetActive(false)
	end
end

return ArenaTeamFormationsWindow
