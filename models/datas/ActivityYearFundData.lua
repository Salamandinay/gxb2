local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityYearFundData = class("ActivityYearFundData", ActivityData, true)

function ActivityYearFundData:getEndTime()
	if self.detail.charges[1].buy_times == 1 then
		return self.start_time + (self.detail.info.buy_day + 30) * 24 * 60 * 60
	else
		return self.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
	end
end

function ActivityYearFundData:getUpdateTime()
	return self:getEndTime()
end

function ActivityYearFundData:getDays()
	if self.detail.charges[1].buy_times == 1 then
		return math.floor((xyd.getServerTime() - self.start_time) / 86400) - self.detail.info.buy_day + 1
	else
		return 0
	end
end

function ActivityYearFundData:onAward(data)
	if type(data) == "number" then
		self.detail.info.buy_day = math.floor((xyd.getServerTime() - self.start_time) / 86400)

		return
	end

	local detail = json.decode(data.detail)
	self.detail.info.awards = detail.info.awards

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_YEAR_FUND, self:getRedMarkState())
end

function ActivityYearFundData:getRedMarkState()
	local flag = false

	if not self:isFunctionOnOpen() then
		flag = false
	end

	if not flag and self:isFirstRedMark() then
		flag = true
	end

	if self.detail.charges[1].buy_times == 1 then
		if self.detail.info.awards[self:getDays()] == 1 then
			flag = self:getRedMarkState2()

			if self:getRedMarkState2() then
				flag = false

				if false then
					flag = true
				end
			end
		end
	else
		local time = xyd.db.misc:getValue("activity_year_fund_red_mark_1")
		flag = not time or not xyd.isToday(tonumber(time))
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_YEAR_FUND, flag)

	return flag
end

function ActivityYearFundData:getRedMarkState2()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = xyd.db.misc:getValue("activity_year_fund_red_mark_2") or 0

	for i = self:getDays() - 1, 1, -1 do
		local id = self.detail.info.awards[i]

		if id == 0 then
			if tonumber(flag) < i then
				return true

				break
			end

			return false

			break
		end
	end

	return false
end

return ActivityYearFundData
