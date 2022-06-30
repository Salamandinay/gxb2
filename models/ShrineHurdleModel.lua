local ShrineHurdleModel = class("ShrineHurdleModel", import(".BaseModel"))
local json = require("cjson")
local ReportHero = import("lib.battle.ReportHero")
local BattleCreateReport = import("lib.battle.BattleCreateReport")
local ReportPet = import("lib.battle.ReportPet")
local fakeGuideData = {
	route_id = 500000
}

function ShrineHurdleModel:ctor()
	ShrineHurdleModel.super.ctor(self)

	self.isAchievment_Open = false
	self.skipReport = xyd.db.misc:getValue("trial_skip_report")

	if tonumber(self.skipReport) == 1 then
		self.skipReport = true
	else
		self.skipReport = false
	end
end

function ShrineHurdleModel:checkInGuide()
	if not self.flags then
		return nil
	end

	for i = 1, 10 do
		if not self.flags[tostring(i)] and not self.flags[i] then
			return i
		end
	end

	return nil
end

function ShrineHurdleModel:isSkipReport()
	return self.skipReport
end

function ShrineHurdleModel:setSkipReport(flag)
	self.skipReport = flag
	local value = nil

	if flag then
		value = 1
	else
		value = 0
	end

	xyd.db.misc:addOrUpdate({
		key = "trial_skip_report",
		value = value
	})
end

function ShrineHurdleModel:onRegister()
	ShrineHurdleModel.super.onRegister(self)
	self:registerEvent(xyd.event.SHRINE_HURDLE_GET_INFO, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.SHRINE_HURDLE_GET_INFO_HISTORY, handler(self, self.onHistoryGetInfo))
	self:registerEvent(xyd.event.SHRINE_HURDLE_NEXT_FLOOR, handler(self, self.onNextFloor))
	self:registerEvent(xyd.event.SHRINE_HURDLE_SELECT_RT, handler(self, self.onSelectRt))
	self:registerEvent(xyd.event.SHRINE_HURDLE_CHALLENGE, handler(self, self.onChallenge))
	self:registerEvent(xyd.event.SHRINE_HURDLE_GET_PARTNERS, handler(self, self.onGetPartners))
	self:registerEvent(xyd.event.SHRINE_HURDLE_END, handler(self, self.onEndHurdle))
	self:registerEvent(xyd.event.SHRINE_HURDLE_GET_REPORTS, handler(self, self.onGetReport))
	self:registerEvent(xyd.event.SHRINE_HURDLE_FLAGS, handler(self, self.onSetFlags))
	self:registerEvent(xyd.event.SHRINE_HURDLE_SET_MAX_DIFF, handler(self, self.onSetHarm))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.onSystemUpdate))
	self:registerEvent(xyd.event.EXCHANGE_SHRINE_CARD, handler(self, self.onBuyTickt))
	self:registerEvent(xyd.event.PARTNER_ADD, function (event)
		if self.isAchievment_Open == false then
			local partnerInfo = xyd.models.slot:getPartner(event.data.partnerID)

			if partnerInfo:getStar() >= 10 then
				self:reqShineHurdleInfo()

				self.isAchievment_Open = true
			end
		end
	end)
	self:registerEventInner(xyd.event.PARTNER_ATTR_CHANGE, function (event)
		if self.isAchievment_Open == false then
			local partnerInfo = xyd.models.slot:getPartner(event.data.partnerID)

			if partnerInfo:getStar() >= 10 then
				self:reqShineHurdleInfo()

				self.isAchievment_Open = true
			end
		end
	end)
end

function ShrineHurdleModel:reqShineHurdleRecords()
	local msg = messages_pb.shrine_hurdle_get_records_req()

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_RECORDS, msg)
end

function ShrineHurdleModel:reqShineHurdleReport(record_id, floor_id)
	local msg = messages_pb.shrine_hurdle_get_reports_req()

	table.insert(msg.ids, record_id)
	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_REPORTS, msg)

	self.reqFloor_ = floor_id
