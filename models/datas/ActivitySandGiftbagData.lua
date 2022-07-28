local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySandGiftbagData = class("ActivitySandGiftbagData", ActivityData, true)

function ActivitySandGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySandGiftbagData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	return red
end

function ActivitySandGiftbagData:register()
	self.specialGiftbagID = xyd.tables.miscTable:getNumber("activity_sand_gift", "value")

	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id

		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
			end
		end
	end)
end

function ActivitySandGiftbagData:getDoubleAwardNum()
	local num = 0

	for index, value in ipairs(self.detail.counts) do
		if tonumber(value) > 0 then
			local award = xyd.tables.activitySandMissionTable:getPaidAwards(tonumber(index))

			if award and award[1] and award[1] == 390 then
				num = num + award[2] * value
			end
		end
	end

	return num
end

function ActivitySandGiftbagData:showRechargeAward(id, items)
	local realItems = {}

	for index, value in ipairs(items) do
		table.insert(realItems, value)
	end

	if id == self.specialGiftbagID and self:getDoubleAwardNum() > 0 then
		table.insert(realItems, {
			item_id = 390,
			item_num = self:getDoubleAwardNum()
		})
	end

	xyd.showRechargeAward(id, realItems)
end

function ActivitySandGiftbagData:haveBuySpecialGiftbag()
	local charges = self.detail.charges

	for i = 1, #charges do
		local giftBagID = tonumber(charges[i].table_id)

		if giftBagID == self.specialGiftbagID and charges[i].buy_times > 0 then
			return true
		end
	end

	return false
end

return ActivitySandGiftbagData
