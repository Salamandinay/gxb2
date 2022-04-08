local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local PromotionGiftbagData = class("PromotionGiftbagData", ActivityData, true)

function PromotionGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function PromotionGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local charges = self.detail_.charges

	for i = 1, #charges do
		local buyTimes = tonumber(charges[i].buy_times)
		local limitTimes = tonumber(charges[i].limit_times)

		if buyTimes < limitTimes then
			return self.defRedMark
		end
	end

	return false
end

function PromotionGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

return PromotionGiftbagData
