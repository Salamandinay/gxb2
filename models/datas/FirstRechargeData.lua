local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local FirstRechargeData = class("FirstRechargeData", GiftBagData, true)

function FirstRechargeData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function FirstRechargeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.can_award == 1 then
		return true
	end

	return self.defRedMark
end

function FirstRechargeData:onRecharge()
	if self.detail.can_award == 0 then
		xyd.models.advertiseComplete:firstRecharge()
	end

	self.detail.can_award = 1
end

function FirstRechargeData:onAward(giftBagID)
	self.detail.can_award = 0
	self.detail.is_awarded = 1
end

return FirstRechargeData
