local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local GrowUpGiftBagData = class("GrowUpGiftBagData", ActivityData, true)

function GrowUpGiftBagData:getUpdateTime()
	return self:getEndTime()
end

function GrowUpGiftBagData:onAward(giftBagID)
	self.detail.charge.buy_times = self.detail.charge.buy_times + 1
end

function GrowUpGiftBagData:onRecharge()
	self.detail.charge.buy_times = self.detail.charge.buy_times + 1
end

function GrowUpGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local giftBagIDs = xyd.tables.activityTable:getGiftBag(self.id)
	local limit = xyd.tables.giftBagTable:getBuyLimit(giftBagIDs[1])

	if limit <= self.detail.charge.buy_times then
		return false
	end

	return self.defRedMark
end

return GrowUpGiftBagData
