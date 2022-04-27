local BaseWindow = import(".BaseWindow")
local Arena3v3FormationWindow = class("Arena3v3FormationWindow", BaseWindow)
local HeroIcon = import("app.components.HeroIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local Partner = import("app.models.Partner")

function Arena3v3FormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.model_ = params.model or xyd.models.arena3v3
	self.player_id = params.player_id
	self.is_robot = params.is_robot
	self.battleType = params.battle_type or xyd.BattleType.ARENA_3v3_DEF
end

function Arena3v3FormationWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponents()
	self.model_:reqEnemyInfo(self.player_id)
	self:registerEvent()

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		self.groupPower_:SetActive(false)
		self.groupMask:SetActive(false)

		self.labelFormation.text = __("DEFFORMATION_2")
	else
		self.labelFormation.text = __("DEFFORMATION")
	end
end

function Arena3v3FormationWindow:getUIComponents()
	local trans = self.window_.transform
	self.closeBtn = trans:NodeByName("closeBtn").gameObject
	local pIcon = trans:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIcon)
	self.playerName = trans:ComponentByName("playerName", typeof(UILabel))
	self.labelId = trans:ComponentByName("labelId", typeof(UILabel))
	self.labelGuild = trans:ComponentByName("labelGuild", typeof(UILabel))
	self.id = trans:ComponentByName("id", typeof(UILabel))
	self.guild = trans:ComponentByName("guild", typeof(UILabel))
	self.groupSignature_ = trans:NodeByName("groupSignature_").gameObject
	self.labelSignature_ = self.groupSignature_:ComponentByName("labelSignature_", typeof(UILabel))
	self.labelFormation = trans:ComponentByName("labelFormation", typeof(UILabel))
	self.serverInfo = trans:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.groupPower_ = trans:NodeByName("groupPower_").gameObject
	self.power = self.groupPower_:ComponentByName("power", typeof(UILabel))
	self.formation = trans:NodeByName("formation").gameObject
	local cnt = 1

	for i = 1, 3 do
		self["formation" .. i] = self.formation:NodeByName("formation" .. i).gameObject
		local grid1 = self["formation" .. i]:NodeByName("grid1").gameObject
		local grid2 = self["formation" .. i]:NodeByName("grid2").gameObject

		for j = 1, 2 do
			local root = grid1:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		for j = 3, 6 do
			local root = grid2:NodeByName("hero" .. cnt).gameObject
			self["hero" .. cnt] = HeroIcon.new(root)

			self["hero" .. cnt]:SetActive(false)

			cnt = cnt + 1
		end

		if i == 3 then
			self.groupMask = self["formation" .. i]:NodeByName("groupMask").gameObject
		end
	end
end

function Arena3v3FormationWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.ARENA_3v3_GET_ENEMY_INFO, self.onGetData, self)
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_GET_ENEMY_INFO, self.onGetData, self)

	UIEventListener.Get(self.groupSignature_).onClick = handler(self, self.creatReportBtn)
end

function Arena3v3FormationWindow:onGetData(event)
	self.dataInfo = event.data
	local data = event.data
	local teams = data.teams
	self.playerName.text = data.player_name
	self.serverId.text = xyd.getServerNumber(data.server_id)
	self.labelId.text = "ID"
	self.id.text = data.player_id

	if data.guild_name and data.guild_name ~= "" then
		self.labelGuild.text = __("GUILD_TEXT12")
		self.guild.text = data.guild_name
	end

	self.pIcon:setInfo({
		avatarID = data.avatar_id,
		lev = data.lev,
		avatar_frame_id = data.avatar_frame_id
	})

	local len = #teams - 1
	local isHideLev = false

	if self.battleType == xyd.BattleType.ARENA_ALL_SERVER_DEF then
		isHideLev = true
		len = #teams
	end

	for i = 1, len do
		local petID = 0

		if teams[i] and teams[i].pet then
			petID = teams[i].pet.pet_id
		end

		for j = 1, #teams[i].partners do
			local index = (i - 1) * 6 + teams[i].partners[j].pos
			local partner = Partner.new()

			partner:populate(teams[i].partners[j])

			local partnerInfo = partner:getInfo()
			partnerInfo.noClick = true
			partnerInfo.hideLev = isHideLev
			partnerInfo.scale = 0.8

			self["hero" .. index]:setInfo(partnerInfo, petID)
			self["hero" .. index]:SetActive(true)
		end
	end

	if data.signature and data.signature ~= "" then
		self.labelSignature_.text = data.signature
	else
		self.labelSignature_.text = __("PERSON_SIGNATURE_TEXT_4")
	end

	self.power.text = data.power
end

function Arena3v3FormationWindow:creatReportBtn()
end

function Arena3v3FormationWindow:showReport(flag)
end

return Arena3v3FormationWindow
