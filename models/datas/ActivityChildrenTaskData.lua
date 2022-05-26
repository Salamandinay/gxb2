local ActivityData = import("app.models.ActivityData")
local ActivityChildrenTaskData = class("ActivityChildrenTaskData", ActivityData, true)

function ActivityChildrenTaskData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChildrenTaskData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	return false
end

return ActivityChildrenTaskData
