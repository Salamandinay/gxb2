local ActivityData = import("app.models.ActivityData")
local Activity4AnniversarySignData = class("Activity4AnniversarySignData", ActivityData, true)
local cjson = require("cjson")

function Activity4AnniversarySignData:getUpdateTime()
	return self:getEndTime()
end

function Activity4AnniversarySignData:getDay()
	return math.ceil((xyd.getServerTime() - self.start_time) / 86400)
end

function Activity4AnniversarySignData:getSignTimes()
	local signTimes = 0

	for i in pairs(self.detail.awarded) do
		if self.detail.awarded[i] == 1 then
			signTimes = signTimes + 1
		end
	end

	return signTimes
end

function Activity4AnniversarySignData:onAward(data)
	if type(data) == "number" then
		self:onRecharge(data)
	else
		self:onGetActivityAward(data)

		local detail = cjson.decode(data.detail)
	end

	self:updateRedMark()
end

function Activity4AnniversarySignData:onRecharge(giftbagID)
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftbagID then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

			break
		end
	end
end

function Activity4AnniversarySignData:onGetActivityAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_4ANNIVERSARY_SIGN then
		return
	end

	self.detail = cjson.decode(data.detail)
	local awards = xyd.tables.activity4AnniversarySignTable:getAwards(self.curSign)
	local items = {}

	for i = 1, #awards do
		local award = awards[i]

		table.insert(items, {
			item_id = award[1],
			item_num = award[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(items)
end

function Activity4AnniversarySignData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_4ANNIVERSARY_SIGN, function ()
		self.holdRed = false
	end)
end

function Activity4AnniversarySignData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
		local viewTime = xyd.db.misc:getValue("activity_4anniversary_sign_viewtime")

		if self:getSignTimes() < 12 and (not viewTime or not xyd.isSameDay(viewTime, xyd.getServerTime())) then
			self.defRedMark = true
		end

		if self:getDay() <= 12 and self.detail.awarded[self:getDay()] ~= 1 then
			self.defRedMark = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4ANNIVERSARY_SIGN, self.defRedMark)

	return self.defRedMark
end

return Activity4AnniversarySignData
