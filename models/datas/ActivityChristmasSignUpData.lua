local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityChristmasSignUpData = class("ActivityChristmasSignUpData", ActivityData, true)

function ActivityChristmasSignUpData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChristmasSignUpData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id == xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP then
			self:onGetMsg(event)
		end
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:onGetGiftbagMsg(event)
	end)

	self.firstTime = true
end

function ActivityChristmasSignUpData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self:getAward(self:getCurDateID()) ~= nil then
		if self:getCurGiftBag() ~= nil and self:getCurGiftBag() ~= 0 then
			if self.detail.charges == nil or self.detail.charges[self:getGiftBagIndex(self:getCurGiftBag())].limit_times <= self.detail.charges[self:getGiftBagIndex(self:getCurGiftBag())].buy_times then
				return false
			else
				if self.firstTime == false then
					return false
				end

				return true
			end
		else
			return false
		end
	else
		return true
	end

	return false
end

function ActivityChristmasSignUpData:getCurDateID()
	local time1 = xyd.getServerTime() - self:startTime()

	return math.floor(time1 / xyd.DAY_TIME) + 1
end

function ActivityChristmasSignUpData:getAward(id)
	if self.detail.records ~= nil and self.detail.records[id] ~= nil and self.detail.records[id] ~= 0 then
		local index = 0

		for i = 1, id do
			if self.detail.records[i] ~= 0 then
				index = index + 1
			end
		end

		return self.detail.item_records[index]
	else
		return nil
	end
end

function ActivityChristmasSignUpData:getCurGiftBag()
	return xyd.tables.activityChristmasSignUpCountDownAwardsTable:getGiftbagID(self:getCurDateID())
end

function ActivityChristmasSignUpData:onGetMsg(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP, function ()
		local detail = cjson.decode(event.data.detail)
		self.detail = detail
	end)
end

function ActivityChristmasSignUpData:onGetGiftbagMsg(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP, function ()
	end)
end

function ActivityChristmasSignUpData:onAward(giftbag_id)
	if giftbag_id and type(giftbag_id) == "number" then
		for i = 1, #self.detail.charges do
			if self.detail.charges[i].table_id == giftbag_id then
				self.detail.charges[i].buy_times = 1 + self.detail.charges[i].buy_times
			end
		end
	end
end

function ActivityChristmasSignUpData:getGiftBagIndex(giftbag_id)
	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftbag_id then
			return i
		end
	end
end

return ActivityChristmasSignUpData
