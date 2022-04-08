local BaseModel = import(".BaseModel")
local FairArena = class("FairArena", BaseModel)
local Partner = import("app.models.Partner")
local json = require("cjson")
local PartnerBoxTable = xyd.tables.activityFairArenaBoxPartnerTable
local ArtifactBoxTable = xyd.tables.activityFairArenaBoxEquipTable
local RobotTable = xyd.tables.activityFairArenaRobotTable

function FairArena:ctor()
	FairArena.super.ctor(self)
end

function FairArena:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetData))
	self:registerEvent(xyd.event.FAIR_ARENA_EXPLORE, handler(self, self.onExplore))
	self:registerEvent(xyd.event.FAIR_ARENA_SELECT, handler(self, self.onSelect))
	self:registerEvent(xyd.event.FAIR_ARENA_BATTLE, handler(self, self.onBattle))
	self:registerEvent(xyd.event.FAIR_ARENA_RESET, handler(self, self.onReset))
	self:registerEvent(xyd.event.FAIR_ARENA_EQUIP, handler(self, self.onEquip))
end

function FairArena:reqArenaInfo()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
end

function FairArena:reqExplore(type)
	local msg = messages_pb.fair_arena_explore_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA
	msg.operate = type

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_EXPLORE, msg)

	if type == xyd.FairArenaType.NORMAL or type == xyd.FairArenaType.TEST then
		xyd.db.misc:setValue({
			value = "1",
			key = "is_can_show_first_equip_red_point"
		})

		local fair_arena_explore_wd = xyd.WindowManager.get():getWindow("fair_arena_explore_window")

		if fair_arena_explore_wd then
			fair_arena_explore_wd:checkShowEquipRedPoint()
		end
	end
end

function FairArena:reqSelect(partners, equips, buffs)
	__TRACE("從哪進來的222")

	local msg = messages_pb.fair_arena_select_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA

	for i = 1, #partners do
		table.insert(msg.partners, partners[i])
	end

	if equips then
		msg.equips = equips
	end

	if buffs then
		msg.buffs = buffs
	end

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_SELECT, msg)
end

function FairArena:reqReset(type, id, table_id)
	local msg = messages_pb.fair_arena_reset_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA
	msg.type = type
	msg.partner_id = id
	msg.table_id = table_id

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_RESET, msg)
end

function FairArena:reqEquip(partner_id, equip_id)
	local msg = messages_pb.fair_arena_equip_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA
	msg.partner_id = partner_id
	msg.equip_id = equip_id

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_EQUIP, msg)
end

function FairArena:reqRank()
	local msg = messages_pb.fair_arena_rank_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_RANK, msg)
end

function FairArena:reqGetReport(id, enemy_infos)
	local msg = messages_pb.fair_arena_get_report_req()
	self.reportEnemyInfos = enemy_infos
	msg.activity_id = xyd.ActivityID.ACTIVITY_FAIR_ARENA
	msg.id = id

	xyd.Backend.get():request(xyd.mid.FAIR_ARENA_GET_REPORT, msg)
end

function FairArena:onGetData(event)
	local data = event.data

	if event and event.data.act_info.activity_id ~= xyd.ActivityID.ACTIVITY_FAIR_ARENA then
		return
	end

	local detail = json.decode(data.act_info.detail)

	self:updateArenaInfo(detail)
end

function FairArena:onExplore(event)
	local data = event.data
	self.operate = data.operate

	self:updateArenaInfo(data.info)

	if self.operate == xyd.FairArenaType.BUY_HOE then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)

		if activityData then
			xyd.models.redMark:setMark(xyd.RedMarkType.FAIR_ARENA, activityData:getRedMarkState())
		end

		local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_num = 1,
				item_id = cost_id
			}
		})
	end
end

function FairArena:onSelect(event)
	local data = event.data

	self:updateArenaInfo(data.info)

	if self.isCheckGetNewEquip then
		local isCanShowFirstEquipRedPoint = xyd.db.misc:getValue("is_can_show_first_equip_red_point")

		if isCanShowFirstEquipRedPoint and isCanShowFirstEquipRedPoint == "1" then
			xyd.db.misc:setValue({
				value = "2",
				key = "is_can_show_first_equip_red_point"
			})

			local fair_arena_explore_wd = xyd.WindowManager.get():getWindow("fair_arena_explore_window")

			if fair_arena_explore_wd then
				fair_arena_explore_wd:checkShowEquipRedPoint()
			end
		end

		self.isCheckGetNewEquip = false
	end
end

function FairArena:onBattle(event)
	local data = event.data
	self.old_enemy_infos = self.data.enemy_infos

	self:updateArenaInfo(data.info)
end

function FairArena:onReset(event)
	local data = event.data

	self:updateArenaInfo(data.info)
