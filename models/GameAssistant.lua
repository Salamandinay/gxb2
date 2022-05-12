local BaseModel = import(".BaseModel")
local GameAssistant = class("GameAssistant", BaseModel)
local Summon = xyd.models.summon
local cjson = require("cjson")
local cjson2 = cjson.new()

cjson2.encode_sparse_array(true)

local missionStatus = {
	UN_DO = 0,
	DOING = 1,
	DONE = 2
}

function GameAssistant:ctor()
	BaseModel.ctor(self)

	self.todayHaveDoneData = {
		friend = false,
		gamble = false,
		tavern = false,
		marketHasBuy = false,
		house = false,
		campaign = false,
		dressShow = false,
		arena = false,
		dungeon = false,
		midas = {
			free = false,
			paid = 0
		},
		dailyQuiz = {
			free = false,
			paid = {
				0,
				0,
				0
			}
		},
		summon = {
			senior = false,
			normal = false
		},
		academyAssessment = {
			free = 0,
			paid = 0,
			fort = 0
		},
		explore = {
			award = false,
			bread = 0
		},
		pet = {
			paid = 0,
			challenge = false,
			award = false,
			fight = 0
		},
		guild = {
			signIn = false,
			gym = false,
			level = 0,
			order = false
		},
		market = {},
		arenaBattleFormationInfo = {}
	}
	self.presetData = {
		friend = false,
		gamble = false,
		marketHasBuy = false,
		house = false,
		campaign = false,
		dressShow = false,
		arena = false,
		dungeon = false,
		midas = {
			free = false,
			paid = 0
		},
		dailyQuiz = {
			free = false,
			paid = {
				0,
				0,
				0
			}
		},
		summon = {
			senior = 2,
			normal = 2
		},
		tavern = {
			false,
			false,
			false,
			false,
			false,
			false,
			false
		},
		academyAssessment = {
			free = 0,
			paid = 0,
			fort = 0
		},
		explore = {
			award = false,
			bread = 0
		},
		pet = {
			paid = 0,
			challenge = false,
			award = false,
			fight = 0
		},
		guild = {
			signIn = false,
			gym = false,
			level = 0,
			order = false
		},
		market = {},
		arenaBattleFormationInfo = {},
		guildBattleFormationInfo = {}
	}

	self:initData()
end

function GameAssistant:onRegister()
	self:registerEvent(xyd.event.MIDAS_BUY_2, handler(self, self.onGetMidasMsg))
	self:registerEvent(xyd.event.GET_HANG_ITEM, handler(self, self.onGetHangItems))
	self:registerEvent(xyd.event.HOUSE_GET_AWARDS, handler(self, self.onGetHouseItems))
	self:registerEvent(xyd.event.BUY_SHOP_ITEM_BATCH, handler(self, self.onGetBuyMarketMsg))
	self:registerEvent(xyd.event.EXPLORE_BUILDING_GET_OUT, handler(self, self.onGetExploreAwardMsg))
	self:registerEvent(xyd.event.ARENA_FIGHT_BATCH, handler(self, self.onGetArenaMsg))
end

function GameAssistant:initData()
	self.limitLevs = xyd.split(xyd.tables.miscTable:getVal("assistant_open_limit"), "|", true)
	local presetData = xyd.db.misc:getValue("gameAssistant_preset_data")
	local todayHaveDoneData = xyd.db.misc:getValue("gameAssistant_todayHaveDoneData")
	local timeStamp = xyd.db.misc:getValue("gameAssistant_todayHaveDoneData_timeStamp")

	if not presetData then
		return
	else
		self.presetData = cjson2.decode(presetData)
	end

	if xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
		self.todayHaveDoneData = cjson2.decode(todayHaveDoneData)
	end

	local timeStamp_click = xyd.db.misc:getValue("gameAssistant_todayHaveClick_timeStamp")

	if not timeStamp_click or not xyd.isSameDay(xyd.getServerTime(), tonumber(timeStamp_click)) then
		self.todayHaveClick = false
	else
		self.todayHaveClick = true
	end

	for key, value in pairs(self.presetData) do
		if type(value) ~= "number" then
			value = nil
		end
	end

	local oldValue = self.presetData.market
	self.presetData.market = {}

	for key, value in pairs(oldValue) do
		self.presetData.market[tonumber(key)] = tonumber(value)
	end

	xyd.db.misc:setValue({
		value = 0,
		key = "gameAssistant_req_gambleData"
	})
	xyd.db.misc:setValue({
		value = 0,
		key = "gameAssistant_req_DungeonData"
	})

	if not self.presetData.pet.fight then
		self.presetData.pet.fight = 0
		self.todayHaveDoneData.pet.fight = 0
	end
end

function GameAssistant:saveData()
	xyd.db.misc:setValue({
		key = "gameAssistant_preset_data",
		value = cjson2.encode(self.presetData)
	})
	xyd.db.misc:setValue({
		key = "gameAssistant_todayHaveDoneData",
		value = cjson2.encode(self.todayHaveDoneData)
	})
	xyd.db.misc:setValue({
		key = "gameAssistant_todayHaveDoneData_timeStamp",
		value = xyd.getServerTime()
	})
end

function GameAssistant:getPresetData()
	return self.presetData
end

function GameAssistant:getTodayHaveDoneData()
	return self.todayHaveDoneData
end

