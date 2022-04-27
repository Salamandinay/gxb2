local PartnerInfoWindow = import(".PartnerInfoWindow")
local NewPartnerInfoWindow = class("NewPartnerInfoWindow", PartnerInfoWindow)
local ItemIcon = import("app.components.ItemIcon")

function NewPartnerInfoWindow:ctor(name, params)
	NewPartnerInfoWindow.super.ctor(self, name, params)
end

function NewPartnerInfoWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.groupMain_ = content:NodeByName("groupMain_").gameObject
	self.groupModel = self.groupMain_:NodeByName("groupModel").gameObject
	self.closeBtn = self.groupMain_:NodeByName("closeBtn").gameObject
	self.groupForce = self.groupMain_:NodeByName("groupForce").gameObject
	self.labelBattlePower = self.groupForce:ComponentByName("labelBattlePower", typeof(UILabel))
	self.labelName = self.groupMain_:ComponentByName("labelName", typeof(UILabel))
	self.jobGroup = self.groupMain_:NodeByName("jobGroup").gameObject
	self.jobIcon = self.jobGroup:ComponentByName("jobIcon", typeof(UISprite))
	self.labelJob = self.jobGroup:ComponentByName("labelJob", typeof(UILabel))
	self.labelJobText = self.jobGroup:ComponentByName("labelJobText", typeof(UILabel))
	self.gradeGroup = self.groupMain_:NodeByName("gradeGroup").gameObject
	self.gradeItemGroup = self.gradeGroup:NodeByName("gradeItemGroup").gameObject
	self.gradeItemGrid = self.gradeItemGroup:GetComponent(typeof(UIGrid))
	self.gradeItem = self.gradeGroup:NodeByName("gradeItem").gameObject

	self.gradeItem:SetActive(false)

	self.labelGrade = self.gradeGroup:ComponentByName("labelGrade", typeof(UILabel))
	self.avatarGroup = self.groupMain_:NodeByName("avatarGroup").gameObject
	self.attr = self.groupMain_:NodeByName("attr").gameObject
	self.labelHp = self.attr:ComponentByName("labelHp", typeof(UILabel))
	self.labelAtk = self.attr:ComponentByName("labelAtk", typeof(UILabel))
	self.labelDef = self.attr:ComponentByName("labelDef", typeof(UILabel))
	self.labelSpd = self.attr:ComponentByName("labelSpd", typeof(UILabel))
	self.attrDetail = self.attr:NodeByName("attrDetail").gameObject
	self.groupAllAttrShow = self.attr:NodeByName("groupAllAttrShow").gameObject
	self.groupAllAttr = self.groupAllAttrShow:NodeByName("groupAllAttr").gameObject
	self.groupAllAttrGrid = self.groupAllAttr:GetComponent(typeof(UIGrid))
	self.skill = self.groupMain_:NodeByName("skill").gameObject
	self.skillGroup = self.skill:NodeByName("skillGroup").gameObject
	self.skillGroupGrid = self.skillGroup:GetComponent(typeof(UIGrid))
	self.skillDesc = self.skill:NodeByName("skillDesc").gameObject
	self.groupEquip = content:NodeByName("groupEquip").gameObject

	for i = 1, 6 do
		local equip = self.groupEquip:NodeByName("equip" .. i).gameObject
		local iconEquipContainer = equip:NodeByName("iconEquip" .. i).gameObject
		local iconEquip = ItemIcon.new(iconEquipContainer)
		self["iconEquip" .. i] = iconEquip
		self["emptyEquip" .. i] = equip:NodeByName("emptyEquip" .. i).gameObject

		if i == 5 then
			self.equipLock = equip:NodeByName("equipLock").gameObject
		end
	end

	self.suitGroup_ = self.groupEquip:NodeByName("suitGroup").gameObject
	self.suitSkillIcon_ = self.groupEquip:ComponentByName("suitGroup/skillIcon", typeof(UISprite))
	self.suitSkillEffectRoot_ = self.groupEquip:NodeByName("suitGroup/effectGroup").gameObject
	self.equipLabel_ = self.groupEquip:ComponentByName("equipLabel_", typeof(UILabel))
end

