local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFanPaiData = class("ActivityFanPaiData", ActivityData, true)

function ActivityFanPaiData:getUpdateTime(giftBagID)
	return self:getEndTime()
end

function ActivityFanPaiData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail = detail.info
end

function ActivityFanPaiData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not self.redMark and xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_FAN_PAI_ITEMID) > 0 then
		return true
	end

	return false
end

return ActivityFanPaiData
