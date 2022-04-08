local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SpringNewYearData = class("SpringNewYearData", ActivityData, true)

function SpringNewYearData:ctor(params)
	self.isCheckCountRed = false

	ActivityData.ctor(self, params)
end

function SpringNewYearData:getUpdateTime()
	return self:getEndTime()
end

function SpringNewYearData:setIsCheckCountRed(flag)
	self.isCheckCountRed = flag
end

function SpringNewYearData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local isHasRed = false

	if self.isCheckCountRed then
		isHasRed = self.lastRedState
	else
		for i, index in pairs(self.detail.limits) do
			if index == 0 then
				local isHaveBuyPartner = false

				for j in pairs(self.detail.buy_times) do
					if self.detail.buy_times[i][j] == 0 then
						isHaveBuyPartner = true

						break
					end
				end

				if isHaveBuyPartner and xyd.tables.activitySpringFestivalAwardTble:getCost(i)[2] <= xyd.models.backpack:getItemNumByID(xyd.ItemID.SPRING_NEW_YEAR) then
					isHasRed = true

					break
				end
			end
		end
	end

	self.lastRedState = isHasRed

	return isHasRed
end

function SpringNewYearData:onAward(data)
	local data = xyd.decodeProtoBuf(data)
	data = json.decode(data.detail)

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.SPRING_NEW_YEAR, function ()
		self.detail.buy_times = data.info.buy_times
		self.detail.limits = data.info.limits
		self.detail.point = data.info.point
	end)
	xyd.models.itemFloatModel:pushNewItems(data.items)
end

return SpringNewYearData
