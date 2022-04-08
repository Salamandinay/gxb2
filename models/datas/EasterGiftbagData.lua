local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local EasterGiftbagData = class("EasterGiftbagData", ActivityData, true)

function EasterGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function EasterGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function EasterGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

return EasterGiftbagData
