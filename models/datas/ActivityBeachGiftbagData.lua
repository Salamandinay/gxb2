local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBeachGiftbagData = class("ActivityBeachGiftbagData", ActivityData, true)

function ActivityBeachGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityBeachGiftbagData:onAward(event)
	local data = event

	if data and type(data) == "number" then
		for i = 1, #self.detail.charges do
			if data == self.detail.charges[i].table_id then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				break
			end
		end
	end
end

function ActivityBeachGiftbagData:getRedMarkState()
	local days = xyd.tables.activityTable:getDays(self.activity_id)

	if days and days > 0 then
		local duration = self:getUpdateTime() - xyd.getServerTime()
		local flag = nil

		if duration > 604800 then
			flag = xyd.db.misc:getValue("ActivityBeachGiftbagRedMark_week1" .. self:getUpdateTime())
		else
			flag = xyd.db.misc:getValue("ActivityBeachGiftbagRedMark_week2" .. self:getUpdateTime())
		end

		if not flag or tonumber(flag) ~= 1 then
			return true
		end
	end

	return false
end

return ActivityBeachGiftbagData
