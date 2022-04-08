local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityIceSecretGiftbagData = class("ActivityIceSecretGiftbagData", GiftBagData, true)

function ActivityIceSecretGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityIceSecretGiftbagData:onAward(giftBagID)
	for i in pairs(self.detail_.charges) do
		local data = self.detail_.charges[i]

		if giftBagID == data.table_id then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

			return
		end
	end
end

function ActivityIceSecretGiftbagData:getStartTime()
	return self.start_time
end

function ActivityIceSecretGiftbagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, true)

		return true
	end

	local timeDays = xyd.db.misc:getValue("activity_ice_secret_giftbag")

	if timeDays == nil then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, true)

		return true
	else
		local startTime = self:startTime()
		local passedTotalTime = xyd.getServerTime() - startTime
		local cd = xyd.tables.giftBagTable:getCD(self.detail.charges[1].table_id)
		local round = math.ceil(passedTotalTime / cd)

		if round ~= tonumber(timeDays) and xyd.getServerTime() < self:getEndTime() then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, true)

			return true
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, false)

			return false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_ICE_SECRET_GIFTBAG, false)

	return false
end

function ActivityIceSecretGiftbagData:getLittleUpdateTime()
	local startTime = self:getStartTime()
	local passedTotalTime = xyd.getServerTime() - startTime
	local cd = xyd.tables.giftBagTable:getCD(self.detail.charges[1].table_id)
	local round = math.ceil(passedTotalTime / cd)
	local countdownTime = round * cd - passedTotalTime

	return countdownTime
end

return ActivityIceSecretGiftbagData
