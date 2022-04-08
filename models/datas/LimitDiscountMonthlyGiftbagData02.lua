local ActivityData = import("app.models.ActivityData")
local LimitDiscountMonthlyGiftbagData02 = class("LimitDiscountMonthlyGiftbagData02", ActivityData, true)
local json = require("cjson")

function LimitDiscountMonthlyGiftbagData02:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountMonthlyGiftbagData02:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_GIFTBAG02)

	originAcivityData:onAward(event)
end

return LimitDiscountMonthlyGiftbagData02
