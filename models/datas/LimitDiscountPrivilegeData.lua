local ActivityData = import("app.models.ActivityData")
local LimitDiscountPrivilegeData = class("LimitDiscountPrivilegeData", ActivityData, true)
local json = require("cjson")

function LimitDiscountPrivilegeData:getUpdateTime()
	return self:getEndTime()
end

function LimitDiscountPrivilegeData:onAward(event)
	local originAcivityData = xyd.models.activity:getActivity(xyd.ActivityID.PRIVILEGE_CARD)

	originAcivityData:onAward(event)
end

return LimitDiscountPrivilegeData
