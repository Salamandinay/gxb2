local QuickFormationWindow = class("QuickFormationWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local QuickFormationPartner = class("QuickFormationPartner", import("app.components.CopyComponent"))
local SkillIcon = import("app.components.SkillIcon")
local ItemIcon = import("app.components.ItemIcon")
local HeroIcon = import("app.components.HeroIcon")
local PotentialIcon = import("app.components.PotentialIcon")
local Partner = import("app.models.Partner")
local GroupBuffIcon = import("app.components.GroupBuffIcon")
local GroupBuffIconItem = class("GroupBuffIconItem")

function GroupBuffIconItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupBuffIcon = GroupBuffIcon.new(self.go)

	self.groupBuffIcon:setScale(0.9)

	UIEventListener.Get(self.groupBuffIcon:getGameObject()).onPress = function (go, isPress)
		if isPress then
			local win = xyd.WindowManager.get():getWindow("group_buff_detail_window")

			if win then
				xyd.WindowManager.get():closeWindow("group_buff_detail_window", function ()
					XYDCo.WaitForTime(1, function ()
						local params = {
							buffID = self.info_.buffId,
							type = self.info_.type_,
							contenty = self.info_.contenty,
							group7Num = self.info_.group7Num
						}

						xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
					end, nil)
				end)
			else
				local params = {
					buffID = self.info_.buffId,
					type = self.info_.type_,
					contenty = self.info_.contenty,
					group7Num = self.info_.group7Num
				}

				xyd.WindowManager.get():openWindow("group_buff_detail_window", params)
			end
		else
			xyd.WindowManager.get():closeWindow("group_buff_detail_window")
		end
	end
end

function GroupBuffIconItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.groupBuffIcon then
		self.groupBuffIcon = GroupBuffIcon.new(self.go, self.parent.buffRenderPanel)
	end

	self.groupBuffIcon:setInfo(info.buffId, info.isAct, info.type_)

	self.info_ = info

	self.go:SetActive(true)
end

function GroupBuffIconItem:getGameObject()
	return self.go
end

function QuickFormationPartner:ctor(go, parent, pos)
	self.parent_ = parent
	self.pos_ = pos
	self.skillItemList_ = {}
	self.equipPlusEffects = {}

	QuickFormationPartner.super.ctor(self, go)
end

function QuickFormationPartner:initUI()
	self:getUIComponent()
	self:register()
	self:layout()
end

function QuickFormationPartner:register()
	UIEventListener.Get(self.suitSkillIcon_.gameObject).onClick = handler(self, self.onClickSuitIcon)

	for i = 1, 4 do
		UIEventListener.Get(self["emptyEquip" .. i]).onClick = handler(self, function ()
			if self:checkRed() then
				return
			end

			self:onclickEmptyEquip(i)
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		end)
	end

	UIEventListener.Get(self.emptyEquip5).onClick = function ()
		xyd.alert(xyd.AlertType.TIPS, __("QUICK_FORMATION_TEXT01"))
	end

	UIEventListener.Get(self.emptyEquip6).onClick = handler(self, function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)
		self:onclickEmptySoul()
	end)

	UIEventListener.Get(self.heroItem_).onClick = function ()
		self.parent_:seletFormation()
	end

	UIEventListener.Get(self.clearBtn_).onClick = function ()
		if self.partner_ then
			self:clearPartnerInfo()
			self.parent_:clearIndexPartner(self.pos_)
		end
	end
end

function QuickFormationPartner:layout()
	if self.pos_ <= 2 then
		self.labelPos_.text = __("HEAD_POS1") .. " " .. self.pos_
	else
		self.labelPos_.text = __("BACK_POS1") .. " " .. self.pos_ - 2
		self.labelPos_.color = Color.New2(2075807999)
	end
end

function QuickFormationPartner:getUIComponent()
	local goTrans = self.go.transform
	self.labelPos_ = goTrans:ComponentByName("labelPos", typeof(UILabel))
	self.heroIconRoot_ = goTrans:NodeByName("heroItem/heroIcon").gameObject
	self.heroItem_ = goTrans:NodeByName("heroItem").gameObject
	self.redPoint_ = goTrans:NodeByName("heroItem/redPoint").gameObject
	self.clearBtn_ = goTrans:NodeByName("clearBtn").gameObject

	for i = 1, 6 do
		local equip = goTrans:NodeByName("equipGroup/equip" .. i).gameObject
		local iconEquipContainer = equip:NodeByName("iconEquip" .. i).gameObject
		self["emptyEquip" .. i] = equip:NodeByName("emptyEquip" .. i).gameObject
		self["effectGroup" .. i] = equip:NodeByName("effectGroup").gameObject
		local iconEquip = ItemIcon.new(iconEquipContainer)

		iconEquip:setDragScrollView(self.parent_.scrollView)

		self["iconEquip" .. i] = iconEquip

		iconEquip:setScale(0.64)

		if i == 5 then
			self.equipLock = equip:NodeByName("equipLock").gameObject
		end
	end

	self.suitGroup_ = goTrans:NodeByName("equipGroup/suitGroup").gameObject
	self.suitSkillIcon_ = goTrans:ComponentByName("equipGroup/suitGroup/skillIcon", typeof(UISprite))
	self.suitSkillRed_ = goTrans:NodeByName("equipGroup/suitGroup/redIcon").gameObject
	self.suitSkillEffectRoot_ = goTrans:NodeByName("equipGroup/suitGroup/effectGroup").gameObject
	local potentialGroup = goTrans:NodeByName("potentialGroup")

	for i = 1, 5 do
		self["skillGroup" .. i] = potentialGroup:NodeByName("potential_icon" .. i).gameObject
	end
