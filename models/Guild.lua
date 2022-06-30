local BaseModel = import(".BaseModel")
local Guild = class("Guild", BaseModel, true)

function Guild:ctor()
	BaseModel.ctor(self)

	self.first_init_recommend_ = true
	self.applyList_ = {}
	self.resetTimes_ = {}
	self.guildSkills_ = {}
	self.selfOrderList = {}
	self.needUpdateJobs_ = {}
	self.luck_req_count_ = 0
	self.bossInfoList_ = {}
	self.logs_ = {}
	self.members_ = {}
	self.apply_members_ = {}
	self.guildList_ = {}
	self.base_info_ = {}
	self.isLoaded_ = false
	self.level_ = 1
	self.guild_id_ = 0
	self.job_ = xyd.GUILD_JOB.NORMAL
	self.skillLevByID_ = {}

	self:initGuildCompetitionInfo()
end

function Guild.____getters:logs()
	return self.logs_
end

function Guild.____getters:members()
	return self.members_
end

function Guild.____getters:base_info()
	return self.base_info_
end

function Guild.____getters:self_info()
	return self.self_info_
end

function Guild.____getters:guild_battle_id()
	return self.guild_battle_id
end

function Guild.____setters:lev(id)
	self.guild_battle_id = id
end

function Guild.____getters:guildsList()
	local tmp1 = {}
	local tmp2 = {}

	for i = 6, #self.guildList_ do
		table.insert(tmp1, self.guildList_[i])
	end

	for i = 1, math.min(5, #self.guildList_) do
		table.insert(tmp2, self.guildList_[i])
	end

	self.guildList_ = tmp1

	return tmp2
end

function Guild.____getters:bossID()
	return self.bossID_ or 0
end

function Guild.____getters:level()
	return self.level_
end

function Guild.____getters:isCheckIn()
	return self.is_checkin_
end

function Guild.____getters:applyMembers()
	return self.apply_members_
end

function Guild.____getters:announcement()
	return self.announcement_
end

function Guild.____getters:guildID()
	return self.guild_id_
end

function Guild.____getters:guildJob()
	return self.job_
end

function Guild:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.RED_POINT, self.onRedMarkInfo, self)
	self:registerEvent(xyd.event.GUILD_CREATE, self.onCreateInfo, self)
	self:registerEvent(xyd.event.GUILD_GET_INFO, self.onGuildInfo, self)
	self:registerEvent(xyd.event.GUILD_CHECKIN, self.onGuildCheckIn, self)
	self:registerEvent(xyd.event.GUILD_QUIT, self.onQuitGuild, self)
	self:registerEvent(xyd.event.GUILD_EDIT_NAME, self.onEditName, self)
	self:registerEvent(xyd.event.GUILD_EDIT_ANNOUNCEMENT, self.onEditAnnouncement, self)
	self:registerEvent(xyd.event.GUILD_REFRESH, self.onGuildRefresh, self)
	self:registerEvent(xyd.event.GUILD_APPLY_LIST, self.onApplyList, self)
	self:registerEvent(xyd.event.GUILD_DELETE_APPLY, self.onRefuseApply, self)
	self:registerEvent(xyd.event.GUILD_GET_SKILLS, self.onGuildSkills, self)
	self:registerEvent(xyd.event.GUILD_UPGRADE_SKILL, self.onGuildSkillLevUp, self)
	self:registerEvent(xyd.event.GUILD_RESET_SKILL, self.onGuildResetSkill, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_ORDER_LIST, self.onGetDiningHallOrderList, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_UPGRADE_ORDER, self.onDiningHallUpgradeOrder, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_COMPLETE_ORDER, self.onCompleteOrder, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_NEW_ORDERS, self.onGetNewOrderList, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_DONATE_GOLD, self.onDiningHallDonateGold, self)
	self:registerEvent(xyd.event.GUILD_BOSS_INFO, self.onBossInfo, self)
	self:registerEvent(xyd.event.GUILD_DISSOLVE, self.onDissolve, self)
	self:registerEvent(xyd.event.GUILD_CANCEL_DISSOLVE, self.onCancelDissolve, self)
	self:registerEvent(xyd.event.SEND_RECRUIT_MSGS, self.onRecruitTime, self)
	self:registerEvent(xyd.event.UNIFORM_ERROR, self.onError, self)
	self:registerEvent(xyd.event.GUILD_BOSS_BROADCAST, self.onGuildBossBroadCast, self)
	self:registerEvent(xyd.event.SYSTEM_REFRESH, self.systemRefresh, self)
	self:registerEvent(xyd.event.FUNCTION_OPEN, self.updateJoinGuildRedMark, self)
	self:registerEvent(xyd.event.GET_LUCKY_STATUS, self.checkLuckyDevice, self)
	self:registerEvent(xyd.event.GUILD_EDIT_PLAN, self.onChangePlan, self)
	self:registerEvent(xyd.event.GUILD_EDIT_APPLY_WAY, self.onChangeWay, self)
	self:registerEvent(xyd.event.GUILD_EDIT_POWER_LIMIT, self.onChangePower, self)
	self:registerEvent(xyd.event.GUILD_COMPETITION_GUILD_RANK, self.updateCompetitionRankInfo, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_UPGRADE_ORDER, self.onUpdateOrder, self)
	self:registerEvent(xyd.event.GUILD_DININGHALL_START_ORDER, self.onUpdateOrder, self)
end

function Guild:onUpdateOrder(event)
	local order_info = event.data.order_info

	for i = 1, #self.selfOrderList do
		local order = self.selfOrderList[i]

		if order_info.order_id == order.order_id then
			self.selfOrderList[i] = order_info

			break
		end
	end
