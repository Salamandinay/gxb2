local ActivityData = import("app.models.ActivityData")
local LimitDiscountdailyGiftbagData02 = class("LimitDiscountdailyGiftbagData02", ActivityData, true)
local json = require("cjson")

function LimitDiscountdailyGiftbagData02:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountdailyGiftbagData02:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.DAILY_GIFGBAG02)

	originAcivityData:onAward(event)
end

return LimitDiscountdailyGiftbagData02