end

function ShrineHurdleModel:reqShineHurdleInfo()
	print("=============================reqShineHurdleInfo===================")

	if not self.reqInfo_ then
		local msg = messages_pb.shrine_hurdle_get_info_req()

		xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_INFO, msg)

		return true
	end

	return false
end

function ShrineHurdleModel:onSystemUpdate()
	if self:checkFuctionOpen() then
		self:reqShineHurdleInfo()
	end
end

function ShrineHurdleModel:onGetInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.reqInfo_ = true
	self.ticket_ = data.ticket
	self.gold_ = data.gold
	self.pr_num_ = data.pr_num
	self.floor_id_ = data.floor_id
	self.route_id_ = data.route_id
	self.floor_index_ = data.floor_index
	self.start_time_ = data.start_time
	self.diff_id_ = data.diff_id
	self.count_ = data.count
	self.extra_ = data.extra
	self.score_ = data.score
	self.last_route_id_ = data.last_route_id
	self.overChallengeDiff = data.diff_ids or {}
	self.buyTimes_ = data.buy_times or 0
	self.isAchievment_Open = true

	if data.skills and tostring(data.skills) ~= "" then
		self.skills_ = json.decode(data.skills)
	else
		self.skills_ = {}
	end

	self.historyScores_ = data.scores or {}
end

function ShrineHurdleModel:getCanBuyTimes()
	local limitNum = tonumber(xyd.tables.miscTable:getVal("shrine_hurdle_ticket_buy_limit"))

	return limitNum - self.buyTimes_
end

function ShrineHurdleModel:onBuyTickt(event)
	self.buyTimes_ = self.buyTimes_ + event.data.num
	self.ticket_ = self.ticket_ + event.data.num
end

function ShrineHurdleModel:getBuyTimes()
	return self.buyTimes_
end

function ShrineHurdleModel:getHistoryInfo()
	local msg = messages_pb.shrine_hurdle_get_info_history_req()

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_INFO_HISTORY, msg)
end

function ShrineHurdleModel:getLastDiff(route_id)
	if not self.diff_ids then
		return 1
	end

	return self.diff_ids[route_id] or 1
end

function ShrineHurdleModel:onHistoryGetInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.diff_ids = data.diff_ids or {}
	self.flags = {}
	self.plot = {}

	if data.flags and #data.flags > 0 then
		for _, id in ipairs(data.flags) do
			self.flags[id] = true
		end
	end

	if data.plot and #data.plot > 0 then
		for _, id in ipairs(data.plot) do
			self.plot[tostring(id)] = true
		end
	end
end

function ShrineHurdleModel:nextFloor(index)
	index = index or 1
	local msg = messages_pb.shrine_hurdle_next_floor_req()
	msg.index = index

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_NEXT_FLOOR, msg)
end

function ShrineHurdleModel:onNextFloor(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.floor_id_ = data.floor_id
	self.floor_index_ = data.floor_index
	self.extra_ = data.extra
end

function ShrineHurdleModel:selectRt(route_id, diff_id)
	local msg = messages_pb.shrine_hurdle_select_rt_req()
	msg.route_id = route_id
	msg.diff_id = diff_id
	msg.index = 1

	xyd.db.misc:addOrUpdate({
		key = "shrine_select_diff_" .. route_id,
		value = diff_id
	})
	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_SELECT_RT, msg)
end

function ShrineHurdleModel:onSelectRt(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.ticket_ = data.ticket
	self.partnerInfos_ = data.partner_infos or {}
	self.pr_num_ = #self.partnerInfos_ or 0
	self.floor_id_ = data.floor_id
	self.route_id_ = data.route_id
	self.floor_index_ = data.floor_index
	self.diff_id_ = data.diff_id
	self.extra_ = data.extra
	self.skills_ = {}
	self.gold_ = 0
	self.score_ = 0

	xyd.db.misc:setValue({
		value = 0,
		key = "shrine_hurdle_close_floor"
	})
end

function ShrineHurdleModel:challengeFight(partners, pet_id)
	pet_id = pet_id or 0
	local msg = messages_pb.shrine_hurdle_challenge_req()

	for _, v in pairs(partners) do
		local partner = messages_pb:fight_partner()
		partner.partner_id = v.partner_id
		partner.pos = v.pos

		table.insert(msg.partners, partner)
	end

	self.battlePatners_ = partners
	msg.pet_id = pet_id

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_CHALLENGE, msg)
end

