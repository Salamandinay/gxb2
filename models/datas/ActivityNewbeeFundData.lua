local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewbeeFundData = class("ActivityNewbeeFundData", ActivityData, true)

function ActivityNewbeeFundData:getEndTime()
	local startTime = self.detail_.info.start_time
	local newTime = xyd.tables.miscTable:getNumber("activity_newbee_fund2_start_time", "value")

	if tonumber(newTime) <= tonumber(startTime) then
		self.isNew_ = true
	end

	if self.detail.charges[1].buy_times == 1 then
		if self.isNew_ then
			local buyTimeEndDis = xyd.tables.miscTable:getNumber("activity_newbee_fund_get_time_new", "value") or 0

			return self.start_time + (self.detail.info.buy_day + buyTimeEndDis) * 24 * 60 * 60
		else
			local buyTimeEndDis = xyd.tables.miscTable:getNumber("activity_newbee_fund_get_time", "value")

			return self.start_time + (self.detail.info.buy_day + buyTimeEndDis) * 24 * 60 * 60
		end
	else
		local buyTimeEndDis = xyd.tables.miscTable:getNumber("activity_newbee_fund_sell_time", "value")

		return self.detail.info.start_time + buyTimeEndDis * 24 * 60 * 60
	end
end

function ActivityNewbeeFundData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	if (self.is_open == 1 or self.is_open == true) and xyd.getServerTime() < self:getEndTime() then
		return true
	end

	return false
end

function ActivityNewbeeFundData:getUpdateTime()
	return self:getEndTime()
end

function ActivityNewbeeFundData:getDays()
	if self.detail.charges[1].buy_times == 1 then
		return math.floor((xyd.getServerTime() - self.start_time) / 86400) - self.detail.info.buy_day + 1
	else
		return 0
	end
end

function ActivityNewbeeFundData:getPopWinName()
	return "newbee_fund_popup_window"
end

function ActivityNewbeeFundData:onAward(data)
	if type(data) == "number" then
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, function ()
			self.detail.info.buy_day = math.floor((xyd.getServerTime() - self.start_time) / 86400)
		end)

		return
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, function ()
		local detail = json.decode(data.detail)
		self.detail.info.awards = detail.info.awards

		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_YEAR_FUND, self:getRedMarkState())
	end)
end

function ActivityNewbeeFundData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if xyd.models.backpack:getLev() < xyd.tables.miscTable:getNumber("activity_newbee_fund_level_limit", "value") then
		return false
	end

	if self:isHide() then
		return false
	end

	if self.detail.charges[1].buy_times == 1 then
		return self.detail.info.awards[self:getDays()] ~= 1 or self:getRedMarkState2()
	else
		local time = xyd.db.misc:getValue("activity_newbee_fund_red_mark_1")

		if time and xyd.isToday(tonumber(time)) then
			return false
		else
			return true
		end
	end
end

function ActivityNewbeeFundData:getRedMarkState2()
	if not self:isFunctionOnOpen() then
		return false
	end

	if xyd.models.backpack:getLev() < xyd.tables.miscTable:getNumber("activity_newbee_fund_level_limit", "value") then
		return false
	end

	if self:isHide() then
		return false
	end

	local flag = xyd.db.misc:getValue("activity_newbee_fund_red_mark_2") or 0

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

function ActivityNewbeeFundData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	local endtimeNum = self:getEndTime()
	endtimeNum = endtimeNum or 0

	if tonumber(endtimeNum) < xyd.getServerTime() then
		return true
	end

	if xyd.tables.miscTable:getNumber("activity_newbee_fund_level_limit", "value") <= xyd.models.backpack:getLev() then
		return false
	end

	return true
end

function ActivityNewbeeFundData:checkPop()
	local startTime = self.detail_.info.start_time
	local newTime = xyd.tables.miscTable:getNumber("activity_newbee_fund2_start_time", "value")

	if tonumber(newTime) <= tonumber(startTime) then
		self.isNew_ = true
	end

	if not self.isNew_ then
		return false
	end

	if xyd.GuideController.get():isGuideComplete() then
		local time = xyd.db.misc:getValue("newbee_fund_popup_check")

		if not self:isHide() and (not time or time and not xyd.isSameDay(tonumber(time), xyd.getServerTime())) and (not self.detail.charges[1].buy_times or self.detail.charges[1].buy_times ~= 1) then
			return true
		else
			return false
		end
	end

	return false
end

return ActivityNewbeeFundData
