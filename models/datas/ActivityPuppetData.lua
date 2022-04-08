local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityPuppetData = class("ActivityPuppetData", GiftBagData, true)

function ActivityPuppetData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPuppetData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

return ActivityPuppetData
