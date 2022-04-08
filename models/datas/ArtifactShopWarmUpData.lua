local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ArtifactShopWarmUpData = class("ArtifactShopWarmUpData", ActivityData, true)

function ArtifactShopWarmUpData:getUpdateTime()
	return self:getEndTime()
end

function ArtifactShopWarmUpData:getEndTime()
	if self.detail.active_time > 0 then
		local lastDays = xyd.tables.miscTable:split2num("activity_mission_time", "value", "|")[2] or 0

		return self.start_time + (self:getActiveDay() + lastDays - 1) * 24 * 60 * 60
	else
		return self.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
	end
end

function ArtifactShopWarmUpData:getActiveDay()
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

function ArtifactShopWarmUpData:getDayNum()
	if self.detail.active_time > 0 then
		return math.floor((xyd.getServerTime() - self.start_time) / 86400) - self:getActiveDay() + 1
	end
end

function ArtifactShopWarmUpData:getCanResitScore()
	if self.detail.active_time <= 0 or self.detail.point >= 180 then
		return -1
	end

	local missionTable = xyd.models.mission:getNowMissionTable()
	local todayPoint = 0
	local oneDayMaxPoint = 0
	local missions = xyd.models.mission:getMissionList()

	for _, mData in ipairs(missions) do
		if missionTable:getType(mData.mission_id) == 1 then
			oneDayMaxPoint = oneDayMaxPoint + 1

			if mData.is_awarded == 1 then
				todayPoint = todayPoint + 1
			end
		end
	end

	local CanResitScore = self:getDayNum() * oneDayMaxPoint - self.detail.point + todayPoint

	if xyd.tables.activityMissionPointTable:getTotalPoint() < self.detail.point + CanResitScore then
		CanResitScore = xyd.tables.activityMissionPointTable:getTotalPoint() - self.detail.point
	end

	return CanResitScore
end

function ArtifactShopWarmUpData:onAward(data)
	if type(data) == "number" then
		self.detail.charges[1].buy_times = 1

		return
	end

	if data.detail then
		local detail = json.decode(data.detail)
		self.detail.active_time = detail.active_time
		self.detail.point = detail.point
	end
end

function ArtifactShopWarmUpData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local time = xyd.db.misc:getValue("artifact_shop_warm_up_redmark")

	if time and xyd.isToday(tonumber(time)) then
		return false
	else
		return true
	end
end

return ArtifactShopWarmUpData
