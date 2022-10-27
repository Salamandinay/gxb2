local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityRelayGiftNewData = class("ActivityRelayGiftNewData", ActivityData, true)

function ActivityRelayGiftNewData:getUpdateTime()
	return self.detail.start_time + 604800
end

function ActivityRelayGiftNewData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	if not red and self:getRedPointOfGiftbag() == true then
		red = true
	end

	return red
end

function ActivityRelayGiftNewData:register()
	self.mainActivityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)

	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id

		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				self:getRedMarkState()
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW then
			local detail = json.decode(data.detail)
			self.detail.awarded_id = detail.awarded_id
		end
	end)

	self.paidGiftBagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_RELAY_GIFT_NEW)
	self.freeGiftbagIDs = xyd.tables.activityRelayGiftNewTable:getIDs()
	self.giftBagIDs = {}
	local paidCount = 1
	local freeCount = 1

	for i = 1, #self.paidGiftBagIDs + #self.freeGiftbagIDs do
		local count = #self.giftBagIDs

		if count == 0 then
			table.insert(self.giftBagIDs, self.paidGiftBagIDs[paidCount])

			paidCount = paidCount + 1
		elseif freeCount <= #self.freeGiftbagIDs then
			if self.giftBagIDs[count] <= #self.freeGiftbagIDs and xyd.tables.activityRelayGiftNewTable:getPreAwardId(freeCount) == self.giftBagIDs[count] then
				table.insert(self.giftBagIDs, self.freeGiftbagIDs[freeCount])

				freeCount = freeCount + 1
			elseif self.giftBagIDs[count] > #self.freeGiftbagIDs and xyd.tables.activityRelayGiftNewTable:getPreGiftbagId(freeCount) == self.giftBagIDs[count] then
				table.insert(self.giftBagIDs, self.freeGiftbagIDs[freeCount])

				freeCount = freeCount + 1
			else
				table.insert(self.giftBagIDs, self.paidGiftBagIDs[paidCount])

				paidCount = paidCount + 1
			end
		else
			table.insert(self.giftBagIDs, self.paidGiftBagIDs[paidCount])

			paidCount = paidCount + 1
		end
	end
end

function ActivityRelayGiftNewData:getRedPointOfGiftbag()
	local index = self:getCurIndex()

	if self.giftBagIDs[index] and self.giftBagIDs[index] <= #self.freeGiftbagIDs then
		return true
	end

	return false
end

function ActivityRelayGiftNewData:getGiftIDs()
	return self.giftBagIDs
end

function ActivityRelayGiftNewData:getPaidGiftIDs()
	return self.paidGiftBagIDs
end

function ActivityRelayGiftNewData:getFreeGiftIDs()
	return self.freeGiftbagIDs
end

function ActivityRelayGiftNewData:getCharge(tableID)
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == tableID then
			return self.detail.charges[i]
		end
	end

	return nil
end

function ActivityRelayGiftNewData:getCurIndex()
	for i = 1, #self.giftBagIDs do
		if self.giftBagIDs[i] <= #self.freeGiftbagIDs then
			if self.detail.awarded_id <= 0 or self.detail.awarded_id < self.giftBagIDs[i] then
				return i
			end
		else
			for j = 1, #self.detail.charges do
				if self.detail.charges[j].table_id == self.giftBagIDs[i] and self.detail.charges[j].buy_times < self.detail.charges[j].limit_times then
					return i
				end
			end
		end
	end

	return #self.giftBagIDs + 1
end

return ActivityRelayGiftNewData
