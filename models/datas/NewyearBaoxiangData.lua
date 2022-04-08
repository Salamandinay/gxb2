local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewyearBaoxiangData = class("NewyearBaoxiangData", ActivityData, true)

function NewyearBaoxiangData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.USE_ITEM, handler(self, self.useGiftBag))
end

function NewyearBaoxiangData:useGiftBag(event)
	local id_ = tonumber(event.data.used_item_id)

	if id_ == xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022 or id_ == xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022 then
		if not self.detail["point_" .. id_] then
			self.detail["point_" .. id_] = 0
		end

		self.detail["point_" .. id_] = self.detail["point_" .. id_] + #event.data.items

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWYEAR_BAOXIANG, function ()
		end)
	end
end

function NewyearBaoxiangData:setAwardId(id)
	self.awardId = id
end

function NewyearBaoxiangData:onAward()
	self.detail.awarded[self.awardId] = 1

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWYEAR_BAOXIANG, function ()
	end)
end

function NewyearBaoxiangData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local ids = xyd.tables.activityNewyearAwardTable:getIds()
	local awardedData = self.detail.awarded

	for i = 1, #ids do
		if awardedData[i] == 0 then
			local id = ids[i]
			local itemID = xyd.tables.activityNewyearAwardTable:getItemID(id)
			local point = xyd.tables.activityNewyearAwardTable:getPoint(id)
			local value = self.detail["point_" .. itemID] or 0

			if point <= value then
				flag = true

				break
			end
		end
	end

	return flag
end

function NewyearBaoxiangData:getUpdateTime()
	return self:getEndTime()
end

return NewyearBaoxiangData
