local ArenaAllServerNew = class("ArenaAllServerNew", import(".BaseModel"))
local MiscTable = xyd.tables.miscTable
local cjson = require("cjson")

function ArenaAllServerNew:ctor()
	ArenaAllServerNew.super.ctor(self)

	self.startTime = 0
	self.supportNums_ = {}
	self.betInfo_ = {}
	self.battleInfosList_ = {}
	self.battleRoundsList_ = {}
	self.reports_ = {}
	self.curReqReport_ = ""
	self.defFormation = {}
	self.firstTime_ = 0
	self.nextUpdateSelfInfoTime_ = 0
	self.nextUpdateBattleInfoTime_ = 0
	self.lastChangeTime = 0
	self.reqHistoryRecord = {}
end

function ArenaAllServerNew:onRegister()
	ArenaAllServerNew.super.onRegister(self)
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_SELF_INFO_NEW, handler(self, self.onGetArenaInfo))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO_NEW, handler(self, self.onGetArenaBattleInfo))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_BET_NEW, handler(self, self.onQuiz))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_CHANGE_BET_NEW, handler(self, self.onQuiz))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HALL_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HISTORY_RANK_NEW, handler(self, self.onGetRank))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_SET_TEAMS_NEW, handler(self, self.onSetTeams))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HALL_RANK_NEW, handler(self, self.onGetHallRank))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_RECORD_NEW2, handler(self, self.onGetReport))
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.ARENA_ALL_SERVER then
			self:reqSelfInfo()
		end
	end)
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_RED_INFO, handler(self, self.onGetRedInfo))
end

function ArenaAllServerNew:reqRedInfo()
	local msg = messages_pb.arena_all_server_get_red_info_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_RED_INFO, msg)
end

function ArenaAllServerNew:onGetRedInfo(event)
	self.is_select_ = event.data.is_select
	self.is_alive_ = event.data.is_alive
	self.start_time_ = event.data.start_time
end

function ArenaAllServerNew:getCurRound()
	if not self.selfInfo_ then
		return 0
	end

	return self.selfInfo_.round or 0
end

function ArenaAllServerNew:updateRedMark()
	if self:checkFunctionOpen() and self:checkOpen() and self:isSelect() and not self:isSetDefend() and (self:checkAlive(xyd.Global.playerID) or self:getCurRound() == 0) then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER, false)
	end
end

function ArenaAllServerNew:checkFunctionOpen()
	if xyd.checkFunctionOpen(xyd.FunctionID.ARENA_ALL_SERVER, true) then
		return true
	else
		return false
	end
end

function ArenaAllServerNew:getStartTime()
	return self.start_time_ or 0
end

function ArenaAllServerNew:isSelect()
	return xyd.checkCondition(self.is_select_ == 1, true, false)
end

function ArenaAllServerNew:checkOpen()
	local startTime = self:getStartTime() or 0

	if xyd.getServerTime() - startTime >= xyd.DAY_TIME * 20 and xyd.getServerTime() - startTime < xyd.DAY_TIME * 26 then
		return true
	end

	return false
end

function ArenaAllServerNew:getCurBattleType()
	local round = self:getCurRound()

	if round <= 3 then
		return xyd.ArenaAllServerBattleType.KNOCKOUT
	elseif round > 3 and round <= 6 then
		return xyd.ArenaAllServerBattleType.FINAL
	end

	return xyd.ArenaAllServerBattleType.NOT_OPEN
end

function ArenaAllServerNew:getFinalTimeGroup()
	local startTime = self:getStartTime()

	if xyd.getServerTime() - startTime >= 20 * xyd.DAY_TIME and xyd.getServerTime() - startTime < 23 * xyd.DAY_TIME then
		return 1
	elseif xyd.getServerTime() - startTime >= 23 * xyd.DAY_TIME and xyd.getServerTime() - startTime < 26 * xyd.DAY_TIME then
		return 2
	else
		return 0
	end
end

function ArenaAllServerNew:checkNeedUpdateInfo(nextTime)
	local flag = false
	local serverTime = xyd.getServerTime()

	if nextTime < serverTime then
		flag = true
	end

	return flag
end

function ArenaAllServerNew:reqSelfInfo()
	if not self:checkFunctionOpen() then
		return
	end

	if self.selfInfo_ and self:checkNeedUpdateInfo(self.nextUpdateSelfInfoTime_) == false then
		return
	end

	local msg = messages_pb.arena_all_server_get_self_info_new_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_SELF_INFO_NEW, msg)
