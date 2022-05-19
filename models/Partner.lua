local xyd = xyd
local Partner = class("Partner", import("app.models.BaseModel"))
local PartnerTable = xyd.tables.partnerTable

function Partner:ctor(...)
	Partner.super.ctor(self, ...)

	self.tableID = 0
	self.star = 0
	self.lev = 0
	self.addHurID = nil
	self.isHeroBook_ = false
	self.showSkin = 1
	self.tmp_treasure_ = nil
	self.showID = nil
	self.love_point = 0
	self.skin_id = 0
	self.isLevingUp = false
end

function Partner:getSkinId()
	if not self.equipments then
		return 0
	end

	if not self.showSkin then
		return 0
	end

	self.skin_id = self.equipments[7] or 0

	return self.skin_id
end

function Partner:isVowed()
	return self.is_vowed > 0
end

function Partner:getLovePoint()
	return self.love_point
end

function Partner:populate(params)
	self.tableID = params.table_id or params.tableID or 0
	self.star = params.star or 0
	self.lev = params.lv or params.lev or params.level or 0
	self.partnerID = params.partner_id or params.partnerID
	self.equipments = {}

	for k, v in ipairs(params.equips or params.equipments or {}) do
		self.equipments[k] = v
	end

	self.grade = params.grade or 0
	self.awake = params.awake or 0
	self.lockFlags = {}

	for _, flag in ipairs(params.flags or params.lockFlags or {}) do
		table.insert(self.lockFlags, flag)
	end

	self.isHeroBook_ = params.isHeroBook or false
	self.showSkin = params.show_skin == nil and 1 or params.show_skin
	self.tmp_treasure_ = params.tmp_treasure
	self.showID = params.show_id
	self.love_point = params.love_point or params.lovePoint or 0
	self.last_love_point_time = params.last_love_point_time or 0
	self.guaji_love_point = params.guaji_love_point or 0
	self.is_vowed = params.is_vowed or 0
	self.wedding_date = params.wedding_date or 0
	self.potentials = params.potentials or {
		0,
		0,
		0
	}
	self.skill_index = params.skill_index or 0
	self.travel = params.travel or 0
	self.potentials_bak = params.potentials_bak
	self.ex_skills = {}

	for _, v in ipairs(params.ex_skills or {}) do
		table.insert(self.ex_skills, v)
	end

	self.star_origin = {}

	for _, v in ipairs(params.star_origin or {}) do
		table.insert(self.star_origin, v)
	end

	self.treasures = xyd.checkCondition(params.treasures and params.treasures[1], params.treasures, {})
	self.select_treasure = params.select_treasure or 1
	self.isCollected_ = self:isCollected()

	self:setSkinID()

	self.isEntrance = params.isEntrance

	if not params.isUpdateAttrs or params.isUpdateAttrs ~= false then
		if not params.noUpdateAttrs then
			self:updateAttrs()
		end
	end
end

function Partner:getSkillIndex()
	return self.skill_index
end

function Partner:getExSkills()
	return self.ex_skills
end

function Partner:getStarOrigin()
	return self.star_origin
end

function Partner:getTotalExLev()
	local result = 0

	if self:getExSkills() ~= nil then
		for k, v in ipairs(self:getExSkills()) do
			result = result + v
		end
	end

	return result
end

function Partner:getIsVoewed()
	return self.is_vowed
end

function Partner:getWeddingDate()
	return self.wedding_date
end

function Partner:updateExSkills(ex_skills)
	self.ex_skills = {}

	for _, v in ipairs(ex_skills or {}) do
		table.insert(self.ex_skills, v)
	end
end

function Partner:updateStarOrigin(s)
	self.star_origin = {}

	for _, v in ipairs(s or {}) do
		table.insert(self.star_origin, v)
	end
end

function Partner:getSpecialType()
	return 0
end

function Partner:isPartnerData()
	return true
end

function Partner:setEquip(equip)
	for k, v in ipairs(equip) do
		self.equipments[k] = v
	end

	self:updateAttrs()
end

