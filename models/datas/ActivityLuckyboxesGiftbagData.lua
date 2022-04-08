local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLuckyboxesGiftbagData = class("ActivityLuckyboxesGiftbagData", ActivityData, true)

function ActivityLuckyboxesGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLuckyboxesGiftbagData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	return red
end

function ActivityLuckyboxesGiftbagData:register()
	self.mainActivityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES)

	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id

		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG then
			local detail = json.decode(data.detail)
			self.detail = detail.info
		end
	end)
end

function ActivityLuckyboxesGiftbagData:getRedPointOfGiftbag()
	local timeStamp = xyd.db.misc:getValue("activity_luckyboxes_gift_time_stamp")
	local haveLeftGiftbag = false
	self.giftBagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG)

	for i = 1, #self.detail.charges do
		if self.detail.charges[i].buy_times < self.detail.charges[i].limit_times then
			haveLeftGiftbag = true
		end
	end

	for i = 1, #self.detail.free_charge do
		if xyd.tables.activityLuckyboxesExchangTable:getLimit(i) - self.detail.exchange_times[i] >= 1 then
			haveLeftGiftbag = true
		end
	end

	if (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true)) and haveLeftGiftbag == true then
		return true
	else
		return false
	end
end

return ActivityLuckyboxesGiftbagData
