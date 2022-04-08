local ActivityData = import("app.models.ActivityData")
local LimitDiscountdailyGiftbagData = class("LimitDiscountdailyGiftbagData", ActivityData, true)
local json = require("cjson")

function LimitDiscountdailyGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountdailyGiftbagData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.DAILY_GIFGBAG)

	originAcivityData:onAward(event)
end

return LimitDiscountdailyGiftbagData
