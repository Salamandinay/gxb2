local ActivityData = import("app.models.ActivityData")
local ActivityChimeData = class("ActivityChimeData", ActivityData, true)
local json = require("cjson")

function ActivityChimeData:ctor(params)
	for i = 1, 2 do
		self["itemShow" .. i] = xyd.tables.miscTable:split2num("activity_chime_cost" .. i, "value", "#")
	end

	self.oldCostIdNum1 = xyd.models.backpack:getItemNumByID(self.itemShow1[1])
	self.oldCostIdNum2 = xyd.models.backpack:getItemNumByID(self.itemShow2[1])

	ActivityData.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityChimeData:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == self.itemShow1[1] then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHIME, function ()
				self.oldCostIdNum1 = xyd.models.backpack:getItemNumByID(self.itemShow1[1])
			end)
		elseif itemId == self.itemShow2[1] then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHIME, function ()
				self.oldCostIdNum2 = xyd.models.backpack:getItemNumByID(self.itemShow2[1])
			end)
		end
	end
end

function ActivityChimeData:getUpdateTime()
	return self:getEndTime()
end

function ActivityChimeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	self:checkRedPointOfTask()

	if self:checkDayGiftBuyRed() then
		return true
	end

	if self:checkRedPointOfTask() then
		return true
	end

	if self.itemShow1[2] <= self.oldCostIdNum1 then
		return true
	end

	if self.itemShow2[2] <= self.oldCostIdNum2 then
		return true
	end

	return false
end

function ActivityChimeData:setData(params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHIME, function ()
		ActivityChimeData.super.setData(self, params)
	end)
end

function ActivityChimeData:getChargesInfo()
	return xyd.cloneTable(self.detail.charges)
end

function ActivityChimeData:onAward(event)
	if type(event) == "number" then
		local giftBagID = event

		for i in pairs(self.detail.charges) do
			if self.detail.charges[i].table_id == giftBagID then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
			end
		end

		local mailId = xyd.tables.giftBagTable:getMailId(giftBagID)

		if mailId and mailId > 0 then
			xyd.alertTips(__("PURCHASE_SUCCESS"))
		end
	else
		if event.activity_id ~= xyd.ActivityID.ACTIVITY_CHIME then
			return
		end

		local data = xyd.decodeProtoBuf(event)
		local info = json.decode(data.detail)

		dump(info, "data_back_308=----------------")

		local type = info.type

		if type == xyd.ActivityChimeReqType.COMMON or type == xyd.ActivityChimeReqType.HIGH then
			local items = info.items

			for i, itemInfo in pairs(items) do
				if self.detail.items[tostring(itemInfo.item_id)] then
					self.detail.items[tostring(itemInfo.item_id)] = self.detail.items[tostring(itemInfo.item_id)] + itemInfo.item_num
				else
					self.detail.items[tostring(itemInfo.item_id)] = itemInfo.item_num
				end
			end

			local data = {}

			for _, award in pairs(items) do
				table.insert(data, {
					item_id = award.item_id,
					item_num = award.item_num,
					cool = xyd.tables.activityChimeDropboxTable:getIsShowWithAward(award.item_id, award.item_num)
				})

				if type == xyd.ActivityChimeReqType.HIGH then
					local isBig = xyd.tables.activityChimeDropboxTable:getIsBigWithAward(award.item_id, award.item_num)

					if isBig and isBig == 1 then
						self.detail.times = 0
					else
						self.detail.times = self.detail.times + 1
					end
				end
			end

			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 1,
				isNeedCostBtn = false,
				data = data
			})
		elseif type == xyd.ActivityChimeReqType.TASK then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_CHIME, function ()
				local id = info.table_id
				self.detail.values[id] = 0
				self.detail.is_completeds[id] = 0
				self.detail.awards[id] = 1
			end)
		end
	end
end

function ActivityChimeData:getTimes()
	return self.detail.times
end

function ActivityChimeData:getMissionAward(id)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_CHIME, require("cjson").encode({
		type = 3,
		table_id = id
	}))
end

function ActivityChimeData:getIsCompleteByTaskID(id)
	return self.detail.is_completeds[id] or 0
end

function ActivityChimeData:getValueByTaskID(id)
	local complete = self:getIsCompleteByTaskID(id)
	local awarded = self:getIsAwardedByTaskID(id)

	if complete > 0 or awarded > 0 then
		return xyd.tables.activityChimeMissionTable:getCompleteValue(id)
	else
		return self.detail.values[id] or 0
	end
end

function ActivityChimeData:getIsAwardedByTaskID(id)
	return self.detail.awards[id] or 0
end

function ActivityChimeData:checkRedPointOfTask(id)
	local ids = xyd.tables.activityChimeMissionTable:getIDs()

	for i = 1, #ids do
		if self:getIsCompleteByTaskID(i) > 0 and self:getIsAwardedByTaskID(i) <= 0 then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHIME_TASK, true)

			return true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHIME_TASK, false)

	return false
end

function ActivityChimeData:getItems(id)
	return self.detail.items
end

function ActivityChimeData:checkDayGiftBuyRed()
	for i in pairs(self.detail.charges) do
		local giftBagID = self.detail.charges[i].table_id
		local mailId = xyd.tables.giftBagTable:getMailId(giftBagID)

		if mailId and mailId > 0 then
			if self.detail.charges[i].buy_times > 0 then
				xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHIME_DEFENSE, false)

				return false
			else
				local todayShowDefenseTime = xyd.db.misc:getValue("activity_chime_day_buy_day_giftbag")

				if not todayShowDefenseTime or not xyd.isSameDay(tonumber(todayShowDefenseTime), xyd.getServerTime(), true) then
					xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHIME_DEFENSE, true)

					return true
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_CHIME_DEFENSE, false)

	return false
end

return ActivityChimeData
