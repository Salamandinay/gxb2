local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTimeGiftbagData = class("ActivityTimeGiftbagData", ActivityData, true)

function ActivityTimeGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTimeGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function ActivityTimeGiftbagData:updateCrystalInfo(buy_times)
	dump(self.detail_, "================buy times")

	self.detail_.detail.buy_times = buy_times
end

return ActivityTimeGiftbagData
