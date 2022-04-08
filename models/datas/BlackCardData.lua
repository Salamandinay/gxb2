local json = require("cjson")
local MonthCardData = import("app.models.datas.MonthCardData")
local BlackCardData = class("BlackCardData", MonthCardData, true)

function BlackCardData:getUpdateTime()
	if self.update_time == nil or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function BlackCardData:backRank()
	local data = self.detail.charges[1]

	if data.end_time ~= 0 then
		return true
	end

	return false
end

function BlackCardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.BLACK_CARD, false)

		return false
	end

	local flag = false

	if self:isFirstRedMark() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.BLACK_CARD, flag)

	return flag
end

return BlackCardData
