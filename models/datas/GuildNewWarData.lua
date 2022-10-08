local ActivityData = import("app.models.ActivityData")
local cjson = require("cjson")
local GuildNewWarData = class("GuildNewWarData", ActivityData, true)

function GuildNewWarData:ctor(params)
	ActivityData.ctor(self, params)

	self.enemyFormationData = {}
	self.showInfoByBattleID = {}
	self.allPlayerDefFormation = {}
	self.tmpBattleIndex = 1
	self.skipReport = false
	self.tmpReports = {}
	self.memberPowerList = {}
	local flag = false

	if tonumber(xyd.db.misc:getValue("guild_new_war_skip_report")) == 1 then
		flag = true
	end

	self.skipReport = flag
end

function GuildNewWarData:getUpdateTime()
	return self:getEndTime()
end

function GuildNewWarData:register()
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_INFO, self.onGetBaseInfo, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_SIGN_IN, self.onGetSignIn, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_FLAG_INFO, self.onGetFlagInfo, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_FIGHT, self.onGetFight, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_GUILD_RANK_LIST, self.onGetGuildRankList, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_PERSON_RANK, self.onGetPersonRankList, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_LOG, self.onGetGuildLogList, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_MESSAGE, self.onGetMessageInfoList, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_BATCH_SET_FLAG, self.onGetBatchSetFlag, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_RALLY, self.onGetRally, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_SWEEP, self.onGetSweep, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_SET_TEAMS, self.onGetSetDefFormation, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_OTHER, self.onGetOtherDefFormation, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_GET_GUILD_MEMBER_POWER, self.onGuildMemberDefFormationPower, self)
	self:registerEvent(xyd.event.GUILD_NEW_WAR_MESSAGE_PUSH_BACK, self.onGuildNewWarMessagePushBack, self)
end

function GuildNewWarData:onAward(data)
end

function GuildNewWarData:getBeginTime()
	return self.start_time
end

function GuildNewWarData:getCurSeason()
	if self.baseInfo and self.baseInfo.self_info.count then
		return self.baseInfo.self_info.count
	else
		return 0
	end
end

function GuildNewWarData:getNodeType(nodeIndex)
	local index = nodeIndex

	if index > 6 then
		index = index - 6
	end

	if index == 1 then
		return xyd.GuildNewWarNodeType.LEFT_FRONT
	elseif index == 2 then
		return xyd.GuildNewWarNodeType.RIGHT_FRONT
	elseif index == 3 then
		return xyd.GuildNewWarNodeType.LEFT_MID
	elseif index == 4 then
		return xyd.GuildNewWarNodeType.MID
	elseif index == 5 then
		return xyd.GuildNewWarNodeType.RIGHT_MID
	elseif index == 6 then
		return xyd.GuildNewWarNodeType.MAIN
	end
end

function GuildNewWarData:getCurPeriod()
	local nowTime = xyd.getServerTime()
	local beginTime = self:getBeginTime()
	local firstWeekBeginTime = xyd.getGMTWeekStartTime(beginTime) + 7 * xyd.DAY_TIME
	local timePass = nowTime - firstWeekBeginTime
	local timePass2 = timePass % (7 * xyd.DAY_TIME)
	local curPeriod = nil
	local disEndTime = self:getEndTime()

	if beginTime <= nowTime and nowTime < firstWeekBeginTime then
		curPeriod = xyd.GuildNewWarPeroid.BEGIN_RELAX
		disEndTime = firstWeekBeginTime
	elseif timePass >= 28 * xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.END_RELAX
		disEndTime = self:getEndTime()
	elseif timePass2 >= 0 and timePass2 < 3600 and timePass > 3600 then
		curPeriod = xyd.GuildNewWarPeroid.CALCULATION
		disEndTime = xyd.getTomorrowTime() - 82800
	elseif timePass2 >= 0 and timePass2 < xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.NORMAL_RELAX
		disEndTime = xyd.getTomorrowTime()
	elseif xyd.DAY_TIME <= timePass2 and timePass2 < xyd.DAY_TIME + 3600 then
		curPeriod = xyd.GuildNewWarPeroid.ATTACHING1
		disEndTime = xyd.getTomorrowTime() - 82800
	elseif timePass2 >= xyd.DAY_TIME + 3600 and timePass2 < 2 * xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.READY1
		disEndTime = xyd.getTomorrowTime()
	elseif timePass2 >= 2 * xyd.DAY_TIME and timePass2 < 4 * xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.FIGHTING1

		if timePass2 < 3 * xyd.DAY_TIME then
			disEndTime = xyd.getTomorrowTime() + xyd.DAY_TIME
		else
			disEndTime = xyd.getTomorrowTime()
		end
	elseif timePass2 >= 4 * xyd.DAY_TIME and timePass2 < 4 * xyd.DAY_TIME + 3600 then
		curPeriod = xyd.GuildNewWarPeroid.ATTACHING2
		disEndTime = xyd.getTomorrowTime() - 82800
	elseif timePass2 >= 4 * xyd.DAY_TIME + 3600 and timePass2 < 5 * xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.READY2
		disEndTime = xyd.getTomorrowTime()
	elseif timePass2 >= 5 * xyd.DAY_TIME and timePass2 < 7 * xyd.DAY_TIME then
		curPeriod = xyd.GuildNewWarPeroid.FIGHTING2

		if timePass2 < 6 * xyd.DAY_TIME then
			disEndTime = xyd.getTomorrowTime() + xyd.DAY_TIME
		else
			disEndTime = xyd.getTomorrowTime()
		end
	end

	dump(curPeriod)

	return curPeriod, disEndTime
