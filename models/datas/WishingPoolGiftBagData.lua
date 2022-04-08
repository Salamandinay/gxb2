local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local WishingPoolGiftBagData = class("WishingPoolGiftBagData", ActivityData, true)

function WishingPoolGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function WishingPoolGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityGambleTable:getIDs()

	for i = 1, #ids do
		if self.detail.point < xyd.tables.activityGambleTable:getPoint(ids[i]) then
			return self.defRedMark
		end
	end

	return false
end

return WishingPoolGiftBagData
