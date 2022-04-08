local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local BenefitGiftbag02Data = class("BenefitGiftbag02Data", ActivityData, true)

function BenefitGiftbag02Data:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function BenefitGiftbag02Data:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function BenefitGiftbag02Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityTable:getGiftBag(self.id)

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.giftBagTable:getBuyLimit(id)

		if self.detail.charges[i].buy_times < limit then
			return self.defRedMark
		end
	end

	return false
end

return BenefitGiftbag02Data
