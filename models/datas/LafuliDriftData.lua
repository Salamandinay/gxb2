local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local LafuliDriftData = class("LafuliDriftData", ActivityData, true)

function LafuliDriftData:ctor(params)
	ActivityData.ctor(self, params)

	self.redMarkState = self.defRedMark

	self:initRedMark()
end

function LafuliDriftData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function LafuliDriftData:initRedMark()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.LAFULI_SIMPLE_DICE) > 0 then
		self.redMarkState = true
	end
end

function LafuliDriftData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.redMarkState
end

return LafuliDriftData
