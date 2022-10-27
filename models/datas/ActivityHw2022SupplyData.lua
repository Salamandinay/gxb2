local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityHw2022SupplyData = class("ActivityHw2022SupplyData", ActivityData, true)

function ActivityHw2022SupplyData:ctor(params)
	ActivityData.ctor(self, params)
end

function ActivityHw2022SupplyData:getUpdateTime()
	return self:getEndTime()
end

function ActivityHw2022SupplyData:getPointNow()
	local startTime = self:startTime()
	local durningTime = (xyd.getServerTime() - startTime) / 60
	local maxPoint = tonumber(xyd.tables.miscTable:getVal("activity_halloween2022_limit_max"))
	local point = 0

	if durningTime <= 720 then
		point = math.floor(durningTime^2.3444483889)
	elseif durningTime > 720 and durningTime < 1750 then
		point = math.log10(durningTime) / math.log10(1.000000071) - 87600835.06
	elseif durningTime >= 1750 then
		point = math.floor(6097.560976 * durningTime + 6829268.293)
	else
		point = maxPoint
	end

	if maxPoint < point then
		point = maxPoint
	end

	return point
end

function ActivityHw2022SupplyData:onAward(data)
	if type(data) == "number" then
		for _, charge in pairs(self.detail_.charges) do
			if charge.table_id == data then
				charge.buy_times = charge.buy_times + 1
			end
		end
	else
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022_SUPPLY, function ()
			if data.activity_id ~= xyd.ActivityID.ACTIVITY_HW2022_SUPPLY then
				return
			end

			local data_ = xyd.decodeProtoBuf(data)
			local info = require("cjson").decode(data_.detail)
			self.detail_.awards = info.info.awards
		end)
	end
end

function ActivityHw2022SupplyData:getRedMarkState()
	local ids = xyd.tables.activityHw2022GiftbagTable:getIDs()
	local awardedData = self.detail_.awards
	local redState = false

	for index, id in ipairs(ids) do
		local awardTime = xyd.tables.activityHw2022GiftbagTable:getOpenTime(id)

		if awardTime <= xyd.getServerTime() and (not awardedData[index] or awardedData[index] == 0) then
			redState = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HW2022_SUPPLY, redState)

	return redState
end

return ActivityHw2022SupplyData
