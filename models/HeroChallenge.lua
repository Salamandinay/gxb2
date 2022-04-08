local BaseModel = import(".BaseModel")
local HeroChallenge = class("HeroChallenge", BaseModel)
local Monster = import("app.models.Monster")
local Pet = import("app.models.Pet")
local cjson = require("cjson")

function HeroChallenge:ctor()
	BaseModel.ctor(self)

	self.heros_ = {}
	self.petIDs = {}
	self.pets_ = {}
	self.curFort_ = 1
	self.curFightStage_ = -1
	self.deadHeros_ = {}
	self.rewards_ = {}
	self.isSkipReport_ = false
	self.records = {}
	self.reports = {}
	self.oldMaxStages_ = {}
	self.buyChess_ = {}
	self.shopChess_ = {}
	self.chessCoin_ = {}
	self.chessHp_ = {}
	self.chessWinList_ = {}
	self.chessFirst_ = {}
	self.conditions_ = {}
	self.chessHeroNum_ = {}
	self.chessFreeTime_ = {}
	self.chessFailHp_ = {}
end

function HeroChallenge:get()
	if HeroChallenge.INSTANCE == nil then
		HeroChallenge.INSTANCE = HeroChallenge.new()

		HeroChallenge.INSTANCE:onRegister()
	end

	return HeroChallenge.INSTANCE
end

function HeroChallenge:reset()
	if HeroChallenge.INSTANCE then
		HeroChallenge.INSTANCE:removeEvents()
	end

	HeroChallenge.INSTANCE = nil
end

function HeroChallenge:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_PARTNER_CHALLENGE_CHESS_INFO, handler(self, self.onPartnerChallengeChessGetInfo))
	self:registerEvent(xyd.event.FIGHT_CHESS, handler(self, self.onFightChess))
	self:registerEvent(xyd.event.RESET_FORT_CHESS, handler(self, self.onResetFortChess))
	self:registerEvent(xyd.event.SELL_PARTNER, handler(self, self.onSellPartner))
	self:registerEvent(xyd.event.BUY_PARTNER, handler(self, self.onPickChess))
	self:registerEvent(xyd.event.REFRESH_CHESS_SHOP, handler(self, self.onRefreshChessShop))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_GET_INFO, handler(self, self.onPartnerChallengeGetInfo))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_FIGHT, handler(self, self.onFight))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_PICK_AWARDS, handler(self, self.onPickAwards))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_RESET_FORT, handler(self, self.onResetFort))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_GET_RECORDS, handler(self, self.onGetRecords))
	self:registerEvent(xyd.event.PARTNER_CHALLENGE_GET_REPORT, handler(self, self.onGetReport))
end

function HeroChallenge:reqHeroChallengeChessInfo()
	if self.data_chess then
		return
	end

	if not self:checkFunctionOpen() then
		return
	end

	local msg = messages_pb.get_partner_challenge_chess_info_req()

	xyd.Backend.get():request(xyd.mid.GET_PARTNER_CHALLENGE_CHESS_INFO, msg)
end

function HeroChallenge:reqRefreshChessShop(fortid)
	local msg = messages_pb.refresh_chess_shop_req()
	msg.fort_id = fortid

	xyd.Backend.get():request(xyd.mid.REFRESH_CHESS_SHOP, msg)
end

function HeroChallenge:reqHeroChallengeInfo(noCheck)
	if not self:checkFunctionOpen() then
		return
	end

	if self.data_ and not noCheck then
		return
	end

	local msg = messages_pb.partner_challenge_get_info_req()

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_GET_INFO, msg)
end

function HeroChallenge:checkActivity(activity_id)
	if not activity_id then
		return false
	end

	local fortID = xyd.tables.partnerChallengeTable:getFortIdByActivityId(activity_id)

	if not fortID then
		return false
	end

	return true
end

function HeroChallenge:getData()
	return self.data_
end

function HeroChallenge:checkFunctionOpen()
	return xyd.checkFunctionOpen(xyd.FunctionID.HERO_CHALLENGE, true)
end