function GameAssistant:reqMidasData()
	xyd.models.midas:reqMidasInfoNew()
end

function GameAssistant:buyMidas(Index)
	local msg = messages_pb:midas_buy_2_req()
	msg.buy_index = Index

	if Index == 1 then
		msg.times = 1
	elseif Index == 2 then
		msg.times = self.presetData.midas.paid - xyd.models.midas.buy_times
	end

	if Index == 2 and xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < self:buyMidasTotalCost(self.presetData.midas.paid) then
		return false
	end

	xyd.Backend.get():request(xyd.mid.MIDAS_BUY_2, msg)

	return true
end

function GameAssistant:buyMidasTotalCost(num)
	local costNum = 0

	if num <= xyd.models.midas.buy_times then
		return 0
	end

	for i = 1, num - xyd.models.midas.buy_times do
		costNum = costNum + xyd.tables.midasBuyCoinTable:getCost(i + xyd.models.midas.buy_times)[2]
	end

	return costNum
end

function GameAssistant:getMidasData()
	local data = {
		left_freeTime = 1 - xyd.models.midas.is_free_award,
		left_canBuy = xyd.tables.vipTable:getMidasTimes(xyd.models.backpack:getVipLev()) - xyd.models.midas.buy_times,
		buy_time = xyd.models.midas.buy_times
	}

	return data
end

function GameAssistant:onGetMidasMsg(event)
end

function GameAssistant:reqCampaignAward()
	self.mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local dropItems = self.mapInfo.drop_items
	local msg = messages_pb.get_hang_item_req()
	local num = 1
	msg.item_type = 1
	msg.count = 5

	xyd.Backend.get():request(xyd.mid.GET_HANG_ITEM, msg)

	if dropItems and #dropItems > 0 then
		local msg2 = messages_pb.get_hang_item_req()
		msg2.item_type = 2

		xyd.Backend.get():request(xyd.mid.GET_HANG_ITEM, msg2)

		num = num + 1
	end

	return num
end

function GameAssistant:onGetHangItems(event)
	xyd.db.misc:setValue({
		key = "gameAssistant_campaign_timeStamp",
		value = xyd.getServerTime()
	})
end

function GameAssistant:reqHouseAward()
	xyd.models.house:reqGetAwards()
end

function GameAssistant:onGetHouseItems(event)
	xyd.db.misc:setValue({
		key = "gameAssistant_house_timeStamp",
		value = xyd.getServerTime()
	})
	xyd.models.redMark:setMark(xyd.RedMarkType.HOUSE, false)
	xyd.models.house:setHangRedPoint(false)
end

function GameAssistant:reqDailyQuizAward()
	local awardTime = 0

	for i = 1, 3 do
		local data = xyd.models.dailyQuiz:getDataByType(i)

		if data and data.cur_quiz_id and data.cur_quiz_id > 0 and xyd.models.dailyQuiz:checkCanFight(data.cur_quiz_id) and data.fight_times < self.presetData.dailyQuiz.paid[i] and self.presetData.dailyQuiz.paid[i] <= data.limit_times then
			xyd.models.dailyQuiz:reqSweep(data.cur_quiz_id, self.presetData.dailyQuiz.paid[i] - data.fight_times)

			awardTime = awardTime + 1
		end
	end

	return awardTime
end

function GameAssistant:getMaxCanBuyDailyQuizTime(index)
	local data_ = xyd.models.dailyQuiz:getDataByType(index)

	if not data_ then
		return
	end

	local buyTimes = data_.buy_times
	local vip = xyd.models.backpack:getVipLev()
	local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)
	local maxCanBuy = maxBuyTimes + 2

	return maxCanBuy
end

function GameAssistant:buyDailyQuizTime(index, buyTime)
	local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = costs[1]
	local costNum = costs[2]

	if xyd.isItemAbsence(costItemID, costNum * buyTime) then
		return false
	end

	xyd.models.dailyQuiz:reqBuy(index, buyTime)

	return true
end

function GameAssistant:getCostNum(buyTime)
	if buyTime <= 0 then
		return 0
	end

	local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = costs[1]
	local costNum = costs[2]

	return buyTime * costNum
end

function GameAssistant:reqBaseSummon(isFree)
	local summonType = xyd.SummonType
	local baseScrollNum = xyd.models.summon:getBaseScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()
	local nowTime = xyd.getServerTime()
	local baseFreeTime = Summon:getBaseSummonFreeTime()
	local baseInterval = xyd.tables.summonTable:getFreeTimeInterval(summonType.BASE_FREE)

	if canSummonNum < 1 then
		return false
	end

	local is_base_free = false
	is_base_free = baseInterval <= nowTime - baseFreeTime

	if is_base_free then
		Summon:summonPartner(summonType.BASE_FREE)
	elseif baseScrollNum >= 1 and not isFree then
		Summon:summonPartner(summonType.BASE)
	else
		return false
	end

	return true
end

function GameAssistant:reqSeniorSummon(isFree)
	local summonType = xyd.SummonType
	local seniorScrollNum = xyd.models.summon:getSeniorScrollNum()
	local canSummonNum = xyd.models.slot:getCanSummonNum()
	local nowTime = xyd.getServerTime()
	local seniorFreeTime = Summon:getSeniorSummonFreeTime()
	local seniorInterval = xyd.tables.summonTable:getFreeTimeInterval(summonType.SENIOR_FREE)

	if canSummonNum < 1 then
		return false
	end

	local is_senior_free = false
	is_senior_free = seniorInterval <= nowTime - seniorFreeTime

	if is_senior_free then
		Summon:summonPartner(summonType.SENIOR_FREE)
	elseif seniorScrollNum >= 1 and not isFree then
		Summon:summonPartner(summonType.SENIOR_SCROLL)
	else
		return false
	end

	return true
