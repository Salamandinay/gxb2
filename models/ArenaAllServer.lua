local ArenaAllServer = class("ArenaAllServer", import(".BaseModel"))
local MiscTable = xyd.tables.miscTable
local cjson = require("cjson")

function ArenaAllServer:ctor()
	ArenaAllServer.super.ctor(self)

	self.startTime = 0
	self.supportNums_ = {}
	self.betInfo_ = {}
	self.battleRounds_ = {}
	self.reports_ = {}
	self.curReqReport_ = ""
	self.defFormation = {}
	self.firstTime_ = 0
	self.nextUpdateSelfInfoTime_ = 0
	self.nextUpdateBattleInfoTime_ = 0
	self.lastChangeTime = 0
end

function ArenaAllServer:onRegister()
	ArenaAllServer.super.onRegister(self)
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_SELF_INFO, handler(self, self.onGetArenaInfo))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO, handler(self, self.onGetArenaBattleInfo))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_BET, handler(self, self.onQuiz))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_CHANGE_BET, handler(self, self.onQuiz))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HALL_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HISTORY_RANK, handler(self, self.onGetRank))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_SET_TEAMS, handler(self, self.onSetTeams))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_HALL_RANK, handler(self, self.onGetHallRank))
	self:registerEvent(xyd.event.ARENA_ALL_SERVER_GET_RECORD, handler(self, self.onGetReport))
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.ARENA_ALL_SERVER then
			self:reqSelfInfo()
			self:reqBattleInfo()
		end
	end)
end

function ArenaAllServer:checkFunctionOpen()
	if xyd.checkFunctionOpen(xyd.FunctionID.ARENA_ALL_SERVER, true) and self:checkFirstOpen() then
		return true
	else
		return false
	end
end

function ArenaAllServer:getFirstTime()
	if not self.firstTime_ or self.firstTime_ <= 0 then
		local serverId = xyd.models.selfPlayer:getServerID()

		if serverId < 3 then
			self.firstTime_ = MiscTable:getNumber("first_all_server_arena_time", "value")
		else
			self.firstTime_ = MiscTable:getNumber("funopen_all_server_arena_time", "value")
		end
	end

	return self.firstTime_
end

function ArenaAllServer:checkOpen()
	local firstTime = self:getFirstTime()
	local serverTime = xyd.getServerTime()

	if serverTime < firstTime then
		return false
	end

	local oneWeek = 604800
	local duration = math.floor((serverTime - firstTime) / oneWeek)

	if duration % 2 == 1 then
		return false
	end

	return true
end

function ArenaAllServer:getCurMatchNum()
	local firstTime = self:getFirstTime()
	local serverTime = xyd.getServerTime()
	local onceTime = 1209600
	local num = math.floor((serverTime - firstTime) / onceTime) + 1

	return num
end

function ArenaAllServer:checkFirstOpen()
	local firstTime = self:getFirstTime()
	local serverTime = xyd.getServerTime()

	if serverTime < firstTime then
		return false
	end

	return true
end

function ArenaAllServer:checkNeedUpdateInfo(nextTime)
	local flag = false
	local serverTime = xyd.getServerTime()

	if nextTime < serverTime then
		flag = true
	end

	return flag
end

function ArenaAllServer:reqSelfInfo()
	if not self:checkFunctionOpen() then
		return
	end

	if self.selfInfo_ and self:checkNeedUpdateInfo(self.nextUpdateSelfInfoTime_) == false then
		return
	end

	local msg = messages_pb.arena_all_server_get_self_info_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_SELF_INFO, msg)
end

function ArenaAllServer:reqBattleInfo()
	if not self:checkFunctionOpen() then
		return
	end

	if self.battleInfos_ and self:checkNeedUpdateInfo(self.nextUpdateBattleInfoTime_) == false then
		return
	end

	local msg = messages_pb.arena_all_server_get_all_battle_info_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_ALL_BATTLE_INFO, msg)
end

