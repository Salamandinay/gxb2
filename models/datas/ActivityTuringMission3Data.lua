local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTuringMission3Data = class("ActivityTuringMission3Data", ActivityData, true)

function ActivityTuringMission3Data:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityTuringMission3Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	if self:isFirstRedMark() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TURING_MISSION3, flag)

	return flag
end

return ActivityTuringMission3Data
