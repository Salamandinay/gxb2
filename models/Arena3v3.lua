local BaseModel = import(".BaseModel")
local Arena3v3 = class("Arena3v3", BaseModel)
local Backpack = xyd.models.backpack
local RedMark = xyd.models.redMark
local Slot = xyd.models.slot
local FunctionTable = xyd.tables.functionTable

function Arena3v3:ctor()
	BaseModel.ctor(self)

	self.defFormation = {}
	self.defTeams = {}
	self.fightRecord = {}
	self.enemyList = {}
	self.rankList = {}
	self.skipReport = false
	self.tmpReports = {}
	self.tmpBattleIndex = 1
	local flag = false

	if tonumber(xyd.db.misc:getValue("arena_3v3_skip_report")) == 1 then
		flag = true
	end

	self.skipReport = flag
end

function Arena3v3:onRegister()
	print(xyd.event.SET_PARTNERS_3v3)
	self:registerEvent(xyd.event.GET_ARENA_3v3_INFO, self.onGetArenaInfo, self)
	self:registerEvent(xyd.event.SET_PARTNERS_3v3, self.onGetArenaInfo, self)
	self:registerEvent(xyd.event.GET_MATCH_3V3_INFOS, self.onGetEnemyList, self)
	self:registerEvent(xyd.event.GET_RANK_3V3_LIST, self.onGetRankList, self)
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (self, event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.ARENA_3v3 then
			self:reqRankList()
			self:reqArenaInfo()
		end
	end, self)
	self:registerEvent(xyd.event.GET_ARENA_3V3_NEW_RANK_LIST, handler(self, self.onGetArena3v3NewRankListBack))
end

function Arena3v3:updateRedMark()
	if self:checkFunctionOpen() and self:checkOpen() and #self:getDefFormation() <= 0 then
		RedMark:setMark(xyd.RedMarkType.ARENA_3v3, true)
	else
		RedMark:setMark(xyd.RedMarkType.ARENA_3v3, false)
	end
end

function Arena3v3:checkFunctionOpen()
	return xyd.checkFunctionOpen(xyd.FunctionID.ARENA_3v3, true)
end

function Arena3v3:checkOpen()
	local startTime = self:getStartTime() - xyd.getServerTime()

	return startTime < 0
end

function Arena3v3:reqArenaInfo()
	local msg = messages_pb:get_arena_3v3_info_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_3v3_INFO, msg)
end

function Arena3v3:onGetArenaInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "3v3=====================================================")
	self:updateLock(data.teams)
	self:updateFormation(data.teams)
	self:updateRank(data.rank)
	self:updateScore(data.score)

	if data.end_time then
		self.ddl = data.end_time
	end

	self.startTime = data.start_time or 0
	self.freeTimes = data.free_times
	self.power = data.power

	if data.is_old then
		self.is_old = data.is_old
	end

	if data.is_last then
		self.is_last = data.is_last
	end

	if data.slave_ids then
		self.slave_ids = data.slave_ids
	end

	self:updateRedMark()
end

function Arena3v3:updateFormation(teams)
	self.defFormation = {}
	teams = teams or {}

	for i = 1, #teams do
		for j = 1, #teams[i].partners do
			local index = (i - 1) * 6 + teams[i].partners[j].pos
			self.defFormation[index] = teams[i].partners[j]
		end
	end

	self.defTeams = teams
end

function Arena3v3:updateRank(rank)
	self.rank = rank
end

function Arena3v3:updateScore(score)
	self.score = score
end

function Arena3v3:getDefTeams()
	return self.defTeams or {}
end

function Arena3v3:updateLock(teams)
	teams = teams or {}
	local partners = Slot:getPartners()

	if teams and #teams > 0 then
		local oldDef = self.defTeams

		for i = 1, #oldDef do
			for j = 1, #oldDef[i].partners do
				if partners[oldDef[i].partners[j].partner_id] then
					partners[oldDef[i].partners[j].partner_id]:setLock(0, xyd.PartnerFlag.CHAMPION)
				end
			end
		end

		for i = 1, #teams do
			for j = 1, #teams[i].partners do
				if partners[teams[i].partners[j].partner_id] then
					partners[teams[i].partners[j].partner_id]:setLock(1, xyd.PartnerFlag.CHAMPION)
				end
			end
		end
	end
end

function Arena3v3:getRank()
	return self.rank or 0
end

function Arena3v3:getTopRank()
	return self.topRank or 0
end

function Arena3v3:getScore()
	return self.score or 0
end

function Arena3v3:getDDL()
	return self.ddl or 0
end

function Arena3v3:getStartTime()
	return self.startTime or 0
end

function Arena3v3:getIsLast()
	return self.is_last
end

function Arena3v3:getIsOld()
	return self.is_old
end

function Arena3v3:getSlaveIds()
	return self.slave_ids
end

function Arena3v3:getFreeTimes()
	return self.freeTimes or 0
end

function Arena3v3:setFreeTimes(num)
	self.freeTimes = num
end

function Arena3v3:getPower()
	return self.power or 0
end

function Arena3v3:setDefFormation(partners, petIDs)
	local msg = messages_pb:set_partners_3v3_req()

	if petIDs == nil then
		petIDs = {
			0,
			0,
			0,
			0
		}
	end

	for i = 1, 3 do
		local teamOne = messages_pb:set_partners_req()
		teamOne.pet_id = petIDs[i + 1]
		local tmpPartner = xyd.slice(partners, (i - 1) * 6 + 1, (i - 1) * 6 + 6)

		for j = 1, #tmpPartner do
			if tmpPartner[j] ~= nil then
				local fight_partner = messages_pb:fight_partner()
				fight_partner.partner_id = tmpPartner[j].partner_id
				fight_partner.pos = tmpPartner[j].pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	xyd.Backend.get():request(xyd.mid.SET_PARTNERS_3v3, msg)
