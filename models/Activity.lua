local BaseModel = import(".BaseModel")
local Activity = class("Activity", BaseModel)
local ActivityTable = xyd.tables.activityTable
local ModelClass, TableClass = unpack(require("app.models.ActivityDatas"))
local json = require("cjson")

function Activity:ctor()
	BaseModel.ctor(self)

	self.activityList = {}
	self.limitRedCount = 0
	self.coolRedCount = 0
	self.pushLimitGiftParams = {}
	self.red_mark_init_flag_ = false
	self.plot_list_ = {}
	self.plot_ids_ = {}
	self.win_list_ = {}
	self.flagFunction = {
		[xyd.ActivityID.NEWBIE_CAMP] = self.isNewBieCampOpen,
		[xyd.ActivityID.ONLINE_AWARD] = self.isOnlineAwardOpen,
		[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = self.isBindAccountOpen
	}
	self.eventsRedCount = {}
	self.eventTypes = {
		xyd.EventType.COOL,
		xyd.EventType.LIMIT,
		xyd.EventType.NEWBIE
	}
	self.redMarkTypes = {
		xyd.RedMarkType.COOL_EVENT,
		xyd.RedMarkType.LIMIT_EVENT,
		xyd.RedMarkType.NEWBIE_GUIDE
	}
	self.vote_req_time = {
		[xyd.ActivityID.ACTIVITY_VOTE] = -1,
		[xyd.ActivityID.ACTIVITY_VOTE2] = -1
	}
end

function Activity.get()
	if Activity.INSTANCE == nil then
		Activity.INSTANCE = Activity.new()

		Activity.INSTANCE:onRegister()
	end

	return Activity.INSTANCE
end

function Activity:reset()
	if Activity.INSTANCE then
		Activity.INSTANCE:removeEvents()
	end

	Activity.INSTANCE = nil
end

function Activity:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_LIST, self.onActivityList, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, self.onAward, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, self.onActivityByID, self)
	self:registerEvent(xyd.event.RECHARGE, self.onRecharge, self)
	self:registerEvent(xyd.event.SYSTEM_REFRESH, self.systemRefresh, self)
	self:registerEvent(xyd.event.LIMIT_GIFT, self.onLimitGift, self)
	self:registerEvent(xyd.event.UNLOCK_SCHOOL_GIFT_BOX, self.onUnlockSchoolGiftBox, self)
	self:registerEvent(xyd.event.EXCHANGE_SCHOOL_GIFT, self.onExchangeSchoolGiftBox, self)
	self:registerEvent(xyd.event.RED_POINT, self.onRedPoint, self)
	self:registerEvent(xyd.event.ACTIVITY_BUY_MUSIC, self.onMusicBuy, self)
	self:registerEvent(xyd.event.GET_ACTIVITY_PLOT, self.onActivityPlot, self)
	self:registerEvent(xyd.event.NEW_PARTNER_WARMUP_FIGHT, self.onNewPartnerWarmUpFight, self)
	self:registerEvent(xyd.event.LEV_CHANGE, self.levChange, self)
end

function Activity:onLimitGift(event)
	local giftbag_id = event.data.giftbag_id
	local activity_id = event.data.activity_id

	table.insert(self.pushLimitGiftParams, {
		giftbag_id = giftbag_id,
		activity_id = activity_id
	})

	if (activity_id == xyd.ActivityID.FOUR_STAR_GIFT or activity_id == xyd.ActivityID.FIVE_STAR_GIFT) and xyd.models.backpack:getLev() > 60 then
		return
	end

	if not DEBUG and xyd.GuideController.get():isPlayGuide() or xyd.WindowManager.get():getWindow("summon_window") then
		return
	end

	if activity_id == 174 then
		return
	end

	self:reqPushActivityInfo(event.data)
end

function Activity:loadTable(callback)
	callback()
end

function Activity:getLimitGiftParams()
	return self.pushLimitGiftParams
end

function Activity:removeLimitGiftParams(giftbagID)
	for index, data in ipairs(self.pushLimitGiftParams) do
		if data.giftbag_id == giftbagID then
			table.remove(self.pushLimitGiftParams, index)
		end
	end
end

function Activity:systemRefresh()
	self:reqActivityList()
end

function Activity:reqAward(id)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = id

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function Activity:reqAwardWithParams(id, params)
	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = id
	msg.params = params

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function Activity:reqActivityList()
	local msg = messages_pb:get_activity_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_LIST, msg)
end

function Activity:reqActivityByID(id)
	local msg = messages_pb:get_activity_info_by_id_req()
	msg.activity_id = id

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
end

function Activity:onGuideComplete()
	self:reqActivityList()
end