end

function QuickFormationPartner:clearPartnerInfo()
	self.partner_ = nil

	self.redPoint_:SetActive(false)

	self.redState_ = false

	if self.heroIcon then
		self.heroIcon:SetActive(false)
	end

	for i = 1, 6 do
		self["iconEquip" .. i]:SetActive(false)
		self:applyPlusEffect(self["effectGroup" .. i], false, i)
	end

	for i = 1, 5 do
		self:updateSuitStatus()

		if self.skillItemList_[i] then
			self.skillItemList_[i]:setInfo(-1, {
				is_active = false,
				is_mask = true,
				is_lock = true
			})
		else
			local iconItem = PotentialIcon.new(self["skillGroup" .. i])

			iconItem:setTouchListener(function ()
				if not self.partner_ or not self.partner_.tableID then
					return
				end

				if self.is_guest then
					return
				end

				local cur_star_ = self.partner_:getStar()

				if cur_star_ + 2 <= i + 10 then
					xyd.showToast(__("POTENTIALITY_LOCK", i))

					return
				elseif cur_star_ + 1 == i + 10 then
					xyd.showToast(__("QUICK_FORMATION_TEXT01"))
				else
					xyd.WindowManager.get():openWindow("potentiality_switch_window", {
						partner = self.partner_,
						quickItem = self
					})
				end
			end)
			iconItem:setDragScrollView(self.parent_.scrollView)

			self.skillItemList_[i] = iconItem

			self.skillItemList_[i]:setInfo(-1, {
				is_active = false,
				is_mask = true,
				is_lock = true
			})
		end
	end
end

function QuickFormationPartner:checkRed()
	if self.redState_ then
		xyd.alertTips(__("QUICK_FORMATION_TEXT23"))

		return true
	end
end

function QuickFormationPartner:updatePotentials(awake_index, index)
	self.partner_.potentials[awake_index] = index
	self.cur_star_ = self.partner_:getStar()
	self.skill_list_ = self.partner_:getPotentialByOrder()
	self.active_status = self.partner_:getActiveIndex()

	self:updatePotentialSkill()
end

function QuickFormationPartner:applyPlusEffect(obj, show, key)
	local parent = obj

	if show then
		local effect = self.equipPlusEffects[key]

		if not effect then
			effect = xyd.Spine.new(parent.gameObject)

			effect:setInfo("jiahao", function ()
				effect:SetLocalScale(0.6464, 0.608, 1)
				effect:SetLocalPosition(15, -15, 0)
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

function QuickFormationPartner:setInfo(info, pet)
	if not info then
		self:clearPartnerInfo()
		self:updateSuitStatus()
	else
		self.partner_ = info
		self.partner_.noClickSelected = true
		self.pet = pet

		if not self.heroIcon then
			self.heroIcon = HeroIcon.new(self.heroIconRoot_)
		end

		self.heroIcon:setInfo(self.partner_, self.pet)
		self.heroIcon:setCallBack(function ()
			self:showPartnerDetail()
		end)
		self.heroIcon:setDargScrollView(self.parent_.scrollView)
		self.heroIcon:SetActive(true)

		self.cur_star_ = self.partner_:getStar()
		self.skill_list_ = self.partner_:getPotentialByOrder()
		self.active_status = self.partner_:getActiveIndex()

		self:updatePotentialSkill()
		self:updateEquips()
	end
end

function QuickFormationPartner:showPartnerDetail()
	if self:checkRed() then
		return
	end

	local params = {
		isLongTouch = true,
		unable_move = true,
		sort_key = "0_0",
		not_open_slot = true,
		partner_id = self.partner_:getPartnerID(),
		table_id = self.partner_:getTableID(),
		skin_id = self.partner_:getSkinID(),
		partner = self.partner_,
		quickItem = self,
		equipsTable = self.parent_:getBpEquipsInfo()
	}

	xyd.WindowManager.get():openWindow("quick_formation_partner_detail_window", params)
end

function QuickFormationPartner:updateEquips()
	__TRACE("========== updateEquips =========")

	local equips = self.partner_:getEquipment()

	for key in pairs(equips) do
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
						self:onclickTreasure(itemID)
					end,
					switch_func = function ()
						self:onclickTreasureExchange(itemID)
					end
				})
				self["iconEquip" .. key]:SetActive(true)
				self["iconEquip" .. key]:setLockLowerRight(self.partner_.select_treasure ~= 1)
				self:applyLockEffect(self.equipLock, false)
			else
				self["iconEquip" .. key]:SetActive(false)

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

			self:applyPlusEffect(self["effectGroup" .. key], false, key)
			self["iconEquip" .. key]:SetActive(true)
		else
			if self:ifhasBpEquip(key) then
				self:applyPlusEffect(self["effectGroup" .. key], true, key)
			else
				self:applyPlusEffect(self["effectGroup" .. key], false, key)
			end

			self["iconEquip" .. key]:SetActive(false)
		end
	end

	self:updateSuitStatus()
end

function QuickFormationPartner:ifhasBpEquip(key)
	local equips = self.parent_:getBpEquipsInfo()[key]

	if not equips or #equips <= 0 then
		return false
	end

	for _, equip in pairs(equips) do
		if not equip.partner_id then
			return true
		end
	end

	return false
end

