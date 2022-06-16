local DressShow = class("DressShow", import(".BaseModel"))
local shopModel = xyd.models.shop

function DressShow:ctor()
	self.showCaseInfo_ = {}
	self.buffs_ = {}
	self.dressToSlotList_ = {}

	DressShow.super.ctor(self)
	self:reqShop1Data()
end

function DressShow:checkDressAddType(dress_id, dress_item_id, slot_id)
	local addType = xyd.tables.dressShowSlotTable:getAddType(slot_id)
	local addNum = xyd.tables.dressShowSlotTable:getAddNum(slot_id)
	local checkFunctionList = {
		function (num)
			local pos = xyd.tables.senpaiDressTable:getPos(dress_id)

			if pos == num then
				return true
			end
		end,
		function (num)
			local qlt = xyd.tables.senpaiDressItemTable:getQlt(dress_item_id)

			if num <= qlt then
				return true
			end
		end,
		function (num)
			local star = xyd.tables.senpaiDressItemTable:getStar(dress_item_id)

			if num <= star then
				return true
			end
		end,
		function (num)
			local base1 = xyd.tables.senpaiDressItemTable:getBase1(dress_item_id)

			if num <= base1 then
				return true
			end
		end,
		function (num)
			local base2 = xyd.tables.senpaiDressItemTable:getBase2(dress_item_id)

			if num <= base2 then
				return true
			end
		end,
		function (num)
			local base3 = xyd.tables.senpaiDressItemTable:getBase3(dress_item_id)

			if num <= base3 then
				return true
			end
		end
	}
	local canAdd = true

	for i = 1, #addType do
		local num = addNum[i]

		if not checkFunctionList[addType[i]](num) then
			canAdd = false

			break
		end
	end

	return canAdd
end

function DressShow:getDressItem(slot_id)
	local data = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slot_id)
	local show_id = data.show_id
	local index = data.index

	if not self.showCaseInfo_[show_id] then
		return 0
	elseif not self.showCaseInfo_[show_id].slots or self.showCaseInfo_[show_id].slots[index] < 0 then
		return 0
	else
		return self.showCaseInfo_[show_id].slots[index]
	end
end

function DressShow:checkUnlcok(slot_id)
	local data = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slot_id)
	local show_id = data.show_id
	local index = data.index

	if not self.showCaseInfo_[show_id] then
		return false
	elseif not self.showCaseInfo_[show_id].slots or self.showCaseInfo_[show_id].slots[index] < 0 then
		return false
	else
		return true
	end
end

function DressShow:getShowSlotByItem(dress_item_id)
	return self.dressToSlotList_[dress_item_id]
end

function DressShow:checkUnlockCondition(slot_id)
	local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(slot_id)
	local unlockNum = xyd.tables.dressShowSlotTable:getUnlockNum(slot_id)

	if not unlockType or unlockType == 0 then
		return true
	elseif unlockType == 1 then
		local baseNum = xyd.models.dress:getAttrs()[1]

		return unlockNum <= baseNum
	elseif unlockType == 2 then
		local baseNum = xyd.models.dress:getAttrs()[2]

		return unlockNum <= baseNum
	elseif unlockType == 3 then
		local baseNum = xyd.models.dress:getAttrs()[3]

		return unlockNum <= baseNum
	elseif unlockType == 4 then
		local stage = xyd.models.towerMap.stage - 1

		return unlockNum <= stage
	elseif unlockType == 5 then
		local stage = xyd.models.dungeon:getHistoryStage() - 1

		return unlockNum <= stage
	elseif unlockType == 6 then
		local level = xyd.models.friendTeamBoss:getMaxHistory()

		return unlockNum <= level
	elseif unlockType == 7 then
		local score = xyd.models.academyAssessment.historyScore

		return unlockNum <= score
	end

	return false
end

function DressShow:getUnlockValueNow(slot_id)
	local unlockType = xyd.tables.dressShowSlotTable:getUnlockType(slot_id)

	if not unlockType or unlockType == 0 then
		return 0
	elseif unlockType == 1 then
		local baseNum = xyd.models.dress:getAttrs()[1]

		return baseNum
	elseif unlockType == 2 then
		local baseNum = xyd.models.dress:getAttrs()[2]

		return baseNum
	elseif unlockType == 3 then
		local baseNum = xyd.models.dress:getAttrs()[3]

		return baseNum
	elseif unlockType == 4 then
		local stage = xyd.models.towerMap.stage - 1

		return stage
	elseif unlockType == 5 then
		local stage = xyd.models.dungeon:getHistoryStage() - 1

		if stage < 0 then
			stage = 0
		end

		return stage
	elseif unlockType == 6 then
		local level = xyd.models.friendTeamBoss:getMaxHistory()

		return level
	elseif unlockType == 7 then
		local score = xyd.models.academyAssessment.historyScore

		return score
	end