function ArenaAllServer:onGetArenaInfo(event)
	self.selfInfo_ = event.data

	self:updateFormation(self.selfInfo_.teams or {})

	self.betInfo_ = cjson.decode(event.data.bet_detail)
	self.supportNums_ = cjson.decode(event.data.support_nums)
	self.nextUpdateSelfInfoTime_ = xyd.getServerTime() + xyd.getUpdateTime()

	self:changeStringKey(self.betInfo_)

	local msg = messages_pb.get_arena_all_server_info_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_ALL_SERVER_INFO, msg)
end

function ArenaAllServer:getDefTeams()
	return self.selfInfo_.teams or {}
end

function ArenaAllServer:updateFormation(teams)
	self.defFormation = {}
	self.allServerTeamList_ = {}

	for i = 1, #teams do
		for j = 1, #teams[i].partners do
			local index = (i - 1) * 6 + teams[i].partners[j].pos
			self.defFormation[index] = teams[i].partners[j]
		end
	end

	self:checkFormationTeam()
end

function ArenaAllServer:checkFormationTeam()
	for i = 1, 18 do
		local partner_id = self.defFormation[i]
		local partner = xyd.models.slot:getPartner(tonumber(partner_id))

		if partner and tonumber(partner_id) > 0 then
			local partnerInfo = partner:getInfo()

			if not self:checkOrigin(partnerInfo) then
				self.defFormation[i] = nil
			end
		end
	end

	for i = 1, 18 do
		local partner_id = self.defFormation[i]
		local partner = xyd.models.slot:getPartner(tonumber(partner_id))

		if partner and tonumber(partner_id) > 0 and not self:checkAllServerBattleLimitByTouch(i, partner_id) then
			self.defFormation[i] = nil
		end
	end
end

function ArenaAllServer:checkOrigin(partnerInfo)
	local table_id = partnerInfo:getTableID()
	local localTabel = xyd.tables.partnerTable

	if localTabel:getStar10(table_id) > 0 or localTabel:getStar(table_id) == 10 or localTabel:getTenId(table_id) > 0 then
		return true
	else
		return false
	end
end

function ArenaAllServer:checkAllServerBattleLimitByTouch(posId, tableID)
	if self.battleType ~= xyd.BattleType.ARENA_ALL_SERVER_DEF then
		return true
	end

	local firstTableID = xyd.tables.partnerTable:getHeroList(tableID)[1] or 0
	local teamID = math.ceil(posId / 6)

	if self:checkAllServerBattleLimit(teamID, firstTableID) then
		return false
	end

	self:changeAllServerTeamListVal(teamID, firstTableID, 1)

	return true
end

function ArenaAllServer:changeAllServerTeamListVal(teamID, firstTableID, val)
	self.allServerTeamList_[teamID] = self.allServerTeamList_[teamID] or {}
	self.allServerTeamList_[teamID][firstTableID] = (self.allServerTeamList_[teamID][firstTableID] or 0) + val
end

function ArenaAllServer:onGetArenaBattleInfo(event)
	self.battleInfos_ = event.data
	self.battleRounds_ = cjson.decode(event.data.rounds)
	self.nextUpdateBattleInfoTime_ = xyd.getServerTime() + xyd.getUpdateTime()

	self:changeStringKey(self.battleRounds_)
end

function ArenaAllServer:changeStringKey(tableArry)
	for i = 0, 10 do
		local item = tableArry[tostring(i)]

		if item and item ~= cjson.null then
			tableArry[i] = item
		end
	end
end

function ArenaAllServer:reqQuiz(playerID)
	local round = self:getCurRound()
	local msg = messages_pb.arena_all_server_bet_req()
	msg.win_player_id = playerID
	msg.round = round

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_BET, msg)
end

function ArenaAllServer:onQuiz(event)
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

