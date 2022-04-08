local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local UpgradeGiftBagData = class("UpgradeGiftBagData", ActivityData, true)

function UpgradeGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function UpgradeGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(xyd.tables.activityTable:getGiftBag(self.id)))

	if limit <= self.detail.charges[1].buy_times then
		return false
	end

	return self.defRedMark
end

function UpgradeGiftBagData:onAward()
	self.detail.charges[1].buy_times = self.detail.charges[1].buy_times + 1
end

function UpgradeGiftBagData:checkCanPurchase()
	local limit = xyd.tables.giftBagTable:getBuyLimit(tonumber(xyd.tables.activityTable:getGiftBag(self.id)))

	if limit <= self.detail.charges[1].buy_times then
		return false
	end

	return true
end

function UpgradeGiftBagData:backRank()
	return not self:checkCanPurchase()
end

return UpgradeGiftBagData
