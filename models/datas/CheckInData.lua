local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local CheckInData = class("CheckInData", ActivityData, true)

function CheckInData:ctor(params)
	ActivityData.ctor(self, params)
end

function CheckInData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local count = self.detail_.count
	local onlineDays = self.detail_.online_days

	return count < onlineDays
end

function CheckInData:onAward(data)
	local detail = json.decode(data.detail)

	if tonumber(detail.count) then
		self.detail_.count = tonumber(detail.count)
	end
end

function CheckInData:checkPop()
	if xyd.GuideController.get():isGuideComplete() and self.detail_ then
		local gotDays = self.detail_.count
		local onlineDays = self.detail_.online_days

		if gotDays < onlineDays then
			return true
		end
	end

	return false
end

function CheckInData:getPopWinName()
	return "check_in_pop_up_window"
end

return CheckInData
