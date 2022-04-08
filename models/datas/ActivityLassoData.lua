local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLassoData = class("ActivityLassoData", ActivityData, true)

function ActivityLassoData:ctor(params)
	ActivityData.ctor(self, params)

	self.isCheckBackPackNum = true
	self.isNeedBackShowRed = false
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