end

function DressShow:getTotalScore()
	local score = 0

	for i = 1, 4 do
		if self.showCaseInfo_[i] and self.showCaseInfo_[i].score then
			score = score + self.showCaseInfo_[i].score
		end
	end

	return score
end

function DressShow:getHistoryTotalScore()
	if not self.historyPoint_ then
		self.historyPoint_ = 0
	end

	return self.historyPoint_
end

function DressShow:getAwardsByShowID(show_id)
	local score = self:getScore(show_id)
	local ids = xyd.tables.dressShowAwardTable:getGroupIds(show_id)
	local curAwardData = {}

	for i = 1, #ids do
		local tableID = ids[i]
		local data = {
			point = xyd.tables.dressShowAwardTable:getPoint(tableID),
			awards = xyd.tables.dressShowAwardTable:getAwards(tableID)
		}

		if score < data.point and i > 1 then
			curAwardData = xyd.tables.dressShowAwardTable:getAwards(ids[i - 1])

			break
		elseif score < data.point and i == 1 then
			return {
				{
					314,
					0
				},
				{
					315,
					0
				}
			}
		end
	end

	return curAwardData
end

function DressShow:getScore(show_id)
	if self.showCaseInfo_[show_id] and self.showCaseInfo_[show_id].score then
		return self.showCaseInfo_[show_id].score
	else
		return 0
	end
end

function DressShow:getLevelByScore(score)
	local list = xyd.tables.miscTable:split2Cost("show_window_point_rank", "value", "|")

	for i = #list, 1, -1 do
		if list[i] <= score then
			return i
		end
	end

	return 1
end

function DressShow:getSlotItemByIndex(show_id, index)
	if self.showCaseInfo_[show_id] and self.showCaseInfo_[show_id].slots then
		return self.showCaseInfo_[show_id].slots[index] or -1
	else
		return -1
	end
end

function DressShow:getSlotState(slot_id)
	local showCase = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slot_id)
	local show_id = showCase.show_id
	local index = showCase.index

	if self.showCaseInfo_[show_id] and self.showCaseInfo_[show_id].slots then
		return self.showCaseInfo_[show_id].slots[index] or -1
	else
		return -1
	end
end

function DressShow:getAwardTime(show_id)
	if self.showCaseInfo_[show_id] and tonumber(self.showCaseInfo_[show_id].award_time) then
		return self.showCaseInfo_[show_id].award_time
	else
		return xyd.getServerTime()
	end
end

function DressShow:onRegister()
	self:registerEvent(xyd.event.SHOW_WINDOW_GET_INFO, handler(self, self.onGetShowCaseInfo))
	self:registerEvent(xyd.event.SHOW_WINDOW_EQUIP_ONE, handler(self, self.onEquipOne))
	self:registerEvent(xyd.event.SHOW_WINDOW_EQUIPS, handler(self, self.onEquips))
	self:registerEvent(xyd.event.SHOW_WINDOW_UNLOCK_SLOT, handler(self, self.onUnlockSlot))
	self:registerEvent(xyd.event.SHOW_WINDOW_GET_SHOP_INFO, handler(self, self.onGetShopInfo))
	self:registerEvent(xyd.event.SHOW_WINDOW_BUY_BUFF, handler(self, self.onBuyBuff))
	self:registerEvent(xyd.event.SHOW_WINDOW_GET_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.BUY_SHOP_ITEM, handler(self, self.onBuyShopItem))
end

function DressShow:updateDressToSlot()
	self.dressToSlotList_ = {}

	for i = 1, 4 do
		if self.showCaseInfo_[i] and self.showCaseInfo_[i].slots then
			for index, value in ipairs(self.showCaseInfo_[i].slots) do
				if value and value > 0 then
					local slot_ids = xyd.tables.dressShowWindowTable:getSlotIDs(i)
					local dress_id = xyd.tables.senpaiDressItemTable:getDressId(value)
					self.dressToSlotList_[dress_id] = slot_ids[index]
				end
			end
		end
	end
end

