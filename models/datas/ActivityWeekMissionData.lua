local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityWeekMissionData = class("ActivityWeekMissionData", ActivityData, true)

function ActivityWeekMissionData:getNowDays()
	self.nowDays = math.ceil((xyd.getServerTime() - self.detail.update_time) / xyd.TimePeriod.DAY_TIME)

	return self.nowDays
end

function ActivityWeekMissionData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_NEW_ROOKIE_MISSION_AWARD, handler(self, self.onMissionAward))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_NEW_ROOKIE_POINT_AWARD, handler(self, self.onGetPointAward))
end

function ActivityWeekMissionData:setChooseDiamond(id)
	self.diamondID = id
end

function ActivityWeekMissionData:setChooseMission(id)
	self.missionID = id
end

function ActivityWeekMissionData:onAward()
	self.detail.buy_times[self.diamondID] = self.detail.buy_times[self.diamondID] + 1
	self.detail.point = self.detail.point + 1

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.WEEK_MISSION, function ()
	end)
end

function ActivityWeekMissionData:onMissionAward(event)
	local missionList = self.detail.missions

	for _, mission in pairs(missionList) do
		if mission.mission_id == event.data.mission_id then
			mission.is_awarded = 1
			self.detail.point = self.detail.point + 1
		end
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.WEEK_MISSION, function ()
	end)
end

function ActivityWeekMissionData:onGetPointAward(event)
	self.detail.point_awarded[event.data.id] = 1
end

function ActivityWeekMissionData:reqActivity()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.WEEK_MISSION)
end

function ActivityWeekMissionData:hasDayRedPoint(day)
	local ids = xyd.tables.activityWeekMissionTable:getMissionListByDay(day)

	if not ids then
		return false
	end

	for i = 1, 3 do
		local list = ids[i]

		for _, id in pairs(list) do
			local mission = self.detail.missions[tonumber(id)]

			if mission.is_completed == 1 and mission.is_awarded == 0 then
				return true
			end
		end
	end

	local ids2 = xyd.tables.activityWeekExchangeTable:getMissionList(day)

	for _, id in pairs(ids2) do
		local buyTimes = self.detail.buy_times[tonumber(id)]
		local cost = xyd.tables.activityWeekExchangeTable:getCost(id)

		if #cost == 0 and buyTimes == 0 then
			return true
		end
	end

	return false
end

function ActivityWeekMissionData:hasTagRedPoint(day, tag)
	if tag ~= 4 then
		local ids = xyd.tables.activityWeekMissionTable:getMissionList(day, tag)

		for _, id in pairs(ids) do
			local mission = self.detail.missions[tonumber(id)]

			if mission.is_completed == 1 and mission.is_awarded == 0 then
				return true
			end
		end
	else
		local ids = xyd.tables.activityWeekExchangeTable:getMissionList(day)

		for _, id in pairs(ids) do
			local buyTimes = self.detail.buy_times[tonumber(id)]
			local cost = xyd.tables.activityWeekExchangeTable:getCost(id)

			if #cost == 0 and buyTimes == 0 then
				return true
			end
		end
	end

	return false
end

function ActivityWeekMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, self:getNowDays() do
		if self:hasDayRedPoint(i) then
			return true
		end
	end

	return false
end

function ActivityWeekMissionData:getEndTime()
	return self.update_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityWeekMissionData:getUpdateTime()
	return self.detail.update_time + xyd.TimePeriod.WEEK_TIME
end

return ActivityWeekMissionData
