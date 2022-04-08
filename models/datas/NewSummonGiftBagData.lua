local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local NewSummonGiftBagData = class("NewSummonGiftBagData", GiftBagData, true)

function NewSummonGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewSummonGiftBagData:getRedMarkState()
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

return NewSummonGiftBagData
