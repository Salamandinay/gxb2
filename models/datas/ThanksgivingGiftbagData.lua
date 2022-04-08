local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ThanksgivingGiftbagData = class("ThanksgivingGiftbagData", ActivityData, true)

function ThanksgivingGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ThanksgivingGiftbagData:onAward(giftBagID)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1
		end
	end
end

function ThanksgivingGiftbagData:getRedMarkState()
	self.defRedMark = false

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local lastViewTime = xyd.db.misc:getValue("thanksgiving_giftbag_view_time")

		if not lastViewTime or not xyd.isSameDay(lastViewTime, xyd.getServerTime()) then
			self.defRedMark = true
		else
			self.defRedMark = false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.THANKSGIVING_GIFTBAG, self.defRedMark)

	return self.defRedMark
end

return ThanksgivingGiftbagData