end

function GameAssistant:reqFriendLove()
	local sendFlag = false
	local getFlag = false
	local list = xyd.models.friend:getFriendList()
	local sendIDs = {}
	local getIDs = {}

	for _, info in ipairs(list) do
		local status = xyd.models.friend:checkIsSend(info.player_id)

		if not status then
			table.insert(sendIDs, info.player_id)
		end

		local receiveStatus = xyd.models.friend:getReceiveStatus(info.player_id)

		if receiveStatus == 1 then
			table.insert(getIDs, info.player_id)
		end
	end

	if #sendIDs > 0 then
		xyd.models.friend:sendGifts(sendIDs)

		sendFlag = true
	end

	local maxLove = tonumber(xyd.tables.miscTable:getVal("friend_love_sum_max"))
	local giftNum = xyd.models.friend:getGiftNum()
	local maxGiftNum = tonumber(xyd.tables.miscTable:getVal("love_coin_daily_max"))

	if giftNum < maxGiftNum and xyd.models.friend:getLoveNum() < maxLove and #getIDs > 0 then
		if maxGiftNum < #getIDs + giftNum then
			local index = maxGiftNum - giftNum
			local copytable = {}

			for i = 1, index do
				table.insert(copytable, getIDs[i])
			end

			getIDs = copytable
		end

		xyd.models.friend:getGifts(getIDs)

		getFlag = true
	end

	return sendFlag, getFlag
end

function GameAssistant:reqArenaBattle()
	local battleInfo = self.presetData.arenaBattleFormationInfo

	if not battleInfo.partners or #battleInfo.partners == 0 then
		return false
	end

	local msg = messages_pb.arena_fight_batch_req()
	msg.pet_id = battleInfo.pet_id

	xyd.getFightPartnerMsg(msg.partners, self.presetData.arenaBattleFormationInfo.partners)

	local defomation = xyd.models.arena:getDefFormation()
	local needCheck = not xyd.models.arena.hasCheck

	if needCheck then
		local power = 0

		for i = 1, #defomation do
			power = defomation[i].power + power
		end

		local numSave = xyd.tables.miscTable:getVal("defense_team_save")

		if battleInfo.power and tonumber(numSave) < battleInfo.power / power then
			xyd.models.arena:checkDefFormation()
		end

		xyd.models.arena.hasCheck = true
	end

	local freeTime = xyd.models.arena:getFreeTimes()

	if freeTime > 0 then
		if freeTime > 3 then
			xyd.models.arena:setFreeTimes(freeTime - 3)
		else
			xyd.models.arena:setFreeTimes(0)
		end
	end

	xyd.Backend.get():request(xyd.mid.ARENA_FIGHT_BATCH, msg)

	return true
end

