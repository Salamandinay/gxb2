local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBeachData = class("ActivityBeachData", ActivityData, true)

function ActivityBeachData:getUpdateTime()
	return self:getEndTime()
end

function ActivityBeachData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.can_attack_times > 0 or self:checkCanGetAward() then
		return true
	end

	return self.defRedMark
end

function ActivityBeachData:updateInfo(data)
	self.detail_ = data
end

function ActivityBeachData:onAward(data)
	local realData = json.decode(data.detail)
	self.detail.awards_1 = realData.awards_1
	self.detail.awards_2 = realData.awards_2
end

function ActivityBeachData:getCurLev()
	local ids = xyd.tables.activityBeachAwardsTable:getIDs()
	local curPoint = self.detail.point or 0
	local lev = 0

	for id in pairs(ids) do
		local point = xyd.tables.activityBeachAwardsTable:getPoint(id)

		if curPoint < point then
			break
		end

		lev = tonumber(id)
	end

	return lev
end

function ActivityBeachData:checkCanGetAward()
	local curLev = self:getCurLev()
	local awards1 = self.detail.awards_1
	local awards2 = self.detail.awards_2
	local isUnLock = self.detail.advance_award_is_lock == 0

	if awards1[curLev - 1] == 0 or isUnLock and awards2[curLev - 1] == 0 then
		return true
	end

	return false
end

return ActivityBeachData