function Activity:onActivityList(event)
	local list = event.data.activity_list

	if UNITY_EDITOR then
		local a = xyd.decodeProtoBuf(event.data)

		dump(a, "查看全部活动数据。。。。。。。。")

		for i, v in pairs(a.activity_list) do
			if tonumber(v.activity_id) == 328 then
				dump(v, "328===========================")
			end
		end

		list = a.activity_list
	end

	if not list then
		return
	end

	for id, data in pairs(self.activityList) do
		if data and tonumber(id) ~= xyd.ActivityID.ACTIVITY_VOTE and tonumber(id) ~= xyd.ActivityID.ACTIVITY_VOTE2 then
			self.activityList[id].valid = false
		end
	end

	local needLoad = {}
	local isReturnBack = false

	for i, data in ipairs(list) do
		local id = data.activity_id

		if xyd.GuideController.get():isGuideComplete() or data.activity_id == xyd.ActivityID.CHECKIN or xyd.tables.activityTable:getType(data.activity_id) ~= xyd.EventType.LIMIT then
			if id == xyd.ActivityID.ACTIVITY_VOT or id == xyd.ActivityID.ACTIVITY_VOTE2 then
				if self.vote_req_time[id] == -1 or tonumber(self.vote_req_time[id]) < xyd.getServerTime() - 3600 then
					self:setActivityData(data)

					self.vote_req_time[id] = xyd.getServerTime()
				else
					local cur_rank = self.activityList[id].detail.rank_list

					self:setActivityData(data)

					self.activityList[id].detail.rank_list = cur_rank
				end
			elseif id == xyd.ActivityID.RETURN then
				local returnData = json.decode(data.detail)

				if returnData.role == xyd.PlayerReturnType.ACTIVE or returnData.role == xyd.PlayerReturnType.RETURN then
					self:setActivityData(data)

					if returnData.role == xyd.PlayerReturnType.RETURN then
						isReturnBack = true
					end
				end
			elseif id == xyd.ActivityID.HOT_POINT_PARTNER or id == xyd.ActivityID.DISCOUNT_MONTHLY then
				if isReturnBack == true then
					self:setActivityData(data)
				end
			elseif id == xyd.ActivityID.ACTIVITY_CUPID_GIFT then
				local detail = json.decode(data.detail)
				local index = 0

				for i = 1, #detail.charges do
					if detail.charges[i].buy_times > 0 then
						index = i
					end
				end

				if index > 0 or xyd.getServerTime() <= tonumber(data.start_time) + 604800 then
					self:setActivityData(data)
				end
			elseif id == xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION or id == xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION2 then
				if xyd.checkFunctionOpen(xyd.FunctionID.GALAXY_TRIP, true) == true then
					self:setActivityData(data)
				end
			else
				self:setActivityData(data)
			end

			if id == xyd.ActivityID.LAFULI_DRIFT and not self.activityList[xyd.ActivityID.COLLECT_CORAL_BRANCH] then
				self.activityList[xyd.ActivityID.COLLECT_CORAL_BRANCH] = ModelClass[xyd.ActivityID.COLLECT_CORAL_BRANCH].new(data)
			end
		end
	end

	self.activityList[xyd.ActivityID.ONLINE_AWARD] = ModelClass[xyd.ActivityID.ONLINE_AWARD].new()
	self.activityList[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = ModelClass[xyd.ActivityID.BIND_ACCOUNT_ENTRY].new()
	self.activityList[xyd.ActivityID.NEWBIE_CAMP] = ModelClass[xyd.ActivityID.NEWBIE_CAMP].new()

	self:updateAddtionFunc()
	self:setRedMarkState()

	local mainWindow = xyd.WindowManager.get():getWindow("main_window")

	if mainWindow then
		mainWindow:CheckExtraActBtn()
		mainWindow:CheckScrollerUpdateLargeActBtn()
	end
end

function Activity:isNewBieCampOpen()
	if xyd.isIosTest() then
		return false
	end

	local timeStamps = xyd.tables.miscTable:split("old_rookie_ddl", "value", "|")

	if tonumber(timeStamps[2]) < xyd.models.selfPlayer:getCreatedTime() or tonumber(timeStamps[1]) < xyd.getServerTime() then
		return false
	end

	local award_list = xyd.models.newbieCamp:getAwardInfo()

	for i = 1, 3 do
		local ids = xyd.tables.newbieCampTable:getIdsByPhase(i)

		for j, id in ipairs(ids) do
			if award_list[id] == nil then
				return true
			end
		end
	end

	return false
end

function Activity:isOnlineAwardOpen()
	local onlineInfo = xyd.models.selfPlayer:getOnlineInfo()

	if onlineInfo ~= nil and onlineInfo.id > 0 then
		return true
	end

	return false
end

function Activity:isBindAccountOpen()
	if xyd.isIosTest() then
		return false
	end

	local status = xyd.models.achievement:checkBindAccount()

	if status == 2 then
		return false
	end

	return true
end

function Activity:updateRedMarkCount(id, updateFunc)
	local function updateRedMarkState()
		local redmark0 = self.activityList[id] and self.activityList[id]:getRedMarkState()

		updateFunc()

		local redmark1 = self.activityList[id] and self.activityList[id]:getRedMarkState()
		local type = xyd.tables.activityTable:getType(id)

		if self.eventsRedCount == nil or self.eventsRedCount[type] == nil then
			return
		end

		local value = 0

		if redmark0 and not redmark1 then
			value = value - 1
		elseif not redmark0 and redmark1 then
			value = value + 1
		end

		self.eventsRedCount[type] = self.eventsRedCount[type] + value
		local win = xyd.WindowManager.get():getWindow("activity_window")

		if win and win.activityType == type then
			win:updateRedMark(id, value)
		end
	end

	updateRedMarkState()

	local win = xyd.WindowManager.get():getWindow("activity_window")

	if win then
		win:updateTitleRedMark(id)
	end

	if next(self.eventsRedCount) then
		for i, v in pairs(self.eventTypes) do
			local type = self.eventTypes[i]

			xyd.models.redMark:setMark(self.redMarkTypes[i], self.eventsRedCount[type] > 0)
		end
	end
end

function Activity:onAward(event)
	local id = event.data.activity_id

	if not self.activityList[id] then
		return
	end

	local needLoad = TableClass[id] and TableClass[id]() or {}

	self:downloadAssets("activity_table_" .. id, needLoad, function (success)
		local redmark0 = self.activityList[id]:getRedMarkState()

		self.activityList[id]:onAward(event.data)

		local redmark1 = self.activityList[id]:getRedMarkState()

		if redmark0 and not redmark1 then
			if ActivityTable:getType(id) == xyd.EventType.COOL then
				self.coolRedCount = self.coolRedCount - 1
			else
				self.limitRedCount = self.limitRedCount - 1
			end
		elseif not redmark0 and redmark1 then
			if ActivityTable:getType(id) == xyd.EventType.COOL then
				self.coolRedCount = self.coolRedCount + 1
			else
				self.limitRedCount = self.limitRedCount + 1
			end
		end

		self:setRedMarkState()
	end)

	if id == xyd.ActivityID.WISH_CAPSULE then
		local data = json.decode(event.data.detail)
		local info = data.info
		local wishData = self:getActivity(id)

		if wishData then
			wishData:selectIndex(data)
		end
	end
end

function Activity:updateActivityInfo(activityID, data)
	local id = activityID

	if not self.activityList[id] then
		return
	end

	local redmark0 = self.activityList[id]:getRedMarkState()

	self.activityList[id]:updateInfo(data)

	local redmark1 = self.activityList[id]:getRedMarkState()

	if redmark0 and not redmark1 then
		if ActivityTable:getType(id) == xyd.EventType.COOL then
			self.coolRedCount = self.coolRedCount - 1
		else
			self.limitRedCount = self.limitRedCount - 1
		end
	elseif not redmark0 and redmark1 then
		if ActivityTable:getType(id) == xyd.EventType.COOL then
			self.coolRedCount = self.coolRedCount + 1
		else
			self.limitRedCount = self.limitRedCount + 1
		end
	end

	self:setRedMarkState()
end

function Activity:onActivityByID(event)
	local id = event.data.act_info.activity_id

	if id == xyd.ActivityID.TULIN_GROWUP_GIFTBAG then
		xyd.GiftbagPushController.get():checkGropupRechargePop()
	end

	local redmark0 = false

	if self.activityList[id] and self.activityList[id]:getRedMarkState() then
		redmark0 = true
	end

	self:setActivityData(event.data.act_info)

	if not self.activityList[id] then
		return
	end

	local needLoad = TableClass[id] and TableClass[id]() or {}

	self:downloadAssets("activity_" .. id, needLoad, function ()
		local redmark1 = self.activityList[id]:getRedMarkState()

		if redmark0 and not redmark1 then
			if ActivityTable:getType(id) == xyd.EventType.COOL then
				self.coolRedCount = self.coolRedCount - 1
			else
				self.limitRedCount = self.limitRedCount - 1
			end
		elseif not redmark0 and redmark1 then
			if ActivityTable:getType(id) == xyd.EventType.COOL then
				self.coolRedCount = self.coolRedCount + 1
			else
				self.limitRedCount = self.limitRedCount + 1
			end
		end

		self:setRedMarkState()
	end)

	local wnd = xyd.WindowManager.get():getWindow("main_window")

	if wnd then
		wnd:CheckExtraActBtn()
	end
end

function Activity:getActivity(id)
	return self.activityList[id]
end

function Activity:isOpen(id)
	local data = self:getActivity(id)

	if not data then
		return false
	end

	return data:isOpen()
end

function Activity:setActivityData(data)
	local id = data.activity_id

	if not ModelClass[id] then
		return
	end

	if not self.activityList[id] then
		self.activityList[id] = ModelClass[id].new(data)
	else
		self.activityList[id]:setData(data)
	end
end

function Activity:updateAddtionFunc()
	self.activityList[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = nil

	if self:isBindAccountOpen() then
		self.activityList[xyd.ActivityID.BIND_ACCOUNT_ENTRY] = ModelClass[xyd.ActivityID.BIND_ACCOUNT_ENTRY].new()
	end

	self.activityList[xyd.ActivityID.ONLINE_AWARD] = nil

	if self:isOnlineAwardOpen() then
		self.activityList[xyd.ActivityID.ONLINE_AWARD] = ModelClass[xyd.ActivityID.ONLINE_AWARD].new()
	end

	self.activityList[xyd.ActivityID.NEWBIE_CAMP] = nil

	if self:isNewBieCampOpen() then
		self.activityList[xyd.ActivityID.NEWBIE_CAMP] = ModelClass[xyd.ActivityID.NEWBIE_CAMP].new()
	end
end

function Activity:setRedMarkState()
	for i, type in pairs(self.eventTypes) do
		self.eventsRedCount[type] = 0
	end

	for i in pairs(self.activityList) do
		local data = self.activityList[i]

		if data ~= nil then
			local id = data.id or data.activity_id

			if data:getRedMarkState() then
				local type = xyd.tables.activityTable:getType(id)

				if self.eventsRedCount[type] ~= nil then
					self.eventsRedCount[type] = self.eventsRedCount[type] + 1
				end
			end
		end
	end

	for i in pairs(self.eventTypes) do
		local type = self.eventTypes[i]

		xyd.models.redMark:setMark(self.redMarkTypes[i], self.eventsRedCount[type] > 0)
	end
end

function Activity:setDefaultRedMark()
	if xyd.models.achievement:checkBindAccount() == 1 then
		xyd.models.redMark:setMark(xyd.RedMarkType.COOL_EVENT, true)
	elseif xyd.models.achievement:checkBindAccount() == 2 then
		if self.red_mark_init_flag_ == false then
			xyd.models.redMark:setMark(xyd.RedMarkType.COOL_EVENT, true)

			self.red_mark_init_flag_ = true
		end
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.COOL_EVENT, false)
	end

	if self.eventsRedCount[xyd.EventType.LIMIT] and tonumber(self.eventsRedCount[xyd.EventType.LIMIT]) then
		xyd.models.redMark:setMark(self.redMarkTypes[2], self.eventsRedCount[xyd.EventType.LIMIT] > 0)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.LIMIT_EVENT, true)
	end
