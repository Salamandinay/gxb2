local BaseModel = import(".BaseModel")
local GuildWar = class("GuildWar", BaseModel)

function GuildWar:ctor()
	GuildWar.super.ctor(self)

	self.matchCD_ = 0
	self.matchDirtyFlag_ = false
end

function GuildWar:getMatchDirtyFlag()
	return self.matchDirtyFlag_
end

function GuildWar:getMatchCD()
	return self.matchCD_
end

function GuildWar:SetMatchDirtyFlag(flag)
	self.matchDirtyFlag_ = flag
end

function GuildWar:setMatchCD(time)
	self.matchCD_ = time
end

function GuildWar:onRegister()
	GuildWar.super.onRegister(self)
	self:registerEvent(xyd.event.GUILD_WAR_GET_INFO, self.onGetGuildWarInfo, self)
	self:registerEvent(xyd.event.GUILD_WAR_JOIN, self.onJoin, self)
	self:registerEvent(xyd.event.GUILD_WAR_FIGHT, self.onFight, self)
	self:registerEvent(xyd.event.GUILD_WAR_MATCH, handler(self, self.onMatch))
	self:registerEvent(xyd.event.GUILD_WAR_SAVE_TEAMS, self.onSaveTeams, self)
	self:registerEvent(xyd.event.GUILD_WAR_GET_FINAL_INFO, self.onGetFinalInfo, self)
	self:registerEvent(xyd.event.GUILD_WAR_SET_PARTNERS, self.onsetDefFormation, self)
end

function GuildWar:Join()
	local msg = messages_pb.guild_war_join_req()

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_JOIN, msg)
end

function GuildWar:onSaveTeams(event)
	local data = event.data

	for i = 1, #self.info_.member_ids do
		table.remove(self.info_.member_ids)
	end

	for i = 1, #self.info_.hide_ids do
		table.remove(self.info_.hide_ids)
	end

	for _, id in ipairs(data.member_ids) do
		table.insert(self.info_.member_ids, id)
	end

	for _, id in ipairs(data.hide_ids) do
		table.insert(self.info_.hide_ids, id)
	end
end

function GuildWar:onMatch(event)
	self.matchInfo_ = event.data
	self.matchDirtyFlag_ = true
end

function GuildWar:onJoin(e)
	local data = e.data
	self.info_.is_signed = 1
	self.info_.rank = data.rank
	self.info_.score = data.score
	xyd.models.guild.guild_battle_id = xyd.models.guild.guildID

	self:updateRank(self.info_.rank)
	self:updateScore(self.info_.score)
end

function GuildWar:reqGuildWarInfo()
	local msg = messages_pb.guild_war_get_info_req()

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_GET_INFO, msg)
end

function GuildWar:onGetGuildWarInfo(event)
	local data = event.data
	local saveData = {
		is_signed = data.is_signed,
		energy = data.energy,
		rank = data.rank,
		member_ids = data.member_ids,
		score = data.score,
		hide_ids = data.hide_ids,
		week_start_time = data.week_start_time,
		fight_times = data.fight_times,
		match_info = data.match_info
	}
	local tempTeams = {}

	for _, teamInfo in ipairs(data.all_teams) do
		local params = {
			avatar_id = teamInfo.avatar_id,
			lev = teamInfo.lev,
			player_name = teamInfo.player_name,
			player_id = teamInfo.player_id,
			partners = teamInfo.partners,
			power = teamInfo.power,
			pet = teamInfo.pet or nil,
			avatar_frame_id = teamInfo.avatar_frame_id,
			signature = teamInfo.signature
		}

		table.insert(tempTeams, params)
	end

	saveData.all_teams = tempTeams
	self.info_ = saveData

	self:setEnergy(self.info_.energy)
	self:updateRank(self.info_.rank)
	self:updateScore(self.info_.score)

	if self.info_.match_info then
		self.matchInfo_ = self.info_.match_info
	end

	if xyd.models.guild.guildID > 0 then
		self.defFormation = xyd.models.guild.self_info.partners
	end
end

function GuildWar:updateRank(rank)
	if rank >= 0 then
		self.rank = rank
	end
end

function GuildWar:updateScore(score)
	self.score = score
end

function GuildWar:onFight(event)
	local data = event.data
	self.energy = data.energy

	self:updateScore(data.score)
	self:updateRank(data.rank)

	self.matchInfo_ = nil
end

function GuildWar:getRank()
	return self.rank or 0
end

function GuildWar:getScore()
	return self.score or 0
end

function GuildWar:getDDL()
	return self.ddl or 0
end

function GuildWar:getEnergyTime()
	return self.energyTime or 0
end

function GuildWar:getEnergy()
	return self.energy or 0
end

function GuildWar:setEnergy(num)
	self.energy = num
end

function GuildWar:getTeamId()
	if self.info_ then
		return self.info_.match_id
	else
		return 0
	end
end

function GuildWar:getIsSigned()
	if self.info_ then
		return self.info_.is_signed
	else
		return false
	end
end

function GuildWar:setDefFormation(partners, petID, team_index)
	local msg = messages_pb.guild_war_set_partners_req()

	if team_index then
		msg.formation_id = team_index
	else
		for _, partner in ipairs(partners) do
			local item = messages_pb.fight_partner()
			item.partner_id = partner.partner_id
			item.pos = partner.pos

			table.insert(msg.partners, item)
		end
	end

	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_SET_PARTNERS, msg)
