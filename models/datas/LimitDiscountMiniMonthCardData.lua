local ActivityData = import("app.models.ActivityData")
local LimitDiscountMiniMonthCardData = class("LimitDiscountMiniMonthCardData", ActivityData, true)
local json = require("cjson")

function LimitDiscountMiniMonthCardData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountMiniMonthCardData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD)

	originAcivityData:onAward(event)
end

return LimitDiscountMiniMonthCardData
