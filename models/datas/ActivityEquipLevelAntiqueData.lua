local ActivityData = import("app.models.ActivityData")
local ActivityEquipLevelAntiqueData = class("ActivityEquipLevelAntiqueData", ActivityData, true)

function ActivityEquipLevelAntiqueData:getUpdateTime()
	return self:getEndTime()
end

return ActivityEquipLevelAntiqueData
