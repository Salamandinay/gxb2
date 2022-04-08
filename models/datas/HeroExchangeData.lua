local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local HeroExchangeData = class("HeroExchangeData", ActivityData, true)

function HeroExchangeData:getUpdateTime()
	return self:getEndTime()
end

function HeroExchangeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local items = self.detail.items

	for i = 1, #items do
		if not items[i].buy_times then
			return self.defRedMark
		end
	end

	return false
end

function HeroExchangeData:judgeItem(itemID, itemList)
	for i = 1, #itemList do
		local item = itemList[i].item
		local cur_id = item[1]

		if cur_id == itemID then
			if not itemList[i].buy_times then
				return true
			end

			return false
		end
	end

	return false
end

return HeroExchangeData
