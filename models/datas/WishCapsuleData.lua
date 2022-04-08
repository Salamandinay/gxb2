local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local WishCapsuleData = class("WishCapsuleData", ActivityData, true)

function WishCapsuleData:ctor(params)
	ActivityData.ctor(self, params)
end

function WishCapsuleData:getUpdateTime()
	return self:getEndTime()
end

function WishCapsuleData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local val = xyd.db.misc:getValue("wish_capsule_redmark")

	if val and val == "true" then
		return false
	end

	return true
end

function WishCapsuleData:selectIndex(selectInfo)
	local miscDataArr = xyd.tables.miscTable:split2Cost("wish_gacha_partners", "value", "|")
	local partnerId = miscDataArr[tonumber(selectInfo.select_index)]

	if miscDataArr and partnerId then
		self.detail.select_id = partnerId
	end

	local wishCapsuleSelectWin = xyd.WindowManager.get():getWindow("wish_capsule_select_window")

	if wishCapsuleSelectWin then
		xyd.WindowManager.get():closeWindow(wishCapsuleSelectWin.name_)
	end

	local summonWin = xyd.WindowManager.get():getWindow("summon_window")

	if summonWin then
		summonWin:refreshWishEnterEffect(false)
	end
end

return WishCapsuleData
