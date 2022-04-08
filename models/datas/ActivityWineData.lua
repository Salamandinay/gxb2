local ActivityData = import("app.models.ActivityData")
local ActivityWineData = class("ActivityWineData", ActivityData, true)
local json = require("cjson")

function ActivityWineData:ctor(params)
	ActivityData.ctor(self, params)

	self.isNeedDeal = true
end

function ActivityWineData:getUpdateTime()
	return self:getEndTime()
end

function ActivityWineData:register()
	self:registerEvent(xyd.event.ACTIVITY_WINE_COST, function (__, evt)
		local data = xyd.decodeProtoBuf(evt.data)
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(data.table_id)

		self:setRedMarkCheck(false)
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_WINE, function ()
			self:setRedMarkCheck(true)

			self.detail.point = self.detail.point + item_data[2] * data.num

			xyd.models.itemFloatModel:pushNewItems(data.items)
		end)
	end, self)
end

function ActivityWineData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_WINE then
		return
	end

	local detail = json.decode(data.detail)
	self.detail = detail.info
	local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

	if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_WINE then
		common_progress_award_window_wn:updateItemState(detail.table_id, 3)
	end

	xyd.models.itemFloatModel:pushNewItems(detail.items)

	for i, item in pairs(detail.items) do
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

function ActivityWineData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_WINE, false)

		return false
	end

	local flag = false
	local ids = xyd.tables.activity3BirthdayDinnerPointTable:getIDs()

	for i in pairs(ids) do
		local max_value = xyd.tables.activity3BirthdayDinnerPointTable:getPoint(ids[i])

		if self.detail.awards[i] == 0 and max_value <= self.detail.point then
			flag = true

			break
		end
	end

	flag = flag or self:getFirstToBagBtn(flag)
	flag = flag or self:getFirstToLoupeBtn(flag)

	if self.isNeedDeal and not flag then
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(1)

		if xyd.models.backpack:getItemNumByID(item_data[1]) / item_data[2] >= 1 then
			flag = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_WINE, flag)

	return flag
end

function ActivityWineData:getFirstToBagBtn(flag)
	local mark = xyd.db.misc:getValue("activity_wine_first_to_bag_btn")

	if not mark then
		flag = true
	end

	return flag
end

function ActivityWineData:getFirstToLoupeBtn(flag)
	local mark = xyd.db.misc:getValue("activity_wine_first_to_loupe_btn")

	if not mark then
		flag = true
	end

	return flag
end

function ActivityWineData:setRedMarkCheck(state)
	self.isNeedDeal = state
end

return ActivityWineData
