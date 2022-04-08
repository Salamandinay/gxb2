local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local WelfareSaleData = class("WelfareSaleData", ActivityData, true)

function WelfareSaleData:ctor(params)
	ActivityData.ctor(self, params)

	self.buyID = 0
end

function WelfareSaleData:getUpdateTime()
	return self:getEndTime()
end

function WelfareSaleData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local WelfareSaleTable = xyd.tables.welfareSaleTable
	local ids = WelfareSaleTable:getIds()
	local BingActivityID = xyd.ActivityID.PROPHET_SUMMON_GIFTBAG
	local data = xyd.models.activity:getActivity(BingActivityID)
	local point = 0

	if data then
		local roundMaxNum = xyd.tables.activityTable:getRound(BingActivityID)[1]
		point = data.detail.point + data.detail.circle_times * roundMaxNum
	end

	for i = 1, #ids do
		local id = ids[i]

		if WelfareSaleTable:getRequirement(id) <= point and self.detail.buy_times[id] < WelfareSaleTable:getLimit(id) then
			local nowTime = xyd.db.misc:getValue("activity_welfare_sale_giftbag_redmark")

			if not nowTime or not xyd.isSameDay(tonumber(nowTime), xyd.getServerTime()) then
				return true
			end

			break
		end
	end

	return false
end

function WelfareSaleData:setBuyID(id)
	self.buyID = id
end

function WelfareSaleData:onAward(data)
	if not self.buyID or self.buyID <= 0 then
		return
	end

	self.detail.buy_times[self.buyID] = self.detail.buy_times[self.buyID] + 1
end

return WelfareSaleData