function HeroChallenge:copyFortInfo(fortInfo, eventFortInfo)
	fortInfo.base_info = {
		fort_id = eventFortInfo.base_info.fort_id,
		fight_max_stage = eventFortInfo.base_info.fight_max_stage,
		current_stage = eventFortInfo.base_info.current_stage,
		rewards = eventFortInfo.base_info.rewards,
		pre_stage = eventFortInfo.base_info.fight_max_stage,
		hp = eventFortInfo.base_info.hp,
		coin = eventFortInfo.base_info.coin,
		free_times = eventFortInfo.base_info.free_times,
		conditions = eventFortInfo.base_info.conditions
	}
	fortInfo.live_partner_ids = {}

	if type(eventFortInfo.live_partner_ids) == "string" then
		fortInfo.live_partner_ids = cjson.decode(eventFortInfo.live_partner_ids)
	else
		for j = 1, #eventFortInfo.live_partner_ids do
			table.insert(fortInfo.live_partner_ids, eventFortInfo.live_partner_ids[j])
		end
	end

	fortInfo.dead_partner_ids = {}

	if eventFortInfo.dead_partner_ids then
		for j = 1, #eventFortInfo.dead_partner_ids do
			table.insert(fortInfo.dead_partner_ids, eventFortInfo.dead_partner_ids[j])
		end
	end

	fortInfo.pet_ids = {}

	if eventFortInfo.pet_ids then
		for j = 1, #eventFortInfo.pet_ids do
			table.insert(fortInfo.pet_ids, eventFortInfo.pet_ids[j])
		end
	end

	fortInfo.buff_ids = {}

	if eventFortInfo.buff_ids then
		for j = 1, #eventFortInfo.buff_ids do
			table.insert(fortInfo.buff_ids, eventFortInfo.buff_ids[j])
		end
	end
end

function HeroChallenge:onPartnerChallengeGetInfo(event)
	self.data_ = {
		map_info = {}
	}
	self.data_.map_info.ticket_time = event.data.map_info.ticket_time
	self.data_.map_list = {}
	local theData = xyd.decodeProtoBuf(event.data)

	for i = 1, #theData.map_list do
		local map_info = theData.map_list[i]
		self.data_.map_list[i] = {}

		self:copyFortInfo(self.data_.map_list[i], map_info)
	end

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.UPDATE_CHALLENGE_TICKET
	})
end

function HeroChallenge:onPartnerChallengeChessGetInfo(event)
	self.data_chess = {
		map_info = {},
		map_list = {}
	}
	local theData = xyd.decodeProtoBuf(event.data)

	for i = 1, #theData.map_list do
		local map_info = theData.map_list[i]
		self.data_chess.map_list[i] = {}

		self:copyFortInfo(self.data_chess.map_list[i], map_info)

		local baseInfo = self.data_chess.map_list[i].base_info
		local rewards = baseInfo.rewards

		if rewards and tostring(rewards) ~= "" then
			baseInfo.rewards = cjson.decode(rewards)
		else
			baseInfo.rewards = nil
		end

		local fortID = baseInfo.fort_id
		self.chessCoin_[fortID] = baseInfo.coin
		self.chessHp_[fortID] = baseInfo.hp
		self.buyChess_[fortID] = baseInfo.rewards
		self.chessFirst_[fortID] = baseInfo.is_first_buy
		self.chessFreeTime_[fortID] = baseInfo.free_times
		self.chessHeroNum_[fortID] = self.data_chess.map_list[i].live_partner_ids
		self.shopChess_[fortID] = baseInfo.rewards
		self.conditions_[fortID] = baseInfo.conditions
	end
end

function HeroChallenge:getshopchess(fortID)
	if self.shopChess_ and next(self.shopChess_) then
		return self.shopChess_[fortID]
	end
end

function HeroChallenge:onRefreshChessShop(event)
	if event.data and event.data.fort_info and tostring(event.data.fort_info) ~= "" then
		local baseInfo = event.data.fort_info.base_info
		local fortID = baseInfo.fort_id
		local rewards = baseInfo.rewards

		if rewards and tostring(rewards) ~= "" then
			rewards = cjson.decode(tostring(rewards))
		else
			rewards = {}
		end

		self.buyChess_[fortID] = rewards
		self.chessCoin_[fortID] = baseInfo.coin
		self.chessFreeTime_[fortID] = baseInfo.free_times
		self.shopChess_[fortID] = rewards
	end
end

