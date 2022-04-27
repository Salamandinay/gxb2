local BaseWindow = import(".BaseWindow")
local GuildCompetitionFormationWindow = class("GuildCompetitionFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function GuildCompetitionFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fortId = 1
	self.fortId = params.fort_id
	self.playerId = params.player_id
	self.playername = params.player_name
	self.avatarFrame = params.avatar_frame
	self.avatarId = params.avatar_id
	self.info = params.info
	self.total_harm = params.total_harm
	self.lev = params.lev
	self.pet_id = params.pet_id
end

function GuildCompetitionFormationWindow:initWindow()
	GuildCompetitionFormationWindow.super.initWindow(self)
	self:getUIComponents()
	self:layout()
end

function GuildCompetitionFormationWindow:getUIComponents()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupMain").gameObject
	self.groupMain = groupMain
	local pIconContainer = groupMain:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.playerName = groupMain:ComponentByName("playerName", typeof(UILabel))
	self.labelFormation = groupMain:ComponentByName("labelFormation", typeof(UILabel))
	local groupIDs = groupMain:NodeByName("groupIDs").gameObject
	self.labelText01 = groupIDs:ComponentByName("labelText01", typeof(UILabel))
	self.labelId = groupIDs:ComponentByName("labelId", typeof(UILabel))
	local groupBuff = groupMain:NodeByName("groupBuff").gameObject
	self.labelBuff = groupBuff:ComponentByName("labelBuff", typeof(UILabel))
	self.groupBuffs = groupBuff:NodeByName("groupBuffs").gameObject
	local groupPower = groupMain:NodeByName("groupPower").gameObject
	self.labelPower = groupPower:ComponentByName("labelPower", typeof(UILabel))
	local group3 = groupMain:NodeByName("group3").gameObject
	self.heroContainer1 = group3:NodeByName("hero1").gameObject
	self.heroContainer2 = group3:NodeByName("hero2").gameObject
	local group4 = groupMain:NodeByName("group4").gameObject
	self.heroContainer3 = group4:NodeByName("hero3").gameObject
	self.heroContainer4 = group4:NodeByName("hero4").gameObject
	self.heroContainer5 = group4:NodeByName("hero5").gameObject
	self.heroContainer6 = group4:NodeByName("hero6").gameObject

	for i = 1, 6 do
		self["hero" .. i] = HeroIcon.new(self["heroContainer" .. i])
	end
end

function GuildCompetitionFormationWindow:layout()
	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.avatarId,
		avatar_frame_id = self.avatarFrame,
		lev = self.lev
	})

	self.playerName.text = self.playername
	self.labelId.text = tostring(self.playerId)

	if self.total_harm then
		self.labelFormation.text = __("FRIEND_HARM") .. self.total_harm
	else
		self.labelFormation.text = __("FRIEND_HARM")
	end

	local power = 0

	for i = 1, #self.info do
		print(self.info[i].pos)

		if self.info[i] and self.info[i].equips and self.info[i].equips[7] then
			self.info[i].skin_id = self.info[i].equips[7]
		end

		local partner = Partner.new()

		partner:populate(self.info[i])

		local info = partner:getInfo()

		self["hero" .. tostring(self.info[i].pos)]:setInfo(info, self.pet_id)
		self["heroContainer" .. tostring(self.info[i].pos)]:SetActive(true)

		self["hero" .. tostring(self.info[i].pos)].noClick = true
		power = power + self.info[i].power
	end

	print(self.hero1.activeSelf)

	self.labelPower.text = tostring(power)

	self.groupMain:SetActive(true)
end

return GuildCompetitionFormationWindow
