local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTripleFirstChargeData = class("ActivityTripleFirstChargeData", ActivityData, true)

function ActivityTripleFirstChargeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTripleFirstChargeData:getRedMarkState()
	return false
end

return ActivityTripleFirstChargeData
