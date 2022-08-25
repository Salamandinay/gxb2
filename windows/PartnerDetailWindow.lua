local BaseWindow = import(".BaseWindow")
local PartnerNameTag = import("app.components.PartnerNameTag")
local SkillIcon = import("app.components.SkillIcon")
local ItemIcon = import("app.components.ItemIcon")
local AttrLabel = import("app.components.AttrLabel")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ParnterImg = import("app.components.PartnerImg")
local PartnerDetailWindow = class("PartnerDetailWindow", BaseWindow)
local Partner = import("app.models.Partner")
local WindowTop = import("app.components.WindowTop")
local AttrTipsItem = import("app.components.AttrTipsItem")
local HeroIcon = import("app.components.HeroIcon")
local PartnerCard = import("app.components.PartnerCard")
local StarOriginNodeItem = import("app.components.StarOriginNodeItem")
local PartnerGravityController = import("app.components.PartnerGravityController")

function PartnerDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params.enterType == 2 then
		params.sort_key = xyd.partnerSortType.isCollected .. "_0"
		params.partner_id = xyd.models.slot:getSortedPartners()[tostring(xyd.partnerSortType.isCollected) .. "_0"][1]
	end

	self.params_ = params
	self.skinID = 1
	self.unableMove = false
	self.notOpenSlotWindow = false
	self.bpEquips = {}
	self.Effects = {}
	self.isPlaySound = false
	self.awakeSelectedPartners = {}
	self.fakeUseRes = {
		[xyd.ItemID.MANA] = 0,
		[xyd.ItemID.PARTNER_EXP] = 0
	}
	self.material_details = {}
	self.fakeLev = 0
	self.isFix = false
	self.tar_src_ = nil
	self.attrTipsItems = {}
	self.attrTipsItemsIndex = 0
	self.model_ = xyd.models.slot
	self.sort_key = params.sort_key or "1_0"
	self.navChosen = 1

	if params.unable_move then
		self.unableMove = params.unable_move
	else
		self.unableMove = false
	end

	self.battleData = params.battleData
	self.if3v3 = params.if3v3 and params.if3v3 or false
	self.ifGalaxy = params.ifGalaxy
	self.isFairyTale_ = params.isFairyTale
	self.isTrial_ = params.isTrial
	self.isSpfarm_ = params.isSpfarm
	self.isShrineHurdle_ = params.isShrineHurdle
	self.isLongTouch = params.isLongTouch
	self.skillIcons = {}
	self.gradeItems = {}
	self.groupAllAttrLables = {}
	self.isPartnerImgClick = true
	self.SLIDEHEIGHT = 243
	self.equipLockEffects = {}
	self.equipPlusEffects = {}
	self.isNeedSkill = true
	self.enterType = params.enterType or 0

	if params.isNeedSkill ~= nil then
		self.isNeedSkill = params.isNeedSkill
	end

	self.needExSkillGuide = false
	self.needStarOriginGuide = false

	self:initCurIndex(params)
	self:checkEnterType()
end

function PartnerDetailWindow:checkEnterType()
	if self.enterType == xyd.PARTNER_DETAIL_ENTER_TYPE.STAR10 then
		for idx in pairs(self.currentSortedPartners_) do
			local p = self.model_:getPartner(self.currentSortedPartners_[idx])

			if p.star >= 10 then
				self.currentIdx_ = idx
				self.partnerId = self.currentSortedPartners_[idx]

				break
			end
		end
	end
end

function PartnerDetailWindow:initCurIndex(params)
	if self.isShrineHurdle_ then
		local np = Partner.new()

		np:populate(self.params_.partner)

		self.partner_ = np

		if self.partner_.skin_id and self.partner_.skin_id > 0 then
			self.partner_:setShowID(self.partner_.skin_id)
			self.partner_:setShowSkin(self.partner_.skin_id)
		end

		self.currentIdx_ = 1
		self.currentSortedPartners_ = {
			np.partner_id
		}
	else
		self.currentSortedPartners_ = self.model_:getSortedPartners()[self.sort_key]
		self.notOpenSlotWindow = params.not_open_slot or false

		for idx in pairs(self.currentSortedPartners_) do
			if self.currentSortedPartners_[idx] == params.partner_id then
				self.currentIdx_ = tonumber(idx)
			end
		end
	end
end

function PartnerDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.top = winTrans:NodeByName("top").gameObject
	self.playerNameGroup = self.top:NodeByName("partnerNameGroup").gameObject
	self.partnerNameTag = PartnerNameTag.new(self.playerNameGroup, true)
	self.loveIconGo = self.top:NodeByName("loveIcon").gameObject
	self.loveIcon = self.top:ComponentByName("loveIcon", typeof(UISprite))
	self.groupPledgeEffect = self.top:NodeByName("groupPledgeEffect").gameObject
	local top_right = winTrans:NodeByName("top_right").gameObject
	self.top_right = winTrans:NodeByName("top_right").gameObject
	self.cvGroup = top_right:NodeByName("cvGroup").gameObject
	self.cvNameLabel = self.cvGroup:ComponentByName("cvInfoGroup/cvNameLabel", typeof(UILabel))
	self.btnComment = top_right:NodeByName("btnComment").gameObject
	self.btnData = top_right:NodeByName("btnData").gameObject
	local center = winTrans:NodeByName("center")
	self.bubble = center:NodeByName("bubble").gameObject
	self.tips = self.bubble:ComponentByName("tips", typeof(UILabel))
	self.btnBack = center:NodeByName("btnBack").gameObject
	local pageGuide = center:NodeByName("page_guide").gameObject
	self.page_guide = center:NodeByName("page_guide").gameObject
	self.arrow_left = pageGuide:NodeByName("arrow_left").gameObject
	self.arrow_left_none = pageGuide:NodeByName("arrow_left_none").gameObject
	self.arrow_right = pageGuide:NodeByName("arrow_right").gameObject
	self.arrow_right_none = pageGuide:NodeByName("arrow_right_none").gameObject
	self.groupBg = center:ComponentByName("groupBg", typeof(UITexture))
	self.groupBgMini = center:ComponentByName("groupBgMini", typeof(UISprite))
	self.partnerImgNode = center:NodeByName("partnerImg").gameObject
	self.partnerImg = ParnterImg.new(self.partnerImgNode)
	self.effectGroup = center:NodeByName("effectGroup").gameObject
	local bottom = winTrans:NodeByName("bottom").gameObject
	self.groupInfo = bottom:NodeByName("groupInfo").gameObject
	local nav = self.groupInfo:NodeByName("nav").gameObject
	self.defaultTabGroup = nav:NodeByName("default").gameObject
	self.guideTabGroup = nav:NodeByName("guide").gameObject
	self.defaultTab = CommonTabBar.new(self.defaultTabGroup, 5, handler(self, self.onClickNav))

	self.defaultTab:setBrforeChangeFuc(function (index, currentIndex)
		if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) and (index == 3 or index == 4) then
			xyd.showToast(__("PUPPET_PARTNER_NO_CLICK"))
			self.defaultTab:setTabActive(currentIndex, true, false)

			return true
		end
	end)

	self.guideTab = CommonTabBar.new(self.guideTabGroup, 2, handler(self, self.onClickNav))
	self.attrChangeGroup = bottom:NodeByName("attrChangeGroup").gameObject
	self.attrChangeGroupTable = self.attrChangeGroup:GetComponent(typeof(UITable))
	self.tab4awakeLock = self.defaultTabGroup:NodeByName("tab_4/awakeLock").gameObject
	self.tab2equipLock = self.defaultTabGroup:NodeByName("tab_2/equipLock").gameObject
	self.tab4none = self.defaultTabGroup:NodeByName("tab_4/none").gameObject
	self.tab3none = self.defaultTabGroup:NodeByName("tab_3/none").gameObject
	self.tab2none = self.defaultTabGroup:NodeByName("tab_2/none").gameObject
	self.labelAttr = self.defaultTabGroup:ComponentByName("tab_1/label", typeof(UILabel))
	self.labelEquip = self.defaultTabGroup:ComponentByName("tab_2/label", typeof(UILabel))
	self.labelSkin = self.defaultTabGroup:ComponentByName("tab_3/label", typeof(UILabel))
	self.labelAwake = self.defaultTabGroup:ComponentByName("tab_4/label", typeof(UILabel))
	self.labelStarOrigin = self.defaultTabGroup:ComponentByName("tab_5/label", typeof(UILabel))
	self.groupAllAttrShow = self.groupInfo:NodeByName("groupAllAttrShow").gameObject
	self.attrClickBg = self.groupAllAttrShow:NodeByName("attrClickBg").gameObject
	self.groupAllAttr = self.groupAllAttrShow:NodeByName("e:Group/groupAllAttr").gameObject
	self.groupAllAttrTable = self.groupAllAttr:GetComponent(typeof(UITable))
	self.nav2_redPoint = self.defaultTabGroup:NodeByName("tab_2/redPoint")
	self.nav4_redPoint = self.defaultTabGroup:NodeByName("tab_4/redPoint")
	self.tab_5 = self.defaultTabGroup:NodeByName("tab_5").gameObject
	local content = self.groupInfo:NodeByName("content").gameObject
	self.content_1 = content:NodeByName("content_1").gameObject
	self.content_1_battleIcon = self.content_1:ComponentByName("content1BattleIcon", typeof(UISprite))
	self.labelGrade = self.content_1:ComponentByName("gradeup/e:Group/labelGrade", typeof(UILabel))
	self.labelLevUp = self.content_1:ComponentByName("levelup/e:Group/labelLevUp", typeof(UILabel))
	self.btnLevUp = self.content_1:NodeByName("levelup/btnLevUp").gameObject
	self.btnLevUp_redPoint = self.content_1:NodeByName("levelup/btnLevUp/redPoint").gameObject
	self.btnLevUpCollider = self.btnLevUp:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnGradeUp = self.content_1:NodeByName("gradeup/btnGradeUp").gameObject
	self.btnGradeUpCollider = self.btnGradeUp:GetComponent(typeof(UnityEngine.BoxCollider))
	self.labelBattlePoint = self.content_1:ComponentByName("labelBattlePoint", typeof(UILabel))
	self.labelLev = self.content_1:ComponentByName("labelLev", typeof(UILabel))
	self.ns1MultiLabel = self.content_1:ComponentByName("ns1:MultiLabel", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.ns1MultiLabel.text = "Niv."

		self.ns1MultiLabel.gameObject:X(-35.8)
	end

	self.jobIcon = self.content_1:ComponentByName("jobIcon", typeof(UISprite))
	self.labelJob = self.content_1:ComponentByName("labelJob", typeof(UILabel))
	local attr = self.content_1:NodeByName("attr").gameObject
	self.labelHp = attr:ComponentByName("labelHp", typeof(UILabel))
	self.labelAtk = attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpd = attr:ComponentByName("labelSpd", typeof(UILabel))
	self.attrDetail = attr:NodeByName("attrDetail").gameObject
	self.gradeGroup = self.content_1:NodeByName("gradeup/gradeGroup").gameObject
	self.gradeGroupGrid = self.gradeGroup:GetComponent(typeof(UIGrid))
	self.gradeItem = self.content_1:NodeByName("gradeup/gradeGroupItem").gameObject

	self.gradeItem:SetActive(false)

	self.textMaxLev = self.content_1:ComponentByName("levelup/maxGroup/textMaxLev", typeof(UILabel))
	self.groupLevupCost = self.content_1:NodeByName("levelup/groupLevupCost").gameObject
	self.labelGoldCost = self.groupLevupCost:ComponentByName("labelGoldCost", typeof(UILabel))
	self.labelExpCost = self.groupLevupCost:ComponentByName("labelExpCost", typeof(UILabel))
	self.skillGroup = self.content_1:NodeByName("skill/skillGroup").gameObject
	self.skillGroupGrid = self.skillGroup:GetComponent(typeof(UIGrid))
	self.skillDesc = self.groupInfo:NodeByName("skillDesc").gameObject
	self.skillMask = self.groupInfo:NodeByName("skillMask").gameObject
	self.btnFullGradeUp = self.content_1:NodeByName("btnFullGradeUp").gameObject
	self.btnFullLevelUp = self.content_1:NodeByName("btnFullLevelUp").gameObject
	self.content_2 = content:NodeByName("content_2").gameObject
	self.equipEffectRender = self.content_2:ComponentByName("equipEffectRender", typeof(UIWidget))

	for i = 1, 6 do
		local equip = self.content_2:NodeByName("equip" .. i).gameObject
		local iconEquipContainer = equip:NodeByName("iconEquip" .. i).gameObject
		local iconEquip = ItemIcon.new(iconEquipContainer)
		self["iconEquip" .. i] = iconEquip
		self["plusEquip" .. i] = equip:NodeByName("plusEquip" .. i).gameObject
		self["emptyEquip" .. i] = equip:NodeByName("emptyEquip" .. i).gameObject

		if i == 5 then
			self.equipLock = equip:NodeByName("equipLock").gameObject
		end
	end

	self.btnEquipAll = self.content_2:NodeByName("btnEquipAll").gameObject
	self.btnEquipAll_redPoint = self.content_2:NodeByName("btnEquipAll/redPoint").gameObject
	self.btnEquipAllLabel = self.btnEquipAll:ComponentByName("button_label", typeof(UILabel))
	self.btnUnequipAll = self.content_2:NodeByName("btnUnequipAll").gameObject
	self.btnUnequipAllLabel = self.btnUnequipAll:ComponentByName("button_label", typeof(UILabel))
	self.suitGroup_ = self.content_2:NodeByName("suitGroup").gameObject
	self.suitSkillIcon_ = self.content_2:ComponentByName("suitGroup/skillIcon", typeof(UISprite))
	self.suitSkillRed_ = self.content_2:NodeByName("suitGroup/redIcon").gameObject
	self.suitSkillEffectRoot_ = self.content_2:NodeByName("suitGroup/effectGroup").gameObject
	self.content_3 = content:NodeByName("content_3").gameObject
	self.btnSkinOn = self.content_3:NodeByName("btnSkinOn").gameObject
	self.btnSkinOnCollider = self.btnSkinOn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnSkinOnLabel = self.btnSkinOn:ComponentByName("button_label", typeof(UILabel))
	self.btnSkinOff = self.content_3:NodeByName("btnSkinOff").gameObject
	self.btnSkinOffLabel = self.btnSkinOff:ComponentByName("button_label", typeof(UILabel))
	self.btnSkinDetail = self.content_3:NodeByName("btnSkinDetail").gameObject
	self.btnSkinPlay = self.content_3:NodeByName("btnFight").gameObject
	self.btnSkinUnlock = self.content_3:NodeByName("btnSkinUnlock").gameObject
	self.btnSkinUnlockLabel = self.btnSkinUnlock:ComponentByName("button_label", typeof(UILabel))
	self.btnSelectPicture = self.content_3:NodeByName("btnSelectPicture").gameObject
	self.btnSelectPictureCollider = self.btnSelectPicture:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnSelectPictureLabel = self.btnSelectPicture:ComponentByName("button_label", typeof(UILabel))
	self.groupSkinCards = self.content_3:NodeByName("clipContainer/groupSkinCards").gameObject
	self.groupSkinCardsGrid = self.groupSkinCards:GetComponent(typeof(UIGrid))
	self.btnShowSkin = self.content_3:NodeByName("btnShowSkin").gameObject
	self.skinEffectGroup = self.content_3:NodeByName("skinEffectGroup").gameObject
	self.cancelEffectGroup = self.skinEffectGroup:NodeByName("cancelEffectGroup").gameObject
	self.labelSkinDesc = self.skinEffectGroup:ComponentByName("labelSkinDesc", typeof(UILabel))
	self.groupEffect1 = self.skinEffectGroup:NodeByName("groupEffect1").gameObject
	self.groupEffect2 = self.skinEffectGroup:NodeByName("groupEffect2").gameObject
	self.groupTouch = self.skinEffectGroup:NodeByName("groupTouch").gameObject
	self.groupModel = self.skinEffectGroup:NodeByName("groupModel").gameObject
	self.btnSetSkinVisible = self.content_3:NodeByName("btnSetSkinVisible").gameObject
	self.groupCardTouch = self.content_3:NodeByName("groupCardTouch").gameObject
	self.textGroup = self.content_3:NodeByName("textGroup").gameObject
	self.wayDescLabel = self.textGroup:ComponentByName("wayDescLabel", typeof(UILabel))
	self.wayLabel = self.textGroup:ComponentByName("wayLabel", typeof(UILabel))
	self.btnBuy = self.content_3:NodeByName("btnBuy").gameObject
	self.btnBuyLabel = self.btnBuy:ComponentByName("btnBuyLabel", typeof(UILabel))
	self.content_4 = content:NodeByName("content_4").gameObject
	self.awakeAttrChangeBg = self.content_4:NodeByName("awakeAttrChangeBg").gameObject
	self.awakeArrowLeft = self.content_4:NodeByName("arrow/awakeArrowLeft").gameObject
	self.awakeArrowRight = self.content_4:NodeByName("arrow/awakeArrowRight").gameObject
	self.awakeRedPoint = self.awakeArrowRight:NodeByName("redPointImg").gameObject
	self.starChange = self.content_4:NodeByName("starChange").gameObject
	self.stars1 = self.starChange:NodeByName("stars1").gameObject
	self.stars1Grid = self.stars1:GetComponent(typeof(UIGrid))
	self.stars2 = self.starChange:NodeByName("stars2").gameObject
	self.stars2Grid = self.stars2:GetComponent(typeof(UIGrid))
	self.starGroup = self.starChange:NodeByName("starGroup").gameObject
	self.tenStarGroup = self.starChange:NodeByName("tenStarGroup").gameObject
	self.skillChange = self.content_4:NodeByName("skillChange").gameObject
	self.awakeSkillBefore = self.skillChange:NodeByName("awakeSkillBefore").gameObject
	self.awakeSkillBeforeLine1 = self.awakeSkillBefore:NodeByName("line1").gameObject
	self.awakeSkillBeforeLine2 = self.awakeSkillBefore:NodeByName("line2").gameObject
	self.awakeSkillAfter = self.skillChange:NodeByName("awakeSkillAfter").gameObject
	self.awakeSkillAfterLine1 = self.awakeSkillAfter:NodeByName("line1").gameObject
	self.awakeSkillAfterLine2 = self.awakeSkillAfter:NodeByName("line2").gameObject
	self.skillItem = self.skillChange:NodeByName("skillItem").gameObject
	self.attrUp_1 = self.content_4:NodeByName("attrUp_1").gameObject
	self.labelAttrUp = self.attrUp_1:ComponentByName("labelAttrUp", typeof(UILabel))
	self.labelAttrNum = self.attrUp_1:ComponentByName("labelAttrNum", typeof(UILabel))
	self.attrUp_2 = self.content_4:NodeByName("attrUp_2").gameObject
	self.labelMaxLevUp = self.attrUp_2:ComponentByName("labelMaxLevUp", typeof(UILabel))
	self.labelMaxLev = self.attrUp_2:ComponentByName("labelMaxLev", typeof(UILabel))
	self.awakeCost = self.content_4:NodeByName("awakeCost").gameObject
	self.imgCostRes = self.awakeCost:ComponentByName("imgCostRes", typeof(UISprite))
	self.labelCostRes = self.awakeCost:ComponentByName("labelCostRes", typeof(UILabel))
	self.labelCostResHas = self.awakeCost:ComponentByName("labelCostResHas", typeof(UILabel))
	self.btnAwake = self.content_4:NodeByName("btnAwake").gameObject
	self.btnAwakeLabel = self.btnAwake:ComponentByName("button_label", typeof(UILabel))
	self.feedIcons = self.content_4:NodeByName("feedIcons").gameObject
	self.feedIconsGrid = self.feedIcons:GetComponent(typeof(UIGrid))
	self.feedIconGroup = self.content_4:NodeByName("feedIconGroup").gameObject
	self.fakeIcons = self.content_4:NodeByName("fakeIcons").gameObject
	self.fakeStars = self.content_4:NodeByName("fakeStars").gameObject
	self.fakeTenStar = self.content_4:NodeByName("fakeTenStar").gameObject
	self.labelMaxAwake = self.content_4:ComponentByName("labelMaxAwake", typeof(UILabel))
	self.exchangeComponent = self.content_4:NodeByName("exchangeComponent").gameObject
	self.awakeSkillDesc = self.groupInfo:NodeByName("awakeSkillDesc").gameObject
	self.content_5 = content:NodeByName("content_5").gameObject
	self.shenxueStarChange = self.content_5:NodeByName("shenxueStarChange").gameObject
	self.shenxueStarsAfter = self.content_5:NodeByName("shenxueStarChange/shenxueStarsAfter").gameObject
	self.shenxueStarsAfterLayout = self.shenxueStarsAfter:GetComponent(typeof(UILayout))
	self.shenxueStarsBefore = self.content_5:NodeByName("shenxueStarChange/shenxueStarsBefore").gameObject
	self.shenxueStarsBeforeLayout = self.shenxueStarsBefore:GetComponent(typeof(UILayout))
	self.heroChange = self.content_5:NodeByName("heroChange").gameObject
	self.shenxueHeroBeforeRoot = self.content_5:NodeByName("heroChange/shenxueHeroBefore").gameObject
	self.shenxueHeroAfterRoot = self.content_5:NodeByName("heroChange/shenxueHeroAfter").gameObject
	self.labelShenxueAttrUp = self.content_5:ComponentByName("attrUp_0/labelShenxueAttrUp", typeof(UILabel))
	self.labelShenxueAttrNum = self.content_5:ComponentByName("attrUp_0/labelShenxueAttrNum", typeof(UILabel))
	self.labelShenxueMaxLevUp = self.content_5:ComponentByName("attrUp_3/labelShenxueMaxLevUp", typeof(UILabel))
	self.labelShenxueMaxLev = self.content_5:ComponentByName("attrUp_3/labelShenxueMaxLev", typeof(UILabel))
	self.btnShenxue = self.content_5:NodeByName("btnShenxue").gameObject
	self.btnShenxueLabel = self.content_5:ComponentByName("btnShenxue/label", typeof(UILabel))
	self.shenxueFeedGroup = self.content_5:ComponentByName("shenxueFeedGroup", typeof(UILayout))
	self.shenxueFeedItem = self.content_5:NodeByName("feedItem").gameObject
	self.midBtns = bottom:NodeByName("midBtns").gameObject
	self.btnLockPartner = self.midBtns:NodeByName("e:Group/btnUnlockPartner").gameObject
	self.btnUnlockPartner = self.midBtns:NodeByName("e:Group/btnLockPartner").gameObject
	self.btnMarkPartner = self.midBtns:NodeByName("e:Group/btnMarkPartner").gameObject
	self.btnMarkPartnerSp = self.btnMarkPartner:GetComponent(typeof(UISprite))
	self.btnZoom = self.midBtns:NodeByName("btnZoom").gameObject
	self.btnShare = self.midBtns:NodeByName("btnShare").gameObject
	self.btnExSkill = self.midBtns:NodeByName("btnExSkill").gameObject
	self.btnPartnerBack = self.midBtns:NodeByName("btnPartnerBack").gameObject

	if xyd.Global.lang == "de_de" then
		self.labelAttr.fontSize = 18
		self.labelEquip.fontSize = 18
		self.labelSkin.fontSize = 18
		self.labelAwake.fontSize = 18
		self.labelStarOrigin.fontSize = 18
	end

	self.content_6 = content:NodeByName("content_6").gameObject
	self.btnStarOriginDetail = self.content_6:NodeByName("btnStarOriginDetail").gameObject
	self.labelStarOriginDetail = self.btnStarOriginDetail:ComponentByName("label", typeof(UILabel))
	self.bgStarOrigin = self.content_6:ComponentByName("bg", typeof(UITexture))
	self.imgStarOriginGroup = self.content_6:ComponentByName("imgGroup", typeof(UISprite))
	self.starOriginItem = self.content_6:NodeByName("starOriginItem").gameObject
	self.starOriginGroup = self.content_6:NodeByName("starGroup").gameObject
end

function PartnerDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initTopGroup()
	self:firstInit()
	self:updateBg()
	self:setPledgeLayout()

	if self.unableMove then
		local wndName = "battle_formation_window"
		local win = nil

		if self.if3v3 then
			wndName = "arena_3v3_battle_formation_window"
		end

		if self.isFairyTale_ then
			wndName = "activity_fairy_tale_formation_window"
		end

		win = xyd.WindowManager.get():getWindow(wndName)

		if win then
			xyd.WindowManager.get():closeWindow(wndName)
		end
	end

	self.btnBuyLabel.text = __("SKIN_TEXT26")
end

function PartnerDetailWindow:firstInit()
	self:initVars()
	self:updateNavState()
	self:updateMiscObj()
	self:updateAttr()
	self:updateGrade()
	self:updateLevUp()
	self:updateSkill()
	self:updateAwakePanel()
	self:updatePuppetNav()
	self:checkStarOriginTab()
	self:checkEquipTab()
	self:updateShenxue()
	self:registerEvent()
	self:initPartnerSkin()
	self:updateEquips()
	self:updateRedPointShow()
	self:initMarkedBtn()
	self:initFullOrderGradeUp()
	self:initFullOrderLevelUp()
	self:checkExSkillGuide()
	self:checkBtnCommentShow()
	self:checkStarOriginGuide()

	if self.enterType == xyd.PARTNER_DETAIL_ENTER_TYPE.STAR10 then
		self:changeInitNav(4)
	end
end

function PartnerDetailWindow:checkBtnCommentShow()
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.btnComment:SetActive(false)
	else
		self.btnComment:SetActive(true)
	end
end

function PartnerDetailWindow:changeInitNav(num)
	self.defaultTab.tabs[num].tab:GetComponent(typeof(UIToggle)).startsActive = true
	self.defaultTab.tabs[1].tab:GetComponent(typeof(UIToggle)).startsActive = false
end

function PartnerDetailWindow:initMarkedBtn()
	local partnerID = self.partner_:getPartnerID()

	if not partnerID then
		return
	end

	local isMarked = xyd.db.misc:getValue("marked_partner_" .. partnerID)
	local src = "btn_wsc"

	if tonumber(isMarked) == 1 then
		src = "btn_sc"
	end

	xyd.setUISpriteAsync(self.btnMarkPartnerSp, nil, src)

	if self.params_ and self.params_.showMarkBtn then
		self.btnMarkPartner:SetActive(true)

		if xyd.isIosTest() then
			self.btnMarkPartner:SetActive(false)
		end
	end

	self:checkExSkillBtn()
	self:checkPartnerBackBtn()
end

function PartnerDetailWindow:checkExSkillBtn()
	local group = xyd.tables.partnerTable:getGroup(self.partner_:getTableID())

	if not self.btnExSkillUISprite then
		self.btnExSkillUISprite = self.midBtns:ComponentByName("btnExSkill", typeof(UISprite))
	end

	if not self.btnExSkillUILabel then
		self.btnExSkillUILabel = self.btnExSkill:ComponentByName("label", typeof(UILabel))
	end

	if group and group == xyd.PartnerGroup.TIANYI then
		if xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 then
			self.btnExSkill:SetActive(true)

			if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
				self.btnExSkill:X(-595)
			end

			xyd.setUISpriteAsync(self.btnExSkillUISprite, nil, "skill_resonate_icon", nil, , true)
			xyd.applyChildrenOrigin(self.btnExSkill)

			self.btnExSkillUILabel.text = __("SKILL_RESONATE_TEXT01")

			return
		end
	elseif self.partner_:getStar() >= 10 and not xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.btnExSkill:SetActive(true)
		xyd.setUISpriteAsync(self.btnExSkillUISprite, nil, "advanced_skill", nil, , true)

		self.btnExSkillUILabel.text = __("EX_SKILL2")

		if xyd.Global.lang == "fr_fr" then
			self.btnExSkill:X(-595)
		end

		if xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 then
			xyd.applyChildrenOrigin(self.btnExSkill)
		else
			xyd.applyChildrenGrey(self.btnExSkill)
		end

		return
	end

	self.btnExSkill:SetActive(false)
end

function PartnerDetailWindow:checkPartnerBackBtn()
	if self.partner_:getStar() < 10 and not xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) and self.partner_:getStar() ~= 6 then
		self.btnPartnerBack:SetActive(true)

		self.btnPartnerBack:ComponentByName("label", typeof(UILabel)).text = __("POTENTIALITY_BACK")

		return
	end

	self.btnPartnerBack:SetActive(false)
