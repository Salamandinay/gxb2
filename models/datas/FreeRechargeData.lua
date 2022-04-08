local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local FreeRechargeData = class("FreeRechargeData", ActivityData, true)

function FreeRechargeData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time
end

function FreeRechargeData:onAward(giftBagID)
	self.detail.buy_times = self.detail.buy_times + 1
end

function FreeRechargeData:isShow()
	if not self:isFunctionOnOpen() then
		return false
	end

	return UNITY_ANDROID or UNITY_EDITOR
end

function FreeRechargeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if UNITY_IOS then
		return false
	end

	return self.defRedMark
end

return FreeRechargeData
