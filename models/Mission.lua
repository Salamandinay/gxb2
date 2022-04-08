local Mission = class("Mission", import(".BaseModel"))

function Mission:ctor()
	Mission.super.ctor(self)

	self.missions_ = {}
	self.filteredMissions_ = {}
	self.redPoint_ = nil
	self.endTime_ = 0
	self.show_final_mission_ = false
end

function Mission:checkCanBattlePass()
	if xyd.models.activity:getBattlePassData() then
		return true
	else
		return false
	end
end

function Mission:getData()
	local msg = messages_pb.get_mission_list_req()

	xyd.Backend.get():request(xyd.mid.GET_MISSION_LIST, msg)
end

function Mission:onGetData(event)
	self.missions_ = {}
	local missions = event.data.missions
	self.endTime_ = event.data.end_time
	self.weekEndTime_ = event.data.weekly_end_time

	for _, data in ipairs(missions) do
		local mission = {
			mission_id = data.mission_id or 0,
			is_completed = data.is_completed or 0,
			is_awarded = data.is_awarded or 0,
			value = data.value or 0,
			extra = data.extra or 0
		}

		table.insert(self.missions_, mission)
	end

	self:sortMission()
	self:missionFilter()
	self:updateRedPoint()
end

function Mission:getNowMissionTable()
	if self.checkCanBattlePass() then
		return xyd.tables.battlePassMissionTable
	else
		return xyd.tables.dailyMissionTable
	end
end

function Mission:getBattlePassLeftTime()
	local bpData = xyd.models.activity:getBattlePassData()
	local bpId = xyd.models.activity:getBattlePassId()
	local startTime = xyd.tables.miscTable:getNumber("bp_start_time", "value")

	if bpData then
		startTime = bpData:startTime()
	end

	local totalTime = xyd.getServerTime() - startTime
	local bpDuration = xyd.tables.miscTable:getNumber("bp_duration", "value")
	local durationTime = bpDuration - totalTime % bpDuration

	return durationTime
end

function Mission:sortMission()
	table.sort(self.missions_, function (a, b)
		local ranka = self:getNowMissionTable():getRank(a.mission_id)
		local rankb = self:getNowMissionTable():getRank(b.mission_id)

		if ranka and rankb then
			local weight_a = a.is_awarded * 100 + (1 - a.is_completed) * 10 + ranka
			local weight_b = b.is_awarded * 100 + (1 - b.is_completed) * 10 + rankb

			return weight_a < weight_b
		elseif ranka and not rankb then
			return false
		elseif not ranka and rankb then
			return true
		else
			if a.is_completed == 1 and b.is_completed ~= 1 then
				return false
			elseif a.is_completed ~= 1 and b.is_completed == 1 then
				return true
			end

			return false
		end
	end)
end

function Mission:missionFilter()
	self.filteredMissions_ = {}
	local lv = xyd.models.backpack:getLev()

	if self:checkCanBattlePass() then
		self.show_final_mission_ = true

		for _, data in ipairs(self.missions_) do
			local missionId = data.mission_id
			local limitLev = xyd.tables.battlePassMissionTable:getLevLimit(missionId)
			local limitBp = xyd.tables.battlePassMissionTable:getBpLimit(missionId)

			if limitLev ~= -1 and limitLev <= lv and limitBp <= xyd.getBpLev() then
				table.insert(self.filteredMissions_, data)
			elseif xyd.tables.battlePassMissionTable:getType(missionId) == xyd.MissionType.TODAY and limitLev ~= -1 then
				self.show_final_mission_ = false
			end
		end
	else
		for _, data in ipairs(self.missions_) do
			local limitLev = xyd.tables.dailyMissionTable:getLevLimit(data.mission_id)

			if limitLev and limitLev ~= -1 and limitLev <= lv then
				table.insert(self.filteredMissions_, data)
			end
		end

		if #self.filteredMissions_ + 1 == #self.missions_ then
			self.show_final_mission_ = true
		else
			self.show_final_mission_ = false
		end
	end
end

function Mission:onCheckLevUp()
end

