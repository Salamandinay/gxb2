local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityHalloweenData = class("ActivityHalloweenData", ActivityData, true)

function ActivityHalloweenData:getUpdateTime()
	return self:getEndTime()
end

function ActivityHalloweenData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.TRICKORTREAT_GET_AWARDS, handler(self, self.onTrickAward))
end

function ActivityHalloweenData:onTrickAward(event)
	local table_id = event.data.table_id
	self.detail.awards[table_id] = self.detail.awards[table_id] + 1
	local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

	if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_HALLOWEEN then
		common_progress_award_window_wn:updateItemState(table_id, 3)
	end

	local awards = xyd.tables.activityHalloweenTrickAwardTable:getAwards(table_id)
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

function ActivityHalloweenData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	self.defRedMark = false

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	else
		if self:isFirstRedMark() then
			self.defRedMark = true
		end

		if xyd.models.backpack:getItemNumByID(xyd.ItemID.GHOST_POTION) >= 1 then
			self.defRedMark = true
		end

		local awardIDs = xyd.tables.activityHalloweenTrickAwardTable:getIDs()

		for i = 1, #awardIDs do
			if xyd.tables.activityHalloweenTrickAwardTable:getComplete(i) <= self.detail.times and self.detail.awards[i] == 0 then
				self.defRedMark = true
			end
		end

		local shopIDs = xyd.tables.activityHalloweenShopTable:getIDs()

		for i = 1, #shopIDs do
			local cost = xyd.tables.activityHalloweenShopTable:getCost(i)

			if self.detail.buy_times[i] < xyd.tables.activityHalloweenShopTable:getLimit(i) and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				self.defRedMark = true
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_HALLOWEEN, self.defRedMark)

	return self.defRedMark
end

return ActivityHalloweenData
