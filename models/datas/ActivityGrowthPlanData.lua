local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGrowthPlanData = class("ActivityGrowthPlanData", ActivityData, true)
local activityGrowthPlanTable = xyd.tables.activityGrowthPlanTable

function ActivityGrowthPlanData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGrowthPlanData:register()
	self:registerEvent(xyd.event.BATTLE_PASS_SP_SET_INDEX, function (event)
		self.detail.index = self:getCurPartnerIndex()
		self.confirmedPartnerID = xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")[self.detail.index]
	end)
	self:registerEvent(xyd.event.BATTLE_PASS_SP_BUY_POINT, function (event)
		self.detail.point = self.detail.point + self.buyPoint
		self.buyPoint = 0
	end)
	self:registerEvent(xyd.event.GET_MISSION_AWARD, function ()
		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
	end)

	self.choosedPartnerID = xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID")

	if tonumber(self.choosedPartnerID) == 0 then
		self.choosedPartnerID = nil
	end

	if self.choosedPartnerID then
		local lastTime = xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID_timeStamp")

		if not lastTime or tonumber(lastTime) < self:startTime() then
			self.choosedPartnerID = nil

			xyd.db.misc:setValue({
				value = 0,
				key = "activity_growth_plan_choosedPartnerID"
			})
		end
	end

	print(self.choosedPartnerID)
	print(xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID"))

	if self.detail.index ~= 0 then
		self.confirmedPartnerID = xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")[self.detail.index]
		self.choosedPartnerID = self.confirmedPartnerID
	end
end

function ActivityGrowthPlanData:getActiveDay()
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

function ActivityGrowthPlanData:getDayNum()
	return math.floor((xyd.getServerTime() - self.start_time) / 86400) + 1
end

function ActivityGrowthPlanData:getCanResitScore()
	if activityGrowthPlanTable:getTotalPoint() <= self.detail.point then
		return -1
	end

	local missionTable = xyd.models.mission:getNowMissionTable()
	local singlePoint = xyd.tables.miscTable:getNumber("activity_growth_plan_score", "value")
	local todayPoint = 0
	local oneDayMaxPoint = 0
	local missions = xyd.models.mission:getMissionList()

	for _, mData in ipairs(missions) do
		if missionTable:getType(mData.mission_id) == 1 and xyd.tables.battlePassMissionTable:getLevLimit(mData.mission_id) ~= -1 then
			oneDayMaxPoint = oneDayMaxPoint + singlePoint

			if mData.is_awarded == 1 then
				todayPoint = todayPoint + singlePoint
			end
		end
	end

	oneDayMaxPoint = 10 * singlePoint
	local CanResitScore = (self:getDayNum() - 1) * oneDayMaxPoint - (self.detail.point - todayPoint)

	if activityGrowthPlanTable:getTotalPoint() < self.detail.point + CanResitScore then
		CanResitScore = activityGrowthPlanTable:getTotalPoint() - self.detail.point
	end

	return CanResitScore
end

function ActivityGrowthPlanData:onAward(data)
	if type(data) == "number" then
		self.detail.charges[1].buy_times = 1

		return
	end

	if data.detail then
		local detail = json.decode(data.detail)
		local awards = self.detail.awarded
		local ex_awards = self.detail.paid_awarded
		local nowPoint = self.detail.point
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

function ActivityGrowthPlanData:getCurPartnerIndex()
	local ids = xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")

	for i = 1, #ids do
		if tonumber(self.choosedPartnerID) == ids[i] then
			return i
		end
	end
end

function ActivityGrowthPlanData:choosePartner(partner_id)
	if self.detail.index == 0 then
		self.choosedPartnerID = partner_id

		xyd.db.misc:setValue({
			key = "activity_growth_plan_choosedPartnerID",
			value = partner_id
		})
		xyd.db.misc:setValue({
			key = "activity_growth_plan_choosedPartnerID_timeStamp",
			value = xyd.getServerTime()
		})
	end
end

function ActivityGrowthPlanData:getSelectedPartnerID()
	if self.detail.index ~= 0 then
		return xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")[self.detail.index]
	else
		local partnerID = xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID")

		if partnerID and tonumber(partnerID) ~= 0 then
			return tonumber(partnerID)
		else
			return nil
		end
	end
end

function ActivityGrowthPlanData:getConfirmedPartnerID()
	if self.detail.index ~= 0 then
		return xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")[self.detail.index]
	else
		return nil
	end
end

function ActivityGrowthPlanData:getNowPoint()
	return self.detail.point or 0
end

function ActivityGrowthPlanData:getHasBuyGiftbag()
	if not self.detail.charges[1] then
		return false
	end

	return self.detail.charges[1].buy_times >= 1 or false
end

function ActivityGrowthPlanData:getBaseIsAwarded(id)
	if not self.detail.awarded then
		return false
	end

	return self.detail.awarded[id] >= 1
end

function ActivityGrowthPlanData:getExtraIsAwarded(id)
	if not self.detail.paid_awarded then
		return false
	end

	return self.detail.paid_awarded[id] >= 1
end

function ActivityGrowthPlanData:getRedMarkState()
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

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_GROWTH_PLAN, flag)

	return flag
end

function ActivityGrowthPlanData:checkRedPointOfGoto()
	if activityGrowthPlanTable:getTotalPoint() <= self.detail.point or self:checkRedPointOfChoosePartner() == true then
		return false
	end

	local missionTable = xyd.models.mission:getNowMissionTable()
	local missions = xyd.models.mission:getMissionList()
	local missions = xyd.models.mission:getMissionList()
	local flag = false

	for _, mData in ipairs(missions) do
		if missionTable:getType(mData.mission_id) == 1 and xyd.tables.battlePassMissionTable:getLevLimit(mData.mission_id) ~= -1 and mData.is_awarded ~= 1 then
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

function ActivityGrowthPlanData:checkRedPointOfChoosePartner()
	if xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID") ~= nil and tonumber(xyd.db.misc:getValue("activity_growth_plan_choosedPartnerID")) ~= 0 or self.detail.index ~= 0 then
		return false
	else
		return true
	end
end

function ActivityGrowthPlanData:checkRedPointOfCanGetAward()
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

return ActivityGrowthPlanData