function ShrineHurdleModel:challengeSelect(choice, index)
	local msg = messages_pb.shrine_hurdle_challenge_req()
	msg.choice = choice
	msg.index = index

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_CHALLENGE, msg)
end

function ShrineHurdleModel:challengeSelectPartner(select_partner)
	local msg = messages_pb.shrine_hurdle_challenge_req()
	local partner = messages_pb:fight_partner()
	partner.partner_id = select_partner
	partner.pos = 1
	msg.choice = 3

	table.insert(msg.partners, partner)
	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_CHALLENGE, msg)
end

function ShrineHurdleModel:onChallenge(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.floor_id and tonumber(data.floor_id) > 0 then
		self.floor_id_ = data.floor_id
	end

	if not self.extra_ then
		self.extra_ = {}
	end

	if data.score and tonumber(data.score) > 0 then
		self.addScore_ = data.score - self.score_
		self.score_ = data.score
	end

	if data.gold and tonumber(data.gold) >= 0 then
		if data.gold ~= self.gold_ then
			self.addGold_ = data.gold - self.gold_
			self.gold_ = data.gold
			local win = xyd.WindowManager.get():getWindow("shrine_hurdle_window")
			local win2 = xyd.WindowManager.get():getWindow("shrine_hurdle_choose_buff_window")

			if win then
				win:showGoldChange(self.addGold_)
			end

			if win2 then
				win2:showGoldChange(self.addGold_)
			end
		else
			self.addGold_ = 0
		end
	end

	if data.choice and tonumber(data.choice) > 0 then
		self.extra_.can_next = 1
		local floor_id, floor_index, floorType = self:getFloorInfo()

		if floorType == 2 then
			if data.choice == 1 then
				local new_skill_id = self.extra_.skills[data.index]
				self.skills_[tostring(new_skill_id)] = 1
			end
		elseif floorType == 3 then
			if data.choice == 1 then
				local new_skill_id = self.extra_.buys[data.index]
				self.skills_[tostring(new_skill_id)] = 1
			elseif data.choice == 2 then
				local skill_id = self.extra_.upgrades[data.index]
				self.skills_[tostring(skill_id)] = self.skills_[tostring(skill_id)] + 1
			end
		elseif floorType == 4 then
			if data.choice == 1 then
				for index, partner_info in pairs(self.partnerInfos_) do
					if partner_info.status.hp and partner_info.status.hp > 0 then
						partner_info.status.hp = partner_info.status.hp + 30

						if partner_info.status.hp > 100 then
							partner_info.status.hp = 100
						end
					end
				end
			elseif data.choice == 2 then
				for _, partner_info in ipairs(data.partners) do
					local partner_id = partner_info.partner_id

					if self.partnerInfos_[partner_id] and self.partnerInfos_[partner_id].status.hp > 0 then
						self.partnerInfos_[partner_id].status.hp = self.partnerInfos_[partner_id].status.hp + 60

						if self.partnerInfos_[partner_id].status.hp > 100 then
							self.partnerInfos_[partner_id].status.hp = 100
						end
					end
				end
			elseif data.choice == 3 then
				for _, partner_info in ipairs(data.partners) do
					local partner_id = partner_info.partner_id
					self.partnerInfos_[partner_id].status.hp = 100
				end
			end
		end
	else
		local battle_report = data.battle_result.battle_report

		if battle_report.isWin and battle_report.isWin == 1 then
			self.extra_.can_next = 1
		end

		local hpList = battle_report.hp

		for _, hpInfo in ipairs(hpList) do
			local hp = hpInfo.hp
			local pos = hpInfo.pos
			local partner_id = nil

			for _, fight_partner in ipairs(self.battlePatners_) do
				if fight_partner.pos == pos then
					partner_id = fight_partner.partner_id
				end
			end

			if partner_id and partner_id > 0 then
				self.partnerInfos_[partner_id].status.hp = hp
			end
		end

		local floorTypes = xyd.tables.shrineHurdleTable:getHurdle(self.floor_id_)
		local floorType = floorTypes[self.floor_index_]

		if floorType == 5 then
			self.addGold_ = -1
			self.scoreBefore_ = self.score_
		end

		xyd.BattleController.get():onShrineHurdleBattle(event, false)
	end
end

function ShrineHurdleModel:onGetReport(event)
	local data = xyd.decodeProtoBuf(event.data)
	local isBoss = false

	if self.reqFloor_ and self.reqFloor_ > 0 then
		local floorTypes = xyd.tables.shrineHurdleTable:getHurdle(self.reqFloor_)
		local floorType = floorTypes[1]
		isBoss = floorType == 5
	end

	xyd.BattleController.get():onShrineHurdleReport(data.reports[1], isBoss)
end

function ShrineHurdleModel:getGoldScoreChange()
	if self:checkInGuide() and self:checkInGuide() >= 4 then
		return 90, 50
	elseif self:checkInGuide() and self:checkInGuide() >= 9 then
		return -1, 50
	end

	return self.addGold_ or 0, self.addScore_ or 0
end

function ShrineHurdleModel:checkIsBoss()
	if self:checkInGuide() and self:checkInGuide() >= 9 then
		return 1
	end

	return self.scoreBefore_
end

function ShrineHurdleModel:clearScoreBefore()
	self.scoreBefore_ = nil
end

function ShrineHurdleModel:getHp(table_id)
	if self.partnerInfos_[table_id] and self.partnerInfos_[table_id].status and self.partnerInfos_[table_id].status.hp then
		return self.partnerInfos_[table_id].status.hp
	else
		return 0
	end
end

function ShrineHurdleModel:getDiffNum()
	return self.diff_id_ or 0
end

function ShrineHurdleModel:checkInBattleTime()
	local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
	local serverTime = xyd.getServerTime()
	local timePass = math.fmod(serverTime - self:getStartTime(), (timeSet[1] + timeSet[2]) * xyd.DAY_TIME)

	if not timePass or timePass < 0 or timePass > timeSet[1] * xyd.DAY_TIME then
		return false
	else
		return true
	end
end

function ShrineHurdleModel:getEndTime(isTotal)
	local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
	local lastTime = timeSet[1] * xyd.DAY_TIME

	if isTotal then
		lastTime = lastTime + timeSet[2] * xyd.DAY_TIME
	end

	return self:getStartTime() + lastTime
end

function ShrineHurdleModel:checkFuctionOpen(need_tips)
	local towerStage = xyd.models.towerMap.stage
	local functionOpenTime = xyd.tables.miscTable:getVal("shrine_time_start")
	local needTowerStage = tonumber(xyd.tables.miscTable:getVal("shrine_open_limit", "value"))

	if xyd.getServerTime() < tonumber(functionOpenTime) then
		return false
	end

	if towerStage >= needTowerStage + 1 and xyd.checkFunctionOpen(xyd.FunctionID.SHRINE_HURDLE, true) and self.isAchievment_Open then
		return true
	else
		return false
	end
end

function ShrineHurdleModel:getStartTime()
	return self.start_time_ or 0
end

function ShrineHurdleModel:getRouteID()
	if self:checkInGuide() and self:checkInGuide() > 1 then
		return 500000
	end

	return self.route_id_ or 0
end

function ShrineHurdleModel:getCount()
	return self.count_ or 1
end

function ShrineHurdleModel:getScore()
	if self:checkInGuide() and self:checkInGuide() >= 9 then
		return 100
	elseif self:checkInGuide() and self:checkInGuide() >= 4 then
		return 50
	end

	return self.score_ or 0
end

function ShrineHurdleModel:getMaxScore(route_id)
	return self.historyScores_[route_id]
end

function ShrineHurdleModel:getMaxDiff(route_id)
	if self.diff_ids then
		return self.diff_ids[route_id] or 0
	else
		return 0
	end
end

function ShrineHurdleModel:reqPartnerInfos()
	local msg = messages_pb.shrine_hurdle_get_partners_req()

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_PARTNERS, msg)
end

