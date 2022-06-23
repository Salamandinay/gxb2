local TimeCloisterModel = class("TimeCloisterModel", import(".BaseModel"))
local json = require("cjson")
local redMark = xyd.models.redMark
local tecTable = xyd.tables.timeCloisterTecTable

function TimeCloisterModel:ctor()
	TimeCloisterModel.super.ctor(self)

	self.techInfo = {}
	self.achInfo = {}
	self.cloisterMaxStage = {}
	self.rankInfo = {}
	self.leftProbeTime = 0
	self.battleEnergyUpdateTime = 0
	self.cardTime = tonumber(xyd.tables.miscTable:getVal("time_cloister_card_time"))
	self.energyTime = tonumber(xyd.tables.miscTable:getVal("time_cloister_energy_time"))
	self.achieveRedState = {}
	self.battleRedState = {}
	self.sum_events = {}
	self.sum_start_events = {}
	self.missionArr = {}
	self.afterMissionArr = {}
	self.threeInfo = {}

	for i = 1, 6 do
		self.achieveRedState[i] = false
		self.battleRedState[i] = false
	end

	xyd.models.selfPlayer:addGlobalTimer(function ()
		if self.leftProbeTime == 0 then
			return
		end

		self.leftProbeTime = self.leftProbeTime - 1
		local info = self:getHangInfo()

		if info and xyd.getServerTime() - info.start_time > 0 and (xyd.getServerTime() - info.start_time) % self.cardTime == 0 then
			info.energy = math.max(info.energy - self.cardTime / self.energyTime, 0)

			if next(info.after_events2) then
				local event = table.remove(info.after_events2, 1)
				info.events[tostring(event)] = (info.events[tostring(event)] or 0) + 1

				self:addAfterEventsToEvents(tostring(event))

				local item = table.remove(info.after_items, 1)

				if item and item ~= "" then
					local data = xyd.split(item, "#")
					local type = tostring(xyd.tables.timeCloisterCardTable:getType(event))
					info.items[type] = info.items[type] or {}
					info.items[type][data[1]] = (info.items[type][data[1]] or 0) + tonumber(data[2])
				end
			else
				self:reqTimeCloisterInfo(1)
			end
		end

		if self.leftProbeTime == 0 then
			redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, true)
		end
	end)
end

function TimeCloisterModel:onRegister()
	self:registerEvent(xyd.event.TIME_CLOISTER_INFO, self.onGetTimeCloisterInfo, self)
	self:registerEvent(xyd.event.GET_ACHIEVE_INFO, self.onGetAchieveInfo, self)
	self:registerEvent(xyd.event.START_HANG, self.onStartHang, self)
	self:registerEvent(xyd.event.STOP_HANG, self.onStopHang, self)
	self:registerEvent(xyd.event.GET_HANG, self.onGetHang, self)
	self:registerEvent(xyd.event.GET_TEC_INFO, self.onGetTechInfo, self)
	self:registerEvent(xyd.event.UPGRADE_SKILL, self.onUpgradeSkill, self)
	self:registerEvent(xyd.event.GET_CLOISTER_INFO, self.onGetCloisterInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_FIGHT, self.onGetBattleResult, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_GET_RANK_LIST, self.onGetRankInfo, self)
	self:registerEvent(xyd.event.SPEED_UP_HANG, self.onSpeedUpHang, self)
	self:registerEvent(xyd.event.GET_CARD_INFO, self.onGetCardInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_GET_ACHIEVEMENT_AWARD, self.onGetAchievementAward, self)
	self:registerEvent(xyd.event.CLOISTER_RED_INFO, self.onGetRedInfo, self)
	self:registerEvent(xyd.event.RED_POINT, self.onRedMarkInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_EXTRA, self.onTimeCloisterExtra, self)
	self:registerEvent(xyd.event.ITEM_CHANGE, self.onItemChange, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_CRYSTAL_INFO, self.onGetThreeCrystalInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_CRYSTAL_BUY_CARD, self.onBackThreeCrystalBuyCards, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_COMMON_GET_CHOICE, self.onBackGetChoiceInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_COMMON_SET_CHOICE, self.onBackSetChoiceInfo, self)
	self:registerEvent(xyd.event.TIME_CLOISTER_COMMON_SET_IDS, self.onBackSetIds, self)
end

function TimeCloisterModel:onItemChange(event)
	self:checkThreeCloisterRed()
end

function TimeCloisterModel:onRedMarkInfo(event)
	local funID = event.data.function_id

	if funID ~= xyd.FunctionID.TIME_CLOISTER then
		return
	end

	local value = event.data.value
	local ids = xyd.tables.timeCloisterAchTypeTable:getIDs()

	for _, id in ipairs(ids) do
		local s = xyd.tables.timeCloisterAchTypeTable:getStart(id)
		local e = xyd.tables.timeCloisterAchTypeTable:getEnd(id)

		if s <= value and value <= e then
			local c = xyd.tables.timeCloisterAchTypeTable:getCloister(id)
			self.achieveRedState[c] = true

			self:updateAchRedState()
		end
	end
end

