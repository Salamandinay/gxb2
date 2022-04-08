local ActivityData = import("app.models.ActivityData")
local ActivityFireworkAwardData = class("ActivityFireworkAwardData", ActivityData, true)

function ActivityFireworkAwardData:getUpdateTime()
	local fireworkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FIREWORK)

	if fireworkData then
		return fireworkData:getEndTime()
	end

	return self:getEndTime()
end

function ActivityFireworkAwardData:getEndTime()
	local fireworkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FIREWORK)

	if fireworkData then
		return fireworkData:getEndTime()
	end

	return ActivityFireworkAwardData.super.getEndTime(self)
end

function ActivityFireworkAwardData:getRound()
	local fireworkData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FIREWORK)

	if fireworkData then
		return fireworkData.detail.round
	end

	return 0
end

return ActivityFireworkAwardData