end

function Guild.lang_sort(a, b)
	local local_lang = xyd.tables.playerLanguageTable:getIDByName(xyd.Global.lang)

	if a.language == local_lang and b.language == local_lang then
		return a.id < b.id
	elseif a.language == local_lang then
		return true
	elseif b.language == local_lang then
		return false
	else
		return a.id < b.id
	end
end

function Guild:onGuildInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	self.hasReq_ = false
	self.isLoaded_ = true
	local data = event.data
	self.self_info_ = data.self_info
	self.guild_id_ = data.self_info.guild_id or 0
	self.is_checkin_ = data.self_info.is_signed
	self.fightTime_ = data.self_info.fight_time or 0
	self.fightTimes_ = data.self_info.fight_times or 0
	self.startOrders_ = data.start_orders
	self.awardBossIds = data.self_info.award_boss_ids
	self.guild_battle_id = data.self_info.guild_battle_id or 0
	self.guildList_ = {}

	for i = 1, #event.data.guilds do
		local guild = event.data.guilds[i]
		local new_data = {
			exp = guild.exp,
			flag = guild.flag,
			name = guild.name,
			announcement = guild.announcement,
			guild_id = guild.guild_id,
			server_id = guild.server_id,
			gold = guild.gold,
			num = guild.num,
			dissolve_time = guild.dissolve_time,
			boss_id = guild.boss_id,
			recruit_time = guild.recruit_time,
			call_battle_time = guild.call_battle_time,
			is_open = guild.is_open,
			language = guild.language,
			plan = guild.plan
		}

		table.insert(self.guildList_, new_data)
	end

	local i = 1
	local length = #self.guildList_

	while i <= length do
		self.guildList_[i].id = i
		i = i + 1
	end

	table.sort(self.guildList_, self.lang_sort)

	if data.guild_info then
		self.base_info_ = data.guild_info.base_info
		self.recruit_time = self.base_info_.recruit_time
		self.logs_ = data.guild_info.logs or {}
		self.members_ = data.guild_info.members or {}
		local exp = data.guild_info.base_info.exp or 0
		self.announcement_ = data.guild_info.base_info.announcement
		self.level_ = xyd.tables.guildExpTable:getLev(exp)

		self:getJob()

		self.bossID_ = self.base_info_.boss_id or 0
		self.enlistTime = self.base_info_.call_battle_time
		self.server_id_ = data.guild_info.base_info.server_id
		self.giftbagTimes = self.base_info_.sale_share_times or 0
		self.saleLev = self.base_info_.sale_refresh_lev or 0
	end

	if self.guildJob ~= xyd.GUILD_JOB.NORMAL then
		self:reqApplyList()
	end

	if self.is_checkin_ == 0 and self.guild_id_ > 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_CHECKIN, true)
	end

	self:updateDiningHallRedMark()
	self:updateBossRedMark()
	self:updateGuildWarRedMark()
	self:updateJoinGuildRedMark()
	self:updateLogRedMark(nil)

	local update_time = self:getFightUpdateTime()

	if update_time > 0 then
		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.NEW_GUILD_BOSS_CAN_FIGHT, update_time)
	end

	local guildCompetitionInfo = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_COMPETITION)

	if guildCompetitionInfo and not guildCompetitionInfo.boss_info then
		self:getGuildCompetitionServerData()
	end

	if self.guild_id_ == 0 then
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.CLOSE_ALL_GUILD_WINDOW,
			data = {}
		})
	end
end

function Guild:getSelfServer()
	return self.server_id_ or 0
end

function Guild:getGuildBossTime()
	if self.self_info_ then
		return self.self_info_.fight_time_patch or {
			0,
			0
		}
	else
		return {
			0,
			0
		}
	end
end

function Guild:getRecruitTime()
	return self.recruit_time or 0
end

function Guild:onCreateInfo(event)
	self.isLoaded_ = true
	local data = event.data
	self.self_info_ = data.self_info
	self.guild_id_ = data.self_info.guild_id or 0
	self.is_checkin_ = data.self_info.is_signed
	self.fightTime_ = data.self_info.fight_time
	self.fightTimes_ = data.self_info.fight_times
	self.awardBossIds = data.self_info.award_boss_ids

	if data.guild_info then
		self.base_info_ = data.guild_info.base_info
		self.logs_ = data.guild_info.logs or {}
		self.members_ = data.guild_info.members or {}
		local exp = data.guild_info.base_info.exp
		self.announcement_ = data.guild_info.base_info.announcement
		self.level_ = xyd.tables.guildExpTable:getLev(exp)

		self:getJob()

		self.bossID_ = self.base_info_.boss_id or 0
		self.giftbagTimes = self.base_info_.sale_share_times or 0
		self.saleLev = self.base_info_.sale_refresh_lev or 0
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_CHECKIN, self.is_checkin_ == 0)
	xyd.models.redMark:setMark(xyd.RedMarkType.JOIN_GUILD, false)

	local guildCompetitionInfo = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_COMPETITION)

	if guildCompetitionInfo and not guildCompetitionInfo.boss_info then
		self:getGuildCompetitionServerData()
	end
end

function Guild:reqGuildInfo()
	if self.hasReq_ then
		return
	end

	if self.isLoaded_ then
		return
	end

	self.hasReq_ = true
	local msg = messages_pb:guild_get_info_req()

	xyd.Backend.get():request(xyd.mid.GUILD_GET_INFO, msg)