end

function GuildNewWarData:getBeginRelaxDay()
	return 3
end

function GuildNewWarData:getEndRelaxDay()
	return 4
end

function GuildNewWarData:getNormalRelaxDay()
	return 1
end

function GuildNewWarData:getReadyTimeDay()
	return 1
end

function GuildNewWarData:getFightingTimeDay()
	return 2
end

function GuildNewWarData:reqBaseInfo(callback)
	if not self.baseInfo or not self.reqBaseTimeStamp or xyd.getServerTime() - self.reqBaseTimeStamp > 60 then
		self.reqBaseTimeStamp = xyd.getServerTime()
		self.reqMainInfoCallBack = callback
		local msg = messages_pb:guild_new_war_get_info_req()

		xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_INFO, msg)
	else
		callback()
	end
end

function GuildNewWarData:onGetBaseInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.baseInfo = data

	if self.reqMainInfoCallBack then
		self.reqMainInfoCallBack()
	end
end

function GuildNewWarData:checkNeedAndCanSignIn(callback)
	local need = true
	local can = false
	local curPeriod = self:getCurPeriod()

	if self.baseInfo and self.baseInfo.is_signed and self.baseInfo.is_signed == 1 then
		if curPeriod == xyd.GuildNewWarPeroid.ATTACHING1 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS01"))
		elseif curPeriod == xyd.GuildNewWarPeroid.CALCULATION or curPeriod == xyd.GuildNewWarPeroid.ATTACHING2 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS02"))
		else
			need = false
		end

		callback(need, can)
	else
		if curPeriod == xyd.GuildNewWarPeroid.ATTACHING1 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS01"))
		elseif curPeriod == xyd.GuildNewWarPeroid.CALCULATION or curPeriod == xyd.GuildNewWarPeroid.ATTACHING2 then
			xyd.alertTips(__("GUILD_NEW_WAR_TIPS02"))
		else
			can = self:canJoinGuildNewWar()
		end

		if can then
			self:reqSignIn(callback)
		else
			callback(need, can)
		end
	end
end

function GuildNewWarData:reqSignIn(callback)
	self.reqSignInCallBack = callback
	local msg = messages_pb:guild_new_war_sign_in_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_SIGN_IN, msg)
end

function GuildNewWarData:onGetSignIn(event)
	self.baseInfo.is_signed = 1

	if self.reqSignInCallBack then
		self.reqSignInCallBack(true, true)
	end
end

function GuildNewWarData:reqFlagInfo(callback)
	self.reqFlagInfoCallBack = callback
	local msg = messages_pb:guild_new_war_get_flag_info_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_FLAG_INFO, msg)
end

function GuildNewWarData:onGetFlagInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.mapInfo = {}
	self.playerIDToFlagInfoArr = {}

	for key, flagInfo in pairs(data.flag_infos) do
		local nodeID = flagInfo.base_id
		local flagID = flagInfo.flag_id

		if flagInfo.player_info and flagInfo.player_info.player_id and flagInfo.player_info.player_id > 0 then
			self.playerIDToFlagInfoArr[flagInfo.player_info.player_id] = {
				nodeID = nodeID,
				flagID = flagID,
				playerInfo = flagInfo.player_info,
				braveHP = flagInfo.courage,
				HP = flagInfo.durable,
				playerID = flagInfo.id
			}
		end

		if not self.mapInfo[nodeID] then
			local nodeType = self:getNodeType(nodeID)
			self.mapInfo[nodeID] = {
				maxFlagNum = 0,
				limitMemberNum = 0,
				curMemberNum = 0,
				curFlagNum = 0,
				flagInfos = {}
			}
		end

		self.mapInfo[nodeID].flagInfos[flagID] = {
			id = flagID,
			braveHP = flagInfo.courage,
			HP = flagInfo.durable,
			playerID = flagInfo.id,
			playerInfo = flagInfo.player_info
		}
		self.mapInfo[nodeID].limitMemberNum = self.mapInfo[nodeID].limitMemberNum + 1
		self.mapInfo[nodeID].maxFlagNum = self.mapInfo[nodeID].maxFlagNum + 1

		if flagInfo.courage > 0 and flagInfo.player_info and flagInfo.player_info.player_id then
			self.mapInfo[nodeID].curMemberNum = self.mapInfo[nodeID].curMemberNum + 1
		end

		if flagInfo.durable > 0 then
			self.mapInfo[nodeID].curFlagNum = self.mapInfo[nodeID].curFlagNum + 1
		end
	end

	for key, flagInfo in pairs(data.other_info) do
		local nodeID = flagInfo.base_id + 6
		local flagID = flagInfo.flag_id

		if not self.mapInfo[nodeID] then
			local nodeType = self:getNodeType(nodeID)
			self.mapInfo[nodeID] = {
				maxFlagNum = 0,
				limitMemberNum = 0,
				curMemberNum = 0,
				curFlagNum = 0,
				flagInfos = {}
			}
		end

		self.mapInfo[nodeID].flagInfos[flagID] = {
			id = flagID,
			braveHP = flagInfo.courage,
			HP = flagInfo.durable,
			playerID = flagInfo.id,
			playerInfo = flagInfo.player_info
		}
		self.mapInfo[nodeID].limitMemberNum = self.mapInfo[nodeID].limitMemberNum + 1
		self.mapInfo[nodeID].maxFlagNum = self.mapInfo[nodeID].maxFlagNum + 1

		if flagInfo.courage > 0 and flagInfo.player_info and flagInfo.player_info.player_id then
			self.mapInfo[nodeID].curMemberNum = self.mapInfo[nodeID].curMemberNum + 1
		end

		if flagInfo.durable > 0 then
			self.mapInfo[nodeID].curFlagNum = self.mapInfo[nodeID].curFlagNum + 1
		end
	end

	if self.reqFlagInfoCallBack then
		self.reqFlagInfoCallBack()
	end
