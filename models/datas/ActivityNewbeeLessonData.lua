local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewbeeLessonData = class("ActivityNewbeeLessonData", ActivityData, true)

function ActivityNewbeeLessonData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local startTime = self.detail_.start_time
	local curDay = math.ceil((xyd.getServerTime() - startTime) / 86400)
	curDay = math.max(curDay, 1)
	curDay = math.min(curDay, 14)
	local dayMisson = xyd.tables.activityNewbeeLessonTable:getDailyMissionByDay(curDay)

	if not dayMisson then
		return flag
	end

	for _, tableId in ipairs(dayMisson) do
		if self.detail_.awards[tableId] == 0 and self.detail_.is_completeds[tableId] == 1 then
			flag = true

			break
		end
	end

	if not flag then
		for i = 19, 20 do
			local taskList = xyd.tables.activityNewbeeLessonTable:getAccumulateTaskByType(i)

			for _, tableId in ipairs(taskList) do
				if self.detail_.awards[tableId] == 0 and self.detail_.is_completeds[tableId] == 1 then
					flag = true

					break
				end
			end

			if flag then
				break
			end
		end
	end

	return flag
end

function ActivityNewbeeLessonData:getUpdateTime()
	return self.detail_.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityNewbeeLessonData:onAward(data)
	self.detail_ = json.decode(data.detail).info

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_LEESON, function ()
	end)
end

return ActivityNewbeeLessonData