end

function PartnerDetailWindow:initVars()
	local partner_id = self.currentSortedPartners_[self.currentIdx_]

	if not partner_id then
		xyd.WindowManager:get():closeWindow(self)
	else
		local partners = self.model_:getPartners()
		self.partner_ = partners[partner_id]
	end

	dump(self.partner_, "self.partner_")
end

function PartnerDetailWindow:updateMiscObj()
	self:updateGuideArrow()
	self:updateNameTag()

	if xyd.isH5() then
		xyd.setUISpriteAsync(self.content_1_battleIcon, nil, "force_icon", nil, )
		self.content_1_battleIcon:MakePixelPerfect()
	end

	self.labelAttr.text = __("ATTR")
	self.labelEquip.text = __("EQUIP")

	if self.status_ == "POTENTIALITY" then
		self.labelAwake.text = __("POTENTIALITY")
	elseif self.status_ == "SHENXUE" then
		self.labelAwake.text = __("SHENXUE")
	else
		self.labelAwake.text = __("AWAKE")
	end

	self.labelStarOrigin.text = __("STAR_ORIGIN_TEXT01")
	self.labelSkin.text = __("SKIN_TEXT01")
	self.labelGrade.text = __("GRADE")

	if xyd.Global.lang == "fr_fr" then
		self.labelGrade.fontSize = 18
	end

	self.labelLevUp.text = __("COST")

	if self.partner_:getLockFlags() and self.partner_:getLockFlags()[1] == 1 then
		self.btnLockPartner:SetActive(false)
		self.btnUnlockPartner:SetActive(true)
	else
		self.btnLockPartner:SetActive(true)
		self.btnUnlockPartner:SetActive(false)
	end

	self:updateCV()
	self:updateLoveIcon()
end

function PartnerDetailWindow:updateCV()
	local name = self.partner_:getCVName()

	if name ~= nil and name and name ~= "" then
		self.cvGroup:SetActive(true)

		self.cvNameLabel.text = __("CV") .. " " .. name
	else
		self.cvGroup:SetActive(false)
	end
end

function PartnerDetailWindow:updateData()
	self:initVars()
	self:updateNavState()
	self:updateMiscObj()
	self:updateAttr()
	self:updateGrade()
	self:updateLevUp()
	self:updateSkill()
	self:updateAwakePanel()
	self:updateEquips()
	self:updatePartnerSkin()
	self:updatePuppetNav()
	self:updateShenxue()
	self:checkExSkillGuide()
	self:checkStarOriginTab()
	self:checkEquipTab()
	self:checkStarOriginGuide()
end

function PartnerDetailWindow:closeSelf()
	if self.isPlaySound and self.currentDialog then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)

		self.isPlaySound = false
	end

	if self.notOpenSlotWindow then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function PartnerDetailWindow:excuteCallBack(isCloseAll)
	PartnerDetailWindow.super.excuteCallBack(self, isCloseAll)

	if isCloseAll then
		return
	end

	if self.sort_key and self:isAttrChange() then
		xyd.models.slot:sortPartners()

		local sort_detail = xyd.split(self.sort_key, "_")
		local params = {
			sortType = tonumber(sort_detail[1]),
			chosenGroup = tonumber(sort_detail[2])
		}
		local wnd = xyd.getWindow("slot_window")

		if wnd then
			wnd:updateByDetailWnd(params)
			wnd:updateSlotNum()
		end
	end
end

function PartnerDetailWindow:isAttrChange()
	return self.isAttrChange_
end

function PartnerDetailWindow:setAttrChange()
	self.isAttrChange_ = true
end

function PartnerDetailWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 25, true, handler(self, self.closeSelf))

	if self.isLongTouch then
		local function callback()
			xyd.showToast(__("IS_IN_BATTLE_FORMATION"))
		end

		local items = {
			{
				hide_plus = true,
				id = xyd.ItemID.PARTNER_EXP,
				callback = callback
			},
			{
				id = xyd.ItemID.MANA,
				callback = callback
			}
		}

		self.windowTop:setItem(items)
	else
		local items = {
			{
				hide_plus = true,
				id = xyd.ItemID.PARTNER_EXP
			},
			{
				id = xyd.ItemID.MANA
			}
		}

		self.windowTop:setItem(items)
	end

	self:fixTop()
end

function PartnerDetailWindow:fixTop()
	if not self.windowTop then
		return
	end

	local top = self.windowTop
	local itemList = top:getResItemList()

	for i = 1, #itemList do
		local item = itemList[i]
		local itemID = item:getItemID()
		local num = xyd.models.backpack:getItemNumByID(itemID)

		item:setItemNum(num - self.fakeUseRes[itemID])
	end
end

function PartnerDetailWindow:updateBg(isGuide)
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

	if isGuide and self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		local showIds = xyd.tables.partnerTable:getShowIds(self.partner_:getTableID())
		showID = tonumber(showIds[self.currentSkin])
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

function PartnerDetailWindow:updateNameTag()
	self.partnerNameTag:setInfo(self.partner_)

	local str = "potentiality_nametag_star"
	local group = self.partner_:getGroup()

	if group and group > 0 then
		str = xyd.checkPartnerGroupImgStr(group, str)
	end

	self.partnerNameTag:setCardStarImg(str)
	self.partnerNameTag:enableGroupTipsPart(self.partner_:getGroup(), 97, -59)
end

function PartnerDetailWindow:updateLoveIcon()
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		self.loveIconGo:SetActive(false)
	else
		self.loveIconGo:SetActive(true)
	end

	if xyd.isIosTest() then
		self.loveIconGo:SetActive(false)
	end

	if self.partner_:isVowed() then
		self.loveIcon.spriteName = tostring(xyd.tables.miscTable:getVal("love_point_icon_vow"))
	else
		self.loveIcon.spriteName = xyd.tables.datesTable:getIcon(self.partner_:getLovePoint())
	end
end

function PartnerDetailWindow:onPartnerVow(event)
	local data = event.data.partner_info

	if data.partner_id ~= self.partner_:getPartnerID() then
		return
	end

	self.loveIcon.spriteName = xyd.tables.miscTable:getVal("love_point_icon_vow")

	if self.isPlaySound then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)
		self.bubble:SetActive(false)

		self.isPlaySound = false
	end

	self:setPledgeLayout()
end

function PartnerDetailWindow:setPledgeLayout()
	local max_base = xyd.tables.miscTable:getNumber("love_point_max_base", "value")
	local backpack = xyd.models.backpack
	local dateRingNum = backpack:getItemNumByID(xyd.ItemID.DATES_RING)

	if self.partner_.isVowed == 0 and max_base <= self.partner_.lovePoint and dateRingNum >= 1 then
		if not self.dbPledge then
			self.dbPledge = xyd.Spine.new(self.groupPledgeEffect)

			self.dbPledge:setInfo("love_point_vow", function ()
				self.dbPledge:SetLocalPosition(0, 0, 0)
				self.dbPledge:SetLocalScale(1, 1, 1)
				self.dbPledge:setRenderTarget(self.groupPledgeEffect:GetComponent(typeof(UIWidget)), 1)
				self.dbPledge:play("texiao01", 0)
			end)
			self.groupPledgeEffect:SetActive(false)
		else
			self.dbPledge:play("texiao01", 0)
			self.groupPledgeEffect:SetActive(true)
		end
	else
		if self.dbPledge then
			self.dbPledge:stop()
		end

		self.groupPledgeEffect:SetActive(false)
	end
end

function PartnerDetailWindow:updateGuideArrow()
	if self.unableMove then
		self.arrow_left:SetActive(false)
		self.arrow_left_none:SetActive(false)
		self.arrow_right:SetActive(false)
		self.arrow_right_none:SetActive(false)

		return
	end

	if #self.currentSortedPartners_ == 1 then
		self.arrow_left:SetActive(false)
		self.arrow_left_none:SetActive(false)
		self.arrow_right:SetActive(false)
		self.arrow_right_none:SetActive(false)

		return
	end

	self.arrow_left:SetActive(true)
	self.arrow_left_none:SetActive(false)
	self.arrow_right:SetActive(true)
	self.arrow_right_none:SetActive(false)

	if self.currentIdx_ == 1 then
		self.arrow_left:SetActive(false)
		self.arrow_left_none:SetActive(true)
	end

	if self.currentIdx_ == #self.currentSortedPartners_ then
		self.arrow_right:SetActive(false)
		self.arrow_right_none:SetActive(true)
	end
end

function PartnerDetailWindow:registerEvent()
	UIEventListener.Get(self.btnBack).onClick = function ()
		xyd.WindowManager:get():closeWindow(self)
		xyd.ModelManager:get():loadModel(xyd.ModelType.SLOT):sortPartners()

		if self.sort_key then
			local sort_detail = xyd.split(self.sort_key, "_")
			local params = {
				sortType = sort_detail[1],
				chosenGroup = sort_detail[2]
			}

			xyd.WindowManager:get():openWindow("slot_window", params)
		end
	end

	UIEventListener.Get(self.arrow_left).onClick = handler(self, function ()
		self:onclickArrow(-1)
	end)
	UIEventListener.Get(self.arrow_right).onClick = handler(self, function ()
		self:onclickArrow(1)
	end)
	UIEventListener.Get(self.btnLockPartner).onClick = handler(self, function ()
		if self:checkLongTouch() then
			return
		end

		self.partner_:lock(true)
		xyd.alertTips(__("PARTNER_LOCK_TIP_1"))
	end)
	UIEventListener.Get(self.btnUnlockPartner).onClick = handler(self, function ()
		if self:checkLongTouch() then
			return
		end

		self.partner_:lock(false)
		xyd.alertTips(__("PARTNER_LOCK_TIP_2"))
	end)
	UIEventListener.Get(self.btnZoom).onClick = handler(self, self.onclickZoom)
	UIEventListener.Get(self.btnShare).onClick = handler(self, self.onclickShare)
	UIEventListener.Get(self.btnExSkill).onClick = handler(self, function ()
		if self:checkLongTouch() then
			return
		end

		local group = xyd.tables.partnerTable:getGroup(self.partner_:getTableID())

		if group and group == xyd.PartnerGroup.TIANYI then
			xyd.WindowManager.get():openWindow("skill_resonate_window", {
				partner = self.partner_
			})
		elseif xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 then
			xyd.WindowManager.get():openWindow("exskill_grade_up_window", {
				partner = self.partner_
			})
		else
			xyd.showToast(__("EX_SKILL_TIPS_TEXT"))
		end
	end)
	UIEventListener.Get(self.btnPartnerBack).onClick = handler(self, function ()
		if self:checkLongTouch() then
			return
		end

		local star = self.partner_:getStar()

		if star == 6 then
			xyd.alertTips(__("ALTAR_INFO_5"))

			return
		end

		local level = self.partner_:getLevel()

		if level == 1 then
			xyd.alertTips(__("ALTAR_INFO_6"))

			return
		end

		if self.fakeLev > 0 then
			self:partnerLevUp(true)

			self.checkOpenPartnerBackWindowFlag = true
		else
			xyd.WindowManager.get():openWindow("potentiality_back_window", {
				partner = self.partner_
			})
		end
	end)
	UIEventListener.Get(self.btnGradeUp).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("grade_up_window", self.partner_)
	end)
	UIEventListener.Get(self.btnLevUp).onClick = handler(self, self.onclickLevUp)
	UIEventListener.Get(self.btnLevUp).onPress = handler(self, self.levUpLongTouch)
	UIEventListener.Get(self.btnLevUp).onDoubleClick = handler(self, self.checkFullGradeUpCondition)
	UIEventListener.Get(self.btnFullGradeUp).onClick = handler(self, self.onfullGradeUp)
	UIEventListener.Get(self.btnFullLevelUp).onClick = handler(self, self.onfullLevelUp)
	UIEventListener.Get(self.attrDetail).onClick = handler(self, function ()
		self:updateGroupAllAttr()
		self.groupAllAttrShow:SetActive(true)
	end)
	UIEventListener.Get(self.attrClickBg).onClick = handler(self, function ()
		self.groupAllAttrShow:SetActive(false)
	end)

	for i = 1, 4 do
		UIEventListener.Get(self["emptyEquip" .. i]).onClick = handler(self, function ()
			self:onclickEmptyEquip(self.bpEquips[i])
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end)
	end

	UIEventListener.Get(self.emptyEquip5).onClick = handler(self, self.onclickEmptyTreasure)
	UIEventListener.Get(self.emptyEquip6).onClick = handler(self, function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if not self.hideBtn_ then
			self:onclickEmptySoul()
		end
	end)
	UIEventListener.Get(self.btnEquipAll).onClick = handler(self, self.onclickBtnEquipAll)
	UIEventListener.Get(self.btnUnequipAll).onClick = handler(self, function ()
		self:onClickUnEquipAll()
	end)
	UIEventListener.Get(self.btnAwake).onClick = handler(self, self.onclickAwake)
	UIEventListener.Get(self.awakeArrowLeft).onClick = handler(self, function ()
		self.awakeStarAim = self.awakeStarAim - 1

		self:updateAwakePanel()
	end)
	UIEventListener.Get(self.awakeArrowRight).onClick = handler(self, function ()
		self.awakeStarAim = self.awakeStarAim + 1

		self:updateAwakePanel()
	end)

	self.eventProxy_:addEventListener(xyd.event.ERROR_MESSAGE, function ()
		self:updateData()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.PARTNER_LEVUP, function (self, event)
		self.btnLevUpCollider.enabled = true

		if self.isFix then
			self:checkOpenPartnerBackWindow(event)

			self.isFix = false

			return
		end

		self:updateAttr()
		self:updateGrade()
		self:updateLevUp()
		self:updateSkill()
		self:updateEquips()

		local levUpEffect = nil

		if self.levUpEffect then
			levUpEffect = self.levUpEffect

			levUpEffect:play("texiao", 1, 1)
		else
			levUpEffect = xyd.Spine.new(self.effectGroup)

			levUpEffect:setInfo("shenji", function ()
				levUpEffect:SetLocalPosition(0, 0, 0)
				levUpEffect:SetLocalScale(1, 1, 1)
				levUpEffect:setRenderTarget(self.effectGroup:GetComponent(typeof(UIWidget)), 1)

				self.levUpEffect = levUpEffect

				table.insert(self.Effects, levUpEffect)
				levUpEffect:play("texiao", 1, 1)
			end)
		end

		local sequence = self:getSequence()

		sequence:Insert(0, self.labelBattlePoint.transform:DOScale(1.27, 0.2))
		sequence:Insert(0.2, self.labelBattlePoint.transform:DOScale(1, 0.4))
		sequence:Insert(0, self.labelLev.transform:DOScale(1.27, 0.2))
		sequence:Insert(0.2, self.labelLev.transform:DOScale(1, 0.4))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil

			self:updateRedPointShow()
		end)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.LOCK_PARTNER, self.updateMiscObj, self)
	self.eventProxy_:addEventListener(xyd.event.PARTNER_GRADEUP, function ()
		self:setAttrChange()
		self:updateData()
	end)
	self.eventProxy_:addEventListener(xyd.event.PARTNER_ONE_CLICK_UP, function ()
		self.fakeLev = 0

		self:initFullOrderGradeUp()
		self:setAttrChange()
		self:updateData()
	end)
	self.eventProxy_:addEventListener(xyd.event.SET_SHOW_ID, function (self, event)
		self:preViewBg()
		self:setSkinBtn()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.AWAKE_PARTNER_FINISH, function (self, event)
		if self.awakeAwardItems then
			table.insert(self.awakeAwardItems, event.data.items)
		else
			self.awakeAwardItems = {}

			table.insert(self.awakeAwardItems, event.data.items)
		end

		if self.isMutiAwake then
			self:onMutiAwake()

			return
		else
			self.awakePartnerID = nil
			self.awakeStarMax = nil
			self.awakeStarAim = nil
		end

		local tableID = self.partner_:getTableID()
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)

		if tableID == tonumber(xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[2]) and activityData and xyd.getServerTime() < activityData:getEndTime() then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)
		end

		self:setAttrChange()
		self:checkExSkillBtn()
		self:checkPartnerBackBtn()
		self:onAwakePartner(event)
		self:updateData()

		self.needStarOriginGuide = true
	end, self)
	self.eventProxy_:addEventListener(xyd.event.CHOOSE_PARTNER_POTENTIAL, function (self, event)
		self:updateData()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.SET_POTENTIALS_BAK, function (self, event)
		self:updateData()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.EQUIP, function ()
		self:setAttrChange()
		self:setSkinBtn()
		self:updateData()
		self:updateRedPointShow()
		self:updateSuitStatus()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.ROB_PARTNER_EQUIP, function ()
		self:setAttrChange()
		self:updateData()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.firstCheckFullOrder = 0

		self:setAttrChange()
		self:updateEquips()
		self:updateLevUp()
		self:updateGrade()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_UPGRADE, function (self, event)
		self:setAttrChange()
		self:updateAttr()
		self:updateEquips()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_RETURN, function (self, event)
		self:setAttrChange()
		self:updateAttr()
		self:updateEquips()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_ON, function (self, event)
		self:applyTreasureUnlockEffect(event)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_SAVE, function (self)
		self:setAttrChange()
		self:updateAttr()
		self:updateEquips()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_SELECT, function (self, event)
		self.partner_:updateAttrs()
		self:setAttrChange()
		self:updateAttr()
		self:updateEquips()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.ARTIFACT_UPGRADE, function (self)
		self:setAttrChange()
		self:updateAttr()
		self:updateEquips()
	end, self)
	self.eventProxy_:addEventListener(xyd.event.PARTNER_ATTR_CHANGE, self.onAttrChange, self)
	self.eventProxy_:addEventListener(xyd.event.SHOW_SKIN, self.onShowSkin, self)
	self.eventProxy_:addEventListener(xyd.event.COMPOSE_PARTNER, self.onShenxue, self)
	self.eventProxy_:addEventListener(xyd.event.SUIT_SKILL, self.updateSuitStatus, self)
	self:setSkinTouchEvent()

	UIEventListener.Get(self.btnComment).onClick = function ()
		if self:checkLongTouch() then
			return
		end

		local curId = 0

		if not xyd.tables.partnerTable:checkIfTaiWu(self.partner_:getTableID()) then
			curId = 2
		end

		xyd.WindowManager.get():openWindow("partner_data_station_window", {
			partner_table_id = self.partner_:getTableID(),
			table_id = self.partner_:getCommentID(),
			curId = curId
		})
		xyd.models.partnerDataStation:reqTouchId(1)
	end

	UIEventListener.Get(self.loveIconGo).onClick = function ()
		if self:checkLongTouch() then
			return
		end

		if self.isPlaySound then
			xyd.SoundManager.get():stopSound(self.currentDialog.sound)
			self.bubble:SetActive(false)

			self.isPlaySound = false
		end

		xyd.WindowManager:get():openWindow("dates_window", {
			chosenGroup = 0,
			sort_key = "3_0",
			no_back = true,
			partner_id = self.partner_:getPartnerID()
		})
	end

	UIEventListener.Get(self.skillMask).onClick = function ()
		self:clearSkillTips()
	end

	self.eventProxy_:addEventListener(xyd.event.ROLLBACK_PARTNER, self.onRollBack, self)
	self.eventProxy_:addEventListener(xyd.event.VOW, handler(self, self.onPartnerVow))
	self.eventProxy_:addEventListener(xyd.event.REPLACE_10_STAR, function ()
		self:fixCurrentIndex(self.partner_:getPartnerID())
		self:setAttrChange()
		self:updateData()
	end)
	self.eventProxy_:addEventListener(xyd.event.UPGRADE_STAR_ORIGIN, function (event)
		if self.name_ ~= "partner_detail_window" then
			return
		end

		self:updateStarOriginGroup()
		self.partner_:updateAttrs()
		self:setAttrChange()
		self:updateData()
	end)
	self.eventProxy_:addEventListener(xyd.event.RESET_STAR_ORIGIN, function (event)
		if self.name_ ~= "partner_detail_window" then
			return
		end

		self.partner_:updateStarOrigin()
		self:updateStarOriginGroup()
		self.partner_:updateAttrs()
		self:setAttrChange()
		self:updateData()
	end)

	UIEventListener.Get(self.btnShowSkin).onClick = function ()
		self.skinEffectGroup:SetActive(not self.skinEffectGroup.activeSelf)
	end

	UIEventListener.Get(self.cancelEffectGroup).onClick = function ()
		self.skinEffectGroup:SetActive(false)
	end

	UIEventListener.Get(self.tab4awakeLock).onClick = function ()
		xyd.alert(xyd.AlertType.TIPS, __("NOT_MAX_GRADE"))
	end

	UIEventListener.Get(self.partnerImgNode).onDragStart = function ()
		self:onTouchBegin()
	end

	UIEventListener.Get(self.partnerImgNode).onDrag = function (go, delta)
		self:onTouchMove(delta)
	end

	UIEventListener.Get(self.partnerImgNode).onDragEnd = function (go)
		self:onTouchEnd()
	end

	UIEventListener.Get(self.partnerImgNode).onClick = function (go)
		self:onclickPartnerImg(not self.isPartnerImgClick)
	end

	UIEventListener.Get(self.btnStarOriginDetail).onClick = function (go)
		self:onClickStarOriginBtn()
	end

	UIEventListener.Get(self.bgStarOrigin.gameObject).onClick = function (go)
		self:onClickStarOriginBtn()
	end

	UIEventListener.Get(self.btnMarkPartner).onClick = handler(self, self.onMarked)
	UIEventListener.Get(self.suitSkillIcon_.gameObject).onClick = handler(self, self.onClickSuitIcon)

	self.eventProxy_:addEventListener(xyd.event.UPGRADE_PARTNER_EX_SKILL, handler(self, self.onExUpgrade))
	self.eventProxy_:addEventListener(xyd.event.RESET_PARTNER_EX_SKILL, handler(self, self.onExUpgrade))
	self.eventProxy_:addEventListener(xyd.event.WINDOW_WILL_CLOSE, handler(self, self.onWindowWillClose))
	self.eventProxy_:addEventListener(xyd.event.USE_OPTIONAL_GIFTBOX, handler(self, self.onUseOptionalGiftBox))