function Partner:updateAttrs(params)
	local changed_attr = {}
	local old_attr = self.attrs

	if params then
		for key, _ in pairs(params) do
			if params[key] ~= nil then
				if type(params[key]) and type(params[key]) ~= "table" then
					self[key] = params[key]
				elseif type(params[key]) == "table" and next(params[key]) ~= nil then
					self[key] = params[key]
				end
			end
		end
	end

	self:initStar()

	local isEntrance = false

	if params and params.isEntrance then
		isEntrance = true
	elseif self.isEntrance then
		isEntrance = self.isEntrance
	end

	self.attrs = xyd.models.heroAttr:attr(self, {
		isHeroBook = self.isHeroBook_,
		isEntrance = isEntrance
	})

	if params then
		for key, _ in pairs(self.attrs) do
			local delta = self.attrs[key] - old_attr[key]

			if delta ~= 0 then
				changed_attr[key] = delta
			end
		end
	end

	return changed_attr
end

function Partner:initStar()
	self.star = xyd.tables.partnerTable:getStar(self:getTableID()) + self.awake
end

function Partner:getPartnerID()
	return self.partnerID
end

function Partner:getEquipment()
	return self.equipments
end

function Partner:getGrade()
	return self.grade
end

function Partner:getMaxGrade()
	return xyd.tables.partnerTable:getMaxGrade(self:getTableID())
end

function Partner:getStar()
	return self.star
end

function Partner:getAwake()
	return self.awake
end

function Partner:getLockFlags()
	return self.lockFlags
end

function Partner:getTmpTreasure()
	return self.tmp_treasure_
end

function Partner:getPotential()
	return self.potentials
end

function Partner:getPartnerCard()
	return xyd.tables.partnerPictureTable:getPartnerCard(self:getTableID())
end

function Partner:getPartnerPic()
	return xyd.tables.partnerPictureTable:getPartnerPic(self:getTableID())
end

function Partner:getPartnerPicXY()
	local id = self:getTableID()

	if self.showSkin == 1 and self:getSkinID() > 0 then
		id = self.getSkinID()
	end

	return xyd.tables.partnerPictureTable:getPartnerPicXY(id)
end

function Partner:getPartnerPicScale()
	local id = self:getTableID()

	if self.showSkin == 1 and self:getSkinID() > 0 then
		id = self:getSkinID()
	end

	return xyd.tables.partnerPictureTable:getPartnerPicScale(id)
end

function Partner:getJob()
	return xyd.tables.partnerTable:getJob(self:getTableID())
end

function Partner:getMaxLev(grade, awake)
	local awake_add_limit = xyd.tables.miscTable:getVal("awake_add_level_limit")

	if awake and awake > 0 then
		if self:getStar() < 10 then
			return xyd.tables.partnerTable:getMaxlev(self:getTableID(), grade) + awake_add_limit * awake
		else
			return xyd.tables.miscTable:split2num("hero_break_lv_cap", "value", "|")[awake]
		end
	else
		return xyd.tables.partnerTable:getMaxlev(self:getTableID(), grade)
	end
end

