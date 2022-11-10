local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewGrowthPlanData = class("ActivityNewGrowthPlanData", ActivityData, true)
local activityGrowthPlanTable = xyd.tables.activityNewGrowthAwardTable

function ActivityNewGrowthPlanData:getUpdateTime()
	return self:getEndTime()
end

function ActivityNewGrowthPlanData:getEndTime()
	return self.detail.start_time + xyd.tables.miscTable:getNumber("activity_new_growth_plan_start3", "value") * 24 * 60 * 60
end

function ActivityNewGrowthPlanData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = xyd.decodeProtoBuf(event.data)

		if data and data.activity_id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
			local json = require("cjson")
			local detail = json.decode(data.detail)

			if self.id == xyd.ActivityID.ACTIVITY_NEW_GROWTH_PLAN then
				local type = detail.type

				if type == 3 then
					self.detail.point = self.detail.point + self.buyPoint
					self.buyPoint = 0
				elseif type == 2 then
					self.detail.index = self:getCurPartnerIndex()
					self.confirmedPartnerID = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")[self.detail.index]
				end
			end
		end
	end)

	self.choosedPartnerID = xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID")

	if tonumber(self.choosedPartnerID) == 0 then
		self.choosedPartnerID = nil
	end

	if self.choosedPartnerID then
		local lastTime = xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID_timeStamp")

		if not lastTime or tonumber(lastTime) < self:startTime() then
			self.choosedPartnerID = nil

			xyd.db.misc:setValue({
				value = 0,
				key = "activity_new_growth_plan_choosedPartnerID"
			})
		end
	end

	print(self.choosedPartnerID)
	print(xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID"))

	if self.detail.index ~= 0 then
		self.confirmedPartnerID = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")[self.detail.index]
		self.choosedPartnerID = self.confirmedPartnerID
	end
end

function ActivityNewGrowthPlanData:getActiveDay()
	if self.activeDay then
		return self.activeDay
	end

	if self.detail.active_time > 0 then
		self.activeDay = math.ceil((self.detail.active_time - self.start_time) / 86400)

		return self.activeDay
	else
		return 0
	end
end

function ActivityNewGrowthPlanData:getDayNum()
	local realDay = 0
	local offsetDay = math.floor((xyd.getServerTime() - self.detail.start_time) / 86400)
	local timeStamp = xyd.getServerTime() - offsetDay * 24 * 60 * 60
	realDay = offsetDay

	if not xyd.isSameDay(timeStamp, self.detail.start_time) then
		realDay = realDay + 1
	end

	return realDay + 1
end

function ActivityNewGrowthPlanData:getCanResitScore()
	if activityGrowthPlanTable:getTotalPoint() <= self.detail.point then
		return -1
	end

	local missionTable = xyd.models.mission:getNowMissionTable()
	local todayPoint = 0
	local oneDayMaxPoint = 0
	local missions = self:getMissionList()

	for index, mission in ipairs(missions) do
		if mission.value >= 0 then
			oneDayMaxPoint = oneDayMaxPoint + xyd.tables.activityNewGrowthPlanTaskTable:getAwards(mission.mission_id)

			if mission.is_completed > 0 then
				todayPoint = todayPoint + xyd.tables.activityNewGrowthPlanTaskTable:getAwards(mission.mission_id)
			end
		end
	end

	local CanResitScore = (self:getDayNum() - 1) * oneDayMaxPoint - (self.detail.point - todayPoint)

	if activityGrowthPlanTable:getTotalPoint() < self.detail.point + CanResitScore then
		CanResitScore = activityGrowthPlanTable:getTotalPoint() - self.detail.point
	end

	return CanResitScore
end

function ActivityNewGrowthPlanData:onAward(data)
	if type(data) == "number" then
		self.detail.charges[1].buy_times = 1

		return
	end

	if data.detail then
		local detail = json.decode(data.detail)
		local awards = self.detail.awarded
		local ex_awards = self.detail.paid_awarded
		local nowPoint = self.detail.point
		local type = detail.type

		if not type or type > 1 then
			return
		end

		local ids = activityGrowthPlanTable:getIDs()

		for i = 1, #ids do
			local id = tonumber(i)

			if activityGrowthPlanTable:getPoint(id) <= nowPoint then
				if self.detail.awarded[id] == 0 then
					self.detail.awarded[id] = 1
				end

				if self.detail.paid_awarded[id] == 0 and self:getHasBuyGiftbag() == true then
					self.detail.paid_awarded[id] = 1
				end
			end
		end
	end
end

function ActivityNewGrowthPlanData:getCurPartnerIndex()
	local ids = xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")

	for i = 1, #ids do
		if tonumber(self.choosedPartnerID) == ids[i] then
			return i
		end
	end
end

function ActivityNewGrowthPlanData:choosePartner(partner_id)
	if self.detail.index == 0 then
		self.choosedPartnerID = partner_id

		xyd.db.misc:setValue({
			key = "activity_new_growth_plan_choosedPartnerID",
			value = partner_id
		})
		xyd.db.misc:setValue({
			key = "activity_new_growth_plan_choosedPartnerID_timeStamp",
			value = xyd.getServerTime()
		})
	end
end

function ActivityNewGrowthPlanData:getSelectedPartnerID()
	if self.detail.index ~= 0 then
		return xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")[self.detail.index]
	else
		local partnerID = xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID")

		if partnerID and tonumber(partnerID) ~= 0 then
			return tonumber(partnerID)
		else
			return nil
		end
	end
end

function ActivityNewGrowthPlanData:getConfirmedPartnerID()
	if self.detail.index ~= 0 then
		return xyd.tables.miscTable:split2Cost("activity_new_growth_plan_partner", "value", "|")[self.detail.index]
	else
		return nil
	end
end

function ActivityNewGrowthPlanData:getNowPoint()
	return self.detail.point or 0
end

function ActivityNewGrowthPlanData:getHasBuyGiftbag()
	if not self.detail.charges[1] then
		return false
	end

	return self.detail.charges[1].buy_times >= 1 or false
end

function ActivityNewGrowthPlanData:getBaseIsAwarded(id)
	if not self.detail.awarded then
		return false
	end

	return self.detail.awarded[id] >= 1
end

function ActivityNewGrowthPlanData:getExtraIsAwarded(id)
	if not self.detail.paid_awarded then
		return false
	end

	return self.detail.paid_awarded[id] >= 1
end

function ActivityNewGrowthPlanData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	if self:checkRedPointOfGoto() == true then
		flag = true
	end

	if self:checkRedPointOfChoosePartner() == true then
		flag = true
	end

	if self:checkRedPointOfCanGetAward() == true then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_NEW_GROWTH_PLAN, flag)

	return flag
