local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySpfarmSupplyData = class("ActivitySpfarmSupplyData", ActivityData, true)

function ActivitySpfarmSupplyData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpfarmSupplyData:onAward(event)
	local giftbag_id = event

	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftbag_id then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

			break
		end
	end

	local charges2 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPFARM).detail.charges

	for i = 1, #charges2 do
		if charges2[i].table_id == giftbag_id then
			charges2[i].buy_times = charges2[i].buy_times + 1

			break
		end
	end
end

function ActivitySpfarmSupplyData:checkSpecialBuy()
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == 438 then
			return self.detail.charges[i].buy_times >= 1
		end
	end

	return false
end

function ActivitySpfarmSupplyData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false
	local redPoint1 = xyd.db.misc:getValue("activity_space_explore_supply_redpoint_1") or 0
	local redPoint2 = xyd.db.misc:getValue("activity_space_explore_supply_redpoint_2") or 0

	if self:getEndTime() - xyd.getServerTime() > xyd.TimePeriod.DAY_TIME * 7 then
		if tonumber(redPoint1) == 0 then
			flag = true
		end
	elseif tonumber(redPoint2) == 0 then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SPACE_EXPLORE_SUPPLY, flag)

	return flag
end

return ActivitySpfarmSupplyData
