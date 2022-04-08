local ActivityData = import("app.models.ActivityData")
local LimitDiscountMonthlyGiftbagData = class("LimitDiscountMonthlyGiftbagData", ActivityData, true)
local json = require("cjson")

function LimitDiscountMonthlyGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountMonthlyGiftbagData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_GIFTBAG)

	originAcivityData:onAward(event)
end

return LimitDiscountMonthlyGiftbagData
