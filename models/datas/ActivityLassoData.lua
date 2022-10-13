local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLassoData = class("ActivityLassoData", ActivityData, true)

function ActivityLassoData:ctor(params)
	ActivityData.ctor(self, params)

	self.isCheckBackPackNum = true
	self.isNeedBackShowRed = false

	self:registerEvent(xyd.event.BOSS_BUY, handler(self, self.onItemBuyBack))
end

function ActivityLassoData:onItemBuyBack(event)
	if event.data.activity_id and event.data.activity_id == xyd.ActivityID.ACTIVITY_LASSO then
		local getCost = xyd.tables.miscTable:split2Cost("activity_lasso_buy", "value", "|#")[2]
		local timesDis = event.data.buy_times - self.detail.buy_times

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = getCost[1],
				item_num = getCost[2] * timesDis
			}
		})

		self.detail.buy_times = event.data.buy_times
	end
end

function ActivityLassoData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLassoData:onAward(data)
	data = xyd.decodeProtoBuf(data)
	local dataValue = json.decode(data.detail)
	self.detail = dataValue.info
	local items = {}

	for k, v in ipairs(dataValue.items) do
		table.insert(items, {
			item_id = v[1],
			item_num = v[2]
		})
	end

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.ACTIVITY_LASSO_GET_AWARD,
		params = {
			ids = dataValue.award_ids,
			items = items
		}
	})
end

function ActivityLassoData:getLeftCircle()
	local leftNum = 1

	for k, v in ipairs(self.detail.awards) do
		if v == 0 then
			leftNum = leftNum + 1
		end
	end

	return leftNum
end

function ActivityLassoData:getRedMarkState()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.LASSO) > 0
end

return ActivityLassoData
