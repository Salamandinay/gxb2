local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewPartnerWarmupData = class("NewPartnerWarmupData", ActivityData, true)

function NewPartnerWarmupData:getUpdateTime()
	if self.update_time ~= nil then
		return self:getEndTime()
	end

	return self.start_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewPartnerWarmupData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEW_PARTNER_WARMUP, function ()
		self.holdRed = false
	end)
end

function NewPartnerWarmupData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
		local curDays = math.ceil((xyd.getServerTime() - self.start_time) / 86400)

		for i = 1, 4 do
			local unlockDay = xyd.tables.newPartnerWarmUpStageTable:getUnlockDay(i)

			if unlockDay <= curDays and self.detail.current_stage == i then
				self.defRedMark = true
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.NEW_PARTNER_WARMUP, self.defRedMark)

	return self.defRedMark
end

return NewPartnerWarmupData