function Partner:getDecompose()
	local treasureItems = {}
	local baseItems = {}
	local equipItems = {}
	local base = xyd.tables.partnerTable:getDeComposeItem(self.tableID)

	for _, data in pairs(base) do
		baseItems[data[1]] = (baseItems[data[1]] or 0) + data[2]
	end

	local i = 6

	while i >= 1 do
		if i ~= 5 and self.equipments[i] > 0 then
			table.insert(equipItems, {
				item_num = 1,
				item_id = self.equipments[i]
			})
		end

		i = i - 1
	end

	for i = 1, self.grade do
		local res = xyd.tables.partnerTable:getGradeUpCost(self.tableID, i)
		local gradeStone = math.floor(res[xyd.ItemID.GRADE_STONE] * xyd.tables.miscTable:getVal("decompose_grade_coin_return_ratio", true))
		baseItems[xyd.ItemID.GRADE_STONE] = (baseItems[xyd.ItemID.GRADE_STONE] or 0) + gradeStone
	end

	if self.star < 10 then
		for i = 0, self.awake - 1 do
			local res = xyd.tables.partnerTable:getAwakeItemCost(self.tableID, i)
			local gradeStone = math.floor(res[2] * xyd.tables.miscTable:getVal("decompose_grade_coin_return_ratio", true))
			baseItems[xyd.ItemID.GRADE_STONE] = (baseItems[xyd.ItemID.GRADE_STONE] or 0) + gradeStone
		end
	end

	if self.star >= 15 then
		local flag = false

		for i = 1, #self.star_origin do
			if self.star_origin[i] > 0 then
				flag = true

				break
			end
		end

		if flag then
			local partnerTableID = self.tableID
			local listTableID = xyd.tables.partnerTable:getStarOrigin(partnerTableID)
			local startIDs = xyd.tables.starOriginListTable:getStarIDs(listTableID)

			for i = 1, #startIDs do
				local beginID = startIDs[i]
				local lev = self.star_origin[i]

				if lev and lev > 0 then
					local starOriginTableID = xyd.tables.starOriginTable:getIdByBeginIDAndLev(beginID, lev)
					local totalCost = xyd.tables.starOriginTable:getCostTotal(starOriginTableID)

					for _, cost in ipairs(totalCost) do
						baseItems[cost[1]] = (baseItems[cost[1]] or 0) + cost[2]
					end
				end
			end
		end
	end

	local exp = math.floor(xyd.tables.miscTable:getVal("decompose_partner_exp_return_ratio", true) * xyd.tables.expPartnerTable:getAllExp(self.lev))
	baseItems[xyd.ItemID.PARTNER_EXP] = (baseItems[xyd.ItemID.PARTNER_EXP] or 0) + exp

	if self.equipments[5] > 0 then
		local res = xyd.tables.equipTable:getTreasureCost(self.equipments[5])
		local baseMagicDust = xyd.tables.miscTable:split2num("decompose_treasure_return_base", "value", "#")

		for i in pairs(res) do
			local v = res[i]
			local num = math.ceil(xyd.tables.miscTable:getVal("decompose_treasure_return_ratio", true) * v[2])

			if v[1] == baseMagicDust[1] then
				num = num + math.ceil(xyd.tables.miscTable:getVal("decompose_treasure_return_ratio", true) * baseMagicDust[2])
			end

			table.insert(treasureItems, {
				item_id = v[1],
				item_num = num
			})
		end
	end

	return {
		baseItems,
		treasureItems,
		equipItems
	}
end

function Partner:getGradeLevNeed()
end

function Partner:getGradeUpCost()
	return xyd.tables.partnerTable:getGradeUpCost(self:getTableID(), self:getGrade() + 1)
end

function Partner:getHostHero()
end

function Partner:getMaterialHero()
end

function Partner:getMaxAwake()
	return 5
end

function Partner:getAwakeMaterial()
	if self:getMaxAwake() <= self.awake then
		if self.star == 9 and xyd.tables.partnerTable:getTenId(self.tableID) > 0 then
			return xyd.tables.partnerTable:getAwakeMaterial(self.tableID, self.awake)
		else
			return nil
		end
	else
		return xyd.tables.partnerTable:getAwakeMaterial(self.tableID, self.awake)
	end
end

function Partner:getAwakeItemCost()
	if self:getMaxAwake() <= self.awake then
		if self.star == 9 and xyd.tables.partnerTable:getTenId(self.tableID) > 0 then
			return xyd.tables.partnerTable:getAwakeItemCost(self.tableID, self.awake)
		else
			return nil
		end
	elseif self:getGroup() ~= xyd.PartnerGroup.TIANYI then
		return xyd.tables.partnerTable:getAwakeItemCost(self.tableID, self.awake)
	elseif self:getGroup() == xyd.PartnerGroup.TIANYI then
		local cost = {}

		table.insert(cost, xyd.tables.partnerTable:getAwakeItemCost(self.tableID, self.awake))
		table.insert(cost, xyd.tables.partnerGroup7Table:getExMaterial(self.tableID, self.awake))

		return cost
	end
end

function Partner:getAwakeGrow()
end

