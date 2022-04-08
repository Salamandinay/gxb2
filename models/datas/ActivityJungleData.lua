local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityJungleData = class("ActivityJungleData", GiftBagData, true)

function ActivityJungleData:ctor(params)
	ActivityData.ctor(self, params)

	self.exchangeID = 0
	self.exchangeTime = 0
	self.item_info = {}
	self.awardedID = 0
	self.singleCost = xyd.tables.miscTable:split2num("activity_jungle_cost", "value", "#")
end

function ActivityJungleData:register()
	self:registerEvent(xyd.event.USE_JUNGLE_ITEM, function (__, evt)
		self.item_info = {}
		local data = xyd.decodeProtoBuf(evt.data)
		local items = data.items

		for i = 1, #items do
			table.insert(self.item_info, items[i])
		end

		for i = 1, #data.points do
			self.detail.points[i] = data.points[i]
		end
	end, self)
	self:registerEvent(xyd.event.GET_JUNGLE_AWARD, function (__, evt)
		self.item_info = {}
		self.awardedID = 0
		local data = xyd.decodeProtoBuf(evt.data)

		for i = 1, #data.awarded do
			if self.detail.awarded[i] ~= data.awarded[i] then
				self.detail.awarded[i] = data.awarded[i]
				self.awardedID = i
				local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

				if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_JUNGLE then
					common_progress_award_window_wn:updateItemState(tonumber(self.awardedID), 3)
				end
			end
		end
	end, self)
end

function ActivityJungleData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false

	if self.singleCost[2] < xyd.models.backpack:getItemNumByID(255) then
		return true
	end

	if self:getExploreProgressRedMarkState(1) or self:getExploreProgressRedMarkState(2) or self:getExploreProgressRedMarkState(3) then
		flag = true
	end

	return flag
end

function ActivityJungleData:getExploreProgressRedMarkState(area)
	local flag = xyd.db.misc:getValue("ExploreProgressRedMark" .. area)

	if flag == nil then
		return true
	end

	local ids = xyd.tables.ActivityJungleAwardsTable:getIDs()

	for i in pairs(ids) do
		if self.detail.awarded[i] == 0 and area == xyd.tables.ActivityJungleAwardsTable:getArea(i) and xyd.tables.ActivityJungleAwardsTable:getPoint(i) <= self.detail.points[area] then
			return true
		end
	end

	return false
end

function ActivityJungleData:getUpdateTime()
	return self:getEndTime()
end

function ActivityJungleData:onAward(data)
	self.detail.buy_times[self.exchangeID] = self.detail.buy_times[self.exchangeID] + self.exchangeTime
end

function ActivityJungleData:setExchangeInfo(id, time)
	self.exchangeID = id
	self.exchangeTime = time
end

return ActivityJungleData
