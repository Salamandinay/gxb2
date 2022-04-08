local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local TenStarExchangeData = class("TenStarExchangeData", ActivityData, true)

function TenStarExchangeData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

return TenStarExchangeData
