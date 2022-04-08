local ArenaAllServerScore = class("ArenaAllServerScore", import(".BaseModel"))

function ArenaAllServerScore:ctor()
	ArenaAllServerScore.super.ctor(self)

	self.enemyList = {}
	self.rankList_ = {}
	self.selfRankList_ = {}
	self.defFormation = {}
	self.reqTimeList = {}
	self.skipReport = false
	self.tmpRankType = 0
	self.addRank = 0
	local flag = false
	self.tmpBattleIndex = 1

	if tonumber(xyd.db.misc:getValue("arena_as_score_skip_report")) == 1 then
		flag = true
	end

	self.skipReport = flag
end

function ArenaAllServerScore:onRegister()
	ArenaAllServerScore.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ARENA_ALL_SERVER_INFO, handler(self, self.onGetArenaInfo))
	self:registerEvent(xyd.event.SET_PARTNERS_ALL_SERVER, handler(self, self.onSetTeams))
	self:registerEvent(xyd.event.GET_RANK_ALL_SERVER_LIST, handler(self, self.onGetRankList))
	self:registerEvent(xyd.event.GET_MATCH_ALL_SEVER_INFOS, handler(self, self.onGetEnemyList))
	self:registerEvent(xyd.event.REFRESH_MATCH_INFOS, handler(self, self.onRefreshEnemyList))
	self:registerEvent(xyd.event.GET_ALL_SEVER_FIGHT, handler(self, self.onAreanAsFight))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_BATCH_AWARDS, handler(self, self.onGetMissionAwardBack))
end

function ArenaAllServerScore:onGetArenaInfo(event)
	self.info_ = xyd.decodeProtoBuf(event.data)

	self:updateFormation(self.info_.teams or {})
	self:checkMissionValue()
	xyd.db.misc:setValue({
		key = "arena_all_server_score_get_info_time",
		value = xyd.getServerTime()
	})
	self:updateDefendRed()
end

function ArenaAllServerScore:checkNoInfo()
	if not self.info_ or not self.info_.end_time then
		return true
	else
		return false
	end
end

function ArenaAllServerScore:getPower()
	if self.info_ then
		return self.info_.power
	else
		return 0
	end
end

function ArenaAllServerScore:getStartTime()
	if self.info_ then
		local startTime_ = self.info_.start_time

		return startTime_
	else
		return 0
	end
end

function ArenaAllServerScore:getRank()
	if self.info_ then
		return self.info_.rank
	else
		return 0
	end
end

function ArenaAllServerScore:getRankType()
	local score = self:getScore()
	local rank = self:getRank()

	return xyd.tables.arenaAllServerRankTable:getRankType(score, rank)
end

function ArenaAllServerScore:getRefreshTime()
	return self.info_.refresh_time
end

function ArenaAllServerScore:getCanRefreshNum()
	return self.info_.refresh
end

function ArenaAllServerScore:reqRankList(rankType)
	local msg = messages_pb.get_rank_all_server_list_req()
	msg.level = rankType or 0

	xyd.Backend.get():request(xyd.mid.GET_RANK_ALL_SERVER_LIST, msg)

	self.tmpRankType = rankType
	self.reqTimeList[rankType] = xyd.getServerTime()
end

function ArenaAllServerScore:getReqRankTime(rankType)
	return self.reqTimeList[rankType] or 0
end

function ArenaAllServerScore:onGetRankList(event)
	self.rankList_[self.tmpRankType] = event.data.list
	self.selfRankList_[self.tmpRankType] = event.data.rank
end

function ArenaAllServerScore:getRankList(rankType)
	return self.rankList_[rankType], self.selfRankList_[rankType]
end

function ArenaAllServerScore:getDefFormation()
	return self.defFormation or {}
end

function ArenaAllServerScore:getScore()
	if self.info_ then
		return self.info_.score
	else
		return 0
	end
end

function ArenaAllServerScore:getMissionCompletes()
	return self.info_.mission_completes
end

function ArenaAllServerScore:getMissionValues()
	return self.info_.mission_values
end

function ArenaAllServerScore:getAwards()
	return self.info_.awards
end

