local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityAltarChargeData = class("ActivityAltarChargeData", ActivityData, true)

function ActivityAltarChargeData:getUpdateTime()
	local starTime = self.detail_.start_time
	local endTime = starTime + tonumber(xyd.tables.miscTable:getVal("activity_star_altar_cost_time"))

	return endTime
end

function ActivityAltarChargeData:checkPop()
	if xyd.GuideController.get():isGuideComplete() and self:isShow() then
		local lastLoginTime = xyd.db.misc:getValue("star_altar_login_open_time")
		local ignore = xyd.db.misc:getValue("star_altar_login_ignore")

		if ignore and tonumber(ignore) == 1 and lastLoginTime and xyd.isSameDay(lastLoginTime, xyd.getServerTime()) then
			return false
		end

		return true
	else
		return false
	end
end

function ActivityAltarChargeData:isShow()
	local starTime = self.detail_.start_time
	local endTime = starTime + tonumber(xyd.tables.miscTable:getVal("activity_star_altar_cost_time"))

	if endTime < xyd.getServerTime() then
		return false
	end

	return true
end

function ActivityAltarChargeData:getPopWinName()
	return "activity_star_charge_window"
end

function ActivityAltarChargeData:onAward(data)
	if tonumber(data) then
		for _, info in ipairs(self.detail_.charges) do
			if tonumber(info.table_id) == tonumber(data) then
				info.buy_times = info.buy_times + 1
			end
		end
	end
end

function ActivityAltarChargeData:getNowStage()
	local nowNum = self:getNowValue() or 0

	for i = 1, 4 do
		local needValue1 = xyd.tables.activityStarAltarCostTable:getNum(i)
		local needValue2 = xyd.tables.activityStarAltarCostTable:getNum(i + 1)

		if needValue1 <= nowNum and nowNum < needValue2 then
			return i + 1
		elseif nowNum < needValue1 then
			return i
		end
	end

	return 5
end

function ActivityAltarChargeData:getNowValue()
	return self.detail_.num
end

function ActivityAltarChargeData:getRedMarkState()
	local flag1 = self:getAwardRed()
	local flag2 = self:getJumpRed()

	return flag1 or flag2
end

function ActivityAltarChargeData:getAwardRed()
	local chargesInfo = self.detail_.charges[1]

	if tonumber(chargesInfo.limit_times) - tonumber(chargesInfo.buy_times) <= 0 then
		return false
	end

	local clickTime = xyd.db.misc:getValue("star_altar_giftbag_click_time")

	if clickTime and xyd.isSameDay(tonumber(clickTime), xyd.getServerTime()) then
		return false
	else
		return true
	end
end

function ActivityAltarChargeData:getJumpRed()
	local clickTime = xyd.db.misc:getValue("star_altar_jump_click_time")

	if clickTime and xyd.isSameDay(tonumber(clickTime), xyd.getServerTime()) then
		return false
	elseif xyd.models.backpack:getItemNumByID(358) > 0 or xyd.models.backpack:getItemNumByID(362) > 0 then
		return true
	end

	return false
end

return ActivityAltarChargeData
