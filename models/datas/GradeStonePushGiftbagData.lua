local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GradeStonePushGiftbagData = class("GradeStonePushGiftbagData", ActivityData, true)

function GradeStonePushGiftbagData:onAward(giftBagID)
	if self.detail.table_id == giftBagID then
		self.detail.buy_times = self.detail.buy_times + 1
	end
end

return GradeStonePushGiftbagData
