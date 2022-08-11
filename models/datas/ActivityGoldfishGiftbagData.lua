local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGoldfishGiftbag = class("ActivityGoldfishGiftbag", ActivityData, true)

function ActivityGoldfishGiftbag:getUpdateTime()
	return self:getEndTime()
end

function ActivityGoldfishGiftbag:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	return red
end

function ActivityGoldfishGiftbag:register()
	self.specialGiftbagID = xyd.tables.miscTable:getNumber("activity_sand_gift", "value")

	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id

		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_GOLDFISH_GIFTBAG then
			self.detail.buy_times = self.detail.buy_times + 1
		end
	end)
end

function ActivityGoldfishGiftbag:haveBuyPardGiftbag()
	local charges = self.detail.charges

	return charges[1].buy_times > 0
end

function ActivityGoldfishGiftbag:getPaidLeftTime()
	local charges = self.detail.charges
	local giftBagID = tonumber(charges[1].table_id)
	local limit = xyd.tables.giftBagTable:getBuyLimit(giftBagID)
	local leftTime = limit - charges[1].buy_times

	return leftTime
end

function ActivityGoldfishGiftbag:getFreeLeftTime()
	local limit = xyd.tables.miscTable:getNumber("activity_goldfish_pack_times", "value")

	if self:haveBuyPardGiftbag() then
		limit = limit + xyd.tables.miscTable:getNumber("activity_goldfish_pack_addtimes", "value")
	end

	local leftTime = limit - self.detail.buy_times

	return leftTime
end

return ActivityGoldfishGiftbag