end

function Guild:updateDiningHallRedMark()
	local orderTime = self.self_info.order_time or 0
	local lev = xyd.tables.miscTable:getNumber("guild_order_open", "value")

	if lev <= self.level and xyd.getServerTime() >= orderTime + tonumber(xyd.tables.miscTable:getVal("guild_order_cd")) then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_ORDER, true)

		return
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_ORDER, false)
end

function Guild:updateBossRedMark()
	if self.guild_id_ <= 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_BOSS, false)

		return
	end

	if xyd.tables.miscTable:getNumber("guild_boss_max_id", "value") < self.bossID then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_BOSS, false)

		return
	end

	local updateTime = self:getFightUpdateTime()

	if updateTime < xyd.getServerTime() then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_BOSS, true)

		return
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_BOSS, false)
end

function Guild:updateGuildWarRedMark()
	local lev = xyd.tables.miscTable:getNumber("guild_war_open", "value")

	if lev <= self.level and #self.self_info.partners <= 0 and xyd.models.guildWar:judgeMoment() < xyd.models.guildWar.MOMENT.FINAL then
		xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_WAR, true)

		return
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_WAR, false)
end

function Guild:getDiningHallOrderList()
	return self.selfOrderList
end

function Guild:reqDiningHallOrderList()
	local msg = messages_pb:guild_dininghall_order_list_req()

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_ORDER_LIST, msg)
end

function Guild:onGetDiningHallOrderList(event)
	local data = event.data.order_list
	self.selfOrderList = {}
	self.startOrders_ = {}
	local i = 1

	while i <= #data do
		local order = {
			order_id = data[i].order_id,
			order_lv = data[i].order_lv,
			start_time = data[i].start_time,
			factor = data[i].factor
		}

		table.insert(self.selfOrderList, order)

		if order.start_time > 0 then
			table.insert(self.startOrders_, order)
		end

		i = i + 1
	end

	local serverTime = xyd.getServerTime()

	table.sort(self.selfOrderList, function (a, b)
		local weightA = (serverTime - a.start_time) * 10 + a.order_lv
		local weightB = (serverTime - b.start_time) * 10 + b.order_lv

		return weightA < weightB
	end)
	self:updateDiningHallRedMark()
end

function Guild:onCompleteOrder(event)
	local data = event.data
	local i = #self.startOrders_

	while i >= 1 do
		if self.startOrders_[i].order_id == data.order_id then
			table.remove(self.startOrders_, i)

			break
		end

		i = i - 1
	end

	self:updateDiningHallRedMark()
end

function Guild:onGetNewOrderList(event)
	local data = event.data.orders
	local i = #self.selfOrderList

	while i >= 1 do
		if self.selfOrderList[i].start_time == 0 then
			table.remove(self.selfOrderList, i)
		end

		i = i - 1
	end

	for _, info in ipairs(data) do
		local order = {
			order_id = info.order_id,
			order_lv = info.order_lv,
			start_time = info.start_time,
			factor = info.factor
		}

		table.insert(self.selfOrderList, order)
	end

	self.self_info_.order_time = event.data.order_time

	self:updateDiningHallRedMark()
end

function Guild:reqDiningHallUpgradeOrder(id)
	local msg = messages_pb:guild_dininghall_upgrade_order_req()
	msg.order_id = id

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_UPGRADE_ORDER, msg)
end

function Guild:reqDiningHallUpgradeAllOrder(level)
	for _, order in pairs(self.selfOrderList) do
		for i = order.order_lv, level - 1 do
			self:reqDiningHallUpgradeOrder(order.order_id)
		end
	end
end

function Guild:onDiningHallUpgradeOrder(event)
	local order_info = event.data.order_info
	local i = 0

	while i < #self.selfOrderList do
		if order_info.order_id == self.selfOrderList[i + 1].order_id then
			self.selfOrderList[i + 1].order_lv = math.max(order_info.order_lv, self.selfOrderList[i + 1].order_lv)

			break
		end

		i = i + 1
	end
end

function Guild:reqDiningHallNewOrders()
	local msg = messages_pb:guild_dininghall_new_orders_req()

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_NEW_ORDERS, msg)
end

function Guild:onDiningHallNewOrders(event)
end

function Guild:reqDiningHallStartOrder(id)
	local msg = messages_pb:guild_dininghall_start_order_req()
	msg.order_id = id

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_START_ORDER, msg)
	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.NEW_GUILD_DINING_HALL_ORDER, xyd.getServerTime() + xyd.tables.miscTable:getNumber("guild_order_cd", "value"))
end

function Guild:onDiningHallStartOrder(event)
end

function Guild:reqDiningHallDonateGold(id)
	local msg = messages_pb:guild_dininghall_donate_gold_req()
	msg.donate_index = id

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_DONATE_GOLD, msg)
end

function Guild:onDiningHallDonateGold(event)
	local data = event.data
	self.base_info_.gold = data.gold
end

function Guild:onBossInfo(event)
	local data = event.data
	local bossInfo = data.boss_info
	local bossRank = data.boss_rank
	local bossID = data.boss_id
	self.bossInfoList_[bossID] = {
		bossInfo = bossInfo,
		bossRank = bossRank
	}
end

function Guild:reqDiningHallGoldRank()
	local msg = messages_pb:guild_dininghall_gold_rank_req()

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_GOLD_RANK, msg)
end

function Guild:onDiningHallGoldRank()
end

