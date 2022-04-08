local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityOptionalSupplySuperData = class("ActivityOptionalSupplySuperData", ActivityData, true)

function ActivityOptionalSupplySuperData:ctor(params)
	ActivityOptionalSupplySuperData.super.ctor(self, params)

	local chargeInfos = self.detail_.charges

	for _, chargeInfo in ipairs(chargeInfos) do
		table.insert(self.detail_, {
			charge = {
				table_id = chargeInfo.table_id,
				buy_times = chargeInfo.buy_times,
				limit_times = chargeInfo.limit_times
			},
			update_time = chargeInfo.update_time,
			attach = chargeInfo.attach
		})
	end

	self.selectAwards = {}
	local lastPushTime = xyd.db.misc:getValue("activity_optional_supply_super_push")
	local lastTime = xyd.tables.giftBagTable:getLastTime(self.detail_[1].charge.table_id)

	if not lastPushTime or lastPushTime + lastTime < xyd.getServerTime() then
		local pushList = xyd.models.activity:getLimitGiftParams()

		for _, chargeInfo in ipairs(chargeInfos) do
			table.insert(pushList, {
				giftbag_id = chargeInfo.table_id,
				activity_id = self.activity_id
			})
		end
	end
end

function ActivityOptionalSupplySuperData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function ActivityOptionalSupplySuperData:setData(params)
	ActivityOptionalSupplySuperData.super.setData(self, params)

	local chargeInfos = self.detail_.charges

	for _, chargeInfo in ipairs(chargeInfos) do
		table.insert(self.detail_, {
			charge = {
				table_id = chargeInfo.table_id,
				buy_times = chargeInfo.buy_times,
				limit_times = chargeInfo.limit_times
			},
			update_time = chargeInfo.update_time,
			attach = chargeInfo.attach
		})
	end
end

function ActivityOptionalSupplySuperData:onAward(data)
	local chargeInfos = self.detail_.charges

	for _, chargeInfo in ipairs(chargeInfos) do
		if chargeInfo.table_id == data then
			chargeInfo.buy_times = chargeInfo.buy_times + 1
		end
	end

	for _, chargeInfo in ipairs(self.detail_) do
		if chargeInfo.charge.table_id == data then
			chargeInfo.charge.buy_times = chargeInfo.charge.buy_times + 1
		end
	end
end

function ActivityOptionalSupplySuperData:setSelectAwards(giftBagID, selectAwards)
	self.selectAwards[giftBagID] = selectAwards
end

function ActivityOptionalSupplySuperData:getSelectAwards(giftBagID)
	for _, chargeInfo in ipairs(self.detail_.charges) do
		if chargeInfo.table_id == giftBagID then
			if chargeInfo.buy_times < chargeInfo.limit_times then
				return {}
			end

			if not self.selectAwards[giftBagID] then
				self.selectAwards[giftBagID] = {}

				for i, index in ipairs(chargeInfo.attach) do
					local awards = xyd.tables.activityLevelPushOptionalTable:getAwards(giftBagID, i)
					self.selectAwards[giftBagID][i] = awards[index]
				end
			end

			return self.selectAwards[giftBagID]
		end
	end
end

return ActivityOptionalSupplySuperData
