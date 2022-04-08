local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGiftBagOptionalData = class("ActivityGiftBagOptionalData", ActivityData, true)

function ActivityGiftBagOptionalData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGiftBagOptionalData:onAward(event)
	local data = event

	if data and type(data) == "number" then
		for i = 1, #self.detail.charges do
			if data == self.detail.charges[i].table_id then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				break
			end
		end
	end
end

function ActivityGiftBagOptionalData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = xyd.db.misc:getValue("activity_giftbag_optional_redmark")

	if self:isFirstRedMark() then
		return true
	end

	if flag then
		return true
	end

	return false
end

return ActivityGiftBagOptionalData
