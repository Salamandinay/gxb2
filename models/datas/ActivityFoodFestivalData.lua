local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFoodFestivalData = class("ActivityFoodFestivalData", ActivityData, true)

function ActivityFoodFestivalData:ctor(params)
	ActivityData.ctor(self, params)

	self.choose_queue = {}
	self.choose_num = {}
end

function ActivityFoodFestivalData:setChoose(id, num)
	table.insert(self.choose_queue, id)
	table.insert(self.choose_num, num)
end

function ActivityFoodFestivalData:getUpdateTime()
	return self:getEndTime()
end

function ActivityFoodFestivalData:onAward(data)
	for i = 1, #self.choose_queue do
		local temp = self.detail.buy_times[self.choose_queue[i]]
		self.detail.buy_times[self.choose_queue[i]] = temp + self.choose_num[i]
	end
end

function ActivityFoodFestivalData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local time = xyd.db.misc:getValue("activity_food_festival2")

	if time then
		return false
	end

	return true
end

return ActivityFoodFestivalData