function NewPartnerInfoWindow:registerEvent()
	UIEventListener.Get(self.attrDetail).onSelect = function (go, isSelected)
		self.groupAllAttrShow:SetActive(not self.groupAllAttrShow.activeSelf)
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:onClickCloseButton()
	end

	UIEventListener.Get(self.suitSkillIcon_.gameObject).onClick = handler(self, self.onClickSuitIcon)
end

function NewPartnerInfoWindow:setLayout()
	self:setAvatar()
	self:setText()
	self:setModel()
	self:setGrade()
	self:setSkillItems()

	self.jobIcon.spriteName = "job_icon" .. tostring(self.partner:getJob())

	self:setAttrLabel()
	self.groupAllAttrShow:SetActive(false)
end

function NewPartnerInfoWindow:setText()
	self.labelName.text = self.partner:getName()
	self.labelBattlePower.text = self.partner:getPower()
	self.labelJobText.text = __("PARTNER_INFO_JOB")
	self.labelJob.text = __("JOB_" .. tostring(self.partner:getJob()))
	self.labelGrade.text = __("PARTNER_INFO_GRADE")
	local attrs = self.partner:getBattleAttrs()
	self.labelHp.text = ": " .. tostring(math.floor(attrs.hp))
	self.labelAtk.text = ": " .. tostring(math.floor(attrs.atk))
	self.labelDef.text = ": " .. tostring(math.floor(attrs.arm))
	self.labelSpd.text = ": " .. tostring(math.floor(attrs.spd))
	self.equipLabel_.text = __("EQUIP")
end

function NewPartnerInfoWindow:setEquip()
	local equips = self.partner:getEquipment()

	for key in ipairs(equips) do
		local itemID = equips[key]

		if tonumber(key) == 7 then
			-- Nothing
		elseif tonumber(key) == 5 then
			if itemID > 0 then
				self["iconEquip" .. key]:setInfo({
					itemID = itemID
				})
				self["iconEquip" .. key]:SetActive(true)
			else
				self["iconEquip" .. key]:SetActive(false)
			end
		elseif itemID > 0 then
			local itemEffect = nil

			if tonumber(key) == 6 and xyd.tables.equipTable:getQuality(itemID) >= 5 and xyd.tables.equipTable:getArtifactUpNext(itemID) == 0 then
				itemEffect = "hunqiui"
			end

			self["iconEquip" .. key]:setInfo({
				itemID = itemID,
				effect = itemEffect
			})

			if not itemEffect then
				self["iconEquip" .. key]:setEffectState(false)
			else
				self["iconEquip" .. key]:setEffectState(true)
			end

			self["iconEquip" .. key]:SetActive(true)
		else
			self["iconEquip" .. key]:SetActive(false)
		end
	end

	self:updateSuitStatus()
end

function NewPartnerInfoWindow:updateSuitStatus()
	local skillIndex = self.partner.skill_index
	local tableId = self.partner.tableID
	local job = xyd.tables.partnerTable:getJob(tableId)
	local hasSuit = self:checkSuit(job)

	if skillIndex and skillIndex > 0 and hasSuit then
		local skillID = tonumber(self:getSuitSkill(skillIndex))

		if skillID and skillID > 0 then
			self.suitGroup_:SetActive(true)

			local iconName = xyd.tables.skillTable:getSkillIcon(skillID)

			xyd.setUISpriteAsync(self.suitSkillIcon_, nil, iconName)
			self:initSuitEffect(job)
		end
	elseif hasSuit then
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

function NewPartnerInfoWindow:checkSuit(job)
	local equips = self.partner:getEquipment()
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

function NewPartnerInfoWindow:initSuitEffect(job)
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

function NewPartnerInfoWindow:onClickSuitIcon()
	local skillIndex = self.partner.skill_index
	local skill_list = self:getSuitSkill()

	if skillIndex and skillIndex > 0 then
		xyd.WindowManager.get():openWindow("suit_skill_detail_window", {
			enough = true,
			justShow = true,
			partner_id = self.partner:getPartnerID(),
			skill_list = skill_list,
			skillIndex = skillIndex
		})
	end
end

function NewPartnerInfoWindow:getSuitSkill(skillIndex)
	local equips = self.partner:getEquipment()

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

return NewPartnerInfoWindow
