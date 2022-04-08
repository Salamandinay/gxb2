local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityValentineData = class("ActivityValentineData", ActivityData, true)

function ActivityValentineData:getUpdateTime()
	return self:getEndTime()
end

function ActivityValentineData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail = detail.info
end

function ActivityValentineData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local awards = self.detail.awards
	local count = 0

	for i = 1, #awards do
		if awards[i] == 1 then
			count = count + 1
		end
	end

	if count < self.detail.num then
		return true
	end

	local time = xyd.db.misc:getValue("activity_valentine_redmark")

	if time and xyd.isToday(tonumber(time)) then
		return false
	else
		return true
	end
end

return ActivityValentineData
