local BaseModel = import(".BaseModel")
local ShenXueModel = class("ShenXueModel", BaseModel)
local cjson = require("cjson")

function ShenXueModel:ctor(...)
	self.forgeStatus = {}
	self.shenXueRedPoint = {}
	self.SlotModel = xyd.models.slot

	BaseModel.ctor(self)
end

function ShenXueModel:get()
	if ShenXueModel.INSTANCE == nil then
		ShenXueModel.INSTANCE = ShenXueModel.new()

		ShenXueModel.INSTANCE:onRegister()
	end

	return ShenXueModel.INSTANCE
end

function ShenXueModel:reset()
	if ShenXueModel.INSTANCE then
		ShenXueModel.INSTANCE:removeEvents()
	end

	ShenXueModel.INSTANCE = nil
end

function ShenXueModel:onRegister()
	BaseModel.onRegister(self)
	self:refreshForgeStatus()
	self:registerEvent(xyd.event.COMPOSE_PARTNER, handler(self, self.onComposePartner))
	self:registerEvent(xyd.event.PARTNER_ADD, handler(self, self.onSlotChange))
	self:registerEvent(xyd.event.PARTNER_DEL, handler(self, self.onSlotChange))
	self:registerEvent(xyd.event.AWAKE_PARTNER, handler(self, self.awakePartner))
	self:registerEvent(xyd.event.PARTNER_ONE_CLICK_UP, handler(self, self.onOneClickLevelUp))
	self:registerEvent(xyd.event.PARTNER_GRADEUP, handler(self, self.awakePartner))
end

function ShenXueModel:onSlotChange(event)
	local params = event.data
	local partnerID = params.partnerID
	local tableID = params.tableID
	local groupId = xyd.tables.partnerTable:getGroup(tableID)

	self:refreshGroup(groupId)
end

function ShenXueModel:onComposePartner(event)
	local params = event.data

	if self.isDoingReq then
		local pInfo = params.partner_info
		self.hostPartner = xyd.models.slot:getPartner(pInfo.partner_id)

		self.hostPartner:gradeUp()

		for _, i in ipairs(event.data.items) do
			table.insert(self.tempItems, {
				item_id = i.item_id,
				item_num = tonumber(i.item_num)
			})
		end
	else
		local pInfo = params.partner_info
		local tableID = pInfo.table_id
		local groupId = xyd.tables.partnerTable:getGroup(tableID)

		self:refreshGroup(groupId)
	end
end

function ShenXueModel:getStatusByTableID(tableID)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	local status = self.forgeStatus[tostring(group)][tostring(tableID)]

	return status
end

function ShenXueModel:clearShenXueRedPoint()
	self.shenXueRedPoint = {}
end

