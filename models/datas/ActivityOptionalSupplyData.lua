local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityOptionalSupplyData = class("ActivityOptionalSupplyData", ActivityData, true)

function ActivityOptionalSupplyData:ctor(params)
	ActivityOptionalSupplyData.super.ctor(self, params)

	local chargeInfos = self.detail_.charge_infos

	for _, chargeInfo in ipairs(chargeInfos) do
		table.insert(self.detail_, chargeInfo)
	end

	self.selectAwards = {}
end

function ActivityOptionalSupplyData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function ActivityOptionalSupplyData:setData(params)
	ActivityOptionalSupplyData.super.setData(self, params)

	local chargeInfos = self.detail_.charge_infos

	for _, chargeInfo in ipairs(chargeInfos) do
		table.insert(self.detail_, chargeInfo)
	end
end

function ActivityOptionalSupplyData:onAward(data)
	local chargeInfos = self.detail_.charge_infos

	for _, chargeInfo in ipairs(chargeInfos) do
		if chargeInfo.charge.table_id == data then
			chargeInfo.charge.buy_times = chargeInfo.charge.buy_times + 1
		end
	end
end

function ActivityOptionalSupplyData:setSelectAwards(giftBagID, selectAwards)
	self.selectAwards[giftBagID] = selectAwards
end

function ActivityOptionalSupplyData:getSelectAwards(giftBagID)
	return self.selectAwards[giftBagID] or {}
end

return ActivityOptionalSupplyData
