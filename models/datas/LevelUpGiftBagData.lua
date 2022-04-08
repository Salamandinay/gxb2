local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local LevelUpGiftBagData = class("LevelUpGiftBagData", GiftBagData, true)

function LevelUpGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.giftBagTable:getLastTime(self.detail.charge.table_id)
end

function LevelUpGiftBagData:onAward(giftBagID)
	self.detail.charge.buy_times = self.detail.charge.buy_times + 1
end

return LevelUpGiftBagData
