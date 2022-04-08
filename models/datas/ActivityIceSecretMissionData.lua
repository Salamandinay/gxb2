local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityIceSecretMissionData = class("ActivityIceSecretMissionData", GiftBagData, true)

function ActivityIceSecretMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityIceSecretMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, true)

		return true
	end

	local timeDays = xyd.db.misc:getValue("activity_ice_secret_mission")

	if timeDays == nil then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, true)

		return true
	else
		local startTime = self:startTime()
		local passedTotalTime = xyd.getServerTime() - startTime
		local dayRound = math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)

		if dayRound ~= tonumber(timeDays) and xyd.getServerTime() < self:getEndTime() then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, true)

			return true
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, false)

			return false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_MISSION, false)

	return false
end

function ActivityIceSecretMissionData:getLittleUpdateTime()
	local startTime = self:startTime()
	local passedTotalTime = xyd.getServerTime() - startTime
	local dayRound = math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)
	local countdownTime = dayRound * xyd.TimePeriod.DAY_TIME - passedTotalTime

	return countdownTime
end

return ActivityIceSecretMissionData