function ShenXueModel:getStatusByTableIDAndStar(tableID, star)
	local group = xyd.tables.partnerTable:getGroup(tableID)
	tableID = tonumber(tableID)

	if not self.shenXueRedPoint[group] then
		self.shenXueRedPoint[group] = {}
	end

	if not self.shenXueRedPoint[group][tableID] then
		self.shenXueRedPoint[group][tableID] = {}
	end

	if not self.shenXueRedPoint[group][tableID][star] then
		local material = self:getMaterial({
			star = star,
			tableID = tableID
		})

		for key, value in pairs(material) do
			material[key] = tonumber(value)
		end

		local partners = xyd.models.slot:getPartners()
		local hostTableID = material[1]
		local hostStar = 5

		if star == 5 then
			hostStar = 4
		end

		self.shenXueRedPoint[group][tableID][star] = false

		for key, value in pairs(partners) do
			if partners[key]:getStar() == hostStar and partners[key]:getTableID() == hostTableID and not partners[key]:isLockFlag() then
				local material_detail = {}

				for keyid, mTableID in pairs(material) do
					if not material_detail[mTableID] then
						material_detail[mTableID] = {}
					end

					if mTableID % 1000 == 999 then
						local star = xyd.tables.partnerIDRuleTable:getStar(mTableID)
						local group = xyd.tables.partnerIDRuleTable:getGroup(mTableID)
						local num = (material_detail[mTableID].needNum or 0) + 1
						material_detail[mTableID] = {
							star = star,
							group = group,
							needNum = num,
							partners = {},
							mTableID = mTableID
						}
					else
						material_detail[mTableID].needNum = (material_detail[mTableID].needNum or 0) + 1
						material_detail[mTableID].tableID = material_detail[mTableID].tableID or mTableID
						material_detail[mTableID].partners = {}
						material_detail[mTableID].mTableID = mTableID
					end
				end

				material_detail[hostTableID].needNum = (material_detail[hostTableID].needNum or 0) + 1

				table.insert(material_detail[hostTableID].partners, partners[key]:getPartnerID())

				local selectedPartners = {
					[partners[key]:getPartnerID()] = true
				}
				local isCanForge = true
				local materialIds = {}

				for i = 1, #material do
					if #materialIds == 0 or materialIds[#materialIds] ~= material[i] then
						materialIds[#materialIds + 1] = material[i]
					end
				end

				for i = 1, #materialIds do
					local mTableID = materialIds[i]

					if material_detail[mTableID].tableID then
						for keyid in pairs(partners) do
							local needCheckFlag = false

							if partners[keyid]:getTableID() == material_detail[mTableID].tableID then
								needCheckFlag = true
							end

							if needCheckFlag then
								if not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
									selectedPartners[partners[keyid]:getPartnerID()] = true

									table.insert(material_detail[mTableID].partners, partners[keyid]:getPartnerID())
								end

								if material_detail[mTableID].needNum <= #material_detail[mTableID].partners then
									break
								end
							end
						end

						if material_detail[mTableID].needNum > #material_detail[mTableID].partners then
							self.shenXueRedPoint[group][tableID][star] = false

							return self.shenXueRedPoint[group][tableID][star]
						end
					else
						for keyid in pairs(partners) do
							if (partners[keyid]:getGroup() == material_detail[mTableID].group or material_detail[mTableID].group == 0) and partners[keyid]:getStar() == material_detail[mTableID].star then
								if not selectedPartners[partners[keyid]:getPartnerID()] and not partners[keyid]:isLockFlag() then
									selectedPartners[partners[keyid]:getPartnerID()] = true

									table.insert(material_detail[mTableID].partners, partners[keyid]:getPartnerID())
								end

								if material_detail[mTableID].needNum <= #material_detail[mTableID].partners then
									break
								end
							end
						end

						if material_detail[mTableID].needNum > #material_detail[mTableID].partners then
							self.shenXueRedPoint[group][tableID][star] = false

							return self.shenXueRedPoint[group][tableID][star]
						end
					end
				end

				self.shenXueRedPoint[group][tableID][star] = true

				return self.shenXueRedPoint[group][tableID][star]
			end
		end
	end

	local status = self.shenXueRedPoint[group][tableID][star]

	return status
end

function ShenXueModel:getForgeList()
	return self.forgeList
end

function ShenXueModel:refreshForgeStatus()
	self.SlotModel:refreshShenxueForgeStatus()

	self.forgeList = self.SlotModel.forgeList
	self.forgeStatus = self.SlotModel.forgeStatus
end

function ShenXueModel:refreshGroup(groupId)
	self.SlotModel:refreshShenxueGroup(groupId)
end

function ShenXueModel:getMaterial(partnerInfo)
	local material = nil

	if partnerInfo.star <= 6 then
		material = xyd.split(xyd.tables.partnerTable:getMaterial(partnerInfo.tableID), "|")
	elseif partnerInfo.star > 6 then
		local tableID = partnerInfo.tableID

		if partnerInfo.star == 10 then
			local sixStarTableID = xyd.tables.partnerTable:getSixStarTableID(tableID)
			tableID = sixStarTableID
		end

		material = xyd.split(xyd.tables.partnerTable:getMaterial(tableID), "|")
		local arr = xyd.split(xyd.tables.partnerTable:getAwakeMaterial(tableID), "|")

		for i = 1, partnerInfo.star - 6 do
			local temp = xyd.split(arr[i], "#")

			for j = 1, #temp do
				table.insert(material, temp[j])
			end
		end
	end

	table.sort(material, function (a, b)
		local aIsFeiTai5 = false
		local bIsFeiTai5 = false
		local aTableID = a
		local bTableID = b
		local aStar = xyd.tables.partnerTable:getStar(aTableID)
		local aTenStarTableID = xyd.tables.partnerTable:getTenStarTableID(aTableID)
		local bStar = xyd.tables.partnerTable:getStar(bTableID)
		local bTenStarTableID = xyd.tables.partnerTable:getTenStarTableID(bTableID)
		local aisAny = aTableID % 1000 == 999
		local bisAny = bTableID % 1000 == 999

		if aStar == 5 and (not aTenStarTableID or aTenStarTableID <= 0) then
			aIsFeiTai5 = true
		end

		if bStar == 5 and (not bTenStarTableID or bTenStarTableID <= 0) then
			bIsFeiTai5 = true
		end

		if aIsFeiTai5 ~= bIsFeiTai5 then
			return aIsFeiTai5
		elseif aisAny ~= bisAny then
			return not aisAny
		else
			return aTableID < bTableID
		end
	end)

	return material
end

function ShenXueModel:getResCost(partnerInfo, desStar)
	local star = 5
	local PartnerTable = xyd.tables.partnerTable
	local tableID = partnerInfo.tableID
	local partnerGrade = partnerInfo.grade
	local partnerLevel = partnerInfo.lev
	local sixStarTableID = xyd.tables.partnerTable:getSixStarTableID(tableID)
	local maxLevel = 100
	local costMANA = xyd.tables.expPartnerTable:getAllMoney(maxLevel) - xyd.tables.expPartnerTable:getAllMoney(partnerLevel)
	local costEXP = xyd.tables.expPartnerTable:getAllExp(maxLevel) - xyd.tables.expPartnerTable:getAllExp(partnerLevel)
	local costSTONE = 0
	local maxGrade = 5
	self.grade = maxGrade

	for i = partnerGrade + 1, maxGrade do
		local GradeUpCost = PartnerTable:getGradeUpCost(tableID, i)
		costMANA = costMANA + GradeUpCost[xyd.ItemID.MANA]
		costSTONE = costSTONE + GradeUpCost[xyd.ItemID.GRADE_STONE]
	end

	local GradeUpCost = PartnerTable:getGradeUpCost(sixStarTableID, 6)
	costMANA = costMANA + GradeUpCost[xyd.ItemID.MANA]
	costSTONE = costSTONE + GradeUpCost[xyd.ItemID.GRADE_STONE]
	local costNum = 0

	for i = 1, desStar - star - 1 do
		local cost = xyd.tables.partnerTable:getAwakeItemCost(sixStarTableID, i - 1)
		cost = xyd.checkCondition(cost and #cost > 0, cost, {
			xyd.ItemID.GRADE_STONE,
			0
		})
		costSTONE = costSTONE + cost[2]
	end

	local costs = {
		[xyd.ItemID.MANA] = costMANA,
		[xyd.ItemID.GRADE_STONE] = costSTONE,
		[xyd.ItemID.PARTNER_EXP] = costEXP
	}

	return costs
