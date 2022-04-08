local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEasterEggData = class("ActivityEasterEggData", ActivityData, true)

function ActivityEasterEggData:ctor(params)
	ActivityEasterEggData.super.ctor(self, params)

	self.isShowRedPoint = xyd.checkCondition(tonumber(xyd.db.misc:getValue("esater_egg_first_touch")), false, true) or xyd.models.backpack:getItemNumByID(xyd.ItemID.PINK_BALLOON) > 0
end

function ActivityEasterEggData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return self.isShowRedPoint
end

function ActivityEasterEggData:getUpdateTime()
	return self:getEndTime()
end

function ActivityEasterEggData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail = detail.info
end

function ActivityEasterEggData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityEasterEggData:onItemChange(event)
	local items = event.data.items

	for _, itemInfo in ipairs(items) do
		if itemInfo.item_id == xyd.ItemID.PINK_BALLOON then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.EASTER_EGG, function ()
				self.isShowRedPoint = xyd.checkCondition(tonumber(xyd.db.misc:getValue("esater_egg_first_touch")), false, true) or xyd.models.backpack:getItemNumByID(xyd.ItemID.PINK_BALLOON) > 0
			end)
		end
	end
end

return ActivityEasterEggData
