local ActivityData = import("app.models.ActivityData")
local LimitDiscountWeeklyGiftbagData = class("LimitDiscountWeeklyGiftbagData", ActivityData, true)
local json = require("cjson")

function LimitDiscountWeeklyGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountWeeklyGiftbagData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.WEEKLY_GIFTBAG)

	originAcivityData:onAward(event)
end

return LimitDiscountWeeklyGiftbagData
