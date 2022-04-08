local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local DoubleRingGiftbagData = class("DoubleRingGiftbagData", ActivityData, true)

function DoubleRingGiftbagData:onAward(giftbagID)
	local charges = self.detail.charges

	for i = 1, #charges do
		if charges[i].table_id == giftbagID then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
		end
	end
end

function DoubleRingGiftbagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function DoubleRingGiftbagData:backRank()
	return self.detail.charges[1].buy_times >= 1
end

return DoubleRingGiftbagData
