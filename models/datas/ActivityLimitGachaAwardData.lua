local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLimitGachaAwardData = class("ActivityLimitGachaAwardData", ActivityData, true)

function ActivityLimitGachaAwardData:ctor(params)
	ActivityData.ctor(self, params)

	self.redMarkState = false

	self:initRedMark()
end

function ActivityLimitGachaAwardData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLimitGachaAwardData:getMaxIndex()
	local times = self.detail.buy_times

	for i = 1, 5 do
		local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(i)

		for j = 1, #ids do
			if times[ids[j]] < xyd.tables.activityLimitExchangeAwardTable:getLimit(ids[j]) then
				return i
			end
		end
	end
end

function ActivityLimitGachaAwardData:initRedMark()
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self:getMaxIndex())
	local flag = self.defRedMark
	local lastID = xyd.tables.activityLimitExchangeAwardTable:getLastID()

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.activityLimitExchangeAwardTable:getLimit(id)

		if limit > 0 and (id ~= lastID or self:getUpdateTime() - xyd.getServerTime() < 86400) and self.detail.buy_times[id] < xyd.tables.activityLimitExchangeAwardTable:getLimit(id) then
			local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(id)

			if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				flag = true
			end
		end
	end

	self.redMarkState = flag
end

function ActivityLimitGachaAwardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.redMarkState
end

return ActivityLimitGachaAwardData
