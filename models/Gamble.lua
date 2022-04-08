local Gamble = class("Gamble", import(".BaseModel"))

function Gamble:ctor()
	Gamble.super.ctor(self)

	self.data_ = {}
	self.reqTimeList_ = {}
	self.freeRefreshTime_ = {
		[1.0] = 0,
		[2.0] = 0
	}
end

function Gamble:onRegister()
	Gamble.super.onRegister(self)
	self:registerEvent(xyd.event.GAMBLE_GET_INFO, handler(self, self.onGambleInfo))
	self:registerEvent(xyd.event.GAMBLE_GET_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.GAMBLE_REFRESH, handler(self, self.onRefresh))
end

function Gamble:reqGambleInfo(gambleType)
	if self.reqTimeList_[gambleType] then
		return false
	end

	local msg = messages_pb.gamble_get_info_req()
	msg.gamble_type = gambleType
	self.reqTimeList_[gambleType] = xyd.getServerTime()

	xyd.Backend.get():request(xyd.mid.GAMBLE_GET_INFO, msg)

	return true
end

function Gamble:clearGambleByType(gambleType)
	self.data_[gambleType] = nil
	self.reqTimeList_[gambleType] = nil
end

function Gamble:reqRefreshInfo(gambleType)
	local msg = messages_pb.gamble_refresh_req()
	msg.gamble_type = gambleType

	xyd.Backend.get():request(xyd.mid.GAMBLE_REFRESH, msg)
end

function Gamble:reqGetAward(gambleType, index)
	local msg = messages_pb.gamble_get_award_req()
	msg.gamble_type = gambleType
	msg.index = index

	xyd.Backend.get():request(xyd.mid.GAMBLE_GET_AWARD, msg)
end

function Gamble:reqBuyCoin(gambleType, num)
	local msg = messages_pb.gamble_buy_coin_req()
	msg.gamble_type = gambleType
	msg.num = num

	xyd.Backend.get():request(xyd.mid.GAMBLE_BUY_COIN, msg)
end

function Gamble:reqGetRecords(gambleType)
	local msg = messages_pb.gamble_records_req()
	msg.gamble_type = gambleType

	xyd.Backend.get():request(xyd.mid.GAMBLE_RECORDS, msg)
end

function Gamble:onGambleInfo(event)
	local data = {
		items = {}
	}

	for i = 1, #event.data.items do
		local item = {
			item_id = event.data.items[i].item_id,
			item_num = event.data.items[i].item_num,
			buy_limit = event.data.items[i].buy_limit,
			buy_times = event.data.items[i].buy_times,
			weight = event.data.items[i].weight,
			cool = event.data.items[i].cool
		}

		table.insert(data.items, item)
	end

	data.gamble_type = event.data.gamble_type
	data.system_refresh_time = event.data.system_refresh_time
	self.data_[data.gamble_type] = data
	self.freeRefreshTime_[event.data.gamble_type] = event.data.free_refresh_time
end

function Gamble:getData(type)
	return self.data_[type] or nil
end

function Gamble:setData(type, data)
	self.data_[type] = data
end

function Gamble:onRefresh(event)
	local data = {
		items = {}
	}

	for i = 1, #event.data.items do
		local item = {
			item_id = event.data.items[i].item_id,
			item_num = event.data.items[i].item_num,
			buy_limit = event.data.items[i].buy_limit,
			buy_times = event.data.items[i].buy_times,
			weight = event.data.items[i].weight,
			cool = event.data.items[i].cool
		}

		table.insert(data.items, item)
	end

	data.gamble_type = event.data.gamble_type
	data.system_refresh_time = event.data.system_refresh_time
	self.data_[data.gamble_type] = data
	self.reqTimeList_[data.gamble_type] = 0
	self.freeRefreshTime_[event.data.gamble_type] = event.data.free_refresh_time or self.freeRefreshTime_[data.gamble_type]
end

function Gamble:onGetAward(event)
	local result = event.data

	if not result.gamble_type or not self:getData(result.gamble_type) then
		return
	end

	local items = self:getData(result.gamble_type).items
	self.reqTimeList_[result.gamble_type] = 0

	for _, itemid in ipairs(result.awards) do
		items[itemid].buy_times = items[itemid].buy_times + 1

		if result.gamble_type == 1 and xyd.tables.itemTable:getType(items[itemid].item_id) == xyd.ItemType.HERO_DEBRIS then
			local cost = xyd.tables.itemTable:partnerCost(items[itemid].item_id)

			if cost[1] == 50 then
				xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.GET_STAR5_HERO_IN_GAMBLE, 1)
			end
		end
	end
end

function Gamble:getSystemTime(type)
	return self:getData(type).system_refresh_time or 0
end

function Gamble:isFreeRefresh(type)
	local freeTime = xyd.tables.gambleConfigTable:getFreeTime(type)

	return freeTime <= xyd.getServerTime() - self.freeRefreshTime_[type]
end

function Gamble:getItems(type)
	if not self:getData(type) then
		return {}
	end

	return self:getData(type).items or {}
end

function Gamble:getItem(type, idx)
	return self:getItems(type)[idx] or {}
end

function Gamble:getAwards(type, awards)
	if not type or not self:getData(type) then
		return {}
	end

	local items = self:getData(type).items or {}
	local tmpItems = {}

	for _, id in ipairs(awards) do
		table.insert(tmpItems, items[id])
	end

	return tmpItems
end

return Gamble
