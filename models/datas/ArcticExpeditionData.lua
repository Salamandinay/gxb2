local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ArcticExpeditionData = class("ArcticExpeditionData", ActivityData, true)

function ArcticExpeditionData:ctor(params)
	ArcticExpeditionData.super.ctor(self, params)

	self.cellInfoReqTimeList = {}
	self.rankList_ = {}
	self.refreshRankTime_ = {}
	self.partnerInfo_ = {}
end

function ArcticExpeditionData:getUpdateTime()
	return self:getEndTime()
end

function ArcticExpeditionData:getEraNow()
	return self.detail_.map_id
end

function ArcticExpeditionData:getSelfGroup()
	return self.detail_.group
end

function ArcticExpeditionData:getStaNum()
	return self.detail_.sta
end

function ArcticExpeditionData:getEra()
	return self.detail_.era or 1
end

function ArcticExpeditionData:getScore()
	return self.detail_.score
end

function ArcticExpeditionData:arcticExpeditionBattle(partnerParams, pet, cell_id)
	local msg = messages_pb.arctic_expedition_battle_req()
	msg.pet_id = pet
	msg.cell_id = cell_id
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
	local fightPartnerList = {}

	for _, info in ipairs(partnerParams) do
		local fightPatner = messages_pb.fight_partner()
		fightPatner.partner_id = info.partner_id
		fightPatner.pos = info.pos
		fightPartnerList[tonumber(info.pos)] = info.partner_id

		table.insert(msg.partners, fightPatner)
	end

	self.fightPartnerList = fightPartnerList
	local cellInfo = self:getCellInfo(cell_id)

	if self:getSelfGroup() ~= cellInfo.group then
		self.isMine_ = false
		self.tempNum_ = cellInfo.num
	else
		self.isMine_ = true
	end

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_BATTLE, msg)
end

function ArcticExpeditionData:getBattleShowType()
	return self.isMine_, self.tempNum_
end

function ArcticExpeditionData:reqChatMsg(channel)
	if self.hasReqChat then
		return
	end

	self.hasReqChat = true
	local msg = messages_pb.arctic_expedition_chat_msg_req()
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
	msg.get_self = 1

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_CHAT_MSG, msg)
end

function ArcticExpeditionData:reqChatContent()
	local msg = messages_pb.arctic_expedition_chat_req()
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
	msg.show_vip = 0
	msg.content = " "

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_CHAT, msg)
end

function ArcticExpeditionData:reqCellRally(cell_id)
	local msg = messages_pb.arctic_expedition_rally_req()
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
	msg.cell_id = cell_id

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_RALLY, msg)
end

function ArcticExpeditionData:getFightPartnerList()
	return self.fightPartnerList
end

function ArcticExpeditionData:checkRallyTime()
	local rallyTimes = self.detail_["rally" .. self:getSelfGroup()] or {}

	table.sort(rallyTimes, function (a, b)
		return a < b
	end)

	if not rallyTimes[3] or xyd.getServerTime() - rallyTimes[3] > 3600 then
		return true
	else
		return false
	end
end

function ArcticExpeditionData:changePartnerFine(partner_id, change_num)
	if self.partnerInfo_[tostring(partner_id)] then
		self.partnerInfo_[tostring(partner_id)] = tonumber(self.partnerInfo_[tostring(partner_id)]) + change_num

		if self.partnerInfo_[tostring(partner_id)] <= 0 then
			self.partnerInfo_[tostring(partner_id)] = 0
		end
	else
		self.partnerInfo_[tostring(partner_id)] = 23
	end
end

