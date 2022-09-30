local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityAngleTeaPartyData = class("ActivityAngleTeaPartyData", ActivityData, true)

function ActivityAngleTeaPartyData:ctor(params)
	ActivityData.ctor(self, params)
	self:initData()
	self:register()
end

function ActivityAngleTeaPartyData:initData()
	self.awardTable = xyd.tables.activityAngleTeaPartyAwardTable
	self.needPoints = {}
	self.awards = {}
	self.plotIDs = {}
	self.battleIDs = {}
	local ids = self.awardTable:getIDs()

	for i = 1, #ids do
		local id = i
		local needPoint = self.awardTable:getPoint(id)

		table.insert(self.needPoints, needPoint)

		local plotID = self.awardTable:getPlotID(id)

		table.insert(self.plotIDs, plotID)

		local battleID = self.awardTable:getBattleID(id)

		table.insert(self.battleIDs, battleID)

		local award = self.awardTable:getAwards(id)

		table.insert(self.awards, award)
	end
end

function ActivityAngleTeaPartyData:onAward(event)
	local data = event

	if data and type(data) == "number" then
		self.detail.charges[1].buy_times = 1 + self.detail.charges[1].buy_times
	end
end

function ActivityAngleTeaPartyData:register()
	self:registerEvent(xyd.event.GET_MISSION_AWARDS, function ()
		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
	end)
	self:registerEvent(xyd.event.GET_MISSION_AWARD, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY then
			return
		end

		self:getRedMarkState()
	end)
end

function ActivityAngleTeaPartyData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityAngleTeaPartyData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		xyd.db.misc:setValue({
			value = "1",
			key = "ActivityFirstRedMark_" .. xyd.ActivityID.ACTIVITY_ANGLE_TEA_PARTY .. "_" .. self.end_time
		})
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ANGLE_TEA_PARTY, true)

		return true
	end

	if self:checkRedPoint_goto() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ANGLE_TEA_PARTY, true)

		return true
	end

	local flag = false

	for i = 1, 4 do
		if self:checkRedPoint_cup(i) == true or self:checkRedPoint_award(i) == true then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ANGLE_TEA_PARTY, true)

			return true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ANGLE_TEA_PARTY, flag)

	return flag
end

function ActivityAngleTeaPartyData:checkRedPoint_cup(id)
	local flag = false

	if (self.needPoints[id] <= self.detail.point or self.detail.charges[1].buy_times > 0) and self:getNowCharterState() < id then
		return true
	end

	return flag
end

function ActivityAngleTeaPartyData:checkRedPoint_award(id)
	local flag = false

	if (self.needPoints[id] <= self.detail.point or self.detail.charges[1].buy_times > 0) and self.detail.awarded[id] ~= 1 and id <= self:getNowCharterState() then
		return true
	end

	return flag
end

function ActivityAngleTeaPartyData:checkRedPoint_goto()
	local flag = false

	if xyd.db.misc:getValue("angle_tea_party_goto_red_mask_timestamp") == nil then
		xyd.db.misc:setValue({
			key = "angle_tea_party_goto_red_mask_timestamp",
			value = xyd.getServerTime()
		})

		return true
	end

	if self.needPoints[4] <= self.detail.point or self.detail.charges[1].buy_times > 0 then
		return false
	end

	if not xyd.isSameDay(xyd.getServerTime(), tonumber(xyd.db.misc:getValue("angle_tea_party_goto_red_mask_timestamp"))) and self.detail.charges[1].buy_times <= 0 then
		return true
	end

	local mission = xyd.models.mission:getMissionList()

	if mission ~= nil then
		for key, value in pairs(mission) do
			if value.is_awarded ~= nil and xyd.tables.battlePassMissionTable:getType(value.mission_id) == xyd.MissionType.TODAY and value.is_awarded ~= 1 then
				flag = true
			end
		end
	end

	return flag
end

function ActivityAngleTeaPartyData:getNowCharterState()
	if xyd.db.misc:getValue("angle_tea_party_charter_state") == nil then
		local stateinfo = {
			timeStamp = 0,
			stateNum = 0
		}

		xyd.db.misc:setValue({
			key = "angle_tea_party_charter_state",
			value = json.encode(stateinfo)
		})
	else
		local timeStamp = json.decode(xyd.db.misc:getValue("angle_tea_party_charter_state")).timeStamp

		if timeStamp == nil or timeStamp < self.start_time or self.end_time < timeStamp then
			local stateinfo = {
				stateNum = 0,
				timeStamp = xyd.getServerTime()
			}

			xyd.db.misc:setValue({
				key = "angle_tea_party_charter_state",
				value = json.encode(stateinfo)
			})
		end
	end

	local stateNum = json.decode(xyd.db.misc:getValue("angle_tea_party_charter_state")).stateNum

	return tonumber(stateNum)
end

function ActivityAngleTeaPartyData:setNowCharterState(state)
	if xyd.db.misc:getValue("angle_tea_party_charter_state") == nil then
		local stateinfo = {
			timeStamp = 0,
			stateNum = 0
		}

		xyd.db.misc:setValue({
			key = "angle_tea_party_charter_state",
			value = json.encode(stateinfo)
		})
	else
		local timeStamp = json.decode(xyd.db.misc:getValue("angle_tea_party_charter_state")).timeStamp

		if timeStamp == nil or timeStamp < self.start_time or self.end_time < timeStamp then
			local stateinfo = {
				stateNum = 0,
				timeStamp = xyd.getServerTime()
			}

			xyd.db.misc:setValue({
				key = "angle_tea_party_charter_state",
				value = json.encode(stateinfo)
			})
		end
	end

	local stateinfo = {
		stateNum = state,
		timeStamp = xyd.getServerTime()
	}

	xyd.db.misc:setValue({
		key = "angle_tea_party_charter_state",
		value = json.encode(stateinfo)
	})
end

return ActivityAngleTeaPartyData
