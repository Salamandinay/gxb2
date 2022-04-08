local BaseModel = import(".BaseModel")
local ArenaTeam = class("ArenaTeam", BaseModel)

function ArenaTeam:ctor()
	BaseModel.ctor(self)

	self.defFormation = {}
	self.defTeams = {}
	self.fightRecord = {}
	self.enemyList = {}
	self.rankList = {}
	self.skipReport = false
	self.tmpReports = {}
	self.tmpBattleIndex = 1
	self.invitations = {}
	self.applyList = {}
	self.inviteTeams = {}
end

function ArenaTeam:checkFunctionOpen()
	return xyd.checkFunctionOpen(xyd.FunctionID.ARENA_TEAM, true)
end

function ArenaTeam:checkOpen()
	local startTime = self:getStartTime() - xyd.getServerTime()

	return startTime < 0
end

function ArenaTeam:isCaptain()
	if self.teamInfo and xyd.Global.playerID == self.teamInfo.leader_id then
		return true
	end

	return false
end

function ArenaTeam:reqArenaInfo()
	local msg = messages_pb:get_arena_team_info_req()

	xyd.Backend:get():request(xyd.mid.GET_ARENA_TEAM_INFO, msg)
end

function ArenaTeam:onGetArenaInfo(event)
	local data = event.data
	self.teamInfo = data.team_info
	self.selfInfo = data.arena_info

	self:updateLock(data.arena_info.partners)
	self:updateFormation(data.arena_info.partners)

	self.ddl = data.end_time and function ()
		return data.end_time
	end or function ()
		return self.ddl
	end()
	self.startTime = data.start_time or 0

	if data.pet and tostring(data.pet) ~= "" then
		self.pet = data.pet.pet_id
	else
		self.pet = nil
	end

	self:updateTeamInfo(data.team_info)
	self:updateRedMark()
end

function ArenaTeam:updateTeamInfo(teamInfo)
	self.teamInfo = teamInfo

	self:updateRank(teamInfo and function ()
		return teamInfo.rank
	end or function ()
		return 0
	end())
	self:updateScore(teamInfo and function ()
		return teamInfo.score
	end or function ()
		return 0
	end())

	self.energy = teamInfo and function ()
		return teamInfo.energy
	end or function ()
		return 0
	end()
	self.energyTime = teamInfo and function ()
		return teamInfo.energy_time
	end or function ()
		return 0
	end()
	self.power = teamInfo and function ()
		return teamInfo.power
	end or function ()
		return 0
	end()
end

function ArenaTeam:onFight(event)
	local data = event.data
	self.energy = data.self_info.energy
	self.energyTime = data.self_info.energy_time
end

function ArenaTeam:updateRank(rank)
	self.rank = rank
end

function ArenaTeam:updateScore(score)
	self.score = score
end

function ArenaTeam:updateFormation(partners)
	if partners then
		self.defFormation = partners

		return
	end
end

function ArenaTeam:updateLock(defPartners)
	local partners = xyd.models.slot:getPartners()

	if defPartners then
		local oldDef = self.defFormation
		local j = 0

		while j < #oldDef do
			if partners[oldDef[j + 1].partner_id] then
				partners[oldDef[j + 1].partner_id]:setLock(0, xyd.PartnerFlag.TEAM_ARENA)
			end

			j = j + 1
		end

		local j = 1

		while j <= #defPartners do
			if partners[defPartners[j].partner_id] then
				partners[defPartners[j].partner_id]:setLock(1, xyd.PartnerFlag.TEAM_ARENA)
			end

			j = j + 1
		end
	end
end

function ArenaTeam:getTeamName()
	if self.teamInfo then
		return self.teamInfo.team_name
	else
		return ""
	end
end

function ArenaTeam:getRank()
	return self.rank or 0
end

function ArenaTeam:getScore()
	return self.score or 0
end

function ArenaTeam:getDDL()
	return self.ddl or 0
end

function ArenaTeam:getStartTime()
	return self.startTime or 0
end

function ArenaTeam:getEnergyTime()
	return self.energyTime or 0
