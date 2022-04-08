local ActivityData = import("app.models.ActivityData")
local ActivityResidentReturnData = class("ActivityResidentReturnData", ActivityData, true)
local json = require("cjson")
local ActivityResidentReturnRewardTable = xyd.tables.activityResidentReturnRewardTable

function ActivityResidentReturnData:ctor(params)
	ActivityData.ctor(self, params)
	xyd.models.mission:getData()

	local doubleTime_left = -1

	if self:getReturnStartTime() ~= -1 and self:getReturnEndTime() ~= -1 and self:getReturnStartTime() <= xyd.getServerTime() and xyd.getServerTime() < self:getReturnStartTime() + xyd.tables.miscTable:getNumber("activity_return2_time1", "value") then
		doubleTime_left = self:getReturnStartTime() + xyd.tables.miscTable:getNumber("activity_return2_time1", "value") - self:getReturnStartTime()
	end

	if doubleTime_left > 0 then
		xyd.addGlobalTimer(handler(self, function ()
			local main_win = xyd.WindowManager.get():getWindow("main_window")

			if main_win then
				main_win:updateUpIcon()
			end

			local campaign_stage_detail_win = xyd.WindowManager.get():getWindow("campaign_stage_detail_window")

			if campaign_stage_detail_win then
				campaign_stage_detail_win:updateUpIcon()
			end

			local daily_quiz_win = xyd.WindowManager.get():getWindow("daily_quiz_window") or xyd.WindowManager.get():getWindow("daily_quiz2_window")

			if daily_quiz_win then
				daily_quiz_win:updateUpIcon()
			end

			local school_choose_window = xyd.WindowManager.get():getWindow("school_choose_window")

			if school_choose_window then
				school_choose_window:updateUpIcon()
			end

			local shop_map_window = xyd.WindowManager.get():getWindow("shop_map_window")

			if shop_map_window then
				shop_map_window:updateUpIcon()
			end

			local guild_window = xyd.WindowManager.get():getWindow("guild_window")

			if guild_window then
				guild_window:updateUpIcon()
			end

			local guild_dininghall = xyd.WindowManager.get():getWindow("guild_dininghall")

			if guild_dininghall then
				guild_dininghall:updateUpIcon()
			end
		end), doubleTime_left, 1)
	end
end

function ActivityResidentReturnData:getReturnStartTime()
	if self.detail and self.detail.start_time then
		return self.detail.start_time
	end

	return -1
end

function ActivityResidentReturnData:getReturnEndTime()
	if self.detail and self.detail.start_time then
		if not self.retutnEndTime then
			local longTime = 0

			for i = 1, 5 do
				local keepTime = xyd.tables.miscTable:getNumber("activity_return2_time" .. i, "value")

				if longTime < keepTime then
					longTime = keepTime
				end
			end

			self.retutnEndTime = self.detail.start_time + longTime
		end

		return self.retutnEndTime
	end

	return -1
end

function ActivityResidentReturnData:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local lastLoginTime = xyd.db.misc:getValue("activity_resident_return_pop_window_complete")

		if lastLoginTime and xyd.isSameDay(tonumber(lastLoginTime), xyd.getServerTime()) then
			return false
		elseif xyd.getServerTime() < self:getReturnStartTime() + 604800 and xyd.models.activity:isResidentReturnTimeIn() then
			return true
		else
			return false
		end
	else
		return false
	end

	return false
end

function ActivityResidentReturnData:getPopWinName()
	return "activity_resident_return_pop_window"
end

function ActivityResidentReturnData:doAfterPop()
	xyd.db.misc:setValue({
		key = "activity_resident_return_pop_window_complete",
		value = xyd.getServerTime()
	})
end

function ActivityResidentReturnData:getReturnSupportCanResitScore()
	local lastDays = math.floor((xyd.getServerTime() - self:getReturnStartTime()) / 86400)
	local missionTable = xyd.models.mission:getNowMissionTable()
	local oneDayMaxPoint = 0
	local missions = xyd.models.mission:getMissionList()

	for _, mData in ipairs(missions) do
		if missionTable:getType(mData.mission_id) == 1 then
			oneDayMaxPoint = oneDayMaxPoint + 1
		end
	end

	local CanResitScore = lastDays * oneDayMaxPoint * 5 - self.detail.point + self.detail.point_today

	if ActivityResidentReturnRewardTable:getTotalPoint() < self.detail.point + CanResitScore then
		CanResitScore = ActivityResidentReturnRewardTable:getTotalPoint() - self.detail.point
	end

	return CanResitScore
