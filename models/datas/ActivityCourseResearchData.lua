local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityCourseResearchData = class("ActivityCourseResearchData", ActivityData, true)

function ActivityCourseResearchData:getUpdateTime()
	return self.detail.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityCourseResearchData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local progress = self.detail.progress
	local treuProgress = 0

	if progress < xyd.tables.activityCourseLearningTable:getLastLevel() then
		treuProgress = math.floor((progress - math.min(self.detail.round, xyd.tables.activityCourseLearningTable:getLastLevel() - 1)) * 1000 + 0.5) / 1000
	else
		treuProgress = 1
	end

	if treuProgress < 1 then
		return false
	else
		return true
	end
end

return ActivityCourseResearchData
