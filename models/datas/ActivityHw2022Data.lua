local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityHw2022Data = class("ActivityHw2022Data", ActivityData, true)
local resItemList = {
	xyd.ItemID.ACTIVITY_HW2022_ITEM1,
	xyd.ItemID.ACTIVITY_HW2022_ITEM2,
	xyd.ItemID.ACTIVITY_HW2022_ITEM3
}

function ActivityHw2022Data:ctor(params)
	ActivityData.ctor(self, params)

	self.resItemNum1 = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM1)
	self.resItemNum2 = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM2)
	self.resItemNum3 = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_ITEM3)
end

function ActivityHw2022Data:getUpdateTime()
	return self:getEndTime()
end

function ActivityHw2022Data:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityHw2022Data:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022, function ()
		if data.activity_id ~= xyd.ActivityID.ACTIVITY_HW2022 then
			return
		end

		local data_ = xyd.decodeProtoBuf(data)

		if data_.detail then
			local info = require("cjson").decode(data_.detail)

			if info.type ~= 3 then
				self.detail_ = info.info
			end
		end
	end)
end

function ActivityHw2022Data:onItemChange(event)
	local items = event.data.items

	for i = 1, #items do
		for index, resItemID in ipairs(resItemList) do
			if items[i].item_id == resItemID then
				self["resItemNum" .. index] = xyd.models.backpack:getItemNumByID(resItemID)
			end
		end
	end

	self:getRedMarkState()
end

function ActivityHw2022Data:getRedMarkState()
	local redState = false

	for type = 1, 2 do
		local costs = xyd.tables.activityHw2022GambleTable:getCost(type)
		local canUse = true

		for _, cost in ipairs(costs) do
			local index = xyd.arrayIndexOf(resItemList, cost[1])

			if self["resItemNum" .. index] < cost[2] then
				canUse = false
			end
		end

		if canUse then
			redState = true
		end
	end

	local touchTime = tonumber(xyd.db.misc:getValue("activity_hw2022_rank_touch"))

	if not touchTime or not xyd.isSameDay(touchTime, xyd.getServerTime()) then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HW2022, redState)

	return redState
end

return ActivityHw2022Data