function DressShow:setShowWindowInfo(show_window_info)
	for i = 1, 4 do
		if show_window_info[i] and tostring(show_window_info[i]) ~= "" then
			self.showCaseInfo_[i] = show_window_info[i]
		else
			self.showCaseInfo_[i] = {}
		end
	end

	self:updateDressToSlot()
	self:updateRedMark()
end

function DressShow:getShowCaseInfo(show_id)
	show_id = show_id or 1

	if not self["reqShowCaseInfoTime" .. show_id] or xyd.getServerTime() - self["reqShowCaseInfoTime" .. show_id] > 60 then
		local msg = messages_pb.show_window_get_info_req()
		msg.show_id = show_id

		xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_GET_INFO, msg)

		self["reqShowCaseInfoTime" .. show_id] = xyd.getServerTime()
		self.tempShowCase_ = show_id

		return true
	else
		return false
	end
end

function DressShow:onGetShowCaseInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	if self.tempShowCase_ then
		self.showCaseInfo_[self.tempShowCase_] = data
		self.tempShowCase_ = nil
	end

	self:updateDressToSlot()
	self:updateRedMark()
end

function DressShow:equipOne(show_id, index, item_id)
	local msg = messages_pb.show_window_equip_one_req()
	msg.show_id = show_id
	msg.index = index
	msg.item_id = item_id

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_EQUIP_ONE, msg)

	self.tempEquipOneShowID_ = show_id
end

function DressShow:clearSlot(slot_id)
	local showCase = xyd.tables.dressShowWindowTable:getShowCaseBySlot(slot_id)
	local msg = messages_pb.show_window_equip_one_req()
	msg.show_id = showCase.show_id
	msg.index = showCase.index
	msg.item_id = 0

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_EQUIP_ONE, msg)

	self.tempEquipOneShowID_ = showCase.show_id
end

function DressShow:onEquipOne(event)
	local data = xyd.decodeProtoBuf(event.data)
	local add = data.add

	if self.tempEquipOneShowID_ then
		self.showCaseInfo_[self.tempEquipOneShowID_].slots[data.index] = data.item_id or 0
		self.showCaseInfo_[self.tempEquipOneShowID_].score = self.showCaseInfo_[self.tempEquipOneShowID_].score + add
		self.tempEquipOneShowID_ = nil
	end

	self:updateDressToSlot()
	self:updataHistoryScore()
end

function DressShow:updataHistoryScore()
	local curScore = self:getTotalScore()

	if self:getHistoryTotalScore() < curScore then
		self.historyPoint_ = curScore
	end
end

function DressShow:equips(show_id, item_ids)
	local msg = messages_pb.show_window_equips_req()
	msg.show_id = show_id

	for _, item_id in ipairs(item_ids) do
		table.insert(msg.item_ids, item_id)
	end

	for index, value in ipairs(self.showCaseInfo_[show_id].slots) do
		if value >= 0 and self.showCaseInfo_[show_id].slots[index] ~= item_ids[index] then
			table.insert(msg.clear_ids, index)
		end
	end

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_EQUIPS, msg)

	self.tempEquipShowID_ = show_id
end

function DressShow:onEquips(event)
	local data = xyd.decodeProtoBuf(event.data)
	local info = data.info

	if self.tempEquipShowID_ then
		self.showCaseInfo_[self.tempEquipShowID_] = info
	end

	self:updateDressToSlot()
	self:updataHistoryScore()
end

function DressShow:unLockSlot(show_id, index)
	local msg = messages_pb.show_window_unlock_slot_req()
	msg.show_id = show_id
	msg.index = index

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_UNLOCK_SLOT, msg)

	self.tempEquipShowID_ = show_id
end

function DressShow:onUnlockSlot(event)
	local data = xyd.decodeProtoBuf(event.data)

	if self.tempEquipShowID_ then
		self.showCaseInfo_[self.tempEquipShowID_].slots[data.index] = 0
	end

	self:updateDressToSlot()
end

function DressShow:getShopInfo()
	local msg = messages_pb.show_window_get_shop_info_req()

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_GET_SHOP_INFO, msg)
end

function DressShow:onGetShopInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.historyPoint_ = data.history
	self.buffs_ = data.buffs

	dump(self.buffs_, "===================DressShow==================,self.buffs_,")
end

function DressShow:buyBuff(table_id, num)
	local msg = messages_pb.show_window_buy_buff_req()
	msg.table_id = table_id
	msg.num = num

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_BUY_BUFF, msg)
end

