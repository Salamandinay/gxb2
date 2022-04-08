local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local LevelFundData = class("LevelFundData", ActivityData, true)

function LevelFundData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function LevelFundData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	local giftId = xyd.tables.activityTable:getGiftBag(self.id)[1]
	local limitNum = xyd.tables.giftBagTable:getBuyLimit(giftId)

	if self.detail.charges[1].buy_times < limitNum then
		return false
	elseif xyd.tables.activityLevelUpTable:getLevel(#xyd.tables.activityLevelUpTable:getIds()) <= xyd.models.backpack:getLev() then
		return true
	end

	return false
end

function LevelFundData:backRank()
	return self.detail.charges[1].buy_times >= 1
end

function LevelFundData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

return LevelFundData
