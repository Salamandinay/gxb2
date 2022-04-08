local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local LibraryWatcherData = class("LibraryWatcherData", ActivityData, true)

function LibraryWatcherData:onAward(data)
	self.detail_ = json.decode(data.detail)
end

function LibraryWatcherData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

return LibraryWatcherData
