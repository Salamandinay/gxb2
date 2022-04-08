local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local MidAutumnActivityData = class("MidAutumnActivityData", ActivityData, true)

function MidAutumnActivityData:setChoose(data)
	table.insert(MidAutumnActivityData.choose_queue, data)
end

function MidAutumnActivityData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function MidAutumnActivityData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityFestivalTabel:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.activityFestivalTabel:getLimit(ids[i])

		if limit ~= -1 and self.detail.buy_times[i] < xyd.tables.activityFestivalTabel:getLimit(ids[i]) then
			local data = xyd.tables.activityFestivalTabel:getCost(ids[i])

			if data[2] <= xyd.models.backpack:getItemNumByID(data[1]) then
				return true
			end
		end
	end

	return self.defRedMark
end

function MidAutumnActivityData:onAward(data)
	while #MidAutumnActivityData.choose_queue > 0 do
		self.detail.buy_times[MidAutumnActivityData.choose_queue[1].id] = self.detail.buy_times[MidAutumnActivityData.choose_queue[1].id] + MidAutumnActivityData.choose_queue[1].num

		table.remove(MidAutumnActivityData.choose_queue, 1)
	end
end

MidAutumnActivityData.choose_queue = {}

return MidAutumnActivityData
