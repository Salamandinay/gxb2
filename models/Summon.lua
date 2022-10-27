local BaseModel = import(".BaseModel")
local Summon = class("Summon", BaseModel)
local SummonTable = xyd.tables.summonTable

function Summon:ctor()
	BaseModel.ctor(self)

	self.skipAnimation = false
	self.loaded = false
	self.timerKey = -1
	local dressSkipAnimation = xyd.db.misc:getValue("dress_skip_animation_state")

	if dressSkipAnimation and tonumber(dressSkipAnimation) == 1 then
		self.dressSkipAnimation = true
	else
		self.dressSkipAnimation = false
	end

	self.fiftySummon = nil
	self.fiftySummonTimes = 0
	self.fiftySummonData = {}
end

function Summon:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_SUMMON_INFO, handler(self, self.onLoadData))
	self:registerEvent(xyd.event.SUMMON, handler(self, self.onSummonEvent))
	self:registerEvent(xyd.event.SUMMON_WISH, handler(self, self.onUpdateData))
	self:registerEvent(xyd.event.GET_DRESS_SUMMON_INFO, handler(self, self.onDressData))
	self:registerEvent(xyd.event.SUMMON_DRESS, handler(self, self.updateDressData))
	self:registerEvent(xyd.event.GET_STARRY_SUMMON_INFO, handler(self, self.onGetStarrySummonInfo))
	self:registerEvent(xyd.event.SET_STARRY_SUMMON_AWARD, handler(self, self.onSetStarrySummonAward))
	self:updateRedPoint()
end

function Summon:updateRedPoint()
	local nowTime = xyd.getServerTime()
	local baseFreeTime = self:getBaseSummonFreeTime()
	local seniorFreeTime = self:getSeniorSummonFreeTime()
	local baseInterval = SummonTable:getFreeTimeInterval(xyd.SummonType.BASE_FREE)
	local seniorInterval = SummonTable:getFreeTimeInterval(xyd.SummonType.SENIOR_FREE)

	if baseFreeTime ~= nil then
		if self.timerKey ~= -1 then
			xyd.removeGlobalTimer(self.timerKey)
		end

		if baseInterval < nowTime - baseFreeTime or seniorInterval < nowTime - seniorFreeTime then
			xyd.models.redMark:setMark(xyd.RedMarkType.SUMMON, true)
		else
			xyd.models.redMark:setMark(xyd.RedMarkType.SUMMON, false)

			local baseTimeDis = baseInterval - (nowTime - baseFreeTime)
			local seniorTimeDis = seniorInterval - (nowTime - seniorFreeTime)
			self.timerKey = xyd.addGlobalTimer(handler(self, self.updateRedPoint), xyd.checkCondition(baseTimeDis < seniorTimeDis, baseTimeDis, seniorTimeDis), 1)
		end
	end
end

function Summon:onLoadData(event)
	local data = event.data

	if data then
		self.baseSummonFreeTime_ = tonumber(data.last_time_3) or 0
		self.seniorSummonFreeTime_ = tonumber(data.last_time_8) or 0
		self.wishSummonFreeTime_ = tonumber(data.last_time_26) or 0
		self.fortyIndex = tonumber(data.forty_index) or 0
		self.loaded = true
		local seniorInterval = xyd.tables.summonTable:getFreeTimeInterval(xyd.SummonType.SENIOR_FREE)

		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.SENIOR_SUMMON, self.seniorSummonFreeTime_ + seniorInterval)
	end

	self:updateRedPoint()
end

function Summon:onDressData(event)
	local data = event.data
	self.summon_times_1_ = data.summon_times_1
	self.summon_times_2_ = data.summon_times_2
end

function Summon:getDressBreakNum()
	return self.summon_times_1_
end

function Summon:getDressLimitBreakNum()
	return self.summon_times_2_
end

function Summon:onSummonEvent(event)
	self:onUpdateData(event)

	local isSummonfifty = self:getFiftySummonStatus()
	local summonIndex = tonumber(event.data.index) or 0

	if isSummonfifty and summonIndex > 0 then
		if summonIndex == 1 then
			self.fiftySummonData = {}
		end

		local partners = event.data.summon_result.partners or {}
		local items = {}

		for i, partner in ipairs(partners) do
			local item_id = partner.table_id
			local star = xyd.tables.partnerTable:getStar(item_id)

			table.insert(items, {
				item_num = 1,
				item_id = item_id,
				partnerId = partner.partner_id
			})
		end

		local params = {
			items = items,
			summonIndex = event.data.index,
			summonId = tonumber(event.data.summon_id) or 0
		}

		table.insert(self.fiftySummonData, params)
	end
