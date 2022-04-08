local ExploreModel = class("ExploreModel", import(".BaseModel"))
local json = require("cjson")
local buidlingTables = {
	xyd.tables.exploreMarketTable,
	xyd.tables.exploreWishingTreeTable,
	xyd.tables.exploreBreadHomeTable
}
local adventureMaxLevel = 10
local redMark = xyd.models.redMark

function ExploreModel:ctor()
	ExploreModel.super.ctor(self)

	self.costItemTraining = {}
	self.costItemOthers = {}

	for i = 1, 5 do
		local cost = xyd.tables.exploreTrainingTable:getBaseCost(i)

		for _, item in ipairs(cost) do
			if not self.costItemTraining[item[1]] then
				self.costItemTraining[item[1]] = 1
			end
		end
	end

	for _, bTable in ipairs(buidlingTables) do
		local cost = bTable:getLevelUpCost(1)

		for _, item in ipairs(cost) do
			if not self.costItemOthers[item[1]] then
				self.costItemOthers[item[1]] = 1
			end
		end
	end

	self.timeCount = {}
end

function ExploreModel:onRegister()
	self:registerEvent(xyd.event.FUNCTION_OPEN, handler(self, self.checkOpen))
	self:registerEvent(xyd.event.EXPLORE_GET_INFO, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.EXPLORE_TRAIN_UPGRADE, self.onTrainingLevelUp, self)
	self:registerEvent(xyd.event.EXPLORE_BUILDING_UPGRADE, self.onBuildingLevelUp, self)
	self:registerEvent(xyd.event.EXPLORE_ADVENTURE_UPGRADE, self.onAdventureLevelUp, self)
	self:registerEvent(xyd.event.EXPLORE_TRAIN_SET_PARTNER, self.onTrainSetPartner, self)
	self:registerEvent(xyd.event.EXPLORE_BUILDING_SET_PARTNER, self.onBuildingSetPartner, self)
	self:registerEvent(xyd.event.EXPLORE_ADVENTURE_EVENT, self.onGetAdventureInfo, self)
	self:registerEvent(xyd.event.EXPLORE_ADVENTURE_COST, self.onGetAdvenEventResult, self)
	self:registerEvent(xyd.event.EXPLORE_ADVENTURE_OPEN_CHEST, self.onOpenAdventureChest, self)
	self:registerEvent(xyd.event.EXPLORE_BUILDING_GET_OUT, self.onBuildingsOutPut, self)
	self:registerEvent(xyd.event.ITEM_CHANGE, self.onItemChange, self)
	self:registerEvent(xyd.event.EXPLORE_BUY_BREAD, self.onBuyBread, self)
	self:registerEvent(xyd.event.BATCH_CHEST_OPEN, self.onBatchChestOpen, self)
end

function ExploreModel:checkOpen(event)
	local funID = event.data.functionID

	if funID == xyd.FunctionID.EXPLORE then
		local msg = messages_pb.explore_get_info_req()

		xyd.Backend.get():request(xyd.mid.EXPLORE_GET_INFO, msg)
	end
end

function ExploreModel:reqTrainingLevelUp(index)
	local msg = messages_pb.explore_train_upgrade_req()
	msg.table_id = index

	xyd.Backend.get():request(xyd.mid.EXPLORE_TRAIN_UPGRADE, msg)
end

function ExploreModel:reqBuildingLevelUp(buildingID)
	local msg = messages_pb.explore_building_upgrade_req()
	msg.id = buildingID

	xyd.Backend.get():request(xyd.mid.EXPLORE_BUILDING_UPGRADE, msg)
end

function ExploreModel:reqAdventureLevelUp()
	local msg = messages_pb.explore_adventure_upgrade_req()

	xyd.Backend.get():request(xyd.mid.EXPLORE_ADVENTURE_UPGRADE, msg)
end