end

function FairArena:onEquip(event)
	local data = event.data

	self:updateArenaInfo(data.info)

	local fair_arena_battle_formation_wd = xyd.WindowManager.get():getWindow("fair_arena_battle_formation_window")

	if fair_arena_battle_formation_wd then
		fair_arena_battle_formation_wd:updateForceNum()
	end
end

function FairArena:updateArenaInfo(info)
	if not self.data then
		self.data = {}
	end

	self.data = {
		explore_times = info.explore_times or 0,
		times = info.times,
		test_times = info.test_times,
		fail_times = info.fail_times,
		explore_type = info.explore_type,
		explore_stage = info.explore_stage,
		is_fail = info.is_fail or 0,
		partners = info.partners,
		equips = info.equips,
		buffs = info.buffs,
		score = info.score,
		cur_history = info.cur_history,
		history_explore = info.history_explore,
		enemy_infos = info.enemy_infos,
		box_partners = info.box_partners,
		box_equips = info.box_equips,
		box_buffs = info.box_buffs,
		self_rank = info.self_rank,
		history_rank = info.history_rank
	}

	if self.data.buy_times then
		self.data.buy_times = info.buy_times or self.data.buy_times
	else
		self.data.buy_times = info.buy_times or 0
	end

	self:initPartners()
	self:updateTimeHoe()
end

function FairArena:getArenaInfo()
	return self.data or xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA).detail
end

function FairArena:initPartners()
	self.partnerIds = {}
	self.partners = {}
	self.equips = {}
	local partners = self.data.partners
	local equips = self.data.equips

	for i = 1, #equips do
		self.equips[i] = {
			id = equips[i]
		}
	end

	for i = 1, #partners do
		local partner_id = i
		local table_id = partners[i].partner_id
		local equips = PartnerBoxTable:getEquips(table_id)

		if partners[i].equip and partners[i].equip > 0 then
			equips[6] = ArtifactBoxTable:getEquipID(self.equips[partners[i].equip].id)
			self.equips[partners[i].equip].table_id = PartnerBoxTable:getPartnerID(table_id)
			self.equips[partners[i].equip].partner_id = partner_id
		end

		local p = Partner.new()

		p:populate({
			isHeroBook = true,
			table_id = PartnerBoxTable:getPartnerID(table_id),
			lev = PartnerBoxTable:getLv(table_id),
			grade = PartnerBoxTable:getGrade(table_id),
			equips = equips,
			partner_id = partner_id
		})

		p.box_table_id = table_id
		p.equip_index = partners[i].equip or 0

		table.insert(self.partners, p)
		table.insert(self.partnerIds, partner_id)
	end

	table.sort(self.partnerIds)
end

function FairArena:getPartners()
	return self.partners
end

function FairArena:getPartnerIds()
	return self.partnerIds
end

function FairArena:getBuffs()
	return self.data.buffs or {}
end

function FairArena:getEquips()
	return self.equips
end

function FairArena:getPartnerByID(id)
	return self.partners[id]
end

function FairArena:getEnemyInfo()
	return self.data.enemy_infos
end

function FairArena:getHoeBuyTimes()
	return self.data.buy_times
end

function FairArena:getSelfInfo()
	return {
		player_name = xyd.Global.playerName,
		lev = xyd.models.backpack:getLev(),
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		server_id = xyd.models.selfPlayer:getServerID()
	}
end

function FairArena:getOldEnemyInfo()
	local infos = self.old_enemy_infos or {}

	return self:makeEnemyInfo(infos)
end

function FairArena:getReportEnemyInfo()
	local infos = self.reportEnemyInfos or {}

	return self:makeEnemyInfo(infos)
end

function FairArena:checkTest()
	return self.data.explore_type == 2
end

function FairArena:readStorageFormation()
	local dbVal = xyd.db.formation:getValue(xyd.BattleType.FAIR_ARENA)

	if not dbVal then
		return false
	end

	local data = require("cjson").decode(dbVal)

	if not data.partners then
		return false
	end

	local nowPartnerList = {}
	local tmpPartnerList = data.partners

	for i = #tmpPartnerList, 1, -1 do
		local sPartnerID = tonumber(tmpPartnerList[i]) or 0
		nowPartnerList[i] = sPartnerID
	end

	return nowPartnerList
end

function FairArena:saveLocalformation(formation)
	local dbParams = {
		value = json.encode(formation),
		key = xyd.BattleType.FAIR_ARENA
	}

	xyd.db.formation:addOrUpdate(dbParams)
end

