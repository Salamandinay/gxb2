local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local BindAccountEntryData = class("BindAccountEntryData", ActivityData, true)

function BindAccountEntryData:ctor()
	local params = {
		is_open = true,
		detail = "{}",
		days = 1,
		end_time = 0,
		start_time = 0,
		activity_id = xyd.ActivityID.BIND_ACCOUNT_ENTRY
	}

	ActivityData.ctor(self, params)
end

function BindAccountEntryData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return xyd.models.achievement.isShowBindAccountRedMark
end

return BindAccountEntryData
