local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local AllStarsPrayData = class("AllStarsPrayData", ActivityData, true)

function AllStarsPrayData:ctor(params)
	ActivityData.ctor(self, params)

	local wishCoinCost = xyd.tables.miscTable:split2Cost("activity_pray_cost", "value", "#")
	self.WishCoinID = wishCoinCost[1]
	self.singleCost_wishCoin = wishCoinCost[2]
	local ids = xyd.tables.activityPrayCostTable:getIDs()
	self.gemIDs = {}
	self.singleCosts_gem = {}
	self.groupFragmentIDs = {}
	self.needNumsOfGroupFragment = {}
	self.singleGetNum_GroupFragment = {}

	for i = 1, #ids do
		local id = i
		local gemCost = xyd.tables.activityPrayCostTable:getCost(id)
		local groupInfo = xyd.tables.activityPrayCostTable:getGroupFragment(id)

		table.insert(self.gemIDs, gemCost[1])
		table.insert(self.singleCosts_gem, gemCost[2])
		table.insert(self.groupFragmentIDs, groupInfo[1])
		table.insert(self.needNumsOfGroupFragment, xyd.tables.activityPrayCostTable:getMerge(id)[2])
		table.insert(self.singleGetNum_GroupFragment, xyd.tables.activityPrayCostTable:getGroupFragment(id)[2])
	end

	self.omniFragmentID = xyd.tables.activityPrayCostTable:getOmniFragment(1)[1]
	self.needOmniFragmentNum = xyd.tables.miscTable:split2Cost("activity_pray_omni_num", "value", "#")[2]
end

function AllStarsPrayData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function AllStarsPrayData:registerEvent()
	self.eventProxyInner_:addEventListener(xyd.event.USE_PRAY_ITEM, function (event)
		if event.data.items ~= nil then
			for key, value in pairs(event.data.items) do
				for key1, value1 in pairs(self.groupFragmentIDs) do
					if tonumber(value.item_id) == tonumber(value1) then
						-- Nothing
					end
				end
			end
		end
	end)
end

function AllStarsPrayData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false

	if self.singleCost_wishCoin <= xyd.models.backpack:getItemNumByID(self.WishCoinID) then
		return true
	end

	for i = 1, #self.gemIDs do
		if self.singleCosts_gem[i] <= xyd.models.backpack:getItemNumByID(self.gemIDs[i]) then
			return true
		end
	end

	if self:checkRedPoint_task() == true then
		return true
	end

	return flag
end

function AllStarsPrayData:checkRedPoint_wishCoin()
	local flag = false

	if self.singleCost_wishCoin <= xyd.models.backpack:getItemNumByID(self.WishCoinID) then
		return true
	end

	return flag
end

function AllStarsPrayData:checkRedPoint_gem(groupID)
	local flag = false

	if self.singleCosts_gem[groupID] <= xyd.models.backpack:getItemNumByID(self.gemIDs[groupID]) then
		return true
	end

	return flag
end

function AllStarsPrayData:checkRedPoint_task()
	local flag = false
	local ids = xyd.tables.activityPrayAwardTable:getIDs()

	for j in pairs(ids) do
		local data = {
			id = j,
			max_value = xyd.tables.activityPrayAwardTable:getComplete(j),
			cur_value = tonumber(self.detail.finish_times)
		}

		if data.max_value < data.cur_value then
			data.cur_value = data.max_value
		end

		if self.detail.award_records[j] == 0 and data.max_value <= self.detail.finish_times then
			flag = true
		end
	end

	return flag
end

return AllStarsPrayData