function QuickFormationPartner:onclickEquip(itemID, key)
	if self:checkRed() then
		return
	end

	local equips = self.parent_:getBpEquipsInfo()[key]
	local itemTable = xyd.tables.itemTable
	local params = {
		btnLayout = 4,
		equipedOn = self.partner_:getInfo(),
		equipedPartner = self.partner_,
		itemID = itemID,
		equips = equips,
		rightLabel = __("REPLACE"),
		rightColor = xyd.ButtonBgColorType.blue_btn_65_65,
		rightCallback = function ()
			xyd.WindowManager:get():openWindow("choose_equip_window", {
				equips = equips,
				now_equip = itemID,
				equipedOn = self.partner_:getInfo(),
				equipedPartnerID = self.partner_:getPartnerID(),
				equipedPartner = self.partner_,
				quickItem = self
			})
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end,
		leftLabel = __("REMOVE"),
		leftColor = xyd.ButtonBgColorType.red_btn_65_65,
		leftCallback = function ()
			self:unEquipSingle(itemID)
			xyd.WindowManager:get():closeWindow("item_tips_window")
		end
	}

	xyd.WindowManager:get():openWindow("item_tips_window", params)
end

function QuickFormationPartner:onclickEmptySoul()
	self:onclickEmptyEquip(6)
end

function QuickFormationPartner:onclickEmptyEquip(key)
	if not self.partner_ then
		return
	end

	if self:checkRed() then
		return
	end

	xyd.WindowManager:get():openWindow("choose_equip_window", {
		equips = self.parent_:getBpEquipsInfo()[key],
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_,
		quickItem = self
	})
end

function QuickFormationPartner:applyLockEffect(obj, show)
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

function QuickFormationPartner:updateSuitStatus()
	local skillIndex = self.partner_ and self.partner_.skill_index or 0
	local tableId = self.partner_ and self.partner_.tableID or 0
	local job = nil

	if not self.partner_ then
		self.hasSuit_ = false
	else
		job = xyd.tables.partnerTable:getJob(tableId)
		self.hasSuit_ = self:checkSuit(job)
	end

	if skillIndex and skillIndex > 0 and self.hasSuit_ then
		local skillID = tonumber(self:getSuitSkill(skillIndex))

		if skillID and skillID > 0 then
			self.suitGroup_:SetActive(true)

			local iconName = xyd.tables.skillTable:getSkillIcon(skillID)

			xyd.setUISpriteAsync(self.suitSkillIcon_, nil, iconName)
			self:initSuitEffect(job)
			self.suitSkillRed_:SetActive(false)
		end
	elseif self.hasSuit_ then
		self.suitSkillRed_:SetActive(true)
		self.suitGroup_:SetActive(true)

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

function QuickFormationPartner:getSuitSkill(skillIndex)
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

function QuickFormationPartner:initSuitEffect(job)
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

function QuickFormationPartner:checkSuit(job)
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

function QuickFormationPartner:onClickSuitIcon()
	if self:checkRed() then
		return
	end

	local skillIndex = self.partner_.skill_index
	local skill_list = self:getSuitSkill()

	if skillIndex and skillIndex > 0 then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			skill_list = skill_list,
			skillIndex = skillIndex,
			quickItem = self,
			partner = self.partner_
		})
	elseif self.hasSuit_ then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			partner_id = self.partner_:getPartnerID(),
			partner = self.partner_,
			skill_list = skill_list,
			quickItem = self
		})
	end
end

function QuickFormationPartner:updatePotentialSkill()
	local skills = self.skill_list_
	local active_status = self.active_status
	local star = self.cur_star_

	for i = 1, 5 do
		local iconItem = nil

		if not self.skillItemList_[i] then
			iconItem = PotentialIcon.new(self["skillGroup" .. i])

			iconItem:setTouchListener(function ()
				if not self.partner_ or not self.partner_.tableID then
					return
				end

				if self.is_guest then
					return
				end

				local cur_star_ = self.partner_:getStar()

				if cur_star_ + 2 <= i + 10 then
					xyd.showToast(__("POTENTIALITY_LOCK", i))

					return
				elseif cur_star_ + 1 == i + 10 then
					xyd.showToast(__("QUICK_FORMATION_TEXT01"))
				else
					xyd.WindowManager.get():openWindow("potentiality_switch_window", {
						partner = self.partner_,
						quickItem = self,
						callback = function (awake_index, index)
							self.partner_.potentials[awake_index] = index
							self.cur_star_ = self.partner_:getStar()
							self.skill_list_ = self.partner_:getPotentialByOrder()
							self.active_status = self.partner_:getActiveIndex()

							self:updatePotentialSkill()
						end
					})
				end
			end)
			iconItem:setDragScrollView(self.parent_.scrollView)

			self.skillItemList_[i] = iconItem
		else
			iconItem = self.skillItemList_[i]
		end

		local params = {}
		local id = -1
		local ind = star - 9

		if i >= ind then
			params.is_lock = true
			params.is_mask = true
		elseif active_status[i] and active_status[i] ~= 0 then
			id = skills[i][active_status[i]]
			params.show_effect = false
		else
			params.show_effect = true
		end

		iconItem:setInfo(id, params)
	end
end

function QuickFormationPartner:equipSingle(itemID)
	local pos = xyd.tables.equipTable:getPos(itemID)
	local equips = self.partner_:getEquipment()
	local oldEquip = equips[pos]
	local now_equips = {}

	for k, v in ipairs(equips) do
		now_equips[k] = v
	end

	now_equips[pos] = itemID

	self.parent_:addEquip(itemID, self.partner_:getPartnerID(), 1)
	self.parent_:deleteEquip(oldEquip, self.partner_:getPartnerID())
	self.partner_:setEquip(now_equips)
	self.parent_:updateCanEquipList()
	self:updateEquips()
end

