local PartnerDetailWindow = import(".PartnerDetailWindow")
local GuideDetailWindow = class("GuideDetailWindow", PartnerDetailWindow)
local MiscTable = xyd.tables.miscTable
local PartnerTable = xyd.tables.partnerTable
local SkillIcon = import("app.components.SkillIcon")
local Partner = import("app.models.Partner")

function GuideDetailWindow:ctor(name, params)
	GuideDetailWindow.super.ctor(self, name, params)

	self.showSkinId = 0

	if params.skin_id and params.skin_id > 0 then
		self.showSkinId = params.skin_id
	end
end

function GuideDetailWindow:initCurIndex(params)
	self.currentSortedPartners_ = params.partners

	for idx = 1, #self.currentSortedPartners_ do
		if self.currentSortedPartners_[idx].table_id == params.table_id then
			self.currentIdx_ = tonumber(idx)
		end
	end
end

function GuideDetailWindow:initWindow()
	PartnerDetailWindow.initWindow(self)

	local except_id_list = MiscTable:split2num("warmup_challenge_partner", "value", "|")

	if xyd.arrayIndexOf(except_id_list, tonumber(self.partner_:getTableID())) ~= -1 then
		self.btnComment:SetActive(false)
	end

	self.defaultTabGroup:SetActive(false)
	self.guideTabGroup:SetActive(true)
end

function GuideDetailWindow:firstInit()
	self:updateData()
	self:registerEvent()
	self:updateCV()
	self:updateLoveIcon()
	self:checkExSkillBtn()

	if PartnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.btnComment:SetActive(false)
	else
		self.btnComment:SetActive(true)
	end
end

function GuideDetailWindow:registerEvent()
	PartnerDetailWindow.registerEvent(self)

	UIEventListener.Get(self.btnExSkill).onClick = handler(self, function ()
		if xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 then
			xyd.WindowManager.get():openWindow("exskill_preview_window", {
				partner = self.partner_
			})
		else
			xyd.showToast(__("EX_SKILL_TIPS_TEXT"))
		end
	end)

	UIEventListener.Get(self.btnData).onClick = function ()
		xyd.WindowManager.get():openWindow("dates_data_window", {
			tableID = self.partner_:getTableID()
		})
	end
end

function GuideDetailWindow:updateSkill()
	local awake = 0
	local skill_ids = nil

	if awake > 0 then
		skill_ids = self.partner_:getAwakeSkill(awake)
	else
		skill_ids = self.partner_:getSkillIDs()
	end

	local exSkills = {
		0,
		0,
		0,
		0
	}
	local hasExSkill = xyd.tables.partnerTable:getExSkill(self.partner_:getTableID())

	if self.isMonster and self.monster_id then
		hasExSkill = xyd.tables.partnerTable:getExSkill(self.monster_id)
	end

	if hasExSkill == 1 then
		exSkills = {
			5,
			5,
			5,
			5
		}
	end

	for key in pairs(skill_ids) do
		local icon = nil

		if tonumber(key) > #self.skillIcons then
			icon = SkillIcon.new(self.skillGroup)
			self.skillIcons[key] = icon

			UIEventListener.Get(icon.go).onSelect = function (go, isSelect)
				if isSelect == false then
					self:clearSkillTips()
				end
			end
		else
			icon = self.skillIcons[key]
		end

		icon.go:SetActive(true)

		local level = exSkills[key]

		if level and level > 0 then
			skill_ids[key] = xyd.tables.partnerExSkillTable:getExID(skill_ids[key])[level]
		end

		icon:setInfo(skill_ids[key], {
			unlocked = true,
			showGroup = self.skillDesc,
			callback = function ()
				self:handleSkillTips(icon)
			end
		})
	end

	for i = #skill_ids + 1, #self.skillIcons do
		local icon = self.skillIcons[i]

		icon.go:SetActive(false)
	end

	self.skillGroupGrid:Reposition()
end

function GuideDetailWindow:initVars()
	local partner = Partner.new()
	local item = self.currentSortedPartners_[self.currentIdx_]

	if not item then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	local tableID = item.table_id

	partner:populate({
		table_id = tableID
	})

	local max_lev = partner:getMaxLev()
	local max_grade = partner:getMaxGrade()
	local show_skin = self.showSkinId > 0
	local equipments = {
		0,
		0,
		0,
		0,
		0,
		0,
		0
	}
	local show_id = tableID

	if show_skin then
		equipments[6] = self.showSkinId
		show_id = self.showSkinId
	end

	local ex_skills = {}

	if partner:getStar() == 10 then
		ex_skills = {
			5,
			5,
			5,
			5
		}
	end

	partner:populate({
		isHeroBook = true,
		table_id = tableID,
		lev = max_lev,
		grade = max_grade,
		show_skin = show_skin,
		equips = equipments,
		show_id = show_id,
		ex_skills = ex_skills
	})

	self.isMonster = item.isMonster
	self.monster_id = item.monster_id
	self.partner_ = partner
end

