local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityCrystalGiftData = class("ActivityCrystalGiftData", GiftBagData, true)

function ActivityCrystalGiftData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityCrystalGiftData:onAward(data)
	if type(data) == "number" then
		for i = 1, #self.detail.charges do
			if data == self.detail.charges[i].table_id then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				break
			end
		end
	else
		local detail = json.decode(data.detail)
		local awards = detail.info.awards
		local charges = detail.info.charges

		for i = 1, #awards do
			self.detail.awards[i] = awards[i]
		end

		for i = 1, #charges do
			self.detail.charges[i].buy_times = charges[i].buy_times
		end
	end
end

function ActivityCrystalGiftData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.awards ~= nil and tonumber(self.detail.awards[1]) > 0 and tonumber(self.detail.charges[1].buy_times) > 1 and tonumber(self.detail.charges[2].buy_times) > 2 then
		return false
	end

	local time = xyd.db.misc:getValue("activity_crystal_gift")

	if time ~= nil and xyd.isToday(tonumber(time)) then
		return false
	end

	return true
end

return ActivityCrystalGiftData
