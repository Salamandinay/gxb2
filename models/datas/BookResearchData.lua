local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local BookResearchData = class("BookResearchData", ActivityData, true)

function BookResearchData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail.max_score = detail.max_score
	self.detail.point = detail.point
	self.detail.challenge_times = detail.challenge_times
	self.detail.awarded = detail.awarded
end

function BookResearchData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

return BookResearchData