function TimeCloisterModel:onGetRedInfo(event)
	if not xyd.checkFunctionOpen(xyd.FunctionID.TIME_CLOISTER, true) then
		return
	end

	local data = event.data
	self.loginInfo = event.data

	if data.cloister_id == 0 then
		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, true)
	else
		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, false)

		if data.stop_time > 0 then
			redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, true)
		else
			redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, false)
		end
	end

	for _, item in ipairs(data.achievement_info) do
		local cloister = xyd.tables.timeCloisterAchTypeTable:getCloister(item.achieve_type)

		if not self.achieveRedState[cloister] and item.achieve_id ~= 0 then
			local complete = xyd.tables.timeCloisterAchTable:getCompleteValue(item.achieve_id)

			if complete and cloister and cloister > 0 then
				self.achieveRedState[cloister] = complete <= tonumber(item.value)
			end
		end
	end

	self:updateAchRedState()

	for cloister, curStage in ipairs(data.stages) do
		if curStage ~= nil and curStage % 11 == 0 then
			local last = xyd.db.misc:getValue("time_cloister_endless_battle_" .. cloister)

			if not last then
				self.battleRedState[cloister] = true
			else
				local weekStart1 = xyd.getGMTWeekStartTime(xyd.getServerTime())
				local weekStart2 = xyd.getGMTWeekStartTime(tonumber(last))
				self.battleRedState[cloister] = weekStart1 ~= weekStart2
			end

			self:checkBattleRedStateAfterTwo(cloister)
		end
	end

	self:updateBattleRedState()
end

function TimeCloisterModel:reqTimeCloisterInfo(hasProgress)
	local msg = messages_pb.time_cloister_info_req()

	if hasProgress then
		msg.has_progress = hasProgress
	end

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_INFO, msg)
end

function TimeCloisterModel:reqStartHang(cloister, partners)
	self.cloisterInfo[cloister].partners = partners
	local msg = messages_pb.start_hang_req()
	msg.cloister_id = cloister

	for _, id in ipairs(partners) do
		table.insert(msg.partners, id)
	end

	xyd.Backend.get():request(xyd.mid.START_HANG, msg)
end

function TimeCloisterModel:reqStopHang()
	self.cloisterInfo[self.chosenCloister].stop_time = xyd.getServerTime()
	local msg = messages_pb.stop_hang_req()

	xyd.Backend.get():request(xyd.mid.STOP_HANG, msg)
end

function TimeCloisterModel:reqGetAward()
	local msg = messages_pb.get_hang_req()

	xyd.Backend.get():request(xyd.mid.GET_HANG, msg)
end

function TimeCloisterModel:reqTechInfo(cloister)
	if self.techInfo[cloister] then
		return
	end

	local msg = messages_pb.get_tec_info_req()
	msg.cloister_id = cloister

	xyd.Backend.get():request(xyd.mid.GET_TEC_INFO, msg)
end

function TimeCloisterModel:reqUpgradeSkill(cloister, table_id)
	local msg = messages_pb.upgrade_skill_req()
	msg.cloister_id = cloister
	msg.table_id = table_id

	xyd.Backend.get():request(xyd.mid.UPGRADE_SKILL, msg)
end

function TimeCloisterModel:reqCloisterInfo(cloister)
	if self.cloisterMaxStage[cloister] then
		return
	end

	local msg = messages_pb.get_cloister_info_req()
	msg.cloister_id = cloister

	xyd.Backend.get():request(xyd.mid.GET_CLOISTER_INFO, msg)
end

function TimeCloisterModel:reqTimeCloisterBattle(cloister, stage, teamFormation, pet_id)
	local msg = messages_pb.time_cloister_fight_req()
	msg.cloister_id = cloister
	msg.stage = stage
	msg.pet_id = pet_id

	for _, teamInfo in pairs(teamFormation) do
		local teamMsg = messages_pb.time_cloister_encounter_team_formation()
		teamMsg.partner_id = teamInfo.partner_id
		teamMsg.pos = teamInfo.pos

		if tonumber(teamInfo.partner_id) < 0 then
			teamMsg.is_extra = true
		else
			teamMsg.is_extra = false
		end

		table.insert(msg.partners, teamMsg)
	end

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_FIGHT, msg)
end

function TimeCloisterModel:reqCloisterRankList(cloister)
	local msg = messages_pb.time_cloister_get_rank_list_req()
	msg.cloister_id = cloister

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_GET_RANK_LIST, msg)
end

function TimeCloisterModel:reqAchieveInfo(cloister)
	local msg = messages_pb.get_achieve_info_req()
	msg.cloister_id = cloister

	xyd.Backend.get():request(xyd.mid.GET_ACHIEVE_INFO, msg)
end

function TimeCloisterModel:reqSpeedUpHang(num)
	local msg = messages_pb.speed_up_hang_req()
	msg.num = num

	xyd.Backend.get():request(xyd.mid.SPEED_UP_HANG, msg)
end

function TimeCloisterModel:reqCardInfo(isMustUpdate)
	if self.cardInfo and not isMustUpdate then
		return
	end

	local msg = messages_pb.get_card_info_req()

	xyd.Backend.get():request(xyd.mid.GET_CARD_INFO, msg)
end

function TimeCloisterModel:reqAchievementAward(achieve_type)
	local msg = messages_pb.time_cloister_get_achievement_award_req()
	msg.achievement_type = achieve_type

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_GET_ACHIEVEMENT_AWARD, msg)
end

