local ActivityData = import("app.models.ActivityData")
local ActivitySandShopData = class("ActivitySandShopData", ActivityData, true)

function ActivitySandShopData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySandShopData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	return flag
end

function ActivitySandShopData:recordBuyId(id, num)
	self.buyId = id
	self.buyNum = num or 1
end

function ActivitySandShopData:onAward(data)
	if data.activity_id == xyd.ActivityID.ACTIVITY_SAND_SHOP then
		self.detail_.buy_times[self.buyId] = self.detail_.buy_times[self.buyId] + self.buyNum
	end
end

function ActivitySandShopData:getNowConditionValue()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_SEARCH)

	if activityData then
		return activityData:getStageID() or 0
	else
		return 0
	end
end

return ActivitySandShopData
