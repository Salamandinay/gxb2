local ActivityData = import("app.models.ActivityData")
local LimitDiscountMonthCardData = class("LimitDiscountMonthCardData", ActivityData, true)
local json = require("cjson")

function LimitDiscountMonthCardData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountMonthCardData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)

	originAcivityData:onAward(event)
end

return LimitDiscountMonthCardData