function FairArena:makeEnemyInfo(infos)
	local player_name, lev, avatar_id, avatar_frame_id, server_id = nil

	if infos.robot_id then
		local id = infos.robot_id
		player_name = RobotTable:getName(id)
		lev = RobotTable:getLev(id)
		avatar_id = RobotTable:getAvatar(id)
		avatar_frame_id = 0
		server_id = xyd.models.selfPlayer:getServerID()
	elseif infos.player_info then
		player_name = infos.player_info.player_name
		lev = infos.player_info.lev
		avatar_id = infos.player_info.avatar_id
		avatar_frame_id = infos.player_info.avatar_frame_id or 0
		server_id = infos.player_info.server_id
	end

	return {
		player_name = player_name,
		lev = lev,
		avatar_id = avatar_id,
		avatar_frame_id = avatar_frame_id,
		server_id = server_id
	}
end

function FairArena:getEndTime()
	return xyd.getServerTime() + 10080
end

function FairArena:getActBuffID(partners)
	local actBuffID = 0
	local groupNum = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local tNum = 0

	for _, p in ipairs(partners) do
		local group = p:getGroup()

		if not groupNum[group] then
			groupNum[group] = 0
		end

		groupNum[group] = groupNum[group] + 1
		tNum = tNum + 1
	end

	if not self.buffDataList then
		self.buffDataList = {}
		local buffIds = xyd.tables.groupBuffTable:getIds()

		for i, buffId in ipairs(buffIds) do
			table.insert(self.buffDataList, tonumber(buffId))
		end

		table.sort(self.buffDataList)
	end

	for i = 1, #self.buffDataList do
		local buffId = self.buffDataList[i]
		local groupDataList = xyd.split(xyd.tables.groupBuffTable:getGroupConfig(buffId), "|")
		local type = xyd.tables.groupBuffTable:getType(buffId)
		local isNewAct = true

		if tonumber(type) == 1 then
			for _, gi in ipairs(groupDataList) do
				local giList = xyd.split(gi, "#")

				if tonumber(groupNum[tonumber(giList[1])]) ~= tonumber(giList[2]) then
					isNewAct = false

					break
				end
			end
		elseif tonumber(type) == 2 then
			local numCount = {}

			for num, _ in ipairs(groupNum) do
				if not numCount[groupNum[num]] then
					numCount[groupNum[num]] = 0
				end

				if tonumber(num) < 5 then
					numCount[groupNum[num]] = numCount[groupNum[num]] + 1
				end
			end

			if groupNum[5] + groupNum[6] == 3 and numCount[1] == 3 then
				isNewAct = true
			else
				isNewAct = false
			end
		end

		if isNewAct then
			actBuffID = buffId

			break
		end
	end

	return actBuffID
end

function FairArena:checkGetNewEquip()
	self.isCheckGetNewEquip = true
end

function FairArena:updateTimeHoe()
	local free_get_arr = xyd.tables.miscTable:split2Cost("fair_arena_free", "value", "|#", true)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)

	if not activityData then
		return
	end

	local start_time = activityData:startTime()
	local count_time = activityData:getEndTime() - xyd.DAY_TIME
	local can_get = false

	for i, data in pairs(free_get_arr) do
		if start_time <= xyd.getServerTime() and xyd.getServerTime() < start_time + (data[1] - 1) * xyd.DAY_TIME then
			count_time = start_time + (data[1] - 1) * xyd.DAY_TIME
			can_get = true

			break
		end
	end

	local duration = count_time - xyd.getServerTime()

	if duration > 0 and can_get then
		if self.globalTimeCount then
			xyd.removeGlobalTimer(self.globalTimeCount)

			self.globalTimeCount = nil
		end

		self.globalTimeCount = xyd.addGlobalTimer(function ()
			xyd.models.fairArena:reqArenaInfo()
			self:updateTimeHoe()
			xyd.models.redMark:setMark(xyd.RedMarkType.FAIR_ARENA, activityData:getRedMarkState())
		end, duration + 2, 1)
	end

	local end_show_time = xyd.getServerTime() - count_time

	if not self.showTimeCount and end_show_time > 0 then
		self.showTimeCount = xyd.addGlobalTimer(function ()
			local fair_arena_entry_wd = xyd.WindowManager.get():getWindow("fair_arena_entry_window")

			if fair_arena_entry_wd then
				xyd.WindowManager.get():closeWindow("fair_arena_entry_window")
				xyd.WindowManager.get():openWindow("fair_arena_entry_window", {
					needReqData = true
				})
			end

			local fair_arena_explore_wd = xyd.WindowManager.get():getWindow("fair_arena_explore_window")

			if fair_arena_explore_wd then
				xyd.WindowManager.get():closeWindow("fair_arena_explore_window")
				xyd.WindowManager.get():openWindow("fair_arena_entry_window", {
					needReqData = true
				})
			end
		end, end_show_time + 2, 1)
	end
end

return FairArena