end

function ArenaAllServerNew:onGetArenaInfo(event)
	self.selfInfo_ = xyd.decodeProtoBuf(event.data)

	self:updateFormation(self.selfInfo_.teams or {})

	self.betInfo_ = cjson.decode(event.data.bet_detail)
	self.supportNums_ = cjson.decode(event.data.support_nums)
	self.nextUpdateSelfInfoTime_ = xyd.getServerTime() + xyd.getUpdateTime()

	self:changeStringKey(self.betInfo_)

	self.zone_ = self.selfInfo_.zone
	self.zoneNum_ = self.selfInfo_.zone_num
	self.start_time_ = self.selfInfo_.start_time

	if not self.battleInfosList_[self.zone_] and xyd.getServerTime() - self:getStartTime() > 20 * xyd.DAY_TIME then
		self:reqBattleInfo(self.zone_)
	end
end

function ArenaAllServerNew:getZoneNum()
	return self.zoneNum_ or 1
end

function ArenaAllServerNew:updateFormation(teams)
	self:updateLock(teams)

	self.defFormation = teams
end

function ArenaAllServerNew:updateLock(teams)
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

		for i = 1, #oldDef2 do
			if partners[oldDef2[i].partner_id] then
				partners[oldDef2[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		for i = 1, #oldDef3 do
			if partners[oldDef3[i].partner_id] then
				partners[oldDef3[i].partner_id]:setLock(0, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		for i = 1, #formation do
			if partners[formation[i].partner_id] then
				partners[formation[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		for i = 1, #formation2 do
			if partners[formation2[i].partner_id] then
				partners[formation2[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
			end
		end

		for i = 1, #formation3 do
			if partners[formation3[i].partner_id] then
				partners[formation3[i].partner_id]:setLock(1, xyd.PartnerFlag.ARENA_SCORE)
			end
		end
	end
end

function ArenaAllServerNew:isSetDefend()
	local val = xyd.db.misc:getValue("arena_all_server_set_defend")

	if val and tonumber(val) == self:getCurMatchNum() then
		return true
	end

	return false
end

function ArenaAllServerNew:getCurMatchNum()
	local firstTime = xyd.tables.miscTable:getNumber("new_arena_all_server_time", "value")
	local serverTime = xyd.getServerTime()
	local onceTime = 28 * xyd.DAY_TIME
	local num = math.floor((serverTime - firstTime) / onceTime) + 1

	return num
end

function ArenaAllServerNew:getZoneID()
	return self.zone_ or 1
end

function ArenaAllServerNew:reqBattleInfo(zone_id)
	if not self:checkFunctionOpen() then
		return
	end

	zone_id = zone_id or self:getZoneID()

	if self.battleInfosList_[zone_id] and self:checkNeedUpdateInfo(self.nextUpdateBattleInfoTime_) == false then
		return
	end

	local msg = messages_pb.arena_all_server_get_all_battle_info_new_req()
	msg.zone = zone_id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO_NEW, msg)
end

function ArenaAllServerNew:onGetArenaBattleInfo(event)
	local zone_id = event.data.zone
	self.battleInfosList_[zone_id] = xyd.decodeProtoBuf(event.data)
	self.battleRoundsList_[zone_id] = cjson.decode(event.data.rounds)
	self.nextUpdateBattleInfoTime_ = xyd.getServerTime() + xyd.getUpdateTime()

	self:changeStringKey(self.battleRoundsList_[zone_id])
end

function ArenaAllServerNew:changeStringKey(tableArry)
	for i = 0, 10 do
		local item = tableArry[tostring(i)]

		if item and item ~= cjson.null then
			tableArry[i] = item
		end
	end
end

function ArenaAllServerNew:reqQuiz(playerID, zone_id)
	zone_id = zone_id or self:getZoneID()
	local round = self:getCurRound()
	local msg = messages_pb.arena_all_server_bet_new_req()
	msg.win_player_id = playerID
	msg.round = round
	msg.zone = zone_id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_BET_NEW, msg)
end

function ArenaAllServerNew:onQuiz(event)
	self.supportNums_ = cjson.decode(event.data.support_nums)
	self.betInfo_ = cjson.decode(event.data.bet_detail)

	self:changeStringKey(self.betInfo_)

	local curBetInfo = self:getCurRoundBetInfo()

	if curBetInfo then
		xyd.db.misc:setValue({
			key = "arena_all_server_quiz",
			value = cjson.encode({
				round = self:getCurRound(),
				win_player_id = curBetInfo.win_player_id
			})
		})
	end
end

function ArenaAllServerNew:reqChangeQuiz(playerID, zone_id)
	zone_id = zone_id or self:getZoneID()
	local round = self:getCurRound()
	local msg = messages_pb.arena_all_server_change_bet_new_req()
	msg.win_player_id = playerID
	msg.round = round
	msg.zone = zone_id
	self.lastChangeTime = xyd.getServerTime()

	xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_CHANGE_BET_NEW, msg)
end

function ArenaAllServerNew:getCurRoundBetInfo()
	local round = self:getCurRound()

	return self:getBetInfoByRound(round)
end

function ArenaAllServerNew:getBetInfoByRound(roundID)
	local info = self:getBetInfo()

	return info[roundID] or {}
end

function ArenaAllServerNew:getBetInfo()
	return self.betInfo_ or {}
end

function ArenaAllServerNew:getBattleInfo()
	return self.battleInfos_ or {}
end

function ArenaAllServerNew:reqGetAward(id)
	local msg = messages_pb.arena_all_server_get_hall_award_new_req()
	msg.id = id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HALL_AWARD_NEW, msg)
end

function ArenaAllServerNew:onGetAward(event)
end

function ArenaAllServerNew:onGetRank(event)
	local data = xyd.decodeProtoBuf(event.data)

	if not self.historyRank_ then
		self.historyRank_ = {}
	end

	local season = self.tempHead
	self.reqHistoryRecord[season] = true

	for index, value in ipairs(data.list) do
		if not self.historyRank_[index] then
			self.historyRank_[index] = {}
		end

		if not self.historyRank_[index].area_list then
			self.historyRank_[index].area_list = {}
		end

		local arenaListData = {}

		if value.area_list and value.area_list[1] then
			arenaListData = value.area_list[1]
		end

		self.historyRank_[index].area_list[season] = arenaListData
	end
end

function ArenaAllServerNew:onSetTeams(event)
	local data = xyd.decodeProtoBuf(event.data)

	self:updateFormation(data.teams or {})
	xyd.db.misc:setValue({
		key = "arena_all_server_set_defend",
		value = self:getCurMatchNum()
	})
	self:updateRedMark()
end

function ArenaAllServerNew:reqSetTeams(partnerParams, petIDs, levelID)
	local msg = messages_pb.arena_all_server_set_teams_new_req()

	if petIDs == nil then
		petIDs = {}
	end

	for _, id in ipairs(petIDs) do
		if id and tonumber(id) > 0 then
			table.insert(msg.pet_ids, tonumber(id))
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

	local subsitNum = xyd.tables.arenaAllServerRankTable:getSubsitNum(levelID)

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

	msg.zone = self:getZoneID()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_SET_TEAMS_NEW, msg)
end

function ArenaAllServerNew:reqGetHallRank()
	local msg = messages_pb.arena_all_server_get_hall_rank_new_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HALL_RANK_NEW, msg)
end

function ArenaAllServerNew:onGetHallRank(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.hallRank_ = data.list
end

function ArenaAllServerNew:reqGetHistoryRank(head, tail)
	if self.reqHistoryRecord[head] then
		return
	end

	local msg = messages_pb.arena_all_server_get_history_rank_new_req()

	if head then
		msg.head = head - 1
		self.tempHead = head
	end

	if tail then
		msg.tail = tail - 1
		self.tempTail = tail
	end

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HISTORY_RANK_NEW, msg)
end

function ArenaAllServerNew:hasReqHistory(season)
	return self.reqHistoryRecord[season]
end

function ArenaAllServerNew:getHistoryRank()
	return self.historyRank_ or {}
end

function ArenaAllServerNew:getSeasons()
	if not self.seasons_ then
		self.seasons_ = {}

		for i = 1, self:getMaxHistorySeason() do
			self.seasons_[i] = i
		end
	end

	return self.seasons_ or {}
end

function ArenaAllServerNew:getMaxHistorySeason()
	local firstTime = xyd.tables.miscTable:getNumber("new_arena_all_server_time", "value")
	local serverTime = xyd.getServerTime()
	local onceTime = 28 * xyd.DAY_TIME
	local xiusanTime = xyd.tables.miscTable:split2Cost("arena_all_server_schedule", "value", "|")[5] * xyd.DAY_TIME
	local num = math.floor((serverTime - firstTime) / onceTime)
	local leftTime = (serverTime - firstTime) % onceTime

	if leftTime > onceTime - xiusanTime then
		num = num + 1
	end

	return num
end

function ArenaAllServerNew:reqReport(ids)
	local curStr = ""
	local msg = messages_pb.arena_all_server_get_record_new2_req()

	for _, id in ipairs(ids) do
		curStr = tostring(curStr) .. tostring(id) .. "_"

		table.insert(msg.record_ids, id)
	end

	if self.reports_[curStr] then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.ARENA_ALL_SERVER_GET_RECORD_NEW2,
			data = self.reports_[curStr]
		})

		return
	end

	self.curReqReport_ = curStr

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_RECORD_NEW2, msg)
end