end

function Activity:onRecharge(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local flag = false
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) == xyd.ActivityID.NEW_LIMIT_FIVE_STAR_GIFTBAG then
		-- Nothing
	end

	for i = 1, #event.data.items do
		local item = event.data.items[i]

		if item.item_id ~= xyd.ItemID.VIP_EXP then
			flag = true

			break
		end
	end

	if xyd.WindowManager.get():getWindow("vip_window") then
		flag = false
	end

	dump(event.data.items)

	if flag then
		local activityID = xyd.tables.giftBagTable:getActivityID(giftBagID)

		if activityID == xyd.ActivityID.ACTIVITY_CUPID_GIFT or activityID == xyd.ActivityID.ACTIVITY_SAND_GIFTBAG then
			local activityData = self:getActivity(activityID)

			activityData:showRechargeAward(event.data.giftbag_id, event.data.items)
		else
			xyd.showRechargeAward(event.data.giftbag_id, event.data.items)
		end
	end

	local activityID = xyd.tables.giftBagTable:getActivityID(giftBagID)

	if activityID ~= xyd.ActivityID.RECHARGE and self:getActivity(activityID) then
		local activityData = self:getActivity(activityID)

		activityData:onAward(giftBagID)

		if activityID == xyd.ActivityID.DISCOUNT_MONTHLY then
			self:getActivity(xyd.ActivityID.MONTH_CARD):onAward(xyd.GIFTBAG_ID.MONTH_CARD)
		end
	end

	local rechargeData = self:getActivity(xyd.ActivityID.RECHARGE)
	local rechargeID = event.data.giftbag_id

	if rechargeID == xyd.GIFTBAG_ID.DISCOUNT_MONTHLY then
		rechargeID = xyd.GIFTBAG_ID.MONTH_CARD
	end

	if rechargeData then
		rechargeData:onAward(rechargeID)
	end

	local firstFechargeData = self:getActivity(xyd.ActivityID.FIRST_RECHARGE)

	if firstFechargeData then
		firstFechargeData:onRecharge()
		self:setRedMarkState()
	end

	local newFirstFechargeData = self:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)

	if newFirstFechargeData then
		newFirstFechargeData:onRecharge()
		self:setRedMarkState()
	end

	if xyd.Global.lang == "ja_jp" and xyd.models.selfPlayer:isShouChongDisplayed() == false then
		xyd.WindowManager.get():openWindow("first_recharge_tips_window")
	end

	self:trackAction("110", "1", "RECHARGE", giftBagID)
