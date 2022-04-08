local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityDragonBoatData = class("ActivityDragonBoatData", ActivityData, true)

function ActivityDragonBoatData:getUpdateTime()
	return self:getEndTime()
end

function ActivityDragonBoatData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

			break
		end
	end
end

function ActivityDragonBoatData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not self.detail.free_charge then
		return false
	end

	return self.detail.free_charge.awarded == 0
end

function ActivityDragonBoatData:updateInfo(params)
	self.detail.free_charge.awarded = params.awarded

	xyd.WindowManager.get():getWindow("activity_window"):setTitleRedMark(self.activity_id)
end

return ActivityDragonBoatData