function TimeCloisterModel:onGetTimeCloisterInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	local maxCloister = data.unlock_cloister
	local cloisterInfo = {}
	local ids = xyd.tables.timeCloisterTable:getIDs()

	for _, id in ipairs(ids) do
		local list = {}
		local lockType = xyd.tables.timeCloisterTable:getLockType(id)
		list.progress = 0

		if lockType == -1 then
			list.state = xyd.CloisterState.UN_OPEN
		else
			list.state = id <= maxCloister and xyd.CloisterState.UN_START or xyd.CloisterState.LOCK
			list.lockType = lockType

			if data.progress then
				list.progress = data.progress[id] or 0
			end
		end

		cloisterInfo[id] = list
	end

	self.chosenCloister = data.cloister_id

	if data.cloister_id ~= 0 then
		cloisterInfo[data.cloister_id].state = data.stop_time == 0 and xyd.CloisterState.ON_GOING or xyd.CloisterState.OVER
		cloisterInfo[data.cloister_id].start_time = data.start_time
		cloisterInfo[data.cloister_id].stop_time = data.stop_time
		cloisterInfo[data.cloister_id].energy = data.energy
		cloisterInfo[data.cloister_id].after_events2 = self:dealInfoAfterEvents(data.after_events2) or {}
		cloisterInfo[data.cloister_id].items = json.decode(data.items) or {}
		cloisterInfo[data.cloister_id].after_items = data.after_items or {}
		cloisterInfo[data.cloister_id].partners = data.partners
		cloisterInfo[data.cloister_id].partner_infos = data.partner_infos
		cloisterInfo[data.cloister_id].self_base = data.self_base
		cloisterInfo[data.cloister_id].s_power = data.s_power
		local greenBase = math.floor(data.s_power * xyd.split(xyd.tables.miscTable:getVal("time_cloister_sp_battle_rate"), "|", true)[1])
		cloisterInfo[data.cloister_id].black_base = {
			data.self_base[1] - greenBase,
			data.self_base[2] - greenBase,
			data.self_base[3] - greenBase
		}
		local events = json.decode(data.events) or {}
		cloisterInfo[data.cloister_id].events = self:dealInfoEvents(events)
		local num = 0

		for _, value in pairs(events) do
			num = num + value
		end

		cloisterInfo[data.cloister_id].maxEnergy = math.ceil(data.energy + num * self.cardTime / self.energyTime - 0.1)

		if data.stop_time == 0 then
			self.leftProbeTime = math.ceil(data.energy * self.energyTime - 0.1) + data.start_time - xyd.getServerTime()
		else
			self.leftProbeTime = 0
		end

		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, false)
		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, data.stop_time > 0)
	else
		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, false)
		redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, true)
	end

	self.sum_events = json.decode(data.sum_events)

	if data.sum_start_events then
		self.sum_start_events = json.decode(data.sum_start_events)
	end

	self.cloisterInfo = cloisterInfo

	for i = 1, 6 do
		if self.battleRedState[i] then
			self:checkBattleRedStateAfterTwo(i)
		end
	end

	self:updateBattleRedState()
end

function TimeCloisterModel:onStartHang(event)
	local data = xyd.decodeProtoBuf(event.data)
	local id = data.cloister_id
	self.cloisterInfo[id].state = xyd.CloisterState.ON_GOING
	self.cloisterInfo[id].start_time = data.start_time
	self.cloisterInfo[id].energy = data.energy
	self.cloisterInfo[id].maxEnergy = data.energy
	self.cloisterInfo[id].after_events2 = self:dealInfoAfterEvents(data.after_events2) or {}
	self.cloisterInfo[id].events = {}
	self.cloisterInfo[id].after_items = data.after_items or {}
	self.cloisterInfo[id].items = {}
	self.cloisterInfo[id].self_base = data.self_base
	self.cloisterInfo[id].s_power = data.s_power
	self.cloisterInfo[id].partner_infos = data.partner_infos
	local greenBase = math.floor(data.s_power * xyd.split(xyd.tables.miscTable:getVal("time_cloister_sp_battle_rate"), "|", true)[1])
	self.cloisterInfo[id].black_base = {
		data.self_base[1] - greenBase,
		data.self_base[2] - greenBase,
		data.self_base[3] - greenBase
	}
	self.chosenCloister = id
	self.leftProbeTime = math.ceil(data.energy * self.energyTime - 0.1)

	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, false)
	self:reqCardInfo(true)

	local time = xyd.getServerTime() + xyd.tables.deviceNotifyTable:getDelayTime(xyd.DEVICE_NOTIFY.TIME_CLOISTER)

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.TIME_CLOISTER, time)
end

function TimeCloisterModel:onStopHang(event)
	self.cloisterInfo[self.chosenCloister].state = xyd.CloisterState.OVER
	self.leftProbeTime = 0

	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, true)

	local time = 0

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.TIME_CLOISTER, time)
end

function TimeCloisterModel:onGetHang(event)
	local overCloister = self.cloisterInfo[self.chosenCloister]

	for id, num in pairs(overCloister.events) do
		local base = math.floor(tonumber(id) / 100) * 100 + 1

		for i = base, tonumber(id) do
			self.sum_events[tostring(i)] = (self.sum_events[tostring(i)] or 0) + num
		end
	end

	for id, num in pairs(overCloister.events) do
		local type = xyd.tables.timeCloisterCardTable:getType(id)

		if type == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_WIN or type == xyd.TimeCloisterCardType.ENCOUNTER_BATTLE_FAIL then
			local parentCard = xyd.tables.timeCloisterCardTable:getParentCard(id)
			self.sum_start_events[tostring(parentCard)] = (self.sum_start_events[tostring(parentCard)] or 0) + num
		end
	end

	local list = {
		state = xyd.CloisterState.UN_START,
		lockType = overCloister.lockType,
		progress = overCloister.progress
	}
	self.cloisterInfo[self.chosenCloister] = list
	self.chosenCloister = 0
	self.leftProbeTime = 0

	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_CAN_PROBE, true)
	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_PROBE_COMPLETED, false)