function Guild:reqDiningHallCompleteOrder(id)
	local msg = messages_pb:guild_dininghall_complete_order_req()
	msg.order_id = id

	xyd.Backend.get():request(xyd.mid.GUILD_DININGHALL_COMPLETE_ORDER, msg)
end

function Guild:fightBoss(bossId, partners, petID, team_index)
	if not partners then
		return
	end

	local msg = messages_pb.guild_boss_fight_req()
	msg.boss_id = bossId
	msg.pet_id = petID

	if team_index and team_index > 0 then
		msg.formation_id = team_index
	else
		for _, p in pairs(partners) do
			local fightPartnerMsg = messages_pb.fight_partner()
			fightPartnerMsg.partner_id = p.partner_id
			fightPartnerMsg.pos = p.pos

			table.insert(msg.partners, fightPartnerMsg)
		end
	end

	xyd.Backend.get():request(xyd.mid.GUILD_BOSS_FIGHT, msg)
end

function Guild:isLoaded()
	return self.isLoaded_
end

function Guild:apply(id)
	local msg = messages_pb:guild_apply_req()
	msg.guild_id = id

	xyd.Backend.get():request(xyd.mid.GUILD_APPLY, msg)
end

function Guild:isApply(id)
	return self.applyList_[id]
end

function Guild:checkIn()
	if self.is_checkin_ == 1 then
		return
	end

	local msg = messages_pb:guild_checkin_req()

	xyd.Backend.get():request(xyd.mid.GUILD_CHECKIN, msg)
end

function Guild:editFlag(id)
	local msg = messages_pb:guild_edit_flag_req()
	msg.flag = id

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_FLAG, msg)

	self.base_info_.flag = id
end

function Guild:editLanguage(id)
	local msg = messages_pb:guild_edit_language_req()
	msg.language = id

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_LANGUAGE, msg)

	self.base_info_.language = id
end

function Guild:guildCreate(name, flag, announcement, lang, apply_way, power_limit, plan)
	local msg = messages_pb:guild_create_req()
	msg.name = xyd.escapesLuaString(name)
	msg.flag = flag
	msg.language = lang
	msg.announcement = xyd.escapesLuaString(announcement)
	msg.apply_way = apply_way
	msg.power_limit = power_limit
	msg.plan = plan

	print(xyd.escapesLuaString(name), flag, xyd.escapesLuaString(announcement), lang)
	xyd.Backend.get():request(xyd.mid.GUILD_CREATE, msg)
end

function Guild:guildAccpetMember(member_id)
	local msg = messages_pb:guild_accept_req()
	msg.member_id = member_id

	xyd.Backend.get():request(xyd.mid.GUILD_ACCEPT, msg)

	for i, data in ipairs(self.apply_members_) do
		local data = self.apply_members_[i]

		if data.player_id == member_id then
			__TS__ArraySplice(self.apply_members_, i, 1)

			if #self.apply_members_ == 0 then
				xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_MEMBER, false)
			end

			break
		end
	end

	self:updateLogRedMark(xyd.getServerTime() + 600)
end

function Guild:guildQuit()
	local msg = messages_pb:guild_quit_req()

	xyd.Backend.get():request(xyd.mid.GUILD_QUIT, msg)
end

function Guild:guildEditName(name)
	local msg = messages_pb:guild_edit_name_req()
	msg.name = xyd.escapesLuaString(name)

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_NAME, msg)
end

function Guild:guildDissolve()
	local msg = messages_pb:guild_dissolve_req()

	xyd.Backend.get():request(xyd.mid.GUILD_DISSOLVE, msg)
end

function Guild:guildEditAnnouncement(announcement)
	local msg = messages_pb:guild_edit_announcement_req()
	msg.announcement = xyd.escapesLuaString(announcement)

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_ANNOUNCEMENT, msg)
end

function Guild:guildCancelDissolve()
	local msg = messages_pb:guild_cancel_dissolve_req()

	xyd.Backend.get():request(xyd.mid.GUILD_CANCEL_DISSOLVE, msg)
end

function Guild:reqApplyList()
	local msg = messages_pb:guild_apply_list_req()

	xyd.Backend.get():request(xyd.mid.GUILD_APPLY_LIST, msg)
end

function Guild:refuseGuildApply(playerID)
	local msg = messages_pb:guild_delete_apply_req()
	msg.member_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_DELETE_APPLY, msg)

	local i = 1

	while i <= #self.apply_members_ do
		local data = self.apply_members_[i]

		if data.player_id == playerID then
			__TS__ArraySplice(self.apply_members_, i, 1)

			if #self.apply_members_ == 0 then
				xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_MEMBER, false)
			end

			break
		end

		i = i + 1
	end
end

function Guild:removeMember(playerID)
	local msg = messages_pb:guild_remove_req()
	msg.member_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_REMOVE, msg)
	self:updateLogRedMark(xyd.getServerTime() + 600)
end

function Guild:appointGuildLeder(playerID)
	local msg = messages_pb:guild_appoint_req()
	msg.member_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_APPOINT, msg)
	self:updateLogRedMark(xyd.getServerTime() + 600)
end

function Guild:transferGuildLeder(playerID)
	local msg = messages_pb:guild_transfer_req()
	msg.member_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_TRANSFER, msg)
	self:updateLogRedMark(xyd.getServerTime() + 600)
end

function Guild:recallGuildLeder(playerID)
	local msg = messages_pb:guild_recall_req()
	msg.member_id = playerID

	xyd.Backend.get():request(xyd.mid.GUILD_RECALL, msg)
	self:updateLogRedMark(xyd.getServerTime() + 600)
end

