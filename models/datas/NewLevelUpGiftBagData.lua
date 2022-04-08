local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local NewLevelUpGiftBagData = class("NewLevelUpGiftBagData", ActivityData, true)

function NewLevelUpGiftBagData:onAward(giftBagID)
	if self.detail[1] then
		for i = 1, #self.detail do
			if self.detail[i].charge.table_id == giftBagID then
				self.detail[i].charge.buy_times = self.detail[i].charge.buy_times + 1
			end
		end

		return
	end

	for i = 1, #self.detail_.charge do
		if self.detail_.charge[i].table_id == giftBagID then
			self.detail_.charge[i].buy_times = self.detail_.charge[i].buy_times + 1
		end
	end
end

return NewLevelUpGiftBagData