end

function Arena3v3:checkDefFormation()
	local msg = messages_pb:set_partners_3v3_req()

	for i = 1, 3 do
		local teamOne = messages_pb:set_partners_req()

		if self.defTeams[i].pet and self.defTeams[i].pet.pet_id then
			teamOne.pet_id = self.defTeams[i].pet.pet_id
		else
			teamOne.pet_id = 0
		end

		for j = 1, #self.defTeams[i].partners do
			if self.defTeams[i].partners[j] ~= nil then
				local fight_partner = messages_pb:fight_partner()
				fight_partner.partner_id = self.defTeams[i].partners[j].partner_id
				fight_partner.pos = self.defTeams[i].partners[j].pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	xyd.Backend.get():request(xyd.mid.SET_PARTNERS_3v3, msg)
end

function Arena3v3:getDefFormation()
	return self.defFormation or {}
end

function Arena3v3:reqRankList()
	local msg = messages_pb:get_rank_3v3_list_req()

	xyd.Backend.get():request(xyd.mid.GET_RANK_3V3_LIST, msg)
end

function Arena3v3:onGetRankList(event)
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

function Arena3v3:getRankList()
	return self.rankList
end

function Arena3v3:reqEnemyList()
	if #self.enemyList < 6 then
		local msg = messages_pb:get_match_3v3_infos_req()

		xyd.Backend.get():request(xyd.mid.GET_MATCH_3V3_INFOS, msg)
	else
		self.enemyList = xyd.splice(self.enemyList, 1, 3)

		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.GET_MATCH_3V3_INFOS
		})
	end
end

function Arena3v3:onGetEnemyList(event)
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

function Arena3v3:getEnemyList()
	return xyd.slice(self.enemyList, 1, 3)
end

function Arena3v3:fight(enemyID, partners, petIDs, is_revenge, is_revenge_index)
	local msg = messages_pb:arena_3v3_fight_req()

	if petIDs == nil then
		petIDs = {
			0,
			0,
			0,
			0
		}
	end

	if is_revenge == nil then
		is_revenge = 0
	end

	for i = 1, 3 do
		local teamOne = messages_pb:set_partners_req()
		teamOne.pet_id = petIDs[i + 1]
		local tmpPartner = xyd.slice(partners, (i - 1) * 6 + 1, (i - 1) * 6 + 6)

		for j = 1, #tmpPartner do
			if tmpPartner[j] ~= nil then
				local fight_partner = messages_pb:fight_partner()
				fight_partner.partner_id = tmpPartner[j].partner_id
				fight_partner.pos = tmpPartner[j].pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	msg.enemy_id = enemyID
	msg.is_revenge = is_revenge

	if is_revenge_index then
		msg.index = is_revenge_index
	end

	xyd.Backend.get():request(xyd.mid.ARENA_3v3_FIGHT, msg)
end

function Arena3v3:reqRecord()
	local msg = messages_pb:arena_3v3_record_req()

	xyd.Backend.get():request(xyd.mid.ARENA_3v3_RECORD, msg)
end

function Arena3v3:reqReport(ids)
	local msg = messages_pb:arena_3v3_get_report_req()

	for _, id in ipairs(ids) do
		table.insert(msg.record_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.ARENA_3v3_GET_REPORT, msg)
end

function Arena3v3:getTmpReports()
	return self.tmpReports
end

function Arena3v3:setTmpReports(data)
	self.tmpReports = data
	self.recordIds = data.record_ids
end

function Arena3v3:resetTmpReports()
	self.tmpReports = {}
	self.recordIds = {}
	self.tmpBattleIndex = 1
end

function Arena3v3:getRecordId()
	return self.recordIds[self.tmpBattleIndex] or -1
end

function Arena3v3:getNextReport()
	self.tmpBattleIndex = self.tmpBattleIndex + 1

	if self.tmpReports.battle_reports and self.tmpReports.battle_reports[self.tmpBattleIndex] then
		return self.tmpReports.battle_reports[self.tmpBattleIndex]
	else
		return nil
	end
end

function Arena3v3:isLastReport()
	if self.tmpReports.battle_reports and self.tmpBattleIndex == #self.tmpReports.battle_reports then
		return true
	end

	return false
end

function Arena3v3:reqEnemyInfo(player_id)
	local msg = messages_pb:arena_3v3_get_enemy_info_req()
	msg.other_player_id = player_id

	xyd.Backend.get():request(xyd.mid.ARENA_3v3_GET_ENEMY_INFO, msg)
end

function Arena3v3:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "arena_3v3_skip_report",
		value = value
	})
end

function Arena3v3:isSkipReport()
	return self.skipReport
end

function Arena3v3:getArena3v3NewRankList()
	local msg = messages_pb:get_arena_3v3_new_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_3V3_NEW_RANK_LIST, msg)
end

function Arena3v3:onGetArena3v3NewRankListBack(event)
	local arenaNewSeasonServerRankWd = xyd.WindowManager.get():getWindow("arena_new_season_server_rank_window")

	if not arenaNewSeasonServerRankWd then
		local player_infos = xyd.decodeProtoBuf(event.data).player_infos
		player_infos = player_infos or {}

		xyd.WindowManager.get():openWindow("arena_new_season_server_rank_window", {
			type = "arena3v3",
			infos = player_infos,
			slaveIds = self:getSlaveIds()
		})
	end
end

return Arena3v3