end

function Activity:trackAction(type, action, position, ...)
	local event = {
		tostring(xyd.getServerTime() * 1000),
		type,
		action,
		position
	}
	local arg = {
		...
	}

	for _, value in ipairs(arg) do
		table.insert(event, tostring(value))
	end

	local str = json.encode({
		event
	})

	xyd.SdkManager.get():logEvent(str)
end

function Activity:getActivityList()
	return self.activityList
end

function Activity:getActivityListByType(activityType)
	local list = {}

	for id, activityData in pairs(self.activityList) do
		local idType = ActivityTable:getType(id)

		if idType == activityType then
			table.insert(list, activityData)
		end
	end

	return list
end

function Activity:isManaCardPurchased()
	local activityData = self:getActivity(xyd.ActivityID.SUBSCRIPTION)

	return activityData and not not activityData:isPurchased()
end

function Activity:fightBoss(activity_id, boss_type, partners, petID)
	local msg = messages_pb:boss_fight_req()
	msg.activity_id = activity_id
	msg.boss_type = boss_type

	for _, v in pairs(partners) do
		table.insert(msg.partners, self:addMsgPartners(v))
	end

	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.BOSS_FIGHT, msg)
end

function Activity:sweepBoss(activity_id, boss_type, partners, num, petID)
	local msg = messages_pb:boss_sweep_req()
	msg.activity_id = activity_id
	msg.boss_type = boss_type

	for _, v in pairs(partners) do
		table.insert(msg.partners, self:addMsgPartners(v))
	end

	msg.num = num
	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.BOSS_SWEEP, msg)