function HeroChallenge:onFightChess(event)
	local theData = xyd.decodeProtoBuf(event.data)

	if theData.fort_info then
		self:updateFortInfo(theData.fort_info)

		if self.curFightStage_ then
			self.records[self.curFightStage_] = nil
		end

		local fortID = theData.fort_info.base_info.fort_id
		local baseInfo = theData.fort_info.base_info
		self.chessHp_[fortID] = baseInfo.hp
		self.chessWinList_[fortID] = theData.is_win
		self.conditions_[fortID] = baseInfo.conditions
		local dieInfo = theData.battle_report.die_info
		local dieNum = 0

		for i = 1, #dieInfo do
			if dieInfo[i] and tonumber(dieInfo[i]) > 6 then
				dieNum = dieNum + 1
			end
		end

		local fixStage = baseInfo.current_stage - xyd.tables.partnerChallengeChessTable:getFirstStageId(baseInfo.current_stage) + 1
		self.chessFailHp_[fortID] = fixStage - dieNum + #event.data.battle_report.teamB
		self.curFightStage_ = nil
	end
end

function HeroChallenge:reqFightChess(partners, petID, stageID)
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.HERO_CHALLENGE) <= 1 then
		xyd.models.heroChallenge:reqHeroChallengeInfo(true)
		xyd.models.heroChallenge:reqHeroChallengeChessInfo(true)
	end

	local infos = {}
	local fortID = xyd.tables.partnerChallengeChessTable:getFortID(stageID)

	for _, partner in ipairs(partners) do
		local hero = self:getChessPartner(partner.partner_id, fortID)

		if hero then
			table.insert(infos, {
				table_id = tonumber(hero:getTableID()),
				pos = partner.pos
			})
		end
	end

	local fortInfo = self:getFortInfoByFortID(fortID)

	if fortInfo then
		self.oldMaxStages_[fortID] = fortInfo.base_info.fight_max_stage
	end

	self.curFightStage_ = tonumber(stageID)
	local msg = messages_pb.fight_chess_req()
	msg.pet_id = petID
	msg.fort_id = fortID
	msg.stage_id = tonumber(stageID)

	for _, info in ipairs(infos) do
		local p = messages_pb.partner_challenge_fight_info()
		p.table_id = info.table_id
		p.pos = info.pos

		table.insert(msg.partners, p)
	end

	xyd.Backend.get():request(xyd.mid.FIGHT_CHESS, msg)
end

function HeroChallenge:getChessPartner(partnerID, fortID)
	local partner = nil
	local heros = self:getHeros(fortID)

	for _, p in ipairs(heros) do
		if p:getPartnerID() == partnerID then
			partner = p

			break
		end
	end

	return partner
end

function HeroChallenge:reqFight(partners, petID, stageID)
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.HERO_CHALLENGE) <= 1 then
		xyd.models.heroChallenge:reqHeroChallengeInfo(true)
		xyd.models.heroChallenge:reqHeroChallengeChessInfo(true)
	end

	local info = {}
	local fortID = xyd.tables.partnerChallengeTable:getFortID(stageID)

	for _, partner in pairs(partners) do
		local hero = self:getPartner(partner.partner_id, fortID)

		table.insert(info, {
			table_id = hero:getTableID(),
			pos = partner.pos
		})
	end

	local fortInfo = self:getFortInfoByFortID(fortID)

	if fortInfo then
		self.oldMaxStages_[fortID] = fortInfo.base_info.fight_max_stage
	end

	self.curFightStage_ = tonumber(stageID)
	local params = {
		partners = info,
		pet_id = petID,
		fort_id = fortID,
		stage_id = tonumber(stageID)
	}
	local msg = messages_pb.partner_challenge_fight_req()

	for _, partner in ipairs(info) do
		local p = messages_pb.partner_challenge_fight_info()
		p.table_id = partner.table_id
		p.pos = partner.pos

		table.insert(msg.partners, p)
	end

	msg.pet_id = params.pet_id
	msg.fort_id = params.fort_id
	msg.stage_id = params.stage_id

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_FIGHT, msg)
end

function HeroChallenge:onFight(event)
	local theData = xyd.decodeProtoBuf(event.data)

	if tostring(event.data.fort_info) ~= "" then
		self:updateFortInfo(theData.fort_info)

		if self.curFightStage_ then
			self.records[self.curFightStage_] = nil
		end
	end

	self.curFightStage_ = nil
end