function ExploreModel:setTrainPartner(trainingRoomID, slotIndex, partnerID)
	local oldPartnerID = self.trainRoomsInfo[trainingRoomID].partners[slotIndex] or 0

	if oldPartnerID ~= 0 then
		local oldPartner = xyd.models.slot:getPartner(oldPartnerID)
		oldPartner.travel = 0

		oldPartner:setLock(0, xyd.PartnerFlag.EXPLORE_TRAINING)
		oldPartner:updateAttrs()
	end

	self.trainRoomsInfo[trainingRoomID].partners[slotIndex] = partnerID
	local msg = messages_pb.explore_train_set_partner_req()
	msg.table_id = trainingRoomID
	msg.index = slotIndex
	msg.partner_id = partnerID

	xyd.Backend.get():request(xyd.mid.EXPLORE_TRAIN_SET_PARTNER, msg)
end

function ExploreModel:setBuildingPartner(buildingID, slotIndex, partnerID)
	local oldPartnerID = self.buildingsInfo[buildingID].partners[slotIndex] or 0

	if oldPartnerID ~= 0 then
		local oldPartner = xyd.models.slot:getPartner(oldPartnerID)

		oldPartner:setLock(0, xyd.PartnerFlag.EXPLORE_MINOR)
	end

	self.buildingsInfo[buildingID].partners[slotIndex] = partnerID
	local msg = messages_pb.explore_building_set_partner_req()
	msg.id = buildingID
	msg.index = slotIndex
	msg.partner_id = partnerID

	xyd.Backend.get():request(xyd.mid.EXPLORE_BUILDING_SET_PARTNER, msg)
end

function ExploreModel:reqAdventureInfo()
	local msg = messages_pb.explore_adventure_event_req()

	xyd.Backend.get():request(xyd.mid.EXPLORE_ADVENTURE_EVENT, msg)
end

function ExploreModel:reqAdventureCost(params)
	self.lastAdventureEventID = self.exploreInfo.event_id
	local msg = messages_pb.explore_adventure_cost_req()
	msg.params = json.encode(params)

	xyd.Backend.get():request(xyd.mid.EXPLORE_ADVENTURE_COST, msg)
end

function ExploreModel:reqOpenAdventureChest(index, isCost)
	local msg = messages_pb.explore_adventure_open_chest_req()
	msg.index = index
	msg.is_cost = isCost

	xyd.Backend.get():request(xyd.mid.EXPLORE_ADVENTURE_OPEN_CHEST, msg)
end

function ExploreModel:reqBuildingsOutPut(params)
	local msg = messages_pb.explore_building_get_out_req()

	for _, id in pairs(params) do
		table.insert(msg.ids, id)
	end

	xyd.Backend.get():request(xyd.mid.EXPLORE_BUILDING_GET_OUT, msg)
end

function ExploreModel:bacthChestOpen(list)
	local msg = messages_pb.batch_chest_open_req()

	for _, i in ipairs(list) do
		table.insert(msg.indexs, i)
	end

	xyd.Backend.get():request(xyd.mid.BATCH_CHEST_OPEN, msg)
end

function ExploreModel:onGetInfo(event)
	local data = event.data
	self.buildingsInfo = {}

	for i = 1, 3 do
		local buildingInfo = {
			updateTime = data.building_info.update_times[i],
			level = data.building_info.lvs[i],
			partners = json.decode(data.building_info.partners[i]),
			stock = data.building_info.stocks[i]
		}

		table.insert(self.buildingsInfo, buildingInfo)
	end

	self.trainRoomsInfo = {}
	self.trainLevel = 0

	for i = 1, 5 do
		local temp = {
			partners = json.decode(data.train_info.partners[i]),
			level = data.train_info.lvs[i]
		}

		table.insert(self.trainRoomsInfo, temp)

		self.trainLevel = self.trainLevel + temp.level
	end

	self.exploreInfo = xyd.decodeProtoBuf(data).explore_info

	redMark:setMark(xyd.RedMarkType.EXPLORE_TRAINING_LV_UP, self:canTrainingRoomLevelUp())
	redMark:setMark(xyd.RedMarkType.EXPLORE_MARKET_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.MARKET))
	redMark:setMark(xyd.RedMarkType.EXPLORE_BREAD_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.BREAD_HOME))
	redMark:setMark(xyd.RedMarkType.EXPLORE_WISHING_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.WIHSING_TREE))
	redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self:canAdventureLevelUp())
	self:checkAvailableBox()
	self:updateOutPutRedMark()
