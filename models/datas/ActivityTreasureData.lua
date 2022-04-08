local ActivityData = import("app.models.ActivityData")
local ActivityTreasureData = class("ActivityTreasureData", ActivityData, true)
local json = require("cjson")

function ActivityTreasureData:ctor(params)
	ActivityData.ctor(self, params)

	self.isNeedDeal = true
end

function ActivityTreasureData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTreasureData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_TREASURE then
		return
	end

	local detail = json.decode(data.detail)
	self.detail = detail.info

	xyd.openWindow("gamble_rewards_window", {
		isNeedCostBtn = false,
		data = detail.items
	})
end

function ActivityTreasureData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false

	if self.isNeedDeal and not flag then
		local item_data = xyd.tables.miscTable:split2num("activity_3birthday_gamble2", "value", "#")

		if xyd.models.backpack:getItemNumByID(item_data[1]) / item_data[2] >= 1 then
			flag = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TREASURE, flag)

	return flag
end

function ActivityTreasureData:setRedMarkCheck(state)
	self.isNeedDeal = state
end

return ActivityTreasureData