function Guild:reqGuildFresh()
	if self.first_init_recommend_ then
		self.first_init_recommend_ = false

		return
	end

	if #self.guildList_ <= 0 then
		local msg = messages_pb:guild_refresh_req()

		xyd.Backend.get():request(xyd.mid.GUILD_REFRESH, msg)
	else
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.GUILD_REFRESH,
			params = {}
		})
	end
end

function Guild:reqGuildSearch(name)
	local msg = messages_pb:guild_search_req()
	msg.msg = name
	self.tmpName = name

	xyd.Backend.get():request(xyd.mid.GUILD_SEARCH, msg)
end

function Guild:getTmpName()
	return self.tmpName
end

function Guild:guildRecruitTime()
	local msg = messages_pb:guild_recruit_time_req()

	xyd.Backend.get():request(xyd.mid.GUILD_RECRUIT_TIME, msg)
end

function Guild:reqBossInfo(bossID)
	local msg = messages_pb:guild_boss_info_req()
	msg.boss_id = bossID

	xyd.Backend.get():request(xyd.mid.GUILD_BOSS_INFO, msg)
end

function Guild:getBossInfo(bossID)
	return self.bossInfoList_[bossID]
end

function Guild:resetData()
	self.guild_id_ = 0
	self.level_ = 1
	self.base_info_ = {}
	self.logs_ = {}
	self.members_ = {}
	self.apply_members_ = {}
	self.guildList_ = {}
	self.applyList_ = {}
	self.is_checkin_ = 0
	self.isLoaded_ = false
	self.job_ = xyd.GUILD_JOB.NORMAL
	self.bossInfoList_ = {}
	self.fightTime_ = nil
	self.fightTimes_ = nil
end

function Guild:getJob()
	local i = 0

	while i < #self.members_ do
		local data = self.members_[i + 1]

		if data.player_id == xyd.models.selfPlayer:getPlayerID() then
			self.job_ = data.job
		end

		i = i + 1
	end
end

function Guild:onQuitGuild(event)
	self:resetData()
	self:reqGuildInfo()
end

function Guild:onEditName(event)
	self.base_info_.name = event.data.name
end

function Guild:onGuildDissolve(event)
	local data = event.data
	self.base_info.dissolve_time = data.dissolve_time
end

function Guild:onGuildCancelDissolve()
	self.base_info.dissolve_time = 0
end

function Guild:onApplyList(event)
	local members = event.data.list
	self.apply_members_ = members
	local redMarkState = members and #members > 0

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_MEMBER, redMarkState)
end

function Guild:onRefuseApply(event)
	local i = 0

	while i < #self.apply_members_ do
		i = i + 1
	end
end

function Guild:onRedMarkInfo(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if funID ~= xyd.FunctionID.GUILD then
		return
	end

	self.isLoaded_ = nil

	self:reqGuildInfo()
end

function Guild:onRemoveMember(event)
	local member_id = event.data.member_id
	local i = 0

	while i < #self.members_ do
		local member = self.members_[i + 1]

		if member_id == member.player_id then
			__TS__ArraySplice(self.apply_members_, i, 1)

			break
		end

		i = i + 1
	end
end

function Guild:onAppointGuildLeder(event)
	local member_id = event.data.member_id
	local i = 0

	while i < #self.members_ do
		local member = self.members_[i + 1]

		if member_id == member.player_id then
			self.members_[i + 1].job = xyd.GUILD_JOB.VICE_LEADER
		end

		i = i + 1
	end
end

function Guild:onTransferGuildLeder(event)
	local member_id = event.data.member_id
	local i = 0

	while i < #self.members_ do
		local member = self.members_[i + 1]

		if member_id == member.player_id then
			self.members_[i + 1].job = xyd.GUILD_JOB.LEADER
		end

		if member_id == xyd.models.selfPlayer:getPlayerID() then
			self.members_[i + 1].job = xyd.GUILD_JOB.NORMAL
		end

		i = i + 1
	end
end

function Guild:onEditAnnouncement(event)
	self.base_info_.announcement = event.data.announcement
end

function Guild:onGuildRefresh(event)
	self.guildList_ = {}

	for i = 1, #event.data.guilds do
		local guild = event.data.guilds[i]
		local new_data = {
			exp = guild.exp,
			flag = guild.flag,
			name = guild.name,
			announcement = guild.announcement,
			guild_id = guild.guild_id,
			server_id = guild.server_id,
			gold = guild.gold,
			num = guild.num,
			dissolve_time = guild.dissolve_time,
			boss_id = guild.boss_id,
			recruit_time = guild.recruit_time,
			call_battle_time = guild.call_battle_time,
			is_open = guild.is_open,
			language = guild.language
		}

		table.insert(self.guildList_, new_data)
	end

	local i = 0
	local length = #self.guildList_

	while i < length do
		self.guildList_[i + 1].id = i
		i = i + 1
	end

	table.sort(self.guildList_, self.lang_sort)
end

function Guild:onGuildCheckIn(event)
	self.is_checkin_ = 1
	self.base_info_.exp = event.data.guild_exp
	self.level_ = xyd.tables.guildExpTable:getLev(self.base_info_.exp)

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_CHECKIN, false)

	local dress_guild_buff = xyd.models.dress:getActiveSkillsNum(xyd.DressBuffAttrType.GUILD_CHECK_IN_GET)

	if dress_guild_buff and dress_guild_buff > 0 then
		XYDCo.WaitForTime(1.3, function ()
			xyd.models.dress:dressSpecialBuffTips(xyd.DressBuffAttrType.GUILD_CHECK_IN_GET)
		end, "dress_buff_guild_check_in_active")
	end