end

function GuildNewWarData:reqFight(nodeID, flagID, is_revenge, is_revenge_index, callback, isDestroyFight)
	self.reqFightCallBack = callback

	if is_revenge == nil then
		is_revenge = 0
	end

	local msg = messages_pb:guild_new_war_fight_req()
	local teams = self:getPvPBattleFormation().teams

	for i = 1, 3 do
		local teamOne = messages_pb:set_partners_req()
		local petID = 0

		if teams[i].pet and (teams[i].pet.pet_id or teams[i].pet.petID) then
			petID = teams[i].pet.pet_id or teams[i].pet.petID
		end

		teamOne.pet_id = petID
		local tmpPartner = teams[i].partners

		for j = 1, 6 do
			if tmpPartner[j] ~= nil then
				local partnerID = tmpPartner[j].partner_id or tmpPartner[j].partnerID
				local partner = xyd.models.slot:getPartner(partnerID)

				if partner then
					local fight_partner = messages_pb:fight_partner()
					fight_partner.partner_id = tmpPartner[j].partner_id or tmpPartner[j].partnerID
					fight_partner.pos = j

					table.insert(teamOne.partners, fight_partner)
				end
			end
		end

		table.insert(msg.teams, teamOne)
	end

	self.tempRecordNodeID = nodeID
	self.tempRecordFlagID = flagID

	if nodeID > 6 then
		nodeID = nodeID - 6
	end

	msg.enemy_id = 0
	msg.is_revenge = is_revenge
	msg.base_id = nodeID
	msg.flag_id = flagID

	if is_revenge_index then
		msg.index = is_revenge_index
	end

	self.isDestroyFight = isDestroyFight

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_FIGHT, msg)
end

function GuildNewWarData:reqMultyFight(nodeID, flagID, num)
	self.leftFightTime = num
	local callback = nil

	function callback()
		self.leftFightTime = self.leftFightTime - 1
		local nowBraveHP = self.mapInfo[self.tempRecordNodeID].flagInfos[self.tempRecordFlagID].braveHP

		if self.leftFightTime > 0 and nowBraveHP > 0 then
			XYDCo.WaitForTime(0.3, function ()
				self:reqFight(nodeID, flagID, nil, , callback)
			end, "guild_new_war_multyFight")
		end
	end

	self:reqFight(nodeID, flagID, nil, , callback)
end

