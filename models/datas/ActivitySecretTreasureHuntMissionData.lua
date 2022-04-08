local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySecretTreasureHuntMissionData = class("ActivitySecretTreasureHuntMissionData", ActivityData, true)

function ActivitySecretTreasureHuntMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySecretTreasureHuntMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local lastViewTime = xyd.db.misc:getValue("secret_treasure_hunt_mission_view_time")

		if not lastViewTime or not xyd.isSameDay(lastViewTime, xyd.getServerTime()) then
			self.defRedMark = true
		else
			self.defRedMark = false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SECRET_TREASURE_HUNT_MISSION, self.defRedMark)

	return self.defRedMark
end

return ActivitySecretTreasureHuntMissionData
