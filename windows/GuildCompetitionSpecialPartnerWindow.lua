local PartnerDetailWindow = import(".PartnerDetailWindow")
local GuildCompetitionSpecialPartnerWindow = class("GuildCompetitionSpecialPartnerWindow", PartnerDetailWindow)
local TipsItem = class("TipsItem", import("app.components.BaseComponent"))
local EntranceTestPartnerWindowUpCon = import("app.components.EntranceTestPartnerWindowUpCon")

function TipsItem:ctor(parentGo, params)
	self.params = params

	TipsItem.super.ctor(self, parentGo)
end

function TipsItem:getPrefabPath()
	return "Prefabs/Components/tips_item"
end

function TipsItem:initUI()
	self:getUIComponent()
	TipsItem.super.initUI(self)
	self:layout()
end

function TipsItem:getGo()
	return self.go.gameObject
end

function TipsItem:getUIComponent()
	self.newTipsNode = self.go:NodeByName("newTipsNode").gameObject
	self.bg = self.newTipsNode:NodeByName("img").gameObject
	self.newTipsWords = self.newTipsNode:ComponentByName("newTipsWords", typeof(UILabel))
	self.redPoint = self.newTipsNode:NodeByName("redPoint").gameObject
end

function TipsItem:layout()
	if self.params and self.params.depth then
		self.go:GetComponent(typeof(UIWidget)).depth = self.params.depth
		self.newTipsNode:GetComponent(typeof(UIWidget)).depth = self.params.depth + 1
		self.redPoint:GetComponent(typeof(UIWidget)).depth = self.params.depth + 10
	end
end

function GuildCompetitionSpecialPartnerWindow:ctor(name, params)
	GuildCompetitionSpecialPartnerWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
	local collection_ids = xyd.models.collection:getData()

	if not collection_ids or #collection_ids <= 0 then
		xyd.models.collection:reqCollectionInfo()
	end

	self.currentSortedPartners_ = {
		self.partner_
	}
	self.hideBtn_ = params.hide_btn
	self.partner_list_ = params.partner_list or {}
	self.is_guest = params.is_guest
	self.sort_type = params.sort_type
	self.current_group = params.current_group or 0
	self.partnerParams = params.partnerParams

	if self.sort_key == "0_0" or not self.sort_key then
		self.sort_key = "0_0_0"
	end

	self.currentIdx_ = 1
end

function GuildCompetitionSpecialPartnerWindow:initCurIndex(params)
end

