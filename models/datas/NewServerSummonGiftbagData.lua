local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewServerSummonGiftbagData = class("NewServerSummonGiftbagData", ActivityData, true)

function NewServerSummonGiftbagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewServerSummonGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local maxPoint = xyd.tables.activityGachaTable:getMaxPoint()
	local isCompleted = maxPoint <= self.detail.point

	if not isCompleted then
		return self.defRedMark
	end

	return false
end

return NewServerSummonGiftbagData
