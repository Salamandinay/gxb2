local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityRepairMissionData = class("ActivityRepairMissionData", ActivityData, true)

function ActivityRepairMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityRepairMissionData:setFirstTimeEnter(flag)
	if flag then
		self.firstTimeEnter = flag
	else
		self.firstTimeEnter = false
	end
end

function ActivityRepairMissionData:isFirstTimeEnter()
	if self.firstTimeEnter ~= nil then
		return self.firstTimeEnter
	end

	return true
end

return ActivityRepairMissionData