function Partner:getAwakeSkill(awake)
	if awake ~= nil then
		local skills = xyd.tables.partnerTable:awakeSkill(self.tableID)

		return xyd.split(skills[awake], "#")
	else
		return xyd.tables.partnerTable:awakeSkill(self.tableID)
	end
end

function Partner:getPasSkill()
	local awake = self:getAwake()
	local awakeSkill = {}
	local tableID = self:getTableID()
	local exSkills = {}

	if self:hasExSkill() then
		exSkills = self:getTypedSkillIds()
	elseif awake and awake ~= 0 and awake < 6 then
		local awakeSkills = PartnerTable:awakeSkill(tableID)
		awakeSkill = xyd.split(awakeSkills[awake], "#", true)
	end

	local skills = {}

	for i = 1, 3 do
		local pasTier = PartnerTable:getPasTier(tableID, i)

		if pasTier and pasTier <= self:getGrade() then
			local skill = nil

			if self:hasExSkill() then
				skill = exSkills[i + 1]
			elseif awake and awake ~= 0 and awake < 6 then
				skill = awakeSkill[i + 1]
			else
				skill = PartnerTable:getPasSkill(tableID, i)
			end

			skill = tonumber(skill) or 0

			if skill > 0 then
				local subSkills = xyd.tables.skillTable:getSubSkills(skill)

				table.insert(skills, skill)

				if #subSkills > 0 then
					for _, subSkill in ipairs(subSkills) do
						if subSkill > 0 then
							table.insert(skills, subSkill)
						end
					end
				end
			end
		else
			break
		end
	end

	local potentials = self:getPotential() or {}
	local skillPotentials = PartnerTable:getPotential(tableID)

	for i = 1, #skillPotentials do
		local tmpSkill = skillPotentials[i]
		local index = potentials[i]

		if index and index > 0 and tmpSkill[index] then
			local skill = tmpSkill[index]
			local subSkills = xyd.tables.skillTable:getSubSkills(skill)

			table.insert(skills, tmpSkill[index])

			if #subSkills > 0 then
				for _, subSkill in ipairs(subSkills) do
					table.insert(skills, subSkill)
				end
			end
		end
	end

	return skills
end

function Partner:getPower()
	if self.attrs then
		return self.attrs.power or 0
	else
		return 0
	end
end

function Partner:getName()
	return xyd.tables.partnerTable:getName(self.tableID)
end

function Partner:getNotation()
	return xyd.tables.partnerNotationTextTable:getNotation(self.tableID)
end

function Partner:getLevel()
	return self.lev
end

function Partner:getGroup()
	return xyd.tables.partnerTable:getGroup(self.tableID)
end

function Partner:getTableID()
	return self.tableID
end

function Partner:getHeroTableID()
	return self.tableID
end

function Partner:getCommentID()
	return xyd.tables.partnerTable:getCommentID(self.tableID)
end

function Partner:getShowInGuide()
	return xyd.tables.partnerTable:getShowInGuide(self.tableID)
end

function Partner:getModelName()
	return xyd.tables.partnerTable:getModelName(self.tableID)
end

function Partner:getModel()
	return xyd:getEffect(self:getModelName(), self:getScale(), self:getScale())
end

function Partner:getModelID()
	return xyd.tables.partnerTable:getModelID(self:getTableID())
end

function Partner:getScale()
	return 0.8
end

function Partner:getSkillID(skillIndex)
	local ids = self:getSkillIDs()

	return ids[skillIndex + 1]
end

function Partner:getSkillIDs()
	local res = {}
	local partnerTable = xyd.tables.partnerTable
	local tableID = self:getTableID()

	table.insert(res, partnerTable:getEnergyID(tableID))

	for i = 1, 3 do
		local skillID = partnerTable:getPasSkill(tableID, i)

		if skillID and skillID ~= 0 then
			table.insert(res, partnerTable:getPasSkill(tableID, i))
		end
	end

	return res
end