function HeroChallenge:updateFortInfo(fortInfo)
	local mapList = self:getMapList()

	if xyd.tables.partnerChallengeChessTable:getFortType(fortInfo.base_info.fort_id) == xyd.HeroChallengeFort.CHESS then
		mapList = self:getChessMapList()
	end

	local fortID = fortInfo.base_info.fort_id
	local index = -1

	for i = 1, #mapList do
		if mapList[i].base_info.fort_id == fortID then
			index = i

			break
		end
	end

	if index > -1 then
		local pre = mapList[index].base_info.fight_max_stage

		self:copyFortInfo(mapList[index], fortInfo)

		mapList[index].base_info.pre_stage = pre
	end

	self:resetFortInfo(fortID)

	if xyd.tables.partnerChallengeChessTable:getFortType(fortID) == xyd.HeroChallengeFort.CHESS then
		self:initChessHeros(fortID)
	else
		self:initHeros(fortID)
	end

	self:initPetList(fortID)
end

function HeroChallenge:getChessMapList()
	if self.data_chess and next(self.data_chess) then
		return self.data_chess.map_list
	else
		return {}
	end
end

function HeroChallenge:reqPickAwards(fortID, index)
	local msg = messages_pb.partner_challenge_pick_awards_req()
	msg.fort_id = tonumber(fortID)
	msg.index = index

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_PICK_AWARDS, msg)
end

function HeroChallenge:onPickAwards(event)
	local theData = xyd.decodeProtoBuf(event.data)

	if theData.fort_info then
		self:updateFortInfo(theData.fort_info)
	end
end

function HeroChallenge:onPickChess(event)
	local theData = xyd.decodeProtoBuf(event.data)

	if event.data.fort_info and tostring(event.data.fort_info) ~= "" then
		local baseInfo = theData.fort_info.base_info
		local rewards = baseInfo.rewards

		if rewards and rewards ~= "" then
			rewards = cjson.decode(rewards)
		else
			rewards = nil
		end

		local fortID = baseInfo.fort_id

		self:updateFortInfo(theData.fort_info)

		self.chessCoin_[fortID] = baseInfo.coin
		self.chessHp_[fortID] = baseInfo.hp
		self.buyChess_[fortID] = rewards
		self.chessFirst_[fortID] = baseInfo.is_first_buy
		self.chessFreeTime_[fortID] = baseInfo.free_times
		self.conditions_[fortID] = baseInfo.conditions

		print("baseInfo.live_partner_ids")
		print(theData.fort_info.live_partner_ids)

		if theData.fort_info.live_partner_ids and tostring(theData.fort_info.live_partner_ids) ~= "" then
			self.chessHeroNum_[fortID] = cjson.decode(theData.fort_info.live_partner_ids)
		else
			self.chessHeroNum_[fortID] = {}
		end

		self.shopChess_[fortID] = rewards
	end
end

function HeroChallenge:reqResetFort(fortID)
	local msg = messages_pb.partner_challenge_reset_fort_req()
	msg.fort_id = tonumber(fortID)

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_RESET_FORT, msg)
end

function HeroChallenge:reqResetFortChess(fortID)
	local msg = messages_pb.reset_fort_chess_req()
	msg.fort_id = tonumber(fortID)

	xyd.Backend.get():request(xyd.mid.RESET_FORT_CHESS, msg)
end

function HeroChallenge:reqSellPartner(fortID, partnerIDs)
	local msg = messages_pb.sell_partner_req()
	msg.fort_id = tonumber(fortID)

	for _, id in ipairs(partnerIDs) do
		table.insert(msg.partner_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.SELL_PARTNER, msg)
end

