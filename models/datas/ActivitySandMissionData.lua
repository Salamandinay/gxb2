local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySandMissionData = class("ActivitySandMissionData", ActivityData, true)

function ActivitySandMissionData:ctor(params)
	ActivitySandMissionData.super.ctor(self, params)
end

function ActivitySandMissionData:turnToDummy()
	local reTargetParams = {
		detail = "{\"update_time\":1870517120,\"finish_counts\":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],\"paid_awarded\":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],\"awarded\":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],\"values\":[2,1,3,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}"
	}

	self:setData(reTargetParams)
end

function ActivitySandMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySandMissionData:getValue(i)
	return self.detail.values[i]
end

function ActivitySandMissionData:getRedMarkState()
	local function check()
		if not self:isFunctionOnOpen() then
			return false
		end

		local cachedDayTime = xyd.db.misc:getValue("daytime_interval_between_most_recently_click_and_event_begin_of_activity_sand_mission")

		if cachedDayTime == nil then
			return true
		else
			local dayRound = self:getPassedDayRound()

			if dayRound ~= tonumber(cachedDayTime) and xyd.getServerTime() < self:getEndTime() then
				return true
			else
				return false
			end
		end

		return false
	end

	local flag = check()

	return flag
end

return ActivitySandMissionData
