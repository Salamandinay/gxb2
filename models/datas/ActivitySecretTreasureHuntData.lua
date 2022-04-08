local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySecretTreasureHuntData = class("ActivitySecretTreasureHuntData", ActivityData, true)

function ActivitySecretTreasureHuntData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySecretTreasureHuntData:getRedMarkState()
	self.resID = xyd.tables.miscTable:split2Cost("find_treasure_item", "value", "|#")[1][1]
	local red = false

	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SECRET_TREASURE_HUNT, false)

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SECRET_TREASURE_HUNT, true)

		return true
	end

	if xyd.models.backpack:getItemNumByID(self.resID) > 0 then
		red = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SECRET_TREASURE_HUNT, red)

	return red
end

return ActivitySecretTreasureHuntData
