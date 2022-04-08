local AdvertiseComplete = class("AdvertiseComplete", import(".BaseModel"))

function AdvertiseComplete:ctor()
	AdvertiseComplete.super.ctor(self)

	self.achievements = {}
end

function AdvertiseComplete:onRegister()
	AdvertiseComplete.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACHIEVEMENT_LIST, self.onAchievementInfo, self)
	self:registerEvent(xyd.event.LEV_CHANGE, self.onLevelChange, self)
	self:registerEvent(xyd.event.MAP_FIGHT, self.onMapFightResult, self)
	self:registerEvent(xyd.event.TOWER_FIGHT, self.onTowerBattle, self)
	self:registerEvent(xyd.event.VIP_CHANGE, self.onVipChange, self)
	self:registerEvent(xyd.event.RECHARGE, self.onRecharge, self)
end

function AdvertiseComplete:onAchievementInfo(event)
	local achievements = event.data.achievements

	for _, achievement in pairs(achievements) do
		if achievement.achieve_type and achievement.achieve_type > 0 then
			self.achievements[tonumber(achievement.achieve_type)] = achievement.value
		end
	end
end

function AdvertiseComplete:onLevelChange(event)
	local data = event.data
	local prenum = data.oldLev
	local num = data.newLev
	local ename = ""

	if prenum < 10 and num >= 10 then
		ename = "lv10"
	elseif prenum < 20 and num >= 20 then
		ename = "lv20"
	elseif prenum < 32 and num >= 32 then
		ename = "lv32"
	elseif prenum < 40 and num >= 40 then
		ename = "lv40"
	elseif prenum < 60 and num >= 60 then
		ename = "lv60"
	end

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

function AdvertiseComplete:onMapFightResult(event)
	local is_win = event.data.is_win

	if not is_win then
		return
	end

	local map_type = event.data.map_type
	local stage_id = event.data.stage_id
	local ename = ""

	if map_type == xyd.MapType.CAMPAIGN and stage_id == xyd.AF_TRACKING_MAP3 then
		ename = "s1lv3_map"
	elseif map_type == xyd.MapType.CAMPAIGN and stage_id == xyd.AF_TRACKING_MAP4 then
		ename = "s1lv4_map"
	end

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

function AdvertiseComplete:onTowerBattle(event)
	if event.data.is_win == 0 then
		return
	end

	local stage = event.data.stage_id
	local ename = ""

	if stage == 5 then
		ename = "lv5_to"
	elseif stage == 10 then
		ename = "lv10_to"
	elseif stage == 15 then
		ename = "lv15_to"
	end

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

function AdvertiseComplete:onVipChange(event)
	if event.data.oldVip < 3 and event.data.newVip >= 3 then
		local ename = "vip3"

		self:eventTracking(ename)
	end

	if event.data.oldVip < 5 and event.data.newVip >= 5 then
		local ename = "vip5"

		self:eventTracking(ename)
	end

	if event.data.oldVip < 6 and event.data.newVip >= 6 then
		local ename = "vip6"

		self:eventTracking(ename)
	end
end

function AdvertiseComplete:firstRecharge()
	local ename = "purchased"

	self:eventTracking(ename)
end

function AdvertiseComplete:rechangGiftBag(giftBagID)
	local ename = ""

	if giftBagID == xyd.GIFTBAG_ID.MONTH_CARD then
		ename = "pass_monthly"
	elseif giftBagID == xyd.GIFTBAG_ID.MINI_MONTH_CARD then
		ename = "pass_mini"
	elseif giftBagID == xyd.GIFTBAG_ID.MANA_WEEK_CARD then
		ename = "pass_wddkly"
	end

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

function AdvertiseComplete:onArenaScore()
	local scoreRecord = self.achievements[xyd.ACHIEVEMENT_TYPE.ARENA_SCORE]

	if scoreRecord > 1200 or xyd.models.arena:getScore() < 1200 then
		print("scoreRecord")
		print(scoreRecord)

		return
	end

	local ename = "1200p_ccl"

	self:eventTracking(ename)
end

function AdvertiseComplete:achieve(type, delta)
	local prenum = self.achievements[type]
	self.achievements[type] = prenum + delta
	local num = prenum + delta
	local ename = ""
	local switch = {
		[xyd.ACHIEVEMENT_TYPE.GET_STAR4_HERO] = function ()
			if prenum < 10 and num >= 10 then
				ename = "10_4_star"
			elseif prenum < 20 and num >= 20 then
				ename = "20_4_star"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.GET_STAR5_HERO] = function ()
			if prenum < 2 and num >= 2 then
				ename = "2_5_star"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.DECOMPOSE_HERO] = function ()
			if prenum < 10 and num >= 10 then
				ename = "10_altar"
			elseif prenum < 20 and num >= 20 then
				ename = "20_altar"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.ARENA_TIMES] = function ()
			if prenum < 10 and num >= 10 then
				ename = "10_ccl"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.GET_GREEN_EQUIP] = function ()
			if prenum < 20 and num >= 20 then
				ename = "20_Green_equip"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.COMPLETE_STAR4_HEROTASK] = function ()
			if prenum < 10 and num >= 10 then
				ename = "10_4_star_Tavern"
			end
		end,
		[xyd.ACHIEVEMENT_TYPE.GET_STAR5_HERO_IN_GAMBLE] = function ()
			if prenum < 1 and num >= 1 then
				ename = "5_star_cc"
			end
		end
	}

	switch[type]()

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

function AdvertiseComplete:eventTracking(eventName)
	xyd.SdkManager.get():eventTracking(eventName)
end

function AdvertiseComplete:vipWindowOpen()
	local ename = "unity_vip_window_open"

	self:eventTracking(ename)
end

function AdvertiseComplete:onRecharge()
	local ename = "unity_recharge"

	self:eventTracking(ename)
end

function AdvertiseComplete:showPayment()
	local ename = "unity_show_payment"

	self:eventTracking(ename)
end

function AdvertiseComplete:pushWindowOpen()
	local ename = "unity_push_window_open"

	self:eventTracking(ename)
end

function AdvertiseComplete:afActivity(activityType)
	local ename = ""

	if activityType == xyd.EventType.COOL then
		ename = "activity_cool"
	elseif activityType == xyd.EventType.PUSH then
		ename = "activity_push"
	end

	if ename ~= "" then
		self:eventTracking(ename)
	end
end

return AdvertiseComplete