function ShrineHurdleModel:checkReqPartnerInfos()
	if not self.partnerInfos_ then
		self:reqPartnerInfos()
	end
end

function ShrineHurdleModel:onGetPartners(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.partnerInfos_ = data.partner_infos or {}
end

function ShrineHurdleModel:getPartners()
	return self.partnerInfos_ or {}
end

function ShrineHurdleModel:getGuidePartnerList()
	local list = xyd.models.slot:getSortedPartners()

	if self.guide_partners ~= nil and #self.guide_partners > 0 then
		return self.guide_partners
	end

	local filterList = {}
	local partners = list[tostring(xyd.partnerSortType.isCollected) .. "_0"]

	for j = 1, #partners do
		local partnerID = partners[j]
		local partner = xyd.models.slot:getPartner(partnerID)

		if partner and partner:getStar() >= 10 then
			local partnerInfo = xyd.getPartnerInfo(partner)
			partnerInfo.status = {
				hp = 100,
				mp = 0
			}
			partnerInfo.power = partner:getPower()
			partnerInfo.group = partner:getGroup()
			local newInfo = xyd.getPartnerInfo(partnerInfo)
			newInfo.lev = partnerInfo.level
			newInfo.lv = partnerInfo.level
			filterList[partnerID] = newInfo
		end
	end

	self.guide_partners = filterList

	return self.guide_partners
end

function ShrineHurdleModel:getPartner(partner_id)
	if xyd.models.shrineHurdleModel:checkInGuide() then
		if not self.guide_partners then
			self:getGuidePartnerList()
		end

		return self.guide_partners[partner_id]
	end

	return self.partnerInfos_[partner_id]
end

function ShrineHurdleModel:getFloorInfo()
	local guideIndex = self:checkInGuide()

	if guideIndex and guideIndex <= 3 then
		return 1, 1, 2
	elseif guideIndex and guideIndex > 3 and guideIndex <= 5 then
		return 2, 1, 1
	elseif guideIndex and guideIndex == 6 then
		return 3, 1, 3
	elseif guideIndex and guideIndex > 6 and guideIndex <= 8 then
		return 4, 1, 4
	elseif guideIndex and guideIndex >= 9 then
		return 5, 1, 5
	end

	local floorTypes = xyd.tables.shrineHurdleTable:getHurdle(self.floor_id_)
	local floorType = nil

	if floorTypes and #floorTypes == 1 then
		floorType = floorTypes[1]
	elseif floorTypes and #floorTypes > 1 then
		floorType = floorTypes[self.floor_index_]
	end

	return self.floor_id_ or 0, self.floor_index_ or 0, floorType
end

function ShrineHurdleModel:getExtra()
	local guideIndex = self:checkInGuide()

	if guideIndex and (guideIndex == 2 or guideIndex == 1) then
		return {
			skills = {
				3,
				20,
				2
			}
		}
	elseif guideIndex and guideIndex == 3 then
		return {
			can_next = 1,
			skills = {
				3,
				20,
				2
			}
		}
	elseif guideIndex and guideIndex == 4 then
		return {
			battle_id = 1000,
			can_next = 0
		}
	elseif guideIndex and guideIndex == 5 then
		return {
			battle_id = 1000,
			can_next = 1
		}
	elseif guideIndex and guideIndex == 6 then
		return {
			can_next = 1,
			buys = {
				1,
				3,
				5
			},
			upgrades = {
				20
			}
		}
	elseif guideIndex and guideIndex == 7 then
		return {
			can_next = 0
		}
	elseif guideIndex and guideIndex == 8 then
		return {
			can_next = 1
		}
	elseif guideIndex and guideIndex == 9 then
		return {
			battle_id = 1000,
			can_next = 0
		}
	end

	return self.extra_ or {}
end

function ShrineHurdleModel:getSkillLv(skill_id)
	if self:checkInGuide() and self:checkInGuide() >= 4 then
		if skill_id == 20 or tostring(skill_id) == "20" then
			return 1
		else
			return 0
		end
	end

	return self.skills_[tostring(skill_id)] or self.skills_[tonumber(skill_id)] or 0
end

function ShrineHurdleModel:getSkillList()
	if self:checkInGuide() and self:checkInGuide() >= 4 then
		return {
			[20.0] = 1
		}
	end

	return self.skills_ or {}
end

function ShrineHurdleModel:getGold()
	if self:checkInGuide() and self:checkInGuide() >= 4 then
		return 90
	end

	return self.gold_
end

function ShrineHurdleModel:endHurdle()
	local msg = messages_pb.shrine_hurdle_end_req()

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_END, msg)
end