function GuildNewWarData:onGetFight(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.baseInfo.self_info.ticket = self.baseInfo.self_info.ticket - 1
	self.tempAddSelfScore = data.self_score - self.baseInfo.self_info.score
	self.baseInfo.self_info.score = data.self_score

	if data.add then
		self.baseInfo.self_guild.score = self.baseInfo.self_guild.score + data.add
	end

	if data.battle_reports and data.battle_reports[#data.battle_reports] then
		local winTime = 0
		local lostTime = 0

		for i = 1, #data.battle_reports do
			if data.battle_reports[i].isWin == 1 then
				winTime = winTime + 1
			else
				lostTime = lostTime + 1
			end
		end

		local reduceBraveHP = xyd.tables.miscTable:split2num("guild_new_war_courage_reduce", "value", "|")[winTime + 1]
		local nowBraveHP = self.mapInfo[self.tempRecordNodeID].flagInfos[self.tempRecordFlagID].braveHP - reduceBraveHP
		self.mapInfo[self.tempRecordNodeID].flagInfos[self.tempRecordFlagID].braveHP = math.max(0, nowBraveHP)

		if reduceBraveHP > 0 and self.mapInfo[self.tempRecordNodeID].flagInfos[self.tempRecordFlagID].braveHP <= 0 then
			local wnd = xyd.getWindow("guild_new_war_fight_window")

			if wnd then
				xyd.closeWindow("guild_new_war_fight_window")
			end
		end

		local battleID = data.battle_reports[#data.battle_reports].info.battle_id
		local nodeType = self:getNodeType(self.tempRecordNodeID)
		local awards = xyd.tables.guildNewWarBaseTable:getAttackLoseAwards(nodeType)

		if lostTime <= winTime then
			awards = xyd.tables.guildNewWarBaseTable:getAttackWinAwards(nodeType)
		end

		self.showInfoByBattleID[battleID] = {
			awards = awards,
			selfPoint = self.tempAddSelfScore or 0,
			enemyPoint = reduceBraveHP or 0,
			winTime = winTime,
			lostTime = lostTime
		}
	end

	self:updateMapInfo()

	if self.reqFightCallBack then
		self.reqFightCallBack()
	end

	local isGuildAddScore = false

	if data.add and data.add > 0 then
		isGuildAddScore = true
	end

	self:battleBackDealRankInfo(isGuildAddScore)
end

function GuildNewWarData:reqGuildRankList(callback)
	self.reqRankListCallBack = callback
	local msg = messages_pb:guild_new_war_get_guild_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_GUILD_RANK_LIST, msg)
end

function GuildNewWarData:onGetGuildRankList(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.guildRankList = data

	if self.reqRankListCallBack then
		self.reqRankListCallBack(data)
	end

	self.baseInfo.rank = self.guildRankList.rank
end

function GuildNewWarData:reqPersonRankList(callback)
	self.reqPersonRankListCallBack = callback
	local msg = messages_pb:guild_new_war_get_person_rank_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_PERSON_RANK, msg)
end

function GuildNewWarData:onGetPersonRankList(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.personRankList = data

	if not self.personRankList.list then
		self.personRankList.list = {}
	end

	if self.reqPersonRankListCallBack then
		self.reqPersonRankListCallBack(data)
	end

	if self.personRankList and self.personRankList.list and #self.personRankList.list > 0 then
		for i, info in pairs(self.personRankList.list) do
			if info.player_id == xyd.models.selfPlayer:getPlayerID() then
				self.baseInfo.self_info.rank = i

				break
			end
		end
	end
end

function GuildNewWarData:reqGuildLogList(callback)
	self.reqGuildLogListCallBack = callback
	local msg = messages_pb:guild_new_war_get_log_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_LOG, msg)
end

function GuildNewWarData:onGetGuildLogList(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.guildLogList = data

	if self.reqGuildLogListCallBack then
		self.reqGuildLogListCallBack(data)
	end
end

function GuildNewWarData:reqMessageInfoList(callback)
	if self.messageInfoList then
		if callback then
			callback(self.messageInfoList)
		end

		return
	end

	self.reqMessageInfoListCallBack = callback
	local msg = messages_pb:guild_new_war_get_message_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_MESSAGE, msg)
end

function GuildNewWarData:onGetMessageInfoList(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.messageInfoList = data

	if not self.messageInfoList.msg then
		self.messageInfoList.msg = {}
	end

	if self.reqMessageInfoListCallBack then
		self.reqMessageInfoListCallBack(data)

		self.reqMessageInfoListCallBack = nil
	end

	local curSeason = self:getCurSeason()
	local curReadNum = curSeason * 10000 + #self.messageInfoList.msg
	local readNum = xyd.db.misc:getValue("guild_new_war_battle_message_read_num")

	if readNum then
		readNum = tonumber(readNum)
	else
		readNum = curSeason * 10000
	end

	if readNum ~= curReadNum then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_BATTLE_MESSAGE_RED, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_BATTLE_MESSAGE_RED, false)
	end
end

function GuildNewWarData:saveReadBattleMessageNum()
	if self.messageInfoList and self.messageInfoList.msg then
		local curSeason = self:getCurSeason()
		local curReadNum = curSeason * 10000 + #self.messageInfoList.msg

		xyd.db.misc:setValue({
			key = "guild_new_war_battle_message_read_num",
			value = curReadNum
		})
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_BATTLE_MESSAGE_RED, false)
end

function GuildNewWarData:onGuildNewWarMessagePushBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "push_guild_new_war_message_back=========")

	if self.messageInfoList and self.messageInfoList.msg then
		if #self.messageInfoList.msg == 0 then
			table.insert(self.messageInfoList.msg, 1, data)
		else
			local isInsert = false

			for i, info in pairs(self.messageInfoList.msg) do
				if info.time <= data.time then
					isInsert = true

					table.insert(self.messageInfoList.msg, i, data)

					break
				end
			end

			if not isInsert then
				table.insert(self.messageInfoList.msg, data)
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_BATTLE_MESSAGE_RED, true)
end

function GuildNewWarData:reqBatchSetFlag(ops, callback)
	self.reqBatchSetFlagCallBack = callback
	local msg = messages_pb:guild_new_war_batch_set_flag_req()

	for i = 1, #ops do
		local op = ops[i]
		local set_op = messages_pb:guild_new_war_set_flag_op()
		set_op.flag_id = op.flag_id
		set_op.base_id = op.base_id
		set_op.op = op.op
		set_op.player_id = op.player_id

		table.insert(msg.ops, set_op)
	end

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_BATCH_SET_FLAG, msg)
end

function GuildNewWarData:onGetBatchSetFlag(event)
	local data = xyd.decodeProtoBuf(event.data)
	local ops = data.ops
	local members = xyd.models.guild.members
	local playerIDTomembers = {}

	for i = 1, #members do
		local playerID = members[i].player_id
		playerIDTomembers[playerID] = members[i]
	end

	for i = 1, #ops do
		local op = ops[i]
		local nodeID = op.base_id
		local flagID = op.flag_id
		local playerID = op.player_id

		if op.op == 2 then
			self.mapInfo[nodeID].flagInfos[flagID].playerInfo = {}
			self.mapInfo[nodeID].flagInfos[flagID].playerID = 0
			self.mapInfo[nodeID].curMemberNum = self.mapInfo[nodeID].curMemberNum - 1
			self.mapInfo[nodeID].curFlagNum = self.mapInfo[nodeID].curFlagNum - 1
			self.playerIDToFlagInfoArr[playerID] = nil
		elseif op.op == 1 then
			if self.playerIDToFlagInfoArr[playerID] then
				self.mapInfo[nodeID].flagInfos[flagID].playerInfo = self.playerIDToFlagInfoArr[playerID].playerInfo
			else
				self.mapInfo[nodeID].flagInfos[flagID].playerInfo = {
					due_date = 0,
					campaign_stage = 180,
					signature = "",
					dress_style = playerIDTomembers[playerID].dress_style,
					server_id = playerIDTomembers[playerID].server_id,
					player_name = playerIDTomembers[playerID].player_name,
					power = self.memberPowerList[playerID] or 0,
					avatar_frame_id = playerIDTomembers[playerID].avatar_frame_id,
					lev = playerIDTomembers[playerID].lev,
					player_id = playerID,
					avatar_id = playerIDTomembers[playerID].avatar_id,
					is_online = playerIDTomembers[playerID].is_online
				}
			end

			self.mapInfo[nodeID].flagInfos[flagID].playerID = playerID
			self.mapInfo[nodeID].curMemberNum = self.mapInfo[nodeID].curMemberNum + 1
			self.mapInfo[nodeID].curFlagNum = self.mapInfo[nodeID].curFlagNum + 1
			self.playerIDToFlagInfoArr[playerID] = {
				nodeID = nodeID,
				flagID = flagID,
				playerInfo = self.mapInfo[nodeID].flagInfos[flagID].playerInfo,
				braveHP = self.mapInfo[nodeID].flagInfos[flagID].braveHP,
				HP = self.mapInfo[nodeID].flagInfos[flagID].HP,
				playerID = playerID
			}
		end
	end

	self:updateMapInfo()

	if self.reqBatchSetFlagCallBack then
		self.reqBatchSetFlagCallBack()
	end