function DressShow:onBuyBuff(event)
	local data = xyd.decodeProtoBuf(event.data)

	if not self.buffs_[data.table_id] then
		self.buffs_[data.table_id] = {}
	end

	if not self.buffs_[data.table_id].times then
		self.buffs_[data.table_id].times = {}
	end

	for i = 1, data.num do
		table.insert(self.buffs_[data.table_id].times, xyd.tables.dressShowWindowShop1Table:getNum(data.table_id))
	end

	if not self.buffs_[data.table_id].buy_times then
		self.buffs_[data.table_id].buy_times = 0
	end

	self.buffs_[data.table_id].buy_times = self.buffs_[data.table_id].buy_times + data.num
end

function DressShow:reqGetAward()
	local msg = messages_pb.show_window_get_award_req()

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_GET_AWARD, msg)
end

function DressShow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.results and tostring(data.results) ~= "" then
		for _, info in ipairs(data.results) do
			local show_id = info.show_id
			self.showCaseInfo_[show_id].award_time = info.award_time
		end
	end

	self:updateRedMark()
end

function DressShow:onBuyShopItem(event)
end

function DressShow:checkCanGetAward()
	for i = 1, 4 do
		if self.showCaseInfo_[i] and self.showCaseInfo_[i].award_time then
			if not xyd.isSameDay(self.showCaseInfo_[i].award_time, xyd.getServerTime()) then
				return true
			end
		elseif self.showCaseInfo_[i] and self.showCaseInfo_[i].score and self.showCaseInfo_[i].score > 0 and (not self.showCaseInfo_[i].award_time or self.showCaseInfo_[i].award_time == 0) then
			return true
		end
	end

	return false
end

function DressShow:getShop1Data()
	self.shop1Data = {}
	local ids = xyd.tables.dressShowWindowShop1Table:getIDs()

	for i = 1, #ids do
		local awakeTime = 0

		if self.buffs_ and self.buffs_[i] and self.buffs_[i].times then
			awakeTime = #self.buffs_[i].times
		end

		local buyTime = 0

		if self.buffs_ and self.buffs_[i] and self.buffs_[i].buy_times then
			buyTime = self.buffs_[i].buy_times
		end

		local data = {
			tableID = i,
			limitTime = xyd.tables.dressShowWindowShop1Table:getBuyTime(i),
			maxTime = xyd.tables.dressShowWindowShop1Table:getMaxTime(i),
			awakeTime = awakeTime,
			buyTime = buyTime,
			cost = xyd.tables.dressShowWindowShop1Table:getCost(i),
			funID = xyd.tables.dressShowWindowShop1Table:getFunctionID(i)[1],
			item = {
				xyd.tables.dressShowWindowShop1Table:getItemIcon(i),
				1
			}
		}

		table.insert(self.shop1Data, data)
	end

	return self.shop1Data
end

function DressShow:refreshShop2Info()
	shopModel:refreshShopInfo(xyd.ShopType.DRESS_SHOW_SHOP2)
end

function DressShow:getShop2Data()
	self.shop2Info_ = shopModel:getShopInfo(xyd.ShopType.DRESS_SHOW_SHOP2)
	self.shop2Data = {}
	local ids = xyd.tables.dressShowWindowShop2Table:getIds()
	local helpArr = {}
	local sum = 0

	for i = 1, #ids do
		local limitTime = xyd.tables.dressShowWindowShop2Table:getBuyTime(i)
		local buyTime = self.shop2Info_.items[i].buy_times or 0
		local point = xyd.tables.dressShowWindowShop2Table:getPoint(i)
		local curPoint = self:getTotalScore()
		local data = {
			tableID = i,
			limitTime = limitTime,
			leftTime = limitTime - buyTime,
			cost = xyd.tables.dressShowWindowShop2Table:getCost(i),
			item = xyd.tables.dressShowWindowShop2Table:getItem(i),
			point = point
		}
		local index = point

		if not helpArr[point] then
			helpArr[point] = 1
			sum = sum + 1
			self.shop2Data[sum] = {}
		end

		table.insert(self.shop2Data[sum], data)
	end

	return self.shop2Data
end

function DressShow:refreshShop3Info()
	shopModel:refreshShopInfo(xyd.ShopType.DRESS_SHOW_SHOP3)
end

