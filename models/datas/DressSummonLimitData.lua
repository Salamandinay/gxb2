local ActivityData = import("app.models.ActivityData")
local DressSummonLimitData = class("DressSummonLimitData", ActivityData, true)

function DressSummonLimitData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function DressSummonLimitData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

return DressSummonLimitData
