local ActivityData = import("app.models.ActivityData")
local ActivityBeachShopData = class("ActivityBeachShopData", ActivityData, true)

function ActivityBeachShopData:getUpdateTime()
	return self:getEndTime()
end

function ActivityBeachShopData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = nil
	local lastTime = xyd.db.misc:getValue("activity_beach_shop_red_time")
	flag = not lastTime or not xyd.isSameDay(tonumber(lastTime), xyd.getServerTime(), true)

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BEACH_SHOP, flag)

	return flag
end

function ActivityBeachShopData:recordBuyId(id)
	self.buyId = id
end

function ActivityBeachShopData:onAward(data)
	if data.activity_id == xyd.ActivityID.ACTIVITY_BEACH_SHOP then
		self.detail_.buy_times[self.buyId] = self.detail_.buy_times[self.buyId] + 1
	end
end

return ActivityBeachShopData
