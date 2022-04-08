local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityPartnerGalleryData = class("ActivityPartnerGalleryData", ActivityData, true)

function ActivityPartnerGalleryData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPartnerGalleryData:getAward(tableID)
	self.detail_.awards[tableID] = 1
end

function ActivityPartnerGalleryData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false
	local ids = xyd.tables.activityPartnerGalleryAwardTable:getIDs()

	for _, id in ipairs(ids) do
		local needPoint = xyd.tables.activityPartnerGalleryAwardTable:getPoint(id)
		flag = flag or needPoint <= self.detail_.score and self.detail_.awards[id] == 0
	end

	return flag
end

return ActivityPartnerGalleryData