function GuildCompetitionSpecialPartnerWindow:getUIComponent()
	PartnerDetailWindow.getUIComponent(self)

	for i = 1, 5 do
		self["tab_cur_" .. tostring(i)] = self.defaultTabGroup:NodeByName("tab_" .. tostring(i)).gameObject
		self["tab_cur_box" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i), typeof(UnityEngine.BoxCollider))

		if i ~= 3 and i ~= 5 then
			self["tab_cur_chosen" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/chosen", typeof(UIWidget))
			self["tab_cur_unchosen" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/unchosen", typeof(UIWidget))
			self["tab_cur_chosen" .. tostring(i)].width = 156
			self["tab_cur_unchosen" .. tostring(i)].width = 156
			self["tab_cur_box" .. tostring(i)].size = Vector3(156, 50, 0)

			if i == 2 then
				local tab2none_UIWidget = self.tab2none:GetComponent(typeof(UIWidget))
				tab2none_UIWidget.width = 156
				local tab2none_BoxCollider = tab2none_UIWidget.gameObject:AddComponent(typeof(UnityEngine.BoxCollider))
				tab2none_UIWidget.autoResizeBoxCollider = true
				tab2none_BoxCollider.size = Vector3(156, 50, 0)
				self.tab2equipLock.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self["tab_cur_label" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/label", typeof(UILabel))
			elseif i == 4 then
				local tab4none_UIWidget = self.tab4none:GetComponent(typeof(UIWidget))
				tab4none_UIWidget.width = 208
				local tab4none_BoxCollider = tab4none_UIWidget.gameObject:AddComponent(typeof(UnityEngine.BoxCollider))
				tab4none_UIWidget.autoResizeBoxCollider = true
				tab4none_BoxCollider.size = Vector3(156, 50, 0)
				self.tab4awakeLock.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self["tab_cur_label" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/label", typeof(UILabel))

				self["tab_cur_unchosen" .. tostring(i)].gameObject:SetActive(false)
			end

			self["tab_cur_" .. tostring(i)]:SetActive(true)
		else
			self["tab_cur_" .. tostring(i)]:SetActive(false)
		end
	end

	self.content = self.groupInfo:NodeByName("content").gameObject
	self.windowBg = self.window_:NodeByName("WINDOWBG").gameObject
	self.detailBg_UIWidget = self.content:ComponentByName("detailBg", typeof(UIWidget))
	self.detailBg_UISprite = self.content:ComponentByName("detailBg", typeof(UISprite))
	self.nav = self.groupInfo:NodeByName("nav").gameObject
	self.bg = self.window_:NodeByName("bg").gameObject
	self.ns1_MultiLabel = self.content_1:ComponentByName("ns1:MultiLabel", typeof(UILabel))
	self.bottom = self.window_:NodeByName("bottom").gameObject

	self.bottom:GetComponent(typeof(UIRect)):SetTopAnchor(nil, 0, 0)
	self.bottom:GetComponent(typeof(UIRect)):SetBottomAnchor(nil, 0, 0)
	self.tab_cur_1:SetLocalPosition(-234, 0, 0)
	self.tab_cur_2:SetLocalPosition(-78, 0, 0)
	self.tab_cur_4:SetLocalPosition(78, 0, 0)
	self.tab_cur_5:SetLocalPosition(234, 0, 0)
	self.nav2_redPoint:SetLocalPosition(67, 20.5, 0)
	self.btnUnequipAll:SetActive(false)
	self.btnEquipAll:SetActive(false)
	self.content_2:SetLocalPosition(0, -30, 0)

	for i = 1, 2 do
		self["e_Image" .. i] = self.content_1.gameObject:NodeByName("e_Image" .. i).gameObject

		self["e_Image" .. i]:SetActive(false)
	end

	self.nav1 = self.defaultTabGroup:NodeByName("tab_1").gameObject
	self.nav2 = self.defaultTabGroup:NodeByName("tab_2").gameObject
	self.nav4 = self.defaultTabGroup:NodeByName("tab_4").gameObject
	self.nav5 = self.defaultTabGroup:NodeByName("tab_5").gameObject

	for i = 1, 4 do
		if i ~= 3 then
			local chosen = self["nav" .. i]:ComponentByName("chosen", typeof(UIWidget))
			local unchosen = self["nav" .. i]:ComponentByName("unchosen", typeof(UIWidget))
			local label = self["nav" .. i]:ComponentByName("label", typeof(UIWidget))
			chosen.width = 208
			unchosen.width = 208
			label.width = 200

			if i == 4 then
				local none = self["nav" .. i]:ComponentByName("none", typeof(UIWidget))
				none.width = 208
			end
		end
	end

	self.nav1:X(-208)
	self.nav2:X(0)
	self.nav4:X(208)

	self.equip_tips = TipsItem.new(self.nav2, {
		depth = 61,
		tipsText = __("ENTRANCE_TEST_UNEQUIP_TIP")
	})
	self.break_tips = TipsItem.new(self.nav4, {
		depth = 71,
		tipsText = __("ENTRANCE_TEST_UNEQUIP_TIP")
	})

	self.equip_tips:getGo():SetLocalPosition(67, 20, 0)
	self.break_tips:getGo():SetLocalPosition(67, 20, 0)
	self.midBtns:Y(640)
	self.equip_tips:SetActive(false)
	self.break_tips:SetActive(false)

	self.gradeup = self.content_1:NodeByName("gradeup").gameObject

	self.gradeup:SetLocalPosition(0, 72, 0)

	self.gradeup_group = self.gradeup:NodeByName("e:Group").gameObject

	self.gradeup_group:SetLocalPosition(-250, 2.5, 0)

	self.gradeup_image = self.gradeup:ComponentByName("e:Group/e:Image", typeof(UIWidget))
	self.gradeup_image.width = 124
	self.gradeup_image.height = 40

	self.gradeItem:NodeByName("bg").gameObject:SetLocalScale(1.1, 1.1, 0)
	self.gradeItem:NodeByName("img").gameObject:SetLocalScale(1.1, 1.1, 0)
	self.gradeGroup:SetLocalPosition(-140, 2, 0)

	self.gradeGroupGrid.cellWidth = 64
	self.levelup = self.content_1:NodeByName("levelup").gameObject

	self.levelup.gameObject:SetLocalPosition(0, 132, 0)

	self.levelup_group = self.levelup:NodeByName("e:Group").gameObject

	self.levelup_group:SetLocalPosition(-250, 0, 0)

	self.levelup_image = self.levelup:ComponentByName("e:Group/e:Image", typeof(UIWidget))
	self.levelup_image.width = 124
	self.levelup_image.height = 40
	self.maxGroup = self.levelup:NodeByName("maxGroup").gameObject

	self.maxGroup:SetActive(false)
	self.jobIcon.gameObject:SetLocalPosition(-138, 132, 0)
	self.labelJob.gameObject:SetLocalPosition(-98, 132, 0)

	local attr = self.content_1:NodeByName("attr").gameObject

	attr:SetLocalPosition(0, 15, 0)

	local skill = self.content_1:NodeByName("skill").gameObject

	skill:SetLocalPosition(-10, -93, 0)

	local skill_bg = skill:NodeByName("e:Image").gameObject
	local skill_bg_sprite = skill:ComponentByName("e:Image", typeof(UISprite))
	local skill_bg_widget = skill_bg:GetComponent(typeof(UIWidget))

	xyd.setUISpriteAsync(skill_bg_sprite, nil, "9gongge23", nil, , )

	skill_bg_widget.width = 650
	skill_bg_widget.height = 150

	skill_bg_widget.gameObject:SetLocalPosition(12, 0, 0)

	self.closeBtnNew = NGUITools.AddChild(self.content.gameObject, self.btnZoom.gameObject)
	self.closeBtnNew.gameObject.name = "closeBtnNew"
	self.closeBtnNew_sprite = self.closeBtnNew:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.closeBtnNew_sprite, nil, "close_btn", nil, , )

	self.closeBtnNew_sprite.height = 60
	self.closeBtnNew_sprite.width = 60
	self.closeBtnNew_sprite.depth = 100

	self.closeBtnNew_sprite.gameObject:SetLocalPosition(295, 366, 0)

	local tipsText = self.content_1:ComponentByName("labelTips", typeof(UILabel))
	tipsText.text = __("ENTRANCE_TEST_SKILL_UNSURE")

	tipsText:Y(-185)
	tipsText:X(-320)
	self.content_2:Y(-51)
	self.content_6:Y(-57)
	self.page_guide.gameObject:SetActive(false)
	self.groupBg.gameObject:SetActive(false)
	self.groupBgMini.gameObject:SetActive(false)
	self.btnZoom.gameObject:SetActive(false)
	self.playerNameGroup.gameObject:SetActive(false)
	self.top_right.gameObject:SetActive(false)
	self.partnerImgNode.gameObject:SetActive(false)
	self.content_1_battleIcon.gameObject:SetActive(false)
	self.labelBattlePoint.gameObject:SetActive(false)
	self.ns1_MultiLabel.gameObject:SetActive(false)
	self.labelLev.gameObject:SetActive(false)
	self.labelMaxAwake.gameObject:SetActive(false)
	self.btnStarOriginDetail:SetActive(false)
	self:changeCommonUI()
end

function GuildCompetitionSpecialPartnerWindow:updateNavShow()
end

function GuildCompetitionSpecialPartnerWindow:changeCommonUI()
	self.detailBg_UIWidget.width = 680
	self.detailBg_UIWidget.height = 618

	self.detailBg_UIWidget.gameObject:Y(100)
	xyd.setUISpriteAsync(self.detailBg_UISprite, nil, "9gongge26", nil, , )

	self.upConItem = EntranceTestPartnerWindowUpCon.new(self.content, {})

	self.upConItem:getGo():SetLocalPosition(0, 317, 0)
	self.upConItem:setEffectConDepth(31)
	self.nav.gameObject:Y(164)
end

function GuildCompetitionSpecialPartnerWindow:onclickArrow(partnerInfo)
end

function GuildCompetitionSpecialPartnerWindow:playOpenAnimation(callback)
	GuildCompetitionSpecialPartnerWindow.super.super.playOpenAnimation(self, callback)
	self.bottom:SetLocalPosition(0, -300, 0)

	local originScaleZ = self.bottom.gameObject.transform.localScale.z
	self.bottom.gameObject.transform.localScale = Vector3(0.5, 0.5, originScaleZ)

	local function setter(value)
		self.bottom.gameObject:GetComponent(typeof(UIWidget)).alpha = value
	end

	local sequence = self:getSequence()

	sequence:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0.5, 1, 0.13):SetEase(DG.Tweening.Ease.Linear))
	sequence:Join(self.bottom.gameObject.transform:DOScale(Vector3(1.1, 1.1, originScaleZ), 0.13):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(self.bottom.gameObject.transform:DOScale(Vector3(0.97, 0.97, originScaleZ), 0.13):SetEase(DG.Tweening.Ease.Linear))
	sequence:Append(self.bottom.gameObject.transform:DOScale(Vector3(1, 1, originScaleZ), 0.16):SetEase(DG.Tweening.Ease.Linear))
	sequence:AppendCallback(function ()
		if sequence then
			sequence:Kill(true)
		end

		self.isCanClose = true
	end)
end

function GuildCompetitionSpecialPartnerWindow:preViewBg()
end

function GuildCompetitionSpecialPartnerWindow:updateBg()
end

function GuildCompetitionSpecialPartnerWindow:checkExSkillBtn()
	self.btnExSkill:SetActive(false)
end

function GuildCompetitionSpecialPartnerWindow:registerEvent()
	GuildCompetitionSpecialPartnerWindow.super.registerEvent(self)

	UIEventListener.Get(self.partnerImgNode).onDragStart = nil
	UIEventListener.Get(self.partnerImgNode).onDrag = nil
	UIEventListener.Get(self.partnerImgNode).onDragEnd = nil
	UIEventListener.Get(self.partnerImgNode).onClick = nil

	UIEventListener.Get(self.windowBg).onClick = function ()
		self:closeSelf()
	end

	UIEventListener.Get(self.bg).onClick = function ()
		self:closeSelf()
	end

	UIEventListener.Get(self.closeBtnNew).onClick = function ()
		self:closeSelf()
	end

	UIEventListener.Get(self.tab2none.gameObject).onClick = function ()
		local period = xyd.tables.activityWarmupArenaPartnerTable:getPeriodByPartnerId(self.partner_.tableID)

		xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_NEW_WARMUP_TEXT" .. period + 25))
	end

	UIEventListener.Get(self.tab4none.gameObject).onClick = function ()
		xyd.alert(xyd.AlertType.TIPS, __("GUILD_COMPETITION_PARTNER_TEXT05"))
	end
end

function GuildCompetitionSpecialPartnerWindow:onclickPartnerImg()
end

function GuildCompetitionSpecialPartnerWindow:initTopGroup()
end

function GuildCompetitionSpecialPartnerWindow:updateNameTag()
	self.upConItem:setPowerName(tostring(self.partner_:getName()))
end

function GuildCompetitionSpecialPartnerWindow:updateCV()
end

function GuildCompetitionSpecialPartnerWindow:initVars()
end

function GuildCompetitionSpecialPartnerWindow:closeSelf()
	if not self.isCanClose then
		return
	end

	if self.isPlaySound then
		self.isPlaySound = false
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function GuildCompetitionSpecialPartnerWindow:updateMiscObj()
	PartnerDetailWindow.updateMiscObj(self)
	self.btnUnlockPartner:SetActive(false)
	self.btnLockPartner:SetActive(false)

	self.labelLevUp.text = __("PARTNER_INFO_JOB")
end

function GuildCompetitionSpecialPartnerWindow:onclickEquip(itemID, equips)
	local itemTable = xyd.tables.itemTable
	local upArrowCallback = nil

	if itemTable:getType(itemID) == xyd.ItemType.ARTIFACT then
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
				xyd.WindowManager:get():openWindow("activity_entrance_test_soul_window", {
					now_equip = itemID,
					equipedOn = self.partner_:getInfo(),
					equipedPartner = self.partner_,
					windowType = xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL
				})
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end,
			leftLabel = __("REMOVE"),
			leftColor = xyd.ButtonBgColorType.red_btn_65_65,
			leftCallback = function ()
				self.partner_.equipments[6] = 0

				self:updateData()
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	local params = {
		fakeSkill = true,
		btnLayout = 0,
		equipedOn = self.partner_:getInfo(),
		equipedPartner = self.partner_,
		itemID = itemID,
		equips = equips,
		upArrowCallback = upArrowCallback,
		fakePartner = self.partner_
	}

	xyd.WindowManager.get():openWindow("item_tips_window", params)
end

function GuildCompetitionSpecialPartnerWindow:updateAttr()
	self.partner_:updateAttrs()
	PartnerDetailWindow.updateAttr(self)
	self.upConItem:setPowerLabel(tostring(self.partner_:getPower()))

	local params = {
		tableID = self.partner_.tableID,
		info = self.partner_:getInfo()
	}

	self.upConItem:setInfo(params)
end

function GuildCompetitionSpecialPartnerWindow:updateLoveIcon()
	self.loveIcon:SetActive(false)
end

function GuildCompetitionSpecialPartnerWindow:updateEquips()
	local equips = self.partner_:getEquipment()
	self.bp_equips = {}
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

	for i in pairs(datas) do
		local itemID = datas[i].item_id
		local itemNum = datas[i].item_num
		local item = {
			itemID = itemID,
			itemNum = itemNum
		}

		if itemNum then
			local pos = MAP_TYPE_2_POS[itemTable:getType(itemID)]

			if pos ~= nil then
				self.bp_equips[pos] = self.bp_equips[pos] or {}

				table.insert(self.bp_equips[pos], item)
			end
		end
	end

	local equipsOfPartners = xyd.models.slot:getEquipsOfPartners()

	for key, value in pairs(equipsOfPartners) do
		local itemID = tonumber(key)
		local itemNum = 1
		local pos = MAP_TYPE_2_POS[itemTable:getType(itemID)]

		if pos ~= nil then
			for partnerkey, partnerId in pairs(equipsOfPartners[key]) do
				local item = {
					itemID = itemID,
					itemNum = itemNum,
					partner_id = partnerId
				}
				self.bp_equips[pos] = self.bp_equips[pos] or {}

				table.insert(self.bp_equips[pos], item)
			end
		end
	end

	local flag = false

	for key in pairs(equips) do
		local itemID = equips[key]

		if tonumber(key) == 7 then
			-- Nothing
		elseif tonumber(key) == 5 then
			if itemID > 0 then
				self["iconEquip" .. tostring(key)]:setInfo({
					noClickSelected = true,
					itemID = itemID,
					callback = function ()
						if not self.hideBtn_ then
							xyd.WindowManager.get():openWindow("activity_entrance_test_crystal_window", {
								partner = self.partner_,
								windowType = xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL
							})
						else
							local params = {
								fakeSkill = true,
								btnLayout = 0,
								equipedOn = self.partner_:getInfo(),
								equipedPartner = self.partner_,
								itemID = itemID,
								equips = equips,
								fakePartner = self.partner_
							}

							xyd.WindowManager.get():openWindow("item_tips_window", params)
						end
					end
				})

				local effect = self.equipPlusEffects[key]

				if effect then
					effect:stop()
					effect:SetActive(false)
				end

				self["iconEquip" .. tostring(key)]:SetActive(true)
			else
				self["iconEquip" .. tostring(key)]:SetActive(false)
				self["plusEquip" .. tostring(key)]:SetActive(false)
				self:applyPlusEffect(self["plusEquip" .. tostring(key)], true, key)
				self.equipLock:SetActive(false)
			end
		elseif itemID > 0 then
			local itemEffect = nil

			if tonumber(key) == 6 and xyd.tables.equipTable:getQuality(itemID) >= 6 and not xyd.tables.equipTable:getArtifactUpNext(itemID) then
				itemEffect = "hunqiui"
			end

			self["iconEquip" .. tostring(key)]:setInfo({
				noClickSelected = true,
				itemID = itemID,
				callback = function ()
					if self.is_guest then
						return
					end

					self:onclickEquip(itemID, self.bp_equips[key])
				end,
				effect = itemEffect
			})
			self["iconEquip" .. tostring(key)]:SetActive(true)
			self:applyPlusEffect(self["plusEquip" .. tostring(key)], false, key)
		else
			self["plusEquip" .. tostring(key)]:SetActive(false)
			self:applyPlusEffect(self["plusEquip" .. tostring(key)], true, key)
			self["iconEquip" .. tostring(key)]:SetActive(false)
		end
	end

	self:updateEquipRed()
	self:updateSuitStatus()
end

function GuildCompetitionSpecialPartnerWindow:updateEquipRed()
end

function GuildCompetitionSpecialPartnerWindow:updateRedPointShow()
end

function GuildCompetitionSpecialPartnerWindow:onclickEmptyTreasure()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.is_guest then
		return
	end

	xyd.WindowManager.get():openWindow("activity_entrance_test_crystal_window", {
		partner = self.partner_,
		windowType = xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL
	})
end

function GuildCompetitionSpecialPartnerWindow:onclickEmptySoul()
	if self.hideBtn_ then
		local equips = self.partner_:getEquipment()
		local params = {
			fakeSkill = true,
			btnLayout = 0,
			equipedOn = self.partner_:getInfo(),
			equipedPartner = self.partner_,
			itemID = equips[6],
			equips = equips,
			fakePartner = self.partner_
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
	xyd.WindowManager.get():openWindow("activity_entrance_test_soul_window", {
		equipedPartner = self.partner_,
		windowType = xyd.TestCrystalOrSoulWindowType.GUILD_COMPETITION_SPECIAL
	})
end

function GuildCompetitionSpecialPartnerWindow:checkBtnCommentShow()
	self.btnComment:SetActive(false)
end

function GuildCompetitionSpecialPartnerWindow:onClickNav(index)
	GuildCompetitionSpecialPartnerWindow.super.onClickNav(self, index)

	local isNew = false
	local tableIDs = xyd.tables.miscTable:split2num("entrance_test_help_show", "value", "|")

	for i = 1, #tableIDs do
		if tableIDs[i] == self.partner_.tableID then
			isNew = true
		end
	end

	if index == 1 and isNew then
		self.content_1:ComponentByName("labelTips", typeof(UILabel)):SetActive(true)
	else
		self.content_1:ComponentByName("labelTips", typeof(UILabel)):SetActive(false)
	end
end

function GuildCompetitionSpecialPartnerWindow:onClickSuitIcon()
	local skillIndex = self.partner_.skill_index
	local skill_list = self:getSuitSkill()

	if self.is_guest then
		return
	end

	if skillIndex and skillIndex > 0 then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			fakeSkill = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			skillIndex = skillIndex,
			partner = self.partner_
		})
	elseif self.hasSuit_ then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			fakeSkill = true,
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			partner = self.partner_
		})
	end
