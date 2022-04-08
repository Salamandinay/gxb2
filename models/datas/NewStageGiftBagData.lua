local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local NewStageGiftBagData = class("NewStageGiftBagData", ActivityData, true)

function NewStageGiftBagData:onAward(giftBagID)
	self.detail[1].charge.buy_times = self.detail[1].charge.buy_times + 1
end

function NewStageGiftBagData:getUpdateTime()
	return self.detail[1].update_time + xyd.tables.giftBagTable:getLastTime(self.detail[1].charge.table_id)
end

return NewStageGiftBagData
