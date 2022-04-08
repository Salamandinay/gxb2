local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local NewFiveStarGiftBagData = class("NewFiveStarGiftBagData", ActivityData, true)

function NewFiveStarGiftBagData:onAward(giftBagID)
	if self.detail[1] then
		for i = 1, #self.detail do
			if self.detail[i].charge.table_id == giftBagID then
				self.detail[i].charge.buy_times = self.detail[i].charge.buy_times + 1
			end
		end

		return
	end

	if self.detail_.table_id ~= giftBagID then
		return
	end

	self.detail_.buy_times = self.detail_.buy_times + 1
end

return NewFiveStarGiftBagData