end

function Activity:fightBossNew(activity_id, partners, petID, times, isSweep)
	local msg = messages_pb:boss_new_fight_req()
	msg.activity_id = xyd.ActivityID.MONTHLY_HIKE
	msg.times = times

	for _, v in pairs(partners) do
		table.insert(msg.partners, self:addMsgPartners(v))
	end

	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.BOSS_NEW_FIGHT, msg)

	if isSweep then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)
		activityData.detail.isSweep = true

		activityData:setTempSweepInfo({
			isSweep = true,
			partners = partners,
			petID = petID,
			times = times
		})
	end
end

function Activity:addMsgPartners(info)
	local PartnersMsg = messages_pb:partners_info()
	PartnersMsg.partner_id = info.partner_id
	PartnersMsg.pos = info.pos

	return PartnersMsg
end

function Activity:sweepBossNew(stage_id, times, isSweep)
	local params = json.encode({
		stage_id = tonumber(stage_id),
		times = times
	})
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.MONTHLY_HIKE)

	if isSweep then
		activityData.detail.needFakeBattle = false
	else
		activityData.detail.needFakeBattle = true
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.MONTHLY_HIKE, params)
end

function Activity:reqRankData()
	xyd.Backend.get():request(xyd.mid.BOSS_GET_RANK, {
		activity_id = xyd.ActivityID.ACTIVITY_WORLD_BOSS
	})
end

function Activity:reqActivityPlot()
	local msg = messages_pb.get_activity_plot_req()

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_PLOT, msg)
end

function Activity:onUnlockSchoolGiftBox(evt)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG, function ()
		local data = self.activityList[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG]

		if data then
			data.detail.box_lock_status = evt.data.box_lock_status
		end

		data:getRedMarkState()
	end)
end

function Activity:onExchangeSchoolGiftBox(evt)
	local data = self.activityList[xyd.ActivityID.ACTIVITY_SCHOOL_GIFTBAG]

	if data then
		local detail = require("cjson").decode(evt.data.detail)
		data.detail.exchange_status = detail.exchange_status

		xyd.itemFloat(detail.items, nil, , 4005)
	end
end

function Activity:onMusicBuy(event)
	local data = self.activityList[xyd.ActivityID.ACTIVITY_CONCERT]

	if data then
		local event_data = event.data

		for i = 1, #data.detail.music_list do
			local music_info = data.detail.music_list[i]

			if music_info.id == event_data.music_id then
				data.detail.music_list[i].is_lock = 0

				return
			end
		end
	end
end

function Activity:onActivityPlot(event)
	local data = event.data
	self.plot_list_ = {}

	for i = 1, #data.plot_ids do
		self.plot_list_[data.plot_ids[i]] = 1
	end

	self.plot_ids_ = data.plot_ids
end

function Activity:checkPlot(id)
	if self.plot_list_[id] then
		return true
	end

	return false
end

function Activity:getPlotIds()
	return self.plot_ids_
end

