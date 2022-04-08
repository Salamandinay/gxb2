local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NineStarGiftBag1Data = class("NineStarGiftBag1Data", ActivityData, true)

function NineStarGiftBag1Data:onAward(giftBagID)
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

return NineStarGiftBag1Data
