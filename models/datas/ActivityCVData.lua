local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityCVData = class("ActivityCVData", ActivityData, true)

function ActivityCVData:onAward(data)
	local id = data.activity_id

	if id ~= self.id then
		return
	end

	self.detail.is_awarded = 1
end

function ActivityCVData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.is_awarded then
		return false
	end

	return self.defRedMark
end

function ActivityCVData:backRank()
	if self.detail.is_awarded then
		return true
	end

	return false
end

return ActivityCVData
