local BaseModel = import(".BaseModel")
local FriendTeamBoss = class("FriendTeamBoss", BaseModel)
local cjson = require("cjson")
FriendTeamBoss.STATE = {
	FIGHTING = 2,
	TEAMUP = 1
}

function FriendTeamBoss:ctor(...)
	BaseModel.ctor(self, ...)

	self.lastApplyList_ = 0
	self.lastInviteList_ = 0
	self.lastFriendTeamList_ = 0
	self.weatherID = 0
end

function FriendTeamBoss:get()
	if FriendTeamBoss.INSTANCE == nil then
		FriendTeamBoss.INSTANCE = FriendTeamBoss.new()

		FriendTeamBoss.INSTANCE:onRegister()
	end

	return FriendTeamBoss.INSTANCE
end

function FriendTeamBoss:reset()
	if FriendTeamBoss.INSTANCE then
		FriendTeamBoss.INSTANCE:removeEvents()
	end

	FriendTeamBoss.INSTANCE = nil
end

function FriendTeamBoss:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_FRIEND_TEAM_BOSS_INFO, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.MODIFY_FRIEND_TEAM_BOSS_TEAM_INFO, handler(self, self.onChangeTeamInfo))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_BUY_ATTACK_TIMES, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_GET_INVITE_LIST, handler(self, self.onGetInviteList))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_INVITE, handler(self, self.onAcceptInvite))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_REFUSE_INVITE, handler(self, self.onRefuseInvite))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_GET_FRIEND_TEAM_LIST, handler(self, self.onGetFriendTeamList))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_GET_APPLY_LIST, handler(self, self.onGetApplyList))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_ACCEPT_APPLY, handler(self, self.onAcceptApply))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_REFUSE_APPLY, handler(self, self.onRefuseApply))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_KICKOUT_FRIEND, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_EXIT_TEAM, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_APPLY_TEAM, handler(self, self.onApply))
	self:registerEvent(xyd.event.FRIEND_TEAM_BOSS_FIGHT, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedPoint))
end

function FriendTeamBoss:onRedPoint(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if funID ~= xyd.FunctionID.FRIEND_TEAM_BOSS then
		return
	end

	local value = event.data.value

	if value == xyd.FriendTeamBossRedMarkType.INFO then
		self:reqInfo()
	elseif value == xyd.FriendTeamBossRedMarkType.INVITE then
		self:reqInviteList()
	elseif value == xyd.FriendTeamBossRedMarkType.APPLY then
		self:reqApplyPlayerList()
	end
end

function FriendTeamBoss:onApply(event)
	for i = 1, #self.friendTeamList_ do
		if event.data.team_id == self.friendTeamList_[i].team_id then
			self.friendTeamList_[i].last_apply_time = xyd.getServerTime()

			break
		end
	end
end

function FriendTeamBoss:onAcceptInvite(event)
	self:onGetInfo(event)

	self.inviteList_ = self.inviteList_ or {}

	for i = 1, #self.inviteList_ do
		if self.inviteList_[i].team_id == event.data.team_id then
			table.remove(self.inviteList_, i)

			break
		end
	end

	self:updateRedMark()
end

function FriendTeamBoss:onRefuseInvite(event)
	self:onAcceptInvite(event)
end

function FriendTeamBoss:onAcceptApply(event)
	self:onGetInfo(event)

	self.applyList_ = self.applyList_ or {}

	for i = 1, #self.applyList_ do
		if self.applyList_[i].player_id == event.data.friend_id then
			table.remove(self.applyList_, i)

			break
		end
	end

	self:updateRedMark()
end

function FriendTeamBoss:onRefuseApply(event)
	self:onAcceptApply(event)
end

function FriendTeamBoss:onGetInfo(event)
	local data = event.data

	if data.team_info and xyd.arrayIndexOf(data.team_info.player_ids, xyd.models.selfPlayer:getPlayerID()) < 0 then
		return
	end

	if data.team_info then
		self.teamInfo_ = data.team_info
	end

	if data.self_info then
		self.selfInfo_ = data.self_info
	end

	if data.weather then
		self.weatherID = data.weather
	end

	if self.teamInfo_ and self.selfInfo_ and self.teamInfo_.team_id ~= self.selfInfo_.team_id then
		self.selfInfo_.team_id = self.teamInfo_.team_id
	end

	self:updateRedMark()
end

function FriendTeamBoss:getMaxHistory()
	return self.selfInfo_.history_max_boss_lev
end

function FriendTeamBoss:updateRedMark()
	if self.inviteList_ and #self.inviteList_ > 0 and not self:checkInFight() then
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_INVITED, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_INVITED, false)
	end

	if self.applyList_ and #self.applyList_ > 0 and not self:checkInFight() and self:getTeamInfo() and self:getTeamInfo().leader_id == xyd.Global.playerID then
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_APPLY, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_APPLY, false)
	end

	if self.teamInfo_ and self:checkInFight() and tonumber(self.teamInfo_.boss_1_hp) > 0 and self.selfInfo_.can_attack_times > 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS, false)
	end

	if self:needRemind() then
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND_TEAM_BOSS_MSG2, false)
	end

	local win = xyd.WindowManager.get():getWindow("friend_team_boss_window")

	if win then
		win:updateRedMark()
	end