function QuickFormationPartner:unEquipSingle(itemID)
	local now_equips = {}
	local equips = self.partner_:getEquipment()

	for k, v in ipairs(equips) do
		now_equips[k] = v
	end

	for key in pairs(now_equips) do
		if now_equips[key] == itemID then
			now_equips[key] = 0
		end
	end

	self.parent_:deleteEquip(itemID, self.partner_:getPartnerID())
	self.partner_:setEquip(now_equips)
	xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_OFF)
	self.parent_:updateCanEquipList()
	self:updateEquips()
end

function QuickFormationPartner:equipRob(itemID, fromPartnerId, targetPartnerId)
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(xyd.tables.itemTable:getType(itemID))]
	local equips = self.partner_:getEquipment()
	local oldEquip = equips[pos]

	if oldEquip and oldEquip > 0 then
		self.parent_:deleteEquip(oldEquip, targetPartnerId)
	end

	self.parent_:deleteEquip(itemID, fromPartnerId)
	self.parent_:addEquip(itemID, targetPartnerId, 1)
	self.parent_:deletePartnerEquip(fromPartnerId, pos)

	local now_equips = {}

	for k, v in ipairs(equips) do
		now_equips[k] = v
	end

	now_equips[pos] = itemID

	self.partner_:setEquip(now_equips)
	self.parent_:updateCanEquipList()
	self:updateEquips()
end

function QuickFormationPartner:onclickTreasure(itemID)
	if self:checkRed() then
		return
	end

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

function QuickFormationPartner:onclickTreasureExchange(itemID)
	if self:checkRed() then
		return
	end

	xyd.WindowManager:get():openWindow("treasure_select_window", {
		type = 1,
		itemID = itemID,
		equipedPartnerID = self.partner_:getPartnerID(),
		equipedPartner = self.partner_,
		quickItem = self
	})
end

function QuickFormationPartner:setRed(redStatus)
	if not self.partner_ then
		return
	end

	self.redState_ = redStatus

	self.redPoint_:SetActive(redStatus)
end

function QuickFormationWindow:ctor(name, params)
	QuickFormationWindow.super.ctor(self, name, params)

	self.navList_ = {}
	self.selectTeam = 1
	self.partnerList_ = {}
	self.partnerInfos_ = {}
	self.partnerInfoTmp_ = {}
	self.buffIconList_ = {}
	self.redStatus_ = {}
	self.model_ = xyd.models.quickFormation

	self.model_:updatePartnerInfo()

	self.pet = self.model_:getPet(self.selectTeam)

	self.model_:updateRedStatus()

	self.redStatusPos_ = self.model_:getHeroRed(self.selectTeam) or {}
end

function QuickFormationWindow:initWindow()
	self:getUIComponent()
	self:initTop()
	self:updateNav()
	self:updateTeamName()
	self:updateAddPos()
	self:updateRedStatus()
	self:updatePartnerInfos()
	self:updatePetInfo()
	self:register()
end

function QuickFormationWindow:getUIComponent()
	self.topNode_ = self.window_:NodeByName("top").gameObject
	self.navGroup_ = self.window_:NodeByName("navGroup").gameObject
	self.gridNav_ = self.navGroup_:ComponentByName("gridNav", typeof(UIGrid))
	self.addBtn_ = self.navGroup_:NodeByName("addBtn").gameObject
	self.helpBtn_ = self.navGroup_:NodeByName("helpBtn").gameObject
	self.navItem_ = self.navGroup_:NodeByName("navItem").gameObject
	local groupContent = self.window_:NodeByName("groupContent")
	self.powerLabel_ = groupContent:ComponentByName("force_num_label", typeof(UILabel))
	self.groupBuffIconRoot_1 = groupContent:NodeByName("groupBuffIcon").gameObject
	self.groupBuffIcon_ = groupContent:ComponentByName("groupBuffIcon/e:image", typeof(UISprite))
	self.groupBuffIconRoot_2 = groupContent:NodeByName("groupBuffIcon2").gameObject
	self.groupBuffIcon2_ = groupContent:ComponentByName("groupBuffIcon2/e:image", typeof(UISprite))
	self.petGroup_ = groupContent:NodeByName("groupPetIcon").gameObject
	self.petIcon_ = groupContent:ComponentByName("groupPetIcon/petIcon", typeof(UISprite))
	self.petLevel_ = groupContent:ComponentByName("groupPetIcon/petLvNum", typeof(UILabel))
	self.btnFormation_ = groupContent:NodeByName("btnFormation").gameObject
	self.btnFormationLabel_ = groupContent:ComponentByName("btnFormation/labelFormation", typeof(UILabel))
	self.scrollView = groupContent:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid = groupContent:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.partnerInfoCard = groupContent:NodeByName("partnerInfoCard").gameObject
	self.btnBack = groupContent:NodeByName("btnBack").gameObject
	self.btnBackLabel = groupContent:ComponentByName("btnBack/label", typeof(UILabel))
	self.btnSure = groupContent:NodeByName("btnSure").gameObject
	self.btnSureLabel = groupContent:ComponentByName("btnSure/label", typeof(UILabel))
	self.btnFormationLabel_.text = __("QUICK_FORMATION_TEXT03")
	self.btnBackLabel.text = __("ACTIVITY_VAMPIRE_GAMBLE_RETURN")
	self.btnSureLabel.text = __("SAVE")
end

function QuickFormationWindow:updatePower()
	local power = 0
	local partners = self.partnerInfos_[self.selectTeam]

	for pos, partnerInfo in pairs(partners) do
		power = power + partnerInfo:getPower()
	end

	self.powerLabel_.text = power