function ShrineHurdleModel:onEndHurdle()
	local historyscore = self.historyScores_[self.route_id_]

	if not historyscore or historyscore < self.score_ then
		self.overChallengeDiff[self.route_id_] = self.diff_id_
		self.historyScores_[self.route_id_] = self.score_
	end

	if not self.diff_ids then
		self.diff_ids = {}
	end

	if not self.diff_ids[self.route_id_] then
		self.diff_ids[self.route_id_] = self.diff_id_
	elseif self.diff_ids[self.route_id_] < self.diff_id_ then
		self.diff_ids[self.route_id_] = self.diff_id_
	end

	self.last_route_id_ = self.route_id_
	self.route_id_ = 0

	self:getHistoryInfo()
end

function ShrineHurdleModel:getLastRouteID()
	return self.last_route_id_
end

function ShrineHurdleModel:setFlag(plot_id, flag_id)
	local msg = messages_pb.shrine_hurdle_flags_req()

	if plot_id then
		msg.plot_id = tonumber(plot_id)
	end

	if flag_id then
		msg.flag_id = tonumber(flag_id)
	end

	if not self.flags then
		self.flags = {}
	end

	self.flags[tostring(flag_id)] = true

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_FLAGS, msg)
end

function ShrineHurdleModel:onSetFlags(event)
	local data = event.data

	if data.plot_id and tonumber(data.plot_id) > 0 then
		self.plot[tostring(data.plot_id)] = true

		if tonumber(data.plot_id) ~= 1000 then
			local text_id = xyd.tables.shrinePlotListTable:getPlotId(data.plot_id)

			xyd.WindowManager.get():openWindow("story_window", {
				story_id = tonumber(text_id),
				story_type = xyd.StoryType.SHRINE_HURDLE
			})
		end
	end

	if data.flag_id and data.flag_id > 0 then
		self.flags[tostring(data.flag_id)] = true
	end
