local Partner = import(".Partner")
local Monster = class("Monster", Partner)

function Monster:ctor(...)
	Monster.super.ctor(self, ...)

	self.partnerLink_ = 0
	self.isMonster_ = true
end

function Monster:populateWithTableID(tableID, params)
	params = params or {}
	self.tableID = tableID
	self.star = params.star or 0
	self.lev = params.lev or params.lv or xyd.tables.monsterTable:getLv(tableID)
	self.partnerID = params.partner_id or params.partnerID
	self.equipments = params.equips or params.equipments or {}
	self.grade = params.grade or xyd.tables.monsterTable:getGrade(tableID)
	self.awake = params.awake or 0
	self.lockFlags = params.flags or params.lockFlags
	self.isHeroBook_ = params.isHeroBook or false
	self.showSkin = params.show_skin == nil and 1 or params.show_skin
	self.tmp_treasure_ = params.tmp_treasure
	self.showID = params.show_id
	self.love_point = params.love_point or params.lovePoint or 0
	self.last_love_point_time = params.last_love_point_time or 0
	self.guaji_love_point = params.guaji_love_point or 0
	self.is_vowed = params.is_vowed or 0
	self.wedding_date = params.wedding_date or 0
	self.partnerLink_ = xyd.tables.monsterTable:getPartnerLink(tableID)
	self.exSkills = params.ex_skills or xyd.tables.monsterTable:getExSkills(tableID)

	self:updateAttrs()
end

function Monster:initStar()
	self.star = xyd.tables.partnerTable:getStar(self:getHeroTableID()) + self.awake
end

function Monster:getHeroTableID()
	if self:isMonster() then
		return self:getPartnerLink()
	end

	return self:getTableID()
end

function Monster:getPartnerLink()
	return self.partnerLink_
end

function Monster:isMonster()
	return self.isMonster_
end

function Monster:getSkillIDs()
	local res = {}
	local mytable = xyd.tables.partnerTable

	table.insert(res, mytable:getEnergyID(self:getHeroTableID()))

	for i = 1, 3 do
		local skillID = mytable:getPasSkill(self:getHeroTableID(), i)

		if skillID then
			table.insert(res, mytable:getPasSkill(self:getHeroTableID(), i))
		end
	end

	return res
end

function Monster:getName()
	return xyd.tables.partnerTable:getName(self:getHeroTableID())
end

function Monster:getGroup()
	return xyd.tables.partnerTable:getGroup(self:getHeroTableID())
end

function Monster:getModelName()
	return xyd.tables.partnerTable:getModelName(self:getHeroTableID())
end

function Monster:getModelID()
	return xyd.tables.partnerTable:getModelID(self:getHeroTableID())
end

function Monster:getJob()
	return xyd.tables.partnerTable:getJob(self:getHeroTableID())
end

function Monster:getStar()
	return xyd.tables.partnerTable:getStar(self:getHeroTableID())
end

function Monster:getMaxGrade()
	return xyd.tables.partnerTable:getMaxGrade(self:getHeroTableID())
end

function Monster:getInfo()
	local info = Partner.getInfo(self)
	info.tableID = self:getHeroTableID()

	return info
end

function Monster:getPasSkill()
	local awake = self:getAwake()
	local awakeSkill = {}
	local tableID = self:getHeroTableID()

	if awake and awake ~= 0 and awake < 6 then
		local awakeSkills = xyd.tables.partnerTable:awakeSkill(tableID)
		awakeSkill = xyd:split(awakeSkills[awake], "#", true)
	end

	local skills = {}

	for i = 1, 3 do
		local pasTier = xyd.tables.partnerTable:getPasTier(tableID, i)

		if pasTier <= self:getGrade() then
			local skill = nil

			if awake and awake ~= 0 and awake < 6 then
				skill = awakeSkill[i + 1]
			else
				skill = xyd.tables.partnerTable:getPasSkill(tableID, i)
			end

			if skill > 0 then
				local subSkills = xyd.tables.skillTable:getSubSkills(skill)

				if #subSkills > 0 then
					table.insertto(skills, subSkills)
				end
			end
		end
	end

	local potentials = self:getPotential() or {}
	local skillPotentials = xyd.tables.partnerTable:getPotential(tableID)

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

return Monster
