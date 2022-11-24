local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGiftbagThreeFiveZeroData = class("ActivityGiftbagThreeFiveZeroData", ActivityData, true)

function ActivityGiftbagThreeFiveZeroData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGiftbagThreeFiveZeroData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function ActivityGiftbagThreeFiveZeroData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_GIFTBAG, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_GIFTBAG, true)

		return true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN_GIFTBAG, self.defRedMark)

	return self.defRedMark
end

return ActivityGiftbagThreeFiveZeroData
