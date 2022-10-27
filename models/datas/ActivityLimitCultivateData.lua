local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLimitCultivateData = class("ActivityLimitCultivateData", ActivityData, true)
local activityID = xyd.ActivityID.ACTIVITY_LIMIT_CULTIVATE
local resItemID = xyd.ItemID.ACTIVITY_5WEEK_COST

function ActivityLimitCultivateData:ctor(params)
	ActivityData.ctor(self, params)

	self.resItemNum = xyd.models.backpack:getItemNumByID(resItemID)
end

function ActivityLimitCultivateData:getUpdateTime()
	return self.detail.start_time + 604800
end

function ActivityLimitCultivateData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		if event.data.activity_id ~= activityID then
			return
		end

		local details = require("cjson").decode(event.data.detail)

		if details.type == 1 then
			self.detail.lefts = details.info.lefts
		end

		self:updateRedMark()
	end)
end

function ActivityLimitCultivateData:onItemChange(event)
	local needUpdate = false
	local items = event.data.items

	for i = 1, #items do
		if items[i].item_id == resItemID then
			self:updateRedMark()
		end
	end
end

function ActivityLimitCultivateData:updateRedMark()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_LIMIT_CULTIVATE, function ()
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_LIMIT_CULTIVATE, self:getRedMarkState())
	end)
end

function ActivityLimitCultivateData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	elseif xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_5WEEK_COST) > 0 then
		self.defRedMark = true
	else
		self.defRedMark = false
	end

	local leftNum = 0
	local lefts = self.detail.lefts

	for i = 1, #lefts do
		leftNum = leftNum + lefts[i]
	end

	if leftNum <= 0 then
		self.defRedMark = false
	end

	return self.defRedMark
end

return ActivityLimitCultivateData
