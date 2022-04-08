local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEnergySummonData = class("ActivityEnergySummonData", ActivityData, true)

function ActivityEnergySummonData:getUpdateTime()
	return self:getEndTime()
end

function ActivityEnergySummonData:onAward(data)
	if type(data) == "number" then
		local giftBagID = data

		for i = 1, #self.detail_.charges do
			if self.detail_.charges[i].table_id == giftBagID then
				self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

				break
			end
		end

		self.detail_.detail.point1 = self.detail_.detail.point1 + self.detail_.detail.point2

		return
	else
		local detail = json.decode(data.detail)

		if detail then
			local info = detail.info
			local items = detail.items
			local Partner = import("app.models.Partner")

			if items and #items > 0 then
				local partnerData = items[1]
				local partner = Partner.new()

				partner:populate(partnerData)
				xyd.models.slot:addPartners({
					partner
				})
			end
		end
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ENERGY_SUMMON, function ()
		local detail = json.decode(data.detail)
		self.detail_.detail = detail.info
	end)
end

function ActivityEnergySummonData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local TodayVisit = tonumber(xyd.db.misc:getValue("activity_energy_summon_info_btn"))

	if TodayVisit == nil then
		TodayVisit = 0
	end

	if self:getLimitEnergy() <= self:getEnergy() and TodayVisit < self:getEndTime() - 1 then
		return true
	end

	local lastLoginTime = xyd.db.misc:getValue("activity_energy_summon")

	if lastLoginTime == nil then
		return true
	else
		return false
	end
end

function ActivityEnergySummonData:getLimitDraw()
	local limit = xyd.tables.miscTable:split2num("act_summon_energy_limit", "value", "|")

	return limit[2]
end

function ActivityEnergySummonData:getLimitEnergy()
	local limit = xyd.tables.miscTable:getNumber("act_summon_energy_cost", "value")

	return limit
end

function ActivityEnergySummonData:getEnergy()
	return self.detail_.detail.point1
end

function ActivityEnergySummonData:getAwarded()
	return self.detail_.detail.awards
end

function ActivityEnergySummonData:getDrawTimes()
	return self.detail_.detail.summon_times
end

function ActivityEnergySummonData:getSummonTimes()
	local factor = self.detail_.charges[1].buy_times
	local getNum = xyd.tables.miscTable:split2num("act_summon_energy_num", "value", "|")
	local point = self.detail_.detail.summon_times * (getNum[1] + getNum[2] * factor)
	local times = math.floor((point - self:getEnergy()) / self:getLimitEnergy())

	return times
end

function ActivityEnergySummonData:getExEnergy()
	local getNum = xyd.tables.miscTable:split2num("act_summon_energy_num", "value", "|")[2]

	return self.detail_.detail.summon_times * getNum
end

return ActivityEnergySummonData