function Partner:getTypedSkillIds()
	local awake = self:getAwake()
	local skillIds = {}

	if awake > 0 then
		skillIds = self:getAwakeSkill(awake)
	else
		skillIds = self:getSkillIDs()
	end

	for i = 1, #skillIds do
		skillIds[i] = self:getExSkillId(i)
	end

	return skillIds
end

function Partner:getExSkillId(skillIndex)
	local skillId = self:getSkillIDs()[skillIndex]
	local exSkillLev = self:getExSkills()[skillIndex]
	local exSkillId = skillId

	if skillId and exSkillLev and exSkillLev ~= 0 then
		local exSkillIds = xyd.tables.partnerExSkillTable:getExID(skillId)
		exSkillId = exSkillIds[exSkillLev]
	end

	return exSkillId
end

function Partner:getPasTier(i)
	return xyd.tables.partnerTable:getPasTier(self.tableID, i)
end

function Partner:getPugongID()
	return xyd.tables.partnerTable:getPugongID(self.tableID)
end

function Partner:getEnergyID()
	return xyd.tables.partnerTable:getEnergyID(self.tableID)
end

function Partner:getInitMp()
	return xyd.tables.partnerTable:getInitMp(self.tableID)
end

function Partner:getAddHurtID()
	if self.addHurID == nil then
		self.addHurID = 0

		for i = 1, 4 do
			local pasSkill = xyd.tables.partnerTable:getPasSkill(self.tableID, i)

			if pasSkill > 0 then
				local effects = xyd.tables.skillTable:getEffects(pasSkill)

				for j = 1, #effects do
					local effect = effects[j]

					if xyd.tables.effectTable:getType(effect) == xyd.BUFF_ADD_HURT then
						self.addHurID = pasSkill

						break
					end
				end
			end
		end
	end

	return self.addHurID
end

function Partner:getCVName()
	return xyd.tables.partnerTextTable:getCVName(self.tableID)
end

function Partner:getBattleAttrs(params)
	if params then
		return xyd.models.heroAttr:attr(self, params)
	else
		return self.attrs
	end
end

function Partner:isCollected()
	if not self.partnerID then
		return false
	end

	self.isCollected_ = xyd.models.slot:getIsCollected(self.partnerID)

	return self.isCollected_
end

function Partner:levUp(lev)
	self.isLevingUp = true
	lev = lev or 1
	local msg = messages_pb.partner_levup_req()
	msg.incr_lv = lev
	msg.partner_id = self.partnerID

	xyd.Backend.get():request(xyd.mid.PARTNER_LEVUP, msg)
end

function Partner:fakeLevUp()
	local data = {}
	local info = self:getInfo()
	data.partner_info = info
	data.partner_info.table_id = info.tableID
	data.partner_info.lev = tonumber(info.lev) + 1
	data.partner_info.equips = data.partner_info.equipments
	data.partner_info.flags = data.partner_info.lockFlags
	data.partner_info.lv = data.partner_info.lev
	data.partner_info.partner_id = info.partnerID
	local e = {
		name = xyd.event.PARTNER_LEVUP,
		data = data
	}

	xyd.EventDispatcher:outer():dispatchEvent(e)
	xyd.EventDispatcher:inner():dispatchEvent(e)
end

function Partner:gradeUp()
	local grade = self:getGrade()

	if grade < self:getMaxGrade() then
		local msg = messages_pb.partner_gradeup_req()
		msg.partner_id = self.partnerID

		xyd.Backend.get():request(xyd.mid.PARTNER_GRADEUP, msg)

		self.grade = self.grade + 1
	end
end

function Partner:equip(equipments)
	local msg = messages_pb.equip_req()
	msg.partner_id = self.partnerID

	for _, v in ipairs(equipments) do
		table.insert(msg.equips, v)
	end

	xyd.Backend.get():request(xyd.mid.EQUIP, msg)
end

function Partner:changeShowID(showID)
	local msg = messages_pb:set_show_id_req()
	msg.partner_id = self.partnerID
	msg.show_id = tonumber(showID)

	xyd.Backend.get():request(xyd.mid.SET_SHOW_ID, msg)
end

