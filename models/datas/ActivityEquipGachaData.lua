local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEquipGachaData = class("ActivityEquipGachaData", ActivityData, true)

function ActivityEquipGachaData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityEquipGachaData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.EQUIP_GACHA)

	if num > 0 then
		return true
	end

	return self.defRedMark
end

function ActivityEquipGachaData:onAward(data)
	local realData = json.decode(data.detail)
	self.detail.equips = realData.equips
	self.detail.cur_times = realData.cur_times
	self.detail.awarded = realData.awarded
	self.detail.point = realData.point
end

return ActivityEquipGachaData
