local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityStarPlanData = class("ActivityStarPlanData", ActivityData, true)

function ActivityStarPlanData:ctor(params)
	ActivityData.ctor(self, params)

	self.resItemNum = xyd.models.backpack:getItemNumByID(454)
end

function ActivityStarPlanData:getUpdateTime()
	return self:getEndTime()
end

function ActivityStarPlanData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityStarPlanData:getBoxInfo()
	local list = self.detail_.list
	local boxInfo = {}

	for index, id in ipairs(list) do
		if not boxInfo[id] then
			boxInfo[id] = 1
		else
			boxInfo[id] = boxInfo[id] + 1
		end
	end

	return boxInfo
end

function ActivityStarPlanData:onAward(data)
	if not data then
		return
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_STAR_PLAN, function ()
		if data.detail and tostring(data.detail) ~= "" then
			local details = json.decode(data.detail)
			local type_ = details.type

			if type_ == 5 then
				self.detail_.list = details.list
			elseif type_ == 1 then
				self.detail_.buy = self.detail_.buy + details.num
			elseif type_ == 3 then
				self.targetList_ = details.list
				self.detail_.times = details.num + self.detail_.times
			elseif type_ == 4 then
				self.detail_.list = details.list
				local id = details.id
				self.detail_.awards[id] = 1
			end
		elseif self.tempItemInfo_ then
			self.detail_.buy_times[self.tempItemInfo_.award_id] = self.detail_.buy_times[self.tempItemInfo_.award_id] + self.tempItemInfo_.num
			self.tempItemInfo_ = nil
		end
	end)
end

function ActivityStarPlanData:getRedMarkState()
	local flag = false

	if self.resItemNum > 0 then
		flag = true
	end

	if self:checkShopRed() then
		flag = true
	end

	return flag
end

function ActivityStarPlanData:checkShopRed()
	local num = self.detail_.times
	local ids = xyd.tables.activityStarPlanAwardsTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local needNum = xyd.tables.activityStarPlanAwardsTable:getNum(id)

		if needNum <= num and self.detail_.awards[id] ~= 1 then
			return true
		end
	end

	return false
end

function ActivityStarPlanData:setTempInfo(itemInfo)
	if itemInfo then
		self.tempItemInfo_ = itemInfo
	end
end

function ActivityStarPlanData:checkUpdateList()
	if self.targetList_ then
		self.detail_.list = self.targetList_
		self.targetList_ = nil

		if not self.detail_.list or #self.detail_.list <= 0 then
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, json.encode({
				type = 5
			}))
		end
	end
end

function ActivityStarPlanData:onItemChange(event)
	local items = event.data.items

	for i = 1, #items do
		if items[i].item_id == 454 then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_STAR_PLAN, function ()
				self.resItemNum = xyd.models.backpack:getItemNumByID(454)
			end)
		end
	end
end

function ActivityStarPlanData:getBuyLeftTime()
	local costData = xyd.split2(xyd.tables.miscTable:getVal("activity_star_plan_buy"), {
		"|",
		"#"
	})
	local limit = tonumber(costData[2][1])

	return math.max(limit - self.detail_.buy, 0)
end

return ActivityStarPlanData
