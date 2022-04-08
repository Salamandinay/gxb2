local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityVoteData = class("ActivityVoteData", ActivityData, true)

function ActivityVoteData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityVoteData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local detail = self.detail
	local mission_count = detail.mission_count
	local mission_awarded = detail.mission_awarded

	for i = 1, #mission_count do
		if xyd.tables.activityWeddingVoteMissionTable:getComplete(i) <= mission_count[i] and not mission_awarded[i] then
			return true
		end
	end

	return self.defRedMark
end

function ActivityVoteData:onAward(data)
	local real_data = json.decode(data.detail)
	local mission_id = real_data.mission_id
	self.detail.mission_awarded[mission_id - 1] = 1
end

return ActivityVoteData