end

function PartnerDetailWindow:onWindowWillClose(event)
	local windowName = event.params.windowName

	if self.needExSkillGuide then
		self:checkExSkillGuide()
	end

	if (windowName == "alert_award_window" or windowName == "potentiality_success_window" or windowName == "alert_item_window") and self.needStarOriginGuide then
		local wnd1 = xyd.getWindow("alert_award_window")
		local wnd2 = xyd.getWindow("potentiality_success_window")
		local wnd3 = xyd.getWindow("alert_item_window")

		if not wnd1 and not wnd2 and not wnd3 then
			self:checkStarOriginGuide()
		end
	end
end

function PartnerDetailWindow:onExUpgrade(event)
	self.partner_:updateExSkills(event.data.partner_info.ex_skills)
	self.partner_:updateAttrs()
	self:updateSkill()
	self:updateAttr()
end

function PartnerDetailWindow:onUseOptionalGiftBox(event)
	if event.data ~= nil then
		local item = {
			event.data
		}
		local itemData = xyd.decodeProtoBuf(event.data)

		if itemData.item_id and xyd.tables.itemTable:getType(itemData.item_id) == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(itemData.item_id)
				},
				callback = function ()
					xyd.alertItems(item)
				end
			})
		else
			xyd.alertItems(item)
		end
	end
end

function PartnerDetailWindow:onMarked()
	if self:checkLongTouch() then
		return
	end

	local key = "marked_partner_" .. self.partner_:getPartnerID()
	local isMarked = tonumber(xyd.db.misc:getValue(key))
	local tips = "COLLECTION_TOP1"
	local src = "btn_wsc"

	if isMarked == 1 then
		isMarked = 0
		tips = "COLLECTION_TOP2"
	else
		src = "btn_sc"
		isMarked = 1
	end

	xyd.models.slot:setIsCollected(self.partner_:getPartnerID(), isMarked)
	xyd.setUISpriteAsync(self.btnMarkPartnerSp, nil, src)
	xyd.alert(xyd.AlertType.TIPS, __(tips))
	self:setAttrChange()
end

function PartnerDetailWindow:onclickEmptySoul()
	if self.bpEquips[6] and #self.bpEquips[6] > 0 then
		self:onclickEmptyEquip(self.bpEquips[6])
	else
		xyd.alert(xyd.AlertType.TIPS, __("GET_FROM_STAGE", "9-9"))
	end
end

function PartnerDetailWindow:onClickNav(index)
	self:partnerLevUp(true)
	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	local old_index = self.navChosen

	if old_index == index then
		return
	end

	if index == 4 then
		if self.status_ ~= "SHENXUE" then
			local maxGrade = self.partner_:getMaxGrade()

			if self.partner_:getGrade() < maxGrade then
				xyd.alert(xyd.AlertType.TIPS, __("NOT_MAX_GRADE"))

				return
			end

			if self.status_ == "POTENTIALITY" then
				self:updateTenStarExchange()
			end

			if old_index == 5 then
				self.content_6:SetActive(false)
			else
				self["content_" .. tostring(old_index)]:SetActive(false)
			end

			self["content_" .. tostring(index)]:SetActive(true)
		else
			self.content_5:SetActive(true)
			self.shenxueFeedGroup:Reposition()
			self.shenxueStarsAfterLayout:Reposition()
			self.shenxueStarsBeforeLayout:Reposition()

			if old_index == 5 then
				self.content_6:SetActive(false)
			else
				self["content_" .. tostring(old_index)]:SetActive(false)
			end
		end
	elseif index == 5 then
		self["content_" .. tostring(old_index)]:SetActive(false)
		self["content_" .. tostring(index + 1)]:SetActive(true)

		if old_index == 4 then
			self.content_5:SetActive(false)
		end
	else
		self["content_" .. tostring(old_index)]:SetActive(false)
		self["content_" .. tostring(index)]:SetActive(true)

		if old_index == 4 then
			self.content_5:SetActive(false)
		end

		if old_index == 5 then
			self.content_6:SetActive(false)
		end
	end

	self.navChosen = index

	if index == 3 then
		self:loadSkinModel()
		self:playSkinEffect()
		self:preViewBg()
	else
		if index == 2 and xyd.tables.miscTable:getNumber("treasure_open_level", "value") <= self.partner_:getLevel() then
			local flag = tonumber(xyd.db.misc:getValue("treasure_img_guide_open"))
		end

		if index == 5 then
			self:updateStarOriginGroup()
		end

		self:stopSkinEffect()
		self:updateBg()
	end
end

function PartnerDetailWindow:updateAttr()
	local grade = self.partner_:getGrade()
	local max_lev = self.partner_:getMaxLev(grade, self.partner_:getAwake())
	local lev = self.partner_:getLevel()
	self.labelBattlePoint.text = self.partner_:getPower()
	self.labelLev.text = tostring(lev) .. "/" .. tostring(max_lev)
	self.jobIcon.spriteName = "job_icon" .. tostring(self.partner_:getJob())
	self.labelJob.text = xyd.tables.jobTextTable:getName(self.partner_:getJob())
	local attrs = self.partner_:getBattleAttrs()
	self.labelHp.text = ": " .. tostring(attrs.hp)
	self.labelAtk.text = ": " .. tostring(attrs.atk)
	self.labelDef.text = ": " .. tostring(attrs.arm)
	self.labelSpd.text = ": " .. tostring(attrs.spd)
end

function PartnerDetailWindow:updateGroupAllAttr()
	local attrs = self.partner_:getBattleAttrs()
	local bt = xyd.tables.dBuffTable
	local i = 0

	for _, key in pairs(xyd.AttrSuffix) do
		i = i + 1
		local value = attrs[key] or 0

		if bt:isShowPercent(key) then
			local factor = bt:getFactor(key)
			value = string.format("%.1f", value * 100 / bt:getFactor(key))
			value = tostring(value) .. "%"
		end

		local params = {
			string.upper(key),
			value
		}
		local label = self.groupAllAttrLables[i]

		if label == nil then
			label = AttrLabel.new(self.groupAllAttr, "large", params)
			self.groupAllAttrLables[i] = label
		else
			label:setValue(params)
		end

		if xyd.Global.lang == "de_de" then
			label.labelName.fontSize = 15
		end
	end
end

function PartnerDetailWindow:updateGrade()
	local grade = self.partner_:getGrade()
	local max_lev = self.partner_:getMaxLev(grade, self.partner_:getAwake())
	local lev = self.partner_:getLevel()

	if max_lev <= lev then
		if self.partner_:getMaxGrade() == grade then
			self.btnGradeUp:SetActive(false)
		else
			self.btnGradeUp:SetActive(true)
		end
	else
		self.btnGradeUp:SetActive(false)
	end

	local depth = self.gradeGroup:GetComponent(typeof(UIWidget)).depth + 2

	for i = 1, #self.gradeItems do
		self.gradeItems[i]:SetActive(false)
	end

	for i = 1, self.partner_:getMaxGrade() do
		if self.gradeItems[i] == nil then
			local item = NGUITools.AddChild(self.gradeGroup, self.gradeItem)

			table.insert(self.gradeItems, item)
		end

		local item = self.gradeItems[i]

		item:SetActive(true)

		local itemWidget = item:GetComponent(typeof(UIWidget))
		local img = item:NodeByName("img").gameObject
		itemWidget.depth = depth

		if grade < i then
			img:SetActive(false)
		else
			img:SetActive(true)
		end
	end

	self.gradeGroupGrid:Reposition()
end

function PartnerDetailWindow:updateLevUp()
	self.textMaxLev.text = __("MAX_LEV")
	local grade = self.partner_:getGrade()
	local max_lev = self.partner_:getMaxLev(grade, self.partner_:getAwake())
	local lev = self.partner_:getLevel()

	if max_lev <= lev then
		self.groupLevupCost:SetActive(false)
		self.btnLevUp:SetActive(false)
	else
		self.groupLevupCost:SetActive(true)
		self.btnLevUp:SetActive(true)

		local cost = xyd.tables.expPartnerTable:getCost(lev + 1)
		self.labelGoldCost.text = xyd.getRoughDisplayNumber(cost[xyd.ItemID.MANA])
		self.labelExpCost.text = xyd.getRoughDisplayNumber(cost[xyd.ItemID.PARTNER_EXP])

		if cost[xyd.ItemID.MANA] > xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) - self.fakeUseRes[xyd.ItemID.MANA] then
			self.labelGoldCost.color = Color.New2(3422556671.0)
		else
			self.labelGoldCost.color = Color.New2(960513791)
		end

		if cost[xyd.ItemID.PARTNER_EXP] > xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP) - self.fakeUseRes[xyd.ItemID.PARTNER_EXP] then
			self.labelExpCost.color = Color.New2(3422556671.0)
		else
			self.labelExpCost.color = Color.New2(960513791)
		end
	end
end

function PartnerDetailWindow:updateSkill()
	if self.isNeedSkill == false then
		return
	end

	local awake = self.partner_:getAwake()
	local skill_ids = nil

	if awake > 0 then
		skill_ids = self.partner_:getAwakeSkill(awake)
	else
		skill_ids = self.partner_:getSkillIDs()
	end

	local grade = self.partner_:getGrade()
	local skills = self.partner_:getExSkills()
	local exSkills = nil

	if skills and next(skills) ~= nil then
		exSkills = skills
	else
		exSkills = {
			0,
			0,
			0,
			0
		}
	end

	for key = 1, #skill_ids do
		local icon = nil

		if tonumber(key) > #self.skillIcons then
			icon = SkillIcon.new(self.skillGroup)
			self.skillIcons[key] = icon
		else
			icon = self.skillIcons[key]
		end

		icon.go:SetActive(true)

		local level = exSkills[key]

		if level and level > 0 then
			skill_ids[key] = xyd.tables.partnerExSkillTable:getExID(skill_ids[key])[level]
		end

		if key == 1 then
			icon:setInfo(skill_ids[key], {
				unlocked = true,
				showGroup = self.skillDesc,
				callback = function ()
					self:handleSkillTips(icon)
				end
			})
		else
			local needGrade = self.partner_:getPasTier(key - 1)

			if needGrade ~= nil and grade < needGrade then
				icon:setInfo(skill_ids[key], {
					unlocked = false,
					unlockGrade = needGrade,
					showGroup = self.skillDesc,
					callback = function ()
						self:handleSkillTips(icon)
					end
				})
			else
				icon:setInfo(skill_ids[key], {
					unlocked = true,
					showGroup = self.skillDesc,
					callback = function ()
						self:handleSkillTips(icon)
					end
				})
			end
		end
	end

	for i = #skill_ids + 1, #self.skillIcons do
		local icon = self.skillIcons[i]

		icon.go:SetActive(false)
	end

	self.skillGroupGrid:Reposition()
end

function PartnerDetailWindow:onclickLevUp()
	if not self.btnLevUp.activeSelf or not self.btnLevUpCollider.enabled then
		return
	end

	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local cost = xyd.tables.expPartnerTable:getCost(self.partner_:getLevel() + 1)
	local bp = xyd.models.backpack

	for itemID in pairs(cost) do
		if cost[itemID] > bp:getItemNumByID(tonumber(itemID)) - self.fakeUseRes[itemID] then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(itemID)))

			return
		end
	end

	self:partnerLevUp()
	self:setAttrChange()
	self:checkFullLevelUpCondition()
	xyd.SoundManager.get():playSound(xyd.SoundID.LEVEL_UP)

	local dialog = xyd.tables.partnerTable:getLvlupDialogInfo(self.partner_:getTableID(), self.partner_:getSkinID())

	self:playSound(dialog)
end

function PartnerDetailWindow:partnerLevUp(fix)
	if self.partner_.isLevingUp then
		return
	end

	if fix == nil then
		fix = false
	end

	local forceReqLev = xyd.split(xyd.tables.miscTable:getVal("partner_force_req_lev"), "|", true)
	local cost = xyd.tables.expPartnerTable:getCost(self.partner_:getLevel() + 1)

	if fix then
		if self.fakeLev > 0 then
			self.isFix = true

			self.partner_:levUp(self.fakeLev)
		end

		for itemID in pairs(cost) do
			self.fakeUseRes[itemID] = 0
		end

		self.fakeLev = 0
	elseif not xyd.tableContains(forceReqLev, self.partner_:getLevel()) then
		for itemID in pairs(cost) do
			self.fakeUseRes[itemID] = self.fakeUseRes[itemID] + tonumber(cost[itemID])
		end

		self.fakeLev = self.fakeLev + 1

		self.partner_:fakeLevUp()
		self:fixTop()
	else
		for itemID in pairs(cost) do
			self.fakeUseRes[itemID] = 0
		end

		self.partner_:levUp(self.fakeLev + 1)

		self.fakeLev = 0
	end
end

function PartnerDetailWindow:levUpLongTouch(go, isPressed)
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local longTouchFunc = nil

	function longTouchFunc()
		self:onclickLevUp()

		if self.levUpLongTouchFlag == true then
			XYDCo.WaitForTime(0.2, function ()
				if not self or not go or go.activeSelf == false then
					return
				end

				longTouchFunc()
			end, "levUpLongTouchClick")
		end
	end

	XYDCo.StopWait("levUpLongTouch")

	if isPressed then
		self.levUpLongTouchFlag = true

		XYDCo.WaitForTime(0.5, function ()
			if not self then
				return
			end

			if self.levUpLongTouchFlag then
				longTouchFunc()
				self:checkFullGradeUpCondition()
			end
		end, "levUpLongTouch")
	else
		self.levUpLongTouchFlag = false
	end
end

function PartnerDetailWindow:initFullOrderGradeUp()
	self.waitTimeKey = 0
	self.firstCheckFullOrder = 0
	self.btnFullGradeUp:ComponentByName("button_label", typeof(UILabel)).text = __("MAX")

	if next(self.waitForTimeKeys_) then
		for i = 1, #self.waitForTimeKeys_ do
			XYDCo.StopWait(self.waitForTimeKeys_[i])
		end

		self.waitForTimeKeys_ = {}
	end

	self.showIndex = 0

	if self.showMaxUpSeq then
		self.showMaxUpSeq:Append(xyd.getTweenAlpha(self.btnFullGradeUp:GetComponent(typeof(UISprite)), 0, 0))

		self.showMaxUpSeq = nil
	end

	self.btnFullGradeUp:SetActive(false)
end

function PartnerDetailWindow:checkFullGradeUpCondition()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local PartnerTable = xyd.tables.partnerTable
	local partnerID = self.partner_:getTableID()
	local maxStarNum = PartnerTable:getStar(partnerID)
	local show_ids = PartnerTable:getShowIds(partnerID)
	local partnerGrade = self.partner_:getGrade()
	local partnerLevel = self.partner_:getLevel()
	local maxLevel = xyd.tables.miscTable:getVal("one_click_upgrade_level")

	if maxStarNum <= 4 or #show_ids < 2 or partnerGrade >= 6 or partnerLevel >= 100 or xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		return
	end

	local hasSuperPartner = false
	local partners = xyd.models.slot:getPartners()

	for id in pairs(partners) do
		local partner = partners[id]

		if partner:getStar() >= 10 then
			hasSuperPartner = true

			break
		end
	end

	if not hasSuperPartner then
		return
	end

	local costMANA = xyd.tables.expPartnerTable:getAllMoney(maxLevel) - xyd.tables.expPartnerTable:getAllMoney(partnerLevel)
	local costEXP = xyd.tables.expPartnerTable:getAllExp(maxLevel) - xyd.tables.expPartnerTable:getAllExp(partnerLevel)
	local costSTONE = 0
	local maxGrade = 5

	if maxStarNum >= 6 then
		maxGrade = 6
	end

	if self.firstCheckFullOrder == 0 then
		for i = partnerGrade + 1, maxGrade do
			local GradeUpCost = PartnerTable:getGradeUpCost(partnerID, i)
			costMANA = costMANA + GradeUpCost[xyd.ItemID.MANA]
			costSTONE = costSTONE + GradeUpCost[xyd.ItemID.GRADE_STONE]
		end

		local ownMANA = xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) - self.fakeUseRes[xyd.ItemID.MANA]
		local ownEXP = xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP) - self.fakeUseRes[xyd.ItemID.PARTNER_EXP]
		local ownSTONE = xyd.models.backpack:getItemNumByID(xyd.ItemID.GRADE_STONE)

		if costMANA <= ownMANA and costEXP <= ownEXP and costSTONE <= ownSTONE then
			self.firstCheckFullOrder = 1

			self:showFullGradeUpBtn()
		end
	end
end

function PartnerDetailWindow:showFullGradeUpBtn()
	self.showIndex = self.showIndex + 1
	local btnSprite = self.btnFullGradeUp:GetComponent(typeof(UISprite))

	self.btnFullGradeUp:SetActive(true)

	if not self.showMaxUpSeq then
		self.showMaxUpSeq = self:getSequence()

		self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 0, 0))
		self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 1, 1))
	end

	local duration = xyd.tables.miscTable:getVal("one_click_upgrade_duration")

	self:waitForTime(duration, function ()
		if self.showIndex > 0 then
			self.showIndex = self.showIndex - 1
		end

		if self.showIndex == 0 and self.showMaxUpSeq then
			self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 0, 1))
			self:waitForTime(1, function ()
				self.firstCheckFullOrder = 0
				self.showMaxUpSeq = nil
			end)
		end
	end, "show_full_grade_up_btn" .. self.waitTimeKey)

	self.waitTimeKey = self.waitTimeKey + 1
end

function PartnerDetailWindow:onfullGradeUp()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	xyd.WindowManager:get():openWindow("full_order_grade_up_window", self.partner_)
end

function PartnerDetailWindow:initFullOrderLevelUp()
	self.waitTimeKey = 0
	self.firstCheckFullOrder = 0
	self.btnFullLevelUp:ComponentByName("button_label", typeof(UILabel)).text = __("MAX")

	if next(self.waitForTimeKeys_) then
		for i = 1, #self.waitForTimeKeys_ do
			XYDCo.StopWait(self.waitForTimeKeys_[i])
		end

		self.waitForTimeKeys_ = {}
	end

	self.showIndex = 0

	if self.showMaxUpSeq then
		self.showMaxUpSeq:Append(xyd.getTweenAlpha(self.btnFullLevelUp:GetComponent(typeof(UISprite)), 0, 0))

		self.showMaxUpSeq = nil
	end

	self.btnFullLevelUp:SetActive(false)
end

function PartnerDetailWindow:checkFullLevelUpCondition()
	if self.partner_:getGrade() ~= self.partner_:getMaxGrade() then
		return
	end

	local max_lev = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake())
	local partnerLevel = self.partner_:getLevel()

	if max_lev < partnerLevel + 20 then
		return
	end

	local costMANA = xyd.tables.expPartnerTable:getAllMoney(partnerLevel + 20) - xyd.tables.expPartnerTable:getAllMoney(partnerLevel)
	local costEXP = xyd.tables.expPartnerTable:getAllExp(partnerLevel + 20) - xyd.tables.expPartnerTable:getAllExp(partnerLevel)

	if self.firstCheckFullOrder == 0 then
		local ownMANA = xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) - self.fakeUseRes[xyd.ItemID.MANA]
		local ownEXP = xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP) - self.fakeUseRes[xyd.ItemID.PARTNER_EXP]

		if costMANA <= ownMANA and costEXP <= ownEXP then
			self.firstCheckFullOrder = 1

			self:showFullLevelUpBtn()
		end
	end
end

function PartnerDetailWindow:showFullLevelUpBtn()
	self.showIndex = self.showIndex + 1
	local btnSprite = self.btnFullLevelUp:GetComponent(typeof(UISprite))

	self.btnFullLevelUp:SetActive(true)

	if not self.showMaxUpSeq then
		self.showMaxUpSeq = self:getSequence()

		self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 0, 0))
		self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 1, 1))
	end

	local duration = xyd.tables.miscTable:getVal("one_click_upgrade_duration")

	self:waitForTime(duration, function ()
		if self.showIndex > 0 then
			self.showIndex = self.showIndex - 1
		end

		if self.showIndex == 0 and self.showMaxUpSeq then
			self.showMaxUpSeq:Append(xyd.getTweenAlpha(btnSprite, 0, 1))
			self:waitForTime(1, function ()
				self.firstCheckFullOrder = 0
				self.showMaxUpSeq = nil
			end)
		end
	end, "show_full_level_up_btn" .. self.waitTimeKey)

	self.waitTimeKey = self.waitTimeKey + 1
end

function PartnerDetailWindow:onfullLevelUp()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	xyd.WindowManager:get():openWindow("full_order_level_up_window", {
		partner = self.partner_,
		fakeUseRes = self.fakeUseRes,
		fakeLev = self.fakeLev,
		levUpCallback = function ()
			if not self then
				return
			end

			for itemID in pairs(self.fakeUseRes) do
				self.fakeUseRes[itemID] = 0
			end

			self.fakeLev = 0

			self:initFullOrderLevelUp()
		end
	})
end

function PartnerDetailWindow:handleSkillTips(icon)
	if self.showSkillTips then
		return
	end

	self.showSkillTips = true
	self.showSkillIcon = icon

	icon:showTips(true, icon.showGroup, 1000)
	self.skillMask:SetActive(true)
end

function PartnerDetailWindow:clearSkillTips()
	if self.showSkillIcon then
		self.showSkillIcon:showTips(false, self.showSkillIcon.showGroup)
		self.skillMask:SetActive(false)
	end

	self.showSkillTips = false
end

function PartnerDetailWindow:onAttrChange(event)
	if not self then
		return
	end

	local changed_attr = event.data.changed_attr

	if self.partner_:getPartnerID() ~= event.data.partnerID then
		return
	end

	if self.attrTipsAction then
		self.attrTipsAction:Kill(false)

		self.attrTipsAction = nil

		self.attrChangeGroup:SetActive(false)
	end

	local index = 0

	if next(changed_attr) == nil then
		return
	end

	for key in pairs(changed_attr) do
		index = index + 1
		local tip = nil

		if self.attrTipsItems[index] == nil then
			self.attrTipsItems[index] = AttrTipsItem.new(self.attrChangeGroup)
		end

		tip = self.attrTipsItems[index]

		tip:SetActive(true)
		tip:setInfo(key, changed_attr[key])
	end

	for i = index + 1, #self.attrTipsItems do
		local tip = self.attrTipsItems[i]

		tip:SetActive(false)
	end

	local w = self.attrChangeGroup:GetComponent(typeof(UIWidget))

	local function getter()
		return w.color
	end

	local function setter(color)
		w.color = color
	end

	self.attrChangeGroup:SetLocalPosition(50, 500, 0)
	self.attrChangeGroup:SetActive(true)
	self.attrChangeGroupTable:Reposition()

	local sequence = self:getSequence()

	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))
	sequence:Insert(0.5, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.4))
	sequence:Insert(0.5, self.attrChangeGroup.transform:DOLocalMoveY(530, 0.4))
	sequence:AppendCallback(handler(self, function ()
		self.attrTipsAction:Kill(false)

		self.attrTipsAction = nil
	end))

	self.attrTipsAction = sequence