end

function Summon:onUpdateData(event)
	local data = event.data.summon_info or {}
	self.baseSummonFreeTime_ = tonumber(data.last_time_3) or 0
	self.seniorSummonFreeTime_ = tonumber(data.last_time_8) or 0
	self.wishSummonFreeTime_ = tonumber(data.last_time_26) or 0
	self.fortyIndex = tonumber(data.forty_index) or 0
	self.loaded = true
	local seniorInterval = xyd.tables.summonTable:getFreeTimeInterval(xyd.SummonType.SENIOR_FREE)

	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.SENIOR_SUMMON, self.seniorSummonFreeTime_ + seniorInterval)
	self:updateRedPoint()
end

function Summon:updateDressData(event)
	local data = event.data
	local summon_id = tonumber(data.summon_id)

	if summon_id == 1 or summon_id == 2 then
		self.summon_times_1_ = data.times
	elseif summon_id == 3 or summon_id == 4 then
		self.summon_times_2_ = data.times
	end

	local type = xyd.tables.summonDressTable:getSummonType(data.summon_id)
	data = xyd.decodeProtoBuf(event.data)

	if type == 3 then
		local params = {}
		local params_key = {}
		local key_arr = {}

		for i, itemData in pairs(data.summon_result.items) do
			if data.transfer[i] == 1 then
				local dressId = xyd.tables.senpaiDressItemTable:getDressId(itemData.item_id)
				local debrisData = xyd.tables.senpaiDressTable:getDressHand(dressId)

				if params_key[debrisData[1]] then
					params_key[debrisData[1]].item_num = params_key[debrisData[1]].item_num + debrisData[2]
				else
					params_key[debrisData[1]] = {
						item_id = debrisData[1],
						item_num = debrisData[2]
					}

					table.insert(key_arr, debrisData[1])
				end
			else
				params_key[itemData.item_id] = {
					item_id = itemData.item_id,
					item_num = itemData.item_num
				}

				table.insert(key_arr, itemData.item_id)
			end
		end

		for i in pairs(key_arr) do
			table.insert(params, params_key[key_arr[i]])
		end

		xyd.WindowManager:get():closeWindow("summon_res_window")

		if #data.summon_result.items > 1 then
			xyd.WindowManager.get():openWindow("alert_heros_window", {
				data = params
			})
		else
			xyd.alertItems(params, nil, __("SUMMON"))
		end
	end

	xyd.models.dress:checkAllItemCanUpEveryDay()
end

function Summon:onGetStarrySummonInfo(event)
	local data = event.data
	self.starrySelects = data.selects
end

function Summon:onSetStarrySummonAward(event)
	local data = event.data
	self.starrySelects = data.selects
end

function Summon:getStarrySelects()
	return self.starrySelects
end

function Summon:getData()
	local msg = {}

	xyd.Backend.get():request(xyd.mid.GET_SUMMON_INFO, msg)
end

function Summon:summonPartner(id, times, index)
	if id == xyd.SummonType.WISH_CRYSTAL or id == xyd.SummonType.WISH_CRYSTAL_TEN or id == xyd.SummonType.WISH_SCROLL or id == xyd.SummonType.WISH_SCROLL_TEN or id == xyd.SummonType.WISH_FREE then
		local msg = messages_pb:summon_wish_req()
		msg.summon_id = id

		if times then
			msg.times = times
		end

		msg.is_jump = self:getSkipAnimation() and 1 or 0

		xyd.Backend.get():request(xyd.mid.SUMMON_WISH, msg)

		return
	end

	local msg = messages_pb:summon_req()
	msg.summon_id = id

	if times then
		msg.times = times
	end

	index = tonumber(index) or 0

	if index then
		msg.index = index
	end

	msg.is_jump = self:getSkipAnimation() and 1 or 0
	local isFifty = self:getFiftySummonStatus()

	if isFifty and index > 0 then
		index = self:setFiftySummonTimes(index)
		msg.is_jump = 1
	end

	xyd.Backend.get():request(xyd.mid.SUMMON, msg)
end

function Summon:getBaseSummonFreeTime()
	return self.baseSummonFreeTime_
end

function Summon:getSeniorSummonFreeTime()
	return self.seniorSummonFreeTime_
end

function Summon:getWishSummonFreeTime()
	return self.wishSummonFreeTime_
end

function Summon:getFortyIndex()
	return self.fortyIndex
end

function Summon:getBaseScrollNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.BASE_SUMMON_SCROLL)
end

function Summon:getSeniorScrollNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.SENIOR_SUMMON_SCROLL)
end

function Summon:getCrystalNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
end

function Summon:getBaodiEnergyNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.BAODI_ENERGY)
end

