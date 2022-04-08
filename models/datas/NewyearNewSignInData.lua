local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewyearNewSignInData = class("NewyearNewSignInData", ActivityData, true)

function NewyearNewSignInData:getUpdateTime()
	return self:getEndTime()
end

function NewyearNewSignInData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.detail.awarded[self.detail.day] == 0
end

function NewyearNewSignInData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.NEWYEAR_NEW_SIGNIN then
		return
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWYEAR_NEW_SIGNIN, function ()
		local data_detail = json.decode(data.detail)
		self.detail.day = data_detail.day
		self.detail.awarded = data_detail.awarded
	end)
end

function NewyearNewSignInData:getSort()
	local count = 0

	for i in pairs(self.detail.awarded) do
		if self.detail.awarded[i] == 1 then
			count = count + 1
		end
	end

	if count < math.min(xyd.tables.activityFestivalLoginTable:getDays(), self.detail.day) then
		return true
	end

	return false
end

function NewyearNewSignInData:backRank()
	return not self:getSort()
end

return NewyearNewSignInData
