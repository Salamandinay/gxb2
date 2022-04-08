local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmasExchangeData = class("ActivityChristmasExchangeData", ActivityData, true)
local slotModel = xyd.models.slot

function ActivityChristmasExchangeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChristmasExchangeData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if xyd.models.backpack:getItemNumByID(311) >= 60 and self.perLogin == true then
		red = true
	end

	return red
end

function ActivityChristmasExchangeData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_CHRISTMAS_EXCHANGE then
			local detail = json.decode(data.detail)

			if self.sendMsg.type == 1 then
				if self.sendMsg.tabIndex == 1 then
					xyd.WindowManager.get():openWindow("summon_effect_res_window", {
						partners = {
							self.sendMsg.award_id
						},
						xyd.alertItems({
							{
								item_num = 1,
								item_id = self.sendMsg.award_id
							}
						})
					})
				elseif self.sendMsg.tabIndex == 2 then
					xyd.WindowManager.get():openWindow("summon_effect_res_window", {
						skins = {
							self.sendMsg.award_id
						},
						callback = function ()
							xyd.alertItems({
								{
									item_num = 1,
									item_id = self.sendMsg.award_id
								}
							})
						end
					})
				elseif self.sendMsg.tabIndex == 3 then
					xyd.alertItems({
						{
							item_num = 1,
							item_id = self.sendMsg.award_id
						}
					})
				end

				self.detail.times[self.oldCardTableRow[self.sendMsg.tabIndex]] = self.detail.times[self.oldCardTableRow[self.sendMsg.tabIndex]] + 1
				self.oldCardTableRow[self.sendMsg.tabIndex] = nil
			elseif self.sendMsg.type == 2 then
				local items = detail.items

				xyd.models.itemFloatModel:pushNewItems(items)

				self.detail.buy_times = self.detail.buy_times + detail.num
			end

			if detail.num and detail.items then
				return
			end

			self.oldCardData = {}
			self.newCardData = {}
			self.exchangeData = {}
			self.oldCardTableRow = {}
		end
	end)

	self.oldCardData = {}
	self.newCardData = {}
	self.exchangeData = {}
	self.oldCardTableRow = {}
	self.helpPartnerList = {}
	local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

	for i = 1, #ids do
		local type = xyd.tables.activityChristmasSocksExchangeTable:getType(i)

		if type == 1 then
			local costCard = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(i)

			for j = 1, #costCard do
				local costItemID = costCard[j][1]

				if not self.helpPartnerList[costItemID] then
					self.helpPartnerList[costItemID] = 1
				end
			end
		end
	end

	self.perLogin = true
end

function ActivityChristmasExchangeData:getResource()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_get", "value", "#")

	return data
end

function ActivityChristmasExchangeData:getSingleCost(index)
	if not self.oldCardData[index] then
		return
	end

	local tableRow = self.oldCardTableRow[index]
	local cost = xyd.tables.activityChristmasSocksExchangeTable:getCost(tableRow)

	return cost
end

function ActivityChristmasExchangeData:getLeftTime(index)
	local type = index
	local limitTime = nil
	local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

	for i = 1, #ids do
		if xyd.tables.activityChristmasSocksExchangeTable:getType(i) == type then
			limitTime = xyd.tables.activityChristmasSocksExchangeTable:getLimit(i)
		end
	end

	local times = 0

	for i = 1, #ids do
		if xyd.tables.activityChristmasSocksExchangeTable:getType(i) == type then
			times = times + self.detail.times[i]
		end
	end

	local leftTime = limitTime - times

	return leftTime
end

function ActivityChristmasExchangeData:getOldCardData(index)
	return self.oldCardData[index]
end

function ActivityChristmasExchangeData:getNewCardData(index)
	if not self.newCardData[index] then
		return nil
	end

	local index1 = self.newCardData[index]

	return self.exchangeData[index].awards[index1].colIndex
end

function ActivityChristmasExchangeData:ChooseNewCard(tabIndex, selectedIndexId)
	self.newCardData[tabIndex] = selectedIndexId

	if selectedIndexId and self.exchangeData[tabIndex].awards[selectedIndexId] and self.exchangeData[tabIndex].awards[selectedIndexId].tableRow then
		self.oldCardTableRow[tabIndex] = self.exchangeData[tabIndex].awards[selectedIndexId].tableRow
		self.exchangeData[tabIndex].tableID = self.exchangeData[tabIndex].awards[selectedIndexId].tableRow
	end
end

function ActivityChristmasExchangeData:ChooseOldCard(tabIndex, selectedIndexId)
	self.oldCardData[tabIndex] = selectedIndexId
	self.newCardData[tabIndex] = nil

	if self.exchangeData[tabIndex] then
		self.exchangeData[tabIndex].awards = {}
		self.exchangeData[tabIndex].tableID = nil
	end

	self.oldCardTableRow[tabIndex] = nil

	if selectedIndexId == nil then
		return
	end

	local itemID = self.oldCardData[tabIndex]

	if tabIndex == 1 then
		local oldPartner = slotModel:getPartner(self.oldCardData[tabIndex])
		itemID = oldPartner:getTableID()
	end

	local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

	for i = 1, #ids do
		local type = xyd.tables.activityChristmasSocksExchangeTable:getType(i)

		if tabIndex == type then
			local costCards = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(i)

			for j = 1, #costCards do
				if costCards[j][1] == itemID then
					self.oldCardTableRow[tabIndex] = i
				end
			end
		end
	end
