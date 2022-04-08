local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local FiveStarGiftData = class("FiveStarGiftData", GiftBagData, true)

function FiveStarGiftData:onAward(giftBagID)
	self.detail.buy_times = self.detail.buy_times + 1
end

function FiveStarGiftData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	local a = self.update_time + xyd.tables.giftBagTable:getLastTime(self.detail.table_id)

	return a
end

return FiveStarGiftData