end

function ArenaTeam:getEnergy()
	return self.energy or 0
end

function ArenaTeam:setEnergy(num)
	self.energy = num
end

function ArenaTeam:getPower()
	return self.power or 0
end

function ArenaTeam:getTeamId()
	return self.teamInfo and function ()
		return self.teamInfo.team_id
	end or function ()
		return 0
	end()
end

function ArenaTeam:getIsJoin()
	if not self.teamInfo or not self.teamInfo.is_join or self.teamInfo.is_join == false or self.teamInfo.is_join == 0 then
		return false
	end

	return true
end

function ArenaTeam:setDefFormation(partners)
	local msg = messages_pb:set_arena_team_partners_req()
	local msg_partner = msg.partners

	for k, v in pairs(partners) do
		table.insert(msg_partner, v)
	end

	xyd.Backend.get():request(xyd.mid.SET_ARENA_TEAM_PARTNERS, msg)
end

function ArenaTeam:onsetDefFormation(event)
	local data = event.data

	self:updateLock(data.partners)
	self:updateFormation(data.partners)

	if self.teamInfo and self.teamInfo.players then
		self:reqArenaInfo()
	end

	self:updateRedMark()
end

function ArenaTeam:getDefFormation()
	return self.defFormation or {}
end

function ArenaTeam:getPet()
	return self.pet or 0
end

function ArenaTeam:reqRankList()
	local msg = messages_pb:get_arena_team_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_TEAM_RANK_LIST, msg)
end

function ArenaTeam:onGetRankList(event)
	self.rankList = event.data.list
end

function ArenaTeam:getRankList()
	return self.rankList
end

function ArenaTeam:reqEnemyList()
	if #self.enemyList < 6 then
		local msg = messages_pb:get_arena_team_match_infos_req()

		xyd.Backend.get():request(xyd.mid.GET_ARENA_TEAM_MATCH_INFOS, msg)
	else
		for i = 1, 3 do
			table.remove(self.enemyList, 1)
		end

		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.GET_ARENA_TEAM_MATCH_INFOS
		})
	end
end

function ArenaTeam:onGetEnemyList(event)
	local data = event.data.match_infos
	self.enemyList = {}

	for k, v in ipairs(data) do
		table.insert(self.enemyList, v)
	end
end

function ArenaTeam:getEnemyList()
	return xyd.slice(self.enemyList, 1, 3)
end

function ArenaTeam:fight(enemyID)
	local msg = messages_pb:arena_team_fight_req()
	msg.enemy_id = enemyID

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_FIGHT, msg)
end

function ArenaTeam:reqRecord()
	local msg = messages_pb:get_arena_team_records_req()

	xyd.Backend.get():request(xyd.mid.GET_ARENA_TEAM_RECORDS, msg)
end

function ArenaTeam:reqReport(ids)
	local msg = messages_pb:get_arena_team_reports_req()
	local records = msg.record_ids

	for i = 1, #ids do
		table.insert(records, ids[i])
	end

	xyd.Backend.get():request(xyd.mid.GET_ARENA_TEAM_REPORTS, msg)
end

function ArenaTeam:getTmpReports()
	return self.tmpReports
end

function ArenaTeam:setTmpReports(data, index)
	self.tmpReports = data
	self.tmpBattleIndex = index or 1
end

function ArenaTeam:resetTmpReports(index)
	self.tmpReports = {}
	self.tmpBattleIndex = 1
	self.tempIndex = index
end

function ArenaTeam:getTempIndex()
	return self.tempIndex
end

function ArenaTeam:resetTempIndex()
	self.tempIndex = nil
end

function ArenaTeam:getNextReport()
	if self.tmpReports.battle_reports and self.tmpReports.battle_reports[function ()
		local ____TS_tmp = self.tmpBattleIndex + 1
		self.tmpBattleIndex = ____TS_tmp

		return ____TS_tmp
	end()] then
		return self.tmpReports.battle_reports[self.tmpBattleIndex]
	else
		return
	end
end

