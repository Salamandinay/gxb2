local PartnerDetailWindow = import(".PartnerDetailWindow")
local QuickFormationPartnerDetailWindow = class("QuickFormationPartnerDetailWindow", PartnerDetailWindow)

function QuickFormationPartnerDetailWindow:ctor(name, params)
	QuickFormationPartnerDetailWindow.super.ctor(self, name, params)

	self.showSkinId = 0
	self.quickItem_ = params.quickItem
	self.bpEquips = params.equipsTable

	dump(self.bpEquips, "self.bpEquips")

	if params.skin_id and params.skin_id > 0 then
		self.showSkinId = params.skin_id
	end
end

function QuickFormationPartnerDetailWindow:initCurIndex(params)
	self.partner_ = params.partner

	if self.partner_.skin_id and self.partner_.skin_id > 0 then
		self.partner_:setShowID(self.partner_.skin_id)
		self.partner_:setShowSkin(self.partner_.skin_id)
	end

	self.currentIdx_ = 1
	self.currentSortedPartners_ = {
		self.partner_.partner_id
	}
end

function QuickFormationPartnerDetailWindow:checkLongTouch()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))

	return true
end

function QuickFormationPartnerDetailWindow:onClickSuitIcon()
	local skillIndex = self.partner_.skill_index
	local skill_list = self:getSuitSkill()

	if skillIndex and skillIndex > 0 then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			skillIndex = skillIndex,
			quickItem = self.quickItem_,
			partner = self.partner_
		})
	elseif self.hasSuit_ then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			quickItem = self.quickItem_
		})
	end
end

function QuickFormationPartnerDetailWindow:onclickTreasure(itemID)
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
			xyd.alertTips(__("QUICK_FORMATION_TEXT02"))
		end,
		leftLabel = __("TRANSFORM"),
		leftColor = xyd.ButtonBgColorType.blue_btn_65_65,
		leftCallback = function ()
			xyd.alertTips(__("QUICK_FORMATION_TEXT02"))
		end,
		midCallback = function ()
			xyd.alertTips(__("QUICK_FORMATION_TEXT02"))
		end,
		midColer = xyd.ButtonBgColorType.blue_btn_65_65,
		midLabel = __("TRANSFORM")
	}

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

function QuickFormationPartnerDetailWindow:onclickTreasureExchange(itemID)
	xyd.WindowManager:get():openWindow("treasure_select_window", {
		type = 1,
		itemID = itemID,
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_,
		quickItem = self.quickItem_
	})
end

function QuickFormationPartnerDetailWindow:updateTenStarExchange()
	if not self.exchangeItem then
		self.exchangeItem = import("app.components.PotentialityComponent").new(self.exchangeComponent)
	end

	self.exchangeComponent:SetActive(true)
	self.exchangeItem:setInfo(self.partner_)
	self.exchangeItem:setLongTouch(true)
	self.exchangeItem:setQuickItem(self.quickItem_)

	self.exchangeItem.isQuickFormation_ = true
end

function QuickFormationPartnerDetailWindow:updateWindowShow()
	self:partnerLevUp(true)

	self.needExSkillGuide = false
	self.needStarOriginGuide = false

	self:initFullOrderGradeUp()
	self:initFullOrderLevelUp()
	self:updateData()
	self:updateBg()
	self:updatePartnerSkin()
	self:setPledgeLayout()
	self:updateNameTag()
	self:checkExSkillBtn()
	self:checkPartnerBackBtn()
	self:initMarkedBtn()
	self:checkContentState()
	self:checkStarOriginUpdate()
	self:checkBtnCommentShow()
end

function QuickFormationPartnerDetailWindow:updateRedPointShow()
end

function QuickFormationPartnerDetailWindow:checkStarOriginTab()
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

function QuickFormationPartnerDetailWindow:onclickEmptyTreasure()
	local open_lev = xyd.tables.miscTable:getVal("treasure_open_level")

	if self.partner_:getLevel() < tonumber(open_lev) then
		xyd.alert(xyd.AlertType.TIPS, __("TREASURE_NOT_OPEN"))
	else
		xyd.showToast(__("QUICK_FORMATION_TEXT02"))
	end
end

function QuickFormationPartnerDetailWindow:onClickStarOriginBtn()
	xyd.openWindow("star_origin_detail_window", {
		isQuickFormation = true,
		partnerID = self.partner_:getPartnerID()
	})
end

function QuickFormationPartnerDetailWindow:onclickLevUp()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onSkinOn()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onSkinOff()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onSelectContainer()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onSetSkinvisible()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onSetPicture()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onBuyTouch()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onclickAwake()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onClickHeroIcon()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:onClickShenXueBtn()
	xyd.showToast(__("QUICK_FORMATION_TEXT02"))
end

function QuickFormationPartnerDetailWindow:levUpLongTouch()
end

function QuickFormationPartnerDetailWindow:updateEquips()
	local equips = self.partner_:getEquipment()

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
					self:onclickEquip(itemID, key)
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

function QuickFormationPartnerDetailWindow:onclickEmptySoul()
	local equips = self.bpEquips[6]

	if equips and #equips > 0 then
		self:onclickEmptyEquip(self.bpEquips[6])
	else
		xyd.alert(xyd.AlertType.TIPS, __("GET_FROM_STAGE", "9-9"))
	end
end

function QuickFormationPartnerDetailWindow:onclickEmptyEquip(equips)
	xyd.WindowManager:get():openWindow("choose_equip_window", {
		equips = equips,
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_,
		quickItem = self.quickItem_
	})
end

function QuickFormationPartnerDetailWindow:onclickEquip(itemID, key)
	local equips = self.bpEquips[key]
	local itemTable = xyd.tables.itemTable
	local upArrowCallback = nil

	if itemTable:getType(itemID) == xyd.ItemType.ARTIFACT and xyd.tables.equipTable:getArtifactUpNext(itemID) ~= 0 then
		function upArrowCallback()
			xyd.WindowManager:get():openWindow("artifact_up_window", {
				itemID = itemID,
				equips = equips,
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_,
				quickItem = self.quickItem_
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
				equipedPartner = self.partner_,
				quickItem = self.quickItem_
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		leftLabel = __("REMOVE"),
		leftColor = xyd.ButtonBgColorType.red_btn_65_65,
		leftCallback = function ()
			self.quickItem_:unEquipSingle(itemID)
			xyd.WindowManager:get():closeWindow("item_tips_window")
			self:updateWindowShow()
		end
	}

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

function QuickFormationPartnerDetailWindow:onClickUnEquipAll()
	local equips = self.partner_:getEquipment()

	if equips[1] + equips[2] + equips[3] + equips[4] + equips[6] == 0 then
		return
	end

	for i = 1, 6 do
		if i ~= 5 and equips[i] > 0 then
			self.quickItem_:unEquipSingle(equips[i])
		end
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_OFF)
	self:updateWindowShow()
end

function QuickFormationPartnerDetailWindow:onclickBtnEquipAll()
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
			self.quickItem_:equipSingle(bestItemID)

			flag_changed = true
		elseif max_lv == old_i_lv and self.partner_:getJob() == xyd.tables.equipTable:getJob(bestItemID) and self.partner_:getJob() ~= xyd.tables.equipTable:getJob(equips[index]) then
			xyd.models.slot:deleteEquip(now_equips[index], self.partner_:getPartnerID())
			self.quickItem_:equipSingle(bestItemID)

			flag_changed = true
		else
			now_equips[index] = equips[index]
		end
	end

	if flag_changed then
		xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_ON)
		self:updateWindowShow()
	end
end

return QuickFormationPartnerDetailWindow