function ArcticExpeditionData:getCellBuffAround(cell_id)
	local cellPos = xyd.tables.arcticExpeditionCellsTable:getCellPos(cell_id)
	local cellList = {}
	local cellList2 = {}
	local cellList3 = {}
	local buffList = {}

	xyd.tables.arcticExpeditionCellsTable:getCellAroud1(cellPos, cellList)

	for key, value in pairs(cellList) do
		if value == 1 then
			local type = xyd.tables.arcticExpeditionCellsTable:getCellType(tonumber(key))
			local buffs = xyd.tables.arcticExpeditionCellsTypeTable:getMapBuffs(type) or {}

			if buffs[1] and self:getCellInfo(tonumber(key)).group == self:getSelfGroup() then
				table.insert(buffList, buffs[1])
			end
		end
	end

	for key, value in pairs(cellList) do
		if value == 1 and tonumber(key) > 0 then
			local pos = xyd.tables.arcticExpeditionCellsTable:getCellPos(tonumber(key))

			xyd.tables.arcticExpeditionCellsTable:getCellAroud1(pos, cellList2)
		end
	end

	for key, value in pairs(cellList2) do
		if cellList[key] == 1 then
			cellList2[key] = nil
		end
	end

	for key, value in pairs(cellList2) do
		if value == 1 then
			local type = xyd.tables.arcticExpeditionCellsTable:getCellType(tonumber(key))
			local buffs = xyd.tables.arcticExpeditionCellsTypeTable:getMapBuffs(type) or {}

			if buffs[2] and self:getCellInfo(tonumber(key)).group == self:getSelfGroup() then
				table.insert(buffList, buffs[2])
			end
		end
	end

	for key, value in pairs(cellList2) do
		if value == 1 and tonumber(key) > 0 then
			local pos = xyd.tables.arcticExpeditionCellsTable:getCellPos(tonumber(key))

			xyd.tables.arcticExpeditionCellsTable:getCellAroud1(pos, cellList3)
		end
	end

	for key, value in pairs(cellList3) do
		if cellList2[key] == 1 or cellList[key] == 1 then
			cellList3[key] = nil
		end
	end

	for key, value in pairs(cellList3) do
		if value == 1 then
			local type = xyd.tables.arcticExpeditionCellsTable:getCellType(tonumber(key))
			local buffs = xyd.tables.arcticExpeditionCellsTypeTable:getMapBuffs(type) or {}

			if buffs[3] and self:getCellInfo(tonumber(key)).group == self:getSelfGroup() then
				table.insert(buffList, buffs[3])
			end
		end
	end

	cellList[cell_id] = 0

	table.sort(buffList)

	return buffList
end

function ArcticExpeditionData:reqMapInfo()
	if not self.mapInfo_ or not self.reqMapTime or xyd.getServerTime() - tonumber(self.reqMapTime) > 60 then
		local msg = messages_pb.arctic_expedition_get_map_info_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_MAP_INFO, msg)

		self.reqMapTime = xyd.getServerTime()

		return true
	else
		return false
	end
end

function ArcticExpeditionData:reqCellInfo(cell_id, needUpdate)
	if not self.cellInfoReqTimeList[cell_id] or xyd.getServerTime() - self.cellInfoReqTimeList[cell_id] > 60 or needUpdate then
		local msg = messages_pb.arctic_expedition_cell_info_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
		msg.cell_id = cell_id

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_CELL_INFO, msg)

		self.cellInfoReqTimeList[cell_id] = xyd.getServerTime()

		return true
	else
		return false
	end
end

function ArcticExpeditionData:reqBattleDetail(record_ids)
	local msg = messages_pb.arctic_expedition_records_req()
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION

	for index, id in ipairs(record_ids) do
		table.insert(msg.record_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_RECORDS, msg)
end

function ArcticExpeditionData:reqTimeMissionInfo(must_refresh)
	local reqTime = self.reqMissionTime_

	if not reqTime or xyd.getServerTime() - tonumber(reqTime) < 60 or must_refresh then
		local msg = messages_pb.arctic_expedition_get_mission_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
		msg.group = self:getSelfGroup()

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_MISSION, msg)

		self.reqMissionTime_ = xyd.getServerTime()

		return true
	end

	return false
end

function ArcticExpeditionData:getArcPartnerInfos()
	if self.reqPartnerTime and xyd.getServerTime() - self.reqPartnerTime < 60 then
		return false
	end

	local msg = messages_pb.arctic_expedition_get_pr_infos_req()
	msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION

	xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_PR_INFOS, msg)

	self.reqPartnerTime = xyd.getServerTime()

	return true
end

function ArcticExpeditionData:reqRankList(group, self_only)
	group = group or self:getSelfGroup()

	if self_only then
		self.selfOnly_ = true
		self.tmpRequiredGroup = group
		local msg = messages_pb.arctic_expedition_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
		msg.group = group
		msg.self_only = self_only

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_RANK_LIST, msg)

		return
	end

	if not self.refreshRankTime_[group] or xyd.getServerTime() - self.refreshRankTime_[group] > 60 then
		self.tmpRequiredGroup = group
		local msg = messages_pb.arctic_expedition_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.ARCTIC_EXPEDITION
		msg.group = group

		xyd.Backend.get():request(xyd.mid.ARCTIC_EXPEDITION_GET_RANK_LIST, msg)

		self.refreshRankTime_[group] = xyd.getServerTime()

		return true
	else
		return false
	end
end

function ArcticExpeditionData:checkCanFightTime()
	if xyd.getServerTime() - self.start_time < xyd.DAY_TIME or xyd.getServerTime() - self.start_time >= 13 * xyd.DAY_TIME then
		return false
	else
		return true
	end
