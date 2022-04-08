local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewBieCampData = class("NewBieCampData", ActivityData, true)

function NewBieCampData:ctor()
	local params = {
		is_open = true,
		detail = "{}",
		days = 1,
		end_time = 0,
		start_time = 0,
		activity_id = xyd.ActivityID.NEWBIE_CAMP
	}

	ActivityData.ctor(self, params)
end

function NewBieCampData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return xyd.models.redMark:getRedState(xyd.RedMarkType.NEWBIE_CAMP)
end

return NewBieCampData
