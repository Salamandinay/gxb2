local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmas2Data = class("ActivityChristmas2Data", ActivityData, true)

function ActivityChristmas2Data:setChoose(id)
	table.insert(ActivityChristmas2Data.choose_queue, id)
end

function ActivityChristmas2Data:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityChristmas2Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local table_ = xyd.tables.activityFestivalTableInFile2
	local ids = table_:getIDs()
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHRISTMAS_SNOW_MAN)
	local flag = false

	for i = 1, #ids do
		if self.detail.buy_times[i] == 0 then
			flag = true
			local cost = table_:getCost(ids[i])

			if cost[1] < num then
				return true
			else
				return self.defRedMark
			end
		end
	end

	if not flag then
		self:setDefRedMark(false)
	end

	return self.defRedMark
end

function ActivityChristmas2Data:onAward(event)
	while #ActivityChristmas2Data.choose_queue > 0 do
		self.detail.buy_times[ActivityChristmas2Data.choose_queue[1]] = self.detail.buy_times[ActivityChristmas2Data.choose_queue[1]] + 1

		xyd.tableSlice(ActivityChristmas2Data.choose_queue, 0, 1)
	end
end

ActivityChristmas2Data.choose_queue = {}

return ActivityChristmas2Data
