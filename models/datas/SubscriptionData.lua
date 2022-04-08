local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SubscriptionData = class("SubscriptionData", ActivityData, true)

function SubscriptionData:displayType()
	local app_type = xyd.isSubscription()

	if app_type == xyd.APP_VERSION.ManaCard then
		return xyd.ActivityID.MANA_WEEK_CARD
	elseif app_type == xyd.APP_VERSION.Subscription or app_type == xyd.APP_VERSION.AND_Subscription then
		return xyd.ActivityID.SUBSCRIPTION
	else
		return xyd.ActivityID.MANA_SUBSCRIPTION
	end
end

function SubscriptionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if not self.defRedMark then
		return false
	end

	return self.detail.end_time < xyd.getServerTime()
end

function SubscriptionData:onAward(giftBagID)
	if giftBagID ~= xyd.GIFTBAG_ID.MANA_SUBSCRIPTION and giftBagID ~= xyd.GIFTBAG_ID.MANA_WEEK_CARD then
		self.detail.buy_times = self.detail.buy_times + 1

		if xyd.Global.lang == "ja_jp" then
			xyd.GiftbagPushController2.get():addTimeOut(function ()
				xyd.GiftbagPushController2.get():openMultiWindow({
					xyd.PopupType.MONTH_CARD,
					xyd.PopupType.FUNDATION,
					xyd.PopupType.SUBSCRIPTION
				})
			end)
		end
	end

	if giftBagID == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND or giftBagID == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND or giftBagID == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION or giftBagID == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION then
		xyd.models.activity:reqActivityByID(self.activity_id)
	elseif xyd.getServerTime() < self.detail.end_time then
		self.detail.end_time = self.detail.end_time + xyd.tables.giftBagTable:getDays(giftBagID) * 3600 * 24 - 1
	else
		self.detail.end_time = xyd.getServerTime() + xyd.tables.giftBagTable:getDays(giftBagID) * 3600 * 24 - 1
	end

	self.detail.cur_giftbag_id = giftBagID
end

function SubscriptionData:backRank()
	local data = self.detail

	if xyd.getServerTime() < tonumber(data.end_time) then
		return true
	end

	return false
end

function SubscriptionData:isPurchased()
	return xyd.getServerTime() < self.detail.end_time
end

return SubscriptionData