end

function ExploreModel:onTrainingLevelUp(event)
	local id = tonumber(event.data.table_id)
	self.trainRoomsInfo[id].level = self.trainRoomsInfo[id].level + 1
	self.trainLevel = self.trainLevel + 1
	local partners = self.trainRoomsInfo[id].partners

	for _, partnerID in ipairs(partners) do
		if partnerID ~= 0 then
			local partner = xyd.models.slot:getPartner(partnerID)
			partner.travel = partner.travel + 100

			partner:updateAttrs()
		end
	end

	redMark:setMark(xyd.RedMarkType.EXPLORE_TRAINING_LV_UP, self:canTrainingRoomLevelUp())
	redMark:setMark(xyd.RedMarkType.EXPLORE_MARKET_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.MARKET))
	redMark:setMark(xyd.RedMarkType.EXPLORE_BREAD_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.BREAD_HOME))
	redMark:setMark(xyd.RedMarkType.EXPLORE_WISHING_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.WIHSING_TREE))
end

function ExploreModel:onBuildingLevelUp(event)
	local id = tonumber(event.data.id)
	self.buildingsInfo[id].level = self.buildingsInfo[id].level + 1
	local redMarkType = {
		xyd.RedMarkType.EXPLORE_MARKET_LV_UP,
		xyd.RedMarkType.EXPLORE_WISHING_LV_UP,
		xyd.RedMarkType.EXPLORE_BREAD_LV_UP
	}

	redMark:setMark(redMarkType[id], self:canBuildingLevelUp(id))
end

function ExploreModel:onAdventureLevelUp(event)
	self.exploreInfo = xyd.decodeProtoBuf(event.data).info

	redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self:canAdventureLevelUp())
end

function ExploreModel:onTrainSetPartner(evnt)
	local data = evnt.data

	if data.partner_id ~= 0 then
		local newPartner = xyd.models.slot:getPartner(data.partner_id)
		newPartner.travel = self.trainRoomsInfo[data.table_id].level * 100 + data.table_id

		newPartner:updateAttrs()
		newPartner:setLock(data.index * 100 + data.table_id, xyd.PartnerFlag.EXPLORE_TRAINING)
	end
end

function ExploreModel:onBuildingSetPartner(event)
	local data = event.data

	if data.partner_id ~= 0 then
		local newPartner = xyd.models.slot:getPartner(data.partner_id)

		newPartner:setLock(data.index * 100 + data.id, xyd.PartnerFlag.EXPLORE_MINOR)
	end
end

function ExploreModel:onGetAdventureInfo(event)
	self.exploreInfo = xyd.decodeProtoBuf(event.data).info
end

function ExploreModel:onGetAdvenEventResult(event)
	self.exploreInfo = xyd.decodeProtoBuf(event.data).info

	self:checkAvailableBox()
end

function ExploreModel:onBatchChestOpen(event)
	local chests = event.data.chests

	for _, item in ipairs(chests) do
		local index = item.index
		local boxID = self.exploreInfo.chests[index]

		if not self.exploreInfo.used_chests[boxID] then
			self.exploreInfo.used_chests[boxID] = 0
		end

		self.exploreInfo.used_chests[boxID] = self.exploreInfo.used_chests[boxID] + 1
		self.exploreInfo.chests[index] = 0
		self.exploreInfo.award_ids[index] = ""
		self.exploreInfo.update_times[index] = 0
	end

	local count = 1

	local function swap(list, a, b)
		local temp = list[a]
		list[a] = list[b]
		list[b] = temp
	end

	for i = 1, #self.exploreInfo.chests do
		if self.exploreInfo.chests[i] ~= 0 then
			swap(self.exploreInfo.chests, i, count)
			swap(self.exploreInfo.award_ids, i, count)
			swap(self.exploreInfo.update_times, i, count)

			count = count + 1
		end
	end

	redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self:canAdventureLevelUp())
	self:checkAvailableBox()
