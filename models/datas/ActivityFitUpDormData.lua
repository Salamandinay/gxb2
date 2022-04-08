local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFitUpDormData = class("ActivityFitUpDormData", ActivityData, true)

function ActivityFitUpDormData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityFitUpDormData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local i = 1

	while i <= 3 do
		local awarded = self.detail["awarded_" .. tostring(i)]
		local j = 0

		while j < #awarded do
			local award = awarded[j]

			if award == 0 then
				local cost = xyd.tables.activityFitUpDormTable:getCost(i, j + 1)
				local selfNum = xyd.models.backpack:getItemNumByID(cost[0])

				if cost[1] < selfNum then
					flag = true

					break
				end
			end

			j = j + 1
		end

		i = i + 1
	end

	if flag then
		return flag
	end

	return self.defRedMark
end

function ActivityFitUpDormData:onAward(data)
	local details = json.decode(data.detail)

	if details.awarded_2 then
		self.detail_.awarded_2 = xyd.split(details.awarded_2, "|", true)
	end

	if details.awarded_1 then
		self.detail_.awarded_1 = xyd.split(details.awarded_1, "|", true)
	end

	if details.awarded_3 then
		self.detail_.awarded_3 = xyd.split(details.awarded_3, "|", true)
	end
end

return ActivityFitUpDormData
