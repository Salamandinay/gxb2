local SoulEquip2 = class("SoulEquip", import("app.models.BaseModel"))

function SoulEquip2:ctor(...)
	SoulEquip2.super.ctor(self, ...)

	self.soulEquipID = 0
	self.tableID = 0
	self.star = 0
	self.lev = 0
	self.pos = 0
end

function SoulEquip2:populate(params)
	self.soulEquipID = params.equip_id or params.SoulEquip_id or params.soulEquipID
	self.tableID = params.table_id or params.tableID or 0
	self.lev = params.lv or params.lev or params.level or 0
	self.awake = params.awake or 0
	self.star = xyd.tables.soulEquip2Table:getStar(self.tableID)
	self.pos = xyd.tables.soulEquip2Table:getPos(self.tableID)
	self.lock = params.lock or 0
	self.exp = params.exp or 0
	self.base_attr_id = params.main
	self.ownerID = params.ownerID
	self.qlt = params.qlt or 1 + self.awake
	self.getTime = self.soulEquipID
	self.replaces = params.replaces
	self.replace_attr_ids = params.replace_attr_ids or {}
	self.replace_factors = params.replace_factors or {}
	self.params = params
	self.ex_attr_ids = params.ex_attr_ids or {}
	self.ex_factor = params.ex_factor or {}
	local temp = params.ex_attrs

	if temp then
		for i = 1, #temp do
			local arr = xyd.split(temp[i], "#")
			self.ex_attr_ids[i] = tonumber(arr[1])
			self.ex_factor[i] = tonumber(arr[2])
		end
	end

	self.init_ex_attr_ids = params.init_ex_attr_ids or {}
	self.init_ex_factor = params.init_ex_factor or {}
	local temp = params.attrs

	if temp then
		for i = 1, #temp do
			local arr = xyd.split(temp[i], "#")
			self.init_ex_attr_ids[i] = tonumber(arr[1])
			self.init_ex_factor[i] = tonumber(arr[2])
		end
	end

	local temp = self.replaces

	if temp then
		for i = 1, #temp do
			local arr = xyd.split(temp[i], "#")
			self.replace_attr_ids[i] = tonumber(arr[1])
			self.replace_factors[i] = tonumber(arr[2])
		end
	end
end

function SoulEquip2:getParams()
	self.params.lv = self.lev
	self.params.awake = self.awake
	self.params.ownerID = self.ownerID

	return self.params
end

function SoulEquip2:getTableID()
	return self.tableID
end

function SoulEquip2:getSoulEquipID()
	return self.soulEquipID
end

function SoulEquip2:getOwnerPartnerID()
	return self.ownerID
end

function SoulEquip2:getSoulEquipInfo()
	return {
		soulEquipID = self.soulEquipID,
		tableID = self.tableID,
		lev = self.lev,
		star = self.star,
		qlt = self.qlt,
		pos = self.pos,
		lock = self.lock,
		exp = self.exp,
		base_attr_id = self.base_attr_id,
		ex_attr_ids = self.ex_attr_ids,
		ex_factor = self.ex_factor,
		init_ex_attr_ids = self.init_ex_attr_ids,
		init_ex_factor = self.init_ex_factor
	}
end

function SoulEquip2:getPos()
	return self.pos
end

function SoulEquip2:getBaseAttrID()
	return self.base_attr_id
end

function SoulEquip2:getExAttrIDs()
	return self.ex_attr_ids
end

function SoulEquip2:containAttr(attrs)
	local helpArr = {}

	for i = 1, #attrs do
		helpArr[attrs[i]] = 1
	end

	local attr = xyd.tables.soulEquip2BaseBuffTable:getBuff(self:getBaseAttrID())

	if helpArr[attr] then
		return true
	end

	for i = 1, #self.ex_attr_ids do
		local attr = xyd.tables.soulEquip2ExBuffTable:getBuff(self.ex_attr_ids[i])

		if helpArr[attr] then
			return true
		end
	end

	return false
end

function SoulEquip2:getLevel()
	return self.lev
end

function SoulEquip2:getStar()
	return self.star
end

function SoulEquip2:getQlt()
	return self.qlt
end

function SoulEquip2:getCurExp()
	return self.exp
end

function SoulEquip2:getGetTime()
	return self.getTime
end

function SoulEquip2:getMaxLevel()
	return xyd.tables.soulEquip2Table:getMaxLev(self:getTableID())
end

function SoulEquip2:getMaxQlt()
	return xyd.tables.soulEquip2Table:getMaxQlt(self:getTableID())
end