function Mission:onGetAward(event)
	local mission_id = event.data.mission_id

	self:setMissionAward(mission_id)
	self:sortMission()
	self:missionFilter()
	self:updateRedPoint()
end

function Mission:setMissionAward(mission_id)
	for _, data in ipairs(self.missions_) do
		if mission_id == data.mission_id then
			data.is_awarded = 1

			break
		end
	end
end

function Mission:onGetAwards(event)
	local result = event.data.result

	for _, data in ipairs(result) do
		local mission_id = data.mission_id

		self:setMissionAward(mission_id)
	end

	self:sortMission()
	self:missionFilter()
	self:updateRedPoint()
end

function Mission:onRegister()
	Mission.super.onRegister(self)
	self:registerEvent(xyd.event.GET_MISSION_LIST, handler(self, self.onGetData))
	self:registerEvent(xyd.event.GET_MISSION_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.GET_MISSION_AWARDS, handler(self, self.onGetAwards))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onCheckLevUp))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.onSystemUpdate))
end

function Mission:getEndTime()
	return self.endTime_
end

function Mission:getMissionList()
	return self.filteredMissions_
end

function Mission:getWeeklyEndTime()
	return self.weekEndTime_
end

function Mission:getFinalMissionInfo()
	for _, data in ipairs(self.missions_) do
		if data.mission_id == Mission.ALL_COMPLETE_MISSION_ID then
			return data
		end
	end
end

function Mission:checkMissionOpen(missionId)
	local limitLev = xyd.tables.battlePassMissionTable:getLevLimit(missionId)
	local limitBp = xyd.tables.battlePassMissionTable:getBpLimit(missionId)

	if limitLev and limitBp and limitLev ~= -1 and limitLev <= xyd.models.backpack:getLev() and limitBp <= xyd.getBpLev() then
		return true
	else
		return false
	end
end

function Mission:updateRedPoint()
	self.redPoint = false

	xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION1, false)
	xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION2, false)
	xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION3, false)

	for key in pairs(self.missions_) do
		if self.missions_[key].is_completed == 1 and self.missions_[key].is_awarded == 0 and self:checkMissionOpen(self.missions_[key].mission_id) then
			local id = self.missions_[key].mission_id
			local type = xyd.tables.battlePassMissionTable:getType(id)

			if self:checkCanBattlePass() then
				if type == 1 then
					self.redPoint = true
				end

				if type == 1 then
					xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION1, true)
				elseif type == 2 then
					xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION2, true)
				else
					xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS_MISSION3, true)
				end
			else
				self.redPoint = true
			end
		end
	end

	if not xyd.checkFunctionOpen(xyd.FunctionID.MISSION, true) then
		self.redPoint = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.MISSION, self.redPoint)

	local time = nil

	if self.redPoint == true then
		time = xyd.getServerTime() + xyd.tables.deviceNotifyTable:getDelayTime(xyd.DEVICE_NOTIFY.MISSION)
	else
		time = 0
	end

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.MISSION, time)
end

function Mission:onSystemUpdate()
	self:getData()
end

function Mission:getDailyMissionFinished()
	local mission = self:getMissionList()
	local flag = true

	if mission ~= nil then
		for key, value in pairs(mission) do
			if value.is_awarded ~= nil and value.is_awarded ~= 1 and xyd.tables.battlePassMissionTable:getType(value.mission_id) == xyd.MissionType.TODAY then
				flag = false

				break
			end
		end
	end

	return flag
end

function Mission:getAward(id)
	local msg = messages_pb.get_mission_award_req()
	msg.mission_id = id

	xyd.Backend.get():request(xyd.mid.GET_MISSION_AWARD, msg)
end

function Mission:reqAwardList(ids)
	local msg = messages_pb.get_mission_awards_req()

	for _, id in ipairs(ids) do
		table.insert(msg.mission_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.GET_MISSION_AWARDS, msg)
end

function Mission:showFinalMission()
	return self.show_final_mission_
end

function Mission:showRedPoint()
	return self.redPoint
end

Mission.ALL_COMPLETE_MISSION_ID = 11

return Mission