function ArenaTeam:getNowBattleIndex()
	return self.tmpBattleIndex
end

function ArenaTeam:isLastReport()
	if self.tmpReports.battle_reports and self.tmpBattleIndex == #self.tmpReports.battle_reports then
		return true
	end

	return false
end

function ArenaTeam:reqEnemyInfo(player_id)
	local msg = messages_pb:get_arena_team_other_team_info_req()
	msg.other_player_id = player_id

	xyd.Backend.get():request(xyd.mid.GET_ARENA_TEAM_OTHER_TEAM_INFO, msg)
end

function ArenaTeam:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "arena_team_skip_report",
		value = value
	})
end

function ArenaTeam:isSkipReport()
	if self.skipReport and self.skipReport ~= 0 then
		return true
	end

	return false
end

function ArenaTeam:onRegister()
	self:registerEvent(xyd.event.GET_ARENA_TEAM_INFO, self.onGetArenaInfo, self)
	self:registerEvent(xyd.event.SET_ARENA_TEAM_PARTNERS, self.onsetDefFormation, self)
	self:registerEvent(xyd.event.GET_ARENA_TEAM_MATCH_INFOS, self.onGetEnemyList, self)
	self:registerEvent(xyd.event.GET_ARENA_TEAM_RANK_LIST, self.onGetRankList, self)
	self:registerEvent(xyd.event.ARENA_TEAM_FIGHT, self.onFight, self)
	self:registerEvent(xyd.event.FUNCTION_OPEN, function (____, event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.ARENA_TEAM then
			self:reqRankList()
			self:reqArenaInfo()
		end
	end, self)
	self:registerEvent(xyd.event.ARENA_TEAM_CHANGE_TEAM, function (____, e)
		self:updateTeamInfo(e.data.team_info)
	end, self)
	self:registerEvent(xyd.event.ARENA_TEAM_CREATE_TEAM, self.onCreateTeam, self)
	self:registerEvent(xyd.event.ARENA_TEAM_APPLY_TEAM, self.onApplyTeam, self)
	self:registerEvent(xyd.event.ARENA_TEAM_ACCEPT, self.onAccept, self)
	self:registerEvent(xyd.event.ARENA_TEAM_QUIT, self.onQuit, self)
	self:registerEvent(xyd.event.ARENA_TEAM_REMOVE_MEMBER, self.onRemoveMember, self)
	self:registerEvent(xyd.event.ARENA_TEAM_DISSOLVE_TEAM, self.onDissolveTeam, self)
	self:registerEvent(xyd.event.ARENA_TEAM_JOIN_TEAM, self.onJoinTeam, self)
	self:registerEvent(xyd.event.ARENA_TEAM_CHANGE_TEAM, self.onChangeTeam, self)
	self:registerEvent(xyd.event.ARENA_TEAM_GET_RECOMMEND_TEAMS, self.onGetRecommendTeams, self)
	self:registerEvent(xyd.event.ARENA_TEAM_GET_INVITE_PLAYERS, self.onGetInvitePlayers, self)
	self:registerEvent(xyd.event.ARENA_TEAM_INVITE_MEMBER, self.onInviteMember, self)
	self:registerEvent(xyd.event.ARENA_TEAM_ACCEPT_INVITATION, self.onAcceptInvitation, self)
	self:registerEvent(xyd.event.ARENA_TEAM_GET_INVITE_TEAMS, self.onGetInviteTeams, self)
	self:registerEvent(xyd.event.ARENA_TEAM_GET_APPLY_LIST, self.onGetApplyList, self)
	self:registerEvent(xyd.event.ARENA_TEAM_REFUSE_APPLY, self.onRefuseApply, self)
	self:registerEvent(xyd.event.ARENA_TEAM_REFUSE_INVITATION, self.onRefuseInvitation, self)
	self:registerEvent(xyd.event.ARENA_TEAM_TRANSFER_LEADER, self.onChangeTeamLeader, self)
	self:registerEvent(xyd.event.SERVER_BROADCAST, self.onServerBroadCast, self)
end

function ArenaTeam:createTeam(teamName, needForce)
	local msg = messages_pb:arena_team_create_team_req()
	msg.team_name = teamName
	msg.need_power = needForce

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_CREATE_TEAM, msg)
end

