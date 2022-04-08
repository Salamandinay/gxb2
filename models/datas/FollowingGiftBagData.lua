local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local FollowingGiftBagData = class("FollowingGiftBagData", ActivityData, true)

function FollowingGiftBagData:onAward(giftBagID)
	self.isTouched = false
	self.detail.is_awarded = 1
end

function FollowingGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if xyd.isH5() == false then
		return false
	end

	if self.isTouched then
		return false
	end

	if not self.detail.is_awarded or self.detail.is_awarded <= 0 then
		return true
	end

	local creatTime = xyd.db.misc:getValue("activity_follow_gift")

	if creatTime and xyd.getServerTime() - tonumber(creatTime) < 259200 then
		return true
	end

	return false
end

return FollowingGiftBagData