function HeroChallenge:onSellPartner(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data and data.fort_info and tostring(data.fort_info) ~= "" then
		local fortID = data.fort_info.base_info.fort_id

		self:updateFortInfo(data.fort_info)

		self.chessCoin_[fortID] = data.fort_info.base_info.coin

		if data.fort_info.live_partner_ids and data.fort_info.live_partner_ids ~= "" then
			self.chessHeroNum_[fortID] = cjson.decode(data.fort_info.live_partner_ids)
		else
			self.chessHeroNum_[fortID] = {}
		end
	end
end

function HeroChallenge:onResetFort(event)
	local theData = xyd.decodeProtoBuf(event.data)

	if theData.fort_info then
		local fortID = theData.fort_info.base_info.fort_id

		self:resetFortInfo(fortID)
		self:clearReward(fortID)
		self:updateFortInfo(theData.fort_info)
	end

	xyd.db.formation:addOrUpdate({
		key = xyd.BattleType.HERO_CHALLENGE,
		value = cjson.encode("")
	})
end

function HeroChallenge:onResetFortChess(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data and data.fort_info and tostring(data.fort_info) ~= "" then
		local baseInfo = data.fort_info.base_info
		local fortID = baseInfo.fort_id

		self:resetFortInfo(fortID)

		local rewards = baseInfo.rewards

		if rewards and rewards ~= "" then
			rewards = cjson.decode(rewards)
		else
			rewards = nil
		end

		self:updateFortInfo(data.fort_info)

		self.chessCoin_[fortID] = baseInfo.coin
		self.chessHp_[fortID] = baseInfo.hp
		self.buyChess_[fortID] = rewards
		self.chessFirst_[fortID] = baseInfo.is_first_buy
		self.chessFreeTime_[fortID] = baseInfo.free_times
		self.chessHeroNum_[fortID] = baseInfo.live_partner_ids
		self.conditions_[fortID] = baseInfo.conditions
		self.shopChess_[fortID] = rewards

		xyd.db.formation:setValue({
			key = xyd.BattleType.HERO_CHALLENGE_CHESS,
			value = cjson.encode("")
		})
	end
end

function HeroChallenge:resetFortInfo(fortID)
	self.heros_[fortID] = nil
	self.petIDs[fortID] = nil
	self.pets_[fortID] = nil
	self.deadHeros_[fortID] = nil
end

function HeroChallenge:reqGetRecords(stageID)
	if self.records[stageID] then
		return true
	end

	local msg = messages_pb.partner_challenge_get_records_req()
	msg.stage_id = stageID

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_GET_RECORDS, msg)

	return false
end

function HeroChallenge:onGetRecords(event)
	local id = event.data.stage_id
	self.records[id] = event.data.records
end

function HeroChallenge:getRecords(id)
	return self.records[id]
end

function HeroChallenge:reqGetReport(stageID, recordID)
	local msg = messages_pb.partner_challenge_get_report_req()
	msg.stage_id = stageID
	msg.record_id = recordID

	xyd.Backend.get():request(xyd.mid.PARTNER_CHALLENGE_GET_REPORT, msg)
end

function HeroChallenge:onGetReport(event)
	local data = xyd.decodeProtoBuf(event.data)
	local recordID = event.data.record_id
	local stageID = event.data.stage_id
	self.reports[tostring(stageID) .. "_" .. tostring(recordID)] = data
end

function HeroChallenge:getReport(id, recordID)
	local key = tostring(id) .. "_" .. tostring(recordID)

	return self.reports[key]
end

function HeroChallenge:getMapList()
	if self.data_ then
		return self.data_.map_list
	end

	return {}
end

function HeroChallenge:getFortInfoByFortID(fortID)
	local list = self:getMapList()

	if xyd.tables.partnerChallengeChessTable:getFortType(fortID) == xyd.HeroChallengeFort.CHESS then
		list = self:getChessMapList()
	end

	local fortInfo = nil

	for _, info in pairs(list) do
		if info.base_info and info.base_info.fort_id == fortID then
			fortInfo = info

			break
		end
	end

	return fortInfo
end

function HeroChallenge:getHeros(fortID)
	if xyd.tables.partnerChallengeChessTable:getFortType(fortID) == xyd.HeroChallengeFort.CHESS and not self.heros_[fortID] then
		self:initChessHeros(fortID)
	end

	if self.heros_[fortID] then
		return self.heros_[fortID]
	end

	self:initHeros(fortID)

	return self.heros_[fortID] or {}
end

function HeroChallenge:initChessHeros(fortID, stageID)
	local info = self:getFortInfoByFortID(fortID)
	local heros = {}
	local m = 1

	if info then
		local liveIDs = info.live_partner_ids

		for table_id, num in pairs(liveIDs) do
			for j = 1, num do
				local np = Monster.new()

				np:populateWithTableID(table_id, {
					partnerID = m
				})

				m = m + 1

				table.insert(heros, np)
			end
		end

		self.heros_[fortID] = heros

		self:sortHeros(fortID)

		return
	end
end

function HeroChallenge:getPets(fortID)
	return self.pets_[fortID and fortID or self.curFort_]
end

function HeroChallenge:isHasPet(petID, fortID)
	local petIDs = self:getPetIDs(fortID)

	if petIDs and xyd.arrayIndexOf(petIDs, petID) > -1 then
		return true
	end

	return false
end

function HeroChallenge:getAliveNum(fortID)
	local info = self:getFortInfoByFortID(fortID)
	local num = 0

	if info then
		local curStage = info.base_info.current_stage
		local liveIDs = info.live_partner_ids
		local isPuzzle = xyd.tables.partnerChallengeTable:isPuzzle(curStage)

		if isPuzzle then
			liveIDs = xyd.tables.partnerChallengeTable:initialPartner(curStage)
		end

		num = #liveIDs
	end

	return num
end

function HeroChallenge:initHeros(fortID, stageID)
	local info = self:getFortInfoByFortID(fortID)
	local heros = {}
	local deadHeros = {}

	if info then
		local curStage = stageID and stageID or info.base_info.current_stage
		local isPuzzle = xyd.tables.partnerChallengeTable:isPuzzle(curStage)
		local liveIDs = info.live_partner_ids
		local deadIDs = info.dead_partner_ids

		if isPuzzle then
			liveIDs = xyd.tables.partnerChallengeTable:initialPartner(curStage)
			deadIDs = {}
		end

		for i = 1, #liveIDs do
			local id = liveIDs[i]
			local np = Monster.new()

			np:populateWithTableID(id, {
				partnerID = i + 1
			})
			table.insert(heros, np)
		end

		for i = 1, #deadIDs do
			local id = deadIDs[i]
			local np = Monster.new()
			local partnerID = i + 1 + #liveIDs

			np:populateWithTableID(id, {
				partnerID = partnerID
			})
			table.insert(heros, np)
			table.insert(deadHeros, partnerID)
		end
	end

	self.heros_[fortID] = heros
	self.deadHeros_[fortID] = deadHeros

	self:sortHeros(fortID)
end

function HeroChallenge:sortHeros(fortID)
	local function levSort(a, b)
		local weight_a = a:getLevel() * 100 + a:getStar() * 10 + a:getGroup()
		local weight_b = b:getLevel() * 100 + b:getStar() * 10 + b:getGroup()

		if weight_a - weight_b ~= 0 then
			return weight_b < weight_a
		else
			return a:getTableID() < b:getTableID()
		end
	end

	table.sort(self.heros_[fortID], levSort)
end

function HeroChallenge:getPartner(partnerID, fortID)
	local partner = nil
	local heros = self:getHeros(fortID)

	for i = 1, #heros do
		local p = heros[i]

		if p:getPartnerID() == partnerID then
			partner = p

			break
		end
	end

	return partner
end

function HeroChallenge:getPartnerByTableID(tableID, fortID, hasSelect)
	if hasSelect == nil then
		hasSelect = {}
	end

	local partner = nil
	local heros = self:getHeros(fortID)

	for i = 1, #heros do
		local p = heros[i]

		if (not partner or not self:isDead(p:getPartnerID(), fortID)) and (p:getTableID() == tableID or p:getHeroTableID() == tableID) and xyd.arrayIndexOf(hasSelect, p:getPartnerID()) < 0 then
			partner = p

			break
		end
	end

	return partner
end

function HeroChallenge:isDead(partnerID, fortID)
	local deadIDs = self.deadHeros_[fortID] or {}

	return xyd.arrayIndexOf(deadIDs, partnerID) > -1
end

function HeroChallenge:initPetList(fortID)
	local id = fortID and fortID or self.curFort_
	self.petIDs[id] = {}
	self.pets_[id] = {}
	local info = self:getFortInfoByFortID(id)

	if info then
		local petIDs = info.pet_ids

		for _, petId in pairs(petIDs) do
			local isOpen = xyd.tables.petTable:isOpen(petId)

			if isOpen then
				local pet = Pet.new()
				local skills = xyd.tables.miscTable:split2num("challenge_pet_skill", "value", "|")

				pet:populate({
					pet_id = petId,
					lev = xyd.tables.miscTable:getNumber("challenge_pet_lv", "value"),
					grade = xyd.tables.petTable:getMaxGrade(petId),
					skills = skills
				})

				self.pets_[id][petId] = pet

				table.insert(self.petIDs[id], petId)
			end
		end
	end
end

function HeroChallenge:getPetIDs(fortID)
	if self.petIDs[fortID and fortID or self.curFort_] then
		return self.petIDs[fortID and fortID or self.curFort_]
	end

	self:initPetList()

	return self.petIDs[fortID and fortID or self.curFort_] or {}
end

function HeroChallenge:getBuffIDs(fortID)
	local info = self:getFortInfoByFortID(fortID)
	local ids = {}

	if info then
		ids = info.buff_ids
	end

	return ids
end

function HeroChallenge:getPetByID(petID, fortID)
	if self.pets_[fortID and fortID or self.curFort_] then
		return self.pets_[fortID and fortID or self.curFort_][petID]
	end

	return nil
end

function HeroChallenge:getTicket()
	if not xyd.getServerTime() then
		return xyd.models.backpack:getItemNumByID(xyd.ItemID.HERO_CHALLENGE)
	end

	local time = xyd:getServerTime() - self:getTicketTime()
	local cd = xyd.tables.miscTable:getNumber("challenge_voucher_cd", "value")

	if time < cd then
		return xyd.models.backpack:getItemNumByID(xyd.ItemID.HERO_CHALLENGE)
	end

	local max = xyd.tables.miscTable:getNumber("challenge_voucher_max", "value")
	local delta = math.floor(time / cd)
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.HERO_CHALLENGE) + delta
	local min = math.min(max, num)

	return min
