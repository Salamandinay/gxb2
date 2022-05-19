local BaseModel = import(".BaseModel")
local AcademyAssessment = class("AcademyAssessment", BaseModel)

function AcademyAssessment:ctor()
	AcademyAssessment.super.ctor(self)

	self.currentStages = {}
	self.maxStages = {}
	self.buySweepTimes = 0
	self.challengeTimes = 0
	self.sweepTimes = 0
end

function AcademyAssessment:onRegister()
	AcademyAssessment.super.onRegister(self)
	self:registerEvent(xyd.event.SCHOOL_PRACTICE_INFO, handler(self, self.onInfo))
	self:registerEvent(xyd.event.SCHOOL_PRACTICE_GET_INFO, handler(self, self.onInfo))
	self:registerEvent(xyd.event.LEV_CHANGE, handler(self, function ()
		if self:getHasData() == false and xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
			xyd.models.academyAssessment:reqInfo()
		end
	end))
	self:registerEvent(xyd.event.SCHOOL_PRACTICE_BUY_TICKETS, function (self, event)
		local mapInfo = event.data.map_info
		self.challengeTimes = mapInfo.challenge_times
		self.buySweepTimes = mapInfo.daily_buy_sweep_times
		self.sweepTimes = mapInfo.sweep_times
		self.data.map_info = mapInfo

		self:setRedMark()
	end, self)
	self:registerEvent(xyd.event.SCHOOL_PRACTICE_FIGHT, function (self, event)
		local data = event.data
		local fortInfo = data.fort_info
		local mapInfo = data.map_info
		self.currentStages[fortInfo.fort_id] = fortInfo.current_stage
		self.maxStages[fortInfo.fort_id] = fortInfo.max_stage
		self.challengeTimes = mapInfo.challenge_times
		self.buySweepTimes = mapInfo.daily_buy_sweep_times
		self.sweepTimes = mapInfo.sweep_times
		self.data.map_info = mapInfo
		self.selfScore = mapInfo.score
		self.historyScore = mapInfo.history_score

		for i = 1, #self.data.map_list do
			if self.data.map_list[i].fort_id == fortInfo.fort_id then
				self.data.map_list[i] = fortInfo

				break
			end

			i = i + 1
		end

		self:setRedMark()
	end, self)
	self:registerEvent(xyd.event.SCHOOL_PRACTICE_SWEEP, function (self, event)
		local mapInfo = event.data.map_info
		self.challengeTimes = mapInfo.challenge_times
		self.buySweepTimes = mapInfo.daily_buy_sweep_times
		self.sweepTimes = mapInfo.sweep_times
		self.data.map_info = mapInfo
		self.selfScore = mapInfo.score
		self.historyScore = mapInfo.history_score

		self:setRedMark()
	end, self)
	self:registerEvent(xyd.event.SCHOOL_BATCH_FAKE_FIGHT, function (self, event)
		local data = event.data
		local fortInfo = data.fort_info
		local mapInfo = data.map_info
		self.currentStages[fortInfo.fort_id] = fortInfo.current_stage
		self.maxStages[fortInfo.fort_id] = fortInfo.max_stage
		self.challengeTimes = mapInfo.challenge_times
		self.buySweepTimes = mapInfo.daily_buy_sweep_times
		self.sweepTimes = mapInfo.sweep_times
		self.data.map_info = mapInfo
		self.selfScore = mapInfo.score
		self.historyScore = mapInfo.history_score

		for i = 1, #self.data.map_list do
			if self.data.map_list[i].fort_id == fortInfo.fort_id then
				self.data.map_list[i] = fortInfo

				break
			end

			i = i + 1
		end

		self:setRedMark()
	end, self)
end

function AcademyAssessment:onInfo(event)
	local data = event.data
	local mapInfo = data.map_info
	local mapList = data.map_list
	self.data = {
		map_info = mapInfo,
		map_list = mapList
	}

	for _, info in pairs(mapList) do
		if info.fort_id then
			self.currentStages[info.fort_id] = info.current_stage
		end
	end

	for _, info in pairs(mapList) do
		if info.fort_id then
			self.maxStages[info.fort_id] = info.max_stage
		end
	end

	self.buySweepTimes = mapInfo.daily_buy_sweep_times
	self.challengeTimes = mapInfo.challenge_times
	self.sweepTimes = mapInfo.sweep_times
	self.seasonId = mapInfo.count
	self.selfScore = mapInfo.score
	self.startTime = mapInfo.start_time
	self.historyScore = mapInfo.history_score
end

function AcademyAssessment:getBuySweepTimes()
	return self.buySweepTimes
end

function AcademyAssessment:getChallengeTimes()
	return self.challengeTimes
end

function AcademyAssessment:getSweepTimes()
	return self.sweepTimes
end

function AcademyAssessment:getData()
	return self.data
end

function AcademyAssessment:getHasData()
	local isHasData = false

	if self.data and #self.currentStages ~= 0 then
		return true
	end

	return isHasData
end

function AcademyAssessment:reqSweep(id, times)
	if self:checkTimeEnd() == false then
		xyd.showToast(__("ACADEMY_ASSESSMENT_END_TIPS"))

		return
	end

	local msg = messages_pb.school_practice_sweep_req()
	msg.stage_id = id
	msg.sweep_times = times

	xyd.Backend.get():request(xyd.mid.SCHOOL_PRACTICE_SWEEP, msg)
end

