local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityRedeemCodeData = class("ActivityRedeemCodeData", ActivityData, true)

function ActivityRedeemCodeData:getUpdateTime()
	return xyd.models.selfPlayer:getCreatedTime() + 1209600
end

function ActivityRedeemCodeData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	if xyd.GuideController.get():isPlayGuide() then
		return true
	end

	return not self.detail_.can_use_code
end

function ActivityRedeemCodeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local stamp = xyd.db.misc:getValue("activity_redeem_code")
	local timeDesc = os.date("!*t", xyd.getServerTime())
	local time = tostring(timeDesc.year) .. tostring(timeDesc.hour >= 8 and timeDesc.yday or timeDesc.yday - 1)

	if not stamp or time ~= stamp then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_REDEEM_CODE, true)

		return true
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_REDEEM_CODE, false)
	end

	return false
end

function ActivityRedeemCodeData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

return ActivityRedeemCodeData