end

function QuickFormationWindow:seletFormation()
	xyd.WindowManager.get():openWindow("battle_formation_window", {
		battleType = xyd.BattleType.QUICK_TEAM_SET,
		formation = self.partnerInfos_[self.selectTeam],
		pet = self.pet
	})
end

function QuickFormationWindow:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "QUICK_FORMATION_TEXT18"
		})
	end

	UIEventListener.Get(self.petGroup_).onClick = function ()
		if self.pet and self.pet > 0 then
			xyd.WindowManager.get():openWindow("choose_pet_window", {
				type = xyd.PetFormationType.Battle1v1,
				select = {
					self.pet,
					0,
					0,
					0
				}
			})
		else
			self:seletFormation()
		end
	end

	UIEventListener.Get(self.btnFormation_).onClick = function ()
		self:seletFormation()
	end

	UIEventListener.Get(self.btnBack).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnSure).onClick = handler(self, self.saveTeamInfo)

	UIEventListener.Get(self.addBtn_).onClick = function ()
		local teamNum = self.model_:getTeamNum() or 1
		local costList = xyd.split(xyd.tables.miscTable:getVal("team_preset_cost"), "|", true)
		local cost = nil

		if teamNum == 3 then
			cost = costList[1]
		elseif teamNum == 4 then
			cost = costList[2]
		end

		if xyd.models.backpack:getCrystal() < cost then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

			return
		end

		xyd.alertYesNo(__("QUICK_FORMATION_TEXT13", cost), function (yes_no)
			if yes_no then
				local msg = messages_pb.open_formation_slot_req()

				xyd.Backend.get():request(xyd.mid.OPEN_FORMATION_SLOT, msg)
			end
		end)
	end

	self.eventProxy_:addEventListener(xyd.event.SET_QUICK_TEAM, handler(self, self.onSetTeam))
	self.eventProxy_:addEventListener(xyd.event.OPEN_FORMATION_SLOT, handler(self, self.onOpenSlot))
end

function QuickFormationWindow:updateAddPos()
	local teamNum = self.model_:getTeamNum() or 1

	self.addBtn_.transform:X(-318 + teamNum * 140)

	if teamNum >= 5 then
		self.addBtn_:SetActive(false)
	end
end

function QuickFormationWindow:initTop()
	local function callback()
		self:onClickCloseButton()
	end

	self.windowTop = WindowTop.new(self.topNode_, self.name_, 5, nil, callback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function QuickFormationWindow:updateNav()
	local teamNum = self.model_:getTeamNum()

	for i = 1, teamNum do
		if not self.navList_[i] then
			local newItemRoot = NGUITools.AddChild(self.gridNav_.gameObject, self.navItem_)

			newItemRoot:SetActive(true)

			UIEventListener.Get(newItemRoot).onClick = function ()
				self:onClickNav(i)
			end

			UIEventListener.Get(newItemRoot).onLongPress = function ()
				print("--------------长按测试------------")
				xyd.WindowManager.get():openWindow("qucik_formation_edit_name_window", {
					id = i
				})
			end

			local labelNav = newItemRoot:ComponentByName("nameLabel", typeof(UILabel))
			local selectImg = newItemRoot:NodeByName("selectImg").gameObject
			local redPoint = newItemRoot:NodeByName("redPoint").gameObject
			self.navList_[i] = {
				label = labelNav,
				selectImg = selectImg,
				redPoint = redPoint
			}
		end

		if i == self.selectTeam then
			self.navList_[i].selectImg:SetActive(true)

			self.navList_[i].label.color = Color.New2(4278124287.0)
			self.navList_[i].label.effectColor = Color.New2(1030530815)
		else
			self.navList_[i].selectImg:SetActive(false)

			self.navList_[i].label.color = Color.New2(1348707327)
			self.navList_[i].label.effectColor = Color.New2(4294967295.0)
		end
	end

	self.gridNav_:Reposition()
end

function QuickFormationWindow:updateTeamName()
	local teamNum = self.model_:getTeamNum()

	for i = 1, teamNum do
		self.navList_[i].label.text = self.model_:getTeamName(i)
	end
end

function QuickFormationWindow:onClickNav(index)
	local function updateFunction()
		self.selectTeam = index
		self.pet = self.model_:getPet(self.selectTeam) or 0
		self.bpEquips = nil
		self.equipsOfPartner = nil
		self.partnerInfos_[self.selectTeam] = nil
		self.partnerInfoTmp_[self.selectTeam] = nil
		self.redStatusPos_ = xyd.models.quickFormation:getHeroRed(self.selectTeam)

		self:updatePetInfo()
		self:updateNav()
		self:updatePartnerInfos()
	end

	if self.selectTeam ~= index then
		if self:checkHasChange() then
			local timeStamp = xyd.db.misc:getValue("quick_formation_change_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "quick_formation_change",
					callback = function ()
						self:saveTeamInfo()
						updateFunction()
					end,
					closeCallback = updateFunction,
					text = __("QUICK_FORMATION_TEXT16")
				})
			else
				updateFunction()
			end
		else
			updateFunction()
		end
	end
end

