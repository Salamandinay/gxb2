local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local Activity4BirthdayPartyData = class("Activity4BirthdayPartyData", ActivityData, true)

function Activity4BirthdayPartyData:getUpdateTime()
	return self:getEndTime()
end

function Activity4BirthdayPartyData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false

		return red
	end

	if not red and self:isFirstRedMark() then
		red = true
	end

	if self:checkRedMarkOfParty() then
		red = true
	end

	return red
end

function Activity4BirthdayPartyData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY then
			local detail = nil

			if data and data.detail and data.detail ~= {} and data.detail ~= "" then
				detail = cjson.decode(data.detail)
			else
				detail = {
					type = 3
				}
			end

			local type = detail.type

			if type == 1 or type == 2 then
				self.detail["awards" .. type] = self.detail["awards" .. type] + self.tempReqUseTime
				self.tempReqUseTime = 0
			elseif type == 3 then
				if not self.detail.buy_times[self.tempShopAwardID] then
					self.detail.buy_times[self.tempShopAwardID] = 0
				end

				self.detail.buy_times[self.tempShopAwardID] = self.detail.buy_times[self.tempShopAwardID] + self.tempShopAwardTime
			elseif type == 4 then
				self.detail.big_award = 1
			elseif type == 5 then
				table.insert(self.detail.plots, detail.table_id)
			end

			self:getRedMarkState()
		end
	end)
end

function Activity4BirthdayPartyData:getResource1()
	local data = xyd.tables.miscTable:split2Cost("activity_4birthday_cost", "value", "#")

	return data
end

function Activity4BirthdayPartyData:checkRedMarkOfParty()
	local red = false

	if self:checkRedMarkOfPartyBtnUse(1) or self:checkRedMarkOfPartyBtnUse(2) then
		red = true
	end

	if not red and self:checkRedMarkOfPartyStory() then
		red = true
	end

	if not red and self:checkRedMarkOfPartySpecialAward() then
		red = true
	end

	if not red and self:checkRedMarkOfPartyBuy() then
		red = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_PARTY, red)

	return red
end

function Activity4BirthdayPartyData:checkRedMarkOfPartyBtnUse(type)
	local cost = self:getResource1()

	if self:getPartyPoint(type) < self:getPartyNeedPoint(type) and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		return true
	end

	return false
end

function Activity4BirthdayPartyData:checkRedMarkOfPartyStory()
	local ids = xyd.tables.activity4birthdayStoryTable:getIDs()

	for i = 1, #ids do
		if self:getStoryState(i) == 2 then
			return true
		end
	end

	return false
end

function Activity4BirthdayPartyData:checkRedMarkOfPartySpecialAward()
	return self:checkPartySpecialAwardCanGet()
end

function Activity4BirthdayPartyData:checkRedMarkOfPartyBuy()
	if self:checkPartySpecialAwardHaveGot() then
		local ids = xyd.tables.activity4birthdayShopTable:getIDs()

		for i = 1, #ids do
			local id = ids[i]
			local limit = xyd.tables.activity4birthdayShopTable:getLimit(id)
			local cost = xyd.tables.activity4birthdayShopTable:getCost(id)
			local buyTime = self:getPartyShopBuyTimes(id)
			local leftTime = limit - buyTime

			if leftTime > 0 and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				return true
			end
		end
	end

	return false
end

function Activity4BirthdayPartyData:getPartyDatas(type)
	local datas = {}
	local ids = xyd.tables.activity4birthdayAwardTable:getIDsByType(type)

	for i = 1, #ids do
		local id = ids[i]
		local data = {
			id = id,
			type = type
		}

		table.insert(datas, data)
	end

	return datas
end

function Activity4BirthdayPartyData:haveGotPartyAward(id)
	local type = xyd.tables.activity4birthdayAwardTable:getType(id)
	local needPoint = xyd.tables.activity4birthdayAwardTable:getPoint(id)

	return needPoint <= self.detail["awards" .. type]
end

function Activity4BirthdayPartyData:getPartyPoint(type)
	return self.detail["awards" .. type]
end

function Activity4BirthdayPartyData:getPartyAllPoint()
	return self:getPartyPoint(1) + self:getPartyPoint(2)
end

function Activity4BirthdayPartyData:getPartyNeedPoint(type)
	local value = xyd.tables.miscTable:split2Cost("activity_4birthday_award_num", "value", "|")

	if value and value[type] then
		return value[type]
	end

	return 0
end

function Activity4BirthdayPartyData:checkPartySpecialAwardHaveGot()
	return self.detail.big_award > 0
end

function Activity4BirthdayPartyData:checkPartySpecialAwardCanGet()
	if self:checkPartySpecialAwardHaveGot() then
		return false
	end

	local nowPoint = self:getPartyAllPoint()
	local need = self:getPartyNeedPoint(1) + self:getPartyNeedPoint(2)

	return nowPoint >= need
end

function Activity4BirthdayPartyData:getPartyShopDatas(type)
	local datas = {}
	local ids = xyd.tables.activity4birthdayShopTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local data = {
			id = id
		}

		table.insert(datas, data)
	end

	return datas
end

function Activity4BirthdayPartyData:reqBuyPartyShopItem(tableID, num)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY
	msg.params = cjson.encode({
		type = 3,
		award_id = tableID,
		num = num
	})
	self.tempShopAwardID = tableID
	self.tempShopAwardTime = num

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function Activity4BirthdayPartyData:reqPartySpecialAward()
	if not self:checkPartySpecialAwardCanGet() then
		return
	end

	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY
	msg.params = cjson.encode({
		type = 4
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function Activity4BirthdayPartyData:getPartyShopBuyTimes(tableID)
	local buyTime = self.detail.buy_times[tableID] or 0

	return buyTime
end

function Activity4BirthdayPartyData:reqPartyAward(type, time)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY
	msg.params = cjson.encode({
		type = type,
		num = time
	})
	self.tempReqUseTime = time

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function Activity4BirthdayPartyData:getStoryState(id)
	local haveRead = false

	for key, value in pairs(self.detail.plots) do
		if tonumber(value) == id then
			haveRead = true
		end
	end

	if haveRead then
		return 3
	else
		local needTime = self.start_time + (id - 1) * 24 * 60 * 60

		if needTime <= xyd.getServerTime() then
			return 2
		else
			return 1
		end
	end
end

function Activity4BirthdayPartyData:readPartyStory(id)
	if self:getStoryState(id) == 2 then
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_4BIRTHDAY_PARTY
		msg.params = cjson.encode({
			type = 5,
			table_id = id
		})

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	end
end

return Activity4BirthdayPartyData
