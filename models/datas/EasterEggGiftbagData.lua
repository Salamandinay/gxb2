local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local EasterEggGiftbagData = class("EasterEggGiftbagData", ActivityData, true)

function EasterEggGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function EasterEggGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

return EasterEggGiftbagData