function ArenaAllServer:reqChangeQuiz(playerID)
	local round = self:getCurRound()
	local msg = messages_pb.arena_all_server_change_bet_req()
	msg.win_player_id = playerID
	msg.round = round
	self.lastChangeTime = xyd.getServerTime()

	xyd.Backend.get():request(xyd.mid.ARENA_ALL_SERVER_CHANGE_BET, msg)
end

function ArenaAllServer:reqGetAward(id)
	local msg = messages_pb.arena_all_server_get_hall_award_req()
	msg.id = id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HALL_AWARD, msg)
end

function ArenaAllServer:onGetAward(event)
end

function ArenaAllServer:reqGetHistoryRank()
	local msg = messages_pb.arena_all_server_get_history_rank_new_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HISTORY_RANK_NEW, msg)
end

function ArenaAllServer:onGetRank(event)
	self.historyRank_ = event.data.list
end

function ArenaAllServer:onSetTeams(event)
	self:updateFormation(event.data.teams or {})
	xyd.db.misc:setValue({
		key = "arena_all_server_set_defend",
		value = self:getCurMatchNum()
	})
	self:updateRedMark()
end

function ArenaAllServer:reqSetTeams(partners, petIDs)
	local msg = messages_pb.arena_all_server_set_teams_req()

	if petIDs == nil then
		petIDs = {
			0,
			0,
			0,
			0
		}
	end

	local teams = {}

	for i = 1, 3 do
		local teamOne = messages_pb.set_partners_req()
		teamOne.pet_id = petIDs[i + 1]

		for j = 1, 6 do
			local oneP = partners[(i - 1) * 6 + j]

			if oneP then
				local fight_partner = messages_pb.fight_partner()
				fight_partner.partner_id = oneP.partner_id
				fight_partner.pos = oneP.pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_SET_TEAMS, msg)
end

function ArenaAllServer:reqGetHallRank()
	local msg = messages_pb.arena_all_server_get_hall_rank_new_req()

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_HALL_RANK_NEW, msg)
end

function ArenaAllServer:onGetHallRank(event)
	self.hallRank_ = event.data.list
end

function ArenaAllServer:reqReport(ids)
	local curStr = ""
	local msg = messages_pb.arena_all_server_get_record_req()

	for _, id in ipairs(ids) do
		curStr = tostring(curStr) .. tostring(id) .. "_"

		table.insert(msg.record_ids, id)
	end

	if self.reports_[curStr] then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.ARENA_ALL_SERVER_GET_RECORD,
			data = self.reports_[curStr]
		})

		return
	end

	self.curReqReport_ = curStr

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_RECORD, msg)
end

function ArenaAllServer:onGetReport(event)
	local reports = event.data.reports
	self.reports_[self.curReqReport_] = {
		reports = {}
	}

	for i = 1, #reports do
		table.insert(self.reports_[self.curReqReport_].reports, reports[i])
	end
end

function ArenaAllServer:getHallRank()
	return self.hallRank_ or {}
end

function ArenaAllServer:getHistoryRank()
	return self.historyRank_ or {}
end

function ArenaAllServer:getStartTime()
	local firstTime = self:getFirstTime()
	local serverTime = xyd.getServerTime()
	local onceTime = 1209600
	local num = math.floor((serverTime - firstTime) / onceTime) + 1

	return firstTime + num * onceTime
end

function ArenaAllServer:reqEnemyInfo(player_id)
	local msg = messages_pb.arena_all_server_get_enemy_info_req()
	msg.other_player_id = player_id

	xyd.Backend:get():request(xyd.mid.ARENA_ALL_SERVER_GET_ENEMY_INFO, msg)
end

function ArenaAllServer:getScoreID()
	if not self.selfInfo_ then
		return 0
	end

	return self.selfInfo_.score_id or 0
end

function ArenaAllServer:getCurRound()
	if not self.selfInfo_ then
		return 0
	end

	return self.selfInfo_.round or 0
end

function ArenaAllServer:getPickPlayers()
	if not self.betInfo_ then
		return {}
	end

	return self.betInfo_.system_pick_players or {}
