local ActivityData = import("app.models.ActivityData")
local ActivityChildhoodShopData = class("ActivityChildhoodShopData", ActivityData, true)
local cjson = require("cjson")

function ActivityChildhoodShopData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChildhoodShopData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP then
		return
	end

	local detail = cjson.decode(data.detail)

	if detail.type == 1 then
		self.detail.buy_times[self.reqParams.award_id] = self.detail.buy_times[self.reqParams.award_id] + self.reqParams.num
		local awards = xyd.tables.activityChildrenShopTable:getAward(self.reqParams.award_id)
		local datas = {}

		for _, award in ipairs(awards) do
			table.insert(datas, {
				item_id = award[1],
				item_num = award[2] * self.reqParams.num
			})
		end

		xyd.models.itemFloatModel:pushNewItems(datas)
	elseif detail.type == 2 then
		self.extraAward = detail.awards
		self.detail.items = detail.items
	elseif detail.type == 3 then
		self.detail.buy = self.detail.buy + self.reqParams.num
		local datas = {}

		table.insert(datas, {
			item_id = xyd.ItemID.CHILDHOOD_SHOP_BALLOON,
			item_num = self.reqParams.num
		})
		xyd.models.itemFloatModel:pushNewItems(datas)
	else
		local datas = {}

		if self.extraAward and #self.extraAward > 0 then
			for _, award in ipairs(self.extraAward) do
				table.insert(datas, {
					item_id = award.item_id,
					item_num = award.item_num
				})
			end
		end

		for i = 1, #self.choose do
			local awards = self:splitAward(self.detail.items[i])
			local index = self.choose[i]

			table.insert(datas, {
				item_id = awards[index][1],
				item_num = awards[index][2]
			})
		end

		xyd.models.itemFloatModel:pushNewItems(datas)

		self.extraAward = nil
		self.detail.items = nil
		self.choose = nil
	end
end

function ActivityChildhoodShopData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP, function ()
		self.holdRed = false
	end)
end

function ActivityChildhoodShopData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
		local gachaCost = xyd.tables.miscTable:split2Cost("activity_children_gamble_cost", "value", "#")

		if gachaCost[2] <= xyd.models.backpack:getItemNumByID(gachaCost[1]) then
			self.defRedMark = true
		end

		local finishType1 = true
		local lastIDofEachLine = {}
		local ids = xyd.tables.activityChildrenShopTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

			if type == 1 then
				local line = xyd.tables.activityChildrenShopTable:getLine(ids[i])

				if self.detail.buy_times[ids[i]] == 0 then
					finishType1 = false
					local timeStamp = xyd.db.misc:getValue("activity_childhood_shop_exchange_line_view_time" .. line)

					if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
						local condition = xyd.tables.activityChildrenShopTable:getCondition(ids[i])
						local cost = xyd.tables.activityChildrenShopTable:getCost(ids[i])

						if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.detail.buy_times[condition] ~= 0 then
							self.defRedMark = true
						end
					end
				end

				lastIDofEachLine[line] = ids[i]
			end

			if type == 2 then
				local cost = xyd.tables.activityChildrenShopTable:getCost(ids[i])

				if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.detail.buy_times[ids[i]] == 0 and finishType1 then
					self.defRedMark = true
				end
			end
		end

		for i = 1, 4 do
			local id = lastIDofEachLine[i]
			local condition = xyd.tables.activityChildrenShopTable:getCondition(id)
			local cost = xyd.tables.activityChildrenShopTable:getCost(id)

			if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.detail.buy_times[id] == 0 and self.detail.buy_times[condition] ~= 0 then
				self.defRedMark = true
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHILDREN_TASK, self.defRedMark)

	return self.defRedMark
end

function ActivityChildhoodShopData:sendReq(params)
	self.reqParams = params

	if params.type == 4 then
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP, cjson.encode({
			type = 4,
			indexs = self.choose
		}))
	else
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP, cjson.encode(params))
	end
end

function ActivityChildhoodShopData:clearChoose()
	self.choose = nil
end

function ActivityChildhoodShopData:setChoose(index)
	if not self.choose then
		self.choose = {}
	end

	table.insert(self.choose, index)

	if #self.choose == #self.detail.items then
		self:sendReq({
			type = 4
		})
	end
end

function ActivityChildhoodShopData:splitAward(items)
	local result = {}
	local sp = xyd.split(items, "|")

	for i = 1, #sp do
		result[i] = xyd.split(sp[i], "#", true)
	end

	return result
end

return ActivityChildhoodShopData
