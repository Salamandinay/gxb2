local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local HalloweenPumpkinFieldData = class("HalloweenPumpkinFieldData", ActivityData, true)

function HalloweenPumpkinFieldData:ctor(params)
	ActivityData.ctor(self, params)

	self.isCheckBackPackNum = true
	self.isNeedBackShowRed = false
end

function HalloweenPumpkinFieldData:getUpdateTime()
	return self:getEndTime()
end

function HalloweenPumpkinFieldData:getEndTime()
	return self.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function HalloweenPumpkinFieldData:setBuyTimes(buy_times)
	self.detail.buy_times = buy_times
	self.isCheckBackPackNum = false

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.HALLOWEEN_PUMPKIN_FIELD, function ()
		self.isCheckBackPackNum = true
	end)
end

function HalloweenPumpkinFieldData:onAward(data)
	data = xyd.decodeProtoBuf(data)
	local dataValue = json.decode(data.detail)
	self.isCheckBackPackNum = false
	self.isNeedBackShowRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.HALLOWEEN_PUMPKIN_FIELD, function ()
		self.isNeedBackShowRed = false
		self.isCheckBackPackNum = true
		self.detail.buy_times = dataValue.info.buy_times
		self.detail.times = dataValue.info.times
		self.detail.awards = dataValue.info.awards
		self.detail.left = dataValue.info.left
	end)
end

function HalloweenPumpkinFieldData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.isNeedBackShowRed == true then
		return true
	end

	if self.isCheckBackPackNum == true and xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_KNIFE) > 0 then
		return true
	end

	local isCanReceive = true

	for i in pairs(self.detail.awards) do
		if self.detail.awards[i] == 0 then
			isCanReceive = false

			break
		end
	end

	return isCanReceive
end

return HalloweenPumpkinFieldData