end

function ArcticExpeditionData:getRankList(group)
	group = group or self:getSelfGroup()

	return self.rankList_[group] or {}
end

function ArcticExpeditionData:getSelfAwardData()
	local group = self:getSelfGroup()
	local rankData = self.rankList_[group]

	return {
		self_rank = rankData.self_rank,
		self_score = rankData.self_score
	}
end

function ArcticExpeditionData:needUpdateMissionInfo()
	return false
end

function ArcticExpeditionData:register()
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_GET_MAP_INFO, function (event)
		local infos = {}

		for index, info in ipairs(event.data.map_infos) do
			local cell_id = info.table_id
			infos[cell_id] = info
		end

		self.mapInfo_ = infos
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_CELL_INFO, function (event)
		local cell_info = xyd.decodeProtoBuf(event.data)
		local cell_id = cell_info.table_id

		if not self.mapInfo_ then
			self.mapInfo_ = {}
		end

		self.mapInfo_[tonumber(cell_id)] = cell_info
		self.cellInfoReqTimeList[tonumber(cell_id)] = xyd.getServerTime()
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_BATTLE, function (event)
		self.refreshRankTime_[0] = 0
		self.refreshRankTime_[self:getSelfGroup()] = 0
		local cellInfo = event.data.info
		self.detail_.sta = event.data.sta
		self.detail_.score = event.data.score + self.detail_.score
		local cell_id = cellInfo.table_id
		self.mapInfo_[tonumber(cell_id)] = cellInfo

		self:getRedMarkState()
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_GET_PR_INFOS, function (event)
		local pr_info = json.decode(event.data.pr_infos)
		self.partnerInfo_ = pr_info
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_GET_MISSION, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		self.timeMissionValue = data.values
		self.timeMissionCompeted = data.is_completeds
		self.detail_.era = data.era

		for i = 1, 3 do
			self.detail_["group_score" .. i] = data["group" .. i]
			self.detail_["last_score" .. i] = data["last" .. i]
			self.detail_["rally" .. i] = data["rally" .. i]
		end
	end)
	self:registerEvent(xyd.event.BOSS_BUY, function (event)
		if event.data.activity_id ~= xyd.ActivityID.ARCTIC_EXPEDITION then
			return
		end

		local buy_times = event.data.buy_times
		self.detail_.sta = self.detail_.sta + buy_times - self.detail_.buy_times
		self.detail_.buy_times = buy_times

		self:getRedMarkState()
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_GET_RANK_LIST, function (event)
		if not self.selfOnly_ then
			self.rankList_[self.tmpRequiredGroup] = xyd.decodeProtoBuf(event.data)
			self.tmpRequiredGroup = nil
		end
	end)
	self:registerEvent(xyd.event.SYS_BROADCAST, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local cell_id = data.table_id

		if cell_id and cell_id > 0 and xyd.SysBroadcast.ACTIVITY_EXPEDITION == data.broadcast_type then
			self:reqCellInfo(cell_id, true)
			self:reqTimeMissionInfo(true)
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local id = event.data.act_info.activity_id

		if id == xyd.ActivityID.ARCTIC_EXPEDITION then
			self:getRedMarkState()

			local win = xyd.WindowManager.get():getWindow("arctic_expedition_main_window")

			if win then
				win:updateMissionRed()
			end
		end
	end)
	self:registerEvent(xyd.event.RED_POINT, function (event)
		if tonumber(event.data.function_id) == xyd.ActivityID.ARCTIC_EXPEDITION then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ARCTIC_EXPEDITION)
		end
	end)
	self:registerEvent(xyd.event.ARCTIC_EXPEDITION_RALLY, function (event)
		self.detail_.last_rally = xyd.getServerTime()

		if not self.detail_["rally" .. self:getSelfGroup()] then
			self.detail_["rally" .. self:getSelfGroup()] = {}
		end

		table.insert(self.detail_["rally" .. self:getSelfGroup()], xyd.getServerTime())
	end)
	self:registerEvent(xyd.event.EXPEDITION_CHAT_BACK, handler(self, self.onGetArcticMessageBack))
end