end

function GuildNewWarData:reqRally(nodeID, callback)
	if nodeID > 6 then
		nodeID = nodeID - 6
	end

	self.reqRallyCallBack = callback
	local msg = messages_pb:guild_new_war_rally_req()
	msg.base_id = nodeID

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_RALLY, msg)
end

function GuildNewWarData:onGetRally(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.baseInfo.rally = data.base_id
	self.baseInfo.rally_cd = xyd.getServerTime() + xyd.tables.miscTable:split2num("guild_new_war_command", "value", "|")[1]

	if self.reqRallyCallBack then
		self.reqRallyCallBack()
	end
end

function GuildNewWarData:reqSweep(nodeID, num, callback)
	if nodeID > 6 then
		nodeID = nodeID - 6
	end

	self.reqSweepCallBack = callback
	self.tempSweepTime = num
	local msg = messages_pb:guild_new_war_sweep_req()
	msg.base_id = nodeID
	msg.num = num

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_SWEEP, msg)
end

function GuildNewWarData:onGetSweep(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.baseInfo.self_info.ticket = 0
	self.tempAddSelfScore = data.self_score - self.baseInfo.self_info.score
	self.baseInfo.self_info.score = data.self_score

	if data.add then
		self.baseInfo.self_guild.score = self.baseInfo.self_guild.score + data.add
	end

	if self.reqSweepCallBack then
		self.reqSweepCallBack()
	end

	local isGuildAddScore = false

	if data.add and data.add > 0 then
		isGuildAddScore = true
	end

	self:battleBackDealRankInfo(isGuildAddScore)
end

function GuildNewWarData:setDefFormation(partners, petIDs, callback)
	self.setDefFormationCallBack = callback
	local msg = messages_pb:guild_new_war_set_teams_req()

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

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_SET_TEAMS, msg)
end

function GuildNewWarData:onGetSetDefFormation(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.allPlayerDefFormation[xyd.Global.playerID] = data

	if self.setDefFormationCallBack then
		self.setDefFormationCallBack()
	end
end

function GuildNewWarData:reqOtherDefFormation(playerID, callback)
	self.tempReqOtherID = playerID
	self.reqOtherDefFormationCallBack = callback
	local msg = messages_pb:guild_new_war_get_other_req()
	msg.other_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_OTHER, msg)
end

