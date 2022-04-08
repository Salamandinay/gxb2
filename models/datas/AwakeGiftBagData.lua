local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local AwakeGiftBagData = class("AwakeGiftBagData", ActivityData, true)

function AwakeGiftBagData:getUpdateTime()
	return self:getEndTime()
end

function AwakeGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, #self.detail.times do
		if self.detail.times[i] ~= xyd.tables.activityCompose10Table:getLimit(i + 1) then
			return self.defRedMark
		end
	end

	return false
end

return AwakeGiftBagData
