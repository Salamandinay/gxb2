local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTuringMission4Data = class("ActivityTuringMission4Data", ActivityData, true)

function ActivityTuringMission4Data:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityTuringMission4Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	if self:isFirstRedMark() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TURING_MISSION4, flag)

	return flag
end

return ActivityTuringMission4Data
