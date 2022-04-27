local PartnerDetailWindow = import(".PartnerDetailWindow")
local ActivityEntranceTestPartnerWindow = class("ActivityEntranceTestPartnerWindow", PartnerDetailWindow)
local TipsItem = class("TipsItem", import("app.components.BaseComponent"))
local EntranceTestPartnerWindowUpCon = import("app.components.EntranceTestPartnerWindowUpCon")
local EntranceTestPartnerWindowChooseGroup = import("app.components.EntranceTestPartnerWindowChooseGroup")

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
		self.redPoint:GetComponent(typeof(UIWidget)).depth = self.params.depth + 3
	end
end

function ActivityEntranceTestPartnerWindow:ctor(name, params)
	ActivityEntranceTestPartnerWindow.super.ctor(self, name, params)

	self.partner_ = params.partner
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	local collection_ids = xyd.models.collection:getData()

	if not collection_ids or #collection_ids <= 0 then
		xyd.models.collection:reqCollectionInfo()
	end

	self.currentSortedPartners_ = {}
	self.hideBtn_ = params.hide_btn
	self.partner_list_ = params.partner_list or {}
	self.is_guest = params.is_guest
	self.sort_type = params.sort_type
	self.current_group = params.current_group or 0

	if self.sort_key == "0_0" or not self.sort_key then
		self.sort_key = "0_0_0"
	end

	if not self.hideBtn_ then
		for key, p in pairs(self.activityData:getSortedPartners()[self.sort_key]) do
			if p.partnerID and p.partnerID ~= 0 then
				table.insert(self.currentSortedPartners_, p)
			end
		end

		for idx in pairs(self.currentSortedPartners_) do
			if self.currentSortedPartners_[idx].tableID == self.partner_.tableID then
				self.currentIdx_ = tonumber(idx)
			end
		end
	else
		for key, p in ipairs(self.partner_list_) do
			if p.tableID and p.tableID == self.partner_.tableID then
				table.insert(self.currentSortedPartners_, p)
			end
		end

		for idx in pairs(self.currentSortedPartners_) do
			if self.currentSortedPartners_[idx].tableID == self.partner_.tableID then
				self.currentIdx_ = tonumber(idx)
			end
		end
	end

	self.eventProxy_:addEventListener(xyd.event.CHOOSE_PARTNER_POTENTIAL, function (___, event)
		self.activityData:setPartnerTime(self.partner_)
	end, self)
end

function ActivityEntranceTestPartnerWindow:initCurIndex(params)
end

