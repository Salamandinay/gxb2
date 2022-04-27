local BaseWindow = import(".BaseWindow")
local AcademyAssessmentFormationWindow = class("AcademyAssessmentFormationWindow", BaseWindow)
local PlayerIcon = import("app.components.PlayerIcon")
local HeroIcon = import("app.components.HeroIcon")
local Partner = import("app.models.Partner")

function AcademyAssessmentFormationWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fortId = 1
	self.fortId = params.fort_id
	self.playerId = params.player_id
	self.playername = params.player_name
	self.avatarFrame = params.avatar_frame
	self.avatarId = params.avatar_id
	self.info = params.info
	self.dress_style = params.dress_style or {}
end

function AcademyAssessmentFormationWindow:initWindow()
	AcademyAssessmentFormationWindow.super.initWindow(self)
	self:getUIComponents()
	self:layout()
end

function AcademyAssessmentFormationWindow:getUIComponents()
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

	self.tipsLabel_ = groupMain:ComponentByName("tipsLabel_", typeof(UILabel))
	self.personCon = groupMain:NodeByName("personCon").gameObject
	self.personBottom = self.personCon:ComponentByName("personBottom", typeof(UISprite))
	self.personEffect = self.personCon:NodeByName("personEffect").gameObject
end

function AcademyAssessmentFormationWindow:layout()
	self.tipsLabel_.text = __("ACADEMY_ASSESSMENT_FORMATION_TIPS")

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.avatarId,
		avatar_frame_id = self.avatarFrame
	})

	self.playerName.text = self.playername
	self.labelId.text = tostring(self.playerId)
	self.labelFormation.text = __("GUILD_WAR_FORMATION_WINDOW")
	local power = 0

	for i = 1, #self.info do
		dump(self.info[i])
		print(self.info[i].pos)

		local partner = Partner.new()

		partner:populate(self.info[i])

		local info = partner:getInfo()

		function info.callback()
		end

		info.isShowSelected = false

		self["hero" .. tostring(self.info[i].pos)]:setInfo(info)
		self["heroContainer" .. tostring(self.info[i].pos)]:SetActive(true)

		power = power + self.info[i].power
	end

	print(self.hero1.activeSelf)

	self.labelPower.text = tostring(power)

	self.groupMain:SetActive(true)
	self:initDress()
end

function AcademyAssessmentFormationWindow:initDress()
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

return AcademyAssessmentFormationWindow
