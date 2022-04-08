local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityIceSecretData = class("ActivityIceSecretData", ActivityData, true)

function ActivityIceSecretData:ctor(params)
	ActivityIceSecretData.super.ctor(self, params)

	self.isTouched = false
end

function ActivityIceSecretData:onAward(data)
	if not data then
		return
	end

	local details = require("cjson").decode(data.detail)
	self.detail_ = details.info
end

function ActivityIceSecretData:getUpdateTime()
	return self:getEndTime()
end

function ActivityIceSecretData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, true)

		return true
	end

	local time = xyd.db.misc:getValue("activity_ice_secret")

	if self.isTouched then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, false)

		return false
	end

	if time and xyd.isToday(tonumber(time)) then
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, false)

		return false
	else
		xyd.db.misc:setValue({
			key = "activity_ice_secret",
			value = xyd.getServerTime()
		})
		xyd.models.redMark:setMark(xyd.RedMarkType.ICE_SECRET, true)

		return true
	end
end

function ActivityIceSecretData:getLittleUpdateTime()
	return xyd.getTomorrowTime() - xyd.getServerTime()
end

function ActivityIceSecretData:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local lastLoginTime = xyd.db.misc:getValue("activity_ice_secret_show")

		if lastLoginTime == nil or tonumber(lastLoginTime) < self.start_time then
			return true
		end
	else
		return false
	end
end

function ActivityIceSecretData:doAfterPop()
	xyd.db.misc:setValue({
		key = "activity_ice_secret_show",
		value = xyd.getServerTime()
	})
end

function ActivityIceSecretData:getPopWinName()
	return "activity_ice_secret_show_window"
end

return ActivityIceSecretData
