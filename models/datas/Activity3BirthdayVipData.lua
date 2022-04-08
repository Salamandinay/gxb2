local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local Activity3BirthdayVipData = class("Activity3BirthdayVipData", ActivityData, true)

function Activity3BirthdayVipData:ctor(params)
	ActivityData.ctor(self, params)

	self.isNeedDeal = true
	self.redMarkState = true
end

function Activity3BirthdayVipData:getUpdateTime()
	return self:getEndTime()
end

function Activity3BirthdayVipData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP then
		return
	end

	local detail = cjson.decode(data.detail)

	xyd.models.itemFloatModel:pushNewItems(detail.items)

	self.detail.awards = detail.info.awards
end

function Activity3BirthdayVipData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_3BIRTHDAY_VIP, false)

		self.redMarkState = false

		return false
	end

	if self:isFirstRedMark() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_3BIRTHDAY_VIP, true)

		self.redMarkState = true

		return true
	end

	if self.isNeedDeal then
		local flag = false
		local vipLev = xyd.models.backpack:getVipLev()
		local ids = xyd.tables.activity3BirthdayVipAwardTable:getIds()

		for i, id in ipairs(ids) do
			if xyd.tables.activity3BirthdayVipAwardTable:getVipLevel(id) <= vipLev and self.detail.awards[i] == 0 then
				flag = true

				break
			end
		end

		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_3BIRTHDAY_VIP, flag)

		self.redMarkState = flag

		return flag
	end

	return self.redMarkState
end

function Activity3BirthdayVipData:setRedMarkCheck(state)
	self.isNeedDeal = state
end

return Activity3BirthdayVipData