end

function Guild:onDissolve(event)
	self.base_info_.dissolve_time = event.data.dissolve_time
end

function Guild:onCancelDissolve(event)
	self.base_info_.dissolve_time = 0
end

function Guild:onRecruitTime(event)
	if event.data.recruit_time then
		self.recruit_time = event.data.recruit_time
	end
end

function Guild:reqGuildSkills()
	if #self.guildSkills_ > 0 then
		return
	end

	local msg = messages_pb:guild_get_skills_req()

	xyd.Backend.get():request(xyd.mid.GUILD_GET_SKILLS, msg)
end

function Guild:onGuildSkills(event)
	self.guildSkills_ = xyd.decodeProtoBuf(event.data).skills
	self.resetTimes_ = xyd.decodeProtoBuf(event.data).reset_times

	self:initSkills()
end

function Guild:initSkills()
	local skills = self:getGuildSkills()
	self.skillLevByID_ = {}

	for i = 1, #skills do
		local skillID = skills[i].skill_id
		self.skillLevByID_[skillID] = skills[i].skill_lv
	end
end

function Guild:getGuildSkills()
	return self.guildSkills_
end

function Guild:getSkillLevByID(skillID)
	if self.skillLevByID_[skillID] then
		return self.skillLevByID_[skillID]
	end

	return 0
end

function Guild:skillLevUp(skillID, num)
	local msg = messages_pb:guild_upgrade_skill_req()
	msg.skill_id = tonumber(skillID)
	msg.num = num

	xyd.Backend.get():request(xyd.mid.GUILD_UPGRADE_SKILL, msg)
end

function Guild:onGuildSkillLevUp(event)
	local skillID = event.data.skill_id
	local num = event.data.num

	self:updateSkillLev(skillID, num)

	local job = xyd.tables.guildSkillTable:getJob(skillID)

	if table.indexof(self.needUpdateJobs_, job) then
		xyd.models.slot:updateJobsAttr({
			job
		})
	end
end

function Guild:updateSkillLev(skillID, num, isReset)
	if isReset == nil then
		isReset = false
	end

	local skills = self:getGuildSkills()
	local i = 1

	while i <= #skills do
		if skills[i].skill_id == skillID then
			if isReset then
				skills[i].skill_lv = num
			else
				skills[i].skill_lv = skills[i].skill_lv + num
			end

			self.skillLevByID_[skillID] = skills[i].skill_lv

			break
		end

		i = i + 1
	end
end

function Guild:resetSkill(job)
	self.resetTimes_[job] = (self.resetTimes_[job] or 0) + 1
	local msg = messages_pb:guild_reset_skill_req()
	msg.job = tonumber(job)

	xyd.Backend.get():request(xyd.mid.GUILD_RESET_SKILL, msg)
end

function Guild:isResetFree(job)
	local num = self.resetTimes_[job] or 0

	return num == 0
end

function Guild:onGuildResetSkill(event)
	local skills = event.data.skills

	for _, skill in ipairs(skills) do
		self:updateSkillLev(skill.skill_id, 0, true)
	end
end

function Guild:needUpdateJobs(jobs)
	self.needUpdateJobs_ = jobs
end

function Guild:onError(event)
	local errorCode = event.data.error_code
	local errorMid = event.data.error_mid

	if errorCode == xyd.ErrorCode.GUILD_NO_EXIST then
		self:resetData()
		self:reqGuildInfo()
	end
end

function Guild:getFightCost()
	local costDataList = xyd.tables.miscTable:split2Cost("guild_boss_fight_cost", "value", "|#")
	local index = nil

	if self.fightTimes_ then
		index = self.fightTimes_ + 1
	else
		index = 1
	end

	local costData = costDataList[index]
	local costNum = nil

	if costData then
		costNum = costData[2]
	end

	local res = {
		costNum = costNum,
		fightTimes = self.fightTimes_
	}

	return res
end

function Guild:updateBossInfo(data)
	data = data.event_data
	local bossId = data.boss_id

	if self.bossInfoList_[bossId] then
		self.bossInfoList_[bossId] = nil
	end

	if tonumber(data.battle_report.isWin) == 1 then
		self.bossID_ = tonumber(data.next_id)

		table.insert(self.awardBossIds, data.boss_id)
	end

	if bossId == xyd.GUILD_FINAL_BOSS_ID then
		self.bossID_ = bossId
	end

	self.fightTime_ = tonumber(data.fight_time) or self.fightTime_
	self.fightTimes_ = tonumber(data.fight_times) or self.fightTimes_

	self:updateBossRedMark()
end

function Guild:getFightUpdateTime()
	if not self.fightTime_ or self.fightTime_ <= 0 then
		return 0
	else
		local updateTime = 0

		if self.bossID_ == xyd.GUILD_FINAL_BOSS_ID then
			updateTime = (math.floor(self.fightTime_ / 86400) + 1) * 86400
		else
			updateTime = self.fightTime_ + tonumber(xyd.tables.miscTable:getVal("guild_boss_fight_cd"))
		end

		return updateTime
	end
end

function Guild:getFinalBossLeftCount()
	local maxFightTimes = 2
	local cd = 86400
	local count = 0
	local serverTime = xyd.getServerTime()
	local curDay = math.floor(serverTime / cd)
	local fightDay = math.floor(self.fightTime_ / cd)

	if self.fightTime_ <= 0 then
		count = maxFightTimes
	elseif curDay == fightDay then
		count = math.max(maxFightTimes - (self.fightTimes_ or 0), 0)
	else
		count = maxFightTimes
	end

	return count