function ArenaTeam:onCreateTeam(event)
	self:updateTeamInfo(event.data.team_info)
end

function ArenaTeam:applyTeam(teamId)
	local msg = messages_pb:arena_team_apply_team_req()
	msg.team_id = tonumber(teamId)

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_APPLY_TEAM, msg)
end

function ArenaTeam:onApplyTeam(event)
end

function ArenaTeam:accept(memberId)
	local msg = messages_pb:arena_team_accept_req()
	msg.member_id = memberId

	self:removeApplyByID(memberId)
	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_ACCEPT, msg)
end

function ArenaTeam:onAccept(event)
	self:updateTeamInfo(event.data.team_info)

	for k, v in ipairs(self.teamInfo.player_ids) do
		self:removeApplyByID(v)
	end
end

function ArenaTeam:quit()
	local msg = messages_pb:arena_team_quit_req()

	xyd.Backend:get():request(xyd.mid.ARENA_TEAM_QUIT, msg)
end

function ArenaTeam:onQuit(event)
	self.teamInfo = nil
end

function ArenaTeam:removeMember(memberId)
	local msg = messages_pb:arena_team_remove_member_req()
	msg.member_id = memberId

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_REMOVE_MEMBER, msg)
end

function ArenaTeam:onRemoveMember(event)
	self:updateTeamInfo(event.data.team_info)
end

function ArenaTeam:dissolveTeam()
	local msg = messages_pb:arena_team_dissolve_team_req()

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_DISSOLVE_TEAM, msg)
end

function ArenaTeam:onDissolveTeam(event)
	self.teamInfo = nil
end

function ArenaTeam:joinTeam()
	local msg = messages_pb:arena_team_join_team_req()

	xyd.Backend:get():request(xyd.mid.ARENA_TEAM_JOIN_TEAM, msg)
end

function ArenaTeam:onJoinTeam(event)
	self:updateTeamInfo(event.data.team_info)
end

function ArenaTeam:changeTeam(memberIds)
	local msg = messages_pb:arena_team_change_team_req()
	local ids = msg.member_ids

	for i = 1, #memberIds do
		table.insert(ids, memberIds[i])
	end

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_CHANGE_TEAM, msg)
end

function ArenaTeam:onChangeTeam(event)
	self:updateTeamInfo(event.data.team_info)
end

function ArenaTeam:getRecommendTeams()
	local msg = messages_pb:arena_team_get_recommend_teams_req()

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_GET_RECOMMEND_TEAMS, msg)
end

function ArenaTeam:onGetRecommendTeams(event)
end

function ArenaTeam:getInvitePlayers()
	local msg = messages_pb:arena_team_get_invite_players_req()

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_GET_INVITE_PLAYERS, msg)
end

function ArenaTeam:onGetInvitePlayers(event)
end

function ArenaTeam:inviteMember(memberID)
	local msg = messages_pb:arena_team_invite_member_req()
	msg.member_id = memberID

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_INVITE_MEMBER, msg)
end

function ArenaTeam:onInviteMember(event)
end

function ArenaTeam:acceptInvitation(teamID)
	local msg = messages_pb:arena_team_accept_invitation_req()
	msg.team_id = teamID

	self:removeInvitationByID(teamID)
	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_ACCEPT_INVITATION, msg)
end

function ArenaTeam:onAcceptInvitation(event)
	local teamInfo = event.data.team_info
	self.teamInfo = teamInfo

	self:removeInvitationByID(teamInfo.team_id)
end

function ArenaTeam:reqInviteTeams()
	local msg = messages_pb:arena_team_get_invite_teams_req()

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_GET_INVITE_TEAMS, msg)
end

function ArenaTeam:onGetInviteTeams(event)
	local tmp = event.data.team_infos or {}
	self.inviteTeams = {}

	for i = 1, #tmp do
		table.insert(self.inviteTeams, tmp[i])
	end