function ArenaAllServerScore:getRankLevel()
	local score = self:getScore()
	local rank = self:getRank()

	return xyd.tables.arenaAllServerRankTable:getRankLevel(score, rank)
end

function ArenaAllServerScore:getDDL()
	local startTime = self:getStartTime()

	return startTime + 19 * xyd.DAY_TIME
end

function ArenaAllServerScore:getOpenTime()
	local startTime = self:getStartTime()

	return startTime - 1 * xyd.DAY_TIME
end

function ArenaAllServerScore:isInOpentime()
	local serverTime = xyd.getServerTime()

	if self:getOpenTime() <= serverTime and serverTime <= self:getDDL() then
		return true
	else
		return false
	end
end

function ArenaAllServerScore:reqSetTeams(partnerParams, petIDs)
	local msg = messages_pb.set_partners_all_server_req()

	if petIDs == nil then
		petIDs = {}
	end

	local nowPetNum = 0
	local petNum = xyd.tables.arenaAllServerRankTable:getPetNum(self:getRankLevel())

	for _, id in ipairs(petIDs) do
		if id and tonumber(id) > 0 and nowPetNum < petNum then
			table.insert(msg.pet_ids, tonumber(id))

			nowPetNum = nowPetNum + 1
		end
	end

	for i = 1, 6 do
		local oneP = partnerParams[i]

		if oneP then
			local fight_partner = messages_pb.fight_partner()
			fight_partner.partner_id = oneP.partner_id
			fight_partner.pos = oneP.pos

			table.insert(msg.partners, fight_partner)
		end
	end

	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(self:getRankLevel())

	for i = 1, subsitNum * 6 do
		local posId = i + 6
		local oneP = partnerParams[posId]
		local index = math.fmod(posId, 6)

		if oneP then
			if index <= 2 and index > 0 then
				table.insert(msg.front_prs, oneP.partner_id)
			else
				table.insert(msg.back_prs, oneP.partner_id)
			end
		elseif index <= 2 and index > 0 then
			table.insert(msg.front_prs, 0)
		else
			table.insert(msg.back_prs, 0)
		end
	end

	xyd.Backend:get():request(xyd.mid.SET_PARTNERS_ALL_SERVER, msg)
end

function ArenaAllServerScore:checkDefFormation()
	local info = self:getDefFormation()
	local score = self:getScore()
	local rank = self:getRank()
	local teams = {}
	local found = false
	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(xyd.tables.arenaAllServerRankTable:getRankLevel(score, rank))
	local petNum = xyd.tables.arenaAllServerRankTable:getPetNum(xyd.tables.arenaAllServerRankTable:getRankLevel(score, rank))
	local msg = messages_pb.set_partners_all_server_req()
	local petIDs = info.pet_infos
	local petIndex = 0

	for _, petInfo in ipairs(petIDs) do
		if petInfo and tonumber(petInfo.pet_id) > 0 and petIndex < petNum then
			table.insert(msg.pet_ids, tonumber(petInfo.pet_id))

			petIndex = petIndex + 1
		end
	end

	for i = 1, 6 do
		local oneP = info.partners[i]

		if oneP then
			local fight_partner = messages_pb.fight_partner()
			fight_partner.partner_id = oneP.partner_id
			fight_partner.pos = oneP.pos

			table.insert(msg.partners, fight_partner)
		end
	end

	if info.front_infos and #info.front_infos > 0 then
		for index, oneP in ipairs(info.front_infos) do
			if index <= subsitNum * 2 then
				table.insert(msg.front_prs, oneP.partner_id)
			end
		end
	end

	if info.back_infos and #info.back_infos > 0 then
		for index, oneP in ipairs(info.back_infos) do
			if index <= subsitNum * 4 then
				table.insert(msg.back_prs, oneP.partner_id)
			end
		end
	end

	xyd.Backend.get():request(xyd.mid.SET_PARTNERS_ALL_SERVER, msg)
end