end

function ActivityNewGrowthPlanData:checkRedPointOfGoto()
	if activityGrowthPlanTable:getTotalPoint() <= self.detail.point or self:checkRedPointOfChoosePartner() == true then
		return false
	end

	local flag = false
	local missions = self:getMissionList()

	for index, mission in ipairs(missions) do
		if mission.value <= 0 then
			flag = true
		end
	end

	local timeStamp = xyd.db.misc:getValue("growth_plan_goto_time_stamp")

	if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true)) and flag == true then
		return true
	else
		return false
	end
end

function ActivityNewGrowthPlanData:checkRedPointOfChoosePartner()
	if xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID") ~= nil and tonumber(xyd.db.misc:getValue("activity_new_growth_plan_choosedPartnerID")) ~= 0 or self.detail.index ~= 0 then
		return false
	else
		return true
	end
end

function ActivityNewGrowthPlanData:checkRedPointOfCanGetAward()
	local awards = self.detail.awarded
	local ex_awards = self.detail.paid_awarded
	local nowPoint = self.detail.point
	local ids = activityGrowthPlanTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(i)

		if activityGrowthPlanTable:getPoint(id) <= nowPoint then
			if self.detail.awarded[id] == 0 then
				return true
			end

			if self.detail.paid_awarded[id] == 0 and self:getHasBuyGiftbag() == true then
				return true
			end
		end
	end

	return false
end

function ActivityNewGrowthPlanData:getMissionList()
	return self.detail.missions
end

return ActivityNewGrowthPlanData
