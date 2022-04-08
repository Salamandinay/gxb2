local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local WeeklyGiftBagData = class("WeeklyGiftBagData", GiftBagData, true)

function WeeklyGiftBagData:ctor(params)
	GiftBagData.ctor(self, params)
end

function WeeklyGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + 604800
end

function WeeklyGiftBagData:onAward(event)
	local giftBagID = type(event) == "number" and event or event.data.giftbag_id

	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

			if self.detail_.charges[i].buy_times == self.detail_.charges[i].limit_times and xyd.tables.giftBagTable:getParams(giftBagID) and xyd.tables.giftBagTable:getParams(giftBagID)[1] then
				local msg = messages_pb:get_activity_info_by_id_req()
				msg.activity_id = self.id

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
				self:setGiftbagID(giftBagID)
			end
		end
	end
end

function WeeklyGiftBagData:updateInfo(params)
	self.detail.free_charge.awarded = params.awarded

	xyd.WindowManager.get():getWindow("activity_window"):setTitleRedMark(self.activity_id)
end

function WeeklyGiftBagData:getRedMarkState()
	local limitDiscountRedState = false
	local limitDiscountRedID = self.id == xyd.ActivityID.WEEKLY_GIFTBAG and xyd.RedMarkType.LIMIT_DISCOUNT_WEEKLY_GIFTBAG or xyd.RedMarkType.LIMIT_DISCOUNT_WEEKLY_GIFTBAG02
	local discountActivityID = self.id == xyd.ActivityID.WEEKLY_GIFTBAG and xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG or xyd.ActivityID.LIMIT_DISCOUNT_WEEKLY_GIFTBAG02
	local discountGiftBagIDs = xyd.tables.activityTable:getGiftBag(discountActivityID)

	for i = 1, #self.detail_.charges do
		for j = 1, #discountGiftBagIDs do
			if self.detail_.charges[i].table_id == discountGiftBagIDs[j] then
				limitDiscountRedState = true
			end
		end
	end

	xyd.models.redMark:setMark(limitDiscountRedID, limitDiscountRedState)

	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.detail.free_charge.awarded == 0 and true or false
end

function WeeklyGiftBagData:setGiftbagID(giftBagID)
	self.giftBagID = giftBagID
end

function WeeklyGiftBagData:getGiftBagID()
	return self.giftBagID
end

return WeeklyGiftBagData
