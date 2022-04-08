local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local LimitFiveStarGiftBagData = class("LimitFiveStarGiftBagData", ActivityData, true)

function LimitFiveStarGiftBagData:onAward(giftBagID)
	self.detail.buy_times = self.detail.buy_times + 1
end

function LimitFiveStarGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.TimePeriod.WEEK_TIME
end

return LimitFiveStarGiftBagData
