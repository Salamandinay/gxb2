local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local IceSecretBossChallengeData = class("IceSecretBossChallengeData", ActivityData, true)

function IceSecretBossChallengeData:ctor(params)
	ActivityData.ctor(self, params)
end

function IceSecretBossChallengeData:getUpdateTime()
	return self:getEndTime()
end

function IceSecretBossChallengeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE, true)

		return true
	end

	local times = self.detail.challenge_times

	if times > 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE, true)

		return true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET_BOSS_CHALLENGE, false)

	return false
end

return IceSecretBossChallengeData
