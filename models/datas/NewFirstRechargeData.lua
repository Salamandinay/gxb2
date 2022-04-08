local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewFirstRechargeData = class("NewFirstRechargeData", ActivityData, true)

function NewFirstRechargeData:getLoginDay()
	return math.ceil((xyd.getServerTime() - xyd.models.selfPlayer:getCreatedTime()) / xyd.TimePeriod.DAY_TIME)
end

function NewFirstRechargeData:getAwardDay()
	if self.detail.update_time == 0 then
		return 0
	else
		return math.ceil((xyd.getServerTime() - self.detail.update_time) / xyd.TimePeriod.DAY_TIME)
	end
end

function NewFirstRechargeData:onRecharge()
	self.detail.can_award = 1
	self.detail.update_time = xyd.getServerTime() - 1

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEW_FIRST_RECHARGE, function ()
	end)
end

function NewFirstRechargeData:isHide(type)
	if type == xyd.EventType.YEARS then
		return false
	elseif self:getLoginDay() <= 7 then
		return true
	else
		local isAwards = self.detail.is_awarded

		for i = 1, #isAwards do
			if isAwards[i] == 0 then
				return false
			end
		end

		return true
	end
end

function NewFirstRechargeData:onAward(data)
	local awardsList = json.decode(data.detail).is_awarded
	self.awardList = {}

	for i = 1, #awardsList do
		if awardsList[i] == 1 and self.detail.is_awarded[i] == 0 then
			table.insert(self.awardList, i)

			self.detail.is_awarded[i] = 1
		end
	end
end

function NewFirstRechargeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self.detail.can_award == 0 then
		local nowDay = self:getLoginDay()
		local lastLoginDay = tonumber(xyd.db.misc:getValue("new_first_recharge_last_day")) or 0

		if nowDay - lastLoginDay >= 1 then
			xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIRST_RECHARGE, true)

			if self:isHide() then
				return false
			else
				return true
			end
		end
	else
		local nowDay = math.min(self:getAwardDay(), 3)
		local flag = self.detail.is_awarded[nowDay] == 0

		xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIRST_RECHARGE, flag)

		if self:isHide() then
			return false
		else
			return flag
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.NEW_FIRST_RECHARGE, false)

	return false
end

function NewFirstRechargeData:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local nowDay = self:getLoginDay()
		local lastLoginDay = tonumber(xyd.db.misc:getValue("new_first_recharge_last_day")) or 0

		return self:getLoginDay() <= 7 and nowDay - lastLoginDay >= 1
	end

	return false
end

function NewFirstRechargeData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

function NewFirstRechargeData:getPopWinName()
	return "new_first_recharge_pop_up_window"
end

return NewFirstRechargeData