function GameAssistant:onGetArenaMsg(event)
	local arena = xyd.models.arena
	local data = xyd.decodeProtoBuf(event.data)
	local results = data.battle_results
	local oldRank = arena:getRank()

	arena:updateRank(results[#results].rank)
	arena:updateScore(results[#results].score)

	if results[#results].rank <= xyd.TOP_ARENA_NUM then
		arena:reqRankList()
	elseif oldRank and oldRank <= xyd.TOP_ARENA_NUM then
		arena:reqRankList()
	end
end

function GameAssistant:checkIfNeedResetFormation(partners)
	local newPartners = {}
	local flag = false

	for i = 1, #partners do
		if partners[i] and partners[i].partner_id and xyd.models.slot:getPartner(partners[i].partner_id) then
			table.insert(newPartners, partners[i])
		else
			flag = true
		end
	end

	if flag then
		for i = 1, #partners do
			if i <= #newPartners then
				partners[i] = newPartners[i]
			else
				partners[i] = nil
			end
		end
	end

	return flag
end

function GameAssistant:reqTavernInfo()
	xyd.models.tavern:reqPubInfo()
end

function GameAssistant:reqComplteTavern(choosenStars)
	local completeTime = 0
	local missionList = {}
	self.completeList = {}
	local missionIDs = xyd.models.tavern:getMissions()

	for _, missionID in ipairs(missionIDs) do
		local mission = xyd.models.tavern:getMissionById(missionID)

		if mission.status == missionStatus.DONE then
			local star = xyd.tables.pubMissionTable:getStar(mission.table_id)

			if choosenStars[star] and completeTime < 2 then
				table.insert(missionList, mission.mission_id)

				completeTime = completeTime + 1
			end
		end
	end

	if #missionList > 0 then
		xyd.models.tavern:completeMultiMission(missionList)

		return true
	else
		return false
	end
end

function GameAssistant:reqGamble()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.GAMBLE_NORMAL) < 2 then
		return false
	else
		xyd.models.gamble:reqGetAward(1, 1)
		xyd.models.gamble:reqGetAward(1, 1)

		return true
	end
end

function GameAssistant:reqMarket()
	local shopInfo = xyd.models.shop:getShopInfo(xyd.ShopType.SHOP_BLACK_NEW)
	local msg = messages_pb:buy_shop_item_batch_req()
	local costNum = {}
	self.tempBuyMarketItems = {}

	for index, num in pairs(self.presetData.market) do
		index = tonumber(index)
		num = tonumber(num)

		if type(num) == "number" and num > 0 then
			local info = shopInfo.items[index]
			local buy_times = info.buy_times or 0
			local left_times = 1

			if xyd.models.activity:isResidentReturnAddTime() then
				local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WELFARE_SOCIETY)
				left_times = left_times * return_multiple
			end

			if buy_times < left_times and type(num) == "number" then
				local item = shopInfo.items[index].item
				local cost = shopInfo.items[index].cost

				if not costNum[cost[1]] then
					costNum[cost[1]] = 0
				end

				if costNum[cost[1]] + cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
					costNum[cost[1]] = costNum[cost[1]] + cost[2]
					local batchItem = messages_pb.shop_batch_item()
					batchItem.index = index
					batchItem.num = num

					table.insert(msg.params, batchItem)
					table.insert(self.tempBuyMarketItems, item)
				end
			end
		end
	end

	if #msg.params == 0 then
		return false
	end

	msg.shop_type = xyd.ShopType.SHOP_BLACK_NEW

	xyd.Backend.get():request(xyd.mid.BUY_SHOP_ITEM_BATCH, msg)

	return true
end

function GameAssistant:onGetBuyMarketMsg(event)
	local params = event.data
	local shopType = params.shop_type

	if not xyd.models.shop.shopList_[shopType] then
		xyd.models.shop.shopList_[shopType] = {}
	end

	xyd.models.shop.shopList_[shopType].items = params.items
	xyd.models.shop.shopList_[shopType].refreshTime = params.refresh_time

	if params.end_time then
		xyd.models.shop.shopList_[shopType].end_time = params.end_time
	end

	xyd.models.shop.requestTimeList_[shopType] = xyd.getServerTime()

	xyd.models.shop:updateShopRedMark(shopType)
end

function GameAssistant:getTempBuyMarketItems()
	return self.tempBuyMarketItems
end

function GameAssistant:reqDressShowAward()
	xyd.models.dressShow:reqGetAward()

	return true
end

function GameAssistant:dungeonIsOpen()
	return xyd.models.dungeon:isOpen()
end

function GameAssistant:dungeonNeedSetPartners()
	if xyd.models.dungeon:isOpen() then
		local partners = xyd.models.dungeon:getPartners()

		return #partners <= 0
	end

	return false
end

function GameAssistant:reqDungeonStart(partnerIDs)
	xyd.models.dungeon:reqStart(partnerIDs)
end

function GameAssistant:getDungeonShopItem()
	return xyd.models.dungeon:getShopItems()
end

function GameAssistant:BuyDungeonShop()
	self.dungeon:reqBuyItem(self.todayHaveDoneData.index[1], indexs)
end

function GameAssistant:onGetDungeonStart(event)
	local sweepAwards = event.data.sweep_awards

	if sweepAwards and (sweepAwards.items and #sweepAwards.items > 0 or sweepAwards.drugs and #sweepAwards.drugs > 0) then
		local items = sweepAwards.items

		for _, item in ipairs(sweepAwards.drugs) do
			local id = xyd.tables.dungeonDrugTable:getId(item.item_id)

			table.insert(items, {
				item_id = id,
				item_num = item.item_num
			})
		end

		xyd.alertItems(items)
	end
end

function GameAssistant:getCurStageIDIndexAcademyAssessment(fortId)
	local currentStageID = xyd.models.academyAssessment:getCurrentStage(fortId)

	return currentStageID
end

function GameAssistant:getMaxCanSweepAcademyAssessment(fortId)
	local times = xyd.models.academyAssessment:getSweepTimes()

	if times <= 0 then
		return 0
	end

	return times
end

function GameAssistant:freeSweepAcademyAssessment(fortId, num)
	local curStageID = xyd.models.academyAssessment:getCurrentStage(fortId)
	local ids = xyd.tables.academyAssessmentNewTable2:getIdsByFort(fortId)
	local index = -1

	if curStageID == -1 then
		index = #ids
	else
		for i = 1, #ids do
			if xyd.tables.academyAssessmentNewTable2:getSchoolSort(ids[i]) == xyd.tables.academyAssessmentNewTable2:getSchoolSort(curStageID) - 1 then
				index = i

				break
			end

			i = i + 1
		end
	end

	index = math.max(index, 0)

	return xyd.models.academyAssessment:reqSweep(ids[index], num)
end

function GameAssistant:getMaxChoosefreeSweepAcademyAssessment()
	return self:getMaxCanSweepAcademyAssessment()
end

function GameAssistant:getMaxBuyTicketAcademyAssessment()
	local crystalNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	local maxCanBuyTime = 0
	local haveBought = xyd.models.academyAssessment:getBuySweepTimes()
	local canBuy = xyd.tables.academyAssessmentCostTable:getIDs() - haveBought

	for i = 1, canBuy do
		local costNum = 0

		if haveBought == 0 then
			costNum = xyd.tables.academyAssessmentCostTable:getCost(i)
		elseif i + haveBought <= xyd.tables.academyAssessmentCostTable:getIDs() then
			costNum = xyd.tables.academyAssessmentCostTable:getCost(i + haveBought) - xyd.tables.academyAssessmentCostTable:getCost(haveBought)
		end

		if crystalNum >= costNum then
			maxCanBuyTime = i
		else
			break
		end
	end

	return maxCanBuyTime
end

function GameAssistant:getCostNumAcademyAssessment(time)
	local costNum = 0
	local haveBought = xyd.models.academyAssessment:getBuySweepTimes()

	if haveBought == 0 then
		costNum = xyd.tables.academyAssessmentCostTable:getCost(time)
	elseif time + haveBought <= xyd.tables.academyAssessmentCostTable:getIDs() then
		costNum = xyd.tables.academyAssessmentCostTable:getCost(time + haveBought) - xyd.tables.academyAssessmentCostTable:getCost(haveBought)
	end

	return costNum or 0
end

function GameAssistant:buyTicketAcademyAssessment(num)
	local realNum = math.min(num, self:getMaxBuyTicketAcademyAssessment())

	if realNum > 0 then
		xyd.models.academyAssessment:reqBuyTickets(xyd.SchoolTicketType.SWEEP, realNum)
	end

	return realNum
end

function GameAssistant:reqExploreAward()
	xyd.models.exploreModel:reqBuildingsOutPut({
		1,
		2,
		3
	})
end

function GameAssistant:getLimitTimesBreadExplore()
	local vipLv = xyd.models.backpack:getVipLev()
	local limitList = xyd.split(xyd.tables.miscTable:getVal("travel_buy_time_limit"), "|", true)
	local limitTimes = limitList[vipLv + 1]

	return limitTimes
end

function GameAssistant:getBuyTimeBreadExplore()
	return xyd.models.exploreModel:getExploreInfo().buy_times
end

function GameAssistant:getMaxCanBuyBreadExplore()
	local vipLv = xyd.models.backpack:getVipLev()
	local limitList = xyd.split(xyd.tables.miscTable:getVal("travel_buy_time_limit"), "|", true)
	local limitTimes = limitList[vipLv + 1]
	local buyTimes = xyd.models.exploreModel:getExploreInfo().buy_times
	local leftTimes = limitTimes - buyTimes
	local travelBuy = xyd.split(xyd.tables.miscTable:getVal("travel_buy"), "|")
	local buyInfo = {}

	for i in ipairs(travelBuy) do
		local temp = xyd.split(travelBuy[i], "#", true)

		table.insert(buyInfo, temp)
	end

	return math.min(leftTimes, math.floor(xyd.models.backpack:getItemNumByID(buyInfo[2][1]) / buyInfo[2][2]))
end

function GameAssistant:getCostNumExplore(num)
	local travelBuy = xyd.split(xyd.tables.miscTable:getVal("travel_buy"), "|")
	local buyInfo = {}

	for i in ipairs(travelBuy) do
		local temp = xyd.split(travelBuy[i], "#", true)

		table.insert(buyInfo, temp)
	end

	return math.max(num * buyInfo[2][2], 0)
end

function GameAssistant:reqBuyBreadExplore(num)
	local msg = messages_pb.explore_buy_bread_req()
	msg.num = num

	xyd.Backend.get():request(xyd.mid.EXPLORE_BUY_BREAD, msg)
end

function GameAssistant:onGetExploreAwardMsg(event)
	xyd.db.misc:setValue({
		key = "gameAssistant_explore_award_timeStamp",
		value = xyd.getServerTime()
	})
end

function GameAssistant:getPetHangAward()
	if self:getPetlastHangRound() == 0 then
		return false
	else
		xyd.models.petTraining:reqTrainingAward()

		return true
	end
end

function GameAssistant:getPetlastHangRound()
	local level = xyd.models.petTraining:getTrainingLevel()
	local cycleTime = xyd.tables.miscTable:getVal("pet_training_hangup_cycle")
	local maxHangTime = xyd.tables.petTrainingNewAwardsTable:getTime(level)
	local hangStartTime = xyd.models.petTraining:getHangTime()
	local nowTime = xyd.getServerTime(true)
	local hangTime = math.min(nowTime - hangStartTime, maxHangTime)

	return math.floor(hangTime / cycleTime)
end

function GameAssistant:completeAllChallengePet(limitTime)
	local msg = messages_pb.pet_training_fight_req()
	msg.pet_id = 0
	local battleTimes = xyd.models.petTraining:getBattleTimes() or 0
	local buyTimes = xyd.models.petTraining:getBuyTimeTimes() or 0
	local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")
	local petBaseEnergy = xyd.tables.miscTable:getNumber("pet_training_pet_energy", "value")
	self.petChallengeTime = 0
	limitTime = limitTime or 9999
	local ids = xyd.models.petSlot:getPetIDs()

	table.sort(ids, function (a, b)
		local petA = xyd.models.petSlot:getPetByID(a)
		local scoreA = petA:getScore()
		local IDA = petA:getPetID()
		local petB = xyd.models.petSlot:getPetByID(b)
		local scoreB = petB:getScore()
		local IDB = petB:getPetID()

		if scoreA ~= scoreB then
			return scoreB < scoreA
		else
			return IDA < IDB
		end
	end)

	local limitLev = xyd.tables.miscTable:getNumber("pet_training_boss_level", "value")

	for i = 1, #ids do
		local pet = xyd.models.petSlot:getPetByID(ids[i])
		local id = pet:getPetID()

		if tonumber(id) ~= 0 then
			local battleTime = xyd.models.petTraining:getPetBattleTimes()[math.floor(id / 100)] or 0
			local lev = xyd.models.petSlot:getPetByID(id).lev
			local leftTili = petBaseEnergy - battleTime
			local leftChallengTime = baseTime - battleTimes - self.petChallengeTime

			if limitLev <= lev and leftTili > 0 and leftChallengTime > 0 and self.petChallengeTime < limitTime then
				for i = 1, math.min(leftTili, leftChallengTime) do
					if self.petChallengeTime < limitTime then
						table.insert(msg.pet_ids, id)

						self.petChallengeTime = self.petChallengeTime + 1
					end
				end
			end
		end
	end

	if #msg.pet_ids == 0 then
		return false
	end

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_FIGHT, msg)

	return true
end

function GameAssistant:buyChallengeTiliPet()
	local ids = xyd.models.petSlot:getPetIDs()

	table.sort(ids, function (a, b)
		local petA = xyd.models.petSlot:getPetByID(a)
		local scoreA = petA:getScore()
		local IDA = petA:getPetID()
		local petB = xyd.models.petSlot:getPetByID(b)
		local scoreB = petB:getScore()
		local IDB = petB:getPetID()

		if scoreA ~= scoreB then
			return scoreB < scoreA
		else
			return IDA < IDB
		end
	end)

	local petID = 0
	local limitLev = xyd.tables.miscTable:getNumber("pet_training_boss_level", "value")

	for i = 1, #ids do
		local id = tonumber(ids[i])
		local lev = xyd.models.petSlot:getPetByID(id).lev

		if limitLev <= lev then
			petID = id

			break
		end
	end

	local costNum = self:getCostNumPet(self.presetData.pet.fight - xyd.models.petTraining:getBuyTimeTimes())

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < costNum then
		return false
	end

	local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")

	for i = 1, self.presetData.pet.fight - xyd.models.petTraining:getBuyTimeTimes() - baseTime do
		xyd.models.petTraining:buyTimes(petID)
	end

	return true
end

function GameAssistant:getMaxCanBuyTimePet()
	local limitTime = #xyd.tables.miscTable:split2Cost("pet_training_energy_buy_cost", "value", "|#")

	if not xyd.models.petTraining:getBuyTimeTimes() then
		return limitTime
	end

	return limitTime - xyd.models.petTraining:getBuyTimeTimes()
end

function GameAssistant:getCostNumPet(num)
	local buyTimes = xyd.models.petTraining:getBuyTimeTimes() or 0
	local costNum = 0
	local limitTime = #xyd.tables.miscTable:split2Cost("pet_training_energy_buy_cost", "value", "|#")

	for i = buyTimes + 1, math.min(limitTime, buyTimes + num) do
		costNum = costNum + xyd.tables.miscTable:split2Cost("pet_training_energy_buy_cost", "value", "|#")[i][2]
	end

	return costNum
end

function GameAssistant:reqCheckInGuild()
	xyd.models.guild:checkIn()
end

function GameAssistant:setOrderAwards(awards)
	self.orderAwards = awards
end

function GameAssistant:getLevelUpOrderCost()
	local costNum = 0
	local hallLev = xyd.tables.guildMillTable:getIdByGold(xyd.models.guild.base_info.gold)
	local canGetOrderNum = (hallLev - 1) / 2 + 1
	local cost = 0

	for i = 1, self.presetData.guild.level - 1 do
		cost = cost + xyd.tables.guildOrderTable:getUpCost(i).num
	end

	cost = cost * canGetOrderNum

	return cost
end

function GameAssistant:reqLevelUpSingleOrder(id, times)
	local msg = messages_pb:guild_dininghall_upgrade_order_req()
	msg.order_id = id
	msg.times = times

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_UPGRADE_ORDER, msg)
end

function GameAssistant:reqLevelUpOrder()
	local desLev = self.presetData.guild.level
	local orderList = xyd.models.guild:getDiningHallOrderList()

	for _, order in pairs(orderList) do
		if order.start_time == 0 then
			local lev = order.order_lv

			self:reqLevelUpSingleOrder(order.order_id, desLev - lev)
		end
	end
end

function GameAssistant:reqGuildFightBoss()
	local msg = messages_pb.guild_boss_fight_req()
	msg.boss_id = xyd.GUILD_FINAL_BOSS_ID
	msg.pet_id = self.presetData.guildBattleFormationInfo.pet_id

	xyd.getFightPartnerMsg(msg.partners, self.presetData.guildBattleFormationInfo.partners)
	xyd.Backend.get():request(xyd.mid.GUILD_BOSS_FIGHT, msg)

	if xyd.models.guild:getFightUpdateTime() <= xyd:getServerTime() then
		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.NEW_GUILD_BOSS_CAN_FIGHT, xyd:getServerTime() + xyd.tables.miscTable:getNumber("guild_boss_fight_cd", "value"))
	end
end

function GameAssistant:getIfCanDoData()
	return self.ifCanDo
end

function GameAssistant:getTotalCostCrystal()
	return self.totalCost[xyd.ItemID.CRYSTAL]
end

function GameAssistant:resetCanDo()
	self.ifCanDo = {
		tavern = false,
		house = false,
		gamble = false,
		friend = false,
		dressShow = false,
		dungeon = false,
		arena = false,
		campaign = false,
		market = false,
		midas = {
			free = false,
			paid = false
		},
		dailyQuiz = {
			free = false,
			paid = {
				false,
				false,
				false
			}
		},
		summon = {
			senior = false,
			normal = false
		},
		academyAssessment = {
			free = false,
			paid = false
		},
		explore = {
			award = false,
			bread = false
		},
		pet = {
			paid = false,
			challenge = false,
			award = false,
			fight = false
		},
		guild = {
			signIn = false,
			gym = false,
			level = false,
			order = false
		}
	}
end

function GameAssistant:jungeIfCanDoTab1()
	local flag = false

	if self.presetData.midas.free == true and self.todayHaveDoneData.midas.free == false and xyd.models.midas.is_free_award == 0 then
		self.ifCanDo.midas.free = true
		flag = true
	end

	if self.presetData.midas.paid > 0 and self.todayHaveDoneData.midas.paid < self.presetData.midas.paid and xyd.models.midas.buy_times < self.presetData.midas.paid then
		self.ifCanDo.midas.paid = true
		flag = true
		self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:buyMidasTotalCost(self.presetData.midas.paid)
	end

	local timeStamp_campaign = xyd.db.misc:getValue("gameAssistant_campaign_timeStamp") or 0

	if xyd.getServerTime() - tonumber(timeStamp_campaign) > xyd.SECOND * 5 and self.presetData.campaign == true then
		self.ifCanDo.campaign = true
		flag = true
	end

	local timeStamp_house = xyd.db.misc:getValue("gameAssistant_house_timeStamp") or 0

	if xyd.getServerTime() - tonumber(timeStamp_house) > xyd.SECOND * 5 and self.presetData.house == true then
		self.ifCanDo.house = true
		flag = true
	end

	for i = 1, 3 do
		local data = xyd.models.dailyQuiz:getDataByType(i)
		local cur_quiz_id = data.cur_quiz_id

		if self.presetData.dailyQuiz.paid[i] > 0 and cur_quiz_id and cur_quiz_id > 0 and data.limit_times < self.presetData.dailyQuiz.paid[i] then
			self.ifCanDo.dailyQuiz.paid[i] = true
			flag = true
			self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:getCostNum(self.presetData.dailyQuiz.paid[i] - data.limit_times)
		end
	end

	for i = 1, 3 do
		local data = xyd.models.dailyQuiz:getDataByType(i)

		if data and data.cur_quiz_id and data.cur_quiz_id > 0 and xyd.models.dailyQuiz:checkCanFight(data.cur_quiz_id) then
			local leftTimes = data.limit_times - data.fight_times

			if data.fight_times < self.presetData.dailyQuiz.paid[i] then
				self.ifCanDo.dailyQuiz.free = true
				flag = true
			end
		end
	end

	if self.presetData.summon.normal < 2 and self.todayHaveDoneData.summon.normal == false then
		self.ifCanDo.summon.normal = true
		flag = true
	end

	if self.presetData.summon.senior < 2 and self.todayHaveDoneData.summon.senior == false then
		self.ifCanDo.summon.senior = true
		flag = true
	end

	if self.presetData.friend == true and self.todayHaveDoneData.friend == false then
		self.ifCanDo.friend = true
		flag = true
	end

	if self.presetData.arena == true and self.todayHaveDoneData.arena == false then
		self.ifCanDo.arena = true
		flag = true
	end

	if self.todayHaveDoneData.tavern == false then
		for i = 1, #self.presetData.tavern do
			if self.presetData.tavern[i] == true then
				self.ifCanDo.tavern = true
				flag = true

				break
			end
		end
	end

	if self.presetData.gamble == true and self.todayHaveDoneData.gamble == false then
		self.ifCanDo.gamble = true
		flag = true
	end

	if self.presetData.market then
		local shopInfo = xyd.models.shop:getShopInfo(xyd.ShopType.SHOP_BLACK_NEW)

		for index, value in pairs(self.presetData.market) do
			if type(value) == "number" and value > 0 then
				local info = shopInfo.items[index]
				local buy_times = info.buy_times or 0
				local left_times = 1

				if xyd.models.activity:isResidentReturnAddTime() then
					local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WELFARE_SOCIETY)
					left_times = left_times * return_multiple
				end

				if buy_times < left_times then
					self.ifCanDo.market = true
					flag = true
					local item = shopInfo.items[index].item
					local cost = shopInfo.items[index].cost

					if cost[1] == 1 then
						self.totalCost[xyd.ItemID.MANA] = self.totalCost[xyd.ItemID.MANA] + cost[2]
					end

					if cost[1] == 2 then
						self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + cost[2]
					end
				end
			end
		end
	end

	if self.presetData.dressShow == true and self.todayHaveDoneData.dressShow == false then
		self.ifCanDo.dressShow = true
		flag = true
	end

	return flag
