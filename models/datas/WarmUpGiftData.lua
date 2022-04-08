local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local WarmUpGiftData = class("WarmUpGiftData", ActivityData, true)

function WarmUpGiftData:getUpdateTime()
	if self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function WarmUpGiftData:ifBack()
	return self.detail_.charges[1].buy_times >= 1
end

function WarmUpGiftData:updateInfo(data)
	self.detail_.charges[1].buy_times = self.detail_.charges[1].buy_times + 1
end

return WarmUpGiftData