end

function TimeCloisterModel:onGetTechInfo(event)
	local cloister_id = event.data.cloister_id or 1
	local skills = event.data.skills
	local ids = tecTable:getIdsByCloister(cloister_id)
	local cloisterTec = {}

	for group, tList in ipairs(ids) do
		local list = {
			totalNum = 0,
			curNum = 0
		}

		for _, id in ipairs(tList) do
			local maxLv = tecTable:getMaxLv(id)
			list[id] = {
				curLv = 0,
				pre_id = tecTable:getPreId(id),
				maxLv = maxLv
			}
			list.totalNum = list.totalNum + maxLv
		end

		cloisterTec[group] = list
	end

	for _, item in ipairs(skills) do
		local group = tecTable:getGroup(item.skill_id)
		cloisterTec[group][item.skill_id].curLv = item.skill_lv
		cloisterTec[group].curNum = cloisterTec[group].curNum + item.skill_lv
	end

	self.techInfo[cloister_id] = cloisterTec
end

function TimeCloisterModel:onUpgradeSkill(event)
	local skill_id = event.data.skill_id
	local cloister = tecTable:getCloister(skill_id)
	local group = tecTable:getGroup(skill_id)
	self.techInfo[cloister][group][skill_id].curLv = self.techInfo[cloister][group][skill_id].curLv + 1
	self.techInfo[cloister][group].curNum = self.techInfo[cloister][group].curNum + 1
end

function TimeCloisterModel:onGetCloisterInfo(event)
	local data = event.data
	self.cloisterMaxStage[data.cloister_id] = data.stage
	self.battleEnergyUpdateTime = data.update_time
end

function TimeCloisterModel:onGetBattleResult(event)
	local data = event.data
	local cloister = xyd.tables.timeCloisterBattleTable:getCloister(data.stage_id)
	local old = self.cloisterMaxStage[cloister]
	local typeOld = xyd.tables.timeCloisterBattleTable:getType(old)
	local typeNow = xyd.tables.timeCloisterBattleTable:getType(data.stage_id)

	if typeNow == 2 then
		if typeOld == 1 then
			self.battleRedState[cloister] = true

			self:checkBattleRedStateAfterTwo(cloister)
		else
			self.battleRedState[cloister] = false

			xyd.db.misc:setValue({
				key = "time_cloister_endless_battle_" .. cloister,
				value = xyd.getServerTime()
			})
		end

		self:updateBattleRedState()
	end

	self.cloisterMaxStage[cloister] = data.stage_id
end

function TimeCloisterModel:onGetRankInfo(event)
	local data = event.data
	self.rankInfo[data.cloister_id] = {
		list = data.list,
		self_rank = data.self_rank and data.self_rank + 1 or data.num,
		self_score = data.self_score or 0,
		num = data.num
	}

	if not data.self_rank then
		self.rankInfo[data.cloister_id].isNoSelfRank = true
	else
		self.rankInfo[data.cloister_id].isNoSelfRank = false
	end
end

function TimeCloisterModel:onGetAchieveInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	local cloister = xyd.tables.timeCloisterAchTypeTable:getCloister(data.achievements[1].achieve_type)
	self.achInfo[cloister] = data.achievements
end

function TimeCloisterModel:onSpeedUpHang(event)
	if event.data and event.data.client_speed then
		self:getHangInfo().stop_time = xyd.getServerTime() - 1
		self.leftProbeTime = 0
		self.cloisterInfo[self.chosenCloister].state = xyd.CloisterState.OVER

		return
	end

	local data = event.data
	local hangInfo = self:getHangInfo()
	hangInfo.start_time = data.start_time
	hangInfo.stop_time = data.stop_time
	hangInfo.energy = data.energy
	hangInfo.events = self:dealInfoEvents(json.decode(data.events)) or {}
	hangInfo.after_events2 = self:dealInfoAfterEvents(data.after_events2) or {}
	hangInfo.items = json.decode(data.items) or {}
	hangInfo.after_items = data.after_items or {}

	if data.stop_time == 0 then
		self.leftProbeTime = math.ceil(data.energy * self.energyTime - 0.1) + data.start_time - xyd.getServerTime()
	else
		self.leftProbeTime = 0
		self.cloisterInfo[self.chosenCloister].state = xyd.CloisterState.OVER
	end
end

function TimeCloisterModel:onGetCardInfo(event)
	local cards = json.decode(event.data.cards) or {}
	local cardTable = xyd.tables.timeCloisterCardTable
	local ids = cardTable:getIDs()
	local list = {}

	for _, id in ipairs(ids) do
		local lock = cardTable:getLock(id)
		list[id] = lock
	end

	for key, value in pairs(cards) do
		list[tonumber(key)] = tonumber(value)
	end

	self.cardInfo = list
end