function ArenaAllServerNew:onGetReport(event)
	local data = xyd.decodeProtoBuf(event.data)
	local reports = data.reports
	self.reports_[self.curReqReport_] = {
		reports = {}
	}

	for i = 1, #reports do
		table.insert(self.reports_[self.curReqReport_].reports, reports[i])
	end
end

function ArenaAllServerNew:getHallRank()
	return self.hallRank_ or {}
end

function ArenaAllServerNew:reqEnemyInfo(player_id, zone_id)
	zone_id = zone_id or self:getZoneID()
	local msg = messages_pb.arena_all_server_get_enemy_info_new2_req()
	msg.other_player_id = player_id
	msg.zone = zone_id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_ENEMY_INFO_NEW2, msg)
end

function ArenaAllServerNew:getScoreID()
	if not self.selfInfo_ then
		return 0
	end

	return self.selfInfo_.score_id or 0
end

function ArenaAllServerNew:getPickPlayers()
	if not self.betInfo_ then
		return {}
	end

	return self.betInfo_.system_pick_players or {}
end

function ArenaAllServerNew:getBattleInfo(zone_id)
	zone_id = zone_id or self.zone_

	return self.battleInfosList_[zone_id] or {}
end

function ArenaAllServerNew:getRounds(zone_id)
	zone_id = zone_id or self.zone_

	return self.battleRoundsList_[zone_id] or {}
