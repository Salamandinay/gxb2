local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local FavorabilityData = class("FavorabilityData", ActivityData, true)

function FavorabilityData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function FavorabilityData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, #self.detail.is_completes do
		if self.detail.is_completes[i] ~= xyd.tables.activityLovePointTable:getLimit(i + 1) then
			return self.defRedMark
		end
	end

	return false
end

return FavorabilityData
