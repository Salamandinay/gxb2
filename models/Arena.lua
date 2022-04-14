local BaseModel = import(".BaseModel")
local Arena = class("Arena", BaseModel)

function Arena:ctor()
	BaseModel.ctor(self)

	self.defFormation = {}
	self.fightRecord = {}
	self.enemyList = {}
	self.rankList = {}
	self.skipReport = false
	local flag = false

	if tonumber(xyd.db.misc:getValue("arena_skip_report")) == 1 then
		flag = true
	end

	self.skipReport = flag
end

function Arena:get()
	if Arena.INSTANCE == nil then
		Arena.INSTANCE = Arena.new()

		Arena.INSTANCE:onRegister()
	end

	return Arena.INSTANCE
end

function Arena:reset()
	if Arena.INSTANCE then
		Arena.INSTANCE:removeEvents()
	end

	Arena.INSTANCE = nil
end

function Arena:onRegister()
	self:registerEvent(xyd.event.GET_ARENA_INFO, handler(self, self.onGetArenaBaseInfo))
	self:registerEvent(xyd.event.SET_PARTNERS, handler(self, self.onGetArenaInfo))
	self:registerEvent(xyd.event.GET_MATCH_INFOS, handler(self, self.onGetEnemyList))
	self:registerEvent(xyd.event.GET_RANK_LIST, handler(self, self.onGetRankList))
	self:registerEvent(xyd.event.ARENA_FIGHT, handler(self, self.onFight))
	self:registerEvent(xyd.event.GET_ARENA_NEW_RANK_LIST, handler(self, self.onGetArenaNewRankListBack))
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.ARENA then
			self:reqRankList()
			self:reqArenaInfo()
		end
	end)
end

function Arena:onSystemUpdate()
	if xyd.checkFunctionOpen(xyd.FunctionID.ARENA, true) then
		self:reqArenaInfo()
	end
end

function Arena:reqArenaInfo()
	local msg = messages_pb:get_arena_info_req()

	xyd.Backend:get():request(xyd.mid.GET_ARENA_INFO, msg)
end

function Arena:onGetArenaBaseInfo(event)
	self:onGetArenaInfo(event)

	local data = xyd.decodeProtoBuf(event.data)
	self.is_last = data.is_last
	self.is_old = data.is_old
	self.slave_ids = data.slave_ids
	local battleChooseWd = xyd.WindowManager.get():getWindow("battle_choose_window")

	if battleChooseWd then
		battleChooseWd:updateArenaShow()
	end

	if self:getIsSettlementing() then
		print("testtestsend==========================test" .. xyd.getServerTime())

		local arenaWd = xyd.WindowManager.get():getWindow("arena_window")

		if arenaWd then
			xyd.WindowManager.get():closeWindow("arena_window")
		end

		xyd.addGlobalTimer(function ()
			xyd.models.arena:reqArenaInfo()
			xyd.models.arena:reqRankList()
		end, 30, 1)
	end

	local arenaEndTime = self:getDDL() - xyd.getServerTime()

	if arenaEndTime > 0 and (not self.globalEndTime or self.globalEndTime and self.globalEndTime < self:getDDL()) then
		self.globalEndTime = self:getDDL()

		xyd.addGlobalTimer(function ()
			local arenaWd = xyd.WindowManager.get():getWindow("arena_window")

			if arenaWd then
				xyd.WindowManager.get():closeWindow("arena_window")
			end

			xyd.models.arena:reqArenaInfo()
			xyd.models.arena:reqRankList()
		end, arenaEndTime + 1, 1)
	end
end

function Arena:onGetArenaInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	self:updateLock(data.partners)

	self.rank = data.rank
	self.topRank = data.best_rank
	self.score = data.score
	self.ddl = data.end_time and data.end_time or self.ddl
	self.freeTimes = data.free_times
	self.power = data.power
	self.defFormation = data.partners or {}

	if data.pet and tostring(data.pet) ~= "" then
		self.pet = data.pet.pet_id
	else
		self.pet = nil
	end

	self.start_time = data.start_time and data.start_time or self.start_time

	xyd.models.advertiseComplete:onArenaScore()
end

function Arena:updateRank(rank)
	self.rank = rank
end

function Arena:updateScore(score)
	self.score = score

	xyd.models.advertiseComplete:onArenaScore()
end

