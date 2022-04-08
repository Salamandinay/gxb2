local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewbeeGachaPoolData = class("NewbeeGachaPoolData", ActivityData, true)

function NewbeeGachaPoolData:ctor(params)
	NewbeeGachaPoolData.super.ctor(self, params)

	local timeStamp = xyd.tables.miscTable:getNumber("activity_newbee_gacha_dropbox_new_time", "value")

	if timeStamp < xyd.getServerTime() then
		self.isNewVersion = true
	end
end

function NewbeeGachaPoolData:getEndTime()
	return self.detail_.start_time + xyd.TimePeriod.WEEK_TIME
end

function NewbeeGachaPoolData:getUpdateTime()
	return self:getEndTime()
end

function NewbeeGachaPoolData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return self:getEndTime() - xyd.getServerTime() > 0
end

function NewbeeGachaPoolData:onAward(data)
	self.detail_ = json.decode(data.detail).info
end

function NewbeeGachaPoolData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self:getRedMarkState1() or self:getRedMarkState2()
end

function NewbeeGachaPoolData:getRedMarkState1()
	if not self:isFunctionOnOpen() then
		return false
	end

	local time = xyd.db.misc:getValue("newbee_gacha_pool_time")

	if time and xyd.isToday(time) then
		return false
	end

	return true
end

function NewbeeGachaPoolData:getRedMarkState2()
	if not self:isFunctionOnOpen() then
		return false
	end

	local index = 0

	for i = 1, #self.detail.awards do
		if self.detail.awards[i] == 0 then
			index = i

			break
		end
	end

	if index == 0 then
		return false
	end

	local limit = nil

	if self.isNewVersion then
		limit = xyd.tables.activityNewbeeGachaNewTable:getLimit(index)
	else
		limit = xyd.tables.activityNewbeeGachaNewTable:getLimit(index)
	end

	if limit <= self.detail.draw_times then
		return true
	end

	return false
end

return NewbeeGachaPoolData
