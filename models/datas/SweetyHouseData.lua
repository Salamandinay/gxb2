local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SweetyHouseData = class("SweetyHouseData", ActivityData, true)

function SweetyHouseData:setChoose(id)
	table.insert(SweetyHouseData.choose_queue, id)
end

function SweetyHouseData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function SweetyHouseData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityHouseTable:getIDs()

	for i = 1, #ids do
		if self.detail.buy_times[i] < xyd.tables.activityHouseTable:getLimit(ids[i]) then
			return self.defRedMark
		end
	end

	return false
end

function SweetyHouseData:onAward(event)
	while #SweetyHouseData.choose_queue > 0 do
		self.detail.buy_times[SweetyHouseData.choose_queue[1]] = self.detail.buy_times[SweetyHouseData.choose_queue[1]] + 1

		xyd.tableSlice(SweetyHouseData.choose_queue, 0, 1)
	end
end

SweetyHouseData.choose_queue = {}

return SweetyHouseData
