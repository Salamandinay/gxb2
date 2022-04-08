local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local TestFeedbackData = class("TestFeedbackData", ActivityData, true)

function TestFeedbackData:onAward(data)
	local realData = json.decode(data.detail)
	self.detail.story_star = realData.story_star
	self.detail.ui_star = realData.ui_star
	self.detail.daily_comment = realData.daily_comment
end

function TestFeedbackData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

return TestFeedbackData