end

function Guild:onGuildBossBroadCast(event)
	local data = event.data

	if self.bossID_ < data.boss_id then
		self.bossInfoList_[self.bossID_] = nil
	end

	self.bossID_ = data.boss_id
	self.bossInfoList_[data.boss_id] = nil
end

function Guild:systemRefresh()
	self.isLoaded_ = nil

	self:reqGuildInfo()
end

function Guild:updateJoinGuildRedMark()
	local joinGuildRedMark = self.guild_id_ <= 0 and xyd.checkFunctionOpen(xyd.FunctionID.GUILD, true)

	xyd.models.redMark:setMark(xyd.RedMarkType.JOIN_GUILD, joinGuildRedMark)
end

function Guild:setGuideFlag()
	local msg = messages_pb:guild_set_guide_flag_req()

	xyd.Backend.get():request(xyd.mid.GUILD_SET_GUIDE_FLAG, msg)

	self.self_info_.guide_flag = 1
end

function Guild:getOnlineCount()
	local mem = self.members
	local cnt = 0
	local i = 1

	while i <= #self.members do
		local data = mem[i].is_online

		if data == 1 then
			cnt = cnt + 1
		end

		i = i + 1
	end

	return cnt
end

function Guild:updateLogRedMark(cur_time)
	if cur_time then
		local i = 1

		while i <= #self.logs do
			local log = self.logs[i]
			cur_time = math.max(log.time, cur_time)
			i = i + 1
		end

		xyd.db.misc:setValue({
			key = "guild_log_read_time",
			value = cur_time
		})
	else
		cur_time = tonumber(xyd.db.misc:getValue("guild_log_read_time"))
	end

	local i = 1

	while i <= #self.logs do
		local log = self.logs[i]

		if cur_time == nil or cur_time < log.time then
			if self.guildJob ~= xyd.GUILD_JOB.NORMAL then
				xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_LOG, true)
			end

			return
		end

		i = i + 1
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_LOG, false)
end

function Guild:getLuckStatus()
	if not self.self_info then
		return 0
	end

	return self.self_info.is_device_lucky or 0
end

function Guild:setLuckStatus(status)
	self.self_info.is_device_lucky = status
end

function Guild:reqIsLuck()
	if self.luck_req_count_ > 2 then
		return
	end

	local msg = messages_pb:get_lucky_status_req()

	xyd.Backend.get():request(xyd.mid.GET_LUCKY_STATUS, msg)

	self.luck_req_count_ = self.luck_req_count_ + 1
end

function Guild:getBaseInfo()
	return self.base_info_
end

function Guild:checkLuckyDevice(event)
	if not self.self_info then
		self.self_info_ = {}
	end

	self.self_info_.is_device_lucky = event.data.is_device_lucky
end

function Guild:initGuildCompetitionInfo(guildCompetitionInfo)
	if guildCompetitionInfo and guildCompetitionInfo.boss_info and not self.guildCompetitionInfo then
		self.guildCompetitionInfo = {}

		self:updateGuildCompetitionInfo(guildCompetitionInfo)
	end
end

function Guild:updateGuildCompetitionInfo(info)
	if not info or info and not info.boss_info then
		return
	end

	if not self.guildCompetitionInfo then
		self:initGuildCompetitionInfo(info)

		return
	end

	if info then
		self.guildCompetitionInfo.boss_harms = info.boss_harms
		self.guildCompetitionInfo.boss_info = info.boss_info
		local json = require("cjson")
		self.guildCompetitionInfo.boss_info.enemies = json.decode(self.guildCompetitionInfo.boss_info.enemies)
		self.guildCompetitionInfo.times = info.times
		self.guildCompetitionInfo.total_harm = info.total_harm
		self.guildCompetitionInfo.update_time = info.update_time

		if info.guild_rank then
			self.guildCompetitionInfo.guild_rank = info.guild_rank.rank
			self.guildCompetitionInfo.guild_rank_sum = info.guild_rank.sum
		end
	end

	self:updateGuildCompetitionTerritoryWindow()
	self:updateGuildCompetitionMainWindow()

	if self:getGuildCompetitionInfo() then
		if self:getGuildCompetitionLeftTime().type == 2 then
			if tonumber(self.guildCompetitionInfo.times) < xyd.tables.miscTable:getNumber("guild_competition_personal_limit", "value") then
				xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_COMPETITION, true)
			else
				xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_COMPETITION, false)
			end
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.GUILD_COMPETITION, false)
		end
	end
end

function Guild:updateGuildCompetitionMainWindow()
	local guildCompetitionMainWd = xyd.WindowManager.get():getWindow("guild_competition_main_window")

	if guildCompetitionMainWd then
		guildCompetitionMainWd:updateBaseShow()
	end
end

function Guild:updateGuildCompetitionTerritoryWindow()
	local guildCompetitionTerritoryWindow = xyd.WindowManager.get():getWindow("guild_territory_window")

	if guildCompetitionTerritoryWindow then
		guildCompetitionTerritoryWindow:updateGuildCompetitionTime()
	end
end

function Guild:getGuildCompetitionInfo()
	return self.guildCompetitionInfo
end

