local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewShimoData = class("ActivityNewShimoData", ActivityData, true)

function ActivityNewShimoData:getUpdateTime()
	return self:getEndTime()
end

function ActivityNewShimoData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.defRedMark
end

function ActivityNewShimoData:isShow()
	if not self:isFunctionOnOpen() then
		return false
	end

	return xyd.checkFunctionOpen(xyd.FunctionID.PET, true)
end

return ActivityNewShimoData
