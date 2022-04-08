local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityRechargeData = class("ActivityRechargeData", ActivityData, true)

function ActivityRechargeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityRechargeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not xyd.db.misc:getValue("activity_recharge_first") then
		return true
	end

	return self.defRedMark
end

return ActivityRechargeData
