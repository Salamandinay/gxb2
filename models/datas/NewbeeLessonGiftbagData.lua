local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewbeeLessonGiftbagData = class("NewbeeLessonGiftbagData", ActivityData, true)

function NewbeeLessonGiftbagData:getUpdateTime()
	return xyd.getDayStartTime(self.detail_.start_time) + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewbeeLessonGiftbagData:onAward(data)
	for _, item in ipairs(self.detail_.charges) do
		if item.table_id == data then
			item.buy_times = item.buy_times + 1

			break
		end
	end
end

function NewbeeLessonGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local time = xyd.db.misc:getValue("newbee_lesson_giftbag")

	if time and xyd.isToday(tonumber(time)) then
		return false
	else
		return true
	end
end

return NewbeeLessonGiftbagData
