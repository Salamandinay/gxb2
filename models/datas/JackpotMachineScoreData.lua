local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local JackpotMachineScoreData = class("JackpotMachineScoreData", ActivityData, true)

function JackpotMachineScoreData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function JackpotMachineScoreData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityTreeTable:getIDs()

	for i = 1, #ids do
		if self.detail.point < xyd.tables.activityGambleTable:getPoint(ids[i]) then
			return self.defRedMark
		end
	end

	return false
end

return JackpotMachineScoreData
