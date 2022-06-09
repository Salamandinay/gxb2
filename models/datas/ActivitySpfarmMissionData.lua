local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySpfarmMissionData = class("ActivitySpfarmMissionData", ActivityData, true)

function ActivitySpfarmMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpfarmMissionData:getRedMarkState()
	local function check()
		if not self:isFunctionOnOpen() then
			return false
		end

		local timeDays = xyd.db.misc:getValue("activity_space_explore_mission")

		if timeDays == nil then
			return true
		else
			local startTime = self:startTime()
			local passedTotalTime = xyd.getServerTime() - startTime
			local dayRound = math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)

			if dayRound ~= tonumber(timeDays) and xyd.getServerTime() < self:getEndTime() then
				return true
			else
				return false
			end
		end

		return false
	end

	local flag = check()

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SPFARM_MISSION, flag)

	return flag
end

return ActivitySpfarmMissionData