function ArenaAllServerScore:reqFight(partnerParams, petIDs, enemy_id, enemy_level, is_revenge)
	local msg = messages_pb.get_all_sever_fight_req()
	msg.enemy_id = enemy_id
	msg.table_id = enemy_level

	if petIDs == nil then
		petIDs = {}
	end

	if is_revenge == nil then
		is_revenge = 0
	end

	msg.is_revenge = is_revenge
	local nowPetNum = 0
	local rankLevel = enemy_level or self:getRankLevel()
	local petNum = xyd.tables.arenaAllServerRankTable:getPetNum(rankLevel)

	for _, id in ipairs(petIDs) do
		if id and tonumber(id) > 0 and nowPetNum < petNum then
			table.insert(msg.pet_ids, tonumber(id))

			nowPetNum = nowPetNum + 1
		end
	end

	for i = 1, 6 do
		local oneP = partnerParams[i]

		if oneP then
			local fight_partner = messages_pb.fight_partner()
			fight_partner.partner_id = oneP.partner_id
			fight_partner.pos = oneP.pos

			table.insert(msg.partners, fight_partner)
		end
	end

	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(enemy_level)

	for i = 1, subsitNum * 6 do
		local posId = i + 6
		local oneP = partnerParams[posId]
		local index = math.fmod(posId, 6)

		if oneP then
			if index <= 2 and index > 0 then
				table.insert(msg.front_prs, oneP.partner_id)
			else
				table.insert(msg.back_prs, oneP.partner_id)
			end
		elseif index <= 2 and index > 0 then
			table.insert(msg.front_prs, 0)
		else
			table.insert(msg.back_prs, 0)
		end
	end

	self.needGetList_ = true
	self.addRank = 0

	xyd.Backend:get():request(xyd.mid.GET_ALL_SEVER_FIGHT, msg)
end

function ArenaAllServerScore:onAreanAsFight(event)
	if event and event.data then
		if not event.data.is_win or tonumber(event.data.is_win) ~= -1 then
			for i in pairs(self:getMissionValues()) do
				if self:getAwards()[i] == 0 then
					local complete_num = xyd.tables.arenaAllServerMissionTable:getComplete(i)

					if self:getMissionValues()[i] < complete_num then
						local mission_type = xyd.tables.arenaAllServerMissionTable:getType(i)

						if mission_type == 1 then
							self:getMissionValues()[i] = self:getMissionValues()[i] + 1
						elseif mission_type == 2 and event.data.is_win == 1 then
							self:getMissionValues()[i] = self:getMissionValues()[i] + 1
						end

						if complete_num <= self:getMissionValues()[i] then
							self:getMissionValues()[i] = complete_num
							self:getMissionCompletes()[i] = 1
						end
					end
				end
			end

			self.info_.fight_times = self.info_.fight_times + 1
		end

		self:checkMissionValue()
	end
end

function ArenaAllServerScore:getFightCost()
	local fightCostList = xyd.tables.miscTable:split2Cost("arena_all_server_cost", "value", "|#")
	self.fightTimes = self.info_.fight_times + 1 or 1

	if self.fightTimes >= #fightCostList then
		self.fightTimes = #fightCostList
	end

	return fightCostList[self.fightTimes]
end

function ArenaAllServerScore:onSetTeams(event)
	self.info_.rank = event.data.rank
	self.info_.power = event.data.power
	self.info_.score = event.data.score

	if not self:getDefFormation().partners or #self:getDefFormation().partners <= 0 then
		self:reqRankList(self:getRankType())
	end

	self:updateFormation(event.data.teams or {})
	xyd.db.misc:setValue({
		key = "arena_all_server_set_defend",
		value = self:getRankLevel()
	})
	self:updateDefendRed()

	if not self.info_.mission_values then
		self:updateBaseInfo()
	end
end

function ArenaAllServerScore:updateFormation(teams)
	self:updateLock(teams)

	self.defFormation = teams
end