function Activity:onRedPoint(evt)
	if evt.data.function_id == xyd.ActivityID.ACTIVITY_LAFULI_CASTLE then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LAFULI_CASTLE)

		if not activityData:getRedMarkState() then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_LAFULI_CASTLE)
		end

		return
	end

	if evt.data.function_id ~= xyd.FunctionID.ACTIVITY then
		return
	end

	local activity_id = evt.data.value

	if activity_id then
		local data = self.activityList[activity_id]

		if data then
			if activity_id == xyd.ActivityID.ACTIVITY_MUSIC_JIGSAW then
				Activity.get():reqActivityByID(xyd.ActivityID.ACTIVITY_MUSIC_JIGSAW)
			else
				data:setDefRedMark(true)
			end
		end
	end
end

function Activity:updateRedMark()
	self:setRedMarkState()
end

function Activity:equipGacha(index)
	local cost = xyd.models.miscTable:split2Cost("activity_equip_gacha_cost_all", "value", "|#")
	local cost1 = cost[1]
	local cost10 = cost[2]
	local num = 0

	if index == 1 then
		num = cost1[2]
	else
		num = cost10[2]
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.EQUIP_GACHA) < num then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.EQUIP_GACHA)))

		return
	end

	local data = require("cjson").encode({
		award_id = index
	})
	local param = {
		activity_id = xyd.ActivityID.EQUIP_GACHA,
		params = data
	}

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, param)
end

function Activity:downloadAssets(name, needLoad, callback)
	if not needLoad or next(needLoad) == nil then
		callback()

		return
	end

	if xyd.isAllPathLoad(needLoad) then
		callback()

		return
	end

	ResCache.DownloadAssets(name, needLoad, function (success)
		callback()
	end, nil)
end

function Activity:ifActivityPushGiftBag(id)
	return table.indexof(self:getPushActivity(), id) ~= false
end

function Activity:getIceSecretTime()
	for _, data in pairs(self.activityList) do
		if data.id == xyd.ActivityID.ICE_SECRET then
			local endTime = data:getUpdateTime()

			if endTime and xyd.getServerTime() < endTime then
				return endTime - xyd.getServerTime()
			end
		end
	end

	return -1
end

function Activity:getPushActivity()
	local result = {}

	for _, data in pairs(self.activityList) do
		if data and data.detail then
			local detail = data.detail

			if detail then
				if detail[1] then
					detail = detail[1]
					local charge = detail.charge
					local giftbagID = nil

					if charge then
						giftbagID = charge.table_id
					end

					if giftbagID then
						local check = xyd.tables.giftBagTable:getParamVIP(giftbagID)

						if check ~= "" then
							table.insert(result, data.id)
						end
					end
				else
					local giftbagID = detail.table_id

					if giftbagID then
						local check = xyd.tables.giftBagTable:getParamVIP(giftbagID)

						if check ~= "" then
							table.insert(result, data.id)
						end
					end
				end
			end
		end
	end

	return result
end

function Activity:getLeastPushTime()
	local result = -1
	local ids = self:getPushActivity()

	for _, id in ipairs(ids) do
		local data = self:getActivity(id)
		local detail = data.detail

		if detail then
			if detail[1] then
				for i = 1, #detail do
					local giftbagID = detail[i].charge.table_id
					local time = detail[i].update_time + xyd.tables.giftBagTable:getLastTime(giftbagID) - xyd.getServerTime()

					if time > 0 then
						if result == -1 then
							result = time
						else
							result = math.min(result, time)
						end
					end
				end
			else
				local giftBagID = detail.table_id
				local time = detail.update_time + xyd.tables.giftBagTable:getLastTime(giftBagID) - xyd.getServerTime()

				if time > 0 then
					if result == -1 then
						result = time
					else
						result = math.min(result, time)
					end
				end
			end
		end
	end

	return result
end

function Activity:updateFuncEntry(id)
	local flag = self.flagFunction[id]()

	if flag and self.activityList[id] == nil then
		self.activityList[id] = ModelClass[id].new()
	end

	if flag == false then
		self.activityList[id] = nil
	end
end

function Activity:reqPushActivityInfo(data)
	if data == nil or data.activity_id == nil then
		data = nil

		return
	end

	local type = xyd.tables.activityTable:getType(data.activity_id)

	if type == xyd.EventType.COOL then
		self:reqActivityList()

		return
	end

	self:reqActivityByID(data.activity_id)
end

function Activity:getBattlePassData()
	local data = self:getActivity(xyd.ActivityID.BATTLE_PASS)
	data = data or self:getActivity(xyd.ActivityID.BATTLE_PASS_2)

	return data
end

