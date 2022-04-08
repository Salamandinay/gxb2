local ActivityData = import("app.models.ActivityData")
local ActivityPopularityVoteData = class("ActivityPopularityVoteData", ActivityData, true)

function ActivityPopularityVoteData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self.detail_.partner_id then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, false)

		return false
	end

	local flag = false
	local lastTime = xyd.db.misc:getValue("activity_popularity_vote_award")
	flag = not lastTime or not xyd.isSameDay(tonumber(lastTime), xyd.getServerTime())
	local t = xyd.tables.activityPopularityVoteTaskTable
	local ids = t:getIDs()
	local missionCount = self.detail_.mission_count
	local missionAwarded = self.detail_.mission_awarded

	for i = 1, #ids do
		local complete = t:getCompleteNum(i)

		if complete <= missionCount[i] and missionAwarded[i] == 0 then
			flag = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, flag)

	return flag
end

function ActivityPopularityVoteData:setVote(itemID, num)
	self.lastVote = {
		itemID,
		num
	}
end

function ActivityPopularityVoteData:setDefRedMark(flag)
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, flag)

	local msg = messages_pb.activity_popularity_vote_vote_mission_info_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE

	xyd.Backend.get():request(xyd.mid.ACTIVITY_POPULARITY_VOTE_VOTE_MISSION_INFO, msg)
end

return ActivityPopularityVoteData
