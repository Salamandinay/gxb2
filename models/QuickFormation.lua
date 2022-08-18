local BaseModel = import(".BaseModel")
local QuickFormation = class("QuickFormation", BaseModel)
local Partner = import("app.models.Partner")

function QuickFormation:ctor()
	QuickFormation.super.ctor(self)

	self.formationInfo_ = {}
	self.partnersInfo_ = {}
	self.redStatus_ = {}
	self.redStatusPos_ = {}
end

function QuickFormation:onRegister()
	self:registerEvent(xyd.event.GET_QUICK_FORMATION_INFO, handler(self, self.onGetTeamsInfo))
	self:registerEvent(xyd.event.SET_QUICK_TEAM, handler(self, self.onSetTeam))
	self:registerEvent(xyd.event.OPEN_FORMATION_SLOT, handler(self, self.onOpenSlot))
end

function QuickFormation:reqTeamsInfo()
	local msg = messages_pb.get_quick_formation_info_req()

	xyd.Backend.get():request(xyd.mid.GET_QUICK_FORMATION_INFO, msg)
end

function QuickFormation:onGetTeamsInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.formations and #data.formations > 0 then
		self:initFomations(data.formations)
	end

	self.slotNum_ = data.slot_num

	self:updateRedStatus()
end

function QuickFormation:initFomations(formation_list)
	for _, info in ipairs(formation_list) do
		local id = info.id

		self:setFomationInfo(id, info)
	end
end

function QuickFormation:setFomationInfo(id, info)
	if self.formationInfo_[id] then
		for _, partner_info in pairs(self.formationInfo_[id].partners) do
			local partnerID = partner_info:getPartnerID()

			xyd.models.slot:getPartner(partnerID):setLock(0, xyd.PartnerFlag.QUICK_FORMATION)
		end
	end

	if id and tonumber(id) > 0 then
		self.formationInfo_[id] = {
			id = id,
			name = info.name,
			pet_id = info.pet_id or 0,
			partners = {}
		}
		self.partnersInfo_[id] = {}

		if info.partners then
			for _, partner_info in ipairs(info.partners) do
				local partnerID = partner_info.partner_id
				local pos = tonumber(partner_info.pos)
				local partnerInfo = xyd.models.slot:getPartner(partnerID)

				partnerInfo:setLock(1, xyd.PartnerFlag.QUICK_FORMATION)

				local np = Partner.new()
				local info = partnerInfo:getInfo()

				if partner_info.table_id and partner_info.table_id > 0 then
					if info.tableID ~= partner_info.table_id then
						np.awakeTableChange = true
					end

					info.tableID = partner_info.table_id
				end

				np:populate(info)
				np:setEquip(partner_info.equips)

				if np.equipments and np.equipments[5] then
					local treasures = np.treasures
					local seletIndex = xyd.arrayIndexOf(treasures, np.equipments[5])
					np.select_treasure = seletIndex
				end

				np:updatePotential(partner_info.potentials)

				np.skill_index = partner_info.skill_index
				self.formationInfo_[id].partners[pos] = np
				self.partnersInfo_[id][tonumber(partner_info.partner_id)] = np
			end
		end
	end
end

function QuickFormation:updatePartnerInfo()
	local teamNum = self:getTeamNum()

	for i = 1, teamNum do
		if self.formationInfo_[i] and self.formationInfo_[i].partners then
			for _, partner_info in pairs(self.formationInfo_[i].partners) do
				local partnerID = partner_info:getPartnerID()
				local partner = xyd.models.slot:getPartner(partnerID)

				if partner then
					local partnerInfo = partner:getInfo()
					partner_info.star = partnerInfo.star
					partner_info.lev = partnerInfo.lev
					partner_info.grade = partnerInfo.grade
					partner_info.awake = partnerInfo.awake
					partner_info.lockFlags = partnerInfo.lockFlags
					partner_info.skin_id = partnerInfo.skin_id
					partner_info.lovePoint = partnerInfo.love_point
					partner_info.isVowed = partnerInfo.is_vowed
					partner_info.group = partnerInfo.group
					partner_info.ex_skills = partnerInfo.ex_skills
					partner_info.star_origin = partnerInfo.star_origin
					partner_info.treasures = partnerInfo.treasures
					partner_info.travel = partnerInfo.travel

					if partnerInfo.tableID and partnerInfo.tableID > 0 then
						if partner_info.tableID ~= partnerInfo.tableID then
							partner_info.awakeTableChange = true
						end

						partner_info.tableID = partnerInfo.tableID
					end
				end

				partner_info:updateAttrs()
			end
		end
	end
end

function QuickFormation:getPartnerInfo(team_index, partner_id)
	if self.partnersInfo_[team_index] and self.partnersInfo_[team_index][partner_id] then
		return self.partnersInfo_[team_index][partner_id]
	else
		self.partnersInfo_[team_index] = {}
		local np = Partner.new()
		local partnerInfo = xyd.models.slot:getPartner(partner_id)

		np:populate(partnerInfo:getInfo())

		self.partnersInfo_[team_index][partner_id] = np

		return np
	end
end

function QuickFormation:getTeamNum()
	if UNITY_EDITOR and not self.slotNum_ then
		return 5
	end

	return self.slotNum_ or 0
end

function QuickFormation:isTeamPartnersHas(index)
	if self.formationInfo_[index] and self.formationInfo_[index].partners then
		local isHas = false

		for i in pairs(self.formationInfo_[index].partners) do
			isHas = true

			break
		end

		return isHas
	end

	return false
