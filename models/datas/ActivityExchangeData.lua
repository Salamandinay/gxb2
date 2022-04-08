local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityExchangeData = class("ActivityExchangeData", ActivityData, true)

function ActivityExchangeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityExchangeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not xyd.db.misc:getValue("activity_exchange_first") then
		return true
	end

	return self.defRedMark
end

return ActivityExchangeData
