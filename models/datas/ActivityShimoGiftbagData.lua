local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityShimoGiftbagData = class("ActivityShimoGiftbagData", ActivityData, true)

function ActivityShimoGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityShimoGiftbagData:isShow()
	if not self:isFunctionOnOpen() then
		return false
	end

	return xyd.checkFunctionOpen(xyd.FunctionID.PET, true)
end

return ActivityShimoGiftbagData
