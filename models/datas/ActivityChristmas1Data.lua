local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmas1Data = class("ActivityChristmas1Data", ActivityData, true)

function ActivityChristmas1Data:setChoose(id)
	table.insert(ActivityChristmas1Data.choose_queue, id)
end

function ActivityChristmas1Data:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityChristmas1Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local table_ = xyd.tables.activityFestivalTableInFile1
	local ids = table_:getIDs()
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHRISTMAS_SOCK)
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

function ActivityChristmas1Data:onAward(event)
	while #ActivityChristmas1Data.choose_queue > 0 do
		self.detail.buy_times[ActivityChristmas1Data.choose_queue[1]] = self.detail.buy_times[ActivityChristmas1Data.choose_queue[1]] + 1

		xyd.tableSlice(ActivityChristmas1Data.choose_queue, 0, 1)
	end
end

ActivityChristmas1Data.choose_queue = {}

return ActivityChristmas1Data
