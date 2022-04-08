local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTimePartnerData = class("ActivityTimePartnerData", ActivityData, true)

function ActivityTimePartnerData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local ids = xyd.tables.activityTimePartnerTable:getIds()

	for _, id in ipairs(ids) do
		if self.detail_.pr_awards[id] < 1 then
			local needPoint = xyd.tables.activityTimePartnerTable:getPoint(id)
			flag = needPoint <= self.detail_.pr

			if flag then
				break
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TIME_PARTNER, flag)

	return flag
end

function ActivityTimePartnerData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTimePartnerData:onAward(data)
	local tableId = json.decode(data.detail).table_id
	self.detail_.pr_awards[tableId] = self.detail_.pr_awards[tableId] + 1

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_TIME_PARTNER, function ()
	end)
end

return ActivityTimePartnerData
