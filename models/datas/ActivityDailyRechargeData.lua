local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityDailyRechargeData = class("ActivityDailyRechargeData", ActivityData, true)

function ActivityDailyRechargeData:ctor(params)
	ActivityData.ctor(self, params)
end

function ActivityDailyRechargeData:getUpdateTime()
	return self.detail.start_time + 2592000
end

function ActivityDailyRechargeData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if self:isFirstRedMark() then
		red = true
	end

	if self.detail.award_times > 0 and #self.detail.award_ids < 15 then
		red = true
	elseif self.detail.free_times == 0 then
		red = true
	else
		red = false
	end

	return red
end

function ActivityDailyRechargeData:register()
	self:registerEvent(xyd.event.RECHARGE, function (event)
		local giftBagID = event.data.giftbag_id

		if #self.detail.award_ids < 15 and #self.detail.award_ids + self.detail.award_times < 15 and (xyd.getServerTime() - xyd.getServerTime() % 86400) / 86400 - (self.detail.get_times_time - self.detail.get_times_time % 86400) / 86400 >= 1 then
			self.detail.get_times_time = xyd.getServerTime()
			self.detail.award_times = self.detail.award_times + 1
		end

		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				self:getRedMarkState()

				return
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		dump(self.detail.award_times)

		local data = event.data
		local detail = json.decode(data.detail)

		if data.activity_id ~= xyd.ActivityID.ACTIVITY_DAILY_RECHARGE then
			return
		end

		self.detail = detail.info

		if detail.type == 2 then
			for i = 1, #detail.items do
				local info = {}

				table.insert(info, {
					item_id = detail.items[i].item_id,
					item_num = detail.items[i].item_num
				})
				xyd.models.itemFloatModel:pushNewItems(info)
			end
		else
			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 4,
				isNeedCostBtn = false,
				data = detail.items
			})
		end

		self:getRedMarkState()
	end)
end

return ActivityDailyRechargeData
