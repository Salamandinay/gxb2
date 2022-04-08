local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityReturnPrivilegeDiscountData = class("ActivityReturnPrivilegeDiscountData", ActivityData, true)

function ActivityReturnPrivilegeDiscountData:ctor(params)
	ActivityReturnPrivilegeDiscountData.super.ctor(self, params)
end

function ActivityReturnPrivilegeDiscountData:onAward(giftBagID)
	local charges = self.detail_.charges

	for _, chargeInfo in ipairs(charges) do
		if chargeInfo.table_id == giftBagID then
			chargeInfo.buy_times = chargeInfo.buy_times + 1
		end
	end

	if giftBagID == xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)[1] then
		local actData = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)

		if not actData.detail_.charges[1].days then
			actData.detail_.charges[1].days = 0
		end

		if not actData.detail_.charges[1].end_time then
			actData.detail_.charges[1].end_time = 0
		end

		if actData.detail_.charges[1].days <= 0 then
			actData.detail_.charges[1].days = xyd.tables.giftBagTable:getDays(giftBagID) - 1
		else
			actData.detail_.charges[1].days = xyd.tables.giftBagTable:getDays(giftBagID) + actData.detail_.charges[1].days
		end

		if actData.detail_.charges[1].end_time > 0 then
			actData.detail_.charges[1].end_time = actData.detail_.charges[1].end_time + xyd.tables.giftBagTable:getDays(giftBagID) * 3600 * 24 - 1
		else
			actData.detail_.charges[1].end_time = xyd.getServerTime() - xyd.getServerTime() % 86400 + xyd.tables.giftBagTable:getDays(giftBagID) * 3600 * 24 - 1
		end
	end

	if giftBagID == xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)[2] then
		local actData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_MONTHLY)
		actData.detail_.ex_buy = actData.detail_.ex_buy + 1
	end
end

return ActivityReturnPrivilegeDiscountData
