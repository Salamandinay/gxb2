local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEquipLevelUpData = class("ActivityEquipLevelUpData", ActivityData, true)

function ActivityEquipLevelUpData:ctor(params)
	ActivityData.ctor(self, params)

	self.choose_queue = {}
	self.isShowRedMark = false
	local lastLoginTime = xyd.db.misc:getValue("activity_equip_level_up_last_touch_time")

	if lastLoginTime == nil or tonumber(lastLoginTime) < self:startTime() then
		self.isShowRedMark = true

		xyd.db.misc:setValue({
			key = "activity_equip_level_up_last_touch_time",
			value = xyd.getServerTime()
		})
	end
end

function ActivityEquipLevelUpData:setChoose(id)
	table.insert(self.choose_queue, id)
end

function ActivityEquipLevelUpData:setSelectSuit(id)
	self.selectSuit = id
end

function ActivityEquipLevelUpData:getUpdateTime()
	return self:getEndTime()
end

function ActivityEquipLevelUpData:onAward()
	for i = 1, #self.choose_queue do
		local id = self.choose_queue[i]
		self.detail.buy_times[id] = self.detail.buy_times[id] + 1

		if xyd.tables.activityEquipLevelUpTable:getType(id) == 2 then
			self.detail.buy_times2 = self.detail.buy_times2 + 1
		end
	end
end

function ActivityEquipLevelUpData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.isShowRedMark
end

return ActivityEquipLevelUpData