end

function ExploreModel:onOpenAdventureChest(event)
	local index = event.data.index
	local boxID = self.exploreInfo.chests[index]

	if not self.exploreInfo.used_chests[boxID] then
		self.exploreInfo.used_chests[boxID] = 0
	end

	self.exploreInfo.used_chests[boxID] = self.exploreInfo.used_chests[boxID] + 1
	local len = #self.exploreInfo.chests

	for i = index, len - 1 do
		self.exploreInfo.chests[i] = self.exploreInfo.chests[i + 1]
		self.exploreInfo.award_ids[i] = self.exploreInfo.award_ids[i + 1]
		self.exploreInfo.update_times[i] = self.exploreInfo.update_times[i + 1]
	end

	self.exploreInfo.chests[len] = 0
	self.exploreInfo.award_ids[len] = ""
	self.exploreInfo.update_times[len] = 0

	redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_LV_UP, self:canAdventureLevelUp())
	self:checkAvailableBox()
end

function ExploreModel:onBuildingsOutPut(event)
	for _, id in ipairs(event.data.ids) do
		self.buildingsInfo[id].updateTime = event.data.info.update_times[id]
		self.buildingsInfo[id].stock = event.data.info.stocks[id]
	end

	self:updateOutPutRedMark()

	local time = xyd.getServerTime() + xyd.tables.deviceNotifyTable:getDelayTime(xyd.DEVICE_NOTIFY.EXPLORE_OUTPUT)

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.EXPLORE_OUTPUT, time)
end

function ExploreModel:onBuyBread(event)
	self.exploreInfo.buy_times = self.exploreInfo.buy_times + event.data.num
end

function ExploreModel:getTrainingLevelUplimit()
	if not self.trainingLevelUplimit then
		self.trainingLevelUplimit = {}
		local limit = xyd.split(xyd.tables.miscTable:getVal("travel_train_grade_limit"), "|")

		for i in ipairs(limit) do
			local temp = xyd.split(limit[i], "#", true)

			table.insert(self.trainingLevelUplimit, temp)
		end
	end

	return self.trainingLevelUplimit
end

function ExploreModel:getTrainingSlotLimit()
	if not self.trainingSlotLimit then
		self.trainingSlotLimit = {}
		local limit = xyd.split(xyd.tables.miscTable:getVal("travel_train_slot_limit"), "|")

		for i in ipairs(limit) do
			local temp = xyd.split(limit[i], "#", true)

			table.insert(self.trainingSlotLimit, temp)
		end
	end

	return self.trainingSlotLimit
end

function ExploreModel:getBuildingsLevelUplimit()
	if not self.buildingsLevelUplimit then
		self.buildingsLevelUplimit = {}
		local limit = xyd.split(xyd.tables.miscTable:getVal("travel_train_facility_limit"), "|")

		for i in ipairs(limit) do
			local temp = xyd.split(limit[i], "#", true)

			table.insert(self.buildingsLevelUplimit, temp)
		end
	end

	return self.buildingsLevelUplimit
end

function ExploreModel:getBuildingSlotLimit()
	if not self.buildingSlotLimit then
		self.buildingSlotLimit = {}
		local limit = xyd.split(xyd.tables.miscTable:getVal("travel_building_slot_limit"), "|")

		for i in ipairs(limit) do
			local temp = xyd.split(limit[i], "#", true)

			table.insert(self.buildingSlotLimit, temp)
		end
	end

	return self.buildingSlotLimit
end

function ExploreModel:getTrainLevel()
	return self.trainLevel
end

function ExploreModel:getBuildsInfo()
	return self.buildingsInfo
end