end

function ShenXueModel:onOneClickLevelUp(event)
	if not self.isDoingReq then
		return
	end

	local fiveStarTableID = self.hostPartner:getTableID()
	local SixStarTableID = xyd.tables.partnerTable:getSixStarTableID(fiveStarTableID)
	local msg = messages_pb.compose_partner_req()
	msg.table_id = SixStarTableID

	table.insert(msg.material_ids, self.hostPartner.partnerID)

	local material = xyd.split(xyd.tables.partnerTable:getMaterial(SixStarTableID), "|")

	for key, tableID in pairs(material) do
		if not self.useArr[tableID] then
			self.useArr[tableID] = 1
		end

		dump(self.material_list)

		local index = self.useArr[tableID]

		table.insert(msg.material_ids, self.material_list[tableID][index].partnerID)

		self.useArr[tableID] = self.useArr[tableID] + 1
	end

	xyd.Backend:get():request(xyd.mid.COMPOSE_PARTNER, msg)
end

function ShenXueModel:awakePartner(event)
	if not self.isDoingReq then
		return
	end

	if event.data.items then
		for _, i in ipairs(event.data.items) do
			table.insert(self.tempItems, {
				item_id = i.item_id,
				item_num = tonumber(i.item_num)
			})
		end
	end

	if not self.awakeTime or self.awakeTime < 1 then
		local params = event.data
		local pInfo = params.partner_info
		local tableID = pInfo.table_id
		local groupId = xyd.tables.partnerTable:getGroup(tableID)

		self:refreshGroup(groupId)

		self.isDoingReq = false
		self.hostPartner = nil
		self.destPartnerInfo = nil
		self.material_list = nil
		self.useArr = {}

		return
	end

	local fiveStarTableID = tonumber(xyd.tables.partnerTable:getFiveStarTableID(self.hostPartner:getTableID()))
	local SixStarTableID = tonumber(xyd.tables.partnerTable:getSixStarTableID(fiveStarTableID))
	local material_ids = {}
	local material = xyd.split(xyd.tables.partnerTable:getAwakeMaterial(SixStarTableID), "|")[self.hostPartner:getAwake() + 1]
	material = xyd.split(material, "#")

	for key, tableID in pairs(material) do
		if not self.useArr[tableID] then
			self.useArr[tableID] = 1
		end

		local index = self.useArr[tableID]

		table.insert(material_ids, self.material_list[tableID][index].partnerID)

		self.useArr[tableID] = self.useArr[tableID] + 1
	end

	self.awakeTime = self.awakeTime - 1

	self.hostPartner:awakePartner(material_ids)
