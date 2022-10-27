local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityHw2022ShopData = class("ActivityHw2022ShopData", ActivityData, true)

function ActivityHw2022ShopData:ctor(params)
	ActivityData.ctor(self, params)
end

function ActivityHw2022ShopData:getUpdateTime()
	return self:getEndTime()
end

function ActivityHw2022ShopData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityHw2022ShopData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_HW2022_SHOP then
		return
	end

	local data_ = xyd.decodeProtoBuf(data)

	if data_.detail then
		local info = require("cjson").decode(data_.detail)
		self.detail_.buy_times = info.info.buy_times

		self:getRedMarkState()
	end
end

function ActivityHw2022ShopData:getRedMarkState()
	local redState = false
	local ids = xyd.tables.activityHw2022ShopTable:getIDs()
	local buyTimes = self.detail_.buy_times

	for index, id in ipairs(ids) do
		local limit_time = xyd.tables.activityHw2022ShopTable:getLimit(id)
		local costs = xyd.tables.activityHw2022ShopTable:getCost(id)

		if not buyTimes[index] or limit_time > buyTimes[index] then
			local flag = true

			for i = 1, #costs do
				local data = costs[i]

				if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
					flag = false
				end
			end

			if flag then
				redState = true

				break
			end
		end
	end

	local touchTime = tonumber(xyd.db.misc:getValue("activity_hw2022_shop_touch"))

	if touchTime or xyd.isSameDay(touchTime, xyd.getServerTime()) then
		redState = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HW2022_SHOP, redState)

	return redState
end

return ActivityHw2022ShopData