function ActivityEntranceTestPartnerWindow:getUIComponent()
	PartnerDetailWindow.getUIComponent(self)

	for i = 1, 4 do
		self["tab_cur_" .. tostring(i)] = self.defaultTabGroup:NodeByName("tab_" .. tostring(i)).gameObject
		self["tab_cur_box" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i), typeof(UnityEngine.BoxCollider))

		if i ~= 3 then
			self["tab_cur_chosen" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/chosen", typeof(UIWidget))
			self["tab_cur_unchosen" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/unchosen", typeof(UIWidget))
			self["tab_cur_chosen" .. tostring(i)].width = 210
			self["tab_cur_unchosen" .. tostring(i)].width = 210
			self["tab_cur_box" .. tostring(i)].size = Vector3(210, 50, 0)

			if i == 4 then
				local tab4none_UIWidget = self.tab4none:GetComponent(typeof(UIWidget))
				tab4none_UIWidget.width = 210
				local tab4none_BoxCollider = tab4none_UIWidget.gameObject:AddComponent(typeof(UnityEngine.BoxCollider))
				tab4none_UIWidget.autoResizeBoxCollider = true
				tab4none_BoxCollider.size = Vector3(210, 50, 0)
				self.tab4awakeLock.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
				self["tab_cur_label" .. tostring(i)] = self.defaultTabGroup:ComponentByName("tab_" .. tostring(i) .. "/label", typeof(UILabel))

				if self.activityData:getLevel() ~= xyd.EntranceTestLevelType.R1 then
					self["tab_cur_unchosen" .. tostring(i)].gameObject:SetActive(false)
				end
			end
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
	self.tab_cur_1:SetLocalPosition(-237, 0, 0)
	self.tab_cur_2:SetLocalPosition(0, 0, 0)
	self.tab_cur_4:SetLocalPosition(237, 0, 0)
	self.nav2_redPoint:SetLocalPosition(104, 20.5, 0)
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

	for i = 1, 4 do
		if i ~= 3 then
			local chosen = self["nav" .. i]:ComponentByName("chosen", typeof(UIWidget))
			local unchosen = self["nav" .. i]:ComponentByName("unchosen", typeof(UIWidget))
			chosen.width = 210
			unchosen.width = 210
		end
	end

	self.nav1:X(-210)
	self.nav4:X(210)

	self.equip_tips = TipsItem.new(self.nav2, {
		depth = 61,
		tipsText = __("ENTRANCE_TEST_UNEQUIP_TIP")
	})
	self.break_tips = TipsItem.new(self.nav4, {
		depth = 71,
		tipsText = __("ENTRANCE_TEST_UNEQUIP_TIP")
	})

	self.equip_tips:getGo():SetLocalPosition(87, 20, 0)
	self.break_tips:getGo():SetLocalPosition(87, 20, 0)
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
	self.content_2:Y(-51)
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
	self:changeCommonUI()
end

function ActivityEntranceTestPartnerWindow:changeCommonUI()
	self.detailBg_UIWidget.width = 680
	self.detailBg_UIWidget.height = 618

	self.detailBg_UIWidget.gameObject:Y(100)
	xyd.setUISpriteAsync(self.detailBg_UISprite, nil, "9gongge26", nil, , )

	self.upConItem = EntranceTestPartnerWindowUpCon.new(self.content, {})

	self.upConItem:getGo():SetLocalPosition(0, 317, 0)
	self.upConItem:setEffectConDepth(20)
	self.nav.gameObject:Y(164)
end

function ActivityEntranceTestPartnerWindow:onclickArrow(partnerInfo)
	self:partnerLevUp(true)

	for idx in pairs(self.currentSortedPartners_) do
		if self.currentSortedPartners_[idx].tableID == partnerInfo.tableID then
			self.currentIdx_ = tonumber(idx)
		end
	end

	self.needIdx_ = true

	if self.isPlaySound then
		xyd.SoundManager.get():stopSound(self.currentDialog.sound)
		self.bubble:SetActive(false)

		self.isPlaySound = false
	else
		self.isPlaySound = self.isPlaySound
	end

	self.needExSkillGuide = false
	self.ExSkillGuideInAward = false

	self:initFullOrderGradeUp()
	self:initFullOrderLevelUp()
	self:updateData()
	self:updateBg()
	self:updatePartnerSkin()
	self:setPledgeLayout()
	self:updateNameTag()
	self:checkExSkillBtn()
	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
	self:updateRedPointShow()
	self:initMarkedBtn()
	self:checkContentState()
	self:checkBtnCommentShow()
end

function ActivityEntranceTestPartnerWindow:playOpenAnimation(callback)
	ActivityEntranceTestPartnerWindow.super.super.playOpenAnimation(self, callback)
	self.bottom:SetLocalPosition(0, -175, 0)

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

		self.chooseGroup = EntranceTestPartnerWindowChooseGroup.new(self.bg.gameObject, {
			onClickPartner = handler(self, self.onclickArrow),
			tableID = self.partner_.tableID,
			current_group = self.current_group,
			sort_type = self.sort_type
		})

		self.chooseGroup:setPanelDepth()
		self.chooseGroup:SetLocalPosition(0, -850, 0)
		self:waitForTime(0.1, function ()
			self.down_tween = self:getSequence()

			self.down_tween:Append(self.chooseGroup:getGameObject().transform:DOLocalMoveY(-173, 0.1))
			self.down_tween:AppendCallback(function ()
				if self.down_tween then
					self.down_tween:Kill(true)

					self.isCanClose = true
				end
			end)
		end)
	end)
end

function ActivityEntranceTestPartnerWindow:preViewBg()
end

function ActivityEntranceTestPartnerWindow:updateBg()
end

function ActivityEntranceTestPartnerWindow:checkExSkillBtn()
	self.btnExSkill:SetActive(false)
end

function ActivityEntranceTestPartnerWindow:registerEvent()
	ActivityEntranceTestPartnerWindow.super.registerEvent(self)

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

	UIEventListener.Get(self.tab4none.gameObject).onClick = function ()
		xyd.alert(xyd.AlertType.TIPS, __("ENTRANCE_TEST_PARTNER_LOCK"))
	end
end

function ActivityEntranceTestPartnerWindow:onclickPartnerImg()
end

function ActivityEntranceTestPartnerWindow:initTopGroup()
end

function ActivityEntranceTestPartnerWindow:updateNameTag()
	self.upConItem:setPowerName(tostring(self.partner_:getName()))
end

function ActivityEntranceTestPartnerWindow:updateCV()
end

function ActivityEntranceTestPartnerWindow:initVars()
	self.partner_ = self.currentSortedPartners_[self.currentIdx_]
end

function ActivityEntranceTestPartnerWindow:closeSelf()
	if not self.isCanClose then
		return
	end

	if self.isPlaySound then
		self.isPlaySound = false
	end

	local win = xyd.WindowManager.get():getWindow("activity_entrance_test_slot_window")

	if not win then
		self.activityData:sendSettedPartnerReq()
	else
		win:showImgState(false)
		self.activityData:makeHeros()
		win:initData()
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityEntranceTestPartnerWindow:updateMiscObj()
	PartnerDetailWindow.updateMiscObj(self)
	self.btnUnlockPartner:SetActive(false)
	self.btnLockPartner:SetActive(false)

	self.labelLevUp.text = __("PARTNER_INFO_JOB")
end

function ActivityEntranceTestPartnerWindow:onclickEquip(itemID, equips)
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
					equipedPartner = self.partner_
				})
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end,
			leftLabel = __("REMOVE"),
			leftColor = xyd.ButtonBgColorType.red_btn_65_65,
			leftCallback = function ()
				self.partner_.equipments[6] = 0
				self.activityData.dataHasChange = true

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