function DressShow:getShop3Data()
	self.shop3Info_ = shopModel:getShopInfo(xyd.ShopType.DRESS_SHOW_SHOP3)
	self.shop3Data = {}
	local ids = xyd.tables.dressShowWindowShop3Table:getIds()
	local helpArr = {}
	local sum = 0

	for i = 1, #ids do
		local limitTime = xyd.tables.dressShowWindowShop3Table:getBuyTime(i)
		local buyTime = self.shop3Info_.items[i].buy_times or 0
		local point = xyd.tables.dressShowWindowShop3Table:getPoint(i)
		local curPoint = self:getTotalScore()
		local data = {
			tableID = i,
			limitTime = limitTime,
			leftTime = limitTime - buyTime,
			cost = xyd.tables.dressShowWindowShop3Table:getCost(i),
			item = xyd.tables.dressShowWindowShop3Table:getItem(i),
			point = point
		}
		local index = point

		if not helpArr[point] then
			helpArr[point] = 1
			sum = sum + 1
			self.shop3Data[sum] = {}
		end

		table.insert(self.shop3Data[sum], data)
	end

	return self.shop3Data
end

function DressShow:getShopResData()
	return {
		{
			1,
			2
		},
		{
			3,
			4
		},
		{
			5,
			6
		}
	}
end

function DressShow:reqShopAward(shopType, index, num)
	if num == nil then
		num = 1
	end

	if not shopType or not index then
		return
	end

	local msg = messages_pb.buy_shop_item_req()
	msg.shop_type = shopType
	msg.index = index
	msg.num = num

	xyd.Backend.get():request(xyd.mid.BUY_SHOP_ITEM, msg)
end

function DressShow:reqShop1Data()
	self:getShopInfo()
end

function DressShow:buyShopItem(table_id, num)
	local msg = messages_pb.show_window_buy_buff_req()
	msg.table_id = table_id
	msg.num = num

	xyd.Backend.get():request(xyd.mid.SHOW_WINDOW_BUY_BUFF, msg)
end

function DressShow:changeBuffTimeByFunction()
end

function DressShow:getBuffs()
	return self.buffs_
end

function DressShow:updateRedMark()
	local canGetAward = self:checkCanGetAward()
	local updateRed = self:checkShopUpdateRed()
	local function_open = xyd.checkFunctionOpen(xyd.FunctionID.DRESS_SHOW, true)

	xyd.models.redMark:setMark(xyd.RedMarkType.DRESS_SHOW, (canGetAward or updateRed) and function_open)
end

function DressShow:checkShopUpdateRed()
	local last_time = tonumber(xyd.db.misc:getValue("dress_show_shop_time"))

	if not last_time then
		return true
	end

	local lastUpdateTime = xyd.calcTimeToNextWeek() - 2 * xyd.DAY_TIME

	if last_time < lastUpdateTime and lastUpdateTime < xyd.getServerTime() then
		return true
	end

	return false
end

function DressShow:onUseBuffTimes(function_id)
	local ids = xyd.tables.dressShowWindowShop1Table:getIDsByFunction(function_id) or {}
	local buffs = self:getBuffs() or {}

	for _, id in ipairs(ids) do
		if buffs[tonumber(id)] then
			local times = buffs[tonumber(id)].times

			for index, value in pairs(times) do
				if value and value > 0 then
					times[index] = value - 1
				end
			end
		end
	end

	self:checkBuff(function_id)
end

function DressShow:checkBuff(function_id)
	local ids = xyd.tables.dressShowWindowShop1Table:getIDsByFunction(function_id) or {}
	local buffs = self:getBuffs() or {}

	for _, id in ipairs(ids) do
		if buffs[tonumber(id)] then
			local times = buffs[tonumber(id)].times

			for index, value in pairs(times) do
				if value and value <= 0 then
					table.remove(times, index)
					self:checkBuff(function_id)

					return
				end
			end
		end
	end
end

function DressShow:updateDressItemInCase(case_id)
	local hasChange = false
	local tempList = {}

	if self.showCaseInfo_[case_id] and self.showCaseInfo_[case_id].slots then
		local slotsData = self.showCaseInfo_[case_id].slots

		for index, value in ipairs(slotsData) do
			if value and value > 0 and xyd.models.backpack:getItemNumByID(value) <= 0 then
				local dress_id = xyd.tables.senpaiDressItemTable:getDressId(value)
				local dress_items = xyd.tables.senpaiDressTable:getItems(dress_id)

				for _, item_id in ipairs(dress_items) do
					if xyd.models.backpack:getItemNumByID(item_id) > 0 then
						tempList[index] = item_id
						hasChange = true
					end
				end
			elseif value <= 0 then
				tempList[index] = 0
			else
				tempList[index] = value
			end
		end
	end

	if hasChange then
		self:equips(case_id, tempList)
	end

	return hasChange
end

return DressShow
