local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTuringMissionData = class("ActivityTuringMissionData", ActivityData, true)

function ActivityTuringMissionData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityTuringMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	if self:isFirstRedMark() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.TURING_MISSION, flag)

	return flag
end

return ActivityTuringMissionData