function Partner:equipRob(itemID, fromPartnerId, targetPartnerId)
	xyd.models.slot:addEquip(itemID, targetPartnerId)
	xyd.models.slot:deleteEquip(itemID, fromPartnerId)

	local MAP_TYPE_2_POS = {
		["6"] = 1,
		["9"] = 4,
		["7"] = 2,
		["8"] = 3,
		["11"] = 6
	}
	local pos = MAP_TYPE_2_POS[tostring(xyd.tables.itemTable:getType(itemID))]
	local changeEquip = self:getEquipment()[pos]

	if changeEquip then
		xyd.models.slot:deleteEquip(changeEquip, targetPartnerId)
	end

	local msg = messages_pb:rob_partner_equip_req()
	msg.from_partner_id = fromPartnerId
	msg.target_partner_id = targetPartnerId
	msg.item_id = tonumber(itemID)

	xyd.Backend.get():request(xyd.mid.ROB_PARTNER_EQUIP, msg)
end

function Partner:equipSingle(itemID)
	local pos = xyd.tables.equipTable:getPos(itemID)
	local oldEquip = self:getEquipment()[pos]
	local now_equips = {}

	for k, v in ipairs(self:getEquipment()) do
		now_equips[k] = v
	end

	now_equips[pos] = itemID

	xyd.models.slot:addEquip(itemID, self.partnerID)
	xyd.models.slot:deleteEquip(oldEquip, self.partnerID)
	self:equip(now_equips)
	xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_ON)
end

function Partner:unEquipSingle(itemID)
	local now_equips = {}

	for k, v in ipairs(self:getEquipment()) do
		now_equips[k] = v
	end

	for key in pairs(now_equips) do
		if now_equips[key] == itemID then
			now_equips[key] = 0
		end
	end

	xyd.models.slot:deleteEquip(itemID, self.partnerID)
	self:equip(now_equips)
	xyd.SoundManager.get():playSound(xyd.SoundID.EQUIP_OFF)
end

function Partner:awakePartner(material_ids)
	local msg = messages_pb.awake_partner_req()
	msg.partner_id = self.partnerID

	for _, id in pairs(material_ids) do
		table.insert(msg.material_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.AWAKE_PARTNER, msg)
end

function Partner:treasureOn()
	local msg = messages_pb:treasure_on_req()
	msg.partner_id = self.partnerID

	xyd.Backend.get():request(xyd.mid.TREASURE_ON, msg)
end

function Partner:treasureRefresh()
	local msg = messages_pb:treasure_refresh_req()
	msg.partner_id = self.partnerID

	xyd.Backend.get():request(xyd.mid.TREASURE_REFRESH, msg)
end

function Partner:treasureSave(index)
	local msg = messages_pb:treasure_save_req()
	msg.partner_id = self.partnerID
	msg.index = index or 1

	xyd.Backend.get():request(xyd.mid.TREASURE_SAVE, msg)
end

function Partner:treasureUpgrade(is_lock)
	local msg = messages_pb:treasure_upgrade_req()
	msg.partner_id = self.partnerID
	msg.is_lock = is_lock and 1 or 0

	xyd.Backend.get():request(xyd.mid.TREASURE_UPGRADE, msg)
end

function Partner:artifactUpgrade(items)
	local msg = messages_pb:artifact_upgrade_req()
	msg.partner_id = self.partnerID

	for _, item in ipairs(items) do
		local itemMsg = messages_pb:items_info()
		itemMsg.item_id = item.item_id
		itemMsg.item_num = item.item_num

		table.insert(msg.items, itemMsg)
	end

	xyd.Backend.get():request(xyd.mid.ARTIFACT_UPGRADE, msg)
end

function Partner:lock(lock_flag)
	local msg = messages_pb:lock_partner_req()
	msg.partner_id = self.partnerID
	msg.is_lock = xyd.checkCondition(lock_flag, 1, 0)

	xyd.Backend.get():request(xyd.mid.LOCK_PARTNER, msg)
end