function TimeCloisterModel:onGetAchievementAward(event)
	local data = event.data
	local cloister = xyd.tables.timeCloisterAchTypeTable:getCloister(data.achieve_type)
	local info = self.achInfo[cloister]
	local canGet = false

	for _, item in ipairs(info) do
		if item.achieve_type == data.achieve_type then
			item.achieve_id = data.achieve_id
			item.value = data.value
		end

		if not canGet and item.achieve_id > 0 then
			local complete = xyd.tables.timeCloisterAchTable:getCompleteValue(item.achieve_id)

			if complete and item.value then
				canGet = complete <= tonumber(item.value)
			end
		end
	end

	self.achieveRedState[cloister] = canGet

	self:updateAchRedState()

	self.cloisterInfo[cloister].progress = data.progress
end

function TimeCloisterModel:getCloisterInfo()
	return self.cloisterInfo
end

function TimeCloisterModel:getChosenCloister()
	return self.chosenCloister
end

function TimeCloisterModel:getHangInfo()
	return self.cloisterInfo[self.chosenCloister]
end

function TimeCloisterModel:getTechInfoByCloister(cloister)
	return self.techInfo[cloister]
end

function TimeCloisterModel:getMaxStage(cloister)
	return self.cloisterMaxStage[cloister]
end

function TimeCloisterModel:getAchInfo(cloister)
	return self.achInfo[cloister]
end

function TimeCloisterModel:getCardInfo()
	return self.cardInfo
end

function TimeCloisterModel:getRankInfo(cloister)
	return self.rankInfo[cloister]
end

function TimeCloisterModel:canGetAward()
	return self.chosenCloister ~= 0 and self.cloisterInfo[self.chosenCloister].state == xyd.CloisterState.OVER
end

function TimeCloisterModel:tryGetTimeCloisterInfo()
	if not self.cloisterInfo then
		self:reqTimeCloisterInfo(1)
	end
end

function TimeCloisterModel:updateAchRedState()
	local achRed = false

	for i = 1, 6 do
		if self.achieveRedState[i] then
			achRed = true

			break
		end
	end

	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_ACHIEVEMENT, achRed)
end

function TimeCloisterModel:updateBattleRedState()
	local battleRed = false

	for i = 1, 6 do
		if self.battleRedState[i] then
			battleRed = true

			break
		end
	end

	redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_BATTLE, battleRed)
end

function TimeCloisterModel:getAchieveRedState()
	return self.achieveRedState
end

function TimeCloisterModel:getBattleRedState()
	return self.battleRedState
end

function TimeCloisterModel:getSumEvents()
	return self.sum_events
end

function TimeCloisterModel:getSumStartEvents()
	return self.sum_start_events
end

function TimeCloisterModel:getBattleEnergyAndTime()
	local energyMax = xyd.split(xyd.tables.miscTable:getVal("time_cloister_fight_energy_max"), "#", true)
	local energyCd = tonumber(xyd.tables.miscTable:getVal("time_cloister_fight_energy_cd"))
	local real = xyd.models.backpack:getItemNumByID(energyMax[1])
	local delta = math.floor((xyd.getServerTime() - self.battleEnergyUpdateTime) / energyCd)

	if energyMax[2] <= real then
		return real, 0
	elseif energyMax[2] <= real + delta then
		return energyMax[2], 0
	else
		return real + delta, self.battleEnergyUpdateTime + energyCd * (delta + 1) - xyd.getServerTime()
	end
end

function TimeCloisterModel:getLoginInfo()
	return self.loginInfo
end

function TimeCloisterModel:setSpeedUpNum(num)
	self.speedUpNum = num
end

function TimeCloisterModel:getSpeedUpNum()
	return self.speedUpNum or 0
end

function TimeCloisterModel:getCloisterImg(str)
	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")
	local bgImg = str

	if time_cloister_probe_wd and time_cloister_probe_wd:getCloister() then
		local cloister = time_cloister_probe_wd:getCloister()

		if cloister and cloister ~= 1 then
			bgImg = bgImg .. "_level_" .. cloister
		end
	end

	return bgImg
end

function TimeCloisterModel:reqTimeCloisterEncounter(cardId, teamFormation, pet_id)
	local msg = messages_pb.time_cloister_extra_req()
	msg.event_id = tostring(cardId)
	msg.pet_id = pet_id

	for _, teamInfo in pairs(teamFormation) do
		local teamMsg = messages_pb.time_cloister_encounter_team_formation()
		teamMsg.partner_id = teamInfo.partner_id
		teamMsg.pos = teamInfo.pos

		if tonumber(teamInfo.partner_id) < 0 then
			teamMsg.is_extra = true
		else
			teamMsg.is_extra = false
		end

		table.insert(msg.partners, teamMsg)
	end

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_EXTRA, msg)
end

function TimeCloisterModel:checkExtraCard(cardId)
	local hangInfo = self:getHangInfo()
	local parentId = xyd.tables.timeCloisterCardTable:getParentCard(cardId)

	if hangInfo.events and parentId and parentId > 0 then
		local searchCardId = false
		local searchParentIndex = "-999"

		for key, value in pairs(hangInfo.events) do
			if key == tostring(cardId) then
				hangInfo.events[key] = hangInfo.events[key] + 1
				searchCardId = true
			end

			if key == tostring(parentId) then
				hangInfo.events[key] = hangInfo.events[key] - 1

				if hangInfo.events[key] == 0 then
					searchParentIndex = key
				end
			end
		end

		if not searchCardId then
			hangInfo.events[tostring(cardId)] = 1
		end

		if searchParentIndex ~= "-999" then
			hangInfo.events[searchParentIndex] = nil
		end

		local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")

		if time_cloister_probe_wd then
			time_cloister_probe_wd:updateShowEventIcon()
		end
	end
