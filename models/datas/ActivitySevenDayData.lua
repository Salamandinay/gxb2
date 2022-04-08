local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySevenDayData = class("ActivitySevenDayData", ActivityData, true)

function ActivitySevenDayData:onAward(data)
	local detailData = json.decode(data.detail)
	detailData.partner_info = nil
	self.detail = detailData
end

function ActivitySevenDayData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local count = self.detail.count
	local onlineDays = self.detail.online_days

	if onlineDays > 7 then
		onlineDays = 7
	end

	return count < onlineDays
end

return ActivitySevenDayData
