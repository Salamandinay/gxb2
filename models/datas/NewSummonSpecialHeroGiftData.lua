local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local NewSummonSpecialHeroGiftData = class("NewSummonSpecialHeroGiftData", GiftBagData, true)

function NewSummonSpecialHeroGiftData:getUpdateTime()
	if self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

return NewSummonSpecialHeroGiftData