end

function GameAssistant:jungeIfCanDoTab2()
	local flag = false
	local isOpen = xyd.models.academyAssessment:checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true)
	local startTime = xyd.models.academyAssessment.startTime or 0
	local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
	local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
	local isInShowTime = false

	if xyd.getServerTime() < startTime + allTime - showTime and startTime <= xyd.getServerTime() then
		-- Nothing
	elseif xyd.getServerTime() < startTime + allTime and xyd.getServerTime() >= startTime + allTime - showTime then
		isInShowTime = true
	else
		isOpen = false
	end

	if not isOpen or isInShowTime then
		self.presetData.academyAssessment.fort = 0
	end

	local fort = self.presetData.academyAssessment.fort

	if fort > 0 then
		local curStageID = self:getCurStageIDIndexAcademyAssessment(fort)
		local index = 0

		if curStageID == -1 then
			index = #xyd.tables.academyAssessmentNewTable2:getIdsByFort(self.presetData.academyAssessment.fort)
		else
			index = xyd.tables.academyAssessmentNewTable2:getSchoolSort(curStageID) - 1
		end

		if not curStageID or index <= 0 then
			return flag
		end
	end

	if fort > 0 and self.presetData.academyAssessment.paid > 0 and self.todayHaveDoneData.academyAssessment.paid < self.presetData.academyAssessment.paid and self:getMaxBuyTicketAcademyAssessment() > 0 then
		self.ifCanDo.academyAssessment.paid = true
		flag = true
		self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:getCostNumAcademyAssessment(self.presetData.academyAssessment.paid - xyd.models.academyAssessment:getBuySweepTimes())
	end

	if fort > 0 and self.presetData.academyAssessment.free > 0 and self:getMaxCanSweepAcademyAssessment() > 0 then
		self.ifCanDo.academyAssessment.free = true
		flag = true
	end

	return flag
