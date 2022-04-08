local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBombData = class("ActivityBombData", ActivityData, true)

function ActivityBombData:getUpdateTime()
	return self:getEndTime()
end

function ActivityBombData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local cost = xyd.tables.miscTable:split2Cost("activity_bomb_make_cost", "value", "#")

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		return true
	end

	return false
end

function ActivityBombData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

return ActivityBombData