end

function PartnerDetailWindow:updateEquips()
	local equips = self.partner_:getEquipment()
	self.bpEquips = {}
	local bp = xyd.models.backpack
	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local datas = bp:getItems()

	for i = 1, #datas do
		local itemID = datas[i].item_id
		local itemNum = datas[i].item_num
		local item = {
			itemID = itemID,
			itemNum = itemNum
		}
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos ~= nil then
			self.bpEquips[pos] = self.bpEquips[pos] or {}

			table.insert(self.bpEquips[pos], item)
		end
	end

	local equipsOfPartners = xyd.models.slot:getEquipsOfPartners()

	for key, _ in pairs(equipsOfPartners) do
		local itemID = tonumber(key)
		local itemNum = 1
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos then
			for _, partner_id in ipairs(equipsOfPartners[key]) do
				local item = {
					itemID = itemID,
					itemNum = itemNum,
					partner_id = partner_id
				}
				self.bpEquips[pos] = self.bpEquips[pos] or {}

				table.insert(self.bpEquips[pos], item)
			end
		end
	end

	for key in ipairs(equips) do
		local itemID = equips[key]

		if tonumber(key) == 7 then
			-- Nothing
		elseif tonumber(key) == 5 then
			if itemID > 0 then
				self["iconEquip" .. key]:setInfo({
					noClickSelected = true,
					switch = true,
					itemID = itemID,
					callback = function ()
						if self.isShrineHurdle_ then
							xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

							return
						end

						self:onclickTreasure(itemID)
					end,
					switch_func = function ()
						if self.isShrineHurdle_ then
							xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

							return
						end

						self:onclickTreasureExchange(itemID)
					end
				})
				self["iconEquip" .. key]:SetActive(true)
				self["iconEquip" .. key]:setLockLowerRight(self.partner_.select_treasure ~= 1)
				self:applyLockEffect(self.equipLock, false)
			else
				self["iconEquip" .. key]:SetActive(false)
				self["plusEquip" .. key]:SetActive(false)

				local open_lev = xyd.tables.miscTable:getVal("treasure_open_level")

				if tonumber(open_lev) <= self.partner_:getLevel() then
					self:applyLockEffect(self.equipLock, true)
				else
					self:applyLockEffect(self.equipLock, false)
				end
			end
		elseif itemID > 0 then
			local itemEffect = nil

			if tonumber(key) == 6 and xyd.tables.equipTable:getQuality(itemID) >= 5 and xyd.tables.equipTable:getArtifactUpNext(itemID) == 0 then
				itemEffect = "hunqiui"
			end

			self["iconEquip" .. key]:setInfo({
				noClickSelected = true,
				itemID = itemID,
				callback = function ()
					self:onclickEquip(itemID, self.bpEquips[key])
				end,
				effect = itemEffect
			})

			if not itemEffect then
				self["iconEquip" .. key]:setEffectState(false)
			else
				self["iconEquip" .. key]:setEffectState(true)
			end

			self["iconEquip" .. key]:SetActive(true)
			self:applyPlusEffect(self["plusEquip" .. key], false, key)
		else
			if self:ifhasBpEquip(key) then
				self["plusEquip" .. key]:SetActive(false)
				self:applyPlusEffect(self["plusEquip" .. key], true, key)
			else
				self["plusEquip" .. key]:SetActive(false)
				self:applyPlusEffect(self["plusEquip" .. key], false, key)
			end

			self["iconEquip" .. key]:SetActive(false)
		end
	end

	self:updateEquipRedMark()

	self.btnEquipAllLabel.text = __("EQUIP_ALL")

	xyd.setBgColorType(self.btnEquipAll, xyd.ButtonBgColorType.blue_btn_65_65)

	self.btnUnequipAllLabel.text = __("UNEQUIP_ALL")

	xyd.setBgColorType(self.btnUnequipAll, xyd.ButtonBgColorType.red_btn_65_65)
	self:updateSuitStatus()
end

function PartnerDetailWindow:ifhasBpEquip(key)
	if not self.bpEquips[key] or #self.bpEquips[key] <= 0 then
		return false
	end

	for _, equip in pairs(self.bpEquips[key]) do
		if not equip.partner_id then
			return true
		end
	end

	return false
end

function PartnerDetailWindow:updateSuitStatus()
	local skillIndex = self.partner_.skill_index
	local tableId = self.partner_.tableID
	local job = xyd.tables.partnerTable:getJob(tableId)
	local hasSuit = self:checkSuit(job)
	self.hasSuit_ = hasSuit

	if skillIndex and skillIndex > 0 and hasSuit then
		local skillID = tonumber(self:getSuitSkill(skillIndex))

		if skillID and skillID > 0 then
			self.suitGroup_:SetActive(true)
			self.suitSkillRed_:SetActive(false)

			local iconName = xyd.tables.skillTable:getSkillIcon(skillID)

			xyd.setUISpriteAsync(self.suitSkillIcon_, nil, iconName)
			self:initSuitEffect(job)
		end
	elseif hasSuit then
		self.suitGroup_:SetActive(true)
		self.suitSkillRed_:SetActive(true)

		if self.suitEffect_ then
			self.suitEffect_:SetActive(false)
		end

		local jobToName = {
			"icon_zybq_zs",
			"icon_zybq_fs",
			"icon_zybq_yx",
			"icon_zybq_ck",
			"icon_zybq_ms"
		}

		xyd.setUISpriteAsync(self.suitSkillIcon_, nil, jobToName[job])
	else
		self.suitGroup_:SetActive(false)
	end
end

function PartnerDetailWindow:initSuitEffect(job)
	local jobToEffect = {
		5,
		1,
		4,
		2,
		3
	}

	if not self.suitEffect_ then
		self.suitEffect_ = xyd.Spine.new(self.suitSkillEffectRoot_)

		self.suitEffect_:setInfo("fx_ui_jobsuit_skill", function ()
			self.suitEffect_:play("texiao0" .. jobToEffect[job], 0, 1)
		end)
	else
		self.suitEffect_:play("texiao0" .. jobToEffect[job], 0, 1)
	end
end

function PartnerDetailWindow:onClickSuitIcon()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local skillIndex = self.partner_.skill_index
	local skill_list = self:getSuitSkill()

	if skillIndex and skillIndex > 0 then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			skillIndex = skillIndex
		})
	elseif self.hasSuit_ then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list
		})
	end
end

function PartnerDetailWindow:getSuitSkill(skillIndex)
	local equips = self.partner_:getEquipment()

	for key in ipairs(equips) do
		local itemID = equips[key]

		if itemID and itemID > 0 then
			local forms = xyd.tables.equipTable:getForm(itemID)

			if forms and #forms > 0 then
				local skills = xyd.tables.equipTable:getSuitSkills(itemID)

				if skillIndex then
					return skills[skillIndex]
				else
					return skills
				end
			end
		end
	end
end

function PartnerDetailWindow:checkSuit(job)
	local equips = self.partner_:getEquipment()
	local tempItem = {}
	local tempSuits = {}

	for key in ipairs(equips) do
		local itemID = equips[key]

		if itemID and itemID > 0 then
			table.insert(tempItem, itemID)

			local forms = xyd.tables.equipTable:getForm(itemID)

			if forms and #forms > 0 then
				table.insert(tempSuits, forms)
			end
		end
	end

	for i = 1, #tempSuits do
		local suitsTable = tempSuits[i]
		local suitNum = 0

		for _, itemID in ipairs(tempItem) do
			if xyd.arrayIndexOf(suitsTable, tostring(itemID)) > 0 then
				suitNum = suitNum + 1
				local skills = xyd.tables.equipTable:getSuitSkills(itemID)

				if suitNum >= 4 and skills and #skills > 0 then
					local job_ = xyd.tables.equipTable:getJob(itemID)

					if job_ == job then
						return true
					end
				end
			end
		end
	end

	return false
end

function PartnerDetailWindow:onclickEmptyTreasure()
	local open_lev = xyd.tables.miscTable:getVal("treasure_open_level")

	if self.partner_:getLevel() < tonumber(open_lev) then
		xyd.alert(xyd.AlertType.TIPS, __("TREASURE_NOT_OPEN"))
	else
		self.partner_:treasureOn()
	end
end