function Activity:getBattlePassTable(tableType)
	if tableType == xyd.BATTLE_PASS_TABLE.MAIN then
		if self:getBattlePassId() == xyd.ActivityID.BATTLE_PASS_2 then
			return xyd.tables.battlePass2Table
		else
			return xyd.tables.battlePassTable
		end
	elseif tableType == xyd.BATTLE_PASS_TABLE.SHOP then
		if self:getBattlePassId() == xyd.ActivityID.BATTLE_PASS_2 then
			return xyd.tables.shopBattlePass2Table
		else
			return xyd.tables.shopBattlePassTable
		end
	elseif tableType == xyd.BATTLE_PASS_TABLE.AWARD then
		if self:getBattlePassId() == xyd.ActivityID.BATTLE_PASS_2 then
			return xyd.tables.battlePassAward2Table
		else
			return xyd.tables.battlePassAwardTable
		end
	end
end

function Activity:getBattlePassId()
	if self:getActivity(xyd.ActivityID.BATTLE_PASS) then
		return xyd.ActivityID.BATTLE_PASS
	else
		return xyd.ActivityID.BATTLE_PASS_2
	end
end

function Activity:onNewPartnerWarmUpFight(event)
	local data = self:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		data.detail_.current_stage = event.data.current_stage
		data.detail_.stage_play_count = event.data.stage_play_count
	end
end

function Activity:setIceSecretRedMarkState()
	local iceSecretRedPointArr = {}

	table.insert(iceSecretRedPointArr, xyd.ActivityID.ICE_SECRET)
	table.insert(iceSecretRedPointArr, xyd.ActivityID.ACTIVITY_ICE_SECRET_GIFTBAG)
	table.insert(iceSecretRedPointArr, xyd.ActivityID.ACTIVITY_ICE_SECRET_MISSION)
	table.insert(iceSecretRedPointArr, xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE)

	for i in pairs(iceSecretRedPointArr) do
		local data = self:getActivity(iceSecretRedPointArr[i])

		if data and data:getEndTime() - xyd.getServerTime() > 0 then
			if iceSecretRedPointArr[i] ~= xyd.ActivityID.ICE_SECRET_BOSS_CHALLENGE then
				if data:getRedMarkState() then
					xyd.models.redMark:setMark(iceSecretRedPointArr[i], true)
				else
					xyd.models.redMark:setMark(iceSecretRedPointArr[i], false)

					local disTime = data:getLittleUpdateTime()

					if disTime > -5 then
						if disTime < 10 then
							disTime = 10
						end

						xyd.addGlobalTimer(handler(self, self.setIceSecretRedMarkState), disTime, 1)
					end
				end
			else
				xyd.models.redMark:setMark(iceSecretRedPointArr[i], data:getRedMarkState())
			end
		else
			xyd.models.redMark:setMark(iceSecretRedPointArr[i], false)
		end
	end
end

function Activity:exploreOldCampusFightTime()
	if self.exploreOldCampusIsFight and self.exploreOldCampusIsFight == true then
		self.exploreOldCampusIsFight = false

		xyd.addGlobalTimer(function ()
			self.exploreOldCampusIsFight = true
		end, 0.5, 1)
	end

	if self.exploreOldCampusIsFight == nil then
		self.exploreOldCampusIsFight = true
	end
end

function Activity:getExploreOldCampusIsFight()
	if self.exploreOldCampusIsFight == nil then
		self.exploreOldCampusIsFight = true
	end

	return self.exploreOldCampusIsFight
end

function Activity:levChange()
	if not self:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_FUND) then
		local openLev = xyd.tables.miscTable:getNumber("activity_newbee_fund_level_limit", "value")

		if openLev <= xyd.models.backpack:getLev() then
			self:reqActivityByID(xyd.ActivityID.ACTIVITY_NEWBEE_FUND)
		end
	end

	if not self:getActivity(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3) then
		local openLev = xyd.tables.miscTable:getNumber("activity_newbee_fund_level_limit", "value")

		if openLev <= xyd.models.backpack:getLev() then
			self:reqActivityByID(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3)
		end
	end
end

function Activity:itemChangeBcackUpateRed(items)
	for i in pairs(items) do
		if items[i].item_id == xyd.ItemID.SPRING_NEW_YEAR then
			local activityData_182 = xyd.models.activity:getActivity(xyd.ActivityID.SPRING_NEW_YEAR)

			if activityData_182 then
				activityData_182:setIsCheckCountRed(true)
				xyd.models.activity:updateRedMarkCount(xyd.ActivityID.SPRING_NEW_YEAR, function ()
					activityData_182:setIsCheckCountRed(false)
				end)
			end
		end

		if items[i].item_id == xyd.ItemID.RED_WINE then
			local activityData_226 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_WINE)

			if activityData_226 then
				activityData_226:setRedMarkCheck(false)
				xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_WINE, function ()
					activityData_226:setRedMarkCheck(true)
				end)
			end
		end

		if items[i].item_id == xyd.ItemID.ROSE_BROOCH then
			local activityData_227 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TREASURE)

			if activityData_227 then
				activityData_227:setRedMarkCheck(false)
				xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_TREASURE, function ()
					activityData_227:setRedMarkCheck(true)
				end)
			end
		end

		if items[i].item_id == xyd.ItemID.VIP_EXP then
			local activityData_229 = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP)

			if activityData_229 then
				activityData_229:setRedMarkCheck(false)
				xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_3BIRTHDAY_VIP, function ()
					activityData_229:setRedMarkCheck(true)
				end)
			end
		end
	end