function GuildNewWarData:onGetOtherDefFormation(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.allPlayerDefFormation[self.tempReqOtherID] = data

	if self.allPlayerDefFormation[self.tempReqOtherID] and not self.allPlayerDefFormation[self.tempReqOtherID].star then
		for i = 1, 3 do
			for j = 1, 6 do
				if data.teams and data.teams[i] and data.teams[i].partners then
					local infoPartner = data.teams[i].partners[j]

					if infoPartner then
						local star = xyd.tables.partnerTable:getStar(infoPartner.table_id) + (infoPartner.awake or 0)
						infoPartner.star = star
					end
				end
			end
		end
	end

	if self.tempReqOtherID == xyd.Global.playerID then
		local wnd = xyd.getWindow("guild_new_war_map_window")

		if wnd then
			wnd:updateRedPoint()
		end
	end

	if self.reqOtherDefFormationCallBack then
		self.reqOtherDefFormationCallBack()
	end
end

function GuildNewWarData:reqGuildMemberDefFormationPower(callback)
	self.guildMemberDefFormationPowerCallback = callback
	local msg = messages_pb:guild_new_war_get_guild_member_power_req()

	xyd.Backend.get():request(xyd.mid.GUILD_NEW_WAR_GET_GUILD_MEMBER_POWER, msg)
end

function GuildNewWarData:onGuildMemberDefFormationPower(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.memberPowerList = {}

	if data.list then
		for i = 1, #data.list do
			self.memberPowerList[data.list[i].player_id] = data.list[i].power
		end
	end

	if self.guildMemberDefFormationPowerCallback then
		self.guildMemberDefFormationPowerCallback()
	end
end

function GuildNewWarData:getVsTotalData()
	local baseInfo = self:getBaseInfo()
	local data = {
		baseInfo = {},
		curSeason = self:getCurSeason()
	}
	data.baseInfo[1] = {
		guildName = baseInfo.self_guild.base_info.name,
		flag = baseInfo.self_guild.base_info.flag,
		power = baseInfo.self_guild.power,
		leader = baseInfo.self_guild.leader,
		point = baseInfo.self_guild.score,
		MvpName = baseInfo.self_guild.mvp
	}
	data.baseInfo[2] = {
		guildName = baseInfo.match_guild.base_info.name,
		flag = baseInfo.match_guild.base_info.flag,
		power = baseInfo.match_guild.power,
		leader = baseInfo.match_guild.leader,
		point = baseInfo.match_guild.score,
		MvpName = baseInfo.match_guild.mvp
	}

	return data
end

function GuildNewWarData:getMapNodeDatas()
	local datas = {}

	for i = 1, 12 do
		local data = self.mapInfo[i]
		data.dress_style = nil

		for j = 1, #data.flagInfos do
			if data.flagInfos[j].playerID > 0 then
				data.dress_style = data.flagInfos[j].playerInfo.dress_style

				break
			end
		end

		data.isAiming = self.baseInfo.rally > 0 and self.baseInfo.rally + 6 == i
	end

	return self.mapInfo
end

function GuildNewWarData:getNodeDetailData(nodeIndex)
	local data = {
		baseInfo = {},
		list = self.mapInfo[nodeIndex].flagInfos
	}
	local nodeType = self:getNodeType(nodeIndex)
	data.baseInfo.maxFlagNum = self.mapInfo[nodeIndex].maxFlagNum
	data.baseInfo.curFlagNum = self.mapInfo[nodeIndex].curFlagNum
	data.baseInfo.isAiming = self.mapInfo[nodeIndex].isAiming
	data.baseInfo.skillID = 0

	return data
end

function GuildNewWarData:getEnemyFormationData(playerID, callback)
	if not self.allPlayerDefFormation[playerID] or not self.allPlayerDefFormation[playerID].teams then
		self:reqOtherDefFormation(playerID, callback)

		return false
	end

	return self.allPlayerDefFormation[playerID]
end

function GuildNewWarData:getLeftAttackTime()
	return self.baseInfo.self_info.ticket
end

function GuildNewWarData:getGuildRank()
	return self.baseInfo.rank
end

function GuildNewWarData:getMyRank()
	return self.baseInfo.self_info.rank
end

function GuildNewWarData:getSelfPoint()
	return self.baseInfo.self_info.score
end

function GuildNewWarData:reqReport(ids)
	local msg = messages_pb:arena_get_report_req()
	msg.record_id = ids

	xyd.Backend:get():request(xyd.mid.ARENA_GET_REPORT, msg)
end

function GuildNewWarData:getDefPlayerData()
	local members = xyd.models.guild.members
	local datas = {}

	for i = 1, #members do
		local playerID = members[i].player_id
		local data = {
			flagIndex = 0,
			nodeIndex = 0,
			playerInfo = {
				job = members[i].job,
				playerID = playerID,
				playerName = members[i].player_name,
				power = xyd.checkCondition(self.memberPowerList[playerID], self.memberPowerList[playerID], 0),
				dress_style = xyd.checkCondition(members[i].dress_style, members[i].dress_style, xyd.models.dress:getEffectEquipedStyles())
			},
			power = xyd.checkCondition(self.memberPowerList[playerID], self.memberPowerList[playerID], 0)
		}

		if self.playerIDToFlagInfoArr[playerID] then
			data = {
				nodeIndex = self.playerIDToFlagInfoArr[playerID].nodeID,
				flagIndex = self.playerIDToFlagInfoArr[playerID].flagID,
				playerInfo = {
					playerID = playerID,
					playerName = members[i].player_name,
					power = self.playerIDToFlagInfoArr[playerID].playerInfo.power,
					dress_style = self.playerIDToFlagInfoArr[playerID].playerInfo.dress_style
				},
				power = self.playerIDToFlagInfoArr[playerID].playerInfo.power
			}
		end

		if data.power > 0 then
			table.insert(datas, data)
		end
	end

	return datas
end

function GuildNewWarData:getFlagData(nodeIndex, flagIndex)
	return self.mapInfo[nodeIndex].flagInfos[flagIndex]
end

function GuildNewWarData:getShowInfoByBattleID(battleID)
	if self.showInfoByBattleID[battleID] then
		return self.showInfoByBattleID[battleID]
	end

	return {
		enemyPoint = 0,
		lostTime = 0,
		winTime = 0,
		selfPoint = 0,
		awards = {}
	}
end

function GuildNewWarData:getDefFormation()
	local formationData = {
		power = 0,
		teams = {
			{
				partners = {}
			},
			{
				partners = {}
			},
			{
				partners = {}
			}
		}
	}

	if not self.allPlayerDefFormation[xyd.Global.playerID] or not self.allPlayerDefFormation[xyd.Global.playerID].teams then
		return formationData
	end

	return self.allPlayerDefFormation[xyd.Global.playerID]
end

function GuildNewWarData:getPvPBattleFormation()
	local DefFormationData = self:getDefFormation()
	local formationData = {
		power = 0,
		teams = {
			{
				partners = {}
			},
			{
				partners = {}
			},
			{
				partners = {}
			}
		}
	}

	for i = 1, 18 do
		local row = 1
		local col = i

		if i > 12 then
			row = 3
			col = i - 12
		elseif i > 6 then
			row = 2
			col = i - 6
		end

		local partnerID = nil

		if DefFormationData.teams[row].partners[col] then
			partnerID = tonumber(DefFormationData.teams[row].partners[col].partner_id)
		end

		local petID = nil

		if DefFormationData.teams[row].pet then
			petID = tonumber(DefFormationData.teams[row].pet)
		end

		if partnerID then
			local partner = xyd.models.slot:getPartner(partnerID)

			if partner then
				formationData.teams[row].partners[col] = partner
			end
		end

		if petID then
			local pet = xyd.models.petSlot:getPetByID(petID)

			if pet then
				formationData.teams[row].pet = pet
			end
		end
	end

	formationData.power = DefFormationData.power

	if not self.pvpPartners then
		local dbVal = xyd.db.formation:getValue(xyd.BattleType.GUILD_NEW_WAR)

		if not dbVal then
			self.pvpPartners = formationData

			return self.pvpPartners
		end

		local data = cjson.decode(dbVal)

		if not data.partners then
			self.pvpPartners = formationData

			return self.pvpPartners
		end

		formationData = {
			power = 0,
			teams = {
				{
					partners = {}
				},
				{
					partners = {}
				},
				{
					partners = {}
				}
			}
		}
		self.pvpPetIDs = data.pet_ids or self.pets

		for i = 1, 18 do
			local row = 1
			local col = i

			if i > 12 then
				row = 3
				col = i - 12
			elseif i > 6 then
				row = 2
				col = i - 6
			end

			local sPartnerID = tonumber(data.partners[tostring(i)])
			local sPetID = tonumber(data.pet_ids[row + 1])
			local partner = xyd.models.slot:getPartner(sPartnerID)
			local pet = xyd.models.petSlot:getPetByID(sPetID)

			if partner then
				formationData.teams[row].partners[col] = partner
			end

			if pet then
				formationData.teams[row].pet = pet
			end
		end

		self.pvpPartners = formationData
	end

	return self.pvpPartners
end

function GuildNewWarData:setPvPBattleFormation(Partners, PetIDs)
	self.pvpPetIDs = PetIDs
	local formationData = {
		teams = {
			{
				partners = {}
			},
			{
				partners = {}
			},
			{
				partners = {}
			}
		}
	}

	for i = 1, 18 do
		local row = 1
		local col = i

		if i > 12 then
			row = 3
			col = i - 12
		elseif i > 6 then
			row = 2
			col = i - 6
		end

		if Partners[i] then
			local sPartnerID = tonumber(Partners[i].partner_id)
			local partner = xyd.models.slot:getPartner(sPartnerID)

			if partner then
				formationData.teams[row].partners[col] = partner
			end
		end

		if PetIDs[row + 1] then
			local sPetID = tonumber(PetIDs[row + 1])
			local pet = xyd.models.petSlot:getPetByID(sPetID)

			if pet then
				formationData.teams[row].pet = pet
			end
		end
	end

	self.pvpPartners = formationData
end

function GuildNewWarData:isSkipBattle()
	return self.skipReport
end

function GuildNewWarData:isSkipReport()
	return self:isSkipBattle()
end

function GuildNewWarData:setSkipBattle(flag)
	self.skipReport = flag
	local value = flag and 1 or 0

	xyd.db.misc:setValue({
		key = "guild_new_war_skip_report",
		value = value
	})
end

function GuildNewWarData:getFlagImgName(isSelf, nodeIndex, isDestroyed, isflag)
	local nodeType = self:getNodeType(nodeIndex)
	local index = 1

	if isSelf then
		index = 2
	end

	if isDestroyed then
		if isflag then
			return "guild_new_war2_icon_qz_3"
		else
			return "guild_new_war2_icon_qz_" .. index
		end
	end

	if nodeType == xyd.GuildNewWarNodeType.LEFT_FRONT or nodeType == xyd.GuildNewWarNodeType.RIGHT_FRONT then
		return "guild_new_war2_icon_qz_qian_" .. index
	elseif nodeType == xyd.GuildNewWarNodeType.MAIN then
		return "guild_new_war2_icon_qz_hou_" .. index
	else
		return "guild_new_war2_icon_qz_zhong_" .. index
	end

	return false
end

function GuildNewWarData:canJoinGuildNewWar()
	local guildLevel = xyd.models.guild.level
	local members = xyd.models.guild.members
	local memberNum = 0
	local helpArr = xyd.tables.miscTable:split2num("guild_new_war_guild_limit", "value", "|")

	for i = 1, #members do
		if members[i].is_online == 1 or xyd.getServerTime() - members[i].last_time <= helpArr[2] * xyd.DAY_TIME then
			memberNum = memberNum + 1
		end
	end

	if helpArr[1] <= guildLevel and helpArr[3] <= memberNum then
		return true
	end

	return false
end

function GuildNewWarData:checkHaveEnemyInfo(playerID, callback)
	if self:getEnemyFormationData(playerID, callback) then
		callback()
	end
end

function GuildNewWarData:setTmpReports(data)
	self.tmpReports = data
	self.recordIds = data.record_ids
end

function GuildNewWarData:resetTmpReports()
	self.tmpReports = {}
	self.recordIds = {}
	self.tmpBattleIndex = 1
end

function GuildNewWarData:isLastReport()
	if self.tmpReports.battle_reports and self.tmpBattleIndex == #self.tmpReports.battle_reports then
		return true
	end

	return false
end

function GuildNewWarData:getTmpReports()
	return self.tmpReports
end

function GuildNewWarData:getNextReport()
	self.tmpBattleIndex = self.tmpBattleIndex + 1

	if self.tmpReports.battle_reports and self.tmpReports.battle_reports[self.tmpBattleIndex] then
		return self.tmpReports.battle_reports[self.tmpBattleIndex]
	else
		return nil
	end
end

function GuildNewWarData:getRecordId()
	return self.recordIds[self.tmpBattleIndex] or -1
end

function GuildNewWarData:getTempBattleSelfInfo()
	return {
		player_name = xyd.Global.playerName,
		lev = xyd.models.backpack:getLev(),
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	}
end

function GuildNewWarData:getTempBattleEnemyInfo()
	return self.tempBattleEnemyInfo
end

function GuildNewWarData:setTempBattleEnemyInfo(info)
	self.tempBattleEnemyInfo = info
end

function GuildNewWarData:getBaseInfo()
	return self.baseInfo
end

function GuildNewWarData:getLeftFightTime()
	return self.leftFightTime
end

function GuildNewWarData:getCurSkill(isSelf)
	local beginIndex = 1
	local endIndex = 6
	local CurSkill = 0

	if not isSelf then
		beginIndex = 7
		endIndex = 12
	end

	for i = beginIndex, endIndex do
		local nodeID = i
		local nodeType = self:getNodeType(nodeID)
		local skillId = xyd.tables.guildNewWarBaseTable:getSkillId(nodeType)
		local isDestroy = true

		for j = 1, #self.mapInfo[nodeID].flagInfos do
			local flagID = j

			if self.mapInfo[nodeID].flagInfos[flagID].HP > 0 then
				isDestroy = false

				break
			end
		end

		if isDestroy then
			CurSkill = skillId
		end
	end

	return CurSkill
end

function GuildNewWarData:checkNeedReqGuildMemberInfo(callback)
	local need = true

	if not need then
		callback()
	else
		self:reqGuildMemberDefFormationPower(callback)
	end

	return need
end

function GuildNewWarData:getRedMarkState()
	local red = false
	red = red or self:checkRedPointPeriodFirstTime()

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR, red)

	return red
end

function GuildNewWarData:checkRedPointPeriodFirstTime()
	local red = false
	local flag = xyd.db.misc:getValue("guild_new_war_" .. self:getBeginTime())

	if not flag then
		red = true
	end

	local period = xyd.db.misc:getValue("guild_new_war_last_click_period")

	if not period or tonumber(period) ~= self:getCurPeriod() then
		red = true
	end

	return red
end

function GuildNewWarData:checkRedPointSelfDefFormation()
	local red = true
	local formation = self:getDefFormation()

	if formation.power and formation.power > 0 then
		red = false
	end

	return red
end

function GuildNewWarData:getGuildLogList()
	return self.guildLogList
end

function GuildNewWarData:checkChatBtnRedPoint()
	local time = xyd.db.misc:getValue("guild_new_war_chat_red_time")

	if not time then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_CHAT_RED, true)
	else
		time = tonumber(time)

		if xyd.isSameDay(time, xyd.getServerTime()) then
			xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_CHAT_RED, false)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_NEW_WAR_CHAT_RED, true)
		end
	end
