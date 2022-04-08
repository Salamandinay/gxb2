local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local OnlineAwardData = class("OnlineAwardData", ActivityData, true)

function OnlineAwardData:ctor()
	local params = {
		is_open = true,
		detail = "{}",
		days = 1,
		end_time = 0,
		start_time = 0,
		activity_id = xyd.ActivityID.ONLINE_AWARD
	}

	ActivityData.ctor(self, params)
end

function OnlineAwardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return xyd.models.selfPlayer.isShowOnlineAwardRedMark
end

return OnlineAwardData
