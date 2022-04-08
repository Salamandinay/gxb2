local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GuildShopData = class("GuildShopData", ActivityData, true)

function GuildShopData:getUpdateTime()
	return xyd.getTomorrowTime()
end

function GuildShopData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function GuildShopData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	local days = xyd.tables.miscTable:split2Cost("guild_sale_refresh_days", "value", "|")
	local weekday = xyd.getGMTWeekDay(xyd.getServerTime())

	for i = 1, #days do
		if days[i] == 7 then
			days[i] = 0
		end

		if tonumber(weekday) == days[i] + 1 then
			return true
		end
	end

	return false
end

return GuildShopData