end

function HeroChallenge:getTicketTime()
	local time_ = 0

	if self.data_ and self.data_.map_info then
		time_ = self.data_.map_info.ticket_time
	end

	return time_
end

function HeroChallenge:getLeftTime()
	local max = xyd.tables.miscTable:getNumber("challenge_voucher_max", "value")

	if max <= self:getTicket() then
		return 0
	end

	local time = xyd:getServerTime() - self:getTicketTime()
	local cd = xyd.tables.miscTable:getNumber("challenge_voucher_cd", "value")
	local leftTime = cd - time % cd

	if leftTime < 1 then
		leftTime = cd
	end

	return leftTime
end

function HeroChallenge:setCurFort(fortID)
	self.curFort_ = fortID
end

function HeroChallenge:getCurFort()
	return self.curFort_
end

function HeroChallenge:isSkipReport()
	return self.isSkipReport_
end

function HeroChallenge:setSkipReport(flag)
	self.isSkipReport_ = flag
end

function HeroChallenge:getCurrentStage(fortID)
	local info = self:getFortInfoByFortID(fortID)
	local curStge = 1

	if info and info.base_info then
		curStge = info.base_info.current_stage
	end

	return curStge
end

function HeroChallenge:getRewards(fortID)
	if self.rewards_[fortID] then
		return self.rewards_[fortID]
	end

	local info = self:getFortInfoByFortID(fortID)

	if xyd.tables.partnerChallengeChessTable:getFortType(fortID) == xyd.HeroChallengeFort.CHESS then
		local sum = {}
		local ids = xyd.tables.partnerChallengeChessTable:getIDs()

		for i = 1, #ids do
			local awradNum = xyd.tables.partnerChallengeChessTable:getReward2(ids[i])
			local item = {
				reward_type = 4,
				num = awradNum or 0,
				ids = {
					xyd.ItemID.HERO_CHALLENGE_CHESS
				}
			}

			table.insert(sum, item)

			self.rewards_[fortID] = sum
		end

		return self.rewards_[fortID]
	end

	if info then
		local rewards = info.base_info.rewards

		if rewards and rewards ~= "" and rewards ~= "{}" then
			rewards = cjson.decode(rewards)
		else
			rewards = nil
		end

		info.base_info.rewards = nil
		self.rewards_[fortID] = rewards
	end

	return self.rewards_[fortID]
