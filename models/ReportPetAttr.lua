local ReportPetAttr = class("ReportPetAttr", import("app.models.BaseModel"))
local BuffTable = xyd.tables.dBuffTable
local HeroTable = xyd.tables.partnerTable
local SkillTable = xyd.tables.skillTable
local EquipTable = xyd.tables.equipTable
local EffectTable = xyd.tables.effectTable
local MonsterTable = xyd.tables.monsterTable
local GuildSkillTable = xyd.tables.guildSkillTable
local AppointmentTable = xyd.tables.datesTable
local jobBuff = {
	zsHpPO = xyd.BUFF_HP_P,
	zsAtkPO = xyd.BUFF_ATK_P,
	zsCritO = xyd.BUFF_CRIT,
	zsMissO = xyd.BUFF_MISS,
	zsSklPO = xyd.BUFF_SKL_P,
	zsSpdO = xyd.BUFF_SPD,
	fsHpPO = xyd.BUFF_HP_P,
	fsAtkPO = xyd.BUFF_ATK_P,
	fsCritO = xyd.BUFF_CRIT,
	fsHitO = xyd.BUFF_HIT,
	fsSklPO = xyd.BUFF_SKL_P,
	fsSpdO = xyd.BUFF_SPD,
	ckHpPO = xyd.BUFF_HP_P,
	ckCritTimeO = xyd.BUFF_CRIT_TIME,
	ckCritO = xyd.BUFF_CRIT,
	ckBrkO = xyd.BUFF_BRK,
	ckSklPO = xyd.BUFF_SKL_P,
	ckSpdO = xyd.BUFF_SPD,
	ckAtkPO = xyd.BUFF_ATK_P,
	yxHpPO = xyd.BUFF_HP_P,
	yxAtkPO = xyd.BUFF_ATK_P,
	yxMissO = xyd.BUFF_MISS,
	yxHitO = xyd.BUFF_HIT,
	yxSklPO = xyd.BUFF_SKL_P,
	yxSpdO = xyd.BUFF_SPD,
	msHpPO = xyd.BUFF_HP_P,
	msMissO = xyd.BUFF_MISS,
	msCritO = xyd.BUFF_CRIT,
	msSpdO = xyd.BUFF_SPD,
	msSklPO = xyd.BUFF_SKL_P,
	msAtkPO = xyd.BUFF_ATK_P
}

function ReportPetAttr:ctor()
	self.isPercent = {}

	self:init()
end

function ReportPetAttr:init()
	if #self.isPercent == 0 then
		local buffs = BuffTable:getBuffs()

		for name in pairs(buffs) do
			if BuffTable:isPercent(name) then
				self.isPercent[name] = true
			end
		end
	end
end

function ReportPetAttr:attr(pet)
	local baseEffects = pet.baseEffects
	local base = {
		spd = 0,
		atk = 0,
		sklP = 0,
		trueAtk = 0,
		crit = 0,
		unCrit = 0,
		brk = 0,
		arm = 0,
		hp = 0,
		miss = 0,
		critTime = 0,
		hit = 0
	}
	local armpValue = 0

	for _, effect in ipairs(baseEffects) do
		local name = effect[1]
		local value = effect[2]

		if base[name] ~= nil then
			base[name] = base[name] + tonumber(value)
		end

		if name == "armP" then
			armpValue = armpValue + value
		end
	end

	local extra = {}
	local isPercent = self.isPercent

	local function addAttr(name, value)
		value = tonumber(value)

		if isPercent[name] then
			if not extra[name] then
				extra[name] = {}
			end

			table.insert(extra[name], value)
		else
			extra[name] = (extra[name] or 0) + value
		end
	end

	local function v(name, nameP)
		if nameP == nil then
			nameP = nil
		end

		local n = math.floor(base[name] or 0) + math.floor(extra[name] or 0)

		if nameP ~= nil and extra[nameP] then
			local flag = false

			if n == 0 then
				n = 1
				flag = true
			end

			for _, p in ipairs(extra[nameP]) do
				if flag then
					n = n + n * p
				else
					n = n + math.floor(n * p)
				end
			end
		end

		return n
	end

	local pas_skills = pet:getPasSkill()

	for i = 1, #pas_skills do
		local pasSkill = pas_skills[i]

		if pasSkill and tonumber(pasSkill) > 0 and SkillTable:attrPas(pasSkill) == 2 then
			for _, effect in ipairs(SkillTable:getEffects(pasSkill)) do
				for _, e in ipairs(effect) do
					local buff = EffectTable:getType(e)
					local num = EffectTable:getNum(e)

					addAttr(buff, num)
				end
			end
		end
	end

	local function calculate()
		local attribs = {
			hp = v(xyd.BUFF_HP, xyd.BUFF_HP_P),
			atk = v(xyd.BUFF_ATK, xyd.BUFF_ATK_P),
			arm = v(xyd.BUFF_ARM, xyd.BUFF_ARM_P),
			armP = armpValue,
			spd = v(xyd.BUFF_SPD),
			hit = v(xyd.BUFF_HIT),
			miss = v(xyd.BUFF_MISS),
			crit = v(xyd.BUFF_CRIT),
			unCrit = v(xyd.BUFF_UNCRIT),
			critTime = v(xyd.BUFF_CRIT_TIME),
			sklP = v(xyd.BUFF_SKL_P),
			decDmg = v(xyd.BUFF_DEC_DMG),
			free = v(xyd.BUFF_FREE),
			unfree = v(xyd.BUFF_UNFREE),
			trueAtk = v(xyd.BUFF_TRUE_ATK),
			brk = v(xyd.BUFF_BRK),
			energy = v(xyd.BUFF_ENERGY),
			avoidHurt = v(xyd.BUFF_AVOID_HURT),
			healI = v(nil, xyd.BUFF_HEAL_I),
			healB = v(nil, xyd.BUFF_HEAL_B),
			allHarmDec = v(xyd.BUFF_ALL_HARM_DEC),
			zs = v(nil, "zs"),
			fs = v(nil, "fs"),
			ms = v(nil, "ms"),
			ck = v(nil, "ck"),
			yx = v(nil, "yx")
		}

		return attribs
	end

	local attribs = calculate()
	local finalEffects = {}

	for name, attr in pairs(attribs) do
		if attr > 0 then
			local effect = {
				name,
				attr
			}

			table.insert(finalEffects, effect)
		end
	end

	return finalEffects
end

return ReportPetAttr
