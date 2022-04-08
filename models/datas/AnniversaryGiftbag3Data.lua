local ActivityData = import("app.models.ActivityData")
local AnniversaryGiftbag3Data = class("AnniversaryGiftbag3Data", ActivityData, true)

function AnniversaryGiftbag3Data:ctor(params)
	ActivityData.ctor(self, params)
end

function AnniversaryGiftbag3Data:getUpdateTime()
	return self:getEndTime()
end

function AnniversaryGiftbag3Data:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false
	local ids = xyd.tables.activityTable:getGiftBag(self.id)

	for i = 1, #ids do
		local id = ids[i]
		local limit = xyd.tables.giftBagTable:getBuyLimit(id)

		if self.detail.charges[i].buy_times < limit then
			local last_time = xyd.db.misc:getValue("anniversary_giftbag_last_time_" .. tostring(self.activity_id))

			if not last_time or not xyd.isSameDay(tonumber(last_time), xyd.getServerTime()) then
				flag = true
			end
		end
	end

	if self.activity_id == xyd.ActivityID.ANNIVERSARY_GIFTBAG3_1 then
		xyd.models.redMark:setMark(xyd.RedMarkType.ANNIVERSARY_GIFTBAG3_1, flag)
	elseif self.activity_id == xyd.ActivityID.ANNIVERSARY_GIFTBAG3_2 then
		xyd.models.redMark:setMark(xyd.RedMarkType.ANNIVERSARY_GIFTBAG3_2, flag)
	end

	return flag
end

return AnniversaryGiftbag3Data
