local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityKakaopayData = class("ActivityKakaopayData", ActivityData, true)

function ActivityKakaopayData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	if not xyd.isH5() then
		return true
	end

	if UNITY_EDITOR or UNITY_ANDROID and xyd.Global.lang == "ko_kr" then
		return false
	else
		return true
	end
end

return ActivityKakaopayData
