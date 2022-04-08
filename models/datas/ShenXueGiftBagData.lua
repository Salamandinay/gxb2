local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ShenXueGiftBagData = class("ShenXueGiftBagData", ActivityData, true)

function ShenXueGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ShenXueGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, #self.detail.times do
		if self.detail.times[i] ~= xyd.tables.activityComposeTable:getLimit(i + 1) then
			return self.defRedMark
		end
	end

	return false
end

return ShenXueGiftBagData