end

function GuildWar:onsetDefFormation(event)
	local data = event.data
	local teams = self.info_.all_teams
	local flag = false

	for _, team in ipairs(teams) do
		if team.player_id == xyd.models.selfPlayer:getPlayerID() then
			while team.partners and #team.partners > 0 do
				table.remove(team.partners)
			end

			for _, partnerid in ipairs(data.partners) do
				table.insert(team.partners, partnerid)
			end

			team.power = data.power
			team.pet = data.pet
			flag = true

			break
		end
	end

	if not flag then
		local selfPlayer = xyd.models.selfPlayer
		local item = {
			avatar_id = selfPlayer:getAvatarID(),
			lev = selfPlayer:getLevel(),
			player_name = selfPlayer:getPlayerName(),
			player_id = selfPlayer:getPlayerID(),
			partners = data.partners,
			avatar_frame_id = selfPlayer:getAvatarFrameID(),
			power = data.power,
			pet = data.pet
		}

		table.insert(teams, item)
	end

	self.deFormation = data.partners

	while teams.partners and #teams.partners > 0 do
		table.remove(xyd.models.guild.self_info.partners)
	end

	for _, partnerid in ipairs(data.partners) do
		table.insert(xyd.models.guild.self_info.partners, partnerid)
	end

	xyd.models.guild:updateGuildWarRedMark()
end

function GuildWar:getDefFormation()
	return self.defFormation or {}
end

function GuildWar:setTeamFormation(member_ids, hide_ids)
	local msg = messages_pb.guild_war_save_teams_req()

	for _, id in ipairs(member_ids) do
		table.insert(msg.member_ids, id)
	end

	for _, id in ipairs(hide_ids) do
		table.insert(msg.hide_ids, id)
	end

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_SAVE_TEAMS, msg)
end

function GuildWar:fight()
	local msg = messages_pb.guild_war_fight_req()

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_FIGHT, msg)
end

function GuildWar:reqRecordDetail(record_ids)
	local msg = messages_pb.guild_war_get_record_detail_req()

	for _, id in ipairs(record_ids) do
		table.insert(msg.record_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_GET_RECORD_DETAIL, msg)
end

function GuildWar:reqRecord()
	local msg = messages_pb.guild_war_get_records_req()

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_GET_RECORDS, msg)
end

function GuildWar:reqReport(id)
	local msg = messages_pb.guild_war_get_report_req()
	msg.record_id = id

	xyd.Backend.get():request(xyd.mid.GUILD_WAR_GET_REPORT, msg)
end

function GuildWar:getTmpReports()
	return self.tmpReports
end

function GuildWar:setTmpReports(data)
	self.tmpReports = data
end

function GuildWar:getNowBattleIndex()
	return self.tmpBattleIndex
end

function GuildWar:isLastReport()
	if self.tmpReports.battle_reports and self.tmpBattleIndex == self.tmpReports.battle_reports.length - 1 then
		return true
	end

	return false
end

function GuildWar:reqEnemyInfo()
	local msg = messages_pb.guild_war_match_req()

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_MATCH, msg)

	self.matchDirtyFlag_ = false
end

function GuildWar:setSkipReport(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "arena_team_skip_report",
		value = value
	})
end

function GuildWar:reqRankList()
	local msg = messages_pb.guild_war_get_rank_list_req()

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_GET_RANK_LIST, msg)
end

function GuildWar:judgeMoment()
	local tmpStr = xyd.tables.miscTable:getVal("guild_war_time_interval")
	local nowTime = xyd.getServerTime()
	local timeIntervals = xyd.split(tmpStr, "|", true)
	local startTime = nil

	if self.info_ then
		startTime = self.info_.week_start_time or xyd.getGMTWeekStartTime(nowTime)
	else
		startTime = xyd.getGMTWeekStartTime(nowTime)
	end

	local timePass = nowTime - startTime

	for i = 1, #timeIntervals do
		if timePass < timeIntervals[i] then
			return i - 1
		end
	end

	return -1
end

function GuildWar:reqFinalInfo()
	local msg = messages_pb.guild_war_get_final_info_req()

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_GET_FINAL_INFO, msg)
end

function GuildWar:onGetFinalInfo(e)
	local data = e.data
	local rounds = require("cjson").decode(data.rounds)
	local guilds = {}

	for i = 1, #data.guild_infos do
		guilds[data.guild_infos[i].guild_id] = data.guild_infos[i]
	end

	self.finalInfo_ = {
		rounds = rounds,
		guilds = guilds
	}
end

function GuildWar:reqFinalRecord(round, index)
	local msg = messages_pb.guild_war_get_final_record_req()
	msg.round = round
	msg.battle_index = index

	xyd.Backend:get():request(xyd.mid.GUILD_WAR_GET_FINAL_RECORD, msg)
end

function GuildWar:getInfo()
	return self.info_
end

function GuildWar:getMatchInfo()
	return self.matchInfo_
end

function GuildWar:getFinalInfo()
	return self.finalInfo_
end

function GuildWar:getmatchDirtyFlag()
	return self.matchDirtyFlag_
end

GuildWar.VS = {
	16,
	15,
	14,
	13,
	12,
	11,
	10,
	9
}
GuildWar.MOMENT = {
	FINAL = 2,
	BEFORE_FINAL = 1,
	AFTER_FINAL = 3,
	RANK_MATCH = 0
}

return GuildWar