end

function ArenaTeam:getInviteTeams()
	return self.inviteTeams
end

function ArenaTeam:getMyTeamInfo()
	return self.teamInfo
end

function ArenaTeam:changeTeamLeader(memberID)
	local msg = messages_pb:arena_team_transfer_leader_req()
	msg.member_id = memberID

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_TRANSFER_LEADER, msg)
end

function ArenaTeam:onChangeTeamLeader(event)
	self:updateTeamInfo(event.data.team_info)
end

function ArenaTeam:reqApplyList()
	local msg = messages_pb:arena_team_get_apply_list_req()

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_GET_APPLY_LIST, msg)
end

function ArenaTeam:onGetApplyList(event)
	local tmp = event.data.apply_list or {}
	self.applyList = {}

	for i = 1, #tmp do
		table.insert(self.applyList, tmp[i])
	end

	self:updateRedMark()
end

function ArenaTeam:getApplyList()
	return self.applyList
end

function ArenaTeam:refuseApply(memberIds)
	if #memberIds <= 0 then
		return
	end

	local msg = messages_pb:arena_team_refuse_apply_req()
	local ids = msg.member_ids

	for i = 1, #memberIds do
		table.insert(ids, memberIds[i])
	end

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_REFUSE_APPLY, msg)
end

function ArenaTeam:onRefuseApply(event)
	local memberIds = event.data.member_ids

	for i = 1, #memberIds do
		self:removeApplyByID(memberIds[i])
	end
end

function ArenaTeam:removeApplyByID(id)
	for i = 1, #self.applyList do
		if self.applyList[i].player_id == id then
			table.remove(self.applyList, i)

			break
		end
	end
end

function ArenaTeam:refuseInvitation(teamIDs)
	if #teamIDs <= 0 then
		return
	end

	local msg = messages_pb:arena_team_refuse_invitation_req()
	local ids = msg.team_ids

	for i = 1, #teamIDs do
		table.insert(ids, teamIDs[i])
	end

	xyd.Backend.get():request(xyd.mid.ARENA_TEAM_REFUSE_INVITATION, msg)
end

function ArenaTeam:onRefuseInvitation(event)
	local teamIDs = event.data.team_ids

	for k, v in ipairs(teamIDs) do
		self:removeInvitationByID(v)
	end
end

function ArenaTeam:removeInvitationByID(id)
	for i = 1, #self.inviteTeams do
		if self.inviteTeams[i].team_id == id then
			table.remove(self.inviteTeams, i)

			break
		end
	end

	self:updateRedMark()
end

function ArenaTeam:updateRedMark()
	if self:checkFunctionOpen() and self:checkOpen() and #self:getDefFormation() <= 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_TEAM, true)
	elseif self:getApplyList() and #self:getApplyList() > 0 and not self:getIsJoin() and (not self:getTeamId() or self:getTeamId() <= 0) then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_TEAM, true)
	elseif self:getInviteTeams() and #self:getInviteTeams() > 0 and not self:getIsJoin() and (not self:getTeamId() or self:getTeamId() <= 0) then
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_TEAM, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.ARENA_TEAM, false)
	end
end

function ArenaTeam:onServerBroadCast(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local data = event.data
	local mid = data.mid

	if data.payload ~= nil then
		return
	end

	if mid == xyd.mid.ARENA_TEAM_INVITE_MEMBER then
		self:reqInviteTeams()
	elseif mid == xyd.mid.ARENA_TEAM_APPLY_TEAM then
		self:reqApplyList()
	elseif mid == xyd.mid.SET_ARENA_TEAM_PARTNERS then
		self:reqArenaInfo()
	else
		self:reqArenaInfo()
	end
end

function ArenaTeam:isShowServerId(id)
	local displayMarks = xyd.tables.miscTable:split2num("merge_server_now_next", "value", "|")
	local index = 1

	if displayMarks[3] < xyd.getServerTime() then
		index = 2
	end

	return displayMarks[index] < id
end

return ArenaTeam
