local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityVote2Data = class("ActivityVote2Data", ActivityData, true)

function ActivityVote2Data:getUpdateTime()
	return self:getEndTime()
end

function ActivityVote2Data:getStartTime()
	return self.start_time
end

function ActivityVote2Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local detail = self.detail
	local mission_count = detail.mission_count
	local mission_awarded = detail.mission_awarded
	local redState = nil
	local missionRedStatus = true
	local time = xyd.db.misc:getValue("activity_vote_2_red")
	missionRedStatus = not time or not xyd.isToday(tonumber(time))
	local stage = self:getCurStatus()

	for i = 1, #mission_count do
		if xyd.tables.activityWeddingVote2MissionTable:getComplete(i) <= mission_count[i] and (not mission_awarded[i] or mission_awarded[i] == 0) then
			redState = true

			break
		end
	end

	if stage ~= 0 and stage ~= 1 and stage ~= 2 then
		redState = false
	end

	if redState then
		return redState
	else
		return missionRedStatus
	end
end

function ActivityVote2Data:addVoteNum(num)
	if self.detail_.vote_num < 32 and self.detail_.vote_num + num >= 32 then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_VOTE2)
	else
		self.detail_.vote_num = self.detail_.vote_num + num
	end
end

function ActivityVote2Data:getCurStatus()
	local timestamp = xyd.tables.miscTable:split2num("wedding_vote2_time_interval", "value", "|")
	local start_time = self:startTime()
	local cur_time = xyd.getServerTime() - start_time

	for i = 1, #timestamp do
		local stamp = timestamp[i] * 24 * 60 * 60

		if cur_time < stamp then
			return i - 1
		end
	end

	return #timestamp
end

function ActivityVote2Data:onAward(data)
	local real_data = json.decode(data.detail)
	local mission_id = real_data.mission_id
	self.detail.mission_awarded[mission_id] = 1
end

return ActivityVote2Data