function PartnerDetailWindow:onclickTreasure(itemID)
	local cost = xyd.tables.equipTable:getTreasureUpCost(itemID)
	local btnLayout = cost and 4 or 1
	local is_spare = self.partner_.select_treasure ~= 1

	if is_spare then
		btnLayout = 0
	end

	local params = {
		itemID = itemID,
		btnLayout = btnLayout,
		is_spare_crystal = is_spare,
		rightLabel = __("LEV_UP"),
		rightColor = xyd.ButtonBgColorType.blue_btn_65_65,
		rightCallback = function ()
			xyd.WindowManager:get():openWindow("treasure_up_window", {
				itemID = itemID,
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		leftLabel = __("TRANSFORM"),
		leftColor = xyd.ButtonBgColorType.blue_btn_65_65,
		leftCallback = function ()
			xyd.WindowManager:get():openWindow("treasure_change_window", {
				itemID = itemID,
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_,
				tmpTreasure = self.partner_:getTmpTreasure()
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		midCallback = function ()
			xyd.WindowManager:get():openWindow("treasure_change_window", {
				itemID = itemID,
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_,
				tmpTreasure = self.partner_:getTmpTreasure()
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		midColer = xyd.ButtonBgColorType.blue_btn_65_65,
		midLabel = __("TRANSFORM")
	}
	local equip_lv = xyd.tables.equipTable:getItemLev(itemID)

	if equip_lv > 1 and not params.is_spare_crystal then
		function params.resetCallBack()
			xyd.WindowManager.get():closeWindow("item_tips_window")
			xyd.WindowManager.get():openWindow("treasure_back_window", {
				item_id = itemID,
				partner_id = self.partner_:getPartnerID()
			})
		end
	end

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

function PartnerDetailWindow:onclickTreasureExchange(itemID)
	xyd.WindowManager:get():openWindow("treasure_select_window", {
		type = 1,
		itemID = itemID,
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_
	})
end

function PartnerDetailWindow:onclickEquip(itemID, equips)
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local itemTable = xyd.tables.itemTable
	local upArrowCallback = nil

	if itemTable:getType(itemID) == xyd.ItemType.ARTIFACT and xyd.tables.equipTable:getArtifactUpNext(itemID) ~= 0 then
		function upArrowCallback()
			xyd.WindowManager:get():openWindow("artifact_up_window", {
				itemID = itemID,
				equips = equips,
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end
	end

	local params = {
		btnLayout = 4,
		equipedOn = self.partner_:getInfo(),
		equipedPartner = self.partner_,
		itemID = itemID,
		equips = equips,
		rightLabel = __("REPLACE"),
		rightColor = xyd.ButtonBgColorType.blue_btn_65_65,
		upArrowCallback = upArrowCallback,
		rightCallback = function ()
			xyd.WindowManager:get():openWindow("choose_equip_window", {
				equips = equips,
				now_equip = itemID,
				equipedOn = self.partner_:getInfo(),
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		leftLabel = __("REMOVE"),
		leftColor = xyd.ButtonBgColorType.red_btn_65_65,
		leftCallback = function ()
			self.partner_:unEquipSingle(itemID)
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end
	}

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

function PartnerDetailWindow:onclickEmptyEquip(equips)
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	xyd.WindowManager:get():openWindow("choose_equip_window", {
		equips = equips,
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_
	})
end

function PartnerDetailWindow:onclickBtnEquipAll()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local equips = self.partner_:getEquipment()
	local now_equips = {}
	local flag_changed = false

	for index in pairs(equips) do
		now_equips[index] = equips[index]
	end

	for index in pairs(self.bpEquips) do
		local old_i_lv = xyd.tables.equipTable:getItemLev(equips[index]) or 0
		local max_lv = -1
		local bestItemID = nil

		for i in ipairs(self.bpEquips[index]) do
			if not self.bpEquips[index][i].partner_id then
				local equip_job = xyd.tables.equipTable:getJob(self.bpEquips[index][i].itemID)

				if not equip_job or equip_job == 0 or self.partner_:getJob() == equip_job then
					local i_lv = xyd.tables.equipTable:getItemLev(self.bpEquips[index][i].itemID)

					if max_lv < i_lv then
						bestItemID = self.bpEquips[index][i].itemID
						max_lv = i_lv
					elseif i_lv == max_lv and tonumber(index) < 4 then
						local i_job = xyd.tables.equipTable:getJob(self.bpEquips[index][i].itemID)
						local bestItemID_job = xyd.tables.equipTable:getJob(bestItemID)

						if self.partner_:getJob() == i_job and self.partner_:getJob() ~= bestItemID_job then
							bestItemID = self.bpEquips[index][i].itemID
						end
					end
				end
			end
		end

		if old_i_lv < max_lv then
			now_equips[index] = bestItemID
			flag_changed = true
		elseif max_lv == old_i_lv and self.partner_:getJob() == xyd.tables.equipTable:getJob(bestItemID) and self.partner_:getJob() ~= xyd.tables.equipTable:getJob(equips[index]) then
			xyd.models.slot:deleteEquip(now_equips[index], self.partner_:getPartnerID())

			now_equips[index] = bestItemID

			xyd.models.slot:addEquip(bestItemID, self.partner_:getPartnerID())

			flag_changed = true
		else
			now_equips[index] = equips[index]
		end
	end

	if flag_changed then
		xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_ON)
		self.partner_:equip(now_equips)
	end
end

function PartnerDetailWindow:updateEquipRedMark()
	local equips = self.partner_:getEquipment()
	local flags = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local now_equips = {}

	for key, value in pairs(equips) do
		now_equips[key] = value
	end

	for index in pairs(self.bpEquips) do
		local old_i_lv = xyd.tables.equipTable:getItemLev(equips[index]) or 0
		local tmp_max_lv = -1

		for i in pairs(self.bpEquips[index]) do
			if not self.bpEquips[index][i].partner_id then
				local equip_job = xyd.tables.equipTable:getJob(self.bpEquips[index][i].itemID)
				local equip_job2 = xyd.tables.equipTable:getJob(equips[index])

				if not equip_job or equip_job == 0 or self.partner_:getJob() == equip_job then
					local i_lv = xyd.tables.equipTable:getItemLev(self.bpEquips[index][i].itemID)

					if tmp_max_lv < i_lv then
						tmp_max_lv = i_lv
					end

					if old_i_lv < tmp_max_lv and old_i_lv ~= 0 then
						flags[index] = 1

						break
					elseif tmp_max_lv == old_i_lv and tonumber(index) < 4 and (not equip_job2 or equip_job2 ~= self.partner_:getJob()) and equip_job and self.partner_:getJob() == equip_job then
						flags[index] = 1
					end
				end
			end
		end
	end

	for i = 1, #flags do
		self["iconEquip" .. i]:showRedMark(flags[i] == 1)
	end
end

function PartnerDetailWindow:applyPlusEffect(obj, show, key)
	local parent = obj.transform.parent

	if show then
		local effect = self.equipPlusEffects[key]

		if not effect then
			effect = xyd.Spine.new(parent.gameObject)

			effect:setInfo("jiahao", function ()
				effect:SetLocalScale(1.01, 0.95, 1)
				effect:SetLocalPosition(21, -26, 0)
				effect:setRenderTarget(self.equipEffectRender, 1)
				effect:play("texiao01", 0)
			end)

			self.equipPlusEffects[key] = effect
		else
			effect:play("texiao01", 0)
		end

		return
	end

	local effect = self.equipPlusEffects[key]

	if effect then
		effect:stop()
		effect:SetActive(false)
	end
end

function PartnerDetailWindow:applyLockEffect(obj, show)
	local parent = obj.transform.parent

	if show then
		local equipLockEffect = self.equipLockEffect

		if equipLockEffect == nil then
			equipLockEffect = xyd.Spine.new(parent.gameObject)

			equipLockEffect:setInfo("suodaiji", function ()
				equipLockEffect:SetLocalPosition(0, -3, 0)
				equipLockEffect:SetLocalScale(1, 1, 1)
				equipLockEffect:setRenderTarget(self.equipEffectRender, 1)
				equipLockEffect:play("texiao01", 0)
			end)

			self.equipLockEffect = equipLockEffect
		else
			equipLockEffect:play("texiao01", 0)
		end

		return
	end

	local equipLockEffect = self.equipLockEffect

	if equipLockEffect then
		equipLockEffect:stop()
		equipLockEffect:SetActive(false)
	end
end

function PartnerDetailWindow:applyTreasureUnlockEffect(event)
	self:applyLockEffect(self.equipLock, false)

	local parent = self.equipLock.transform.parent
	local effect = xyd.Spine.new(parent.gameObject)

	effect:setInfo("sbao", function ()
		effect:SetLocalPosition(0, -3, 0)
		effect:SetLocalScale(1.01, 0.95, 1)
		effect:setRenderTarget(self.equipEffectRender, 1)
		effect:play("texiao01", 1, 1, function ()
			self:updateData()

			local item_id = event.data.partner_info.equips[xyd.EquipPos.TREASURE]

			xyd.alertItems({
				{
					item_num = 1,
					item_id = item_id
				}
			})
		end)
	end)
end

function PartnerDetailWindow:initPartnerSkin()
	self.btnSkinOnLabel.text = __("SKIN_TEXT02")
	self.btnSkinOffLabel.text = __("SKIN_TEXT03")
	self.btnSkinUnlockLabel.text = __("SKIN_TEXT22")

	xyd.setBgColorType(self.btnSkinOn, xyd.ButtonBgColorType.blue_btn_65_65)
	xyd.setBgColorType(self.btnSkinOff, xyd.ButtonBgColorType.red_btn_65_65)
	xyd.setBgColorType(self.btnSelectPicture, xyd.ButtonBgColorType.blue_btn_65_65)
	xyd.setBgColorType(self.btnSkinUnlock, xyd.ButtonBgColorType.blue_btn_65_65)
	self:initSkinEffect()
	self:updatePartnerSkin()
end

function PartnerDetailWindow:updatePartnerSkin()
	local tableID = self.partner_:getTableID()
	local showIDsBase = xyd.tables.partnerTable:getShowIds(tableID)
	local showIDs = showIDsBase

	if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		showIDs = {
			tonumber(showIDsBase[1])
		}
	end

	local showID = self.partner_:getShowID()
	self.skinIDs = {}
	self.skinCards = {}
	local dressSkinID = self.partner_:getSkinID()

	NGUITools.DestroyChildren(self.groupSkinCards.transform)

	for i = 1, #showIDs do
		local skinID = showIDs[i]
		local card = PartnerCard.new(self.groupSkinCards)

		card:setTouchListener(function ()
			self:setMultiSkinState(i)
		end)

		local tmpPartner = Partner.new(self.groupSkinCards)
		local collectionID = xyd.tables.itemTable:getCollectionId(skinID)
		local qlt = nil

		if collectionID and collectionID > 0 then
			qlt = xyd.tables.collectionTable:getQlt(collectionID)
		end

		tmpPartner:populate({
			tableID = skinID,
			star = xyd.tables.partnerTable:getStar(skinID)
		})
		card:setDefaultSkinCard(tmpPartner, qlt)
		card:setQltLowerThanPartnerName()
		table.insert(self.skinCards, card)
		table.insert(self.skinIDs, tonumber(skinID))
	end

	self.skinState = -1
	local skinIDs = {}

	if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		table.insert(skinIDs, tonumber(showIDsBase[2]))
		table.insert(skinIDs, tonumber(showIDsBase[3]))
	end

	local tempSkinIDs = xyd.tables.partnerTable:getSkins(tostring(tableID))

	if next(skinIDs) == nil then
		skinIDs = tempSkinIDs
	else
		for i, id in pairs(tempSkinIDs) do
			table.insert(skinIDs, id)
		end
	end

	if xyd.Global.isReview == 1 then
		skinIDs = {}
	end

	for i = 1, #skinIDs do
		local skinID = skinIDs[i]
		local showTime = xyd.tables.partnerPictureTable:getShowTime(skinID)

		if showTime and showTime <= xyd.getServerTime() then
			local card = PartnerCard.new(self.groupSkinCards)

			card:setTouchListener(function ()
				self:setMultiSkinState(i + #showIDs)
			end)

			local group = self.partner_:getGroup()
			local collectionID = xyd.tables.itemTable:getCollectionId(skinID)
			local qlt = nil

			if collectionID and collectionID > 0 then
				qlt = xyd.tables.collectionTable:getQlt(collectionID)
			end

			local data = {
				is_equip = false,
				tableID = tableID,
				group = group,
				skin_id = skinID,
				qlt = qlt
			}

			card:setSkinCard(data)

			if skinID == dressSkinID then
				card:setSkinCollect(true)
			end

			card:setDisplay()
			card:showSkinNum()
			card:setQltLowerThanPartnerName()

			if group == xyd.PartnerGroup.TIANYI then
				if i == 1 then
					card:setOnlySkin()
					card:setSkinName(__("SKIN_TEXT27"))
				elseif i == 2 then
					card:setOnlySkin()
					card:setSkinName(__("SKIN_TEXT28"))
				end
			end

			table.insert(self.skinCards, card)
			table.insert(self.skinIDs, skinID)
		end
	end

	self.groupSkinCardsGrid:Reposition()

	if dressSkinID == 0 or dressSkinID ~= showID then
		if showID and showID ~= self.partner_:getTableID() then
			if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
				self.currentSkin = xyd.arrayIndexOf(self.skinIDs, showID)
			else
				self.currentSkin = xyd.arrayIndexOf(self.skinIDs, showID)
			end
		else
			local star = self.partner_:getStar()

			if star <= 5 then
				self.currentSkin = 1
			elseif star < 10 then
				self.currentSkin = 2
			else
				self.currentSkin = 3
			end

			local group = self.partner_:getGroup()

			if group == xyd.PartnerGroup.TIANYI then
				if star <= 12 then
					self.currentSkin = 1
				elseif star < 15 then
					self.currentSkin = 2
				else
					self.currentSkin = 3
				end
			end
		end
	else
		self.currentSkin = xyd.arrayIndexOf(self.skinIDs, dressSkinID)
	end

	self:setSkinState(0)

	local isShow = self.partner_:isShowSkin()

	if dressSkinID == 0 then
		self.btnSetSkinVisible:SetActive(false)
	else
		local btnSetSkinVisibleSprite = self.btnSetSkinVisible:GetComponent(typeof(UISprite))

		self.btnSetSkinVisible:SetActive(true)

		if isShow then
			btnSetSkinVisibleSprite.spriteName = "skin_btn02"
		else
			btnSetSkinVisibleSprite.spriteName = "skin_btn01"
		end
	end

	for i = 1, #self.skinCards do
		local card = self.skinCards[i].go

		UIEventListener.Get(card).onDragStart = function ()
			self:onScrollBegin()
		end

		UIEventListener.Get(card).onDrag = function (go, delta)
			self:onScrollMove(delta)
		end

		UIEventListener.Get(card).onDragEnd = function (go)
			self:onScrollEnd()
		end
	end
end

function PartnerDetailWindow:setMultiSkinState(target_ind)
	if self.isMove then
		return
	end

	if self.currentSkin == target_ind then
		local currentSkinID = self.skinIDs[self.currentSkin]
		local tableID = self.partner_:getTableID()

		xyd.WindowManager:get():openWindow("skin_tip_window", {
			skin_id = currentSkinID,
			tableID = tableID
		})
	end

	self.currentSkin = target_ind

	self:setSkinState(0.5)
end

function PartnerDetailWindow:setSkinState(ease)
	if ease == nil then
		ease = 0
	end

	for i = 1, #self.skinCards do
		local card = self.skinCards[i]

		if self.currentSkin == i then
			card:setGroupScale(1, ease)
		else
			card:setGroupScale(0.9, ease)
		end
	end

	self:setSkinBtn()

	if self.isMove then
		return
	end

	local transform = self.groupSkinCards.transform

	if ease == 0 then
		self.groupSkinCards:SetLocalPosition(-166 * (self.currentSkin - 1), transform.localPosition.y, 0)
	else
		self.isMove = true
		local sequence = self:getSequence()

		sequence:Append(self.groupSkinCards.transform:DOLocalMoveX(-166 * (self.currentSkin - 1), ease))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil
			self.isMove = false

			self.groupSkinCards:SetLocalPosition(-166 * (self.currentSkin - 1), transform.localPosition.y, 0)
		end)
	end

	self:updateNameTag()

	if self.navChosen == 3 or self.navChosen == 4 then
		self:preViewBg()
	end
end

function PartnerDetailWindow:setSkinTouchEvent()
	UIEventListener.Get(self.groupCardTouch).onDragStart = function ()
		self:onScrollBegin()
	end

	UIEventListener.Get(self.groupCardTouch).onDrag = function (go, delta)
		self:onScrollMove(delta)
	end

	UIEventListener.Get(self.groupCardTouch).onDragEnd = function (go)
		self:onScrollEnd()
	end

	UIEventListener.Get(self.btnSkinOn).onClick = handler(self, self.onSkinOn)
	UIEventListener.Get(self.btnSkinOff).onClick = handler(self, self.onSkinOff)
	UIEventListener.Get(self.btnSetSkinVisible).onClick = handler(self, self.onSetSkinvisible)
	UIEventListener.Get(self.btnSelectPicture).onClick = handler(self, self.onSetPicture)
	UIEventListener.Get(self.btnBuy).onClick = handler(self, self.onBuyTouch)
	UIEventListener.Get(self.groupTouch).onClick = handler(self, self.onModelTouch)

	UIEventListener.Get(self.btnSkinUnlock).onClick = function ()
		local currentSkinID = self.skinIDs[self.currentSkin]

		xyd.WindowManager.get():openWindow("skin_unlock_window", {
			id = currentSkinID
		})
	end
end

function PartnerDetailWindow:onScrollBegin(event)
	self.scrollX = 0
end

function PartnerDetailWindow:onScrollMove(delta)
	self.scrollX = self.scrollX + delta.x
end

function PartnerDetailWindow:onScrollEnd(event)
	if self.isMove then
		return
	end

	if self.scrollX > 10 and self.currentSkin > 1 then
		self.currentSkin = self.currentSkin - 1

		self:setSkinState(0.6)
	elseif self.scrollX < -10 and self.currentSkin < #self.skinIDs then
		self.currentSkin = self.currentSkin + 1

		self:setSkinState(0.6)
	end
end

function PartnerDetailWindow:onSkinOn()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local currentSkinID = self.skinIDs[self.currentSkin]

	if self.partner_:getGroup() ~= xyd.PartnerGroup.TIANYI and currentSkinID > 0 and xyd.models.backpack:getItemNumByID(currentSkinID) <= 0 then
		return
	end

	local equip = self.partner_:getEquipment()

	self.partner_:equip({
		equip[1],
		equip[2],
		equip[3],
		equip[4],
		equip[5],
		equip[6],
		currentSkinID
	})

	self.skinState = currentSkinID
end

function PartnerDetailWindow:onSkinOff()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local equip = self.partner_:getEquipment()

	if equip[7] == 0 then
		return
	end

	self.partner_:equip({
		equip[1],
		equip[2],
		equip[3],
		equip[4],
		equip[5],
		equip[6],
		0
	})

	self.skinState = 0
end

function PartnerDetailWindow:setSkinBtn()
	local skinID = self.partner_:getSkinID()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local card = self.skinCards[self.currentSkin]
	local group = self.partner_:getGroup()
	local star = self.partner_:getStar()

	card:showSkinNum()

	for i = 1, #self.skinIDs do
		local card0 = self.skinCards[i]

		if group ~= xyd.PartnerGroup.TIANYI then
			card0:setSkinCollect(self.skinIDs[i] == skinID or skinID == 0 and self.skinIDs[i] == self.partner_:getTableID())
		elseif group == xyd.PartnerGroup.TIANYI then
			card0:setSkinCollect(false)

			if self.skinIDs[i] == skinID then
				card0:setSkinCollect(true)
			elseif skinID == 0 then
				if star >= 15 then
					card0:setSkinCollect(i == 3)
				elseif star >= 13 then
					card0:setSkinCollect(i == 2)
				elseif star >= 10 then
					card0:setSkinCollect(i == 1)
				end
			end
		end
	end

	if self.skinState == skinID then
		xyd.alert(xyd.AlertType.TIPS, __("SKIN_TEXT09"))
	end

	self.skinState = -1
	local curStar = self.partner_:getStar()
	local hero_list = xyd.tables.partnerTable:getHeroList(self.partner_:getTableID())
	local max_star = 0

	for i = 1, #hero_list do
		local star = xyd.tables.partnerTable:getStar(hero_list[i]) or 1
		max_star = math.max(max_star, star)
	end

	self.showBtnBuy_ = false
	local group = self.partner_:getGroup()

	if group ~= xyd.PartnerGroup.TIANYI and max_star >= 10 and self.currentSkin <= 3 or max_star <= 9 and self.currentSkin <= 2 or max_star <= 5 and self.currentSkin <= 1 or group == xyd.PartnerGroup.TIANYI and curStar <= 15 and self.currentSkin <= 3 then
		self.btnSkinUnlock:SetActive(false)

		if group ~= xyd.PartnerGroup.TIANYI and (curStar >= 10 and self.currentSkin <= 3 or curStar >= 6 and self.currentSkin <= 2 or curStar <= 5 and self.currentSkin <= 1) or group == xyd.PartnerGroup.TIANYI and (curStar >= 15 and self.currentSkin <= 3 or curStar >= 13 and self.currentSkin <= 2 or curStar < 13 and self.currentSkin <= 1) then
			local showID = self.partner_:getShowID() or self.partner_:getTableID()

			if showID == self.skinIDs[self.currentSkin] then
				self.btnSelectPictureLabel.text = __("PARTNER_CANCEL_PICTURE")

				if self.partner_:getSkinID() == 0 and (group ~= xyd.PartnerGroup.TIANYI and (curStar >= 10 and self.currentSkin == 3 or curStar < 10 and self.currentSkin == 2 or curStar <= 5 and self.currentSkin == 1) or group == xyd.PartnerGroup.TIANYI and (curStar >= 15 and self.currentSkin == 3 or curStar <= 13 and self.currentSkin == 2 or curStar < 13 and self.currentSkin == 1)) then
					xyd.setEnabled(self.btnSelectPicture, false)
				else
					xyd.setEnabled(self.btnSelectPicture, true)
				end
			else
				self.btnSelectPictureLabel.text = __("PARTNER_CHOOSE_PICTURE")

				if string.lower(xyd.Global.lang) == "en_en" then
					self.btnSelectPictureLabel.fontSize = 22
				end

				xyd.setEnabled(self.btnSelectPicture, true)
			end

			self.btnSkinOn:SetActive(false)
			self.btnSkinOff:SetActive(false)
			self.textGroup:SetActive(false)
			self.btnSelectPicture:SetActive(true)
			self.btnBuy:SetActive(false)

			self.labelSkinDesc.text = __("SKIN_TEXT06", self.partner_:getName())
		else
			self.btnSkinOn:SetActive(false)
			self.btnSkinOff:SetActive(false)
			self.btnSelectPicture:SetActive(false)
			self.textGroup:SetActive(true)
			self.btnBuy:SetActive(false)

			self.wayDescLabel.text = __("SKIN_TEXT18")

			if group ~= xyd.PartnerGroup.TIANYI then
				if self.currentSkin == 2 then
					self.wayLabel.text = __("SKIN_TEXT19")
				elseif self.currentSkin == 3 then
					self.wayLabel.text = __("SKIN_TEXT20")
				end
			elseif self.currentSkin == 2 then
				self.wayLabel.text = __("PARTNER_GROUP_7_SKIN_TEXT", 13)
			elseif self.currentSkin == 3 then
				self.wayLabel.text = __("PARTNER_GROUP_7_SKIN_TEXT", 15)
			end
		end
	else
		self.btnSelectPicture:SetActive(false)
		self.textGroup:SetActive(false)
		self.btnSkinUnlock:SetActive(false)
		self.btnBuy:SetActive(false)

		if skinID == currentSkinID then
			self.btnSkinOff:SetActive(true)
			self.btnSkinOn:SetActive(false)
		else
			self.btnSkinOff:SetActive(false)
			self.btnSkinOn:SetActive(true)
		end

		if self.btnSkinOn.activeSelf and xyd.tables.itemTable:getType(currentSkinID) == xyd.ItemType.SKIN then
			xyd.applyOrigin(self.btnSkinOn:GetComponent(typeof(UISprite)))

			self.btnSkinOnLabel.color = Color.New(1, 1, 1, 1)
			self.btnSkinOnCollider.enabled = true

			if xyd.models.backpack:getItemNumByID(currentSkinID) <= 0 then
				if self:checkOtherSkinOnOtherPartner(self.partner_.tableID, currentSkinID) then
					self.btnSkinOnCollider.enabled = false

					xyd.applyDark(self.btnSkinOn:GetComponent(typeof(UISprite)))

					self.btnSkinOnLabel.color = Color.New(0.7, 0.7, 0.7, 1)
				else
					self.btnSkinOn:SetActive(false)

					if xyd.tables.skinTable:checkInTable(currentSkinID) then
						self.btnSkinUnlock:SetActive(true)
					elseif xyd.tables.shopSkinTable:itemCanBuy(currentSkinID) then
						self.btnBuy:SetActive(true)

						self.showBtnBuy_ = true
					else
						self.textGroup:SetActive(true)

						self.wayDescLabel.text = __("SKIN_TEXT18")
						local collectionId = xyd.tables.itemTable:getCollectionId(currentSkinID)
						self.wayLabel.text = xyd.tables.collectionTextTable:getDesc(collectionId)

						print("self.wayLabel.text", self.wayLabel.text)
					end
				end
			end
		else
			xyd.applyOrigin(self.btnSkinOn:GetComponent(typeof(UISprite)))

			self.btnSkinOnLabel.color = Color.New(1, 1, 1, 1)
			self.btnSkinOnCollider.enabled = true
		end

		self.btnSetSkinVisible:SetActive(skinID > 0 and skinID == currentSkinID)
	end

	if group ~= xyd.PartnerGroup.TIANYI and (max_star >= 10 and self.currentSkin <= 3 or max_star >= 6 and self.currentSkin <= 2 or max_star <= 5 and self.currentSkin <= 1) or group == xyd.PartnerGroup.TIANYI and curStar <= 15 and self.currentSkin <= 3 then
		local sufix = ""

		if self.currentSkin == 1 then
			sufix = "06"
		elseif self.currentSkin == 2 then
			sufix = "16"
		else
			sufix = "17"
		end

		self.labelSkinDesc.text = __("SKIN_TEXT" .. tostring(sufix), self.partner_:getName())

		if group == xyd.PartnerGroup.TIANYI then
			if self.currentSkin == 1 then
				self.labelSkinDesc.text = __("SKIN_TEXT06", self.partner_:getName())
			elseif self.currentSkin == 2 then
				self.labelSkinDesc.text = __("PARTNER_GROUP_7_SKIN_TEXT2", self.partner_:getName(), 13)
			else
				self.labelSkinDesc.text = __("PARTNER_GROUP_7_SKIN_TEXT2", self.partner_:getName(), 15)
			end
		end
	else
		print("self.labelSkinDesc.text", self.labelSkinDesc.text)

		self.labelSkinDesc.text = xyd.tables.equipTextTable:getSkinDesc(currentSkinID)
	end

	if currentSkinID == 7226 and xyd.Global.lang == "de_de" then
		self.labelSkinDesc.width = 450
	else
		self.labelSkinDesc.width = 348
	end

	self:loadSkinModel()
end

function PartnerDetailWindow:checkOtherSkinOnOtherPartner(table_id, skin_id)
	local list = xyd.tables.partnerTable:getHeroList(table_id)

	for j = 1, #list do
		local li = xyd.models.slot:getListByTableID(list[j])

		for i = 1, #li do
			local partner = li[i]
			local equip = partner:getEquipment()

			if equip[7] == skin_id then
				return true
			end
		end
	end

	return false
end

function PartnerDetailWindow:loadSkinModel()
	local skinID = self.partner_:getSkinID()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local tableID = self.partner_:getTableID()
	local modelID = 0
	local curStar = self.partner_:getStar()
	local hero_list = xyd.tables.partnerTable:getHeroList(self.partner_:getTableID())
	local max_star = self.partner_:getStar()

	for i = 1, #hero_list do
		max_star = math.max(max_star, xyd.tables.partnerTable:getStar(hero_list[i]))
	end

	if max_star >= 10 and self.currentSkin <= 3 or max_star >= 6 and self.currentSkin <= 2 or max_star <= 5 and self.currentSkin <= 1 then
		if xyd.tables.itemTable:getType(currentSkinID) == xyd.ItemType.SKIN then
			modelID = xyd.tables.equipTable:getSkinModel(currentSkinID)
		else
			modelID = xyd.tables.partnerTable:getModelID(self.skinIDs[self.currentSkin])
		end
	elseif xyd.tables.itemTable:getType(currentSkinID) ~= xyd.ItemType.SKIN then
		modelID = xyd.tables.partnerTable:getModelID(tableID)
	else
		modelID = xyd.tables.equipTable:getSkinModel(currentSkinID)
	end

	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	if self.skinModel and self.skinModel:getName() == name or self.navChosen ~= 3 then
		return
	end

	if self.skinModel then
		self.skinModel:destroy()

		if self.skinModel:getName() == xyd.tables.modelTable:getModelName(5500604) then
			self.skinModel:cleanUp()
		end
	end

	local model = xyd.Spine.new(self.groupModel)

	model:setInfo(name, function ()
		self.modelID = modelID

		model:SetLocalPosition(0, 0, 0)
		model:SetLocalScale(scale, scale, 1)
		model:setRenderTarget(self.groupModel:GetComponent(typeof(UIWidget)), 5)

		if self.navChosen == 3 then
			model:play("idle", 0)
		end
	end)

	self.skinModel = model
end

function PartnerDetailWindow:onSetSkinvisible()
	local isShow = self.partner_:isShowSkin() and 0 or 1

	if not self.partner_:getSkinID() then
		self.btnSetSkinVisible:SetActive(false)
	else
		self.btnSetSkinVisible:SetActive(true)

		local btnSetSkinVisibleSprite = self.btnSetSkinVisible:GetComponent(typeof(UISprite))

		if isShow == 1 then
			btnSetSkinVisibleSprite.spriteName = "skin_btn02"
		else
			btnSetSkinVisibleSprite.spriteName = "skin_btn01"
		end
	end

	local partnerID = self.partner_:getPartnerID()

	xyd.models.slot:setShowSkin(partnerID, isShow)
end

function PartnerDetailWindow:onSetPicture()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local showID = self.partner_:getShowID()
	local skin = self.partner_:getSkinID()
	local group = self.partner_:getGroup()

	if group == xyd.PartnerGroup.TIANYI or xyd.tables.itemTable:getType(currentSkinID) ~= xyd.ItemType.SKIN then
		if showID == currentSkinID then
			local id = nil

			if xyd.tables.itemTable:getType(skin) == xyd.ItemType.SKIN then
				id = skin
			else
				id = self.partner_:getTableID()

				if self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
					local curStar = self.partner_:getStar()

					if curStar >= 15 then
						id = self.skinIDs[3]
					elseif curStar <= 13 then
						id = self.skinIDs[2]
					elseif curStar <= 10 then
						id = self.skinIDs[1]
					end
				end
			end

			self.partner_:changeShowID(id)
			xyd.alert(xyd.AlertType.TIPS, __("HAVE_CANCEL_PICTURE"))
		else
			self.partner_:changeShowID(currentSkinID)
			xyd.alert(xyd.AlertType.TIPS, __("HAVE_CHOOSE_PICTURE"))
		end
	end
end

function PartnerDetailWindow:onShowSkin()
	if self.partner_:isShowSkin() then
		xyd.alert(xyd.AlertType.TIPS, __("SKIN_TEXT08"))
	else
		xyd.alert(xyd.AlertType.TIPS, __("SKIN_TEXT07"))
	end
end

function PartnerDetailWindow:initSkinEffect()
	if self.skinEffect1 then
		return
	end

	self.skinEffect1 = xyd.Spine.new(self.groupEffect1)
	self.skinEffect2 = xyd.Spine.new(self.groupEffect2)

	self.skinEffect1:setInfo("fx_ui_fazhen", function ()
		self.skinEffect1:SetLocalPosition(0, 0, -10)
		self.skinEffect1:SetLocalScale(1, 1, 1)
		self.skinEffect1:setRenderTarget(self.groupEffect1:GetComponent(typeof(UIWidget)), 10)
	end)
	self.skinEffect2:setInfo("fx_ui_fazhen", function ()
		self.skinEffect2:SetLocalPosition(0, 0, 0)
		self.skinEffect2:SetLocalScale(1, 1, 1)
		self.skinEffect2:setRenderTarget(self.groupEffect2:GetComponent(typeof(UIWidget)), 1)
	end)
	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function PartnerDetailWindow:playSkinEffect()
	if self.skinModel then
		self.skinModel:play("idle", 0, 1, nil, true)
	end

	if not self.skinEffect1 then
		return
	end

	if not self.skinEffect2 then
		return
	end

	self.skinEffect1:play("texiao01", 0, 1, nil, true)
	self.skinEffect2:play("texiao02", 0, 1, nil, true)
	self.groupEffect1:SetActive(true)
	self.groupEffect2:SetActive(true)
end

function PartnerDetailWindow:stopSkinEffect()
	if self.skinModel then
		self.skinModel:stop()
	end

	if self.skinEffect1 then
		self.skinEffect1:stop()
	end

	if self.skinEffect1 then
		self.skinEffect2:stop()
	end

	self.groupEffect1:SetActive(false)
	self.groupEffect2:SetActive(false)
end

function PartnerDetailWindow:onModelTouch()
	if not self.skinModel then
		return
	end

	local tableID = self.partner_:getTableID()
	local mp = xyd.tables.partnerTable:getEnergyID(tableID)
	local ack = xyd.tables.partnerTable:getPugongID(tableID)
	local skillID = 0

	if xyd.getServerTime() % 2 > 0 then
		skillID = mp

		if self.modelID ~= 5500602 and self.modelID ~= 5500603 and self.modelID ~= 5500604 and self.modelID ~= 5500605 then
			self.skinModel:play("skill", 1, 1, function ()
				self.skinModel:play("idle", 0)
			end)
		else
			self.skinModel:play("skill01", 1, 1, function ()
				self.skinModel:play("idle", 0)
			end)
		end
	else
		skillID = ack

		self.skinModel:play("attack", 1, 1, function ()
			self.skinModel:play("idle", 0)
		end, true)
	end

	if self.skillSound then
		xyd.SoundManager.get():stopSound(self.skillSound)
	end

	self.skillSound = xyd.tables.skillTable:getSound(skillID)

	xyd.SoundManager.get():playSound(self.skillSound)
end

function PartnerDetailWindow:preViewBg()
	local currentSkinID = self.skinIDs[self.currentSkin]
	local showID = self.partner_:getShowID()
	local skinID = self.partner_:getSkinID()

	if xyd.tables.itemTable:getType(skinID) == xyd.ItemType.SKIN and showID == nil then
		self.partner_:changeShowID(skinID)

		return
	end

	showID = currentSkinID

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

function PartnerDetailWindow:updateTab4(state)
	if state == "default" then
		self.defaultTab.tabs[4].label:SetActive(true)
		self.tab4none:SetActive(false)
		self.tab4awakeLock:SetActive(false)
		self.labelAwake:X(0)
	elseif state == "none" then
		self.defaultTab.tabs[4].label:SetActive(false)
		self.tab4none:SetActive(true)
		self.tab4awakeLock:SetActive(false)
		self.labelAwake:X(0)
	elseif state == "lock" then
		self.defaultTab.tabs[4].label:SetActive(true)
		self.tab4none:SetActive(true)
		self.tab4awakeLock:SetActive(true)
		self.labelAwake:X(19)
	end

	if self.tab4none.activeSelf == false then
		self.nav4_redPoint:SetActive(false)
	end
end

function PartnerDetailWindow:updateAwakePanel()
	self:updateTab4("default")

	if self.partner_:getStar() >= 6 then
		self.defaultTab:setTabEnable(4, true)

		local setFake = nil

		function setFake(is_fake)
			local flag = not is_fake

			self.starChange:SetActive(flag)
			self.skillChange:SetActive(flag)
			self.attrUp_1:SetActive(flag)
			self.attrUp_2:SetActive(flag)
			self.feedIcons:SetActive(flag)
			self.btnAwake:SetActive(flag)
			self.awakeCost:SetActive(flag)
			self.fakeIcons:SetActive(false)
			self.labelMaxAwake:SetActive(not flag)
			self.awakeAttrChangeBg:SetActive(flag)
			self.exchangeComponent:SetActive(false)
			self.awakeArrowLeft:SetActive(false)
			self.awakeArrowRight:SetActive(false)

			if flag then
				self.fakeStars:SetActive(false)
				self.fakeTenStar:SetActive(false)
			elseif self.partner_:getStar() > 9 then
				self.fakeStars:SetActive(false)
				self.fakeTenStar:SetActive(false)
			else
				self.fakeStars:SetActive(not flag)
				self.fakeTenStar:SetActive(flag)
			end
		end

		self:updateAwakeData()

		if self:checkAwake2Top() then
			setFake(true)

			if self.partner_:getStar() > 9 then
				self:updateTenStarExchange()
			else
				self:updateAwakeLabel()
			end
		else
			setFake(false)
			self:updateAwakeStar()
			self:updateAwakeSkill()
			self:updateAwakeLabel()
			self:createAwakeHeroIcon()
			self:updateAwakeArrow()
		end

		local maxGrade = self.partner_:getMaxGrade()

		if self.partner_:getGrade() < maxGrade then
			self:updateTab4("lock")

			if self.navChosen == 4 then
				self.defaultTab:setTabActive(1, true)
			end
		elseif self.navChosen == 4 then
			self.defaultTab:setTabActive(4, true)
		else
			self.defaultTab:setTabActive(4, false)
		end
	end

	self.awakeSelectedPartners = {}
end

function PartnerDetailWindow:checkAwake2Top()
	if self.partner_:getStar() >= 10 then
		return true
	elseif xyd.tables.partnerTable:getTenId(self.partner_:getTableID()) == 0 and self.partner_:getAwake() >= 3 then
		return true
	else
		return false
	end
end

function PartnerDetailWindow:updateAwakeLabel()
	self.labelMaxAwake.text = __("MAX_AWAKE")

	if self:checkAwake2Top() then
		return
	end

	self.labelAttrUp.text = __("ATTR_UP")
	self.labelMaxLevUp.text = __("TOP_LEV_UP_TO")

	if self.awakeStarAim == 10 then
		local np = Partner.new()

		np:populate({
			table_id = xyd.tables.partnerTable:getTenId(self.partner_:getTableID())
		})

		self.labelMaxLev.text = __(np:getMaxLev())
		self.labelAttrNum.text = tostring(20 * (self.awakeStarAim - self.partner_:getStar()) + 10) .. "%"
	else
		local star = self.awakeStarAim
		local awake = star - 6
		self.labelMaxLev.text = __(self.partner_:getMaxLev(self.partner_:getGrade(), awake))
		self.labelAttrNum.text = tostring(20 * (self.awakeStarAim - self.partner_:getStar())) .. "%"
	end

	local bp = xyd.models.backpack
	local costNum = 0

	for i = self.partner_:getStar(), self.awakeStarAim - 1 do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeItemCost(self.partner_:getTableID(), awake)
		cost = xyd.checkCondition(cost and #cost > 0, cost, {
			xyd.ItemID.GRADE_STONE,
			0
		})
		costNum = costNum + cost[2]
	end

	local resNum = bp:getItemNumByID(xyd.ItemID.GRADE_STONE)
	self.labelCostRes.text = "/" .. tostring(costNum)
	self.labelCostResHas.text = xyd.getRoughDisplayNumber(resNum)

	if resNum < costNum then
		self.labelCostResHas.color = Color.New2(3422556671.0)
	else
		self.labelCostResHas.color = Color.New2(1432789759)
	end

	xyd.setUISpriteAsync(self.imgCostRes, nil, xyd.tables.itemTable:getSmallIcon(xyd.ItemID.GRADE_STONE))

	self.btnAwakeLabel.text = __("AWAKE")

	xyd.setBgColorType(self.btnAwake, xyd.ButtonBgColorType.blue_btn_70_70)
end

function PartnerDetailWindow:updateAwakeData()
	if not self.awakePartnerID then
		self.awakePartnerID = self.partner_:getPartnerID()
	end

	if self.awakePartnerID ~= self.partner_:getPartnerID() then
		self.awakePartnerID = self.partner_:getPartnerID()
		self.awakeStarMax = nil
		self.awakeStarAim = nil
	end

	if not self.awakeStarMax then
		self.awakeStarMax = 9
		local tableID = self.partner_:getTableID()
		local tenTableID = xyd.tables.partnerTable:getTenId(tableID)

		if tenTableID ~= 0 then
			self.awakeStarMax = 10
		end
	end

	if not self.awakeStarAim then
		self.awakeStarAim = math.min(self.partner_:getStar() + 1, self.awakeStarMax)
	end
end

function PartnerDetailWindow:updateAwakeArrow()
	if self.awakeStarAim <= self.partner_:getStar() + 1 then
		self.awakeArrowLeft:SetActive(false)
	else
		self.awakeArrowLeft:SetActive(true)
	end

	if self.awakeStarMax <= self.awakeStarAim then
		self.awakeArrowRight:SetActive(false)
	else
		self.awakeArrowRight:SetActive(true)
		self:updateAwakeRedPoint()
	end
end

function PartnerDetailWindow:updateAwakeRedPoint()
	local canAwakeRedPoint = true
	local costNum = 0
	local star5PartnerID = xyd.tables.partnerTable:getHeroList(self.partner_:getTableID())[1]

	for i = self.partner_:getStar(), self.awakeStarAim do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeItemCost(self.partner_:getTableID(), awake)
		cost = xyd.checkCondition(cost and #cost > 0, cost, {
			xyd.ItemID.GRADE_STONE,
			0
		})
		costNum = costNum + cost[2]
	end

	local resNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.GRADE_STONE)

	if resNum < costNum then
		canAwakeRedPoint = false
	end

	local materials = {}

	for i = self.partner_:getStar(), self.awakeStarAim do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeMaterial(self.partner_:getTableID(), awake)

		for i = 1, #cost do
			table.insert(materials, cost[i])
		end
	end

	if not materials or not next(materials) then
		return
	end

	local m_detail = {}

	for _, heroID in ipairs(materials) do
		if not m_detail[heroID] then
			m_detail[heroID] = {}
		end

		if heroID == star5PartnerID then
			local commonHeroID = heroID - heroID % 1000 + 999

			if not m_detail[commonHeroID] then
				m_detail[commonHeroID] = {}
			end

			m_detail[commonHeroID].needNum = (m_detail[commonHeroID].needNum or 0) + 1
		end

		if heroID % 1000 == 999 then
			local star = xyd.tables.partnerIDRuleTable:getStar(heroID)
			local group = xyd.tables.partnerIDRuleTable:getGroup(heroID)
			local heroIcon = xyd.tables.partnerIDRuleTable:getIcon(heroID)
			local num = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID] = {
				star = star,
				group = group,
				needNum = num,
				heroIcon = heroIcon,
				partners = {}
			}
		else
			m_detail[heroID].needNum = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID].tableID = m_detail[heroID].tableID or heroID
			m_detail[heroID].partners = {}
		end

		m_detail[heroID].noClickSelected = true
		m_detail[heroID].notPlaySaoguang = true
	end

	for key in pairs(m_detail) do
		local benchPartners = {}

		if m_detail[key].tableID then
			self:awakeAddPartnersById(m_detail[key].tableID, benchPartners)
		else
			self:awakeAddPartnersByParams(m_detail[key], benchPartners)
		end

		if m_detail[key].needNum > #benchPartners then
			canAwakeRedPoint = false
		end
	end

	if canAwakeRedPoint == true then
		self.awakeRedPoint:SetActive(true)
	else
		self.awakeRedPoint:SetActive(false)
	end
end

function PartnerDetailWindow:updateAwakeStar()
	local star = self.partner_:getStar()

	local function initStarItem(parent, fill)
		local star = NGUITools.AddChild(parent, self.starGroup)

		if not fill then
			local starRed = star:NodeByName("starRed").gameObject

			starRed:SetActive(false)
		end
	end

	local function initTenStarItem(parent, num)
		NGUITools.AddChild(parent, self.tenStarGroup)
	end

	NGUITools.DestroyChildren(self.stars1.transform)
	NGUITools.DestroyChildren(self.stars2.transform)

	for i = 6, 9 do
		if i <= star then
			initStarItem(self.stars1, true)
		else
			initStarItem(self.stars1, false)
		end
	end

	if self.awakeStarAim == 10 then
		initTenStarItem(self.stars2, 0)
	else
		for i = 6, 9 do
			if i <= self.awakeStarAim then
				initStarItem(self.stars2, true)
			else
				initStarItem(self.stars2, false)
			end
		end
	end

	self.stars1Grid:Reposition()
	self.stars2Grid:Reposition()
end

function PartnerDetailWindow:updateAwakeSkill()
	local skills_old, skills_new = nil

	if self.partner_:getStar() == 6 then
		skills_old = self.partner_:getSkillIDs()
	else
		skills_old = self.partner_:getAwakeSkill(self.partner_:getAwake())
	end

	if self.awakeStarAim == 10 then
		local star9_skills = self.partner_:getAwakeSkill(3)
		local np = Partner.new()

		np:populate({
			table_id = xyd.tables.partnerTable:getTenId(self.partner_:getTableID())
		})

		local star10_skills = np:getSkillIDs()
		skills_new = star9_skills
		skills_new[1] = star10_skills[1]
	else
		local star = self.awakeStarAim
		local awake = star - 6
		skills_new = self.partner_:getAwakeSkill(awake)
	end

	local skillOldList = {}
	local skillNewList = {}

	for i = 2, #skills_old do
		if tonumber(skills_old[i]) ~= tonumber(skills_new[i]) then
			table.insert(skillOldList, skills_old[i])
			table.insert(skillNewList, skills_new[i])
		end
	end

	if skills_old and skills_old[1] and tonumber(skills_old[1]) ~= tonumber(skills_new[1]) then
		table.insert(skillOldList, skills_old[1])
		table.insert(skillNewList, skills_new[1])
	end

	NGUITools.DestroyChildren(self.awakeSkillBeforeLine1.transform)
	NGUITools.DestroyChildren(self.awakeSkillBeforeLine2.transform)
	NGUITools.DestroyChildren(self.awakeSkillAfterLine1.transform)
	NGUITools.DestroyChildren(self.awakeSkillAfterLine2.transform)

	local skillNum = #skillOldList

	for i = 1, math.min(2, skillNum) do
		local skillItem = NGUITools.AddChild(self.awakeSkillBeforeLine1, self.skillItem)
		skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
		self["oldSkill" .. i] = SkillIcon.new(skillItem)

		self["oldSkill" .. i]:setInfo(skillOldList[i], {
			showLev = true,
			showGroup = self.awakeSkillDesc,
			callback = function ()
				self:handleSkillTips(self["oldSkill" .. i])
			end
		})

		UIEventListener.Get(self["oldSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:clearSkillTips()
			end
		end
	end

	for i = 3, skillNum do
		local skillItem = NGUITools.AddChild(self.awakeSkillBeforeLine2, self.skillItem)
		skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
		self["oldSkill" .. i] = SkillIcon.new(skillItem)

		self["oldSkill" .. i]:setInfo(skillOldList[i], {
			showLev = true,
			showGroup = self.awakeSkillDesc,
			callback = function ()
				self:handleSkillTips(self["oldSkill" .. i])
			end
		})

		UIEventListener.Get(self["oldSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:clearSkillTips()
			end
		end
	end

	for i = 1, math.min(2, skillNum) do
		local skillItem = NGUITools.AddChild(self.awakeSkillAfterLine1, self.skillItem)
		skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
		self["newSkill" .. i] = SkillIcon.new(skillItem)

		self["newSkill" .. i]:setInfo(skillNewList[i], {
			showLev = true,
			showGroup = self.awakeSkillDesc,
			callback = function ()
				self:handleSkillTips(self["newSkill" .. i])
			end
		})

		UIEventListener.Get(self["newSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:clearSkillTips()
			end
		end
	end

	for i = 3, skillNum do
		local skillItem = NGUITools.AddChild(self.awakeSkillAfterLine2, self.skillItem)
		skillItem:GetComponent(typeof(UIWidget)).depth = 250 + i * 10
		self["newSkill" .. i] = SkillIcon.new(skillItem)

		self["newSkill" .. i]:setInfo(skillNewList[i], {
			showLev = true,
			showGroup = self.awakeSkillDesc,
			callback = function ()
				self:handleSkillTips(self["newSkill" .. i])
			end
		})

		UIEventListener.Get(self["newSkill" .. i].go).onSelect = function (go, isSelect)
			if isSelect == false then
				self:clearSkillTips()
			end
		end
	end

	if skillNum < 3 then
		self.awakeSkillBeforeLine1:GetComponent(typeof(UILayout)).gap = Vector2(14.285714285714286, 0)
		self.awakeSkillAfterLine1:GetComponent(typeof(UILayout)).gap = Vector2(14.285714285714286, 0)
	else
		self.awakeSkillBeforeLine1:GetComponent(typeof(UILayout)).gap = Vector2(31.42857142857143, 0)
		self.awakeSkillAfterLine1:GetComponent(typeof(UILayout)).gap = Vector2(31.42857142857143, 0)
	end

	self.awakeSkillBeforeLine1:GetComponent(typeof(UILayout)):Reposition()
	self.awakeSkillBeforeLine2:GetComponent(typeof(UILayout)):Reposition()
	self.awakeSkillAfterLine1:GetComponent(typeof(UILayout)):Reposition()
	self.awakeSkillAfterLine2:GetComponent(typeof(UILayout)):Reposition()

	if skillNum == 4 then
		self.awakeSkillBefore:X(-217)
		self.awakeSkillAfter:X(181)
	else
		self.awakeSkillBefore:X(-199)
		self.awakeSkillAfter:X(199)
	end

	if skillNum < 3 then
		self.awakeSkillBeforeLine1:Y(2)
		self.awakeSkillAfterLine1:Y(2)
	else
		self.awakeSkillBeforeLine1:Y(15)
		self.awakeSkillAfterLine1:Y(15)
	end
end

function PartnerDetailWindow:createAwakeHeroIcon()
	local star5PartnerID = xyd.tables.partnerTable:getHeroList(self.partner_:getTableID())[1]

	if xyd.tables.partnerTable:getStar(star5PartnerID) == 4 then
		star5PartnerID = xyd.tables.partnerTable:getShenxueTableId(star5PartnerID)
	end

	local materials = {}

	for i = self.partner_:getStar(), self.awakeStarAim - 1 do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeMaterial(self.partner_:getTableID(), awake)

		for i = 1, #cost do
			table.insert(materials, cost[i])
		end
	end

	table.sort(materials, function (a, b)
		local pointA = a
		local pointB = b

		if a == star5PartnerID then
			pointA = 0
		end

		if b == star5PartnerID then
			pointB = 0
		end

		return pointA < pointB
	end)
	self:updateMaterial()
	NGUITools.DestroyChildren(self.feedIcons.transform)

	local flag = {}
	self.awakeHeroIcons = {}

	for _, key in ipairs(materials) do
		if not flag[key] then
			flag[key] = 1
			local group = NGUITools.AddChild(self.feedIcons, self.feedIconGroup)
			local heroIconContainer = group:NodeByName("heroIcon").gameObject
			local icon = HeroIcon.new(heroIconContainer)
			local label = group:ComponentByName("labelAwakeFeed", typeof(UILabel))
			local imgPlus = group:ComponentByName("addIcon", typeof(UISprite))

			self.material_details[key].callback = function ()
				self:onClickHeroIcon(self.material_details[key], icon, label, imgPlus, key)
			end

			icon:setInfo(self.material_details[key])
			icon:setGrey()

			local text = "0/" .. self.material_details[key].needNum
			label.text = text

			table.insert(self.awakeHeroIcons, {
				key = key,
				icon = icon,
				label = label,
				imgPlus = imgPlus
			})
		end
	end

	self.feedIconsGrid:Reposition()
	self:updateAwakeHeroIcon()
end

function PartnerDetailWindow:updateMaterial()
	local materials = {}

	for i = self.partner_:getStar(), self.awakeStarAim - 1 do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeMaterial(self.partner_:getTableID(), awake)

		for i = 1, #cost do
			table.insert(materials, cost[i])
		end
	end

	if not materials or not next(materials) then
		return
	end

	local m_detail = {}

	for _, heroID in ipairs(materials) do
		if not m_detail[heroID] then
			m_detail[heroID] = {}
		end

		if heroID % 1000 == 999 then
			local star = xyd.tables.partnerIDRuleTable:getStar(heroID)
			local group = xyd.tables.partnerIDRuleTable:getGroup(heroID)
			local heroIcon = xyd.tables.partnerIDRuleTable:getIcon(heroID)
			local num = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID] = {
				star = star,
				group = group,
				needNum = num,
				heroIcon = heroIcon,
				partners = {}
			}
		else
			m_detail[heroID].needNum = (m_detail[heroID].needNum or 0) + 1
			m_detail[heroID].tableID = m_detail[heroID].tableID or heroID
			m_detail[heroID].partners = {}
		end

		m_detail[heroID].noClickSelected = true
		m_detail[heroID].notPlaySaoguang = true
	end

	self.material_details = m_detail
end

function PartnerDetailWindow:getMaterial()
	return self.material_details
end

function PartnerDetailWindow:updateAwakeHeroIcon()
	self.awakeSelectedPartners = {}
	local partners = xyd.models.slot:getPartners()

	for key in pairs(self.material_details) do
		local ps = self.material_details[key].partners
		self.material_details[key].benchPartners = {}

		if ps then
			for _, partnerID in pairs(ps) do
				self.awakeSelectedPartners[partnerID] = 1

				table.insert(self.material_details[key].benchPartners, partners[partnerID])
			end
		end
	end

	for key in pairs(self.material_details) do
		if self.material_details[key].tableID then
			self:awakeAddPartnersById(self.material_details[key].tableID, self.material_details[key].benchPartners)
		else
			self:awakeAddPartnersByParams(self.material_details[key], self.material_details[key].benchPartners)
		end
	end

	for _, awakeHeroIcon in pairs(self.awakeHeroIcons) do
		local key = awakeHeroIcon.key
		local md = self.material_details[key]

		if md then
			local icon = awakeHeroIcon.icon
			local label = awakeHeroIcon.label
			local imgPlus = awakeHeroIcon.imgPlus

			if md.needNum <= #md.benchPartners then
				icon:showRedMark(true)
			else
				icon:showRedMark(false)
			end

			if md.needNum <= #md.partners then
				icon:setOrigin()

				label.color = Color.New2(2986279167.0)

				imgPlus:SetActive(false)
			else
				imgPlus:SetActive(true)

				label.color = Color.New2(4294967295.0)

				icon:setGrey()
			end

			label.text = #md.partners .. "/" .. md.needNum
			icon.selected = false
		end
	end
end

function PartnerDetailWindow:awakeAddPartnersById(tableID, array)
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if partners[key]:getTableID() == tableID and self.awakeSelectedPartners[partners[key]:getPartnerID()] ~= 1 and partners[key]:getPartnerID() ~= self.partner_:getPartnerID() then
			table.insert(array, partners[key])
		end
	end

	if #array > 0 and array[1]:getStar() == 5 then
		table.sort(array, function (a, b)
			local tableID_a = a:getTableID()
			local tableID_b = b:getTableID()
			local offset_a = tableID_a - 100000
			local offset_b = tableID_b - 100000

			if offset_a > 0 and offset_b > 0 or offset_a < 0 and offset_b < 0 then
				local weightA = a:getLevel() * 1000000 + a:getTableID()
				local weightB = b:getLevel() * 1000000 + b:getTableID()

				return weightA < weightB
			else
				return tableID_b < tableID_a
			end
		end)
	else
		table.sort(array, function (a, b)
			local weightA = a:getLevel() * 1000000 + a:getTableID()
			local weightB = b:getLevel() * 1000000 + b:getTableID()

			return weightA < weightB
		end)
	end

	return array
end

function PartnerDetailWindow:awakeAddPartnersByParams(params, array)
	local partners = xyd.models.slot:getPartners()

	for key in pairs(partners) do
		if (partners[key]:getGroup() == params.group or params.group == 0) and partners[key]:getStar() == params.star and self.awakeSelectedPartners[partners[key]:getPartnerID()] ~= 1 and partners[key]:getPartnerID() ~= self.partner_:getPartnerID() and partners[key]:getGroup() ~= xyd.PartnerGroup.TIANYI then
			table.insert(array, partners[key])
		end
	end

	if #array > 0 and array[1]:getStar() == 5 then
		table.sort(array, function (a, b)
			local tableID_a = a:getTableID()
			local tableID_b = b:getTableID()
			local offset_a = tableID_a - 100000
			local offset_b = tableID_b - 100000

			if offset_a > 0 and offset_b > 0 or offset_a < 0 and offset_b < 0 then
				local weightA = a:getLevel() * 1000000 + a:getTableID()
				local weightB = b:getLevel() * 1000000 + b:getTableID()

				return weightA < weightB
			else
				return tableID_b < tableID_a
			end
		end)
	else
		table.sort(array, function (a, b)
			local weightA = a:getLevel() * 1000000 + a:getTableID()
			local weightB = b:getLevel() * 1000000 + b:getTableID()

			return weightA < weightB
		end)
	end

	return array
end

function PartnerDetailWindow:onClickHeroIcon(params, this_icon, this_label, this_imgPlus, mTableID)
	params.mTableID = mTableID
	params.this_icon = this_icon
	params.this_label = this_label
	params.this_imgPlus = this_imgPlus
	params.showBaoxiang = true
	params.notShowGetWayBtn = true

	xyd.WindowManager:get():openWindow("choose_partner_window", params)
end

function PartnerDetailWindow:onMutiAwake()
	self.awakeTimes = self.awakeTimes - 1

	if self.awakeTimes <= 0 then
		self.isMutiAwake = false
	end

	local materials = self.awakeMaterials[#self.awakeMaterials - self.awakeTimes]
	local partners = {}

	for i = 1, #materials do
		local partnerID = materials[i]
		local partner = xyd.models.slot:getPartner(partnerID)

		table.insert(partners, partner)
	end

	xyd.checkHasMarriedAndNotice(partners, function ()
		self.partner_:awakePartner(materials)
	end)
end

function PartnerDetailWindow:onclickAwake()
	local can_awake = true
	local materials = {}
	local costNum = 0

	for i = self.partner_:getStar(), self.awakeStarAim - 1 do
		local star = i
		local awake = star - 6
		local cost = xyd.tables.partnerTable:getAwakeItemCost(self.partner_:getTableID(), awake)
		cost = xyd.checkCondition(cost and #cost > 0, cost, {
			xyd.ItemID.GRADE_STONE,
			0
		})
		costNum = costNum + cost[2]
	end

	local resNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.GRADE_STONE)

	if resNum < costNum then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.GRADE_STONE)))

		return
	end

	for _, heroIcon in ipairs(self.awakeHeroIcons) do
		local icon = heroIcon.icon
		local info = icon:getPartnerInfo()
		local partner_num = info.partners and #info.partners or 0

		if partner_num < info.needNum then
			can_awake = false

			break
		else
			for _, v in ipairs(info.partners) do
				table.insert(materials, v)
			end
		end
	end

	if can_awake then
		self.awakeMaterials = {}

		for i = self.partner_:getStar(), self.awakeStarAim - 1 do
			local materials = {}
			local star = i
			local awake = star - 6
			local cost = xyd.tables.partnerTable:getAwakeMaterial(self.partner_:getTableID(), awake)

			for i = 1, #cost do
				local key = cost[i]
				local ps = self.material_details[key].partners

				table.insert(materials, ps[#ps])

				ps[#ps] = nil
			end

			table.insert(self.awakeMaterials, materials)
		end

		self.awakeTimes = self.awakeStarAim - self.partner_:getStar()
		self.isMutiAwake = true
		self.partnerStarBeforeAwake = self.partner_:getStar()
		self.formerPartner = Partner.new()

		self.formerPartner:populate(self.partner_:getInfo())
		self:onMutiAwake()
	else
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_PARTNERS"))
	end
end

function PartnerDetailWindow:fixCurrentIndex(partner_id)
	self.currentSortedPartners_ = self.model_:getSortedPartners()[self.sort_key]

	for idx, _ in pairs(self.currentSortedPartners_) do
		if self.currentSortedPartners_[idx] == partner_id then
			self.currentIdx_ = tonumber(idx)
		end
	end
end

function PartnerDetailWindow:onAwakePartner(event)
	self:fixCurrentIndex(self.partner_:getPartnerID())

	if self.partner_:getStar() <= 10 then
		self:onAwake(event)
	else
		self:onPotentiality(event)
	end

	local dialog = xyd.tables.partnerTable:getPowerUpDialogInfo(self.partner_:getTableID(), self.partner_:getSkinID())

	if not dialog or not dialog.time or dialog.sound == 0 then
		dialog = xyd.tables.partnerTable:getAwakeDialogInfo(self.partner_:getTableID(), self.partner_:getSkinID())
	end

	self:playSound(dialog)
end

function PartnerDetailWindow:onAwake(event)
	if not self.formerPartner then
		return
	end

	local win_params = {
		partner = self.partner_,
		formerPartner = self.formerPartner,
		attrParams = {}
	}
	local items = {}

	for i = 1, #self.awakeAwardItems do
		local awardItems = self.awakeAwardItems[i]

		for _, item in ipairs(awardItems) do
			table.insert(items, {
				item_id = item.item_id,
				item_num = tonumber(item.item_num)
			})
		end
	end

	win_params.items = items
	self.awakeAwardItems = nil
	local maxLev = self.formerPartner:getMaxLev(self.formerPartner:getGrade(), self.formerPartner:getAwake())
	local newMaxLev = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake())

	table.insert(win_params.attrParams, {
		"TOP_LEV_UP",
		maxLev,
		newMaxLev
	})

	local attr_enums = {
		"hp",
		"atk"
	}
	local attrs = self.formerPartner:getBattleAttrs()
	local new_attrs = self.partner_:getBattleAttrs()

	for i = 1, #attr_enums do
		local v = attr_enums[i]
		local params = {
			v,
			attrs[v],
			new_attrs[v]
		}

		table.insert(win_params.attrParams, params)
	end

	local skills_old, skills_new = nil

	if self.formerPartner:getStar() == 6 then
		skills_old = self.formerPartner:getSkillIDs()
	else
		skills_old = self.formerPartner:getAwakeSkill(self.formerPartner:getAwake())
	end

	if self.partner_:getStar() == 10 then
		local star9_skills = self.formerPartner:getAwakeSkill(3)
		local star10_skills = self.partner_:getSkillIDs()
		skills_new = star9_skills
		skills_new[1] = star10_skills[1]
	else
		skills_new = self.partner_:getAwakeSkill(self.partner_:getAwake())
	end

	local skillOldList = {}
	local skillNewList = {}

	for i = 2, #skills_old do
		if tonumber(skills_old[i]) ~= tonumber(skills_new[i]) then
			table.insert(skillOldList, skills_old[i])
			table.insert(skillNewList, skills_new[i])
		end
	end

	if skills_old and skills_old[1] and tonumber(skills_old[1]) ~= tonumber(skills_new[1]) then
		table.insert(skillOldList, skills_old[1])
		table.insert(skillNewList, skills_new[1])
	end

	win_params.skillOldList = skillOldList
	win_params.skillNewList = skillNewList

	if self.partner_:getStar() == 10 and xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 and self.partner_:getGroup() ~= xyd.PartnerGroup.TIANYI then
		self.needExSkillGuide = true
	end

	local newStar = self.partner_:getStar()

	if newStar >= 6 and newStar <= 10 then
		local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
		local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

		if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
			local win = xyd.getWindow("main_window")

			win:setHasEvaluateWindow(true, xyd.EvaluateFromType.AWAKE)
		end
	end

	xyd.WindowManager:get():openWindow("awake_ok_window", win_params)
end

function PartnerDetailWindow:onPotentiality(event)
	local win_params = {
		partner = self.partner_,
		attrParams = {}
	}
	local items = {}

	for _, item in ipairs(event.data.items) do
		table.insert(items, {
			item_id = item.item_id,
			item_num = tonumber(item.item_num)
		})
	end

	win_params.items = items
	local maxLev = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake() - 1)
	local newMaxLev = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake())

	table.insert(win_params.attrParams, {
		"TOP_LEV_UP",
		maxLev,
		newMaxLev
	})

	local attr_enums = {
		"hp",
		"atk"
	}
	local attrs = self.partner_:getBattleAttrs({
		awake = self.partner_:getAwake() - 1
	})
	local new_attrs = self.partner_:getBattleAttrs()

	for i = 1, #attr_enums do
		local v = attr_enums[i]
		local params = {
			v,
			attrs[v],
			new_attrs[v]
		}

		table.insert(win_params.attrParams, params)
	end

	local awake = self.partner_:getAwake()
	local skills_old = awake <= 1 and self.partner_:getSkillIDs() or self.partner_:getAwakeSkill(awake - 1)
	local skills_new = self.partner_:getAwakeSkill(awake)

	for i = 1, #skills_old do
		if tonumber(skills_old[i]) ~= tonumber(skills_new[i]) then
			win_params.skillOld = skills_old[i]
			win_params.skillNew = skills_new[i]

			break
		end
	end

	xyd.WindowManager:get():openWindow("potentiality_success_window", win_params)
end

function PartnerDetailWindow:updateTenStarExchange()
	if not self.exchangeItem then
		self.exchangeItem = import("app.components.PotentialityComponent").new(self.exchangeComponent)
	end

	self.exchangeComponent:SetActive(true)
	self.exchangeItem:setInfo(self.partner_)
	self.exchangeItem:setLongTouch(self.isLongTouch)

	self.exchangeItem.isShrineHurdle_ = self.isShrineHurdle_
end

function PartnerDetailWindow:updateStarOriginGroup()
	self.labelStarOriginDetail.text = __("STAR_ORIGIN_TEXT02")
	local group = self.partner_:getGroup()
	local partnerTableID = self.partner_:getTableID()
	local listTableID = xyd.tables.partnerTable:getStarOrigin(partnerTableID)
	local starIDs = xyd.tables.starOriginListTable:getNode(listTableID)
	local xy = xyd.tables.starOriginListTable:getXY(listTableID)
	local nodeType = xyd.tables.starOriginListTable:getNodeType(listTableID)

	if group == 7 then
		xyd.setUISpriteAsync(self.imgStarOriginGroup, nil, xyd.tables.partnerGroup7Table:getStarOriginImg1(partnerTableID), nil, , true)
	else
		xyd.setUISpriteAsync(self.imgStarOriginGroup, nil, xyd.tables.groupTable:getStarOriginImg1(group), nil, , true)
	end

	self.starOriginGroup:X(xy[1])
	self.starOriginGroup:Y(xy[2])

	for i = 1, #starIDs do
		local nodeTableID = starIDs[i]
		local state = 0
		local lev = self:getStarOriginNodeLev(nodeTableID)
		local nodeGroup = xyd.tables.starOriginNodeTable:getOriginGroup(nodeTableID)
		local preNodeTableID = xyd.tables.starOriginNodeTable:getPreId(nodeTableID)
		local preNodeNeedLev = xyd.tables.starOriginNodeTable:getPreLv(nodeTableID)

		if preNodeTableID and preNodeTableID > 0 then
			local preNodeLev = self:getStarOriginNodeLev(preNodeTableID)

			if preNodeNeedLev <= preNodeLev then
				if lev > 0 then
					local beginID = xyd.tables.starOriginListTable:getStarIDs(listTableID)[i]
					local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, lev)
					local nextID = xyd.tables.starOriginTable:getNextId(starOriginTableID)

					if not nextID or nextID < 1 then
						state = 3
					else
						state = 2
					end
				else
					state = 2
				end
			else
				state = 1
			end
		elseif lev > 0 then
			local beginID = xyd.tables.starOriginListTable:getStarIDs(listTableID)[i]
			local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, lev)
			local nextID = xyd.tables.starOriginTable:getNextId(starOriginTableID)

			if not nextID or nextID < 1 then
				state = 3
			else
				state = 2
			end
		else
			state = 2
		end

		if not self.starOriginNodeItems then
			self.starOriginNodeItems = {}
		end

		if not self.starOriginNodeItems[i] then
			local tmp = NGUITools.AddChild(self.starOriginGroup.gameObject, self.starOriginItem)
			local item = StarOriginNodeItem.new(tmp, self)
			self.starOriginNodeItems[i] = item
		end

		self.starOriginNodeItems[i]:setInfo({
			nodeTableID = nodeTableID,
			lev = lev,
			state = state
		})
	end

	if nodeType and nodeType[1] and nodeType[2] then
		local allUnlock = true

		for i = 1, #starIDs do
			if self.starOriginNodeItems[i].state <= 1 then
				allUnlock = false
			end
		end

		if allUnlock then
			local state = 2

			if self.starOriginNodeItems[nodeType[2]].lev > 0 then
				state = 3
			end

			self.starOriginNodeItems[nodeType[1]]:setLineByPreNodeID(starIDs[nodeType[2]], state)
		end
	end
end

function PartnerDetailWindow:getStarOriginNodeLev(nodeTableID)
	local partnerTableID = self.partner_:getTableID()
	local listTableID = xyd.tables.partnerTable:getStarOrigin(partnerTableID)
	local starIDs = xyd.tables.starOriginListTable:getNode(listTableID)

	for i = 1, #starIDs do
		if starIDs[i] == nodeTableID then
			return self.partner_:getStarOrigin()[i] or 0
		end
	end

	return 0
end

function PartnerDetailWindow:checkStarOriginUpdate()
	if self.name_ ~= "partner_detail_window" then
		return
	end

	if self.navChosen ~= 5 then
		return
	end

	self:updateStarOriginGroup()
end

function PartnerDetailWindow:checkStarOriginGuide()
	local wnd1 = xyd.getWindow("alert_award_window")
	local wnd2 = xyd.getWindow("potentiality_success_window")
	local wnd3 = xyd.getWindow("alert_item_window")

	if wnd1 or wnd2 or wnd3 then
		return
	end

	if self.isShrineHurdle_ then
		return
	end

	if self.needExSkillGuide then
		return
	end

	if not self:isWndComplete() then
		return
	end

	if self.isPlayingSwitchAnimation then
		return
	end

	local slotWd = xyd.WindowManager.get():getWindow("slot_window")

	if not slotWd then
		return
	end

	local isHasGoStarOriginGuide = xyd.db.misc:getValue("is_has_go_star_origin_guide")

	if isHasGoStarOriginGuide and tonumber(isHasGoStarOriginGuide) == 1 then
		return
	elseif self.showStarOriginTab == true then
		self.needStarOriginGuide = false

		xyd.WindowManager:get():openWindow("common_trigger_guide_window", {
			guide_type = xyd.CommonTriggerGuideType.STAR_ORIGIN
		})
		xyd.db.misc:setValue({
			value = 1,
			key = "is_has_go_star_origin_guide"
		})
	end
end

function PartnerDetailWindow:onClickStarOriginBtn()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	xyd.openWindow("star_origin_detail_window", {
		partnerID = self.partner_:getPartnerID()
	})
end

function PartnerDetailWindow:onclickArrow(delta)
	if self:checkLongTouch() then
		return
	end

	self:partnerLevUp(true)

	self.currentIdx_ = self.currentIdx_ + delta
	self.needIdx_ = true

	if self.isPlaySound then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)
		self.bubble:SetActive(false)

		self.isPlaySound = false
	else
		self.isPlaySound = self.isPlaySound
	end

	self.needExSkillGuide = false
	self.needStarOriginGuide = false
	self.isPlayingSwitchAnimation = true

	self:initFullOrderGradeUp()
	self:initFullOrderLevelUp()
	self:updateData()
	self:updateBg()
	self:updatePartnerSkin()
	self:playSwitchAnimation()
	self:setPledgeLayout()
	self:updateNameTag()
	self:checkExSkillBtn()
	self:checkPartnerBackBtn()
	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
	self:updateRedPointShow()
	self:initMarkedBtn()
	self:checkContentState()
	self:checkStarOriginUpdate()
	self:checkBtnCommentShow()
end

function PartnerDetailWindow:checkContentState()
	if self.navChosen == 4 then
		if self.status_ ~= "SHENXUE" then
			self["content_" .. tostring(5)]:SetActive(false)

			local maxGrade = self.partner_:getMaxGrade()

			if self.partner_:getGrade() < maxGrade then
				return
			end

			self["content_" .. tostring(4)]:SetActive(true)
		else
			self["content_" .. tostring(4)]:SetActive(false)
			self["content_" .. tostring(5)]:SetActive(true)
			self.shenxueStarsAfterLayout:Reposition()
			self.shenxueStarsBeforeLayout:Reposition()
			self.shenxueFeedGroup:Reposition()
		end
	end
end

function PartnerDetailWindow:onclickPartnerImg(cancel)
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		return
	end

	if cancel then
		return
	end

	if self.bubble and self.bubble.activeSelf then
		return
	end

	if self.isPlaySound then
		return
	end

	self.bubble:SetActive(not self.bubble.activeSelf)

	local clickSoundNum = xyd.tables.partnerTable:getClickSoundNum(self.partner_:getTableID(), self.partner_:getSkinID())
	local rand = math.floor(math.random() * clickSoundNum + 0.5) + 1
	local index = clickSoundNum < rand and rand - clickSoundNum or rand
	local dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.partner_:getTableID(), index, self.partner_:getSkinID(), self.partner_:getLovePoint())

	if self.currentDialog and dialogInfo.sound == self.currentDialog.sound then
		index = clickSoundNum < index + 1 and index - (clickSoundNum - 1) or index + 1
		dialogInfo = xyd.tables.partnerTable:getClickDialogInfo(self.partner_:getTableID(), index, self.partner_:getSkinID())
	end

	if not dialogInfo or not next(dialogInfo) then
		return
	end

	self.isPlaySound = true
	self.tips.text = dialogInfo.dialog

	xyd.SoundManager.get():playSound(dialogInfo.sound, function ()
	end)

	dialogInfo.timeOutId = self:setTimeout(function ()
		self.isPlaySound = false

		self.bubble:SetActive(false)
	end, self, dialogInfo.time * 1000)
	self.currentDialog = dialogInfo

	self.partnerImg:effectClickFunction()
end

function PartnerDetailWindow:onclickShare()
	local levNeed = xyd.tables.miscTable:getVal("talk_level")
	local cd = xyd.tables.miscTable:getVal("talk_cd")
	local curCd = xyd.getServerTime() - Chat:get():getLastTalk(xyd.MsgType.SHARE_PARTNER)
	local tips = nil

	if xyd.models.backpack:getLev() < levNeed then
		tips = __("CHAT_LIMIT_LEV", levNeed)
	elseif cd - curCd > 0 then
		tips = __("SHARE_CHAT_LIMIT_TIME", cd - curCd)
	else
		tips = __("SHARE_PARTNER_OK")

		Chat:get():sendServerMsg(JSON:stringify(self.partner_:getInfo()), xyd.MsgType.SHARE_PARTNER)
	end

	xyd.alert(xyd.AlertType.TIPS, tips)
end

function PartnerDetailWindow:onclickZoom(event, isGuide)
	local showID = nil

	if self.navChosen == 3 then
		local currentSkinID = self.skinIDs[self.currentSkin]
		showID = self.partner_:getShowID()

		if not showID or showID == 0 then
			showID = self.partner_:getTableID()
		end

		if currentSkinID ~= 0 then
			showID = currentSkinID
		end
	else
		showID = self.partner_:getShowID()

		if not showID or showID == 0 then
			showID = self.partner_:getTableID()
		end
	end

	if isGuide and self.partner_:getGroup() == xyd.PartnerGroup.TIANYI then
		local showIds = xyd.tables.partnerTable:getShowIds(self.partner_:getTableID())

		if self.currentSkin <= #showIds then
			showID = tonumber(showIds[self.currentSkin])
		end
	end

	local res = "college_scene" .. self.partner_:getGroup()

	xyd.WindowManager.get():openWindow("partner_detail_zoom_window", {
		item_id = showID,
		bg_source = res,
		group = self.partner_:getGroup()
	})
end

function PartnerDetailWindow:onTouchBegin()
	self.slideXY = {
		x = 0,
		y = 0
	}
	self.isPartnerImgClick = true
end

function PartnerDetailWindow:onTouchMove(delta)
	if self.unableMove then
		return
	end

	self.slideXY.x = self.slideXY.x + delta.x
	self.slideXY.y = self.slideXY.y + delta.y

	self.groupInfo:Y(self.SLIDEHEIGHT - math.abs(self.slideXY.x))
end

function PartnerDetailWindow:onTouchEnd()
	self:levUpLongTouch(false)

	if self.unableMove then
		return
	end

	if self.slideXY.x > 50 and self.arrow_left.activeSelf then
		self:onclickArrow(-1)
	elseif self.slideXY.x < -50 and self.arrow_right.activeSelf then
		self:onclickArrow(1)
	else
		local action = self:getSequence()

		action:Append(self.groupInfo.transform:DOLocalMoveY(self.SLIDEHEIGHT, 0.2))
	end
end

function PartnerDetailWindow:playSwitchAnimation()
	local sequence = self:getSequence()
	local w = self.groupInfo:GetComponent(typeof(UIWidget))

	local function getter()
		return w.color
	end

	local function setter(color)
		w.color = color
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.LONG_ALERT)

	local originY = 243

	sequence:Insert(0, self.groupInfo.transform:DOLocalMoveY(-600, 0.2))
	sequence:Insert(0.2, self.groupInfo.transform:DOLocalMoveY(originY, 0.2))
	sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.01, 0.1))
	sequence:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.1))
	sequence:AppendCallback(function ()
		self.isPlayingSwitchAnimation = false

		self:checkExSkillGuide()
		self:checkStarOriginGuide()
	end)