end

function GuildCompetitionSpecialPartnerWindow:willClose()
	GuildCompetitionSpecialPartnerWindow.super.willClose(self)

	local guild_competition_partner_study_window = xyd.WindowManager.get():getWindow("guild_competition_partner_study_window")

	if guild_competition_partner_study_window then
		guild_competition_partner_study_window:saveInfo()
	else
		xyd.models.guild:setCompetitionSpecialPartner(self.partner_)
	end
end

function GuildCompetitionSpecialPartnerWindow:onClickEscBack()
	self:closeSelf()
end

function GuildCompetitionSpecialPartnerWindow:updateTenStarExchange()
	if not self.exchangeItem then
		self.exchangeItem = import("app.components.PotentialityComponent").new(self.exchangeComponent, self.is_guest)
	end

	self.exchangeComponent:SetActive(true)
	self.exchangeItem:setInfo(self.partner_)
	self.exchangeItem:setLongTouch(self.isLongTouch)

	if self.hideBtn_ then
		self.exchangeItem:hideBtn()
	end

	self.exchangeItem:setGuildCompetitionSpecialState()

	local exchangeComponent_bg = self.exchangeComponent:NodeByName("potentiality_component2/e:Image1").gameObject

	exchangeComponent_bg:SetActive(false)
	self.labelMaxAwake:SetActive(false)
	self.exchangeComponent.gameObject:SetLocalScale(0.9, 0.9, 0)
	self.exchangeComponent.gameObject:SetLocalPosition(0, -13, 0)

	local e_img_line1 = self.exchangeComponent:NodeByName("potentiality_component2/e:Image2").gameObject

	e_img_line1:SetActive(false)

	local e_img_line1 = self.content_4:ComponentByName("e:Image", typeof(UIWidget))
	e_img_line1.width = 606

	e_img_line1.gameObject:Y(-100.5)
