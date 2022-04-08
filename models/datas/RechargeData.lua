local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local RechargeData = class("RechargeData", GiftBagData, true)

function RechargeData:setData(params)
	RechargeData.super.setData(self, params)

	local returnData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)

	if returnData then
		local giftData = nil
		local charges = returnData.detail_.charges

		for _, chargeInfo in ipairs(charges) do
			if chargeInfo.table_id == 302 then
				giftData = chargeInfo
			end
		end

		table.insert(self.detail_.charges, giftData)
	end
end

function RechargeData:onAward(giftBagID)
	xyd.models.advertiseComplete:rechangGiftBag(giftBagID)

	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

			if xyd.tables.giftBagTable:getGiftType(giftBagID) == xyd.GIFTBAG_TYPE.CARD or xyd.tables.giftBagTable:getGiftType(giftBagID) == xyd.GIFTBAG_TYPE.LIMIT_TIME_CARD or xyd.tables.giftBagTable:getGiftType(giftBagID) == xyd.GIFTBAG_TYPE.LIMIT_TIME_MINICARD then
				xyd.models.activity:reqActivityByID(xyd.ActivityID.RECHARGE)
			end
		end
	end
end

function RechargeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

return RechargeData