end

function ShenXueModel:reqAwakeOfShenXue(hostPartner, material_list, destPartnerInfo)
	if self.isDoingReq then
		return
	end

	self.isDoingReq = true
	self.hostPartner = hostPartner
	self.destPartnerInfo = destPartnerInfo
	self.material_list = material_list
	self.useArr = {}
	self.tempItems = {}

	hostPartner:fullOrderGradeUp()

	self.awakeTime = destPartnerInfo.star - 6
end

function ShenXueModel:getIsDoingReq()
	return self.isDoingReq
end

function ShenXueModel:getTempItems()
	return self.tempItems
end

function ShenXueModel:getMaterialPartnerRecordTableIDs()
	if not self.materialPartnerRecordTableIDs then
		self.materialPartnerRecordTableIDs = {}
		local value = xyd.db.misc:getValue("shenxue_material_partners_tableIDs")

		if value then
			local records = cjson.decode(value)

			for i = 1, #records do
				table.insert(self.materialPartnerRecordTableIDs, tonumber(records[i]))
			end
		else
			local ids = self:getAllFiveStarPartnerTableIDs()

			for i = 1, #ids do
				local tenStarTableID = xyd.tables.partnerTable:getTenStarTableID(ids[i])

				if not tenStarTableID then
					table.insert(self.materialPartnerRecordTableIDs, ids[i])
				end
			end
		end
	end

	return self.materialPartnerRecordTableIDs
end

function ShenXueModel:setMaterialPartnerRecordTableIDs(arr)
	self.materialPartnerRecordTableIDs = arr

	xyd.db.misc:setValue({
		key = "shenxue_material_partners_tableIDs",
		value = cjson.encode(self.materialPartnerRecordTableIDs)
	})
end

function ShenXueModel:getAllFiveStarPartnerTableIDs()
	if not self.allFiveStarPartnerTableIDs then
		self.allFiveStarPartnerTableIDs = {}
		local ids = xyd.tables.partnerTable:getIds()

		for _, id in ipairs(ids) do
			if xyd.tables.partnerTable:getStar(id) == 5 and xyd.tables.partnerTable:getShowInGuide(id) >= 1 and tonumber(xyd.tables.partnerTable:getShowInGuide(id)) <= xyd.getServerTime() then
				table.insert(self.allFiveStarPartnerTableIDs, tonumber(id))
			end
		end
	end

	return self.allFiveStarPartnerTableIDs
end

ShenXueModel.INSTANCE = nil

return ShenXueModel
