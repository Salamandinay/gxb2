local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityHalloweenMissionData = class("ActivityHalloweenMissionData", ActivityData, true)

function ActivityHalloweenMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityHalloweenMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_MISSION, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_MISSION, true)

		return true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_MISSION, self.defRedMark)

	return self.defRedMark
end

return ActivityHalloweenMissionData
