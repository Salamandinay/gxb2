local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local MonthBeginningGiftBagData = class("MonthBeginningGiftBagData", GiftBagData, true)

function MonthBeginningGiftBagData:ctor(params)
	GiftBagData.ctor(self, params)
end

function MonthBeginningGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function MonthBeginningGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.free_charge.awarded == 0 then
		return true
	end

	return false
end

function MonthBeginningGiftBagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function MonthBeginningGiftBagData:updateInfo(params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.MONTH_BEGINNING_GIFTBAG, function ()
		self.detail.free_charge.awarded = params.awarded
	end)
end

function MonthBeginningGiftBagData:updateCrystalInfo(awardStateArrs)
	self.detail.buy_times = awardStateArrs
end

return MonthBeginningGiftBagData