end

function ArenaAllServerNew:getBattlePlayerInfos(zone_id)
	local battleInfo = self:getBattleInfo(zone_id)

	return battleInfo.player_infos or {}
end

function ArenaAllServerNew:getBattlePlayerInfo(playerID, zone_id)
	zone_id = zone_id or self:getZoneID()
	local playerInfos = self:getBattlePlayerInfos(zone_id)
	local playerInfo = nil

	for _, info in ipairs(playerInfos) do
		if info.player_id == playerID then
			playerInfo = info

			break
		end
	end

	return playerInfo
end

function ArenaAllServerNew:getSupportNumByPlayerID(playerID)
	return self.supportNums_[tostring(playerID)] or 0
end

function ArenaAllServerNew:getPickSupportRate()
	local pickplayers = self:getPickPlayers()
	local nums = {}
	local total = 0

	for _, player in ipairs(pickplayers) do
		local playerID = player.player_id
		local num = self:getSupportNumByPlayerID(playerID)

		table.insert(nums, num)

		total = total + num
	end

	if total == 0 then
		total = 1
	end

	local rates = {
		(nums[1] or 0) / total,
		(nums[2] or 0) / total
	}

	return rates
end

function ArenaAllServerNew:getNextFightTime()
	return xyd.getUpdateTime()
end

function ArenaAllServerNew:isRestTime()
	if not self.selfInfo_ then
		return true
	end

	return self.selfInfo_.is_rest_time == 1
end

function ArenaAllServerNew:checkAlive(playerID, zone_id)
	zone_id = zone_id or self.zone_
	local curRound = self:getCurRound()
	local rounds = self:getRounds(zone_id)
	local roundInfo = rounds[curRound - 1]

	if roundInfo and roundInfo.win_ids then
		for _, id in ipairs(roundInfo.win_ids) do
			if id == playerID then
				return true
			end
		end
	end

	return false
end