end

function GuildCompetitionSpecialPartnerWindow:updateTab4(state)
	if self.partner_:getStar() < 10 then
		self.tab4none:SetActive(true)
		self:updateNavAlpha(4, false)
		self.tab4awakeLock:SetActive(true)
		self.tab4awakeLock.gameObject:X(-75)
		self.labelAwake:X(0)
	else
		self.tab4none:SetActive(false)
		self:updateNavAlpha(4, true)
		self.tab4awakeLock:SetActive(false)
		self.labelAwake:X(0)
	end

	self.defaultTab.tabs[4].label:SetActive(true)
	self.nav4_redPoint:SetActive(false)
end

function GuildCompetitionSpecialPartnerWindow:updateStarOriginGroup()
	GuildCompetitionSpecialPartnerWindow.super.updateStarOriginGroup(self)
end

function GuildCompetitionSpecialPartnerWindow:checkStarOriginUpdate()
	if self.navChosen ~= 5 then
		return
	end

	self:updateStarOriginGroup()
end

function GuildCompetitionSpecialPartnerWindow:onClickStarOriginBtn()
end

function GuildCompetitionSpecialPartnerWindow:getStarOriginNodeLev(nodeTableID)
	local partnerTableID = self.partner_:getTableID()
	local listTableID = xyd.tables.partnerTable:getStarOrigin(partnerTableID)
	local starIDs = xyd.tables.starOriginListTable:getNode(listTableID)
	local startIDs = xyd.tables.starOriginListTable:getStartIDs(listTableID)
	local endIDs = xyd.tables.starOriginListTable:getEndIDs(listTableID)

	for i = 1, #starIDs do
		if starIDs[i] == nodeTableID then
			return endIDs[i] - startIDs[i]
		end
	end

	return 0