end

function HeroChallenge:clearReward(fortID)
	self.rewards_[fortID] = nil
end

function HeroChallenge:getOldMaxStage(fortID)
	return self.oldMaxStages_[fortID] or 0
end

function HeroChallenge:checkPlayStory(stageID)
	local fortID = xyd.tables.partnerChallengeTable:getFortID(stageID)
	local maxStage = self:getOldMaxStage(fortID)

	if stageID <= maxStage then
		return false
	end

	return true
end

function HeroChallenge:checkPlayChessStory(stageID)
	local fortID = xyd.tables.partnerChallengeChessTable:getFortID(stageID)
	local maxStage = self:getOldMaxStage(fortID)

	if stageID <= maxStage then
		return false
	end

	return true
end

function HeroChallenge:checkHideSkip(stageID)
	local fortID = xyd.tables.partnerChallengeTable:getFortID(stageID)
	local maxStage = self:getOldMaxStage(fortID)
	local flag = false

	if maxStage < stageID then
		flag = true
	end

	return flag
end

function HeroChallenge:checkNeedShowRed()
	local touchIds = self:getTouchRedID()
	local ids = xyd.tables.partnerChallengeTable:getFortIds()
	local chessIds = xyd.tables.partnerChallengeChessTable:getFortIds()
	local newIds = {}

	for key, id in pairs(chessIds) do
		newIds[tonumber(key)] = id
	end

	for id in pairs(ids) do
		newIds[tonumber(id)] = ids[id]
	end

	for id in pairs(newIds) do
		if xyd.arrayIndexOf(touchIds, tonumber(id)) < 0 then
			local activity_id = xyd.tables.partnerChallengeTable:getActivityByFortId(id)

			if not xyd.models.activity:getActivity(activity_id) then
				return true
			end
		end
	end

	return false