end

function GuildNewWarData:battleBackDealRankInfo(isGuildAddScore)
	xyd.addGlobalTimer(function ()
		if not self.guildRankList then
			self:reqGuildRankList()
		elseif isGuildAddScore then
			local guildScore = self.baseInfo.self_guild.score

			if guildScore == 0 then
				self.baseInfo.rank = 0
			elseif self.guildRankList.list and #self.guildRankList.list == 0 then
				self.baseInfo.rank = 1
			else
				local isSearch = false
				local isInRank = false

				for i = #self.guildRankList.list, 1 do
					local info = self.guildRankList.list[i]

					if info.score < guildScore then
						isSearch = true
						self.baseInfo.rank = i
					end

					if info.guild_id == self.baseInfo.self_guild.base_info.guild_id then
						isInRank = true
					end
				end

				if not isSearch and not isInRank and #self.guildRankList.list < 50 then
					self.baseInfo.rank = #self.guildRankList.list + 1
				end
			end
		end

		if not self.personRankList then
			self:reqPersonRankList()
		else
			local selfScore = self.baseInfo.self_info.score

			if selfScore and selfScore > 0 then
				if self.personRankList.list and #self.personRankList.list == 0 then
					self.baseInfo.rank = 1
				else
					local isSearch = false
					local isInRank = false

					for i = #self.personRankList.list, 1 do
						local info = self.personRankList.list[i]

						if info.score < selfScore then
							isSearch = true
							self.baseInfo.rank = i
						end

						if info.player_id == xyd.models.selfPlayer:getPlayerID() then
							isInRank = true
						end
					end

					if not isSearch and not isInRank then
						self.baseInfo.self_info.rank = #self.personRankList.list + 1
					end
				end
			end
		end
	end, 1, 1)
end

function GuildNewWarData:updateMapInfo()
	for nodeID, nodeInfo in pairs(self.mapInfo) do
		nodeInfo.curMemberNum = 0
		nodeInfo.curFlagNum = 0

		for key, flagInfo in pairs(nodeInfo.flagInfos) do
			if flagInfo.braveHP > 0 and flagInfo.playerInfo and flagInfo.playerInfo.player_id then
				self.mapInfo[nodeID].curMemberNum = self.mapInfo[nodeID].curMemberNum + 1
			end

			if flagInfo.HP > 0 then
				self.mapInfo[nodeID].curFlagNum = self.mapInfo[nodeID].curFlagNum + 1
			end
		end
	end
end

return GuildNewWarData
