local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySmashEggData = class("ActivitySmashEggData", ActivityData, true)

function ActivitySmashEggData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySmashEggData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail = detail.info
end

function ActivitySmashEggData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activitySmashEggTable:getItemIDs()

	for i = 1, #ids do
		if xyd.models.backpack:getItemNumByID(ids[i]) > 0 then
			return true
		end
	end

	return false
end

return ActivitySmashEggData