end

function FriendTeamBoss:onGetApplyList(event)
	self.lastApplyList_ = xyd.getServerTime()
	self.applyList_ = {}

	for _, item in ipairs(event.data.apply_list) do
		local info = {
			server_id = item.server_id,
			player_name = item.player_name,
			avatar_frame_id = item.avatar_frame_id,
			lev = item.lev,
			is_online = item.is_online,
			player_id = item.player_id,
			avatar_id = item.avatar_id,
			boss_level = item.boss_level
		}

		table.insert(self.applyList_, info)
	end

	self:updateRedMark()
end

function FriendTeamBoss:getApplyList()
	return cjson.decode(cjson.encode(self.applyList_ or {}))
end

function FriendTeamBoss:onGetInviteList(event)
	self.lastInviteList_ = xyd.getServerTime()
	self.inviteList_ = {}

	for _, item in ipairs(event.data.invite_list) do
		local team_info = {
			team_id = item.team_id,
			team_name = item.team_name,
			team_icon = item.team_icon,
			last_modify_time = item.last_modify_time,
			player_ids = item.player_ids,
			leader_id = item.leader_id,
			team_status = item.team_status,
			boss_level = item.boss_level,
			last_apply_time = item.last_apply_time,
			player_ids = {}
		}

		for _, player_id in ipairs(item.player_ids) do
			table.insert(team_info.player_ids, player_id)
		end

		table.insert(self.inviteList_, team_info)
	end

	self:updateRedMark()
end

function FriendTeamBoss:getInviteList()
	return cjson.decode(cjson.encode(self.inviteList_ or {}))
end

function FriendTeamBoss:onChangeTeamInfo(event)
	local data = event.data
	self.teamInfo_.last_modify_time = data.last_modify_time
	self.teamInfo_.team_name = data.team_name
	self.teamInfo_.team_icon = data.team_icon
end

function FriendTeamBoss:onGetFriendTeamList(event)
	self.lastFriendTeamList_ = xyd.getServerTime()
	self.friendTeamList_ = {}

	for _, item in ipairs(event.data.team_list) do
		local team_info = {
			team_id = item.team_id,
			team_name = item.team_name,
			team_icon = item.team_icon,
			last_modify_time = item.last_modify_time,
			player_ids = item.player_ids,
			leader_id = item.leader_id,
			team_status = item.team_status,
			boss_level = item.boss_level,
			last_apply_time = item.last_apply_time,
			player_ids = {}
		}

		for _, player_id in ipairs(item.player_ids) do
			table.insert(team_info.player_ids, player_id)
		end

		table.insert(self.friendTeamList_, team_info)
	end
end

function FriendTeamBoss:getFriendTeamList()
	return cjson.decode(cjson.encode(self.friendTeamList_ or {}))
end

function FriendTeamBoss:applyTeam(team_id)
	if not team_id then
		return
	end

	local msg = messages_pb.friend_team_boss_apply_team_req()
	msg.team_id = team_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_APPLY_TEAM, msg)
end

function FriendTeamBoss:reqApplyPlayerList()
	local CD = 1

	if self.applyList_ and CD > xyd.getServerTime() - self.lastApplyList_ then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.FRIEND_TEAM_BOSS_GET_APPLY_LIST,
			params = {
				apply_list = self.applyList_
			}
		})

		return
	end

	local msg = messages_pb.friend_team_boss_get_apply_list_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_APPLY_LIST, msg)
