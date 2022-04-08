local Pet = class("Pet")

function Pet:ctor()
	self.tableID = 0
	self.lev = 0
	self.skills = {}
end

function Pet:populate(params)
	self.tableID = params.pet_id or params.petID or 0
	self.lev = params.lev or params.lv or 0
	self.petID = params.pet_id or params.petID
	self.grade = params.grade or 0
	self.skills = params.skills or {}
	self.top_grade = params.top_grade or self.grade
	self.ex_lv = params.ex_lv or 0
end

function Pet:getTopGrade()
	return self.top_grade
end

function Pet:getPetID()
	return self.petID
end

function Pet:getGrade()
	return self.grade
end

function Pet:getMaxGrade()
	return xyd.tables.petTable:getMaxGrade(self:getTableID())
end

function Pet:getPetCard()
	return xyd.tables.petTable:getPetCard(self:getTableID())
end

function Pet:getMaxLev(grade)
	return xyd.tables.petTable:getMaxlev(self:getTableID(), grade)
end

function Pet:getGradeUpCost()
	return xyd.tables.petTable:getGradeUpCost(self:getTableID(), self:getGrade() + 1)
end

function Pet:getName()
	return xyd.tables.petTable:getName(self.tableID)
end

function Pet:getLevel()
	return self.lev
end

function Pet:getTableID()
	return self.tableID
end

function Pet:getModelName()
	return xyd.tables.modelTable:getModelName(self:getModelID())
end

function Pet:getModel()
	return xyd:getEffect(self:getModelName(), self:getScale(), self:getScale())
end

function Pet:getModelID()
	local offset = self.grade > 0 and function ()
		return self.grade - 1
	end or function ()
		return 0
	end()

	return xyd.tables.petTable:getModelID(self:getTableID()) + offset
end

function Pet:getScale()
	return 1
end

function Pet:getSkillID(skillIndex)
	local ids = self:getSkillIDs()

	return ids[skillIndex + 1]
end

function Pet:getSkillIDs()
	local res = {}
	local t = xyd.tables.petTable

	table.insert(res, t:getEnergyID(self:getTableID()))

	local pasSkills = self:getPasSkillIDs()

	for i = 1, #pasSkills do
		table.insert(res, pasSkills[i])
	end

	return res
end

function Pet:getPasSkillIDs()
	local res = {}
	local t = xyd.tables.petTable

	for i = 1, 4 do
		local skillID = t:getPasSkill(self:getTableID(), i)

		if skillID and skillID ~= 0 then
			table.insert(res, skillID)
		end
	end

	return res
end

function Pet:getPasTier(i)
	return xyd.tables.petTable:getPasTier(self.tableID, i)
end

function Pet:getPugongID()
end

function Pet:getEnergyID()
	return xyd.tables.petTable:getEnergyID(self.tableID) + self:getLevel() - 1
end

function Pet:getInitMp()
	return 0
end

function Pet:getSkills()
	return self.skills
end

function Pet:getInfo()
	return {
		tableID = self.tableID,
		lev = self.lev,
		petID = self.petID,
		grade = self.grade,
		skills = self.skills
	}
end

function Pet:getExLv()
	return self.ex_lv
end

function Pet:getScore()
	local tmp = 0
	local params = xyd.tables.miscTable:split2Cost("pet_training_pet_atk", "value", "|")

	for i = 1, #self.skills do
		tmp = tmp + self.skills[i] * params[3]
	end

	return self.lev * params[1] + self.ex_lv * params[2] + tmp
end

return Pet