function ArenaAllServerScore:updateLock(teams)
	local partners = xyd.models.slot:getPartners()
	local numTime = xyd.getServerTime() - self:getStartTime()
	local formation = teams.partners or {}
	local formation2 = teams.front_infos or {}
	local formation3 = teams.back_infos or {}

	if formation and #formation > 0 and numTime > -xyd.DAY_TIME and numTime < 19 * xyd.DAY_TIME then
		local oldDef = self.defFormation.partners or {}
		local oldDef2 = self.defFormation.front_infos or {}
		local oldDef3 = self.defFormation.back_infos or {}

		for i = 1, #oldDef do
			if partners[oldDef[i].partner_id] then
				partners[oldDef[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		if oldDef2 then
			for i = 1, #oldDef2 do
				if partners[oldDef2[i].partner_id] then
					partners[oldDef2[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA_SCORE)
				end
			end
		end

		if oldDef3 then
			for i = 1, #oldDef3 do
				if partners[oldDef3[i].partner_id] then
					partners[oldDef3[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA_SCORE)
				end
			end
		end

		for i = 1, #formation do
			if partners[formation[i].partner_id] then
				partners[formation[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		if formation2 then
			for i = 1, #formation2 do
				if partners[formation2[i].partner_id] then
					partners[formation2[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
				end
			end
		end

		if formation3 then
			for i = 1, #formation3 do
				if partners[formation3[i].partner_id] then
					partners[formation3[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
				end
			end
		end
	end
end

function ArenaAllServerScore:reqEnemyList()
	if xyd.HOUR < xyd.getServerTime() - self:getRefreshTime() or self.needGetList_ then
		local msg = messages_pb:get_match_all_sever_infos_req()

		xyd.Backend.get():request(xyd.mid.GET_MATCH_ALL_SEVER_INFOS, msg)

		self.info_.refresh_time = xyd.getServerTime()
		self.needGetList_ = false

		return
	end

	if #self.enemyList < 6 then
		local msg = messages_pb:get_match_all_sever_infos_req()

		xyd.Backend.get():request(xyd.mid.GET_MATCH_ALL_SEVER_INFOS, msg)
	else
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.GET_MATCH_ALL_SEVER_INFOS
		})
	end
end

function ArenaAllServerScore:refreshEnemyList()
	local msg = messages_pb:get_match_all_sever_infos_req()

	xyd.Backend.get():request(xyd.mid.REFRESH_MATCH_INFOS, msg)
end

function ArenaAllServerScore:onGetEnemyList(event)
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
			is_online = info.is_online,
			rank = info.rank
		})
	end

	self.enemyList = list
end

function ArenaAllServerScore:onRefreshEnemyList(event)
	self.info_.refresh_time = xyd.getServerTime()
	self.info_.refresh = self.info_.refresh + 1
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
			is_online = info.is_online,
			rank = info.rank
		})
	end

	self.enemyList = list
end

function ArenaAllServerScore:removePlayerInEnemyList(enemyInfo)
	for index, info in ipairs(self.enemyList) do
		if info.player_id == enemyInfo.player_id then
			table.remove(self.enemyList, index)
		end
	end

	if #self.enemyList > 0 then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.GET_MATCH_ALL_SEVER_INFOS
		})
	else
		self:reqEnemyList()
	end
end

function ArenaAllServerScore:getEnemyList()
	return {
		self.enemyList[1],
		self.enemyList[2],
		self.enemyList[3]
	}
end

function ArenaAllServerScore:reqEnemyInfo(player_id)
	local msg = messages_pb:arena_all_server_get_enemy_info_new_req()
	msg.other_player_id = player_id

	xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_GET_ENEMY_INFO_NEW, msg)
end

function ArenaAllServerScore:checkMissionValue()
	if not self:isInOpentime() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, false)

		return
	end

	local arena_all_server_score_mission_time_show = xyd.db.misc:getValue("arena_all_server_score_mission_time_show")

	if not arena_all_server_score_mission_time_show or arena_all_server_score_mission_time_show and tonumber(arena_all_server_score_mission_time_show) < xyd.getServerTime() - xyd.DAY_TIME then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, true)

		return
	end

	if not self:getMissionValues() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, false)

		return
	else
		local isRed = false

		for i, value in pairs(self:getAwards()) do
			if value == 0 and self:getMissionValues()[i] == xyd.tables.arenaAllServerMissionTable:getComplete(i) then
				isRed = true

				break
			end
		end

		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, isRed)

		return
	end
end

xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_MISSION, false)