function Guild:getGuildCompetitionLeftTime()
	local guildCompetitionData = xyd.models.activity:getActivity(xyd.ActivityID.GUILD_COMPETITION)

	if guildCompetitionData and guildCompetitionData:startTime() <= xyd.getServerTime() then
		local dayArr = xyd.tables.miscTable:split2num("guild_competition_time", "value", "|")
		local type = -1
		local curStartTime = guildCompetitionData:startTime()
		local day_seconds = 86400
		local curEndTime = curStartTime + dayArr[1] * day_seconds + dayArr[2] * day_seconds + dayArr[3] * day_seconds

		if xyd.getServerTime() < curStartTime + dayArr[1] * day_seconds then
			type = 1
			curEndTime = curStartTime + dayArr[1] * day_seconds
		elseif xyd.getServerTime() < curStartTime + dayArr[1] * day_seconds + dayArr[2] * day_seconds then
			type = 2
			curEndTime = curStartTime + dayArr[1] * day_seconds + dayArr[2] * day_seconds
		elseif xyd.getServerTime() < curStartTime + dayArr[1] * day_seconds + dayArr[2] * day_seconds + dayArr[3] * day_seconds then
			type = 3
		end

		return {
			type = type,
			curEndTime = curEndTime,
			endTime = curStartTime + dayArr[1] * day_seconds + dayArr[2] * day_seconds + dayArr[3] * day_seconds
		}
	else
		return {
			endTime = 0,
			curEndTime = 0,
			type = -1
		}
	end
end

function Guild:getGuildCompetitionServerData()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.GUILD_COMPETITION)
end

function Guild:getGuildCompetitionBossPress(index)
	local roundIndex = tonumber(self:getGuildCompetitionInfo().boss_info.enemy_lvs[index])
	local allBlood = 0
	local curBlood = 0
	local bossTable = xyd.tables.guildCompetitionBossTable
	local battleId = bossTable["getBattleId" .. index](bossTable, roundIndex)
	local monsters = xyd.tables.battleTable:getMonsters(battleId)

	for i in pairs(monsters) do
		allBlood = allBlood + xyd.tables.monsterTable:getHp(monsters[i])
	end

	for i, hp in pairs(self:getGuildCompetitionInfo().boss_info.enemies[index]) do
		curBlood = curBlood + hp
	end

	local provalue = curBlood / allBlood
	provalue = xyd.checkCondition(provalue > 1, 1, provalue)

	return {
		provalue = provalue,
		curBlood = curBlood,
		allBlood = allBlood
	}
end

function Guild:setGuildCompetitionFight(boss_id, type, partners, petID)
	local msg = messages_pb:guild_competition_battle_req()
	msg.boss_id = boss_id
	msg.activity_id = xyd.ActivityID.GUILD_COMPETITION

	for _, v in pairs(partners) do
		table.insert(msg.partners, self:addMsgPartners(v))
	end

	msg.pet_id = petID
	msg.type = type

	xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_BATTLE, msg)
end

function Guild:addMsgPartners(info)
	local PartnersMsg = messages_pb:partners_info()
	PartnersMsg.partner_id = info.partner_id
	PartnersMsg.pos = info.pos

	return PartnersMsg
end

function Guild:guildCometitionBattleBack(info)
	if self.guildCompetitionInfo then
		local json = require("cjson")
		self.guildCompetitionInfo.boss_info = info.boss_info
		self.guildCompetitionInfo.boss_info.enemies = json.decode(self.guildCompetitionInfo.boss_info.enemies)
		local guildCompetitionMainWd = xyd.WindowManager.get():getWindow("guild_competition_main_window")

		if guildCompetitionMainWd then
			guildCompetitionMainWd:updatePersonGroup(info.boss_id)
		end

		self.guildCompetitionInfo.times = self.guildCompetitionInfo.times + 1

		if self.guildCompetitionInfo.times > #xyd.tables.guildCompetitionBossTable:getIds() then
			self.guildCompetitionInfo.times = #xyd.tables.guildCompetitionBossTable:getIds()
		end

		if info.guild_rank then
			self.guildCompetitionInfo.guild_rank = info.guild_rank.rank
			self.guildCompetitionInfo.guild_rank_sum = info.guild_rank.sum
		end
	end

	self:updateGuildCompetitionMainWindow()
end

function Guild:updateCompetitionRankInfo(event)
	if self.guildCompetitionInfo then
		local info = xyd.decodeProtoBuf(event.data)
		self.guildCompetitionInfo.guild_rank = info.self_rank
		self.guildCompetitionInfo.guild_rank_sum = info.sum
		local guildCompetitionMainWd = xyd.WindowManager.get():getWindow("guild_competition_main_window")

		if guildCompetitionMainWd then
			guildCompetitionMainWd:updateRank()
		end
	end
end

function Guild:reqChangePlan(plan)
	local msg = messages_pb:guild_edit_plan_req()
	msg.plan = plan
	self.tmpPlan = plan

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_PLAN, msg)
end

function Guild:onChangePlan()
	self.base_info_.plan = self.tmpPlan
	self.tmpPlan = nil
end

function Guild:reqChangeApplyWay(way)
	local msg = messages_pb.guild_edit_apply_way_req()
	msg.apply_way = way
	self.tmpWay = way

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_APPLY_WAY, msg)
end

function Guild:onChangeWay()
	self.base_info_.apply_way = self.tmpWay
	self.tmpWay = nil
end

function Guild:reqChangePower(power_limit)
	local msg = messages_pb:guild_edit_power_limit_req()
	msg.power_limit = power_limit
	self.tmpLimit = power_limit

	xyd.Backend.get():request(xyd.mid.GUILD_EDIT_POWER_LIMIT, msg)
end

function Guild:onChangePower()
	self.base_info_.power_limit = self.tmpLimit
	self.tmpLimit = nil
end

return Guild
