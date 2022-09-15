local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityRepairGiftBag = class("ActivityRepairGiftBag", GiftBagData, true)

function ActivityRepairGiftBag:getRedMarkState()
	local redState = true
	local lastViewTime = xyd.db.misc:getValue("activity_repair_giftbag_view_time")

	if lastViewTime and xyd.isSameDay(tonumber(lastViewTime), xyd.getServerTime()) then
		redState = false
	else
		local limit = tonumber(xyd.tables.miscTable:getVal("activity_repair_console_diamonds_giftbag_limit"))
		local buyTimes = self.detail_.award
		redState = limit > buyTimes
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_REPAIR_GIFTBAG, redState)

	return redState
end

function ActivityRepairGiftBag:getUpdateTime()
	return self:getEndTime()
end

function ActivityRepairGiftBag:register()
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

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_REPAIR_GIFTBAG, function ()
			if data.activity_id == xyd.ActivityID.ACTIVITY_REPAIR_GIFTBAG then
				local detail = json.decode(data.detail)
				self.detail = detail.info

				xyd.models.itemFloatModel:pushNewItems(detail.items)
			end
		end)
	end)
end

return ActivityRepairGiftBag