end

function HeroChallenge:updateRedMark()
	if self:checkFunctionOpen() and self:checkNeedShowRed() then
		xyd.models.redMark:setMark(xyd.RedMarkType.HERO_CHALLENGE, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.HERO_CHALLENGE, false)
	end
end

function HeroChallenge:getTouchRedID()
	local str = xyd.db.misc:getValue("hero_challenge_touch_id")
	local ids = {}

	if str then
		ids = cjson.decode(str) or {}
	end

	return ids
end

function HeroChallenge:saveRedInfo(id)
	local ids = self:getTouchRedID()

	if xyd.arrayIndexOf(ids, id) > -1 then
		return
	end

	table.insert(ids, id)
	xyd.db.misc:addOrUpdate({
		key = "hero_challenge_touch_id",
		value = cjson.encode(ids)
	})
	self:updateRedMark()
end

function HeroChallenge:checkItemShowRed(id)
	local touchIds = self:getTouchRedID()

	return xyd.arrayIndexOf(touchIds, id) < 0
end

function HeroChallenge:initBookLabel(id)
	if not self.data_chess then
		return 0
	end

	for i = 1, #self.data_chess.map_list do
		if self.data_chess.map_list[i].base_info.fort_id == id then
			return self.data_chess.map_list[i].base_info.coin
		end
	end

	return 0
end

function HeroChallenge:getBuyChessReward(fortID)
	if self.buyChess_ and next(self.buyChess_) and self.buyChess_[fortID] then
		return self.buyChess_[fortID]
	end
end

function HeroChallenge:reqBuyPartner(fortID, index)
	local msg = messages_pb.buy_partner_req()
	msg.fort_id = tonumber(fortID)
	msg.index = index

	xyd.Backend.get():request(xyd.mid.BUY_PARTNER, msg)
end

function HeroChallenge:getCoin(fortid)
	if self.chessCoin_ then
		return self.chessCoin_[fortid]
	end
end

function HeroChallenge:getHp(fortid)
	if self.chessHp_ then
		return self.chessHp_[fortid]
	end
end

function HeroChallenge:getiswin(fortid)
	if self.chessWinList_ then
		return self.chessWinList_[fortid]
	end
end

function HeroChallenge:getFailhp(fortid)
	if self.chessFailHp_ then
		return self.chessFailHp_[fortid]
	end
end

function HeroChallenge:getFreeTime(fortid)
	if self.chessFreeTime_ then
		return self.chessFreeTime_[fortid]
	end
end

function HeroChallenge:getConditions(fortid)
	if self.conditions_ then
		return self.conditions_[fortid]
	end
end

function HeroChallenge:getHeroNum(fortid, partnerID)
	if self.chessHeroNum_ and self.chessHeroNum_[fortid] then
		local liveIDs = self.chessHeroNum_[fortid]

		for key, num in pairs(liveIDs) do
			if tonumber(key) == tonumber(partnerID) then
				return num
			end
		end
	end
end

function HeroChallenge:getFirst(fortid)
	if not self.chessFirst_ then
		return
	end

	return self.chessFirst_[fortid]
end

function HeroChallenge:getAwardItemInfo()
	local fortId = self:getCurFort()
	local info = self:getFortInfoByFortID(fortId)
	local awards = self:getRewards(fortId)
	local curStage = info.base_info.current_stage
	local curAward = nil

	if curStage == -1 then
		curAward = {
			num = 0,
			ids = {
				165
			}
		}
	elseif curStage == 1 then
		curAward = awards[1]
	else
		curAward = awards[curStage - 1]
	end

	return curAward
end

HeroChallenge.INSTANCE = nil

return HeroChallenge