function SoulEquip2:getSuitID()
	local groupID = xyd.tables.soulEquip2Table:getGroup(self:getTableID())

	if groupID and groupID > 0 then
		return xyd.tables.soulEquip2GroupTable:getSuitSkill(groupID)
	else
		return nil
	end
end

function SoulEquip2:getBaseAttr(fakeLev)
	fakeLev = fakeLev or 0
	local buff = {
		{}
	}
	local baseAttrID = self:getBaseAttrID()
	local baseValue = xyd.tables.soulEquip2BaseBuffTable:getBase(baseAttrID)
	local growValue = xyd.tables.soulEquip2BaseBuffTable:getGrow(baseAttrID)
	local starFactor = xyd.tables.soulEquip2BaseBuffTable:getStarGrow(baseAttrID)[self.star]
	local qltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[self.qlt]
	buff[1][1] = xyd.tables.soulEquip2BaseBuffTable:getBuff(baseAttrID)
	buff[1][2] = (baseValue + growValue * (self.lev + fakeLev)) * starFactor * qltFactor

	return buff
end

function SoulEquip2:getExAttr(notCotainInitAttr)
	local result = {}
	local baseAttrID = self:getBaseAttrID()
	local starFactor = xyd.tables.soulEquip2BaseBuffTable:getStarGrow(baseAttrID)[self.star]
	local qltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[self.qlt]

	if not notCotainInitAttr then
		for i = 1, #self.init_ex_attr_ids do
			local exID = self.init_ex_attr_ids[i]
			local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(exID)
			local baseAttr = xyd.tables.soulEquip2ExBuffTable:getBase(exID)
			local buffValue = baseAttr * starFactor * qltFactor * self.init_ex_factor[i]
			local insertIndex = 0

			for k, v in pairs(result) do
				if v[1] == buff then
					insertIndex = k

					break
				end
			end

			if insertIndex > 0 then
				result[insertIndex][2] = result[insertIndex][2] + buffValue
			else
				table.insert(result, {
					buff,
					buffValue
				})
			end
		end
	end

	for i = 1, #self.ex_attr_ids do
		local exID = self.ex_attr_ids[i]
		local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(exID)
		local baseAttr = xyd.tables.soulEquip2ExBuffTable:getBase(exID)
		local buffValue = baseAttr * starFactor * qltFactor * self.ex_factor[i]
		local insertIndex = 0

		for k, v in pairs(result) do
			if v[1] == buff then
				insertIndex = k

				break
			end
		end

		if insertIndex > 0 then
			result[insertIndex][2] = result[insertIndex][2] + buffValue
		else
			table.insert(result, {
				buff,
				buffValue
			})
		end
	end

	return result
end

function SoulEquip2:getInitExAttr()
	local result = {}
	local baseAttrID = self:getBaseAttrID()
	local starFactor = xyd.tables.soulEquip2BaseBuffTable:getStarGrow(baseAttrID)[self.star]
	local qltFactor = xyd.tables.soulEquip2BaseBuffTable:getQltGrow(baseAttrID)[self.qlt]

	for i = 1, #self.init_ex_attr_ids do
		local exID = self.init_ex_attr_ids[i]
		local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(exID)
		local baseAttr = xyd.tables.soulEquip2ExBuffTable:getBase(exID)
		local buffValue = baseAttr * starFactor * qltFactor * self.init_ex_factor[i]
		result[i] = {
			buff,
			buffValue
		}
	end

	return result
end

function SoulEquip2:getIsLock()
	return self.lock == 1
end

function SoulEquip2:setOwnerID(ownerID)
	self.ownerID = ownerID
end

function SoulEquip2:setLevel(lv)
	self.lev = lv
end

function SoulEquip2:setExp(exp)
	self.exp = exp
end

function SoulEquip2:getAwake()
	return self.awake
end

function SoulEquip2:setAwake(awake)
	self.awake = awake or 0
	self.qlt = 1 + self.awake
end

function SoulEquip2:setExAttr(ex_ids, ex_factors)
	self.ex_attr_ids = ex_ids or {}
	self.ex_factor = ex_factors or {}
end

function SoulEquip2:setLock(lock)
	self.lock = lock
end

function SoulEquip2:getReplaces()
	return self.replaces
end

function SoulEquip2:setReplaces(ex_ids, ex_factors)
	self.replace_attr_ids = ex_ids
	self.replace_factors = ex_factors
end

function SoulEquip2:getReplacesIDs()
	return self.replace_attr_ids
end

function SoulEquip2:getReplacesFactors()
	return self.replace_factors
end

return SoulEquip2