function GuideDetailWindow:updateData()
	self:initVars()
	self:updateBg()
	self:updateGuideArrow()
	self:updateNameTag()
	self:updateAttr()
	self:updateGrade()
	self:updateLevUp()
	self:updateSkill()
	self:updateCV()
	self:updateDataBtn()
	self:initPartnerSkin()

	self.labelGrade.text = __("GRADE")
	self.labelLevUp.text = __("COST")

	self.bubble:SetActive(false)
	self.btnLockPartner:SetActive(false)
	self.btnUnlockPartner:SetActive(false)
	self.btnShare:SetActive(false)

	self.guideTabGroup:ComponentByName("tab_1/label", typeof(UILabel)).text = __("ATTR")
	self.guideTabGroup:ComponentByName("tab_2/label", typeof(UILabel)).text = __("SKIN_TEXT01")

	if xyd.isH5() then
		xyd.setUISpriteAsync(self.content_1_battleIcon, nil, "force_icon", nil, )
		self.content_1_battleIcon:MakePixelPerfect()
	end
end

function GuideDetailWindow:onClickNav(index)
	if index == 2 then
		index = 3
	end

	local except_id_list = MiscTable:split2num("warmup_challenge_partner", "value", "|")

	if xyd.arrayIndexOf(except_id_list, tonumber(self.partner_:getTableID())) ~= -1 then
		xyd.showToast(__("NEW_FUNCTION_TIP"))

		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	local old_index = self.navChosen

	if old_index == index then
		return
	end

	if PartnerTable:checkPuppetPartner(self.partner_:getTableID()) and (index == 3 or index == 4) then
		xyd.showToast(__("PUPPET_PARTNER_NO_CLICK"))

		return
	end

	self["content_" .. tostring(old_index)]:SetActive(false)
	self["content_" .. tostring(index)]:SetActive(true)

	self.navChosen = index

	if index == 3 then
		self:loadSkinModel()
		self:playSkinEffect()
		self:preViewBg()
	else
		self:stopSkinEffect()
		self:updateBg()
	end
end

function GuideDetailWindow:setSkinBtn()
	PartnerDetailWindow.setSkinBtn(self)

	self.currentSkinID4SkinPlay = self.skinIDs[self.currentSkin]

	self.btnSkinOn:SetActive(false)
	self.btnSkinOff:SetActive(false)
	self.btnSelectPicture:SetActive(false)
	self.btnSkinDetail:SetActive(true)
	self.btnSkinUnlock:SetActive(false)

	if self:isSkinId() then
		self.btnSkinPlay:SetActive(true)

		if not self.showBtnBuy_ then
			self.btnSkinDetail:X(-100)
		else
			self.btnSkinDetail:SetActive(false)
			self.btnBuy.transform:X(-100)
		end
	else
		self.btnSkinPlay:SetActive(false)
		self.btnSkinDetail:X(0)
		self.btnBuy.transform:X(0)
	end

	self.btnSkinPlay:ComponentByName("button_label", typeof(UILabel)).text = __("FORMATION_TRY_FIGHT")

	xyd.setBgColorType(self.btnSkinPlay, xyd.ButtonBgColorType.blue_btn_65_65)
	xyd.setBgColorType(self.btnSkinDetail, xyd.ButtonBgColorType.blue_btn_65_65)

	self.btnSkinDetail:ComponentByName("button_label", typeof(UILabel)).text = __("SKIN_TEXT04")

	self.textGroup:SetActive(false)

	for _, card in ipairs(self.skinCards) do
		card:setSkinCollect(false)
		card:hideSkinNum()
	end
end

function GuideDetailWindow:isSkinId()
	local partnerTableId = self.partner_:getTableID()
	local skinIds = xyd.tables.partnerTable:getSkins(partnerTableId)

	return xyd.arrayIndexOf(skinIds, self.currentSkinID4SkinPlay) > -1
end

function GuideDetailWindow:setSkinTouchEvent()
	PartnerDetailWindow.setSkinTouchEvent(self)

	UIEventListener.Get(self.btnSkinDetail).onClick = function ()
		local currentSkinID = self.skinIDs[self.currentSkin]
		local tableID = self.partner_:getTableID()

		xyd.WindowManager.get():openWindow("skin_tip_window", {
			skin_id = currentSkinID,
			tableID = tableID
		})
	end

	UIEventListener.Get(self.btnSkinPlay).onClick = handler(self, self.onClickSkinPlay)
end

function GuideDetailWindow:onClickSkinPlay()
	local battleId1 = xyd.tables.skinShowStageTable:getBattleId1(self.currentSkinID4SkinPlay)
	local battleId2 = xyd.tables.skinShowStageTable:getBattleId2(self.currentSkinID4SkinPlay)

	xyd.BattleController.get():frontBattleBy2BattleId(battleId1, battleId2, xyd.BattleType.SKIN_PLAY, 1)
end

function GuideDetailWindow:updatePartnerSkin()
	PartnerDetailWindow.updatePartnerSkin(self)

	for _, card in ipairs(self.skinCards) do
		card:setSkinCollect(false)
		card:hideSkinNum()
	end
end

function GuideDetailWindow:closeSelf()
	if self.isPlaySound then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)

		self.isPlaySound = false
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function GuideDetailWindow:updateLoveIcon()
	self.loveIconGo:SetActive(false)
end

function GuideDetailWindow:updateDataBtn()
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.btnData:SetActive(false)
	else
		self.btnData:SetActive(true)
	end
end

function GuideDetailWindow:hidePartnerBackBtn()
	self.btnPartnerBack:SetActive(false)
end

function GuideDetailWindow:onclickArrow(delta)
	GuideDetailWindow.super.onclickArrow(self, delta)
	self.btnPartnerBack:SetActive(false)
end

return GuideDetailWindow
