local ActivityData = import("app.models.ActivityData")
local ActivityFireworkData = class("ActivityFireworkData", ActivityData, true)
local json = require("cjson")

function ActivityFireworkData:ctor(params)
	ActivityData.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.itemChange))
end

function ActivityFireworkData:getUpdateTime()
	return self:getEndTime()
end

function ActivityFireworkData:itemChange(event)
	local items = event.data.items

	for i, item in pairs(items) do
		if item.item_id == xyd.ItemID.FIRE_MATCH then
			xyd.models.activity:updateRedMarkCount(self.activity_id, function ()
				self.lastFireMatchNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIRE_MATCH)
			end)
		elseif item.item_id == xyd.ItemID.FIRE_MOMENT then
			xyd.models.activity:updateRedMarkCount(self.activity_id, function ()
				self.lastShopCanBut = self:isCanBuyShop()
			end)
		end
	end
end

function ActivityFireworkData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_FIREWORK, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_FIREWORK, true)

		return true
	end

	local flag = false
	local fireMatchNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.FIRE_MATCH)

	if not self.lastFireMatchNum then
		self.lastFireMatchNum = fireMatchNum
	end

	if self.lastFireMatchNum ~= fireMatchNum then
		if self.lastFireMatchNum > 0 then
			flag = true
		end
	elseif fireMatchNum > 0 then
		flag = true
	end

	if self.lastShopCanBut == nil then
		self.lastShopCanBut = self:isCanBuyShop()
	end

	if self.lastShopCanBut ~= self:isCanBuyShop() then
		if self.lastShopCanBut then
			flag = true
		end
	elseif self:isCanBuyShop() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_FIREWORK, flag)

	return flag
end

function ActivityFireworkData:isCanBuyShop()
	local costNum = self.detail.sta_cost

	for i in pairs(xyd.tables.activityFireworkShopRankTable:getIDs()) do
		local num = xyd.tables.activityFireworkShopRankTable:getPoint(i)

		if num <= costNum then
			for j, checkId in pairs(xyd.tables.activityFireworkShopTable:getRanksAward()[i]) do
				local limit = xyd.tables.activityFireworkShopTable:getLimit(checkId)
				local cost = xyd.tables.activityFireworkShopTable:getCost(checkId)

				if self.detail.buy_times[checkId] < limit and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
					return true
				end
			end
		end
	end

	return false
end

function ActivityFireworkData:onAward(data)
	if data.activity_id ~= self.activity_id then
		return
	end

	data = xyd.decodeProtoBuf(data)
	local info = json.decode(data.detail)

	dump(info, "test——firework——award——back========================")

	if info.award_type == xyd.FireWorkAwardType.FIRE then
		self.detail["fire_" .. info.mode].items = info.items
		self.detail["fire_" .. info.mode].status = json.decode(info.statuses[#info.statuses])
		self.detail.energy = self.detail.energy + info.mode * #info.statuses
	elseif info.award_type == xyd.FireWorkAwardType.SHOP then
		xyd.models.activity:updateRedMarkCount(self.activity_id, function ()
			self.detail.buy_times[tonumber(info.award_id)] = self.detail.buy_times[tonumber(info.award_id)] + tonumber(info.num)
			local cost = xyd.tables.activityFireworkShopTable:getCost(info.award_id)

			if cost[1] == xyd.ItemID.FIRE_MOMENT then
				self.detail.sta_cost = self.detail.sta_cost + tonumber(cost[2]) * tonumber(info.num)
			end

			self.lastShopCanBut = self:isCanBuyShop()
			local award = xyd.tables.activityFireworkShopTable:getAward(info.award_id)
			local itemArr = {
				{
					item_id = award[1],
					item_num = award[2] * info.num
				}
			}

			xyd.models.itemFloatModel:pushNewItems(itemArr)
		end)
	elseif info.award_type == xyd.FireWorkAwardType.POWER then
		local needPowerNum = xyd.tables.miscTable:getNumber("firework_energy", "value") * info.mode
		self.detail.energy = self.detail.energy - needPowerNum

		if self.detail.energy < 0 then
			self.detail.energy = 0
		end

		self.detail["fire_" .. info.mode].is_powered = 2
	elseif info.award_type == xyd.FireWorkAwardType.GET_AWARD then
		xyd.models.itemFloatModel:pushNewItems(info.items)

		local isAllGet = true

		for i in pairs(info.status) do
			if info.status[i] ~= 3 then
				isAllGet = false

				break
			end
		end

		if isAllGet then
			self.detail["fire_" .. info.mode].status = {
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0,
				0
			}
			self.detail.round = self.detail.round + 1 * info.mode
			self.detail["fire_" .. info.mode].items = {
				"",
				"",
				"",
				"",
				"",
				"",
				"",
				"",
				""
			}
			self.detail["fire_" .. info.mode].is_powered = 1
		else
			self.detail["fire_" .. info.mode].status = info.status
		end

		for i, item in pairs(info.items) do
			if self.detail.items[tostring(item.item_id)] then
				self.detail.items[tostring(item.item_id)] = self.detail.items[tostring(item.item_id)] + item.item_num
			else
				self.detail.items[tostring(item.item_id)] = item.item_num
			end
		end
	end
end

function ActivityFireworkData:updateFireMatchGet(num)
	if num > 0 then
		self.detail.sta_get = self.detail.sta_get + num
	end
end

return ActivityFireworkData