function ActivityEntranceTestPartnerWindow:updateAttr()
	self.partner_:updateAttrs({
		isEntrance = true
	})
	PartnerDetailWindow.updateAttr(self)
	self.upConItem:setPowerLabel(tostring(self.partner_:getPower()))

	local params = {
		tableID = self.partner_.tableID,
		info = self.partner_:getInfo()
	}

	self.upConItem:setInfo(params)
end

function ActivityEntranceTestPartnerWindow:updateLoveIcon()
	self.loveIcon:SetActive(false)
end

function ActivityEntranceTestPartnerWindow:updateEquips()
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
								partner = self.partner_
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

function ActivityEntranceTestPartnerWindow:updateEquipRed()
	local hasRed = false

	for i in pairs(self.partner_.equipments) do
		if i < 7 and self.partner_.equipments[i] == 0 then
			hasRed = true

			break
		end
	end

	local skill_index = self.partner_:getSkillIndex()

	if not skill_index or skill_index == 0 then
		hasRed = true
	end

	if self.is_guest then
		hasRed = false
	end

	self.equip_tips:getGo():SetActive(hasRed)

	if self.activityData:getLevel() ~= xyd.EntranceTestLevelType.R1 then
		local hasPotentRed = false

		if #self.partner_.potentials >= 5 then
			for i in pairs(self.partner_.potentials) do
				if self.partner_.potentials[i] == 0 then
					hasPotentRed = true
				end
			end
		else
			hasPotentRed = true
		end

		if self.is_guest then
			hasPotentRed = false
		end

		self.break_tips:getGo():SetActive(hasPotentRed)
	end
end

function ActivityEntranceTestPartnerWindow:updateRedPointShow()
end

function ActivityEntranceTestPartnerWindow:onclickEmptyTreasure()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.is_guest then
		return
	end

	xyd.WindowManager.get():openWindow("activity_entrance_test_crystal_window", {
		partner = self.partner_
	})
end

function ActivityEntranceTestPartnerWindow:onclickEmptySoul()
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
		isEntrance = true,
		equipedPartner = self.partner_
	})
end

function ActivityEntranceTestPartnerWindow:checkBtnCommentShow()
	self.btnComment:SetActive(false)
end

function ActivityEntranceTestPartnerWindow:onClickSuitIcon()
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

function ActivityEntranceTestPartnerWindow:willClose()
	ActivityEntranceTestPartnerWindow.super.willClose(self)
end

function ActivityEntranceTestPartnerWindow:onClickEscBack()
	self:closeSelf()
end

function ActivityEntranceTestPartnerWindow:updateTenStarExchange()
	if not self.exchangeItem then
		self.exchangeItem = import("app.components.PotentialityComponent").new(self.exchangeComponent, self.is_guest)
	end

	self.exchangeComponent:SetActive(true)
	self.exchangeItem:setInfo(self.partner_)
	self.exchangeItem:setLongTouch(self.isLongTouch)

	if self.hideBtn_ then
		self.exchangeItem:hideBtn()
	end

	self.exchangeItem:setEntranceState()

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

function ActivityEntranceTestPartnerWindow:updateTab4(state)
	if self.activityData:getLevel() == xyd.EntranceTestLevelType.R1 then
		self.tab4none:SetActive(true)
		self.tab4awakeLock:SetActive(true)
		self.tab_cur_label4.gameObject:SetLocalPosition(15, 2, 0)

		local tab4awakeLock_UISprite = self.tab4awakeLock.gameObject:GetComponent(typeof(UISprite))

		self.tab4awakeLock.gameObject:X(15 - self.tab_cur_label4.width / 2 - 11 - tab4awakeLock_UISprite.width / 2)
	else
		self.tab4none:SetActive(false)
		self.tab4awakeLock:SetActive(false)
	end

	self.defaultTab.tabs[4].label:SetActive(true)
	self.nav4_redPoint:SetActive(false)
end

return ActivityEntranceTestPartnerWindow
