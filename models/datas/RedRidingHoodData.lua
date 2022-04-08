local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local RedRidingHoodData = class("RedRidingHoodData", ActivityData, true)

function RedRidingHoodData:getUpdateTime()
	return self:getEndTime()
end

function RedRidingHoodData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isHide() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.charges[1].buy_times > 0 and self.detail.charges[2].buy_times > 0 and self.detail.charges[3].buy_times > 0 and self.detail.item_buys[1].buy_times > 0 then
		return false
	end

	local time = xyd.db.misc:getValue("red_riding_hood")

	if time and xyd.isToday(tonumber(time)) then
		return false
	end

	return true
end

function RedRidingHoodData:getRankState()
	if self.detail.charges[1].buy_times > 0 and self.detail.charges[2].buy_times > 0 and self.detail.charges[3].buy_times > 0 and self.detail.item_buys[1].buy_times > 0 then
		return true
	end

	return false
end

function RedRidingHoodData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	if self.detail.charges[1].buy_times == 0 or self.detail.charges[1].left_days > 0 then
		return false
	end

	if self.detail.charges[2].buy_times == 0 or self.detail.charges[2].left_days > 0 then
		return false
	end

	if self.detail.charges[3].buy_times == 0 or self.detail.charges[3].left_days > 0 then
		return false
	end

	if self.detail.item_buys[1].buy_times == 0 or self.detail.item_buys[1].left_days > 0 then
		return false
	end

	return true
end

return RedRidingHoodData
