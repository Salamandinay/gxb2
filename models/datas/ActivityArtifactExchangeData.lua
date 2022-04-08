local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityArtifactExchangeData = class("ActivityArtifactExchangeData", ActivityData, true)

function ActivityArtifactExchangeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityArtifactExchangeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function ActivityArtifactExchangeData:setAwardID(id)
	self.awardID = id
end

function ActivityArtifactExchangeData:onAward(data)
	if data.activity_id == xyd.ActivityID.ACTIVITY_ARTIFACT_EXCHANGE and self.awardID then
		self.detail.buy_times[self.awardID] = self.detail.buy_times[self.awardID] + 1
	end
end

return ActivityArtifactExchangeData
