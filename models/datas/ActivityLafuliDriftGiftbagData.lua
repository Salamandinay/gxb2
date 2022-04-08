local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLafuliDriftGiftbagData = class("ActivityLafuliDriftGiftbagData", ActivityData, true)

function ActivityLafuliDriftGiftbagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityLafuliDriftGiftbagData:onAward()
	self.detail.charges[1].buy_times = self.detail.charges[1].buy_times + 1
end

function ActivityLafuliDriftGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_LAFULI_GIFTBAG, self.defRedMark)

	return self.defRedMark
end

return ActivityLafuliDriftGiftbagData