end

function GameAssistant:jungeIfCanDoTab3()
	local flag = false
	local timeStamp_explore = xyd.db.misc:getValue("gameAssistant_explore_award_timeStamp") or 0

	if xyd.getServerTime() - tonumber(timeStamp_explore) > xyd.SECOND * 3600 and self.presetData.explore.award == true then
		self.ifCanDo.explore.award = true
		flag = true
	end

	if self:getBuyTimeBreadExplore() < self.presetData.explore.bread then
		self.ifCanDo.explore.bread = true
		flag = true
		self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:getCostNumExplore(self.presetData.explore.bread - self:getBuyTimeBreadExplore())
	end

	if self.presetData.pet.award == true and self:getPetlastHangRound() ~= 0 then
		self.ifCanDo.pet.award = true
		flag = true
	end

	local baseTime = xyd.tables.miscTable:getNumber("pet_training_boss_limit", "value")
	local buyTimes = xyd.models.petTraining:getBuyTimeTimes() or 0
	local battleTimes = xyd.models.petTraining:getBattleTimes() or 0
	local leftChallengTime = baseTime - battleTimes
	local allChallengTime = baseTime + buyTimes
	local haveDoneChallengTime = allChallengTime - leftChallengTime

	if haveDoneChallengTime < self.presetData.pet.fight then
		self.ifCanDo.pet.fight = true
		flag = true
		self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:getCostNumPet(self.presetData.pet.fight - buyTimes - baseTime)
	end

	return flag
