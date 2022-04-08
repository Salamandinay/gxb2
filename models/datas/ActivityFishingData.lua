local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFishingData = class("ActivityFishingData", ActivityData, true)

function ActivityFishingData:getUpdateTime()
	return self:getEndTime()
end

function ActivityFishingData:register()
	self.firstTime = true
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GO_FISHING, handler(self, self.onFishing))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityFishingData:onFishing(event)
	self.detail.point = self.detail.point + 1
	self.detail.fishs[event.data.id].num = self.detail.fishs[event.data.id].num + 1

	if self.detail.fishs[event.data.id].num == 1 then
		self.collectUpdateMark = true
	end

	if event.data.len < self.detail.fishs[event.data.id].min or self.detail.fishs[event.data.id].min == 0 then
		self.detail.fishs[event.data.id].min = event.data.len
		self.collectUpdateMark = true
	end

	if self.detail.fishs[event.data.id].max < event.data.len or self.detail.fishs[event.data.id].max == 0 then
		self.detail.fishs[event.data.id].max = event.data.len
		self.collectUpdateMark = true
	end

	if event.data.need_id and tostring(event.data.need_id) ~= "" then
		self.detail.need_id = event.data.need_id
		self.detail.award = event.data.award
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_FISHING, function ()
		self:getRedMarkState()
	end)
end

function ActivityFishingData:onItemChange()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_FISHING, function ()
		self:getRedMarkState()
	end)
end

function ActivityFishingData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_FISHING then
		return
	end

	local table_id = json.decode(data.detail).table_id
	self.detail.awards[table_id] = self.detail.awards[table_id] + 1
	local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

	if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.FISHING then
		common_progress_award_window_wn:updateItemState(table_id, 3)
	end

	local awards = xyd.tables.activityFishingAwardTable:getAwards(table_id)
	local award_items = {}

	for i = 1, #awards do
		local award = awards[i]

		table.insert(award_items, {
			item_id = award[1],
			item_num = award[2]
		})
	end

	xyd.models.itemFloatModel:pushNewItems(award_items)

	for i, item in pairs(award_items) do
		local type = xyd.tables.itemTable:getType(item.item_id)

		if type == xyd.ItemType.SKIN then
			xyd.onGetNewPartnersOrSkins({
				destory_res = false,
				skins = {
					tonumber(item.item_id)
				}
			})
		end
	end
end

function ActivityFishingData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self:getFishableRedMark() or self:getCollectRedMark() or self:getAwardRedMark() then
		return true
	end

	return false
end

function ActivityFishingData:getFishableRedMark()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.FISHING_ROD) > 5 then
		return true
	else
		return false
	end
end

function ActivityFishingData:getCollectRedMark()
	if self.collectUpdateMark then
		return true
	else
		return false
	end
end

function ActivityFishingData:getAwardRedMark()
	local ids = xyd.tables.activityFishingAwardTable:getIDs()

	for i = 1, #ids do
		if self.detail.awards[i] == 0 and xyd.tables.activityFishingAwardTable:getComplete(ids[i]) <= self.detail.point then
			return true
		end
	end

	return false
end

return ActivityFishingData