function Arena:updateLock(formation)
	local partners = xyd.models.slot:getPartners()

	if formation and #formation > 0 then
		local oldDef = self.defFormation

		for i = 1, #oldDef do
			if partners[oldDef[i].partner_id] then
				partners[oldDef[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA)
			end
		end

		for i = 1, #formation do
			if partners[formation[i].partner_id] then
				partners[formation[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA)
			end
		end
	end
end

function Arena:getRank()
	return self.rank or 0
end

function Arena:getTopRank()
	return self.topRank or 0
end

function Arena:getScore()
	return self.score or 0
end

function Arena:getDDL()
	return self.ddl or 0
end

function Arena:getFreeTimes()
	return self.freeTimes or 0
end

function Arena:setFreeTimes(num)
	self.freeTimes = num
end

function Arena:getPower()
	return self.power or 0
end

function Arena:setDefFormation(partners, pet_id)
	local msg = messages_pb:set_partners_req()

	for _, v in pairs(partners) do
		local partner = messages_pb:fight_partner()
		partner.partner_id = v.partner_id
		partner.pos = v.pos

		table.insert(msg.partners, partner)
	end

	if pet_id then
		msg.pet_id = pet_id
	end

	xyd.Backend:get():request(xyd.mid.SET_PARTNERS, msg)
end

function Arena:checkDefFormation()
	local defFormation = self:getDefFormation()
	local msg = messages_pb:set_partners_req()

	for _, v in pairs(defFormation) do
		local partner = messages_pb:fight_partner()
		partner.partner_id = v.partner_id
		partner.pos = v.pos

		table.insert(msg.partners, partner)
	end

	if self.pet then
		msg.pet_id = self.pet
	end

	xyd.Backend:get():request(xyd.mid.SET_PARTNERS, msg)
end

function Arena:getDefFormation()
	return self.defFormation or {}
end

function Arena:getPet()
	return self.pet or 0
end

function Arena:reqRankList()
	local msg = messages_pb:get_rank_list_req()

	xyd.Backend:get():request(xyd.mid.GET_RANK_LIST, msg)
end

function Arena:onGetRankList(event)
	self.rankList = {}

	for _, info in ipairs(event.data.list) do
		table.insert(self.rankList, {
			score = info.score,
			player_name = info.player_name,
			avatar_id = info.avatar_id,
			avatar_frame_id = info.avatar_frame_id,
			lev = info.lev,
			player_id = info.player_id,
			power = info.power,
			is_robot = info.is_robot,
			server_id = info.server_id,
			is_online = info.is_online
		})
	end
end

function Arena:getRankList()
	return self.rankList
end

function Arena:reqEnemyList()
	if #self.enemyList < 6 then
		local msg = messages_pb.get_match_infos_req()

		xyd.Backend:get():request(xyd.mid.GET_MATCH_INFOS, msg)
	else
		__TS__ArraySplice(self.enemyList, 0, 3)

		local eventObj = {
			name = xyd.event.GET_MATCH_INFOS
		}

		xyd.EventDispatcher:inner():dispatchEvent(eventObj)
	end
end

function Arena:onGetEnemyList(event)
	local match_infos = event.data.match_infos
	local list = {}

	for i = 1, #match_infos do
		local info = match_infos[i]

		table.insert(list, {
			score = info.score,
			player_name = info.player_name,
			avatar_id = info.avatar_id,
			avatar_frame_id = info.avatar_frame_id,
			lev = info.lev,
			player_id = info.player_id,
			power = info.power,
			is_robot = info.is_robot,
			server_id = info.server_id,
			is_online = info.is_online
		})
	end

	self.enemyList = list
end

function Arena:getEnemyList()
	return __TS__ArraySlice(self.enemyList, 0, 3)
end

function Arena:reqRecord()
	local msg = messages_pb:arena_record_req()

	xyd.Backend:get():request(xyd.mid.ARENA_RECORD, msg)
end

function Arena:reqReport(id)
	local msg = messages_pb:arena_get_report_req()
	msg.record_id = id

	xyd.Backend:get():request(xyd.mid.ARENA_GET_REPORT, msg)
end

function Arena:reqEnemyInfo(player_id)
	local msg = messages_pb:arena_get_enemy_info_req()
	msg.other_player_id = player_id

	xyd.Backend:get():request(xyd.mid.ARENA_GET_ENEMY_INFO, msg)
end

function Arena:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "arena_skip_report",
		value = value
	})
end

function Arena:isSkipReport()
	return self.skipReport
end

function Arena:getLastOpponent()
	return self.last_player_id
end

function Arena:setLastOpponent(player_id)
	self.last_player_id = player_id
end

function Arena:onFight(event)
	xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.ARENA_TIMES, 1)
end

function Arena:getArenaNewRankList()
	local msg = messages_pb:get_arena_new_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_NEW_RANK_LIST, msg)
end

function Arena:onGetArenaNewRankListBack(event)
	local arenaNewSeasonServerRankWd = xyd.WindowManager.get():getWindow("arena_new_season_server_rank_window")

	if not arenaNewSeasonServerRankWd then
		xyd.WindowManager.get():openWindow("arena_new_season_server_rank_window", {
			infos = xyd.decodeProtoBuf(event.data).player_infos
		})
	end
end

function Arena:getArenaNewRankList()
	local msg = messages_pb:get_arena_new_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_NEW_RANK_LIST, msg)
end

function Arena:getIsLast()
	return self.is_last
end

function Arena:getIsOld()
	return self.is_old
end

function Arena:getStartTime()
	return self.start_time or 0
end

function Arena:getSlaveIds()
	return self.slave_ids
end

function Arena:getIsSettlementing()
	if self:getDDL() and self:getDDL() <= xyd.getServerTime() then
		return true
	end

	return false
end

function Arena:getNewSeasonOpenTime()
	return 3600
end

Arena.INSTANCE = nil

return Arena
