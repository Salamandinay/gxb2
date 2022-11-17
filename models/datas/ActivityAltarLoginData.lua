local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityAltarLoginData = class("ActivityAltarLoginData", ActivityData, true)

function ActivityAltarLoginData:getRedMarkState()
	local day = self:getNowDay()

	return self.detail_.awards[day] ~= 1
end

function ActivityAltarLoginData:getUpdateTime()
	local starTime = self.detail_.start_time
	local endTime = starTime + tonumber(xyd.tables.miscTable:getVal("activity_star_altar_cost_time"))

	return endTime
end

function ActivityAltarLoginData:getNowDay()
	local startTime = self.detail_.start_time
	local durningTime = xyd.getServerTime() - startTime
	local durningDay = math.floor(durningTime / xyd.DAY_TIME)

	return durningDay + 1
end

function ActivityAltarLoginData:checkFinish(day)
	return self.detail_.awards[tonumber(day)] == 1
end

function ActivityAltarLoginData:getLoginNum()
	local num = 0

	for i = 1, 7 do
		if self.detail_.awards[i] and self.detail_.awards[i] == 1 then
			num = num + 1
		end
	end

	return num
end

function ActivityAltarLoginData:onAward(data)
	if not data then
		return
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN, function ()
		local details = require("cjson").decode(data.detail)
		self.detail_ = details.info
	end)
end

function ActivityAltarLoginData:getSort()
	local count = 0

	for i in pairs(self.detail.awards) do
		if self.detail.awards[i] == 1 then
			count = count + 1
		end
	end

	local nowDay = self:getNowDay()

	if nowDay <= count then
		return true
	end

	return false
end

function ActivityAltarLoginData:backRank()
	return self:getSort()
end

function ActivityAltarLoginData:isShow()
	local starTime = self.detail_.start_time
	local endTime = starTime + tonumber(xyd.tables.miscTable:getVal("activity_star_altar_cost_time"))

	if endTime < xyd.getServerTime() then
		return false
	end

	return true
end

return ActivityAltarLoginData
