local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityCupidGiftData = class("ActivityCupidGiftData", ActivityData, true)

function ActivityCupidGiftData:getUpdateTime()
	if self:haveBuyAnyGift() then
		return self:getEndTime()
	else
		return self:getNowGiftEndTime()
	end
end

function ActivityCupidGiftData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false

		return red
	end

	local lastOpenTime = tonumber(xyd.db.misc:getValue("activity_cupid_gift_openTime"))

	if not lastOpenTime then
		red = true
	end

	if not red then
		local nowTime = xyd.getServerTime()
		local lastWeekDay = self:getTimeWeekDay(lastOpenTime)
		local nowWeekDay = self:getTimeWeekDay(nowTime)

		if nowTime - lastOpenTime > 604800 then
			red = true
		elseif lastWeekDay < 5 and nowWeekDay < 5 or lastWeekDay > 5 and nowWeekDay > 5 then
			red = false
		elseif lastWeekDay < 5 and nowWeekDay > 5 or lastWeekDay > 5 and nowWeekDay < 5 then
			red = true
		elseif lastWeekDay == 5 then
			red = false
		end
	end

	return red
end

function ActivityCupidGiftData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_CUPID_GIFT then
			local detail = nil

			if data and data.detail and data.detail ~= {} and data.detail ~= "" then
				detail = cjson.decode(data.detail)
			else
				detail = {}
			end
		end
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ACTIVITY_CUPID_GIFT then
			return
		end

		self.selectedIndex = nil
		local win = xyd.getWindow("activity_window")

		if win then
			win:setTitleTimeLabel(xyd.ActivityID.ACTIVITY_CUPID_GIFT, self:getUpdateTime() - xyd.getServerTime(), 1)
		end
	end)
end

function ActivityCupidGiftData:reqSummon(num)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_CUPID_GIFT
	msg.params = cjson.encode({
		num = num
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityCupidGiftData:getNowGiftEndTime()
	return self.start_time + 604800
end

function ActivityCupidGiftData:haveBuyAnyGift()
	return self:getMaxHaveBuyGiftIndex() > 0
end

function ActivityCupidGiftData:getMaxHaveBuyGiftIndex()
	local index = 0

	dump(self.detail)

	for i = 1, #self.detail.charges do
		if self.detail.charges[i].buy_times > 0 then
			index = i
		end
	end

	dump(index)

	return index
end

function ActivityCupidGiftData:getCurGiftIndex()
	local index = 0

	if tonumber(xyd.getServerTime()) < self.start_time + 604800 then
		index = self:getMaxHaveBuyGiftIndex() + 1

		if index > 3 then
			index = 0
		end
	end

	return index
end

function ActivityCupidGiftData:getCurGiftBagID()
	return xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_CUPID_GIFT)[self:getCurGiftIndex()] or 0
end

function ActivityCupidGiftData:getCurGiftID()
	local giftID = self:getCurGiftBagID()

	if giftID > 0 then
		return xyd.tables.giftBagTable:getGiftID(giftID)
	end

	return 0
end

function ActivityCupidGiftData:getTimesPerWeek()
	local result = 0
	local index = self:getMaxHaveBuyGiftIndex()

	for i = 1, index do
		result = result + xyd.tables.activityCupidGiftAwardTable:getDrawTimes(self.detail.charges[i].table_id)
	end

	return result
end

function ActivityCupidGiftData:getNowLeftTime()
	local cost = xyd.tables.miscTable:split2Cost("activity_cupid_gift_draw", "value", "#")

	return math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2])
end

function ActivityCupidGiftData:getExp(giftBagID)
	return xyd.tables.giftBagTable:getVipExp(self:getCurGiftBagID())
end

function ActivityCupidGiftData:getChooseAwardIndex()
	local realIndex = self.detail.self_chosen[self:getCurGiftID()]

	if realIndex and self.selectedIndex ~= realIndex then
		self.selectedIndex = realIndex
	end

	local index = self.selectedIndex or 0

	return index
end

function ActivityCupidGiftData:selectSpecialAward(index)
	self.selectedIndex = index
end

function ActivityCupidGiftData:reqSelectSpecialAward()
	local msg = messages_pb.stay_set_attach_index_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_CUPID_GIFT
	msg.index = self.selectedIndex
	msg.giftbag_id = self:getCurGiftBagID()

	xyd.Backend.get():request(xyd.mid.STAY_SET_ATTACH_INDEX, msg)
end

function ActivityCupidGiftData:showRechargeAward(id, items)
	local cost = xyd.tables.miscTable:split2Cost("activity_cupid_gift_draw", "value", "#")
	local realItems = {}
	local award = xyd.tables.activityCupidGiftAwardTable:getAward(id)

	for index, value in ipairs(items) do
		if value.item_id ~= cost[1] then
			table.insert(realItems, value)
		end
	end

	xyd.showRechargeAward(id, realItems)
end

function ActivityCupidGiftData:getTimeWeekDay(time)
	local timeDesc = os.date("!*t", time)
	local weekDay = timeDesc.wday

	if weekDay == 0 then
		weekDay = 7
	end

	return weekDay
end

return ActivityCupidGiftData