end

function ActivityResidentReturnData:onAward(data)
	if type(data) == "number" then
		self.detail.charges[1].buy_times = 1

		return
	end

	if data.detail then
		local detail = json.decode(data.detail)
		self.detail.point = self.detail.point + detail.num
	end
end

function ActivityResidentReturnData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	if (self.is_open == 1 or self.is_open == true) and xyd.getServerTime() < self:getReturnEndTime() then
		return true
	end

	return false
end

function ActivityResidentReturnData:setRedMarkState(type)
	if not xyd.models.activity:isResidentReturnTimeIn() then
		for i = 0, 5 do
			xyd.models.redMark:setMark(xyd.RedMarkType["ACTIVITY_RESIDENT_RETURN_RED_" .. i], false)
		end

		return
	end

	if not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_0 then
		local localMainRedTime = xyd.db.misc:getValue("activity_resident_return_to_main_red_time")

		if not localMainRedTime or localMainRedTime and not xyd.isSameDay(tonumber(localMainRedTime), xyd.getServerTime()) then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_0, true)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_0, false)
		end
	end

	if not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_1 then
		local localGrowAddTime = xyd.db.misc:getValue("activity_resident_return_growadd_red_time")

		if self:getReturnAlongEndTime(1) <= xyd.getServerTime() then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_1, false)
		elseif not localGrowAddTime or localGrowAddTime and not xyd.isSameDay(tonumber(localGrowAddTime), xyd.getServerTime()) then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_1, true)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_1, false)
		end
	end

	if not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2 then
		local localSupportTime = xyd.db.misc:getValue("activity_resident_return_support_red_time")

		if self:getReturnAlongEndTime(2) <= xyd.getServerTime() then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2, false)
		elseif self:getReturnSupportCanResitScore() > 0 then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2, true)
		elseif not localSupportTime or localSupportTime and not xyd.isSameDay(tonumber(localSupportTime), xyd.getServerTime()) then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2, true)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2, false)
		end
	end

	if not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_5 then
		local localCommunityTime = xyd.db.misc:getValue("activity_resident_return_community_red_time")

		if self:getReturnAlongEndTime(5) <= xyd.getServerTime() then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_5, false)
		elseif not localCommunityTime or localCommunityTime and not xyd.isSameDay(tonumber(localCommunityTime), xyd.getServerTime()) then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_5, true)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_5, false)
		end
	end

	local flag = false

	if (not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_3) and xyd.getServerTime() < self:getReturnAlongEndTime(3) then
		local lastTime = xyd.db.misc:getValue("activity_return_discount_red_time")
		flag = not lastTime or not xyd.isSameDay(tonumber(lastTime), xyd.getServerTime(), true)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_3, flag)

	flag = false

	if (not type or type == xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_4) and xyd.getServerTime() < self:getReturnAlongEndTime(4) then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RETURN_GIFT_OPTIONAL)

		if not activityData then
			return
		end

		local charges = activityData.detail_.charges

		for _, chargeInfo in pairs(charges) do
			flag = flag or chargeInfo.buy_times < chargeInfo.limit_times
		end

		local lastTime = xyd.db.misc:getValue("activity_return_gift_optional_red_time")
		flag = flag and (not lastTime or not xyd.isSameDay(tonumber(lastTime), xyd.getServerTime(), true))
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_4, flag)
end

function ActivityResidentReturnData:getReturnAlongEndTime(state)
	if self.detail and self.detail.start_time then
		if not self["retutnAlongEndTime" .. state] then
			local keepTime = xyd.tables.miscTable:getNumber("activity_return2_time" .. state, "value")
			self["retutnAlongEndTime" .. state] = self.detail.start_time + keepTime
		end

		return self["retutnAlongEndTime" .. state]
	end

	return -1
end

function ActivityResidentReturnData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_MISSION_LIST, handler(self, self.onGetMission))
end

function ActivityResidentReturnData:onGetMission()
	self:setRedMarkState()
end

return ActivityResidentReturnData