end

function GameAssistant:jungeIfCanDoTab4()
	local flag = false

	if xyd.models.guild.guildID <= 0 or self.limitLevs[3] > xyd.models.guild.level then
		return flag
	end

	if self.presetData.guild.signIn == true and self.todayHaveDoneData.guild.signIn == false and xyd.models.guild.guildID > 0 and xyd.models.guild.isCheckIn ~= 1 then
		self.ifCanDo.guild.signIn = true
		flag = true
	end

	if self.presetData.guild.order == true and xyd.models.guild.guildID > 0 then
		local gSelfInfo = xyd.models.guild.self_info
		gSelfInfo.order_time = gSelfInfo.order_time or 0
		local tmp = xyd.getServerTime()
		local tmp2 = tonumber(xyd.tables.miscTable:getVal("guild_order_cd"))

		if tmp >= gSelfInfo.order_time + tmp2 then
			self.ifCanDo.guild.order = true
			flag = true
		end
	end

	if self.ifCanDo.guild.order == true and xyd.models.guild.guildID > 0 and self.presetData.guild.level > 0 then
		self.ifCanDo.guild.level = true
		flag = true
		self.totalCost[xyd.ItemID.CRYSTAL] = self.totalCost[xyd.ItemID.CRYSTAL] + self:getLevelUpOrderCost()
	end

	local leftTime = xyd.models.guild:getFinalBossLeftCount()

	if self.presetData.guild.gym == true and self.todayHaveDoneData.guild.gym == false and xyd.models.guild.guildID > 0 and leftTime > 0 then
		if os.date("!*t", xyd.getServerTime()).wday ~= 6 or os.date("!*t", xyd.getServerTime()).hour ~= 0 then
			self.ifCanDo.guild.gym = true
			flag = true
		end
	end

	return flag
end

function GameAssistant:jungeIfCanDo(tabIndex)
	local flag = false
	self.totalCost = {
		[xyd.ItemID.CRYSTAL] = 0,
		[xyd.ItemID.MANA] = 0
	}

	self:resetCanDo()

	if tabIndex == 0 or tabIndex == 1 then
		local f = self:jungeIfCanDoTab1()
		flag = flag or f
	end

	if tabIndex == 0 or tabIndex == 2 then
		local f = self:jungeIfCanDoTab2()
		flag = flag or f
	end

	if tabIndex == 0 or tabIndex == 3 then
		local f = self:jungeIfCanDoTab3()
		flag = flag or f
	end

	if tabIndex == 0 or tabIndex == 4 then
		local f = self:jungeIfCanDoTab4()
		flag = flag or f
	end

	return flag
end

return GameAssistant
