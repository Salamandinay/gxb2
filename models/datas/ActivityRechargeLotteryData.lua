local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityRechargeLotteryData = class("ActivityRechargeLotteryData", ActivityData, true)
local resItemID = xyd.ItemID.RECHARGE_LOTTERY_TICKET

function ActivityRechargeLotteryData:ctor(params)
	ActivityData.ctor(self, params)

	self.resItemNum = xyd.models.backpack:getItemNumByID(resItemID)
end

function ActivityRechargeLotteryData:getUpdateTime()
	return self:getEndTime()
end

function ActivityRechargeLotteryData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityRechargeLotteryData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY then
		return
	end

	local result = string.gsub(data.detail, "'", "\"")
	local newDetail = cjson.decode(result)

	for i in ipairs(self.detail.awards) do
		if self.detail.awards[i] ~= newDetail.awards[i] then
			self.awardID = i
		end
	end

	self.detail = newDetail
end

function ActivityRechargeLotteryData:onItemChange(event)
	local needUpdate = false
	local items = event.data.items

	for i = 1, #items do
		if items[i].item_id == resItemID then
			if self.resItemNum < xyd.models.backpack:getItemNumByID(resItemID) then
				xyd.models.itemFloatModel:pushNewItems({
					{
						item_id = resItemID,
						item_num = xyd.models.backpack:getItemNumByID(resItemID) - self.resItemNum
					}
				})

				needUpdate = true
			end

			self.resItemNum = xyd.models.backpack:getItemNumByID(resItemID)
		end
	end

	if needUpdate then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY)
	end

	self:updateRedMark()
end

function ActivityRechargeLotteryData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_RECHARGE_LOTTERY, function ()
		self.holdRed = false
	end)
end

function ActivityRechargeLotteryData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local isFinish = true

		for _, v in pairs(self.detail.awards) do
			if v ~= 1 then
				isFinish = false
			end
		end

		local lastViewTime = xyd.db.misc:getValue("activity_recharge_lottery_view_time")

		if isFinish then
			self.defRedMark = false
		elseif not lastViewTime or not xyd.isSameDay(tonumber(lastViewTime), xyd.getServerTime()) then
			self.defRedMark = true
		elseif xyd.models.backpack:getItemNumByID(xyd.ItemID.RECHARGE_LOTTERY_TICKET) > 0 then
			self.defRedMark = true
		else
			self.defRedMark = false
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_RECHARGE_LOTTERY, self.defRedMark)

	return self.defRedMark
end

return ActivityRechargeLotteryData