function ArcticExpeditionData:onGetArcticMessageBack(event)
	local msg = xyd.decodeProtoBuf(event.data)
	local eMsgId = tonumber(msg.e_msg_id) or 0

	if eMsgId == 0 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_NORMAL
	elseif eMsgId <= 5 then
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_SYS
	else
		msg.type = xyd.MsgType.ARCTIC_EXPEDITION_ASSEMBLE
		local group = msg.group

		if group == self:getSelfGroup() then
			if not self.detail_["rally" .. self:getSelfGroup()] then
				self.detail_["rally" .. self:getSelfGroup()] = {}
			end

			table.insert(self.detail_["rally" .. self:getSelfGroup()], xyd.getServerTime())

			local content = msg.content

			if type(content) == "string" then
				content = json.decode(content)
			end

			local cellID = tonumber(content[1])

			self:reqCellInfo(cellID, true)
		end
	end
end

function ArcticExpeditionData:getGroupByRank(rankIndex)
	local rankSort = {}

	for i = 1, 3 do
		table.insert(rankSort, {
			score = self.detail_["group_score" .. i] or 0,
			group = i
		})
	end

	table.sort(rankSort, function (a, b)
		return b.score < a.score
	end)

	return rankSort[rankIndex]
end

function ArcticExpeditionData:getGroupRank(group)
	group = group or self:getSelfGroup()
	local rankSort = {}

	for i = 1, 3 do
		table.insert(rankSort, {
			score = self.detail_["group_score" .. i] or 0,
			group = i
		})
	end

	table.sort(rankSort, function (a, b)
		return b.score < a.score
	end)

	for i = 1, 3 do
		if rankSort[i].group == group then
			return i
		end
	end

	return 1
end

function ArcticExpeditionData:getTimeMissionInfo(id)
	return {
		value = self.timeMissionValue[tonumber(id)],
		is_completed = self.timeMissionCompeted[tonumber(id)]
	}
end

function ArcticExpeditionData:checkWillOpenNextStage()
	local era_id = self:getEra()

	if era_id >= 3 then
		return false
	end

	local ids = xyd.tables.arcticExpeditionEraTaskTable:getIDsByEraID(tonumber(era_id))

	for _, id in ipairs(ids) do
		if not self.timeMissionCompeted[id] or self.timeMissionCompeted[id] == 0 then
			return false
		end
	end

	return true
end

function ArcticExpeditionData:getMaxBuyNum()
	local duringTime = xyd.getServerTime() - self.start_time
	local canBuyNum = tonumber(xyd.tables.miscTable:getVal("expedition_energy_buy_count")) * (math.floor(duringTime / xyd.DAY_TIME) + 1)
	local buyTimes = self.detail_.buy_times or 0

	return xyd.checkCondition(canBuyNum - buyTimes > 0, canBuyNum - buyTimes, 0)
end

function ArcticExpeditionData:getGroupScoreData(group)
	group = group or self:getSelfGroup()

	return self.detail_["group_score" .. group], self.detail_["last_score" .. group]
end

function ArcticExpeditionData:getArcticPartnerValue(partner_id)
	return tonumber(self.partnerInfo_[tostring(partner_id)]) or tonumber(xyd.tables.miscTable:getVal("expedition_girls_labor"))
end

function ArcticExpeditionData:getArcticPartnerState(partner_id)
	local maxValue = tonumber(xyd.tables.miscTable:getVal("expedition_girls_labor"))
	local value = tonumber(self.partnerInfo_[tostring(partner_id)])

	if not value then
		return 1
	elseif value < maxValue and value > 12 then
		return 2
	elseif value <= 12 and value > 0 then
		return 3
	else
		return 4
	end
end

function ArcticExpeditionData:getMapInfo()
	return self.mapInfo_ or {}
end

function ArcticExpeditionData:getCellInfo(cell_id)
	return self.mapInfo_[tonumber(cell_id)]
end

function ArcticExpeditionData:checkMissionRed()
	local ids = xyd.tables.arcticExpeditionTaskTable:getIDs()

	for _, id in ipairs(ids) do
		local value = self.detail_.values[tonumber(id)] or 0
		local is_completeds = self.detail_.is_completeds[tonumber(id)] or 0
		local is_awarded = self.detail_.awards[tonumber(id)] or 0
		local complete_value = xyd.tables.arcticExpeditionTaskTable:getCompleteValue(id) or 1
		local limit_time = xyd.tables.arcticExpeditionTaskTable:getLimitTime(id) or 1

		if limit_time <= 1 and complete_value <= value and is_awarded ~= 1 then
			return true
		elseif is_awarded < limit_time and is_awarded < is_completeds and is_completeds > 0 then
			return true
		end
	end

	return false
end

function ArcticExpeditionData:getRedMarkState()
	local redState = false

	if self:checkMissionRed() or self.detail_.sta and self.detail_.sta > 0 then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ARCTIC_EXPEDITION, redState)
end

return ArcticExpeditionData