end

function QuickFormation:getTeamName(index)
	if self.formationInfo_[index] then
		return self.formationInfo_[index].name
	end

	local localTeamName = xyd.db.misc:getValue("qucik_formation_edit_index_name_" .. index)

	if localTeamName then
		return localTeamName
	end

	return __("QUICK_FORMATION_TEXT12", index)
end

function QuickFormation:setTeamName(index, name)
	if self:isTeamPartnersHas(index) then
		self.formationInfo_[index].name = name
	end

	xyd.db.misc:setValue({
		key = "qucik_formation_edit_index_name_" .. index,
		value = xyd.escapesLuaString(name)
	})
end

function QuickFormation:getPartnerList(team_index)
	if self.formationInfo_[team_index] then
		return self.formationInfo_[team_index].partners
	end

	return {}
end

function QuickFormation:getPet(team_index)
	if self.formationInfo_[team_index] then
		return self.formationInfo_[team_index].pet_id
	end

	return 0
end

function QuickFormation:setTeamInfo(index, pet, partners)
	local msg = messages_pb.set_quick_team_req()
	msg.id = index
	local formation = msg.formation
	local name = self:getTeamName(index)
	formation.name = name
	formation.pet_id = pet
	self.tmpTeamInfo_ = {
		name = name,
		id = index,
		pet_id = pet,
		partners = {}
	}

	for _, info in ipairs(partners) do
		local copyPartnerInfo = {
			pos = info.pos,
			skill_index = info.skill_index,
			potentials = info.potentials,
			partner_id = info.partner_id,
			equips = {}
		}
		local partner_info = messages_pb.quick_partner_set_info()
		local partner_id = info.partner_id
		partner_info.partner_id = partner_id

		for _, id in ipairs(info.potentials) do
			table.insert(partner_info.potentials, id)
		end

		partner_info.pos = info.pos
		partner_info.skill_index = info.skill_index

		for key, equipInfo in ipairs(info.equips) do
			local equip_id = equipInfo.id or 0
			local from_partner_id = equipInfo.from_partner_id or 0
			local quick_equips_info = messages_pb.quick_equips_info()
			quick_equips_info.id = equip_id

			if key == 7 and equipInfo.id > 0 then
				quick_equips_info.from_partner_id = partner_id
			else
				quick_equips_info.from_partner_id = from_partner_id
			end

			table.insert(partner_info.equips, quick_equips_info)

			copyPartnerInfo.equips[key] = equip_id
		end

		table.insert(formation.partners, partner_info)
		table.insert(self.tmpTeamInfo_.partners, copyPartnerInfo)
	end

	xyd.Backend.get():request(xyd.mid.SET_QUICK_TEAM, msg)
end

function QuickFormation:onSetTeam()
	if self.tmpTeamInfo_ then
		self:setFomationInfo(self.tmpTeamInfo_.id, self.tmpTeamInfo_)
	end

	self:updateRedStatus()
end

function QuickFormation:onOpenSlot(event)
	self.slotNum_ = event.data.slot_num
end

function QuickFormation:updateRedStatus()
	local teamNum = self:getTeamNum()

	for i = 1, teamNum do
		self.redStatus_[i] = 0
		self.redStatusPos_[i] = {}
		local bpEquips = self:getBackPackEquipInfo()
		local partners = self:getPartnerList(i)

		for pos, partnerInfo in pairs(partners) do
			local Equips = partnerInfo:getEquipment()

			if partnerInfo.awakeTableChange then
				self.redStatus_[i] = 1

				if not self.redStatusPos_[i] then
					self.redStatusPos_[i] = {}
				end

				self.redStatusPos_[i][pos] = 1
			else
				for key, itemID in ipairs(Equips) do
					if itemID and itemID > 0 and key ~= 5 and key ~= 7 then
						local partner_id = self:getFromPartnerID(itemID, bpEquips)

						if partner_id < 0 then
							self.redStatus_[i] = 1

							if not self.redStatusPos_[i] then
								self.redStatusPos_[i] = {}
							end

							self.redStatusPos_[i][pos] = 1

							break
						end
					elseif key == 5 then
						local partnerInfo = xyd.models.slot:getPartner(partnerInfo:getPartnerID())
						local treasures = partnerInfo.treasures or {}

						if #treasures > 0 and xyd.arrayIndexOf(treasures, itemID) <= -1 or #treasures <= 0 and partnerInfo.equipments[5] and partnerInfo.equipments[5] ~= itemID then
							self.redStatus_[i] = 1

							if not self.redStatusPos_[i] then
								self.redStatusPos_[i] = {}
							end

							self.redStatusPos_[i][pos] = 1

							break
						end
					elseif key == 7 then
						local partnerInfo = xyd.models.slot:getPartner(partnerInfo:getPartnerID())
						local skin_id = partnerInfo:getSkinID()

						if skin_id ~= itemID and itemID > 0 then
							self.redStatus_[i] = 1

							if not self.redStatusPos_[i] then
								self.redStatusPos_[i] = {}
							end

							self.redStatusPos_[i][pos] = 1
						end
					end
				end
			end
		end
	end
end

function QuickFormation:getHeroRed(index)
	return self.redStatusPos_[index] or {}
end

function QuickFormation:getFromPartnerID(itemID, bpEquips)
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

function QuickFormation:getRedStatus()
	return self.redStatus_
end

function QuickFormation:getBackPackEquipInfo()
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

return QuickFormation