end

function ActivityChristmasExchangeData:getCanChooseOldData(tabIndex)
	local datas = {}

	if tabIndex == 1 then
		local havePartnerList = xyd.models.slot:getPartners()

		for key, partner in pairs(havePartnerList) do
			local lev = partner:getLevel()
			local star = partner:getStar()
			local partnerID = partner:getPartnerID()

			if lev == 1 and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) and star == 5 and self.helpPartnerList[partner:getTableID()] then
				table.insert(datas, {
					itemNum = 1,
					indexID = partnerID,
					itemID = partner:getTableID(),
					lev = partner:getLevel(),
					lock = partner:isLockFlag()
				})
			end
		end
	elseif tabIndex == 2 or tabIndex == 3 then
		local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChristmasSocksExchangeTable:getType(i)

			if tabIndex == type then
				local costCard = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(i)

				for j = 1, #costCard do
					local costItemID = costCard[j][1]
					local haveNum = xyd.models.backpack:getItemNumByID(costItemID)

					if haveNum and haveNum > 0 then
						local flag = false

						for k = 1, #datas do
							if datas[k].indexID == costItemID then
								flag = true
							end
						end

						if flag == false then
							table.insert(datas, {
								indexID = costItemID,
								itemID = costItemID,
								itemNum = haveNum
							})
						end
					end
				end
			end
		end
	end

	return datas
end

function ActivityChristmasExchangeData:getCanChooseNewData(tabIndex)
	self.exchangeData[tabIndex] = {
		awards = {},
		tableID = nil
	}
	local oldData = self:getOldCardData(tabIndex)
	local awards = {}
	local tableID = nil

	if tabIndex == 1 then
		local oldPartner = slotModel:getPartner(oldData)
		local oldTableID = oldPartner:getTableID()

		print(oldData)

		local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChristmasSocksExchangeTable:getType(i)

			print(type)

			if tabIndex == type then
				local costCards = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(i)

				for j = 1, #costCards do
					if costCards[j][1] == oldTableID then
						tableID = i

						table.insert(awards, {
							awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(i),
							tableRow = i
						})
					end
				end
			end
		end

		self.exchangeData[tabIndex].awards = {}
		self.exchangeData[tabIndex].tableID = tableID

		for i = 1, #awards do
			for j = 1, #awards[i].awards do
				local flag = false

				if oldTableID == awards[i].awards[j][1] then
					flag = true
				end

				for k = 1, #self.exchangeData[tabIndex].awards do
					if self.exchangeData[tabIndex].awards[k].itemID == awards[i].awards[j][1] then
						flag = true
					end
				end

				if flag == false then
					table.insert(self.exchangeData[tabIndex].awards, {
						lev = 1,
						indexID = #self.exchangeData[tabIndex].awards + 1,
						itemID = awards[i].awards[j][1],
						itemNum = awards[i].awards[j][2],
						tableRow = awards[i].tableRow,
						colIndex = j
					})
				end
			end
		end
	elseif tabIndex == 2 or tabIndex == 3 then
		local ids = xyd.tables.activityChristmasSocksExchangeTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChristmasSocksExchangeTable:getType(i)

			print(type)

			if tabIndex == type then
				local costCards = xyd.tables.activityChristmasSocksExchangeTable:getCostCard(i)

				for j = 1, #costCards do
					if costCards[j][1] == oldData then
						tableID = i

						table.insert(awards, {
							awards = xyd.tables.activityChristmasSocksExchangeTable:getAwards(i),
							tableRow = i
						})
					end
				end
			end
		end

		self.exchangeData[tabIndex].awards = {}
		self.exchangeData[tabIndex].tableID = tableID

		for i = 1, #awards do
			for j = 1, #awards[i].awards do
				local flag = false

				if oldData == awards[i].awards[j][1] then
					flag = true
				end

				for k = 1, #self.exchangeData[tabIndex].awards do
					if self.exchangeData[tabIndex].awards[k].itemID == awards[i].awards[j][1] then
						flag = true
					end
				end

				if flag == false then
					table.insert(self.exchangeData[tabIndex].awards, {
						lev = 1,
						indexID = #self.exchangeData[tabIndex].awards + 1,
						itemID = awards[i].awards[j][1],
						itemNum = awards[i].awards[j][2],
						tableRow = awards[i].tableRow,
						colIndex = j
					})
				end
			end
		end
	end

	return self.exchangeData[tabIndex].awards
end

function ActivityChristmasExchangeData:getBuyLeftTime()
	local limitTime = xyd.tables.miscTable:getNumber("activity_christmas_socks_buy_limit", "value")
	local times = self.detail.buy_times
	local leftTime = limitTime - times

	return leftTime
end

function ActivityChristmasExchangeData:getBuySingleCost()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_buy", "value", "|#")
	local cost = data[1]

	return cost
end

function ActivityChristmasExchangeData:getBuySingleGet()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_buy", "value", "|#")
	local cost = data[2]

	return cost
end

function ActivityChristmasExchangeData:clearData()
	self.oldCardData = {}
	self.newCardData = {}
	self.exchangeData = {}
	self.oldCardTableRow = {}
end

return ActivityChristmasExchangeData
