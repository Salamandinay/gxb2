local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityPopularityVoteSurveyData = class("ActivityPopularityVoteSurveyData", ActivityData, true)

function ActivityPopularityVoteSurveyData:getRedMarkState()
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_SURVEY, true)

	return true
end

function ActivityPopularityVoteSurveyData:onAward(data)
	self.hasVoted = true
end

function ActivityPopularityVoteSurveyData:isOpen(data)
	if self.hasVoted or self.detail.select_id ~= 0 then
		return false
	end

	return true
end

return ActivityPopularityVoteSurveyData
