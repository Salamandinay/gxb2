local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTreeGroupData = class("ActivityTreeGroupData", ActivityData, true)

function ActivityTreeGroupData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTreeGroupData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local val = xyd.db.misc:getValue("activity_tree_group_redmark")

	if val == nil or val == false then
		return true
	end

	return false
end

return ActivityTreeGroupData