end

function PartnerDetailWindow:playOpenAnimation(callback)
	self:initVars()
	self:updateBg()

	local nCenter = self.playerNameGroup.transform.localPosition.x
	local lockX = self.midBtns.transform.localPosition.x

	self.groupInfo:X(720)
	self.partnerImg.parentGo:X(-720)
	self.playerNameGroup:X(nCenter - 720)
	self.midBtns:X(lockX + 720)
	self:waitForTime(0.1, function ()
		local sequence = self:getSequence()

		sequence:Insert(0, self.groupInfo.transform:DOLocalMoveX(-20, 0.2))
		sequence:Insert(0.2, self.groupInfo.transform:DOLocalMoveX(0, 0.3))
		sequence:Insert(0, self.partnerImg.parentGo.transform:DOLocalMoveX(20, 0.2))
		sequence:Insert(0.2, self.partnerImg.parentGo.transform:DOLocalMoveX(0, 0.3))
		sequence:Insert(0, self.playerNameGroup.transform:DOLocalMoveX(nCenter + 20, 0.2))
		sequence:Insert(0.2, self.playerNameGroup.transform:DOLocalMoveX(nCenter, 0.3))
		sequence:Insert(0, self.midBtns.transform:DOLocalMoveX(lockX - 20, 0.2))
		sequence:Insert(0.2, self.midBtns.transform:DOLocalMoveX(lockX, 0.3))

		local function getter()
			return self.groupBg.color
		end

		local function setter(color)
			self.groupBg.color = color
		end

		sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.1, 0))
		sequence:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.2))

		local Center = self.loveIcon.transform.localPosition.x

		sequence:Insert(0, self.loveIcon.transform:DOLocalMoveX(Center - 720, 0))
		sequence:Insert(0, self.loveIcon.transform:DOLocalMoveX(Center + 20, 0.2))
		sequence:Insert(0.2, self.loveIcon.transform:DOLocalMoveX(Center, 0.3))
		sequence:AppendCallback(function ()
			sequence:Kill(false)

			sequence = nil

			if xyd.GuideController.get():isGuideComplete() then
				self:onclickPartnerImg()
			end

			self:setWndComplete()
			self:checkExSkillGuide()
			self:checkStarOriginGuide()
		end)
	end, nil)
	callback()