end

function TimeCloisterModel:dealInfoEvents(events)
	if not events then
		return {}
	end

	local tempArr = {}
	self.missionArr = {}

	for i in pairs(events) do
		local searchMark = string.find(i, "#")

		if searchMark then
			local splitArr = xyd.split(i, "#")
			local cardType = xyd.tables.timeCloisterCardTable:getType(splitArr[1])

			if not tempArr[tostring(splitArr[1])] then
				tempArr[tostring(splitArr[1])] = tonumber(events[i])
			else
				tempArr[tostring(splitArr[1])] = tempArr[tostring(splitArr[1])] + tonumber(events[i])
			end

			if cardType == xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
				if not self.missionArr[tostring(splitArr[1])] then
					self.missionArr[tostring(splitArr[1])] = {}
				end

				local params = {
					mission_id = tonumber(splitArr[2]),
					mission_params1 = tonumber(splitArr[3])
				}

				for i = 1, events[i] do
					table.insert(self.missionArr[tostring(splitArr[1])], params)
				end
			end
		else
			tempArr[tostring(i)] = events[i]
		end
	end

	return tempArr
end

function TimeCloisterModel:dealInfoAfterEvents(after_events2)
	if not after_events2 then
		return {}
	end

	local tempArr = {}

	for i in pairs(after_events2) do
		local searchMark = string.find(tostring(after_events2[i]), "#")
		local splitArr = xyd.split(tostring(after_events2[i]), "#")

		if searchMark then
			table.insert(tempArr, splitArr[1])

			local cardType = xyd.tables.timeCloisterCardTable:getType(splitArr[1])

			if cardType == xyd.TimeCloisterCardType.DRESS_MISSION_EVENT then
				if not self.afterMissionArr[tostring(splitArr[1])] then
					self.afterMissionArr[tostring(splitArr[1])] = {}
				end

				local params = {
					mission_id = tonumber(splitArr[2]),
					mission_params1 = tonumber(splitArr[3])
				}

				table.insert(self.afterMissionArr[tostring(splitArr[1])], params)
			end
		else
			table.insert(tempArr, after_events2[i])
		end
	end

	return tempArr
end

function TimeCloisterModel:addAfterEventsToEvents(eventId)
	local cardType = xyd.tables.timeCloisterCardTable:getType(eventId)

	if cardType == xyd.TimeCloisterCardType.DRESS_MISSION_EVENT and self.afterMissionArr[tostring(eventId)] and self.afterMissionArr[tostring(eventId)][1] then
		if not self.missionArr[tostring(eventId)] then
			self.missionArr[tostring(eventId)] = {}
		end

		table.insert(self.missionArr[tostring(eventId)], self.afterMissionArr[tostring(eventId)][1])
		table.remove(self.afterMissionArr[tostring(eventId)], 1)
	end
end

function TimeCloisterModel:getMissionArr()
	return self.missionArr
end

function TimeCloisterModel:reqDressShow(str, itemId)
	local msg = messages_pb.time_cloister_extra_req()
	msg.event_id = str
	msg.item_id = itemId

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_EXTRA, msg)

	self.reqDressShowEventId = str
end

function TimeCloisterModel:onTimeCloisterExtra(event)
	local data = xyd.decodeProtoBuf(event.data)
	local items = {}
	local event_id = data.event_id

	if data.items then
		items = data.items
	elseif event_id and tonumber(event_id) > 0 then
		event_id = tonumber(event_id)
		local awards = xyd.tables.timeCloisterCardTable:getAwards(event_id)

		for i in pairs(awards) do
			table.insert(items, {
				item_id = awards[i][1],
				item_num = awards[i][2]
			})
		end
	end

	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")
	local info = self:getHangInfo()
	local type = tostring(xyd.tables.timeCloisterCardTable:getType(event_id))

	for i in pairs(items) do
		info.items[type] = info.items[type] or {}
		info.items[type][tostring(items[i].item_id)] = (info.items[type][tostring(items[i].item_id)] or 0) + tonumber(items[i].item_num)
	end

	if data.battle_result then
		local time_cloister_encounter_wd = xyd.WindowManager.get():getWindow("time_cloister_encounter_window")

		if time_cloister_encounter_wd then
			xyd.WindowManager.get():closeWindow("time_cloister_encounter_window")
		end

		self:checkExtraCard(event_id)
	else
		if self.reqDressShowEventId then
			local showEventIdArr = xyd.split(tostring(self.reqDressShowEventId), "#")
			local eventId = showEventIdArr[1]
			local missionId = showEventIdArr[2]
			local missionParams1 = showEventIdArr[3]

			if self.missionArr[eventId] then
				for i, value in pairs(self.missionArr[eventId]) do
					if tonumber(value.mission_id) == tonumber(missionId) then
						if missionParams1 then
							if value.mission_params1 and tonumber(value.mission_params1) == tonumber(missionParams1) then
								table.remove(self.missionArr[eventId], i)

								break
							end
						elseif not value.mission_params1 then
							table.remove(self.missionArr[eventId], i)

							break
						end
					end
				end
			end

			for i in pairs(self.missionArr) do
				if #self.missionArr == 0 then
					table.remove(self.missionArr, i)
				end
			end

			self:checkExtraCard(event_id)

			self.reqDressShowEventId = nil
			local time_cloister_show_dress_wd = xyd.WindowManager.get():getWindow("time_cloister_show_dress_window")

			if time_cloister_show_dress_wd then
				xyd.WindowManager.get():closeWindow("time_cloister_show_dress_window")
			end
		end

		time_cloister_probe_wd:showItemsTween(items, xyd.TimeCloisterExtraEvent.DRESS_SHOW)
	end