end

function ArenaAllServer:getBetInfo()
	return self.betInfo_ or {}
end

function ArenaAllServer:getCurRoundBetInfo()
	local round = self:getCurRound()

	return self:getBetInfoByRound(round)
end

function ArenaAllServer:getBetInfoByRound(roundID)
	local info = self:getBetInfo()

	return info[roundID] or {}
end

function ArenaAllServer:getBattleInfo()
	return self.battleInfos_ or {}
end

function ArenaAllServer:getRounds()
	return self.battleRounds_ or {}
end

function ArenaAllServer:getBattlePlayerInfos()
	local battleInfo = self:getBattleInfo()

	return battleInfo.player_infos or {}
end

function ArenaAllServer:getBattlePlayerInfo(playerID)
	local playerInfos = self:getBattlePlayerInfos()
	local playerInfo = nil

	for _, info in ipairs(playerInfos) do
		if info.player_id == playerID then
			playerInfo = info

			break
		end
	end

	return playerInfo
end

function ArenaAllServer:getSupportNumByPlayerID(playerID)
	return self.supportNums_[tostring(playerID)] or 0
end

function ArenaAllServer:getPickSupportRate()
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

function ArenaAllServer:getCurBattleType()
	local round = self:getCurRound()

	if round <= 3 then
		return xyd.ArenaAllServerBattleType.KNOCKOUT
	elseif round > 3 and round <= 6 then
		return xyd.ArenaAllServerBattleType.FINAL
	end

	return xyd.ArenaAllServerBattleType.NOT_OPEN
end

function ArenaAllServer:getNextFightTime()
	return xyd.getUpdateTime()
end

function ArenaAllServer:isRestTime()
	if not self.selfInfo_ then
		return true
	end

	return self.selfInfo_.is_rest_time == 1
end

function ArenaAllServer:checkAlive(playerID)
	local curRound = self:getCurRound()
	local rounds = self:getRounds()
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

function ArenaAllServer:getReportIds(round, winPlayerID)
	local rounds = self:getRounds()
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

function ArenaAllServer:getTimeStr(index, isShowEndYear)
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

function ArenaAllServer:getDefFormation()
	return self.defFormation or {}
end

function ArenaAllServer:isSelect()
	if not self.selfInfo_ then
		return false
	end

	return self.selfInfo_.is_select == 1
end

function ArenaAllServer:isSetDefend()
	local val = xyd.db.misc:getValue("arena_all_server_set_defend")

	if val and tonumber(val) == self:getCurMatchNum() then
		return true
	end

	return false
end

function ArenaAllServer:updateRedMark()
	if self:checkFunctionOpen() and self:checkOpen() and self:isSelect() and self:isSetDefend() == false and (self:checkAlive(xyd.Global.playerID) or self:getCurRound() == 0) then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_ALL_SERVER, false)
	end
end

function ArenaAllServer:getGroupFightRecords()
	if not self.selfInfo_ then
		return {}
	end

	return self.selfInfo_.group_fight_records or {}
end

function ArenaAllServer:getSelfFightRecords()
	local arry = {}
	local rounds = self:getRounds()
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
					losePlayerID = lastRoundInfo.win_ids[index * 2 + 1]
				end

				if losePlayerID and losePlayerID > 0 then
					local playerInfo = xyd.decodeProtoBuf(self:getBattlePlayerInfo(losePlayerID))
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
				local playerInfo = xyd.decodeProtoBuf(self:getBattlePlayerInfo(winPlayerID))
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

function ArenaAllServer:checkChangeTime()
	local val = xyd.tables.miscTable:getNumber("arena_all_server_time", "value")
	local serverTime = xyd.getServerTime()
	local num = serverTime - self.lastChangeTime

	if val <= num then
		return true
	end

	xyd.showToast(__("ARENA_ALL_SERVER_QUIZ_LIMIT", val - num))

	return false
end

return ArenaAllServer
