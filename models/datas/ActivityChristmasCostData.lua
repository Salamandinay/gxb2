local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmasCostData = class("ActivityChristmasCostData", ActivityData, true)

function ActivityChristmasCostData:getUpdateTime()
	return self:getEndTime()
end

return ActivityChristmasCostData
