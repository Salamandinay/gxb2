local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SakuraDateData = class("SakuraDateData", ActivityData, true)

function SakuraDateData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local energy = self.detail.energy + self.detail.recover_energy
	local complete_num = self:getCompleteNumber()

	if energy >= 1 then
		if complete_num < 6 then
			return true
		else
			return false
		end
	end

	return self.defRedMark
end

function SakuraDateData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function SakuraDateData:getCompleteNumber()
	local cnt = 0
	local tmpStatus = self.detail.date_status

	for i = 1, #tmpStatus do
		if tmpStatus[i] then
			cnt = cnt + 1
		end
	end

	return cnt
end

return SakuraDateData