end

function TimeCloisterModel:setOver()
	local eventObj = {
		name = xyd.event.SPEED_UP_HANG,
		data = {
			client_speed = 1,
			stop_time = xyd.getServerTime() - 1
		}
	}

	xyd.EventDispatcher.outer():dispatchEvent(eventObj)
	xyd.EventDispatcher.inner():dispatchEvent(eventObj)
end

function TimeCloisterModel:setSpeedMorePropTips(isShow)
	self.isShowSpeedMoreProTips = isShow
end

function TimeCloisterModel:getSpeedMorePropTips()
	return self.isShowSpeedMoreProTips
end

function TimeCloisterModel:getThreeCardBaseInfo(isWithCard)
	local msg = messages_pb.time_cloister_crystal_info_req()
	msg.cloister_id = xyd.TimeCloisterMissionType.THREE

	if isWithCard then
		msg.with_card = 1
	else
		msg.with_card = 0
	end

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_CRYSTAL_INFO, msg)
end

function TimeCloisterModel:onGetThreeCrystalInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "timeCloister3 INFO :==================")

	self.threeInfo.threeCrystalCards = data.cards
	self.threeInfo.threeCrystalShops = data.shops

	if data.ids then
		self.threeInfo.threeCrystalBattleCardIds = data.ids

		xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS, false)
	else
		self.threeInfo.threeCrystalBattleCardIds = {}

		xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS, true)
	end

	self.threeInfo.point = data.point

	self:getChoiceInfo(xyd.TimeCloisterMissionType.THREE)
end

function TimeCloisterModel:getChoiceInfo(cloisterId)
	local msg = messages_pb.time_cloister_common_get_choice_req()
	msg.cloister_id = cloisterId

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_COMMON_GET_CHOICE, msg)
end

function TimeCloisterModel:checkThreeCloisterRed()
	local resArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_item", "value", "|")
	local showNumArr = xyd.tables.miscTable:split2num("time_cloister_crystal_card_buy_tips", "value", "|")
	local isShow = true

	for i, id in pairs(resArr) do
		if xyd.models.backpack:getItemNumByID(id) < showNumArr[i] then
			isShow = false

			break
		end
	end

	if isShow then
		xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_BUY, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_BUY, false)
	end
end

function TimeCloisterModel:getThreeCrystalInfo()
	return self.threeInfo
end

function TimeCloisterModel:getThreeCrystalShops()
	return self.threeInfo.threeCrystalShops
end

function TimeCloisterModel:getThreeCrystalCards(index)
	if index then
		return self.threeInfo.threeCrystalCards[index]
	end

	return self.threeInfo.threeCrystalCards
end

function TimeCloisterModel:getThreeCrystalPoint()
	return self.threeInfo.point
end

function TimeCloisterModel:getThreeChoiceCrystalBuffId()
	return self.threeInfo.choiceId
end

function TimeCloisterModel:getThreeChoiceCrystalBattleCardIds()
	return self.threeInfo.threeCrystalBattleCardIds
end

function TimeCloisterModel:onBackGetChoiceInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "get choice info =====")

	if data.cloister_id == xyd.TimeCloisterMissionType.THREE then
		self.threeInfo.choiceId = data.id
	end
end

function TimeCloisterModel:setChoiceInfo(cloisterId, id)
	local msg = messages_pb.time_cloister_common_set_choice_req()
	msg.cloister_id = cloisterId
	msg.id = id

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_COMMON_SET_CHOICE, msg)
end

function TimeCloisterModel:onBackSetChoiceInfo(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "set choice info =====")

	if data.cloister_id == xyd.TimeCloisterMissionType.THREE then
		self.threeInfo.choiceId = data.id
	end

	local timeCloisterCrystalChoiceWd = xyd.WindowManager.get():getWindow("time_cloister_crystal_choice_window")

	if timeCloisterCrystalChoiceWd then
		xyd.WindowManager.get():closeWindow("time_cloister_crystal_choice_window")
	end

	xyd.showToast(__("TIME_CLOISTER_TEXT114"))
end

function TimeCloisterModel:sendSetIds(cloisterId, ids)
	local msg = messages_pb.time_cloister_common_set_ids_req()
	msg.cloister_id = cloisterId

	for i in pairs(ids) do
		table.insert(msg.ids, ids[i])
	end

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_COMMON_SET_IDS, msg)
end

function TimeCloisterModel:onBackSetIds(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "set ids back =====")

	if data.cloister_id == xyd.TimeCloisterMissionType.THREE then
		if data.ids then
			self.threeInfo.threeCrystalBattleCardIds = data.ids

			xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS, false)
		else
			self.threeInfo.threeCrystalBattleCardIds = {}

			xyd.models.redMark:setMark(xyd.RedMarkType.TIME_CLOISTER_RED_THREE_SET_BATTLE_IDS, true)
		end
	end

	local TimeCloisterCrystalBattleCardWd = xyd.WindowManager.get():getWindow("time_cloister_crystal_battle_card_window")

	if TimeCloisterCrystalBattleCardWd then
		xyd.WindowManager.get():closeWindow("time_cloister_crystal_battle_card_window")
	end

	xyd.showToast(__("TIME_CLOISTER_TEXT114"))
