local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local DarkGuardData = class("DarkGuardData", ActivityData, true)

function DarkGuardData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function DarkGuardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local cost_type = xyd.tables.miscTable:split2Cost("activity_guard_item_atk", "value", "#")[0]

	if xyd.models.backpack:getItemNumByID(cost_type) >= 1 then
		return true
	end

	return self.defRedMark
end

function DarkGuardData:onAward(data)
	local data_detail = json.decode(data.detail)
	self.detail.hp = data_detail.info.hp
end

return DarkGuardData
