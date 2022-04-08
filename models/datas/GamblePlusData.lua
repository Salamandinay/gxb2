local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GamblePlusData = class("GamblePlusData", ActivityData, true)

function GamblePlusData:ctor(params)
	ActivityData.ctor(self, params)

	self.isShowRedPoint = self.defRedMark

	self:initRedMarkState()
end

function GamblePlusData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function GamblePlusData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.isShowRedPoint
end

function GamblePlusData:initRedMarkState()
	local ids = xyd.tables.activityGamblePlusTable:getIDs()

	for _, id in pairs(ids) do
		local point = xyd.tables.activityGamblePlusTable:getPoint(id)

		if point <= xyd.models.backpack:getItemNumByID(xyd.ItemID.HEART_POKER) then
			if self.detail.awarded[id] and self.detail.awarded[id] <= 0 then
				self.isShowRedPoint = true

				return
			end

			if self.detail.charges[1].buy_times > 0 and self.detail.paid_awarded[id] and self.detail.paid_awarded[id] <= 0 then
				self.isShowRedPoint = true

				return
			end
		end
	end

	self.isShowRedPoint = false
end

function GamblePlusData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function GamblePlusData:onItemChange(event)
	local items = event.data.items

	for _, itemInfo in ipairs(items) do
		if itemInfo.item_id == xyd.ItemID.HEART_POKER then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.GAMBLE_PLUS, function ()
				self:initRedMarkState()
			end)
		end
	end
end

return GamblePlusData
