local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityIceSummerData = class("ActivityIceSummerData", ActivityData, true)

function ActivityIceSummerData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityIceSummerData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.awardeds[1] == 0 then
		return true
	end

	local backpackNum = tonumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.ICE_SUMMER_COIN))

	if backpackNum > 0 then
		return true
	end

	local awardeds = self.detail.awardeds
	local used_times = tonumber(self.detail.used_times)
	local readNum = 0
	local storyAwardTable = xyd.tables.activityIceSummerStoryTable
	local len = #storyAwardTable:getIDs()

	for i = 1, len do
		if awardeds[i] == 1 then
			readNum = readNum + 1
		end
	end

	for i = 1, len do
		local storyCost = storyAwardTable:getCost(i + 1)
		local sumCollect = used_times

		if i == readNum and storyCost ~= nil and sumCollect ~= nil and storyCost <= sumCollect then
			return true
		end
	end

	return false
end

function ActivityIceSummerData:onAward(data)
	if data == nil then
		return
	elseif type(data) == "number" then
		self.detail_.charges[1].buy_times = self.detail_.charges[1].buy_times + 1

		return
	end

	local details = require("cjson").decode(data.detail)
	self.detail_.awarded = details.info.awardeds
end

return ActivityIceSummerData
