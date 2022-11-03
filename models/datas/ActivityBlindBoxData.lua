local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBlindBoxData = class("ActivityBlindBoxData", ActivityData, true)

function ActivityBlindBoxData:ctor(params)
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.BLIND_BOX_TICKET)

	ActivityBlindBoxData.super.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityBlindBoxData:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == xyd.ItemID.BLIND_BOX_TICKET then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BLIND_BOX, function ()
				self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.BLIND_BOX_TICKET)
			end)

			break
		end
	end
end

function ActivityBlindBoxData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_BLIND_BOX then
		return
	end

	local data_ = xyd.decodeProtoBuf(data)

	if data_.detail then
		local info = require("cjson").decode(data_.detail)
		self.detail_ = info.info

		self:getRedMarkState()
	end
end

function ActivityBlindBoxData:getUpdateTime()
	return self:getEndTime()
end

function ActivityBlindBoxData:isSummoned()
	for i = 1, #self.detail_.buy_times do
		if self.detail_.buy_times[i] ~= 0 then
			return true
		end
	end

	return false
end

function ActivityBlindBoxData:getTotalWeight()
	for i = 1, 8 do
		if self.detail_.selects[i] == 0 then
			return -1
		end
	end

	local weight = 0
	local ids = self.detail_.selects
	local firstPrizeId = xyd.tables.activityBlindBoxTable:getFirstPrizeID(self.detail_.round)
	local firstPrizeResNum = xyd.tables.activityBlindBoxTable:getNum(firstPrizeId) - self.detail_.buy_times[1]
	weight = weight + xyd.tables.activityBlindBoxTable:getWeight(firstPrizeId) * firstPrizeResNum

	for i = 1, 8 do
		local awardResNum = xyd.tables.activityBlindBoxTable:getNum(ids[i]) - self.detail_.buy_times[i + 1]
		weight = weight + xyd.tables.activityBlindBoxTable:getWeight(ids[i]) * awardResNum
	end

	if weight == 0 then
		weight = 1
	end

	return weight
end

function ActivityBlindBoxData:getTotalRes()
	for i = 1, 8 do
		if self.detail_.selects[i] == 0 then
			return -1
		end
	end

	local ids = self.detail_.selects
	local firstPrizeId = xyd.tables.activityBlindBoxTable:getFirstPrizeID(self.detail_.round)
	local totalRes = xyd.tables.activityBlindBoxTable:getNum(firstPrizeId) - self.detail_.buy_times[1]

	for i = 1, 8 do
		totalRes = totalRes + xyd.tables.activityBlindBoxTable:getNum(ids[i]) - self.detail_.buy_times[i + 1]
	end

	return totalRes
end

function ActivityBlindBoxData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local redState = false

	if self.checkBackpackItemNum >= 1 then
		redState = true
	end

	if self:getTotalRes() == 0 then
		redState = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BLIND_BOX, redState)

	return redState
end

return ActivityBlindBoxData