end

function PartnerDetailWindow:willClose()
	BaseWindow.willClose(self)

	if self.fakeLev and self.fakeLev > 0 then
		self:partnerLevUp(true)
	end

	local wnd = xyd.WindowManager.get():getWindow("res_loading_window")

	if wnd then
		xyd.WindowManager.get():closeWindow("res_loading_window")
	end

	self.attrTipsItems = {}

	if self.unableMove and self.battleData then
		local wndName = "battle_formation_window"

		if self.if3v3 then
			wndName = "arena_3v3_battle_formation_window"
		end

		if self.battleData.windowName == "friend_boss_battle_formation_window" then
			wndName = "friend_boss_battle_formation_window"
		end

		if self.isFairyTale_ then
			wndName = "activity_fairy_tale_formation_window"
		end

		if self.isTrial_ then
			wndName = "battle_formation_trial_window"
		end

		if self.isSpfarm_ then
			wndName = "battle_formation_spfarm_window"
		end

		if self.ifGalaxy then
			wndName = "galaxy_trip_formation_window"
		end

		if self.battleData.battleType ~= xyd.BattleType.EXPLORE_ADVENTURE and self.battleData.battleType ~= xyd.BattleType.ARENA_ALL_SERVER and self.battleData.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF and self.battleData.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF_2 then
			xyd.WindowManager.get():openWindow(wndName, self.battleData)
		end
	end

	if self.isPlaySound and self.currentDialog then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)

		self.isPlaySound = false
	end
end

function PartnerDetailWindow:didClose(params)
	BaseWindow.didClose(self, params)
end

function PartnerDetailWindow:SetIfNeedSkill(isNeed)
	self.isNeedSkill = isNeed
end

function PartnerDetailWindow:onBuyTouch()
	if self:checkLongTouch() then
		return
	end

	local currentSkinID = self.skinIDs[self.currentSkin]
	local datas = {
		skin_id = currentSkinID
	}

	xyd.WindowManager.get():openWindow("skin_detail_buy_window", {
		id = currentSkinID,
		datas = datas
	})
end

function PartnerDetailWindow:updateNavState()
	if self:checkAwake2Top() and self.partner_:getStar() > 9 then
		self.status_ = "POTENTIALITY"
	elseif self.partner_:getStar() < 6 then
		self.status_ = "SHENXUE"
	else
		self.status_ = "AWAKE"
	end
end

function PartnerDetailWindow:checkStarOriginTab()
	if self.name_ ~= "partner_detail_window" then
		return
	end

	self.showStarOriginTab = false

	if self.partner_:getStar() >= 15 and xyd.tables.partnerTable:getStarOrigin(self.partner_:getTableID()) > 0 then
		self.showStarOriginTab = true
	end

	local tabWidth = 177
	local tabLabelWidth = 160
	local tabImgName1 = "nav_btn_blue_right"
	local tabImgName2 = "nav_btn_white_right"
	local tabImgName3 = "nav_btn_grey_right"

	if self.showStarOriginTab then
		tabWidth = 141
		tabLabelWidth = 123
		tabImgName1 = "nav_btn_blue_mid"
		tabImgName2 = "nav_btn_white_mid"
		tabImgName3 = "nav_btn_grey_mid"
	end

	for i = 1, 4 do
		self.defaultTabGroup:ComponentByName("tab_" .. i .. "/chosen", typeof(UISprite)).width = tabWidth
		self.defaultTabGroup:ComponentByName("tab_" .. i .. "/unchosen", typeof(UISprite)).width = tabWidth

		if i < 3 then
			self.defaultTabGroup:ComponentByName("tab_" .. i .. "/label", typeof(UILabel)).width = tabLabelWidth
		end

		if i > 2 then
			local none = self.defaultTabGroup:ComponentByName("tab_" .. i .. "/none", typeof(UISprite))
			none.width = tabWidth
		end

		if self.showStarOriginTab then
			self.defaultTabGroup:NodeByName("tab_" .. i).gameObject:X(-282 + (i - 1) * tabWidth)
		else
			self.defaultTabGroup:NodeByName("tab_" .. i).gameObject:X(-265 + (i - 1) * tabWidth)
		end
	end

	self.defaultTabGroup:NodeByName("tab_5").gameObject:SetActive(self.showStarOriginTab)
	xyd.setUISpriteAsync(self.defaultTabGroup:ComponentByName("tab_4/chosen", typeof(UISprite)), nil, tabImgName1)
	xyd.setUISpriteAsync(self.defaultTabGroup:ComponentByName("tab_4/unchosen", typeof(UISprite)), nil, tabImgName2)
	xyd.setUISpriteAsync(self.defaultTabGroup:ComponentByName("tab_4/none", typeof(UISprite)), nil, tabImgName3)

	if not self.showStarOriginTab then
		self.content_6:SetActive(false)

		self.defaultTabGroup:ComponentByName("tab_4/label", typeof(UILabel)).fontSize = 26

		if xyd.Global.lang == "de_de" then
			self.defaultTabGroup:ComponentByName("tab_4/label", typeof(UILabel)).fontSize = 18
		end
	elseif xyd.Global.lang == "en_en" then
		self.defaultTabGroup:ComponentByName("tab_4/label", typeof(UILabel)).fontSize = 22
	end
end

function PartnerDetailWindow:updateShenxue()
	if self.status_ ~= "SHENXUE" then
		self.content_5:SetActive(false)
		self.nav4_redPoint:SetActive(false)
	else
		self.materialIdList_ = {}
		self.mateOptionalList_ = {}
		self.materialNeedNumList_ = {}
		self.materialKeyList_ = {}

		NGUITools.DestroyChildren(self.shenxueFeedGroup.transform)
		NGUITools.DestroyChildren(self.shenxueStarsBefore.transform)
		NGUITools.DestroyChildren(self.shenxueStarsAfter.transform)

		local partnerTable = xyd.tables.partnerTable
		local shenxueTableId = partnerTable:getShenxueTableId(self.partner_:getTableID())

		if shenxueTableId == 0 then
			return
		end

		self.nav4_redPoint:SetActive(xyd.models.shenxue:getStatusByTableID(shenxueTableId))

		local beforePartnerParams = {
			noClick = false,
			noClickSelected = true,
			scale = 0.9,
			needRedPoint = false,
			uiRoot = self.shenxueHeroBeforeRoot,
			tableID = self.partner_:getTableID(),
			callback = function ()
				xyd.WindowManager.get():openWindow("partner_info", {
					table_id = self.partner_:getTableID(),
					grade = self.partner_:getGrade(),
					lev = self.partner_:getLevel()
				})
			end
		}

		if not self.shenxueHeroBefore then
			self.shenxueHeroBefore = HeroIcon.new(self.shenxueHeroBeforeRoot)
		end

		self.shenxueHeroBefore:setInfo(beforePartnerParams)

		local afterPartnerParams = {
			noClick = false,
			noClickSelected = true,
			scale = 0.9,
			needRedPoint = false,
			uiRoot = self.shenxueHeroAfterRoot,
			tableID = shenxueTableId,
			callback = function ()
				xyd.WindowManager.get():openWindow("partner_info", {
					table_id = shenxueTableId,
					grade = self.partner_:getGrade(),
					lev = self.partner_:getLevel()
				})
			end
		}

		if not self.shenxueHeroAfter then
			self.shenxueHeroAfter = HeroIcon.new(self.shenxueHeroAfterRoot)
		end

		self.shenxueHeroAfter:setInfo(afterPartnerParams)

		local function addStar(parent, starNum, showBg)
			local widgt = parent:GetComponent(typeof(UIWidget))
			local imgStar = NGUITools.AddChild(parent)
			local starSprite = imgStar:AddComponent(typeof(UISprite))
			starSprite.height = 32
			starSprite.width = 33
			starSprite.depth = widgt.depth + 1
			local imgName = nil

			if not showBg then
				if starNum == 5 then
					imgName = "partner_star_yellow"
				elseif starNum == 6 then
					imgName = "partner_star_red_big"
				end
			else
				imgName = "partner_star_bg"
			end

			xyd.setUISpriteAsync(starSprite, nil, imgName, function ()
				starSprite:MakePixelPerfect()
			end)
		end

		local beforeStar = self.partner_:getStar()

		if beforeStar == 4 then
			self.labelShenxueAttrNum.text = "20%"

			for i = 0, 4 do
				if i == 4 then
					addStar(self.shenxueStarsBefore, 5, true)
				else
					addStar(self.shenxueStarsBefore, 5, false)
				end

				addStar(self.shenxueStarsAfter, 5, false)
			end
		elseif beforeStar == 5 then
			self.labelShenxueAttrNum.text = "50%"

			for i = 0, 4 do
				addStar(self.shenxueStarsBefore, 5, false)

				if i < 4 then
					if i == 0 then
						addStar(self.shenxueStarsAfter, 6, false)
					else
						addStar(self.shenxueStarsAfter, 6, true)
					end
				end
			end
		end

		self.shenxueStarsAfterLayout:Reposition()
		self.shenxueStarsBeforeLayout:Reposition()

		self.labelShenxueAttrUp.text = __("ATTR_UP")
		self.labelShenxueMaxLevUp.text = __("TOP_LEV_UP_TO")
		local np = Partner.new()

		np:populate({
			table_id = shenxueTableId
		})

		self.labelShenxueMaxLev.text = __(np:getMaxLev())
		self.btnShenxueLabel.text = __("SHENXUE")
		UIEventListener.Get(self.btnShenxue).onClick = handler(self, self.onClickShenXueBtn)

		self:initShenxueMaterialsData()
		self:initShenxueMaterialsLayout()
		self:autoPutMaterial()
	end
