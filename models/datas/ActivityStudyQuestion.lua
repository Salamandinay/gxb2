local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityStudyQuestion = class("ActivityStudyQuestion", ActivityData, true)

function ActivityStudyQuestion:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.QUIZ_ANSWER_QUESTION, handler(self, self.onUpdateSlotInfo))
	self.eventProxyOuter_:addEventListener(xyd.event.QUIZ_RESET_QUESTION, handler(self, self.onUpdateSlotInfo))
	self.eventProxyOuter_:addEventListener(xyd.event.QUIZ_UNLOCK_QUESTION, handler(self, self.onUpdateSlotInfo))
end

function ActivityStudyQuestion:setActionSlotID(slotID)
	self.slotID_ = slotID
end

function ActivityStudyQuestion:onUpdateSlotInfo(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.STUDY_QUESTION, function ()
		local data = event.data
		self.detail_.slot_infos = data.slot_infos
		self.detail_.awarded = data.awarded
		self.detail_.energy = data.energy
		self.detail_.update_time = data.update_time
	end)
end

function ActivityStudyQuestion:onAward(data)
	self:onUpdateSlotInfo({
		data = json.decode(data.detail)
	})
end

function ActivityStudyQuestion:getUpdateTime()
	return self:getEndTime()
end

function ActivityStudyQuestion:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, 16 do
		if not self.detail_.slot_infos[i].is_correct or self.detail_.slot_infos[i].is_correct == 0 then
			return tonumber(self.detail_.energy) > 0
		end
	end

	return false
end

return ActivityStudyQuestion
