local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFreeBuyData = class("ActivityFreeBuyData", ActivityData, true)

function ActivityFreeBuyData:getShowEndTime()
	local startTime = self.detail_.start_time

	return startTime + 3 * xyd.DAY_TIME
end

function ActivityFreeBuyData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	if not xyd.GuideController.get():isGuideComplete() then
		return false
	end

	local hasBuy = false

	for i = 1, 3 do
		if self:checkBuyTimes(i) then
			hasBuy = true
		end
	end

	if not hasBuy and self:getShowEndTime() < xyd.getServerTime() then
		return false
	end

	if hasBuy and xyd.getServerTime() > self:getShowEndTime() + 6 * xyd.DAY_TIME then
		return false
	end

	if hasBuy and self:checkHasAllawarded() and self:getShowEndTime() < xyd.getServerTime() then
		return false
	end

	if (self.is_open == 1 or self.is_open == true) and self.days and self.days < 0 then
		return true
	end

	return false
end

function ActivityFreeBuyData:checkHasAllawarded()
	local hasAllAwarded = true

	for i = 1, 3 do
		if self:checkBuyTimes(i) then
			local awardIds = xyd.tables.activityFreebuyAwardTable:getIdsByType(i)

			for _, id in ipairs(awardIds) do
				if not self.detail_.awards[tonumber(id)] or self.detail_.awards[tonumber(id)] ~= 1 then
					return false
				end
			end
		end
	end

	return true
end

function ActivityFreeBuyData:isShow()
	return self:isOpen()
end

function ActivityFreeBuyData:getToday()
	local today = 0

	for i = 1, 3 do
		if xyd.isSameDay(xyd.getServerTime(), self.detail_.start_time + i * xyd.DAY_TIME) then
			today = i + 1

			break
		end
	end

	return today
end

function ActivityFreeBuyData:getTodayAfterBuy(index)
	local today = 2
	local buy_days = self.detail_.buy_days[index]

	if buy_days == 0 then
		for i = 1, 9 do
			if xyd.isSameDay(xyd.getServerTime(), self.detail_.start_time + (i - 1) * xyd.DAY_TIME) then
				today = i

				break
			end
		end
	else
		for i = 1, 9 do
			if xyd.isSameDay(xyd.getServerTime(), self.detail_.start_time + (i + buy_days - 2) * xyd.DAY_TIME) then
				today = i

				break
			end
		end
	end

	return today
end

function ActivityFreeBuyData:getCanAwardList(index)
	local duringDay = self:getTodayAfterBuy(index)
	local awarded = self.detail_.awards
	local awardIds = xyd.tables.activityFreebuyAwardTable:getIdsByType(index)
	local hasAwardedDay = 0
	local list = {}

	for i = 1, #awardIds do
		local id = awardIds[i]

		if awarded and awarded[id] == 1 then
			if hasAwardedDay < i then
				hasAwardedDay = i
			end

			if i == duringDay then
				table.insert(list, awardIds[i + 1])

				break
			end
		elseif i <= duringDay then
			table.insert(list, id)
		end
	end

	if hasAwardedDay >= #awardIds then
		return #awardIds, awardIds
	else
		return hasAwardedDay, list
	end
end

function ActivityFreeBuyData:getUpdateTime()
	local hasBuy = false

	for i = 1, 3 do
		if self:checkBuyTimes(i) then
			hasBuy = true

			break
		end
	end

	if not hasBuy then
		return self:getShowEndTime()
	else
		return self:getShowEndTime() + 6 * xyd.DAY_TIME
	end
end

function ActivityFreeBuyData:checkBuyTimes(index)
	if self.detail_.buy_times[index] and self.detail_.buy_times[index] > 0 then
		return true
	else
		return false
	end
end

function ActivityFreeBuyData:checkCanBuy(index)
	if self:getShowEndTime() < xyd.getServerTime() then
		return false
	end

	if index == 1 then
		return true
	end

	for i = 1, index - 1 do
		if not self.detail_.buy_times[i] or self.detail_.buy_times[i] == 0 then
			return false
		end
	end

	return true
end

function ActivityFreeBuyData:onAward(event_data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_FREEBUY, function ()
		local data = event_data.detail

		if event_data.detail and tostring(event_data.detail) ~= "" then
			data = cjson.decode(event_data.detail)
		end

		if data.type and data.type == 2 then
			local ids = data.ids

			for _, id in ipairs(ids) do
				self.detail_.awards[id] = 1
			end
		elseif self.tempAwardId_ then
			self.detail_.buy_times[self.tempAwardId_] = 1
			self.detail_.buy_days[self.tempAwardId_] = self:getToday()
		end
	end)
end

function ActivityFreeBuyData:setTempAwardID(index)
	self.tempAwardId_ = index
end

function ActivityFreeBuyData:getTempAwardID(...)
	return self.tempAwardId_
end

function ActivityFreeBuyData:clearTempAwardID(...)
	self.tempAwardId_ = nil
end

function ActivityFreeBuyData:checkPop()
	if not xyd.GuideController.get():isGuideComplete() then
		return false
	end

	local checkTips = xyd.db.misc:getValue("freebuy_popup_time")

	if not self:isOpen() then
		return false
	end

	if not checkTips or not xyd.isSameDay(checkTips, xyd.getServerTime()) then
		return true
	else
		return false
	end
end

function ActivityFreeBuyData:doAfterPop()
end

function ActivityFreeBuyData:getPopWinName()
	return "freebuy_giftbag_popup_window"
end

function ActivityFreeBuyData:getRedMarkState()
	for i = 1, 3 do
		if self:checkBuyTimes(i) then
			local duringDay = self:getTodayAfterBuy(i)
			local hasAwardedDay = self:getCanAwardList(i)

			if duringDay - hasAwardedDay > 0 then
				return true
			end
		end
	end

	return false
end

return ActivityFreeBuyData
