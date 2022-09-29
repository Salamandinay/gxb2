local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySportsData = class("ActivitySportsData", ActivityData, true)

function ActivitySportsData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.SPORTS_BET, handler(self, self.onSportsBet))
end

function ActivitySportsData:onSportsBet(event)
	self.detail.bet_records = event.data.bet_records

	if not self.detail.mission_count then
		self.detail.mission_count = {}
	end

	self.detail.mission_count[3] = 1

	xyd.models.redMark:setMark(xyd.RedMarkType.SPORTS, self:getRedMarkState())
end

function ActivitySportsData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activity:getLastTime(self.activity_id)
end

function ActivitySportsData:getStateEndTime()
	local state = self:getNowState()
	local daysArr = xyd.tables.miscTable:split2num("activity_sports_time_interval", "value", "|")

	if state == 1 then
		return self.start_time + daysArr[1]
	elseif state == 2 then
		return self.start_time + daysArr[1] + daysArr[2]
	elseif state == 3 then
		return self.start_time + daysArr[1] + daysArr[2] + daysArr[3]
	else
		return self.start_time + daysArr[1] + daysArr[2] + daysArr[3] + daysArr[4]
	end
end

function ActivitySportsData:getNowState()
	local daysArr = xyd.tables.miscTable:split2num("activity_sports_time_interval", "value", "|")

	if xyd.getServerTime() < self.start_time + daysArr[1] then
		return 1
	elseif xyd.getServerTime() < self.start_time + daysArr[1] + daysArr[2] then
		return 2
	elseif xyd.getServerTime() < self.start_time + daysArr[1] + daysArr[2] + daysArr[3] then
		return 3
	elseif xyd.getServerTime() < self.start_time + daysArr[1] + daysArr[2] + daysArr[3] + daysArr[4] then
		return 4
	else
		return 5
	end
end

function ActivitySportsData:isFinalBeforeDay()
	local state = self:getNowState()

	if state == 4 then
		local daysArr = xyd.tables.miscTable:split2num("activity_sports_time_interval", "value", "|")

		if xyd.getServerTime() >= self.start_time + daysArr[1] + daysArr[2] + daysArr[3] + daysArr[4] - xyd.DAY_TIME then
			return true
		end
	end

	return false
end

function ActivitySportsData:isFinalDay()
	local state = self:getNowState()

	return state == 5
end

function ActivitySportsData:getDayIndex()
	local alreadTime = xyd.getServerTime() - self.start_time

	return math.ceil(alreadTime / 86400)
end

function ActivitySportsData:onAward(data)
	local newDetail = json.decode(data.detail)

	if newDetail.plot_ids and next(newDetail.plot_ids) then
		self.detail.travel_info.plot_ids = newDetail.plot_ids
	end

	if newDetail.mission_awarded then
		self.detail.mission_awarded = newDetail.mission_awarded
	end

	if newDetail.achieve_type then
		self:updateAchieve(newDetail)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.SPORTS, self:getRedMarkState())
end

function ActivitySportsData:getMissionRed()
	local ids = {}
	local state = self:getNowState()
	local missions = xyd.tables.activitySportsMissionTable:getIds()

	if state == xyd.ActivitySportsTime.SHOW or self:isFinalBeforeDay() then
		return false
	else
		local missionCount = self.detail.mission_count or {}
		local missionAward = self.detail.mission_awarded or {}

		for i = 1, #missions do
			local id = missions[i]

			if state == xyd.ActivitySportsTime.FIGHT_ALL or not xyd.tables.activitySportsMissionTable:isLimit(id) and state == 1 then
				local completeNum = xyd.tables.activitySportsMissionTable:getCompleteValue(id)

				if completeNum <= missionCount[i] and (not missionAward[i] or missionAward[i] == 0) then
					table.insert(ids, id)
				end
			end
		end

		return #ids > 0
	end
end

function ActivitySportsData:getAchieveRed()
	local ids = {}
	local list = self.detail.achievement_list.achievements or {}

	for _, achieve in ipairs(list) do
		local compValue = xyd.tables.activitySportsAchievementTable:getCompleteValue(achieve.achieve_id)

		if compValue and achieve.achieve_id > 0 and compValue <= achieve.value then
			return true
		end
	end

	return false
end

function ActivitySportsData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:getAchieveRed() or self:getMissionRed() then
		return true
	else
		return false
	end
end

function ActivitySportsData:updateAchieve(newDetail)
	local list = self.detail.achievement_list.achievements or {}

	for i = 1, #list do
		if list[i].achieve_type == newDetail.achieve_type then
			list[i].achieve_id = newDetail.achieve_id

			break
		end
	end
end

function ActivitySportsData:checkAchieveRedPoint()
	local ids = {}
	local list = self.detail.achievement_list.achievements or {}
	local a_t = xyd.tables.activitySportsAchievementTable

	for key, item in pairs(list) do
		if item.achieve_id > 0 and a_t:getCompleteValue(item.achieve_id) <= item.value then
			table.insert(ids, item.achieve_id)

			break
		end
	end

	return #ids > 0
end

return ActivitySportsData
