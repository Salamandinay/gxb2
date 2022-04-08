local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityPromotionTestData = class("ActivityPromotionTestData", ActivityData, true)

function ActivityPromotionTestData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPromotionTestData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	return red
end

function ActivityPromotionTestData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
	end)
end

function ActivityPromotionTestData:getCurPoint()
	if not self.detail.times then
		self.detail.times = 0
	end

	return self.detail.times
end

function ActivityPromotionTestData:getFreeAwardIsAwarded(index)
	if not self.detail.awards then
		self.detail.awards = {
			0,
			0,
			0,
			0,
			0
		}
	end

	return self.detail.awards[index] > 0
end

function ActivityPromotionTestData:getExtraAwardIsAwarded(index)
	if not self.detail.ex_awards then
		self.detail.ex_awards = {
			0,
			0,
			0,
			0,
			0
		}
	end

	return self.detail.ex_awards[index] > 0
end

function ActivityPromotionTestData:getExtraAwardIsLock(index)
	local condition = xyd.tables.activityPromotionTestTable:getCondition(index)
	local hasNum = xyd.models.backpack:getItemNumByID(condition[1])

	return hasNum < condition[2]
end

return ActivityPromotionTestData
