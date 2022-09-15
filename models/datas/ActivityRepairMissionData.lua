local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityRepairMissionData = class("ActivityRepairMissionData", ActivityData, true)

function ActivityRepairMissionData:getUpdateTime()
	return self:getEndTime()
end

return ActivityRepairMissionData
