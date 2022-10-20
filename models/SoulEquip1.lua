local SoulEquip1 = class("SoulEquip", import("app.models.BaseModel"))

function SoulEquip1:ctor(...)
	SoulEquip1.super.ctor(self, ...)

	self.soulEquipID = 0
	self.tableID = 0
	self.star = 0
	self.lev = 0
	self.pos = 0
end

function SoulEquip1:populate(params)
	self.soulEquipID = params.equip_id or params.SoulEquip_id or params.soulEquipID
	self.tableID = params.table_id or params.tableID or 0
	self.lev = params.lv or params.lev or params.level or 0
	self.awake = params.awake or 0
	self.star = params.star or 1 + self.awake
	self.pos = 1
	self.lock = params.lock or 0
	self.ownerID = params.ownerID
	self.qlt = xyd.tables.soulEquip1Table:getQlt(self.tableID)
	self.getTime = self.soulEquipID
	self.params = params
	self.replaces = {}
	self.ex_attr_ids = {}
	local temp = params.ex_attr_ids or params.attrs

	if temp then
		for i = 1, #temp do
			self.ex_attr_ids[i] = tonumber(temp[i])
		end
	end

	local temp = params.replaces

	if temp then
		for i = 1, #temp do
			self.replaces[i] = tonumber(temp[i])
		end
	end
end

function SoulEquip1:getParams()
	return self.params
end

function SoulEquip1:getTableID()
	return self.tableID
end

function SoulEquip1:getSoulEquipID()
	return self.soulEquipID
end

function SoulEquip1:getOwnerPartnerID()
	return self.ownerID
end

function SoulEquip1:getSoulEquipInfo()
	return {
		soulEquipID = self.soulEquipID,
		tableID = self.tableID,
		lev = self.lev,
		star = self.star,
		qlt = self.qlt,
		pos = self.pos,
		lock = self.lock,
		ex_attr_ids = self.ex_attr_ids
	}
end

function SoulEquip1:getPos()
	return self.pos
end

function SoulEquip1:getLevel()
	return self.lev
end

function SoulEquip1:getStar()
	return self.star
end

function SoulEquip1:getQlt()
	return self.qlt
end

function SoulEquip1:getGetTime()
	return self.getTime
end

function SoulEquip1:getMaxLevel()
	return xyd.tables.miscTable:split2Cost("soul_equip1_star_lvl", "value", "|")[self:getStar()]
end

function SoulEquip1:getMaxLevelInMaxStar()
	return xyd.tables.miscTable:split2Cost("soul_equip1_star_lvl", "value", "|")[self:getMaxStar()]
end

function SoulEquip1:getMaxStar()
	return xyd.tables.soulEquip1Table:getMaxStar(self:getTableID())
end

function SoulEquip1:getBaseAttr(fakeLev)
	local result = {}
	fakeLev = fakeLev or 0

	for i = 1, 3 do
		local baseAttr = xyd.tables.soulEquip1Table:getBaseSingle(self:getTableID(), i)

		if baseAttr and baseAttr[2] and tonumber(baseAttr[2]) > 0 then
			local singleGrow = xyd.tables.soulEquip1Table:getGrowSingle(self:getTableID(), i)
			local attrValue = (baseAttr[2] + singleGrow[2] * (self:getLevel() + fakeLev)) * xyd.tables.soulEquip1Table:getStarGrow(self:getTableID())[self:getStar()]

			table.insert(result, {
				baseAttr[1],
				attrValue
			})
		end
	end

	return result
end

function SoulEquip1:getExAttr(fakeLev)
	local result = {}
	fakeLev = fakeLev or 0

	for i = 1, #self.ex_attr_ids do
		local exID = self.ex_attr_ids[i]

		if exID and exID > 0 then
			local buff = xyd.tables.soulEquip1ExBuffTable:getBuff(exID)
			local baseAttr = xyd.tables.soulEquip1ExBuffTable:getBase(exID)
			local singleGrow = xyd.tables.soulEquip1ExBuffTable:getGrow(exID)
			local buffValue = baseAttr + singleGrow * (self:getLevel() + fakeLev)
			result[i] = {
				buff,
				buffValue
			}
		end
	end

	return result
end

function SoulEquip1:getExAttrIDs()
	return self.ex_attr_ids
end

function SoulEquip1:getMaxExNum()
	local maxStar = self:getMaxStar()

	return xyd.tables.miscTable:split2Cost("soul_equip1_ex_num", "value", "|")[maxStar]
end

function SoulEquip1:getIsLock()
	return self.lock == 1
end

function SoulEquip1:setOwnerID(ownerID)
	self.ownerID = ownerID
end

function SoulEquip1:getAwake()
	return self.awake
end

function SoulEquip1:setAwake(awake)
	self.awake = awake or 0
	self.star = 1 + self.awake
end

function SoulEquip1:setLevel(lev)
	self.lev = lev
end

function SoulEquip1:setExAttr(ex_attr_id, pos)
	self.ex_attr_ids[pos] = ex_attr_id
end

function SoulEquip1:setLock(lock)
	self.lock = lock
end

function SoulEquip1:getReplaces()
	return self.replaces
end

function SoulEquip1:setReplace(value, index)
	dump(index)
	dump(value)

	self.replaces[index] = value
end

return SoulEquip1
