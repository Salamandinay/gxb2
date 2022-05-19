local PartnerDetailWindow = import(".PartnerDetailWindow")
local GuideDetailWindow = class("GuideDetailWindow", PartnerDetailWindow)
local MiscTable = xyd.tables.miscTable
local PartnerTable = xyd.tables.partnerTable
local SkillIcon = import("app.components.SkillIcon")
local Partner = import("app.models.Partner")
local PartnerGravityController = import("app.components.PartnerGravityController")

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
			local group = xyd.tables.partnerTable:getGroup(params.table_id)

			if group == xyd.PartnerGroup.TIANYI then
				if params.is_group7_ex_gallery == nil and self.currentSortedPartners_[idx].is_group7_ex_gallery == nil or params.is_group7_ex_gallery == true and self.currentSortedPartners_[idx].is_group7_ex_gallery == true then
					self.currentIdx_ = tonumber(idx)

					break
				end
			else
				self.currentIdx_ = tonumber(idx)

				break
			end
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
		local group = xyd.tables.partnerTable:getGroup(self.partner_:getTableID())

		if group and group ~= xyd.PartnerGroup.TIANYI then
			if xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 then
				xyd.WindowManager.get():openWindow("exskill_preview_window", {
					partner = self.partner_
				})
			else
				xyd.showToast(__("EX_SKILL_TIPS_TEXT"))
			end
		elseif group and group == xyd.PartnerGroup.TIANYI then
			xyd.WindowManager.get():openWindow("skill_resonate_window", {
				isGuide = true,
				partner = self.partner_
			})
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

	local item = self.currentSortedPartners_[self.currentIdx_]
	local group = xyd.tables.partnerTable:getGroup(item.table_id)

	if group == xyd.PartnerGroup.TIANYI then
		skill_ids = self.partner_:getSkillIDs()

		if hasExSkill == 1 then
			if item.is_group7_ex_gallery == nil then
				exSkills = xyd.models.slot:getGroup7ShowGuideInfo().low_ex_skills
			elseif item.is_group7_ex_gallery == true then
				exSkills = xyd.models.slot:getGroup7ShowGuideInfo().max_ex_skills
			end
		end
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

	local param = {
		isHeroBook = true,
		table_id = tableID,
		lev = max_lev,
		grade = max_grade,
		show_skin = show_skin,
		equips = equipments,
		show_id = show_id,
		ex_skills = ex_skills
	}
	local hasExSkill = xyd.tables.partnerTable:getExSkill(tableID)
	local group = xyd.tables.partnerTable:getGroup(tableID)

	if group == xyd.PartnerGroup.TIANYI then
		if hasExSkill == 1 then
			if item.is_group7_ex_gallery == nil then
				param.ex_skills = xyd.models.slot:getGroup7ShowGuideInfo().low_ex_skills
			elseif item.is_group7_ex_gallery == true then
				param.ex_skills = xyd.models.slot:getGroup7ShowGuideInfo().max_ex_skills
			end
		end

		if item.is_group7_ex_gallery == nil then
			-- Nothing
		elseif item.is_group7_ex_gallery == true then
			param.awake = xyd.models.slot:getGroup7ShowGuideInfo().max_awake
			param.lev = xyd.models.slot:getGroup7ShowGuideInfo().max_lev
		end
	end

	partner:populate(param)

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

function GuideDetailWindow:checkExSkillBtn()
	GuideDetailWindow.super.checkExSkillBtn(self)

	local item = self.currentSortedPartners_[self.currentIdx_]
	local group = xyd.tables.partnerTable:getGroup(item.table_id)

	if group == xyd.PartnerGroup.TIANYI then
		self.btnExSkill:SetActive(false)

		if item.is_group7_ex_gallery then
			self.btnExSkill:SetActive(true)
		end
	end
end

function GuideDetailWindow:updateBg()
	if self.partner_:getGroup() == 7 and (UNITY_EDITOR or UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.5.374") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.3.444") >= 0) then
		if not self.partnerGravity then
			self.partnerGravity = PartnerGravityController.new(self.groupBg.gameObject, 5)
		else
			self.partnerGravity:SetActive(true)
		end
	elseif self.partnerGravity then
		self.partnerGravity:SetActive(false)
	end

	local res = "college_scene" .. tostring(self.partner_:getGroup())

	if self.groupBg.mainTexture ~= res then
		local miniBgPath = "college_scene" .. tostring(self.partner_:getGroup()) .. "_mini"

		xyd.setUISprite(self.groupBgMini, nil, miniBgPath)
		xyd.setUITextureByNameAsync(self.groupBg, res, false)
	end

	local showID = self.partner_:getShowID()
	showID = showID or self.partner_:getTableID()

	if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		local item = self.currentSortedPartners_[self.currentIdx_]

		if item.is_group7_ex_gallery then
			local showIds = xyd.tables.partnerTable:getShowIds(self.partner_:getTableID())
			showID = tonumber(showIds[xyd.models.slot:getGroup7ShowGuideInfo().max_show_guide_index])
		end
	end

	if self.partnerImg:getItemID() == showID then
		return
	end

	self.partnerImg:setImg()
	self.partnerImg:setImg({
		showResLoading = true,
		windowName = self.name_,
		itemID = showID
	})

	local dragonBoneID = xyd.tables.partnerPictureTable:getDragonBone(showID)
	local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(showID)
	local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(showID)

	if xy and scale then
		self.partnerImg.go.transform:SetLocalPosition(xy.x, -xy.y, 0)
		self.partnerImg.go.transform:SetLocalScale(scale, scale, scale)
	end
end

return GuideDetailWindow
