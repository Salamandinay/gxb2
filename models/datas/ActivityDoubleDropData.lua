local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityDoubleDropData = class("ActivityDoubleDropData", ActivityData, true)

function ActivityDoubleDropData:ctor(params)
	ActivityData.ctor(self, params)
end

function ActivityDoubleDropData:getUpdateTime()
	return self:getEndTime()
end

return ActivityDoubleDropData
