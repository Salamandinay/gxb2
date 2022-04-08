local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local BenefitGiftbagData = class("BenefitGiftbagData", ActivityData, true)

function BenefitGiftbagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function BenefitGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function BenefitGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local limit = xyd.tables.giftBagTable:getBuyLimit(xyd.tables.activityTable:getGiftBag(self.id)) or 0

	if limit <= self.detail.charges[1].buy_times then
		return false
	end

	return self.defRedMark
end

return BenefitGiftbagData
