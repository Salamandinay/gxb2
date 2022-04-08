Hero = {
	name = "Hero",
	__index = Hero,
	prototype = {}
}
Hero.prototype.__index = Hero.prototype
Hero.prototype.constructor = Hero

function Hero.new(...)
	local self = setmetatable({}, Hero.prototype)

	self:____constructor(...)

	return self
end

function Hero.prototype:____constructor()
	self.tableID = 0
	self.star = 0
	self.lev = 0
	self.color = 0
	self.addHurID = nil
	self.pos = 0
end

function Hero.prototype:populate(params)
	self.tableID = params.table_id or 0
	self.star = params.star or 0
	self.lev = params.lev or 0
	self.color = params.color or 0
end

function Hero.prototype:getName()
	return PartnerTable:get():getName(self.tableID)
end

function Hero.prototype:getLevel()
	return self.lev
end

function Hero.prototype:getGroup()
	return PartnerTable:get():getGroup(self.tableID)
end

function Hero.prototype:getTableID()
	return self.tableID
end

function Hero.prototype:getShowInGuide()
	return PartnerTable:get():getShowInGuide(self.tableID)
end

function Hero.prototype:getModelName()
	return PartnerTable:get():getModelName(self.tableID)
end

function Hero.prototype:getModel()
	return xyd:getEffect(self:getModelName(), self:getScale(), self:getScale())
end

function Hero.prototype:getModelID()
	return PartnerTable:get():getModelID(self:getTableID())
end

function Hero.prototype:getScale()
	return 0.8
end

function Hero.prototype:getSkillID(skillIndex)
end

function Hero.prototype:getPugongID()
	return PartnerTable:get():getPugongID(self.tableID)
end

function Hero.prototype:getEnergyID()
	return PartnerTable:get():getEnergyID(self.tableID)
end

function Hero.prototype:getInitMp()
	return PartnerTable:get():getInitMp(self.tableID)
end

function Hero.prototype:getAddHurtID()
	if self.addHurID == nil then
		self.addHurID = 0
		local i = 0

		while i < 3 do
			local pasSkill = PartnerTable:get():getPasSkill(self.tableID, i + 1)

			if pasSkill > 0 then
				local effects = SkillTable:get():getEffects(pasSkill)
				local j = 0

				while j < effects.length do
					local effect = effects[j]

					if EffectTable:get():getType(effect) == xyd.BUFF_ADD_HURT then
						self.addHurID = pasSkill

						break
					end

					j = j + 1
				end
			end

			i = i + 1
		end
	end

	return self.addHurID
end