end

function FriendTeamBoss:acceptApply(player_id)
	if not player_id then
		return
	end

	local msg = messages_pb.friend_team_boss_accept_apply_req()
	msg.friend_id = player_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_ACCEPT_APPLY, msg)
end

function FriendTeamBoss:refuseApply(player_id)
	if not player_id then
		return
	end

	local msg = messages_pb.friend_team_boss_refuse_apply_req()
	msg.friend_id = player_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_REFUSE_APPLY, msg)
end

function FriendTeamBoss:refuseInvite(team_id)
	if not team_id then
		return
	end

	local msg = messages_pb.friend_team_boss_refuse_invite_req()
	msg.team_id = team_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_REFUSE_INVITE, msg)
end

function FriendTeamBoss:exitTeam()
	local msg = messages_pb.friend_team_boss_exit_team_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_EXIT_TEAM, msg)
end

function FriendTeamBoss:kickOutPlayer(player_id)
	if not player_id then
		return
	end

	local msg = messages_pb.friend_team_boss_kickout_friend_req()
	msg.friend_id = player_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_KICKOUT_FRIEND, msg)
end

function FriendTeamBoss:invitePlayer(player_id)
	if not player_id then
		return
	end

	local msg = messages_pb.friend_team_boss_invite_friend_req()
	msg.friend_id = player_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_INVITE_FRIEND, msg)
end

function FriendTeamBoss:reqInviteList()
	local CD = 1

	if self.inviteList_ and CD > xyd.getServerTime() - self.lastInviteList_ then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.FRIEND_TEAM_BOSS_GET_INVITE_LIST,
			params = {
				invite_list = self.inviteList_
			}
		})

		return
	end

	local msg = messages_pb.friend_team_boss_get_invite_list_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_INVITE_LIST, msg)
end

function FriendTeamBoss:acceptInvite(team_id)
	if not team_id then
		return
	end

	local msg = messages_pb.friend_team_boss_accept_invite_req()
	msg.team_id = team_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_ACCEPT_INVITE, msg)
end

function FriendTeamBoss:getTeamInfo()
	return self.teamInfo_
end

function FriendTeamBoss:getSelfInfo()
	return self.selfInfo_
end

function FriendTeamBoss:reqInfo(friend_id)
	if not xyd.checkFunctionOpen(xyd.FunctionID.FRIEND_TEAM_BOSS, true) then
		return
	end

	local msg = messages_pb.get_friend_team_boss_info_req()

	if friend_id then
		msg.friend_id = friend_id
	end

	xyd.Backend.get():request(xyd.mid.GET_FRIEND_TEAM_BOSS_INFO, msg)
end

function FriendTeamBoss:reqTeamList()
	local CD = 1

	if self.friendTeamList_ and CD > xyd.getServerTime() - self.lastFriendTeamList_ then
		xyd.EventDispatcher:inner():dispatchEvent({
			name = xyd.event.FRIEND_TEAM_BOSS_GET_FRIEND_TEAM_LIST,
			params = {
				team_list = self.friendTeamList_
			}
		})

		return
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_FRIEND_TEAM_LIST)
end

function FriendTeamBoss:reqOtherTeamInfo(team_id, player_id)
	if not team_id and not player_id then
		return
	end

	local msg = messages_pb.friend_team_boss_get_team_detail_req()
	msg.team_id = team_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_TEAM_DETAIL, msg)
end

function FriendTeamBoss:reqModifyTeamInfo(team_id, team_name, team_icon)
	local msg = messages_pb.modify_friend_team_boss_team_info_req()
	msg.team_id = team_id and team_id or self.teamInfo_.team_id
	msg.team_name = team_name and team_name or self.teamInfo_.team_name
	msg.team_icon = team_icon and team_icon or self.teamInfo_.team_icon

	xyd.Backend.get():request(xyd.mid.MODIFY_FRIEND_TEAM_BOSS_TEAM_INFO, msg)
end

function FriendTeamBoss:buyTimes()
	local msg = {}

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_BUY_ATTACK_TIMES)
end

function FriendTeamBoss:checkInFight()
	if self.teamInfo_ and self.teamInfo_.team_status == FriendTeamBoss.STATE.FIGHTING then
		return true
	else
		return false
	end
