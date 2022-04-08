local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SchoolOpensGiftbagData = class("SchoolOpensGiftbagData", ActivityData, true)

function SchoolOpensGiftbagData:getUpdateTime()
	if self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function SchoolOpensGiftbagData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail_.award_counts = detail.award_counts
	local win = xyd.getWindow("activity_window")

	win:itemFloat(detail.items)
end

function SchoolOpensGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local awardCount = self.detail_.award_counts
	local lockState = self.detail_.box_lock_status

	if awardCount[1] and awardCount[1] > 0 then
		flag = true

		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHRISTMAS_SALE, flag)

		return flag
	end

	for i = 2, 3 do
		if awardCount[i] and awardCount[i] > 0 and lockState[i] and lockState[i] > 0 then
			flag = true

			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHRISTMAS_SALE, flag)

			return flag
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHRISTMAS_SALE, flag)

	return flag
end

return SchoolOpensGiftbagData