function ArenaAllServerNew:getReportIds(round, winPlayerID, zone_id)
	zone_id = zone_id or self:getZoneID()
	local rounds = self:getRounds(zone_id)
	local curRoundInfo = rounds[round] or {}
	local winIDs = curRoundInfo.win_ids or {}
	local reportIDs = curRoundInfo.report_ids or {}
	local index = -1

	for i = 1, #winIDs do
		if winIDs[i] == winPlayerID then
			index = i

			break
		end
	end

	local data = {}

	if index ~= -1 then
		data = reportIDs[index]
	end

	return data
end

function ArenaAllServerNew:getTimeStr(index, isShowEndYear)
	local firstTime = self:getFirstTime()
	local onceTime = 1209600
	local oneWeek = 518400
	local startTime = firstTime + (index - 1) * onceTime
	local endTime = startTime + oneWeek
	local startTimeInfo = os.date("*t", startTime)
	local endTimeInfo = os.date("*t", endTime)
	local timeStr = tostring(startTimeInfo.year) .. "." .. tostring(startTimeInfo.month) .. "." .. tostring(startTimeInfo.day) .. " - "

	if isShowEndYear then
		timeStr = tostring(timeStr) .. tostring(endTimeInfo.year) .. "." .. tostring(endTimeInfo.month) .. "." .. tostring(endTimeInfo.day)
	else
		timeStr = tostring(timeStr) .. tostring(endTimeInfo.month) .. "." .. tostring(endTimeInfo.day)
	end

	return timeStr
end

function ArenaAllServerNew:getDefFormation()
	return self.defFormation or {}
end

function ArenaAllServerNew:getGroupFightRecords()
	if not self.selfInfo_ then
		return {}
	end

	return self.selfInfo_.group_fight_records or {}
end

function ArenaAllServerNew:getSelfFightRecords()
	local arry = {}
	local rounds = self:getRounds(self.zone_)
	local curRound = self:getCurRound()
	local selfPlayerID = xyd.Global.playerID

	if curRound > 1 then
		for roundNum = curRound - 1, 1, -1 do
			local roundInfo = rounds[roundNum]
			local reportIDs = roundInfo.report_ids or {}
			local winIDs = roundInfo.win_ids or {}
			local loseIDs = roundInfo.lose_ids or {}

			if winIDs and xyd.arrayIndexOf(winIDs, selfPlayerID) > -1 then
				local index = xyd.arrayIndexOf(winIDs, selfPlayerID)
				local tmpReportIDs = reportIDs[index]
				local lastRoundInfo = rounds[roundNum - 1]
				local losePlayerID = lastRoundInfo.win_ids[index * 2]

				if losePlayerID == selfPlayerID then
					losePlayerID = lastRoundInfo.win_ids[index * 2 - 1]
				end

				if losePlayerID and losePlayerID > 0 then
					local playerInfo = self:getBattlePlayerInfo(losePlayerID)
					playerInfo.round_text = roundNum
					playerInfo.is_win = 1
					playerInfo.record_ids = tmpReportIDs

					table.insert(arry, playerInfo)
				end
			elseif loseIDs and xyd.arrayIndexOf(loseIDs, selfPlayerID) > -1 then
				local lastRoundInfo = rounds[roundNum - 1]
				local lastWinIDs = lastRoundInfo.win_ids or {}
				local lastIndex = xyd.arrayIndexOf(lastWinIDs, selfPlayerID)
				local index = math.ceil(lastIndex / 2)
				local tmpReportIDs = reportIDs[index]
				local winPlayerID = winIDs[index]
				local playerInfo = self:getBattlePlayerInfo(winPlayerID)
				playerInfo.round_text = roundNum
				playerInfo.is_win = 0
				playerInfo.record_ids = tmpReportIDs

				table.insert(arry, playerInfo)
			end
		end
	end

	local groupFights = self:getGroupFightRecords()

	for i = 1, #groupFights do
		local info = groupFights[i]

		if i == 0 then
			info.round_text = 0
		end

		table.insert(arry, info)
	end

	return arry
end

function ArenaAllServerNew:checkChangeTime()
	local val = xyd.tables.miscTable:getNumber("arena_all_server_time", "value")
	local serverTime = xyd.getServerTime()
	local num = serverTime - self.lastChangeTime

	if val <= num then
		return true
	end

	xyd.showToast(__("ARENA_ALL_SERVER_QUIZ_LIMIT", val - num))

	return false
end

return ArenaAllServerNew
