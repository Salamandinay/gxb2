local BaseWindow = import(".BaseWindow")
local TrialFormationWindow = class("TrialFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function TrialFormationWindow:ctor(name, params)
	self.playerId = params.player_id
	self.playername = params.player_name
	self.avatarFrame = params.avatar_frame
	self.avatarId = params.avatar_id
	self.sever_id = params.server_id
	self.dress_style = params.dress_style
	self.boss_id = params.boss_id

	BaseWindow.ctor(self, name, params)
end

function TrialFormationWindow:initWindow()
	TrialFormationWindow.super.initWindow(self)
	self:getUIComponents()
	self:registerEvent()
	self:hide()

	local msg = messages_pb.trial_get_fight_boss_formation_req()
	msg.other_player_id = self.playerId
	msg.boss_id = self.boss_id or 1

	xyd.Backend:get():request(xyd.mid.TRIAL_GET_FIGHT_BOSS_FORMATION, msg)
end

function TrialFormationWindow:getUIComponents()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupMain").gameObject
	self.groupMain = groupMain
	local pIconContainer = groupMain:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.playerName = groupMain:ComponentByName("playerName", typeof(UILabel))
	self.labelFormation = groupMain:ComponentByName("labelFormation", typeof(UILabel))
	local serverGroup = groupMain:NodeByName("serverGroup").gameObject

	serverGroup:SetActive(true)

	self.serverId = serverGroup:ComponentByName("label", typeof(UILabel))
	local groupIDs = groupMain:NodeByName("groupIDs").gameObject
	self.labelText01 = groupIDs:ComponentByName("labelText01", typeof(UILabel))
	self.labelId = groupIDs:ComponentByName("labelId", typeof(UILabel))
	local groupBuff = groupMain:NodeByName("groupBuff").gameObject
	self.labelBuff = groupBuff:ComponentByName("labelBuff", typeof(UILabel))
	self.groupBuffs = groupBuff:ComponentByName("groupBuffs", typeof(UILayout))
	self.buffItem = groupBuff:NodeByName("buffItem").gameObject
	self.groupPower = groupMain:NodeByName("groupPower").gameObject
	self.labelPower = self.groupPower:ComponentByName("labelPower", typeof(UILabel))
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

	self.personCon = groupMain:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
end

function TrialFormationWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.TRIAL_GET_FIGHT_BOSS_FORMATION, handler(self, self.onGetInfo))
end

function TrialFormationWindow:onGetInfo(event)
	local formation = event.data.formation
	self.buffIds = {}
	self.petId = 0
	self.info = {}

	if formation then
		self.buffIds = formation.buff_ids
		self.petId = formation.pet_id
		self.info = formation.partner_infos
	end

	self:layout()
end

function TrialFormationWindow:layout()
	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.avatarId,
		avatar_frame_id = self.avatarFrame
	})

	self.playerName.text = self.playername
	self.labelId.text = tostring(self.playerId)
	self.labelFormation.text = __("GUILD_WAR_FORMATION_WINDOW")
	self.labelText01.text = "ID"

	if not self.sever_id then
		self.serverId.text = "S999"
	else
		self.serverId.text = xyd.getServerNumber(self.sever_id)
	end

	local power = 0

	for i = 1, #self.info do
		local partner = Partner.new()

		partner:populate(self.info[i])

		local info = partner:getInfo()

		self["hero" .. tostring(self.info[i].pos)]:setInfo(info, self.petId)
		self["heroContainer" .. tostring(self.info[i].pos)]:SetActive(true)

		self["hero" .. tostring(self.info[i].pos)].noClick = true
		power = power + self.info[i].power
	end

	self.labelPower.text = tostring(power)

	self.groupPower:GetComponent(typeof(UILayout)):Reposition()
	self.groupMain:SetActive(true)

	if #self.buffIds > 0 then
		self.labelBuff.text = __("ACTIVITY_NEW_TRIAL_BLESS_WINDOW")
	else
		self.labelBuff.text = " "
	end

	for _, id in ipairs(self.buffIds) do
		local src = xyd.tables.newTrialBuffTable:getIcon(id)
		local buffItem = NGUITools.AddChild(self.groupBuffs.gameObject, self.buffItem)
		local buffImg = buffItem:ComponentByName("imgBuff", typeof(UISprite))

		print("src")
		print(src)
		xyd.setUISpriteAsync(buffImg, nil, src)
	end

	self.groupBuffs:Reposition()
	self:show()
	self:initDress()
end

function TrialFormationWindow:initDress()
	local styleID = {}
	local ids = xyd.tables.senpaiDressSlotTable:getIDs()

	for i = 1, #ids do
		if self.dress_style and self.dress_style[i] then
			table.insert(styleID, self.dress_style[i])
		else
			table.insert(styleID, xyd.tables.senpaiDressSlotTable:getDefaultStyle(ids[i]))
		end
	end

	self.normalModel_ = import("app.components.SenpaiModel").new(self.personEffect)

	self.normalModel_:setModelInfo({
		ids = styleID
	})
end

return TrialFormationWindow
