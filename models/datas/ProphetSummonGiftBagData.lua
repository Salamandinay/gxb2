local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ProphetSummonGiftBagData = class("ProphetSummonGiftBagData", ActivityData, true)
local ActivityTable = xyd.tables.activityTreeTable

function ProphetSummonGiftBagData:ctor(params)
	ProphetSummonGiftBagData.super.ctor(self, params)
	self:registerEvent(xyd.event.SUMMON, self.onProphet, self)
end

function ProphetSummonGiftBagData:getUpdateTime()
	if not self.detail.update_time then
		return self:getEndTime()
	end

	return self.detail.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ProphetSummonGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityTreeTable:getIDs()

	for i = 1, #ids do
		if self.detail.point < xyd.tables.activityTreeTable:getPoint(ids[i]) then
			return self.defRedMark
		end
	end

	return false
end

function ProphetSummonGiftBagData:onProphet(event)
	if xyd.getServerTime() <= self:getEndTime() then
		self.detail_.point = self.detail_.point + #event.data.summon_result.items + #event.data.summon_result.partners

		if ActivityTable:getLaterPoint() <= self.detail_.point and self.detail_.circle_times < xyd.tables.activityTable:getRound(self.id)[2] then
			self.detail_.point = self.detail_.point - ActivityTable:getLaterPoint()
			self.detail_.circle_times = self.detail_.circle_times + 1
		end
	end
end

return ProphetSummonGiftBagData