end

function ShrineHurdleModel:checkUnlockStory(type)
	local ids = xyd.tables.shrinePlotListTable:getListByType(type)
	local unlock_id = 0

	for index, id in ipairs(ids) do
		if not self.plot[tostring(id)] then
			unlock_id = id

			break
		end
	end

	xyd.models.shrineHurdleModel:setFlag(unlock_id)
end

function ShrineHurdleModel:checkPlotRead(plot_id)
	if not self.plot then
		return false
	end

	return self.plot[tostring(plot_id)]
end

function ShrineHurdleModel:setHarm(harm)
	local msg = messages_pb.shrine_hurdle_set_max_diff_req()

	if harm then
		msg.harm = tonumber(harm)
	end

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_SET_MAX_DIFF, msg)
end

function ShrineHurdleModel:onSetHarm(event)
	local diff = event.data.diff
	self.overChallengeDiff = {
		diff,
		diff,
		diff
	}
end

function ShrineHurdleModel:getOverDiff(route_id)
	return self.overChallengeDiff[route_id] or 0
end

function ShrineHurdleModel:fakeBattle(type, partnerParams, pet)
	local petA = nil

	if tonumber(pet) and tonumber(pet) > 0 then
		petA = self:getReportPetById(pet)
	end

	local useTable = nil

	if type == 1 then
		useTable = xyd.tables.shrineHurdleBattleTable
	else
		useTable = xyd.tables.shrineHurdleBossTable
	end

	local battle_id = useTable:getBattleId(1000)
	local herosA = {}
	local herosB = {}

	for _, patnerInfo in ipairs(partnerParams) do
		local hero = self:getReportHeroByPartnerId(patnerInfo.partner_id, patnerInfo.pos)

		table.insert(herosA, hero)
	end

	local str = xyd.tables.battleTable:getMonsters(battle_id)

	if not str or #str <= 0 then
		return
	end

	local poss = xyd.tables.battleTable:getStands(battle_id)

	for i = 1, #str do
		local hero = ReportHero.new()

		hero:populateWithTableID(str[i], {
			pos = poss[i]
		})
		table.insert(herosB, hero)
	end

	local params = {
		maxRound = 15,
		battle_type = xyd.BattleType.SHRINE_HURDLE,
		herosA = herosA,
		herosB = herosB,
		petA = petA,
		guildSkillsA = xyd.models.guild:getGuildSkills(),
		guildSkillsB = {},
		battleID = battle_id,
		god_skills = {
			532001,
			500000,
			500001
		},
		random_seed = math.random(1, 10000)
	}
	local reporter = BattleCreateReport.new(params)

	reporter:run()

	local totalHurm = reporter:getTotalHarm()
	local params2 = {
		event_data = {},
		battle_type = xyd.BattleType.SHRINE_HURDLE
	}
	params2.event_data.battle_report = reporter:getReport()
	params2.event_data.battle_report.total_harm = totalHurm
	params2.event_data.is_win = 1

	if type == 1 then
		params2.event_data.score = 50
		params2.event_data.gold = 90
	else
		params2.event_data.isBoss = true
		params2.isBoss = true
		params2.event_data.score = 100
		params2.event_data.gold = 90
	end

	local guideIndex = xyd.models.shrineHurdleModel:checkInGuide()

	if guideIndex and guideIndex == 10 then
		xyd.models.shrineHurdleModel:setHarm(tonumber(totalHurm))
	end

	xyd.BattleController.get():startBattle(params2)
end

function ShrineHurdleModel:getReportHeroByPartnerId(partnerId, pos)
	local partner = xyd.models.slot:getPartner(partnerId)
	local info = partner:getInfo()
	local hero = ReportHero.new()
	info.table_id = partner.tableID
	info.level = partner.lev
	info.show_skin = partner:isShowSkin()
	info.equips = partner.equipments
	info.love_point = partner.lovePoint
	info.is_vowed = partner.isVowed
	info.pos = pos
	info.potentials = {}

	for i = 1, #partner:getPotential() do
		info.potentials[i] = partner:getPotential()[i]
	end

	hero:populate(info)

	return hero
end

function ShrineHurdleModel:getReportPetById(id)
	if id == 0 then
		return
	end

	local petInfo = xyd.models.petSlot:getPetByID(id)
	local pet = ReportPet.new()
	local skills = {}

	for i = 1, 4 do
		skills[i] = petInfo.skills[i]
	end

	pet:populate({
		pet_id = id,
		grade = petInfo.grade,
		lv = petInfo.lev,
		skills = skills,
		ex_lv = petInfo.ex_lv
	})

	return pet
end

return ShrineHurdleModel