end

function PartnerDetailWindow:initShenxueMaterialsData()
	local partnerTable = xyd.tables.partnerTable
	local shenxueTableId = partnerTable:getShenxueTableId(self.partner_:getTableID())
	local materials = xyd.split(partnerTable:getMaterial(shenxueTableId), "|")
	local lastTableID = 0
	self.totalShenxueMatNum = 0

	for _, mTableID in ipairs(materials) do
		if not self.materialNeedNumList_[tostring(mTableID)] then
			self.materialNeedNumList_[tostring(mTableID)] = 0
		end

		self.materialNeedNumList_[tostring(mTableID)] = self.materialNeedNumList_[tostring(mTableID)] + 1

		if tonumber(mTableID) ~= lastTableID then
			table.insert(self.materialKeyList_, tonumber(mTableID))

			self.totalShenxueMatNum = self.totalShenxueMatNum + 1
			lastTableID = tonumber(mTableID)
		end
	end

	for mTableID, _ in pairs(self.materialNeedNumList_) do
		local needNum = self.materialNeedNumList_[mTableID]
		local redFlag = false
		local partnerList = self:getShenxueMaterial(mTableID)

		if needNum <= #partnerList then
			redFlag = true
		end

		self.mateOptionalList_[tostring(mTableID)] = {
			partnerList = partnerList,
			redFlag = redFlag,
			needNum = needNum,
			mTableID = mTableID
		}
		self.materialIdList_[tostring(mTableID)] = {}
	end
end

function PartnerDetailWindow:refreshShenxueMaterials()
	for mTableID, _ in pairs(self.materialNeedNumList_) do
		local needNum = self.materialNeedNumList_[mTableID]
		local redFlag = false
		local partnerList = self:getShenxueMaterial(mTableID)

		if needNum <= #partnerList then
			redFlag = true
		end

		self.mateOptionalList_[tostring(mTableID)] = {
			partnerList = partnerList,
			redFlag = redFlag,
			needNum = needNum,
			mTableID = mTableID
		}
	end
end

function PartnerDetailWindow:initShenxueMaterialsLayout()
	for id = 1, self.totalShenxueMatNum do
		local optionalList = {}
		local mTableID = 0
		mTableID = self.materialKeyList_[id]
		optionalList = self.mateOptionalList_[tostring(mTableID)]
		local heroGroup = NGUITools.AddChild(self.shenxueFeedGroup.gameObject, self.shenxueFeedItem)

		heroGroup:SetActive(true)

		local goTrans = heroGroup.transform
		self["labelShenxueFeed" .. id] = goTrans:ComponentByName("labelNum", typeof(UILabel))
		local iconContainer = goTrans:NodeByName("iconContainer0").gameObject
		self["shenxueRedPointImg" .. id] = goTrans:NodeByName("redPointImg0").gameObject
		self["shenxuePlusIcon" .. id] = goTrans:NodeByName("plusImg").gameObject
		local touchGroup = goTrans:NodeByName("touchGroup").gameObject
		local pInfo = {}

		if tonumber(mTableID) % 1000 == 999 then
			pInfo = {
				needRedPoint = false,
				needStarBg = true,
				noClick = true,
				uiRoot = iconContainer,
				group = math.floor(tonumber(mTableID) % 10000 / 1000),
				star = math.floor(tonumber(mTableID) / 10000),
				heroIcon = xyd.tables.partnerIDRuleTable:getIcon(tostring(mTableID))
			}
		else
			pInfo = {
				noClick = true,
				needRedPoint = false,
				uiRoot = iconContainer,
				tableID = mTableID
			}
		end

		self["shenxueFeed" .. id] = HeroIcon.new(iconContainer)

		self["shenxueFeed" .. id]:setInfo(pInfo)

		UIEventListener.Get(touchGroup).onClick = function ()
			self:onSelectContainer(id)
		end

		xyd.applyChildrenGrey(self["shenxueFeed" .. id]:getIconRoot())

		self["labelShenxueFeed" .. id].text = "0/" .. optionalList.needNum

		if optionalList.redFlag == true then
			self["shenxueRedPointImg" .. id]:SetActive(true)
		else
			self["shenxueRedPointImg" .. id]:SetActive(false)
		end
	end

	self.shenxueFeedGroup:Reposition()
end

function PartnerDetailWindow:getShenxueMaterial(mTableID)
	local partnerList = {}
	local partner_id = self.partner_:getPartnerID()

	if tonumber(mTableID) % 1000 == 999 then
		local group = math.floor(tonumber(mTableID) % 10000 / 1000)
		local star = math.floor(tonumber(mTableID) / 10000)
		partnerList = self.model_:getListByGroupAndStar(group, star, partner_id)
	else
		partnerList = self.model_:getListByTableID(tonumber(mTableID), partner_id)
	end

	local tempPartnerList = {}

	for i, partnerInfo in pairs(partnerList) do
		if partnerInfo:getGroup() ~= xyd.PartnerGroup.TIANYI then
			table.insert(tempPartnerList, partnerInfo)
		end
	end

	return tempPartnerList
end

function PartnerDetailWindow:onSelectContainer(id)
	local materialList = {}
	local mTableID = self.materialKeyList_[id]
	materialList = self.materialIdList_[tostring(mTableID)]
	local benchPartners = self.mateOptionalList_[tostring(mTableID)].partnerList

	if #benchPartners > 0 and benchPartners[1]:getStar() == 5 then
		table.sort(benchPartners, function (a, b)
			local tableID_a = a:getTableID()
			local tableID_b = b:getTableID()
			local offset_a = tableID_a - 100000
			local offset_b = tableID_b - 100000

			if offset_a > 0 and offset_b > 0 or offset_a < 0 and offset_b < 0 then
				local weightA = a:getLevel() * 1000000 + a:getTableID()
				local weightB = b:getLevel() * 1000000 + b:getTableID()

				return weightA < weightB
			else
				return tableID_b < tableID_a
			end
		end)
	end

	local params = {
		isShenxue = true,
		benchPartners = benchPartners or {},
		partners = materialList or {},
		id = id,
		confirmCallback = function ()
			self:confirmSelectList(id)
		end,
		selectCallback = function (id, pInfo, choose)
			self:setSelectList(id, pInfo, choose)
		end,
		mTableID = mTableID,
		needNum = self.materialNeedNumList_[tostring(mTableID)],
		this_icon = self["shenxueFeed" .. id],
		showBaoxiang = true,
		notShowGetWayBtn = true
	}

	xyd.WindowManager.get():openWindow("choose_partner_window", params)
end

function PartnerDetailWindow:refreshOptionalList(optionalList, clickMaterialList)
	local tempList = optionalList.partnerList

	for _, clickPartnerId in ipairs(clickMaterialList) do
		for id, _ in ipairs(tempList) do
			local partner = tempList[id]
			local partnerId = partner:getPartnerID()

			if partnerId == clickPartnerId then
				table.remove(tempList, id)
			end
		end
	end
end

function PartnerDetailWindow:confirmSelectList(clickId)
	if tolua.isnull(self.window_) then
		return
	end

	local clickMTableID = self.materialKeyList_[clickId]
	local clickMaterialList = self.materialIdList_[tostring(clickMTableID)]

	for id = 1, self.totalShenxueMatNum do
		local mTableID = self.materialKeyList_[id]
		self.isCanForge = true
		local mateNum = 0
		local mateAllNum = nil
		local optionalList = self.mateOptionalList_[tostring(mTableID)]
		local materialList = self.materialIdList_[tostring(mTableID)]

		if id ~= clickId then
			self:refreshOptionalList(optionalList, clickMaterialList)
		end

		if materialList then
			mateNum = #materialList
		end

		mateAllNum = mateNum + #optionalList.partnerList

		if optionalList.needNum <= mateAllNum then
			optionalList.redFlag = true

			self["shenxueRedPointImg" .. id]:SetActive(true)
		else
			optionalList.redFlag = false

			self["shenxueRedPointImg" .. id]:SetActive(false)
		end

		self["labelShenxueFeed" .. id].text = mateNum .. "/" .. optionalList.needNum
		local obj = self["shenxueFeed" .. id]

		if optionalList.needNum <= mateNum then
			self["shenxuePlusIcon" .. id]:SetActive(false)

			self["labelShenxueFeed" .. id].color = Color.New2(2986279167.0)

			xyd.applyChildrenOrigin(obj:getIconRoot())
		else
			self["shenxuePlusIcon" .. id]:SetActive(true)

			self["labelShenxueFeed" .. id].color = Color.New2(4294967295.0)

			xyd.applyChildrenGrey(obj:getIconRoot())

			self.isCanForge = false
		end
	end
end

function PartnerDetailWindow:setSelectList(id, pInfo, choose)
	local partnerID = pInfo.partnerID
end

function PartnerDetailWindow:autoPutMaterial()
	for i = 1, self.totalShenxueMatNum - 1 do
		local mTableID = self.materialKeyList_[i]
		local optionalList = self.mateOptionalList_[tostring(mTableID)]
		local pushList = {}
		local partnerList = optionalList.partnerList

		for j = 1, #partnerList do
			if #pushList == optionalList.needNum then
				break
			end

			if not partnerList[j]:isLockFlag() and tonumber(partnerList[j].lev) == 1 and tonumber(partnerList[j].love_point) <= 0 then
				table.insert(pushList, partnerList[j]:getPartnerID())
			end
		end

		self.materialIdList_[tostring(mTableID)] = pushList

		self:confirmSelectList(i)
	end
end

function PartnerDetailWindow:onClickShenXueBtn()
	local partner_id = self.partner_:getPartnerID()
	local hostPartner = self.model_:getPartner(partner_id)
	local lockType = hostPartner:getLockType()

	local function doShenxue()
		local isCanForge = true
		local partnerList = {}

		table.insert(partnerList, partner_id)

		self.isMarkedBefore_ = xyd.db.misc:getValue("marked_partner_" .. partner_id)

		for _, mTableID in pairs(self.materialKeyList_) do
			local needNum = self.materialNeedNumList_[tostring(mTableID)]

			if not self.materialIdList_[tostring(mTableID)] or needNum > #self.materialIdList_[tostring(mTableID)] then
				isCanForge = false

				break
			end

			for _, partnerId in ipairs(self.materialIdList_[tostring(mTableID)]) do
				table.insert(partnerList, tonumber(partnerId))
			end
		end

		if not isCanForge then
			return
		end

		local partnerTable = xyd.tables.partnerTable
		local shenxueTableId = partnerTable:getShenxueTableId(self.partner_:getTableID())
		local partners = {}

		for _, id in ipairs(partnerList) do
			local partnerID = self.model_:getPartner(id)

			if partnerID and id ~= partner_id then
				table.insert(partners, partnerID)
			end
		end

		xyd.checkHasMarriedAndNotice(partners, function ()
			local msg = messages_pb.compose_partner_req()
			msg.table_id = tonumber(shenxueTableId)

			for i = 1, #partnerList do
				table.insert(msg.material_ids, partnerList[i])
			end

			xyd.Backend:get():request(xyd.mid.COMPOSE_PARTNER, msg)
		end)
	end

	if lockType ~= 0 then
		if xyd.checkLast(hostPartner) then
			xyd.showToast(__("UNLOCK_FAILED"))
		elseif xyd.checkDateLock(hostPartner) then
			xyd.showToast(__("DATE_LOCK_FAIL"))
		elseif xyd.checkQuickFormation(hostPartner) then
			xyd.showToast(__("QUICK_FORMATION_TEXT21"))
		elseif xyd.checkGalaxyFormation(hostPartner) then
			xyd.showToast(__("GALAXY_TRIP_TIPS_20"))
		else
			local str = __("IF_UNLOCK_HERO_2")

			if lockType == 1 then
				str = __("IF_UNLOCK_HERO_4")
			end

			xyd.alertYesNo(str, function (yes_no)
				if yes_no then
					local succeed = xyd.partnerUnlock(hostPartner)

					if succeed then
						if lockType == 1 then
							self.lockBefore_ = true
						end

						doShenxue()
					else
						xyd.showToast(__("UNLOCK_FAILED"))

						return
					end
				end
			end)
		end
	else
		doShenxue()
	end
end

function PartnerDetailWindow:onShenxue(event)
	local tableID = self.partner_:getTableID()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)

	if tableID == tonumber(xyd.split(xyd.tables.miscTable:getVal("graduate_gift_partner"), "|")[1]) and activityData and xyd.getServerTime() < activityData:getEndTime() then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG)
	end

	self:setAttrChange()
	self:fixCurrentIndex(self.partner_:getPartnerID())
	self:onComposePartner(event)
	self:updateData()

	if self.lockBefore_ then
		self.partner_:lock(true)

		self.lockBefore_ = false
	end

	if self.isMarkedBefore_ then
		self:onMarked()

		self.isMarkedBefore_ = false
	end

	self:checkPartnerBackBtn()
end

function PartnerDetailWindow:onComposePartner(event)
	local params = event.data
	local partnerInfo = params.partner_info
	local newPartner = Partner.new()

	newPartner:populate(partnerInfo)

	local items = {}

	for _, item in ipairs(params.items) do
		table.insert(items, {
			item_id = item.item_id,
			item_num = tonumber(item.item_num)
		})
	end

	local win_params = {
		formerPartner = self.partner_,
		partner = newPartner,
		attrParams = {},
		items = items,
		isShenxue = 1
	}
	local maxLev = self.partner_:getMaxLev(self.partner_:getGrade(), self.partner_:getAwake())
	local newMaxLev = newPartner:getMaxLev(newPartner:getGrade(), newPartner:getAwake())

	table.insert(win_params.attrParams, {
		"TOP_LEV_UP",
		maxLev,
		newMaxLev
	})

	local attr_enums = {
		"hp",
		"atk",
		"spd",
		"arm"
	}
	local attrs = self.partner_:getBattleAttrs({
		awake = self.partner_:getAwake()
	})
	local new_attrs = newPartner:getBattleAttrs({
		awake = newPartner:getAwake()
	})

	for _, v in ipairs(attr_enums) do
		local params = {
			v,
			attrs[v],
			new_attrs[v]
		}

		table.insert(win_params.attrParams, params)
	end

	self.partnerId = partnerInfo.partner_id

	self:fixCurrentIndex(self.partnerId)
	xyd.WindowManager.get():openWindow("awake_ok_window", win_params)

	local newStar = newPartner:getStar()

	if newStar >= 6 and newStar <= 10 then
		local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
		local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

		if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
			local win = xyd.getWindow("main_window")

			win:setHasEvaluateWindow(true, xyd.EvaluateFromType.AWAKE)
		end
	end
end

function PartnerDetailWindow:updateRedPointShow()
	local res1 = xyd.checkPartnerRedMark(self.partner_:getPartnerID(), xyd.RedMarkType.PROMOTABLE_PARTNER)
	local res2 = xyd.checkPartnerRedMark(self.partner_:getPartnerID(), xyd.RedMarkType.AVAILABLE_EQUIPMENT)
	local lev = self.partner_:getLevel()
	local grade = self.partner_:getGrade()
	local max_lev = self.partner_:getMaxLev(grade, self.partner_:getAwake())

	if lev < max_lev then
		local cost = xyd.tables.expPartnerTable:getCost(lev + 1)

		if cost[xyd.ItemID.MANA] > xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA) - self.fakeUseRes[xyd.ItemID.MANA] then
			res1 = false
		end

		if cost[xyd.ItemID.PARTNER_EXP] > xyd.models.backpack:getItemNumByID(xyd.ItemID.PARTNER_EXP) - self.fakeUseRes[xyd.ItemID.PARTNER_EXP] then
			res1 = false
		end
	end

	self.btnLevUp_redPoint:SetActive(res1)
	self.btnEquipAll_redPoint:SetActive(res2)
	self.nav2_redPoint:SetActive(res2)
end

function PartnerDetailWindow:updatePuppetNav()
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		if self.navChosen == 3 or self.navChosen == 4 then
			self.defaultTab:setTabActive(1, true)
		else
			self.defaultTab:setTabActive(self.navChosen, true)
		end

		self.tab4none:SetActive(true)
		self.tab3none:SetActive(true)
	else
		self.tab3none:SetActive(false)

		if self.partner_:getStar() < 6 then
			local shenxueTableId = xyd.tables.partnerTable:getShenxueTableId(self.partner_:getTableID())

			if shenxueTableId == 0 then
				self:updateTab4("none")
				self.defaultTab:setTabActive(4, false)
				self.defaultTab:setTabEnable(4, false)

				if self.navChosen and self.navChosen ~= 4 then
					self.defaultTab:setTabActive(self.navChosen, true)
				else
					self.defaultTab:setTabActive(1, true)
				end
			elseif self.shenxueTableId_ and self.shenxueTableId_ == 0 then
				self.defaultTab:setTabEnable(4, true)

				if self.navChosen and self.navChosen ~= 4 then
					self.defaultTab:setTabActive(self.navChosen, true)
				else
					self.defaultTab:setTabActive(1, true)
				end
			end

			self.shenxueTableId_ = shenxueTableId
		else
			local maxGrade = self.partner_:getMaxGrade()

			if self.partner_:getGrade() < maxGrade and self.navChosen == 4 then
				self.defaultTab:setTabActive(1, true)
			end
		end

		if self.navChosen == 5 and (self.partner_:getStar() < 15 or xyd.tables.partnerTable:getStarOrigin(self.partner_:getTableID()) <= 0) and self.name_ ~= "activity_entrance_test_partner_window" then
			self.defaultTab:setTabActive(self.navChosen, false)
			self.defaultTab:setTabActive(1, true)
		else
			self.defaultTab:setTabActive(self.navChosen, true)
		end
	end
end

function PartnerDetailWindow:onRollBack(event)
	self:setAttrChange()
	xyd.WindowManager.get():closeThenOpenWindow(self.name_, "slot_window", {}, function ()
		local data = xyd.decodeProtoBuf(event.data)
		local items = data.items
		local ViwedPartnerID = nil
		local infos = {}

		for i = 1, #data.partners do
			local item = {
				item_num = 1,
				item_id = data.partners[i].table_id,
				awake = data.partners[i].awake,
				partner_id = data.partners[i].partner_id
			}

			if data.partners[i].is_vowed == 1 then
				ViwedPartnerID = data.partners[i].table_id
			end

			table.insert(infos, item)
		end

		local tmpData = {}
		local starData = {}

		for _, item in ipairs(infos) do
			local itemID = item.item_id
			local partner = xyd.models.slot:getPartner(item.partner_id)

			if tmpData[itemID] == nil then
				tmpData[itemID] = 0
			end

			starData[itemID] = partner:getStar()
			tmpData[itemID] = tmpData[item.item_id] + item.item_num
		end

		local datas = {}

		for k, v in pairs(tmpData) do
			table.insert(datas, {
				item_id = tonumber(k),
				item_num = v,
				star = starData[k]
			})
		end

		if ViwedPartnerID ~= nil then
			for i = 1, #datas do
				if datas[i].item_id == ViwedPartnerID then
					if datas[i].item_num > 1 then
						datas[i].item_num = datas[i].item_num - 1

						table.insert(datas, {
							item_num = 1,
							is_vowed = 1,
							item_id = datas[i].item_id,
							star = datas[i].star
						})
					else
						datas[i].is_vowed = 1
					end
				end
			end
		end

		local new_items = {}

		for i = 1, #items do
			if tonumber(items[i].item_num) ~= 0 then
				local new_item = {
					item_id = items[i].item_id,
					item_num = items[i].item_num
				}

				table.insert(new_items, new_item)
			end
		end

		xyd.WindowManager.get():openWindow("alert_heros_window", {
			data = datas
		}, function ()
			xyd.alertItems(new_items, nil, __("GET_ITEMS"))
		end)
	end)
end

function PartnerDetailWindow:checkLongTouch()
	if self.isLongTouch then
		xyd.showToast(__("IS_IN_BATTLE_FORMATION"))

		return true
	end

	return false
end

function PartnerDetailWindow:iosTestChangeUI()
	local winTrans = self.window_.transform
	local allChildren = winTrans:GetComponentsInChildren(typeof(UISprite), true)

	for i = 0, allChildren.Length - 1 do
		local sprite = allChildren[i]

		xyd.setUISprite(sprite, nil, sprite.spriteName .. "_ios_test")
	end

	xyd.setUISprite(self.btnUnequipAll:GetComponent(typeof(UISprite)), nil, "white_btn_65_65_ios_test")
	self.btnComment:SetActive(false)
	self.btnMarkPartner:SetActive(false)
end

function PartnerDetailWindow:playSound(dialog)
	if xyd.tables.partnerTable:checkPuppetPartner(self.partner_:getTableID()) then
		return
	end

	if not dialog or not next(dialog) or not dialog.time then
		return
	end

	if self.isPlaySound and self.currentDialog.sound == dialog.sound then
		return
	end

	if self.isPlaySound then
		if self.currentDialog.timeOutId then
			XYDCo.StopWait(self.currentDialog.timeOutId)
		end

		if self.currentDialog.sound then
			xyd.SoundManager.get():stopSound(self.currentDialog.sound)
		end
	end

	self.bubble:SetActive(true)

	self.tips.text = dialog.dialog

	xyd.SoundManager.get():playSound(dialog.sound)

	dialog.timeOutId = self:setTimeout(function ()
		self.isPlaySound = false

		self.bubble:SetActive(false)
	end, self, dialog.time * 1000)
	self.isPlaySound = true
	self.currentDialog = dialog
end

function PartnerDetailWindow:getCurPartner()
	return self.partner_
end

function PartnerDetailWindow:checkOpenPartnerBackWindow(event)
	if self.checkOpenPartnerBackWindowFlag == true then
		self.checkOpenPartnerBackWindowFlag = false
		local data = xyd.decodeProtoBuf(event.data)

		if data.partner_info.partner_id == self.partner_:getPartnerID() then
			xyd.WindowManager.get():openWindow("potentiality_back_window", {
				partner = self.partner_
			})
		end
	end
end

function PartnerDetailWindow:checkExSkillGuide()
	local wnd1 = xyd.getWindow("alert_award_window")
	local wnd2 = xyd.getWindow("potentiality_success_window")
	local wnd3 = xyd.getWindow("alert_item_window")
	local wnd4 = xyd.getWindow("awake_ok_window")

	if wnd1 or wnd2 or wnd3 or wnd4 then
		return
	end

	if self.isShrineHurdle_ then
		return
	end

	if not self:isWndComplete() then
		return
	end

	if self.isPlayingSwitchAnimation then
		return
	end

	if self.name_ ~= "partner_detail_window" then
		return
	end

	local slotWd = xyd.WindowManager.get():getWindow("slot_window")

	if not slotWd then
		return
	end

	if self.partner_:getStar() == 10 and xyd.tables.partnerTable:getExSkill(self.partner_:getTableID()) == 1 and self.partner_:getGroup() ~= xyd.PartnerGroup.TIANYI and xyd.models.slot:needExskillGuide() then
		xyd.WindowManager:get():openWindow("exskill_guide_window", {
			wnd = self,
			table = xyd.tables.partnerExskillGuideTable,
			guide_type = xyd.GuideType.PARTNER_EXSKILL
		})
		xyd.models.slot:setExskillGuide()
	end
end

function PartnerDetailWindow:onClickUnEquipAll()
	if self.isShrineHurdle_ then
		xyd.showToast(__("IS_IN_SHRINE_FORMATION"))

		return
	end

	local equips = self.partner_:getEquipment()

	if equips[1] + equips[2] + equips[3] + equips[4] + equips[6] == 0 then
		return
	end

	local now_equips = {
		0,
		0,
		0,
		0,
		equips[5],
		0,
		equips[7]
	}

	xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_OFF)
	self.partner_:equip(now_equips)
end

function PartnerDetailWindow:checkEquipTab()
end

return PartnerDetailWindow
