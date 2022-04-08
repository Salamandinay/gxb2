local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local DailyGiftBagData = class("DailyGiftBagData", GiftBagData, true)

function DailyGiftBagData:ctor(params)
	GiftBagData.ctor(self, params)
end

function DailyGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + 86400
end

function DailyGiftBagData:getRedMarkState()
	local limitDiscountRedState = false
	local limitDiscountRedID = self.id == xyd.ActivityID.DAILY_GIFGBAG and xyd.RedMarkType.LIMIT_DISCOUNT_DAILY_GIFGBAG or xyd.RedMarkType.LIMIT_DISCOUNT_DAILY_GIFGBAG02
	local discountActivityID = self.id == xyd.ActivityID.DAILY_GIFGBAG and xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG or xyd.ActivityID.LIMIT_DISCOUNT_DAILY_GIFGBAG02
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

function DailyGiftBagData:onAward(event)
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

function DailyGiftBagData:updateInfo(params)
	self.detail.free_charge.awarded = params.awarded

	xyd.WindowManager.get():getWindow("activity_window"):setTitleRedMark(self.activity_id)
end

function DailyGiftBagData:setGiftbagID(giftBagID)
	self.giftBagID = giftBagID
end

function DailyGiftBagData:getGiftBagID()
	return self.giftBagID
end

return DailyGiftBagData