end

function GuildCompetitionSpecialPartnerWindow:checkStarOriginTab()
end

function GuildCompetitionSpecialPartnerWindow:checkEquipTab()
	self.tab2none:SetActive(false)
	self.tab2equipLock.gameObject:SetActive(false)
	self:updateNavAlpha(2, true)
	self.labelEquip:X(0)

	self.labelEquip.fontSize = 26

	if xyd.Global.lang == "fr_fr" then
		self.labelEquip.fontSize = 18
	elseif xyd.Global.lang == "de_de" then
		self.labelEquip.fontSize = 18
	end
end

function GuildCompetitionSpecialPartnerWindow:updateNavAlpha(navIndex, visible)
	if not self["alphaNavChosen" .. navIndex] then
		self["alphaNavChosen" .. navIndex] = self.defaultTabGroup:ComponentByName("tab_" .. navIndex .. "/chosen", typeof(UISprite))
	end

	if not self["alphaNavUnchosen" .. navIndex] then
		self["alphaNavUnchosen" .. navIndex] = self.defaultTabGroup:ComponentByName("tab_" .. navIndex .. "/unchosen", typeof(UISprite))
	end
end

function GuildCompetitionSpecialPartnerWindow:firstInit()
	GuildCompetitionSpecialPartnerWindow.super.firstInit(self)
end

function GuildCompetitionSpecialPartnerWindow:updateData()
	GuildCompetitionSpecialPartnerWindow.super.updateData(self)
end

function GuildCompetitionSpecialPartnerWindow:updateLevUp()
	GuildCompetitionSpecialPartnerWindow.super.updateLevUp(self)
	self.groupLevupCost:SetActive(false)
	self.btnLevUp:SetActive(false)
end

function GuildCompetitionSpecialPartnerWindow:checkPartnerBackBtn()
end

function GuildCompetitionSpecialPartnerWindow:updateNavState()
	self.status_ = "POTENTIALITY"
end

return GuildCompetitionSpecialPartnerWindow