function QuickFormationWindow:checkHasChange()
	if self.pet ~= self.model_:getPet(self.selectTeam) then
		return true
	end

	local partners = self.model_:getPartnerList(self.selectTeam)
	local partner_info = self.partnerInfos_[self.selectTeam] or {}
	local partnerNum = 0

	for i = 1, 6 do
		if partner_info[i] then
			partnerNum = partnerNum + 1
		end
	end

	if partnerNum <= 0 then
		return false
	end

	for i = 1, 6 do
		if partners[i] and not partner_info[i] or not partners[i] and partner_info[i] then
			return true
		end

		if partners[i] and partner_info[i] then
			if partners[i]:getPartnerID() ~= partner_info[i]:getPartnerID() then
				return true
			end

			local equips = partners[i]:getEquipment()
			local equips2 = partner_info[i]:getEquipment()

			for j = 1, 6 do
				if equips[j] and equips[j] ~= equips2[j] or not equips[j] and equips2[j] and equips2[j] ~= 0 then
					return true
				end
			end

			local potential = partners[i]:getPotential()
			local potential2 = partner_info[i]:getPotential()

			for j = 1, 5 do
				if potential[j] and potential[j] ~= potential2[j] or not potential[j] and potential2[j] and potential2[j] ~= 0 then
					return true
				end
			end
		end
	end

	return false
end

function QuickFormationWindow:clearIndexPartner(pos)
	if self.partnerInfos_[self.selectTeam] then
		self.partnerInfos_[self.selectTeam][pos] = nil
	end

	if self.partnerInfoTmp_[self.selectTeam] then
		self.partnerInfoTmp_[self.selectTeam][pos] = nil
	end

	self.bpEquips = nil

	self:updateCanEquipList()
	self:updateGroupBuff()
end

function QuickFormationWindow:setPartnerList(partnerParams, pet)
	self.pet = pet
	self.partnerInfos_[self.selectTeam] = {}
	self.partnerInfoTmp_[self.selectTeam] = {}
	self.redStatus_[self.selectTeam] = 0
	self.redStatusPos_ = {}
	self.bpEquips = nil
	self.equipsOfPartner = nil

	for _, info in ipairs(partnerParams) do
		local pos = info.pos
		local partnerID = info.partner_id
		local partnerInfo = xyd.models.slot:getPartner(partnerID)
		local np = Partner.new()

		np:populate(partnerInfo:getInfo())

		np.equipments = {}
		np.potentials = {}
		local potentials = partnerInfo:getPotential()
		local equips = partnerInfo:getEquipment()

		for i = 1, 7 do
			if equips[i] and equips[i] > 0 then
				np.equipments[i] = equips[i]
			else
				np.equipments[i] = 0
			end
		end

		for i = 1, 5 do
			if potentials[i] and potentials[i] > 0 then
				np.potentials[i] = potentials[i]
			else
				np.potentials[i] = 0
			end
		end

		self.partnerInfos_[self.selectTeam][pos] = np
		self.partnerInfoTmp_[self.selectTeam][partnerID] = np
	end

	self:updatePartnerInfos()
	self:updatePetInfo()
end

function QuickFormationWindow:updatePartnerInfos()
	if not self.partnerInfos_[self.selectTeam] then
		self.partnerInfos_[self.selectTeam] = {}
		self.partnerInfoTmp_[self.selectTeam] = {}
		local partners = self.model_:getPartnerList(self.selectTeam)

		for pos, partnerInfo in pairs(partners) do
			local np = Partner.new()

			np:populate(partnerInfo:getInfo())

			np.equipments = {}
			np.potentials = {}
			local potentials = partnerInfo:getPotential()
			local equips = partnerInfo:getEquipment()

			for i = 1, 7 do
				if equips[i] and equips[i] > 0 then
					np.equipments[i] = equips[i]
				else
					np.equipments[i] = 0
				end
			end

			for i = 1, 5 do
				if potentials[i] and potentials[i] > 0 then
					np.potentials[i] = potentials[i]
				else
					np.potentials[i] = 0
				end
			end

			np.select_treasure = partnerInfo.select_treasure
			self.partnerInfos_[self.selectTeam][pos] = np
			self.partnerInfoTmp_[self.selectTeam][np:getPartnerID()] = np
		end

		self:updateCanEquipList()
	else
		self:updateCanEquipList()
	end

	for i = 1, 6 do
		if not self.partnerList_[i] then
			local newRoot = NGUITools.AddChild(self.grid.gameObject, self.partnerInfoCard)

			newRoot:SetActive(true)

			self.partnerList_[i] = QuickFormationPartner.new(newRoot, self, i)
		end

		if self.partnerInfos_[self.selectTeam][i] then
			self.partnerList_[i]:setInfo(self.partnerInfos_[self.selectTeam][i], self.pet)
		else
			self.partnerList_[i]:setInfo()
		end

		self.partnerList_[i]:setRed(self.redStatusPos_[i] == 1)
	end

	self.grid:Reposition()
	self.scrollView:ResetPosition()
	self:updateGroupBuff()
	self:updatePower()

	if self.redStatus_[self.selectTeam] == 1 then
		xyd.alertTips(__("QUICK_FORMATION_TEXT11"))
	end
end

function QuickFormationWindow:updateGroupBuff()
	local groupNum = {}
	local tNum = 0
	local buffDataList = {}

	for i = 1, 6 do
		local partnerInfo = self.partnerInfos_[self.selectTeam][i]

		if partnerInfo then
			local group = partnerInfo:getGroup()

			if not groupNum[group] then
				groupNum[group] = 0
			end

			groupNum[group] = groupNum[group] + 1
			tNum = tNum + 1
		end
	end

	for i = 1, xyd.GROUP_NUM do
		if not groupNum[i] then
			groupNum[i] = 0
		end
	end

	local showBuffIds = xyd.tables.groupBuffTable:getBuffIds(groupNum)

	for index, info in ipairs(showBuffIds) do
		buffDataList[index] = {
			isAct = true,
			buffId = tonumber(info.id),
			type = xyd.GroupBuffIconType.GROUP_BUFF,
			group7Num = info.group7Num or 0
		}
	end

	for i = 1, 2 do
		if not self.buffIconList_[i] then
			self.buffIconList_[i] = GroupBuffIconItem.new(self["groupBuffIconRoot_" .. i])
		end

		self.buffIconList_[i]:update(nil, buffDataList[i])
	end
