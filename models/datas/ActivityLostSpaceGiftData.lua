local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLostSpaceGiftData = class("ActivityLostSpaceGiftData", ActivityData, true)

function ActivityLostSpaceGiftData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityLostSpaceGiftData:onAward()
	self.detail.charges[1].buy_times = self.detail.charges[1].buy_times + 1
end

function ActivityLostSpaceGiftData:checkBuy()
	return self.detail.charges[1].buy_times >= 1
end

function ActivityLostSpaceGiftData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
	end

	return self.defRedMark
end

return ActivityLostSpaceGiftData
