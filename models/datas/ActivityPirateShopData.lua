local ActivityData = import("app.models.ActivityData")
local ActivityPirateShopData = class("ActivityPirateShopData", ActivityData, true)
local json = require("cjson")

function ActivityPirateShopData:ctor(params)
	self.checkItemId = 411
	self.checkItemNeedNum = 50
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivityPirateShopData.super.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityPirateShopData:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == self.checkItemId then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE, function ()
				self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)
			end)

			break
		end
	end
end

function ActivityPirateShopData:getRedMarkState()
	local redState = false

	if self.checkItemNeedNum <= self.checkBackpackItemNum then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_PIRATE_SHOP, redState)

	return redState
end

function ActivityPirateShopData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPirateShopData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_PIRATE_SHOP, function ()
		if data.activity_id == xyd.ActivityID.ACTIVITY_PIRATE_SHOP then
			local detail = json.decode(data.detail)
			self.detail.unlock_item_times = detail.unlock_item_times
			self.detail.buy_times = detail.buy_times
			local items = detail.items

			xyd.models.itemFloatModel:pushNewItems(items)
			dump(detail)
		end
	end)
end

return ActivityPirateShopData
