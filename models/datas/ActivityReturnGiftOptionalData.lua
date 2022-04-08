local ActivityData = import("app.models.ActivityData")
local ActivityReturnGiftOptionalData = class("ActivityReturnGiftOptionalData", ActivityData, true)

function ActivityReturnGiftOptionalData:ctor(params)
	ActivityReturnGiftOptionalData.super.ctor(self, params)
end

function ActivityReturnGiftOptionalData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function ActivityReturnGiftOptionalData:onAward(tableId)
	local charges = self.detail_.charges

	for _, chargeInfo in pairs(charges) do
		if tableId == chargeInfo.table_id then
			chargeInfo.buy_times = chargeInfo.buy_times + 1
		end
	end
end

return ActivityReturnGiftOptionalData