function Summon:getLimitTenScrollId()
	local summonGiftData = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE)

	if summonGiftData and xyd.getServerTime() < summonGiftData:getEndTime() then
		local costData = SummonTable:getCost(xyd.SummonType.ACT_LIMIT_TEN)

		return costData[1]
	else
		return nil
	end
end

function Summon:getLimitTenScrollNum()
	local itemId = self:getLimitTenScrollId()

	if not itemId then
		return 0
	else
		return xyd.models.backpack:getItemNumByID(itemId)
	end
end

function Summon:getSkipAnimation()
	local val = xyd.db.misc:getValue("set_summon_skip")

	if tonumber(val) == 1 then
		self.skipAnimation = true
	end

	return self.skipAnimation
end

function Summon:setSkipAnimation(flag)
	self.skipAnimation = flag
	local val = 0

	if flag then
		val = 1
	end

	xyd.db.misc:setValue({
		key = "set_summon_skip",
		value = val
	})
end

function Summon:reqDressSummonInfo()
	local msg = messages_pb.get_dress_summon_info_req()

	xyd.Backend.get():request(xyd.mid.GET_DRESS_SUMMON_INFO, msg)
end

function Summon:reqSummonDress(summon_id, num)
	local msg = messages_pb.summon_req()
	msg.summon_id = summon_id
	msg.times = num

	xyd.Backend:get():request(xyd.mid.SUMMON_DRESS, msg)
end

function Summon:reqStarrySummonInfo()
	local msg = messages_pb.get_starry_summon_info_req()

	xyd.Backend:get():request(xyd.mid.GET_STARRY_SUMMON_INFO, msg)
end

function Summon:setStarrySummonAward(summonIds, indexs)
	local msg = messages_pb.set_starry_summon_award_req()

	for i in pairs(summonIds) do
		table.insert(msg.summon_ids, summonIds[i])
	end

	for i in pairs(indexs) do
		table.insert(msg.indexs, indexs[i])
	end

	xyd.Backend:get():request(xyd.mid.SET_STARRY_SUMMON_AWARD, msg)
end

function Summon:starrySummon(summonId, times)
	local msg = messages_pb.starry_summon_req()
	msg.summon_id = summonId
	msg.times = times

	xyd.Backend:get():request(xyd.mid.STARRY_SUMMON, msg)
end

function Summon:reqStarrySummonLog()
	local msg = messages_pb.get_starry_summon_log_res()

	xyd.Backend:get():request(xyd.mid.GET_STARRY_SUMMON_LOG, msg)
end

function Summon:changeDressSkipAnimation()
	if self.dressSkipAnimation == false then
		self.dressSkipAnimation = true
	else
		self.dressSkipAnimation = false
	end

	xyd.db.misc:setValue({
		key = "dress_skip_animation_state",
		value = self.dressSkipAnimation
	})
	print(xyd.db.misc:getValue("dress_skip_animation_state"))
end

function Summon:getDressSkipAnimation()
	print(xyd.db.misc:getValue("dress_skip_animation_state"))
	print(self.dressSkipAnimation)

	return self.dressSkipAnimation
end

function Summon:getFiftySummonStatus()
	if self.fiftySummon == nil then
		local val = xyd.db.misc:getValue("set_fifty_summon")

		if tonumber(val) == 1 then
			self.fiftySummon = true
		end
	end

	return self.fiftySummon
end

function Summon:setFiftySummonStatus(status)
	self.fiftySummon = status
	local val = 0

	if status then
		self.fiftySummonTimes = 0
		val = 1
	end

	xyd.db.misc:setValue({
		key = "set_fifty_summon",
		value = val
	})
end

function Summon:setFiftySummonTimes(num)
	if not num then
		self.fiftySummonTimes = self.fiftySummonTimes + 1
	else
		self.fiftySummonTimes = num
	end

	return self.fiftySummonTimes
end

function Summon:getFiftySummonTimes()
	return self.fiftySummonTimes
end

function Summon:getFiftySummonData(index)
	if index then
		return self.fiftySummonData[index]
	else
		return self.fiftySummonData
	end
end

function Summon:getAutoAltarStatus()
	if self.autoAltarStatus == nil then
		local val = xyd.db.misc:getValue("set_auto_altar")

		if tonumber(val) == 1 then
			self.autoAltarStatus = true
		end
	end

	return self.autoAltarStatus
end

function Summon:setAutoAltarStatus(status)
	self.autoAltarStatus = status
	local val = 0

	if status then
		val = 1
	end

	xyd.db.misc:setValue({
		key = "set_auto_altar",
		value = val
	})
end

return Summon
