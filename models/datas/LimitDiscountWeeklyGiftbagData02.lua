local ActivityData = import("app.models.ActivityData")
local LimitDiscountWeeklyGiftbagData02 = class("LimitDiscountWeeklyGiftbagData02", ActivityData, true)
local json = require("cjson")

function LimitDiscountWeeklyGiftbagData02:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountWeeklyGiftbagData02:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.WEEKLY_GIFTBAG02)

	originAcivityData:onAward(event)
end

return LimitDiscountWeeklyGiftbagData02