end

function Activity:setNeedOpenActivityAloneEnter(type, num)
	if not self.needOpenActivityAloneEnter then
		self.needOpenActivityAloneEnter = {}
	end

	if not self.needOpenActivityAloneEnter_NumArr then
		self.needOpenActivityAloneEnter_NumArr = {}
	end

	if not self.needOpenActivityAloneEnter_NumArr[type] then
		self.needOpenActivityAloneEnter_NumArr[type] = {}
	end

	local isSearch = false

	for i in pairs(self.needOpenActivityAloneEnter_NumArr[type]) do
		if self.needOpenActivityAloneEnter_NumArr[type][i] == num then
			isSearch = true

			break
		end
	end

	if not isSearch then
		table.insert(self.needOpenActivityAloneEnter_NumArr[type], num)
	end

	if not self.needOpenActivityAloneEnter[type] then
		self.needOpenActivityAloneEnter[type] = {}
	end

	self.needOpenActivityAloneEnter[type][num] = 1
end

function Activity:updateNeedOpenActivityAloneEnter(type, num)
	local isNeedUpdate = false

	if self.needOpenActivityAloneEnter_NumArr and self.needOpenActivityAloneEnter_NumArr[type] then
		for i, key in pairs(self.needOpenActivityAloneEnter_NumArr[type]) do
			if key <= num and self.needOpenActivityAloneEnter[type][key] ~= nil then
				isNeedUpdate = true
				self.needOpenActivityAloneEnter[type][key] = nil
			end
		end
	end

	if isNeedUpdate then
		local mainWd = xyd.WindowManager.get():getWindow("main_window")

		mainWd:CheckExtraActBtn()
		dump("update mainWindow activity enter")
	end
end

function Activity:updateMainWindowNew()
	if xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_MONTHLY_GIFTBAG) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_WEEKLY_GIFTBAG) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_MONTH_CARD) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_PRIVILEGE_CARD) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_DAILY_GIFGBAG) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_MONTHLY_GIFTBAG02) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_WEEKLY_GIFTBAG02) or xyd.models.redMark:getRedState(xyd.RedMarkType.LIMIT_DISCOUNT_DAILY_GIFGBAG02) then
		xyd.models.redMark:setMark(xyd.RedMarkType.MAIN_WINDOW_ACTIVITY_NEW, false)

		return
	end

	local ids = xyd.tables.miscTable:split2Cost("giftbag_new_show", "value", "|")
	local targetIds = {}
	local sortedIDs = table.sortedKeys(self.activityList)
	local targetIds = {}

	for i = 1, #ids do
		for j = 1, #sortedIDs do
			if ids[i] == sortedIDs[j] and xyd.tables.activityTable:getType(tonumber(ids[i])) == 1 then
				table.insert(targetIds, ids[i])
			end
		end
	end

	for i = 1, #targetIds do
		local timestamp = xyd.models.activity:getActivity(targetIds[i]).end_time

		if not xyd.db.misc:getValue("main_window_activity_new" .. targetIds[i] .. timestamp) then
			xyd.models.redMark:setMark(xyd.RedMarkType.MAIN_WINDOW_ACTIVITY_NEW, true)

			return
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.MAIN_WINDOW_ACTIVITY_NEW, false)
end

function Activity:isResidentReturnTimeIn()
	local returnData = self:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if returnData and returnData:getReturnStartTime() ~= -1 and returnData:getReturnEndTime() ~= -1 and returnData:getReturnStartTime() <= xyd.getServerTime() and xyd.getServerTime() < returnData:getReturnEndTime() then
		return true
	end

	return false
end

function Activity:isResidentReturnAddTime()
	local returnData = self:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if returnData and returnData:getReturnStartTime() ~= -1 and returnData:getReturnEndTime() ~= -1 and returnData:getReturnStartTime() <= xyd.getServerTime() and xyd.getServerTime() < returnData:getReturnStartTime() + xyd.tables.miscTable:getNumber("activity_return2_time1", "value") then
		return true
	end

	return false
end

function Activity:updateActivityOnlyEnter(type)
	local main_wn = xyd.WindowManager.get():getWindow("main_window")

	if main_wn then
		main_wn:CheckExtraActBtn(type)
	end
end

function Activity:getArcticPartnerState(partner_id)
	local activityData = self:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)

	if activityData then
		return activityData:getArcticPartnerState(partner_id)
	end

	return 1
end

function Activity:getArcticPartnerValue(partner_id)
	local activityData = self:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)

	if activityData then
		return activityData:getArcticPartnerValue(partner_id)
	end

	return 24
end

return Activity
