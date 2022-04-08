local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local RingGiftbagData = class("RingGiftbagData", ActivityData, true)

function RingGiftbagData:onAward(giftbagID)
	local charges = self.detail.charges

	for i = 1, #charges do
		if charges[i].table_id == giftbagID then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
		end
	end
end

return RingGiftbagData