end

function QuickFormationWindow:updateCanEquipList()
	local bp = xyd.models.backpack
	local itemTable = xyd.tables.itemTable

	if not self.bpEquips then
		self.bpEquips = {}
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
			local itemNum = tonumber(datas[i].item_num)
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

		local equipsOfPartners = self:getEquipsOfPartners()

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

		local partnersList = self.partnerInfos_[self.selectTeam] or {}

		for i = 1, 6 do
			local partnerInfo = partnersList[i]

			if partnerInfo then
				local partnerID = partnerInfo:getPartnerID()
				local backpackInfo = xyd.models.slot:getPartner(partnerID)

				if partnerInfo then
					local equips = partnerInfo.equipments
					local back_pack_equips = backpackInfo and backpackInfo.equipments or {}

					for i = 1, 6 do
						if back_pack_equips[i] and back_pack_equips[i] > 0 and i ~= 5 then
							self:deleteEquip(back_pack_equips[i], partnerID)
						end

						if equips[i] and equips[i] > 0 and i ~= 5 then
							self:addEquip(equips[i], partnerID, -1)
						end
					end
				end
			end
		end
	end
end

function QuickFormationWindow:getEquipsOfPartners()
	if not self.equipsOfPartner then
		local partnersList = self.partnerInfos_[self.selectTeam] or {}
		local partners = xyd.models.slot:getPartners()
		local equipsOfPartner = {}

		for id in pairs(partners) do
			local partnerInfo = nil

			for _, Info in pairs(partnersList) do
				if Info:getPartnerID() == id then
					partnerInfo = Info

					break
				end
			end

			if not partnerInfo then
				for key, equip in pairs(partners[id].equipments) do
					if equip then
						if not equipsOfPartner[equip] then
							equipsOfPartner[equip] = {}
						end

						table.insert(equipsOfPartner[equip], partners[id].partnerID)
					end
				end
			else
				for key, equip in pairs(partners[id].equipments) do
					local equip_ = partnerInfo.equipments[key]

					if not equipsOfPartner[equip] then
						equipsOfPartner[equip] = {}
					end

					if equip == equip_ then
						table.insert(equipsOfPartner[equip], partners[id].partnerID)
					else
						table.insert(equipsOfPartner[equip], 0)
					end
				end
			end
		end

		self.equipsOfPartner = equipsOfPartner

		return equipsOfPartner
	else
		return self.equipsOfPartner
	end
end

function QuickFormationWindow:getBpEquipsInfo()
	return self.bpEquips
end

function QuickFormationWindow:addEquip(itemId, partnerId, from_backpack)
	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemId))]
	local list = self:getBpEquipsInfo()[pos]

	if from_backpack > 0 then
		for index, info in pairs(list) do
			if info.itemID == itemId and (not info.partner_id or info.partner_id == 0) then
				info.itemNum = info.itemNum - 1

				if info.itemNum <= 0 then
					table.remove(list, index)
				end
			end
		end
	elseif from_backpack < 0 then
		local hasFind = false

		for index, info in pairs(list) do
			if info.itemID == itemId and (not info.partner_id or info.partner_id == 0) then
				info.itemNum = info.itemNum - 1
				hasFind = true

				if info.itemNum <= 0 then
					table.remove(list, index)
				end
			end
		end

		if not hasFind then
			for index, info in pairs(list) do
				if info.itemID == itemId and info.partner_id and info.partner_id >= 0 then
					table.remove(list, index)

					break
				end
			end
		end
	end

	local item = {
		itemNum = 1,
		itemID = itemId,
		partner_id = partnerId
	}

	if not list then
		self.bpEquips[pos] = {}
		list = self.bpEquips[pos]
	end

	table.insert(list, item)
	self:updatePower()
end

function QuickFormationWindow:deleteEquip(itemId, partnerId)
	if not itemId or itemId == 0 then
		return
	end

	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemId))]
	local list = self.bpEquips[pos] or {}
	local hasFind = false

	for index, info in pairs(list) do
		if info.itemID == itemId and info.partner_id and info.partner_id == partnerId then
			table.remove(list, index)

			hasFind = true

			break
		end
	end

	if hasFind then
		local find2 = false

		for index, info in pairs(list) do
			if info.itemID == itemId and (not info.partner_id or info.partner_id == 0) then
				info.itemNum = info.itemNum + 1
				find2 = true

				break
			end
		end

		if not find2 then
			local item = {
				itemNum = 1,
				itemID = itemId
			}
			self.bpEquips[pos] = self.bpEquips[pos] or {}

			table.insert(self.bpEquips[pos], item)
		end
	else
		for index, info in pairs(list) do
			if info.itemID == itemId and (not info.partner_id or info.partner_id == 0) then
				info.itemNum = info.itemNum + 1

				break
			end
		end
	end

	self:updatePower()
end