function ExploreModel:getTrainRoomsInfo()
	return self.trainRoomsInfo
end

function ExploreModel:getExploreInfo()
	return self.exploreInfo
end

function ExploreModel:getLastAdventureEventID()
	return self.lastAdventureEventID
end

function ExploreModel:onItemChange(event)
	if not self.trainRoomsInfo then
		return
	end

	local items = xyd.decodeProtoBuf(event.data).items

	for _, item in ipairs(items) do
		if self.costItemTraining[item.item_id] == 1 then
			redMark:setMark(xyd.RedMarkType.EXPLORE_TRAINING_LV_UP, self:canTrainingRoomLevelUp())
		end

		if self.costItemOthers[item.item_id] == 1 then
			redMark:setMark(xyd.RedMarkType.EXPLORE_MARKET_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.MARKET))
			redMark:setMark(xyd.RedMarkType.EXPLORE_BREAD_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.BREAD_HOME))
			redMark:setMark(xyd.RedMarkType.EXPLORE_WISHING_LV_UP, self:canBuildingLevelUp(xyd.exploreBuildings.WIHSING_TREE))
		end
	end
end

function ExploreModel:canTrainingRoomLevelUp()
	local limit = self:getTrainingLevelUplimit()

	for i = 1, 5 do
		local flag = true
		local lv = self.trainRoomsInfo[i].level
		local cost = xyd.tables.exploreTrainingTable:getCost(i, lv)

		for j = 1, 2 do
			local data = cost[j]
			flag = flag and data[2] <= xyd.models.backpack:getItemNumByID(data[1])
		end

		local minLev = 61

		for j = 1, 5 do
			if j ~= i and self.trainRoomsInfo[j].level < minLev then
				minLev = self.trainRoomsInfo[j].level
			end
		end

		local maxLev = 0

		for _, item in ipairs(limit) do
			if item[2] <= minLev then
				maxLev = item[1]
			else
				break
			end
		end

		flag = flag and lv < maxLev

		if flag then
			return true
		end
	end

	return false
end

function ExploreModel:canBuildingLevelUp(buildingID)
	local lv = self.buildingsInfo[buildingID].level
	local bTable = buidlingTables[buildingID]
	local levelUpCost = bTable:getLevelUpCost(lv)
	local flag = true

	for _, data in ipairs(levelUpCost) do
		flag = flag and data[2] <= xyd.models.backpack:getItemNumByID(data[1])
	end

	local limit = self:getBuildingsLevelUplimit()
	local trainLevel = self:getTrainLevel()
	local maxLev = 0

	for _, item in ipairs(limit) do
		if item[2] <= trainLevel then
			maxLev = item[1]
		else
			break
		end
	end

	flag = flag and lv < maxLev

	return flag
end

function ExploreModel:canAdventureLevelUp()
	if self.exploreInfo.lv == adventureMaxLevel then
		return false
	end

	local flag = true
	local limit = xyd.tables.exploreAdventureTable:getLevelUpLimit(self.exploreInfo.lv)
	local usedChests = self.exploreInfo.used_chests

	for j = 1, #limit do
		local data = limit[j]
		local usedNum = usedChests[data[1]] or 0

		if usedNum < data[2] then
			flag = false

			break
		end
	end

	return flag
end

function ExploreModel:setBattleAwards(items)
	self.battleAwards = items
end

function ExploreModel:getBattleAwards()
	return self.battleAwards
end

function ExploreModel:checkAvailableBox()
	for _, keyId in pairs(self.timeCount) do
		xyd.removeGlobalTimer(keyId)
	end

	local notifyTime = 57600
	local boxList = self.exploreInfo.chests or {}
	local updateTimes = self.exploreInfo.update_times
	local flag = false

	for i in ipairs(boxList) do
		if boxList[i] ~= 0 then
			local lastTime = xyd.tables.adventureBoxTable:getTimeCost(boxList[i])
			local duration = updateTimes[i] + lastTime - xyd.getServerTime()
			flag = flag or duration <= 0

			if duration > 0 then
				local keyId = xyd.addGlobalTimer(function ()
					redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_BOX_CAN_OPEN, true)
				end, duration, 1)
				self.timeCount[i] = keyId
			end

			notifyTime = notifyTime < duration and notifyTime or duration
		end
	end

	redMark:setMark(xyd.RedMarkType.EXPLORE_ADVENTURE_BOX_CAN_OPEN, flag)
	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.EXPLORE_FREE_BOX, notifyTime)
