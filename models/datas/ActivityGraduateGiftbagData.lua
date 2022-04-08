local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGraduateGiftbagData = class("ActivityGraduateGiftbagData", ActivityData, true)

function ActivityGraduateGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGraduateGiftbagData:onAward(data)
	if type(data) == "table" then
		self.detail_ = json.decode(data.detail).info

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_GRADUATE_GIFTBAG, function ()
		end)
	else
		local charges = self.detail.charges

		for _, item in ipairs(charges) do
			if item.table_id == data then
				item.buy_times = item.buy_times + 1
			end
		end
	end
end

function ActivityGraduateGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local t = xyd.tables.activityGraduateGiftbagTable
	local ids = t:getItemsList()
	local flag = false

	for _, item in pairs(ids) do
		if item.star <= self.detail.score then
			flag = flag or self.detail.awarded[item.freeId] == 0
		else
			break
		end
	end

	return flag
end

function ActivityGraduateGiftbagData:isHide()
	if not self:isFunctionOnOpen() then
		return false
	end

	return self.detail.active_time == 0
end

return ActivityGraduateGiftbagData