function QuickFormationWindow:deletePartnerEquip(partner_id, pos)
	local partnerList = self.partnerInfoTmp_[self.selectTeam]
	local np = nil

	if partnerList[partner_id] then
		np = partnerList[partner_id]
	end

	if not np then
		local info = xyd.models.quickFormation:getPartnerInfo(self.selectTeam, partner_id)
		np = Partner.new()

		np:populate(info:getInfo())

		np.equipments = {}
		np.potentials = {}
		local potentials = info:getPotential()
		local equips = info:getEquipment()

		for i = 1, 7 do
			if equips[i] and equips[i] > 0 then
				np.equipments[i] = equips[i]
			else
				np.equipments[i] = 0
			end
		end

		for i = 1, 5 do
			if potentials[i] and potentials[i] > 0 then
				np.potentials[i] = potentials[i]
			else
				np.potentials[i] = 0
			end
		end

		self.partnerInfoTmp_[self.selectTeam][partner_id] = np
	end

	local equips = np:getEquipment()
	equips[pos] = 0

	np:setEquip(equips)

	for i = 1, 6 do
		if self.partnerInfos_[self.selectTeam][i] and self.partnerInfos_[self.selectTeam][i]:getPartnerID() == partner_id then
			self.partnerList_[i]:setInfo(np, self.pet)
		end
	end
end

function QuickFormationWindow:updatePetInfo()
	if self.pet and self.pet > 0 then
		local iconName = xyd.tables.petTable:getAvatar(self.pet)
		local pet = xyd.models.petSlot:getPetByID(self.pet)
		local grade = pet:getGrade()

		xyd.setUISpriteAsync(self.petIcon_, nil, iconName .. grade)
		self.petIcon_.transform:X(0)
		self.petIcon_.transform:Y(0)

		self.petLevel_.text = xyd.models.petSlot:getPetByID(self.pet):getLevel()
	else
		xyd.setUISpriteAsync(self.petIcon_, nil, "icon_pet")
		self.petIcon_.transform:X(2)
		self.petIcon_.transform:Y(2)

		self.petLevel_.text = " "
	end
end

function QuickFormationWindow:onChoosePet(pet_list)
	self.pet = pet_list[1] or 0

	self:updatePetInfo()
	self:updatePartnerInfos()
end

function QuickFormationWindow:getBackPackEquipInfo()
	local bpEquips = {}
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
		local itemNum = tonumber(datas[i].item_num)
		local item = {
			itemID = itemID,
			itemNum = itemNum
		}
		local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]

		if pos ~= nil then
			bpEquips[pos] = bpEquips[pos] or {}

			table.insert(bpEquips[pos], item)
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
				bpEquips[pos] = bpEquips[pos] or {}

				table.insert(bpEquips[pos], item)
			end
		end
	end

	return bpEquips
end

function QuickFormationWindow:saveTeamInfo()
	local index = self.selectTeam
	local pet = self.pet or 0
	local bpEquips = self:getBackPackEquipInfo()
	local partnerInfos = {}

	for pos, partnerInfo in pairs(self.partnerInfos_[self.selectTeam]) do
		local params = {
			partner_id = partnerInfo:getPartnerID(),
			potentials = partnerInfo:getPotential(),
			pos = pos,
			skill_index = partnerInfo:getSkillIndex(),
			equips = {}
		}
		local Equips = partnerInfo:getEquipment()

		for key, itemID in ipairs(Equips) do
			params.equips[key] = {
				id = itemID
			}

			if itemID and itemID > 0 and key ~= 5 and key ~= 7 then
				local partner_id = self:getFromPartnerID(itemID, bpEquips)

				if partner_id < 0 then
					xyd.alertTips(__("QUICK_FORMATION_TEXT22"))

					return
				end

				params.equips[key].from_partner_id = partner_id
			else
				params.equips[key].from_partner_id = 0
			end
		end

		table.insert(partnerInfos, params)
	end

	if #partnerInfos <= 0 then
		xyd.alertTips(__("AT_LEAST_ONE_HERO"))

		return
	end

	xyd.models.quickFormation:setTeamInfo(index, pet, partnerInfos)
end

function QuickFormationWindow:getFromPartnerID(itemID, bpEquips)
	local itemTable = xyd.tables.itemTable
	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(itemTable:getType(itemID))]
	local list = bpEquips[pos] or {}

	for index, itemInfo in ipairs(list) do
		if itemInfo.itemID == itemID and itemInfo.itemNum and tonumber(itemInfo.itemNum) > 0 then
			if not itemInfo.partner_id or itemInfo.partner_id <= 0 then
				itemInfo.itemNum = itemInfo.itemNum - 1

				return 0
			else
				itemInfo.itemNum = itemInfo.itemNum - 1

				return itemInfo.partner_id
			end
		end
	end

	return -1
end

function QuickFormationWindow:onSetTeam()
	xyd.alertTips(__("QUICK_FORMATION_TEXT04"))
	self:updateRedStatus()
end

function QuickFormationWindow:updateRedStatus()
	local teamNum = self.model_:getTeamNum()
	self.redStatus_ = self.model_:getRedStatus()

	for i = 1, teamNum do
		self.navList_[i].redPoint:SetActive(self.redStatus_[i] == 1)
	end
end

function QuickFormationWindow:onOpenSlot()
	self:updateNav()
	self:updateTeamName()
	self:updateAddPos()
end

function QuickFormationWindow:onClickCloseButton()
	if self:checkHasChange() then
		local timeStamp = xyd.db.misc:getValue("quick_formation_change_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "quick_formation_change",
				isNoESC = true,
				callback = function ()
					self:saveTeamInfo()
					self:close()
				end,
				closeCallback = function ()
					self:close()
				end,
				closeFun = function ()
					self.windowTop:setCloseBtnState(true)
				end,
				text = __("QUICK_FORMATION_TEXT16")
			})
		else
			self:close()
		end
	else
		self:close()
	end

	self.windowTop:setCloseBtnState(true)
end

return QuickFormationWindow