end

function ExploreModel:updateOutPutRedMark()
	redMark:setMark(xyd.RedMarkType.EXPLORE_OUPUT_AWARD, self:checkOutPutAward())

	if self.outPutKeyId then
		xyd.removeGlobalTimer(self.outPutKeyId)

		self.outPutKeyId = nil
	end

	local cd = 3600

	for i = 1, 3 do
		local info = self.buildingsInfo[i]
		local delta = (xyd.getServerTime() - info.updateTime) % cd

		if cd > delta then
			cd = delta or cd
		end
	end

	self.outPutKeyId = xyd.addGlobalTimer(function ()
		redMark:setMark(xyd.RedMarkType.EXPLORE_OUPUT_AWARD, self:checkOutPutAward())
	end, cd, 1)
end

function ExploreModel:checkOutPutAward()
	local flag = false
	local facCD = xyd.split(xyd.tables.miscTable:getVal("travel_facility_cd"), "|", true)
	local buildingTables = {
		xyd.tables.exploreMarketTable,
		xyd.tables.exploreWishingTreeTable,
		xyd.tables.exploreBreadHomeTable
	}

	for i = 1, 3 do
		local info = self.buildingsInfo[i]
		local bTable = buildingTables[i]
		local outPut = bTable:getOutput(info.level)
		local outPutNum = tonumber(outPut[2])
		local stayNum = bTable:getStayMax(info.level)

		for j in ipairs(info.partners) do
			local partnerID = info.partners[j]

			if partnerID and partnerID ~= 0 then
				local star = xyd.models.slot:getPartner(partnerID).star

				if j % 2 ~= 0 then
					outPutNum = outPutNum * (1 + xyd.tables.exploreFacilityAddTable:getOutAdd(i, star) / 100)
				else
					stayNum = stayNum * (1 + xyd.tables.exploreFacilityAddTable:getStayAdd(i, star) / 100)
				end
			end
		end

		local cd = facCD[i]
		local duration = xyd.getServerTime() - info.updateTime
		local count = math.floor(duration / cd)
		local hasNum = math.floor(count * outPutNum / (86400 / cd) + info.stock)
		flag = flag or hasNum > 0
	end

	return flag
end

function ExploreModel:isSkipReport()
	local state = xyd.db.misc:getValue("explore_adventure_skip_report")

	if state and tonumber(state) == 1 then
		return true
	else
		return false
	end
end

function ExploreModel:getSetUpList()
	if not self.setUplist then
		local list = xyd.db.misc:getValue("auto_adventure_setup")

		if not list then
			self.setUpList = {
				1,
				1,
				1
			}

			self:setSetUpList()
		else
			self.setUpList = json.decode(list)
		end
	end

	return self.setUpList
end

function ExploreModel:setSetUpList()
	xyd.db.misc:setValue({
		key = "auto_adventure_setup",
		value = json.encode(self.setUpList)
	})
end

function ExploreModel:getSpSetUpList()
	if not self.spSetUplist then
		local list = xyd.db.misc:getValue("auto_adventure_sp_setup")

		if not list then
			self.spSetUplist = {
				0,
				1
			}

			self:setSpSetUpList()
		else
			self.spSetUplist = json.decode(list)
		end
	end

	return self.spSetUplist
end

function ExploreModel:setSpSetUpList()
	xyd.db.misc:setValue({
		key = "auto_adventure_sp_setup",
		value = json.encode(self.spSetUplist)
	})
end

return ExploreModel
