local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = class("GiftBagData", ActivityData, true)

function GiftBagData:getGiftBagData(giftBagID)
	for i = 1, #self.detail_.charges do
		local data = self.detail_.charges[i]

		if giftBagID == data.table_id then
			return data
		end
	end

	return nil
end

return GiftBagData
