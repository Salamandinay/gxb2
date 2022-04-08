local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local SuperHeroClubData = class("SuperHeroClubData", GiftBagData, true)

function SuperHeroClubData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function SuperHeroClubData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local nowRound = self.detail.round_id
	local newIds = xyd.tables.activityPartnerJackpotTable:getNewIds(nowRound)
	local value = xyd.db.misc:getValue("partner_jackpot_records")
	local recordIds = {}

	if value then
		recordIds = json.decode(value)
	end

	for _, id in ipairs(newIds) do
		if xyd.arrayIndexOf(recordIds, id) < 1 then
			return true
		end
	end

	return false
end

return SuperHeroClubData
