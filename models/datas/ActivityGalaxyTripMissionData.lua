local ActivityData = import("app.models.ActivityData")
local ActivityGalaxyTripMissionData = class("ActivityGalaxyTripMissionData", ActivityData, true)
local json = require("cjson")

function ActivityGalaxyTripMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGalaxyTripMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	return flag
end

function ActivityGalaxyTripMissionData:register()
	self:registerEvent(xyd.event.GALAXY_TRIP_GET_MISSIONS_INFO, self.onGetTaskInfo, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityGalaxyTripMissionData:getCurSeason()
	return self.detail_.act_count
end

function ActivityGalaxyTripMissionData:getTotalEnergy()
	local totalEnergy = xyd.models.galaxyTrip:getGalaxyTripGetMainScore()

	return totalEnergy
end

function ActivityGalaxyTripMissionData:IfBuyGiftBag()
	return self.detail_.charges[1].buy_times > 0
end

function ActivityGalaxyTripMissionData:setHaveBuyGiftbag()
	self.detail_.charges[1].buy_times = self.detail_.charges[1].buy_times + 1
end

function ActivityGalaxyTripMissionData:getTaskCompleteValue(id)
	return self.taskInfo[id].value
end

function ActivityGalaxyTripMissionData:getTaskAwarded(id)
	return self.taskInfo[id].is_completed > 0
end

function ActivityGalaxyTripMissionData:getFreeAwardAwarded(id)
	return self.detail_.awarded[id] > 0
end

function ActivityGalaxyTripMissionData:getPaidAwardAwarded(id)
	return self.detail_.paid_awarded[id] > 0
end

function ActivityGalaxyTripMissionData:checkRedMaskOfTask()
	local red = false

	return red
end

function ActivityGalaxyTripMissionData:checkRedMaskOfAward()
	local red = false
	local ids = xyd.tables.galaxyTripBattlepassTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if xyd.tables.galaxyTripBattlepassTable:getPointLimit(id) <= self:getTotalEnergy() and (not self:getFreeAwardAwarded(id) or not self:getPaidAwardAwarded(id) and self:IfBuyGiftBag() == true) then
			red = true
		end
	end

	return red
end

function ActivityGalaxyTripMissionData:checkNeedReqTaskInfo()
	if not self.taskInfo or xyd.getServerTime() - self.reqTaskTime > 30 then
		if not self.isReqing then
			self.isReqing = true

			self:reqTaskInfo()
		end

		return true
	else
		return false
	end
end

function ActivityGalaxyTripMissionData:onGetTaskInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.taskInfo = data.missions
	self.reqTaskTime = xyd.getServerTime()
	self.isReqing = false
end

function ActivityGalaxyTripMissionData:reqTaskInfo()
	local msg = messages_pb:galaxy_trip_get_missions_info_req()
	local ids = xyd.tables.galaxyTripMissionTable:getIDs()

	for _, id in ipairs(ids) do
		table.insert(msg.mission_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MISSIONS_INFO, msg)
end

function ActivityGalaxyTripMissionData:onGetAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION then
		return
	end

	local ids = xyd.tables.galaxyTripBattlepassTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		dump(data)
		dump(self.detail_)
		dump(self.detail_.awarded)
		dump(self.detail_.paid_awarded)

		if xyd.tables.galaxyTripBattlepassTable:getPointLimit(id) <= self:getTotalEnergy() then
			if not self:getFreeAwardAwarded(id) then
				self.detail_.awarded[id] = 1
			end

			if not self:getPaidAwardAwarded(id) and self:IfBuyGiftBag() == true then
				self.detail_.paid_awarded[id] = 1
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GALAXY_TRIP, self:checkRedMaskOfAward())
end

return ActivityGalaxyTripMissionData