function ArenaAllServerScore:updateDefendRed()
	local redState = false
	local startTime = self:getStartTime()

	if not self:checkFunctionOpen() then
		return false
	end

	if xyd.getServerTime() < startTime - xyd.DAY_TIME or xyd.getServerTime() > startTime + 19 * xyd.DAY_TIME then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_DEFEND, false)

		return
	end

	if not self.defFormation or not self.defFormation.partners or #self.defFormation.partners <= 0 then
		redState = true
	else
		local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(self:getRankLevel())

		if not self.defFormation.front_infos or not #self.defFormation.back_infos then
			redState = true
		elseif #self.defFormation.front_infos + #self.defFormation.back_infos + #self.defFormation.partners < subsitNum * 6 + 6 then
			redState = true
		end
	end

	if self.defFormation and self.defFormation.partners and #self.defFormation.partners > 0 and self:getDDL() - xyd.getServerTime() < xyd.DAY_TIME * 3 and xyd.DAY_TIME < self:getDDL() - xyd.getServerTime() then
		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.ARENA_ALL_SERVER_SCORE_OVER, self:getDDL() - xyd.DAY_TIME)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER_SCORE_DEFEND, redState)
end

function ArenaAllServerScore:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "arena_as_score_skip_report",
		value = value
	})
end

function ArenaAllServerScore:isSkipReport()
	return self.skipReport
end

function ArenaAllServerScore:getTmpReports()
	return self.tmpReports
end

function ArenaAllServerScore:updateBaseInfo()
	if not self:checkFunctionOpen() then
		return
	end

	local msg = messages_pb.get_arena_all_server_info_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_ALL_SERVER_INFO, msg)
end

function ArenaAllServerScore:checkFunctionOpen()
	if xyd.checkFunctionOpen(xyd.FunctionID.ARENA_ALL_SERVER, true) then
		return true
	else
		return false
	end
end

function ArenaAllServerScore:setTmpReports(data)
	self.tmpReports = data
	self.recordIds = data.record_ids
end

function ArenaAllServerScore:resetTmpReports()
	self.tmpReports = {}
	self.recordIds = {}
	self.tmpBattleIndex = 1
end

function ArenaAllServerScore:getRecordId()
	return self.recordIds[self.tmpBattleIndex] or -1
end

function ArenaAllServerScore:updateRank(rank)
	self.addRank = self.info_.rank - rank
	self.info_.rank = rank
end

function ArenaAllServerScore:updateScore(score)
	self.info_.score = score
end

function ArenaAllServerScore:getNextReport()
	self.tmpBattleIndex = self.tmpBattleIndex + 1

	if self.tmpReports.battle_reports and self.tmpReports.battle_reports[self.tmpBattleIndex] then
		return self.tmpReports.battle_reports[self.tmpBattleIndex]
	else
		return nil
	end
end

function ArenaAllServerScore:isLastReport()
	if self.tmpReports.battle_reports and self.tmpBattleIndex == #self.tmpReports.battle_reports then
		return true
	end

	return false
end

function ArenaAllServerScore:checkInfoOtherDay()
	local getTime = xyd.db.misc:getValue("arena_all_server_score_get_info_time")

	if getTime and not xyd.isSameDay(getTime, xyd.getServerTime()) then
		self:updateBaseInfo()

		return true
	end

	return false
end

function ArenaAllServerScore:onGetMissionAwardBack(event)
	if event and event.data then
		local common_progress_award_window_wd = xyd.WindowManager.get():getWindow("common_progress_award_window")

		if common_progress_award_window_wd and common_progress_award_window_wd:getWndType() == xyd.CommonProgressAwardWindowType.ARENA_ALL_SERVER_SCORE_MISSION_WINDOW then
			for key, table_id in pairs(event.data.table_ids) do
				self:getAwards()[table_id] = 1

				common_progress_award_window_wd:updateItemState(table_id, 3)
			end
		end

		xyd.models.itemFloatModel:pushNewItems(event.data.items, nil)
		self:checkMissionValue()
	end
end

function ArenaAllServerScore:reqRecord()
	local msg = messages_pb:arena_all_server_record_req()

	xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_RECORD, msg)
end

function ArenaAllServerScore:reqReport(ids)
	local msg = messages_pb:arena_all_server_get_report_req()

	for _, id in ipairs(ids) do
		table.insert(msg.record_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_GET_REPORT, msg)
end

function ArenaAllServerScore:getBattleAddRank()
	return self.addRank
end

return ArenaAllServerScore
