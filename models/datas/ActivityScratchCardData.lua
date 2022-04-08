local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityScratchCardData = class("ActivityScratchCardData", ActivityData, true)

function ActivityScratchCardData:getUpdateTime()
	return self:getEndTime()
end

function ActivityScratchCardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return xyd.models.backpack:getItemNumByID(xyd.ItemID.SCRATCH_CARD_TICKET) > 0
end

function ActivityScratchCardData:onAward(data)
	local real_data = json.decode(data.detail)
	local items = real_data.items
	local awards = real_data.awards

	if not self.detail.records or self.detail.records == 0 then
		self.detail.records = {}
	end

	for i = 1, #items do
		table.insert(self.detail.records, 1, {
			items = items[i],
			awards = awards[i]
		})
	end
end

return ActivityScratchCardData
