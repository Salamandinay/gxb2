local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewyearSignInData = class("NewyearSignInData", ActivityData, true)

function NewyearSignInData:getUpdateTime()
	return self:getEndTime()
end

function NewyearSignInData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.count < math.min(xyd.tables.activityFestivalLoginTable:getDays(), self.detail.online_days) then
		return true
	end

	return self.defRedMark
end

function NewyearSignInData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.NEWYEAR_SIGNIN then
		return
	end

	self.detail.count = self.detail.count + 1
end

function NewyearSignInData:getSort()
	if self.detail.count < math.min(xyd.tables.activityFestivalLoginTable:getDays(), self.detail.online_days) then
		return true
	end

	return false
end

function NewyearSignInData:backRank()
	return not self:getSort()
end

return NewyearSignInData
