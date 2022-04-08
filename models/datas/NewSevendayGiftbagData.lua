local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewSevendayGiftbagData = class("NewSevendayGiftbagData", ActivityData, true)

function NewSevendayGiftbagData:ctor(params)
	ActivityData.ctor(self, params)

	self.freeID = 0
end

function NewSevendayGiftbagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.TimePeriod.WEEK_TIME
end

function NewSevendayGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local onTime = xyd.getServerTime() - self.update_time
	local onDays = 1

	if onTime > 0 then
		onDays = math.ceil(onTime / xyd.TimePeriod.DAY_TIME)
	end

	for i = 1, onDays do
		if self.detail.free_awarded[i] == 0 then
			return true
		end
	end

	return false
end

function NewSevendayGiftbagData:setFreeID(id)
	self.freeID = id
end

function NewSevendayGiftbagData:onAward(data)
	if type(data) == "number" then
		for i = 1, #self.detail.charges do
			if data == self.detail.charges[i].table_id then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
			end
		end
	else
		local detail = json.decode(data.detail)
		self.detail.free_awarded = detail
	end
end

return NewSevendayGiftbagData