function Partner:getInfo()
	return {
		tableID = self.tableID,
		star = self.star,
		lev = self.lev,
		partnerID = self.partnerID,
		equipments = self.equipments,
		grade = self.grade,
		awake = self.awake,
		lockFlags = self.lockFlags,
		skin_id = self:getSkinID(),
		lovePoint = self.love_point,
		isVowed = self.is_vowed,
		power = self:getPower(),
		group = self:getGroup(),
		potentials = self.potentials,
		skill_index = self.skill_index,
		ex_skills = self.ex_skills,
		wedding_date = self.wedding_date,
		travel = self.travel,
		potentials_bak = self.potentials_bak,
		treasures = self.treasures,
		star_origin = self.star_origin
	}
end

function Partner:getLockType()
	local lockFlags = self.lockFlags

	for i = 1, xyd.PartnerFlag.LOCK_NUM do
		if lockFlags[i] then
			if lockFlags[i] ~= 0 then
				return i
			end
		end
	end

	return 0
end

function Partner:getLockTypes()
	local lockFlags = self.lockFlags
	local locks = {}

	for i = 1, xyd.PartnerFlag.LOCK_NUM do
		if lockFlags[i] then
			if lockFlags[i] ~= 0 then
				table.insert(locks, i)
			end
		end
	end

	return locks
end

function Partner:setLock(flag, type)
	self.lockFlags[type] = flag
end

function Partner:isLockFlag()
	if not self.lockFlags then
		return false
	end

	for _, v in pairs(self.lockFlags) do
		if tonumber(v) ~= 0 then
			return true
		end
	end

	return false
end

function Partner:replace(tableID)
	self.tableID = tableID
	self.equipments[7] = 0

	self:updateAttrs()
end

function Partner:getSkinID()
	self:setSkinID()

	return self.equipments[7] or 0
end

function Partner:setSkinID()
	local skinID = 0
	skinID = (not self.equipments or self.showSkin ~= 1) and 0 or self.equipments[7] or 0
	self.skin_id = skinID
end

function Partner:isShowSkin()
	return self.showSkin == 1
end

function Partner:setShowSkin(showSkin)
	self.showSkin = showSkin

	self:setSkinID()
end

function Partner:getShowID()
	return self.showID
end

function Partner:setShowID(show_id)
	self.showID = show_id
end

function Partner:displayChange()
	local selfPlayer = xyd.models.selfPlayer

	if selfPlayer:getPicturePartner() ~= self.partnerID then
		return
	end

	local pictureID = selfPlayer:getPictureID()
	local showID = self:getSkinID() or self.tableID

	if pictureID ~= showID then
		selfPlayer:editPlayerPicture(showID, self.partnerID)
	end
end

function Partner:getWeddingSkin()
	return xyd.tables.partnerTable:getWeddingSkin(self.tableID)
end

function Partner:isMonster()
	return false
end

function Partner:getActiveIndex()
	return self.potentials or {
		0,
		0,
		0,
		0,
		0
	}
end

function Partner:getPotentialByOrder()
	return xyd.tables.partnerTable:getPotential(self.tableID)
end

function Partner:getPotentialBak()
	return self.potentials_bak
end

function Partner:isCanAwake()
	local tableID = self:getTableID()
	local star = self:getStar()
	local tenTableID = xyd.tables.partnerTable:getTenId(tableID)

	if star < 6 then
		return false
	end

	if star == 9 and tenTableID == 0 then
		return false
	end

	if star == 13 then
		return false
	end

	local maxGrade = self:getMaxGrade()
	local grade = self:getGrade()

	if grade < maxGrade then
		return false
	end

	return true
end

function Partner:fullOrderGradeUp()
	local msg = messages_pb.partner_one_click_up_req()
	msg.partner_id = self.partnerID

	xyd.Backend.get():request(xyd.mid.PARTNER_ONE_CLICK_UP, msg)
end

function Partner:updateTreasures(treasures)
	self.treasures = treasures
end

function Partner:updateIndexedTreasure(index, value)
	self.treasures[index] = value
end

function Partner:updateSelectTreasure(index)
	self.select_treasure = index
end

function Partner:hasExSkill()
	if PartnerTable:getExSkill(self.tableID) == 1 then
		return true
	else
		return false
	end
end

return Partner
