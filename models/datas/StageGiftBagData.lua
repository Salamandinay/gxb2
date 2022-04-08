local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local StageGiftBagData = class("StageGiftBagData", ActivityData, true)

function StageGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	local a = self.update_time + xyd.tables.giftBagTable:getLastTime(self.detail.charge.table_id)

	return a
end

function StageGiftBagData:onAward(giftBagID)
	self.detail.charge.buy_times = self.detail.charge.buy_times + 1
end

return StageGiftBagData
