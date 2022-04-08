local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityReturnTestData = class("ActivityReturnTestData", ActivityData, true)

function ActivityReturnTestData:ctor(params)
	ActivityData.ctor(self, params)

	if self.detail.role == xyd.PlayerReturnType.RETURN then
		local doubleTimeGet = tonumber(xyd.tables.miscTable:getVal("activity_return_drop_period"))
		local doubleTime_left = xyd.getServerTime() - self:startTime()

		if doubleTime_left > 0 then
			doubleTime_left = doubleTimeGet - doubleTime_left
		else
			doubleTime_left = -1
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

				local activity_return_win = xyd.WindowManager.get():getWindow("activity_return_window")

				if activity_return_win then
					activity_return_win:updateUpIcon()
				end
			end), doubleTime_left, 1)
		end
	end

	if #self.detail.apply_list > 0 then
		self.defRedMark = true
	end
end

function ActivityReturnTestData:onAward(data)
	if self.awardId_ and self.awardId_ ~= 0 and self.awardNum_ and self.awardNum_ > 0 then
		self.detail_.buy_times[self.awardId_] = self.detail_.buy_times[self.awardId_] + self.awardNum_
	end

	dump(self.detail_.buy_times)
end

function ActivityReturnTestData:setBuyItem(award_id, num)
	self.awardId_ = award_id
	self.awardNum_ = num
end

function ActivityReturnTestData:getBuyItem()
	return self.awardId_, self.awardNum_
end

function ActivityReturnTestData:getRole()
	return self.detail.role
end

function ActivityReturnTestData:getIsDoubleTime()
	if self.detail.role == xyd.PlayerReturnType.RETURN then
		local doubleTimeGet = tonumber(xyd.tables.miscTable:getVal("activity_return_drop_period"))
		local doubleTime_left = xyd.getServerTime() - self:startTime()

		if doubleTime_left > 0 then
			doubleTime_left = doubleTimeGet - doubleTime_left
		else
			doubleTime_left = -1
		end

		if doubleTime_left > 0 then
			return true
		else
			return false
		end
	else
		return false
	end
end

function ActivityReturnTestData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not self.defRedMark then
		return false
	else
		self.hasCompAllMission = self:checkCompMission()
		self.acceptInfoList_ = self.detail_.accept_show_info
		local canOpenApplyWindow = not self.acceptInfoList_ or not self.acceptInfoList_[1] or #self.acceptInfoList_ == 2 and not self.hasCompAllMission or self.hasCompAllMission and #self.acceptInfoList_ == 1

		return canOpenApplyWindow and tonumber(self.detail_.role) == 2
	end
end

function ActivityReturnTestData:checkCompMission()
	self.tMissionAwarded_ = self.detail_.t_mis_awarded or {}
	local tMissionList = xyd.tables.activityReturnTMissionTable:getIds()

	for _, missionId in ipairs(tMissionList) do
		if not self.tMissionAwarded_[missionId] or self.tMissionAwarded_[missionId] == 0 then
			return false
		end
	end

	return true
end

return ActivityReturnTestData