end

function TimeCloisterModel:getThreeChoiceCrystalBuffNum(choiceId)
	local tecMineArrs = self:getTechInfoByCloister(xyd.TimeCloisterMissionType.THREE)[2]
	local tecArr = xyd.tables.timeCloisterCrystalBuffTable:getTecId(choiceId)
	local tecId = tecArr[1]
	local addTecId = tecArr[2]
	local nums = xyd.tables.timeCloisterTecTable:getNum(tecId)
	local baseNum = nums[1]
	local addTecIdNums = xyd.tables.timeCloisterCrystalBuffTable:getNum(choiceId)
	local lastNum = baseNum

	if tecMineArrs[addTecId].curLv > 0 then
		lastNum = baseNum + addTecIdNums[tecMineArrs[addTecId].curLv]
	end

	return lastNum
end

function TimeCloisterModel:getThreeCrystalTypeWithCardsIndex(index)
	if not self.threeInfo.threeTypeWithCardsIndex then
		self.threeInfo.threeTypeWithCardsIndex = {
			[0] = {},
			{},
			{},
			{},
			{}
		}

		for i, data in pairs(self:getThreeCrystalCards()) do
			local type = xyd.tables.timeCloisterCrystalCardTable:getType(data.card)

			table.insert(self.threeInfo.threeTypeWithCardsIndex[type], i)
		end

		for i = 1, 4 do
			for j, data in pairs(self.threeInfo.threeTypeWithCardsIndex[i]) do
				table.insert(self.threeInfo.threeTypeWithCardsIndex[0], data)
			end
		end
	end

	if index then
		return self.threeInfo.threeTypeWithCardsIndex[index]
	end

	return self.threeInfo.threeTypeWithCardsIndex
end

function TimeCloisterModel:sendThreeCrystalBuyCards(itemI)
	local msg = messages_pb.time_cloister_crystal_buy_card_req()
	msg.cloister_id = xyd.TimeCloisterMissionType.THREE
	msg.index = tonumber(itemI)

	xyd.Backend.get():request(xyd.mid.TIME_CLOISTER_CRYSTAL_BUY_CARD, msg)
end

function TimeCloisterModel:onBackThreeCrystalBuyCards(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "buyCard :==================")

	local index = data.index
	local info = self.threeInfo.threeCrystalCards[index]
	local cardCurLevelLimit = xyd.tables.timeCloisterCrystalCardTable:getCardNum(info.card)
	local addPoint = xyd.tables.timeCloisterCrystalCardTable:getPoint(info.card)
	self.threeInfo.point = self.threeInfo.point + addPoint

	if info.buy_times < cardCurLevelLimit - 1 then
		info.buy_times = info.buy_times + 1
	else
		local nextId = xyd.tables.timeCloisterCrystalCardTable:getNextId(info.card)

		if nextId and nextId ~= -1 then
			info.card = nextId
			info.buy_times = 0
		else
			info.buy_times = cardCurLevelLimit
		end
	end

	self.threeInfo.threeCrystalShops = data.shops
end

function TimeCloisterModel:changeCommonCardUI(obj)
	local time_cloister_probe_wd = xyd.WindowManager.get():getWindow("time_cloister_probe_window")
	local cloisterId = 1

	if time_cloister_probe_wd and time_cloister_probe_wd:getCloister() then
		cloisterId = time_cloister_probe_wd:getCloister()
	end

	local bg = obj:NodeByName("bg")

	if bg then
		bg = obj:ComponentByName("bg", typeof(UISprite))
	else
		bg = obj:GetComponent(typeof(UISprite))
	end

	if bg then
		xyd.setUISpriteAsync(bg, nil, xyd.tables.timeCloisterTable:getCardBg(cloisterId))
	end

	local nameBg = obj:ComponentByName("nameBg", typeof(UISprite))
	nameBg.height = 32

	xyd.setUISpriteAsync(nameBg, nil, xyd.tables.timeCloisterTable:getCardNameBg(cloisterId))

	local nameLabel = obj:ComponentByName("nameLabel", typeof(UILabel))
	nameLabel.color = Color.New2("0x" .. xyd.tables.timeCloisterTable:getCardNameColor(cloisterId) .. "ff")
	local descLabel = obj:NodeByName("descLabel")

	if descLabel then
		descLabel = obj:ComponentByName("descLabel", typeof(UILabel))
	else
		descLabel = obj:ComponentByName("scroller/descLabel", typeof(UILabel))
	end

	if descLabel then
		descLabel.color = Color.New2("0x" .. xyd.tables.timeCloisterTable:getCardTextColor(cloisterId) .. "ff")
	end
end

function TimeCloisterModel:checkBattleRedStateAfterTwo(cloister)
	local cloisterInfo = self:getCloisterInfo()

	if not cloisterInfo then
		return
	end

	local afterTwoCloister = cloister + 2

	if cloisterInfo[afterTwoCloister] ~= nil and xyd.tables.timeCloisterTable:getLockType(afterTwoCloister) ~= -1 then
		if cloisterInfo[afterTwoCloister].state == xyd.CloisterState.UN_OPEN then
			-- Nothing
		elseif cloisterInfo[afterTwoCloister].state ~= xyd.CloisterState.LOCK then
			self.battleRedState[cloister] = false
		end
	end
end

return TimeCloisterModel
