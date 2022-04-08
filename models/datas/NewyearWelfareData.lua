local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewyearWelfareData = class("NewyearWelfareData", ActivityData, true)

function NewyearWelfareData:getUpdateTime()
	return self:getEndTime()
end

function NewyearWelfareData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.NEWYEAR_WELFARE, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.NEWYEAR_WELFARE, true)

		return true
	end

	local flag1 = false
	local nowTime = xyd.db.misc:getValue("activity_newyear_welfare_time")

	if not nowTime or not xyd.isSameDay(tonumber(nowTime), xyd.getServerTime()) then
		flag1 = true
	end

	local flag2 = false

	for i = 1, 16 do
		if self.detail.buy_times[i] < xyd.tables.newyearWelfareTable:getLimit(i) then
			flag2 = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.NEWYEAR_WELFARE, flag1 and flag2)

	return flag1 and flag2
end

return NewyearWelfareData
