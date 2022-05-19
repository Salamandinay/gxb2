local ActivityData = import("app.models.ActivityData")
local NewPartnerWarmupGiftbagData = class("NewPartnerWarmupGiftbagData", ActivityData, true)

function NewPartnerWarmupGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function NewPartnerWarmupGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function NewPartnerWarmupGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.NEW_PARTNER_WARMUP_ACTIVITIES, self.defRedMark)

	return self.defRedMark
end

return NewPartnerWarmupGiftbagData
