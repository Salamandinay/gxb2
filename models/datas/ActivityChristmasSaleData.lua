local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmasSaleData = class("ActivityChristmasSaleData", ActivityData, true)

function ActivityChristmasSaleData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityChristmasSaleData:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.DEER_CANDY then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE, function ()
			end)
		end
	end
end

function ActivityChristmasSaleData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChristmasSaleData:onAward(data)
	local limits = self.detail.limits[self.awardId]
	limits.limit = limits.limit + (self.awardNum or 1)
	local opAwardsIndexs = xyd.split(self.detail[tostring(self.awardId)], "|", true)

	for i = 1, #opAwardsIndexs do
		local index = opAwardsIndexs[i]
		limits["limit" .. i][index] = limits["limit" .. i][index] + (self.awardNum or 1)
	end

	self.detail.cost = self.detail.cost + tonumber(xyd.tables.activityChristmasSaleAwardsTable:getCost(self.awardId)[2]) * (self.awardNum or 1)

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHRISTMAS_SALE, function ()
	end)
end

function ActivityChristmasSaleData:setAwardId(id)
	self.awardId = id
end

function ActivityChristmasSaleData:setAwardNum(num)
	self.awardNum = num
end

function ActivityChristmasSaleData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local ActivityChristmasSaleAwardsTable = xyd.tables.activityChristmasSaleAwardsTable
	local ids = ActivityChristmasSaleAwardsTable:getIds()

	for i = 1, #ids do
		local id = ids[i]
		local requirement = ActivityChristmasSaleAwardsTable:getRequirement(id)
		local limit = ActivityChristmasSaleAwardsTable:getLimit(id)
		local cost = tonumber(ActivityChristmasSaleAwardsTable:getCost(id)[2])
		local hasNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.DEER_CANDY)
		flag = requirement <= self.detail.cost and self.detail.limits[i].limit < limit and cost <= hasNum

		if flag then
			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHRISTMAS_SALE, flag)

	return flag
end

return ActivityChristmasSaleData