end

function FriendTeamBoss:getTime2End()
	local weekStartTime = xyd.getGMTWeekStartTime(xyd.getServerTime())
	local interval = xyd.getServerTime() - weekStartTime
	local t = xyd.split(xyd.tables.miscTable:getVal("govern_team_kill_result"), "|")

	for i = 1, #t do
		local t_arr = xyd.split(t[i], "#", true)
		local time = (t_arr[1] - 1) * 86400 + t_arr[2] * 3600

		if interval < time then
			return time - interval
		end
	end

	local t_arr = xyd.split(t[1], "#", true)
	local time = (t_arr[1] - 1) * 86400 + t_arr[2] * 3600 + 604800

	return time - interval
end

function FriendTeamBoss:getTime2TeamEnd()
	local endTime = self:getTime2End()

	return endTime - tonumber(xyd.tables.miscTable:getVal("govern_team_time"))
end

function FriendTeamBoss:reqFight(partners, pet, index, team_index)
	local msg = messages_pb.friend_team_boss_fight_req()

	if team_index and team_index > 0 then
		msg.formation_id = team_index
	else
		xyd.getFightPartnerMsg(msg.partners, partners)
	end

	msg.pet_id = pet
	msg.boss_index = index

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_FIGHT, msg)
end

function FriendTeamBoss:reqRecord()
	local msg = messages_pb.friend_team_boss_get_records_req()
	msg.team_id = self.teamInfo_.team_id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_RECORDS, msg)
end

function FriendTeamBoss:reqReport(id)
	local msg = messages_pb.friend_team_boss_get_report_req()
	msg.record_id = id

	xyd.Backend.get():request(xyd.mid.FRIEND_TEAM_BOSS_GET_REPORT, msg)
end

function FriendTeamBoss:getWeatherID()
	return self.weatherID
end

function FriendTeamBoss:getRemindMsg()
	local remindMsg = {}
	local teamInfo = self:getTeamInfo()
	local noticeInfo = teamInfo.notice_info
	local teamMateInfo = teamInfo.arena_defence_info
	local team_status = teamInfo.team_status
	local isLeader = teamInfo.leader_id == xyd.Global.playerID

	if #noticeInfo == 1 or #noticeInfo ~= #teamMateInfo then
		return false
	end

	local limitDays = xyd.tables.miscTable:getNumber("govern_team_offline_notice", "value")

	if team_status == 1 then
		for i = 1, #teamMateInfo do
			if xyd.Global.playerID ~= teamMateInfo[i].player_id and limitDays <= math.floor((xyd.getServerTime() - noticeInfo[i].last_online_time) / xyd.TimePeriod.DAY_TIME) then
				if isLeader then
					table.insert(remindMsg, {
						state = 2,
						playerName = teamMateInfo[i].player_name
					})
				elseif teamInfo.leader_id == teamMateInfo[i].player_id then
					table.insert(remindMsg, {
						state = 3,
						playerName = teamMateInfo[i].player_name
					})
				end
			end
		end
	elseif team_status == 2 then
		for i = 1, #teamMateInfo do
			if xyd.Global.playerID ~= teamMateInfo[i].player_id and noticeInfo[i].is_former_boss_attack == 0 then
				table.insert(remindMsg, {
					state = 1,
					playerName = teamMateInfo[i].player_name
				})
			end
		end
	end

	return remindMsg
end

function FriendTeamBoss:needRemind()
	local teamInfo = self:getTeamInfo()

	if not teamInfo then
		return false
	end

	local noticeInfo = teamInfo.notice_info
	local teamMateInfo = teamInfo.arena_defence_info

	if #noticeInfo == 1 or #noticeInfo ~= #teamMateInfo then
		return false
	end

	local msgs = self:getRemindMsg()

	if not msgs or #msgs <= 0 then
		return false
	end

	local state = xyd.db.misc:getValue("friend_team_boss_remind_state")
	local time = xyd.db.misc:getValue("friend_team_boss_remind_time")

	if not state or not time then
		return true
	end

	if teamInfo.team_status ~= tonumber(state) and xyd.TimePeriod.DAY_TIME < xyd.getServerTime() - tonumber(time) then
		return true
	else
		return false
	end
end

return FriendTeamBoss
