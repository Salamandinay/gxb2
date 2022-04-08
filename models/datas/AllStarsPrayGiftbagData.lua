local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local AllStarsPrayGiftbagData = class("AllStarsPrayGiftbagData", ActivityData, true)

function AllStarsPrayGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function AllStarsPrayGiftbagData:onAward(data)
	if type(data) == "number" then
		local giftBagID = data

		for i = 1, #self.detail_.charges do
			if self.detail_.charges[i].table_id == giftBagID then
				self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
			end
		end
	else
		self.detail_.buy_times = json.decode(data.detail).buy_times
		local itemInfos = {}
		local awards = xyd.tables.activityPrayGiftTable:getAwards(self.buyIndex)

		for i = 1, #awards do
			local award = awards[i]

			table.insert(itemInfos, {
				item_id = award[1],
				item_num = award[2]
			})
		end

		xyd.itemFloat(itemInfos)
	end
end

function AllStarsPrayGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.defRedMark
end

function AllStarsPrayGiftbagData:setBuyIndex(buyIndex)
	self.buyIndex = buyIndex
end

return AllStarsPrayGiftbagData
