local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySpaceExploreTeamData = class("ActivitySpaceExploreTeamData", ActivityData, true)

function ActivitySpaceExploreTeamData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function ActivitySpaceExploreTeamData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpaceExploreTeamData:onAward(data)
	local detail = json.decode(data.detail)
	local ids = detail.ids
	local partners = xyd.tables.activitySpaceExplorePartnerTable:getIDs()
	local hasPartners = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SPACE_EXPLORE).detail_.partners

	for _, id in ipairs(ids) do
		for index, partnerId in ipairs(partners) do
			if id == partnerId then
				if hasPartners[index] == 0 then
					hasPartners[index] = 1
				end

				break
			end
		end
	end

	self.detail_.times = detail.info.times
end

return ActivitySpaceExploreTeamData
