local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLimitCallBossData = class("ActivityLimitCallBossData", ActivityData, true)

function ActivityLimitCallBossData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLimitCallBossData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local times = self.detail.challenge_times

	if times > 0 then
		return true
	end

	return false
end

function ActivityLimitCallBossData:onAward()
	self.detail.challenge_times = self.detail.challenge_times - 1
end

return ActivityLimitCallBossData