function AcademyAssessment:reqFight(stageId, partners, petId)
	if self:checkTimeEnd() == false then
		xyd.showToast(__("ACADEMY_ASSESSMENT_END_TIPS"))

		return
	end

	local msg = messages_pb.school_practice_fight_req()
	msg.stage_id = stageId

	for _, p in pairs(partners) do
		local fightPartnerMsg = messages_pb.fight_partner()
		fightPartnerMsg.partner_id = p.partner_id
		fightPartnerMsg.pos = p.pos

		table.insert(msg.partners, fightPartnerMsg)
	end

	msg.pet_id = petId

	xyd.Backend.get():request(xyd.mid.SCHOOL_PRACTICE_FIGHT, msg)
	xyd.db.misc:setValue({
		key = "cur_academy_assessment_stage_id",
		value = stageId
	})
end

function AcademyAssessment:reqBuyTickets(id, num)
	local msg = messages_pb.school_practice_buy_tickets_req()
	msg.ticket_type = id
	msg.times = num

	xyd.Backend.get():request(xyd.mid.SCHOOL_PRACTICE_BUY_TICKETS, msg)
end

function AcademyAssessment:reqInfo()
	local msg = messages_pb.school_practice_get_info_req()

	xyd.Backend.get():request(xyd.mid.SCHOOL_PRACTICE_GET_INFO, msg)
end

function AcademyAssessment:getCurrentStage(fortId)
	return self.currentStages[fortId]
end

function AcademyAssessment:getMaxStage(fortId)
	return self.maxStages[fortId]
end

function AcademyAssessment:setRedMark()
	xyd.models.redMark:setMark(xyd.RedMarkType.ACADEMY_ASSESSMENT, self:checkRedMark())
end

function AcademyAssessment:checkRedMark()
	if not xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
		return false
	end

	if self:checkTimeEnd() == false then
		return false
	end

	if not self.data or #self.currentStages == 0 then
		return false
	end

	if self:getIsNewSeason() and not xyd.db.misc:getValue("academy_assessment_pop_up_window_pop_state" .. self.seasonId) then
		return true
	end

	local infos = self.data.map_list

	for i = 1, #infos do
		local info = infos[i]
		local firstStage = self:getAcademyAssessMentTable():getFirstId(info.fort_id)

		if (info.current_stage - firstStage >= 1 or info.current_stage == -1) and self.sweepTimes > 0 then
			return true
		end

		local timeStamp = xyd.db.misc:getValue("academy_assessment_daily_redpoint")

		if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime())) and info.current_stage < info.max_stage - 30 and self.data.map_info.challenge_times > 0 then
			return true
		end
	end

	return false
end

function AcademyAssessment:getIsNewSeason()
	if self.seasonId and self.seasonId > 0 then
		return true
	else
		return false
	end
end

function AcademyAssessment:checkTimeEnd()
	if self:getIsNewSeason() then
		local startTime = xyd.models.academyAssessment.startTime
		local allTime = xyd.tables.miscTable:getNumber("school_practise_season_duration", "value")
		local showTime = xyd.tables.miscTable:getNumber("school_practise_display_duration", "value")
		local durationTime = startTime + allTime - showTime - xyd.getServerTime()

		if xyd.getServerTime() < startTime + allTime - showTime and startTime <= xyd.getServerTime() then
			return true
		elseif xyd.getServerTime() < startTime + allTime and xyd.getServerTime() >= startTime + allTime - showTime then
			return false
		else
			return false
		end
	else
		return true
	end

	return true
end

function AcademyAssessment:getAcademyAssessMentTable()
	if self:getIsNewSeason() then
		local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

		if tonumber(time) <= xyd.getServerTime() then
			return xyd.tables.academyAssessmentNewTable2
		else
			return xyd.tables.academyAssessmentNewTable
		end
	else
		return xyd.tables.academyAssessmentTable
	end
end

function AcademyAssessment:readStorageFormation(fortId)
	local dbVal = xyd.db.formation:getValue(xyd.BattleType.ACADEMY_ASSESSMENT .. "_" .. fortId)

	if not dbVal then
		return false
	end

	local data = require("cjson").decode(dbVal)

	if not data.partners then
		return false
	end

	self.temp_pet = data.pet_id or 0
	local tmpPartnerList = data.partners
	local nowPartnerList = {}

	for i = #tmpPartnerList, 1, -1 do
		local sPartnerID = tonumber(tmpPartnerList[i])

		if xyd.models.slot:getPartner(sPartnerID) then
			nowPartnerList[i] = {
				partner_id = sPartnerID,
				pos = i
			}
		end
	end

	return nowPartnerList
end

function AcademyAssessment:onNextBattle(nextId)
	local fortId = xyd.tables.academyAssessmentNewTable:getFortID(nextId)
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if tonumber(time) <= xyd.getServerTime() then
		fortId = xyd.tables.academyAssessmentNewTable2:getFortID(nextId)
	end

	local partnerParams = self:readStorageFormation(fortId)

	self:reqFight(nextId, partnerParams, self.temp_pet)
end

function AcademyAssessment:getAwardPointTable()
	local time = xyd.tables.miscTable:getVal("school_practise_switch_time")

	if xyd.getServerTime() < tonumber(xyd.tables.miscTable:getVal("school_practise_point_time_stamp")) then
		if tonumber(time) <= xyd.getServerTime() then
			return xyd.tables.schoolPractisePointTableNew
		else
			return xyd.tables.schoolPractisePointTable2
		end
	elseif tonumber(time) <= xyd.getServerTime() then
		return xyd.tables.schoolPractisePointTableNew
	else
		return xyd.tables.schoolPractisePointTable
	end
end

function AcademyAssessment:checkFunctionOpen()
	if not self.data then
		return false
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.ACADEMY_ASSESSMENT, true) then
		return false
	end

	return true
end

return AcademyAssessment
