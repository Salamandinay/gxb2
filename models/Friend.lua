local Friend = class("Friend", import(".BaseModel"))

function Friend:ctor()
	Friend.super.ctor(self)

	self.data_ = {}
	self.recommendList_ = {}
	self.isLoadRecommend_ = false
	self.isLoad_ = false
	self.isReceiveRed_ = false
	self.isRequestRed_ = false
	self.isBoss_ = false
	self.timeCount_ = nil
	self.friendFight_ = {}
	self.friendPet_ = {}
	self.requestList_ = {}
	self.lastApplyID_ = -1
	self.mySharedPartnerInfo = nil
	self.unlockStage = 1
	self.sharedTimes = 0
	self.bossIsAlive = false
	self.selectedBossLevel = nil
	self.redPointType = {
		FRIENDBOSS = 1
	}
	self.maxCanJumpBattle = 0
	local value = xyd.db.misc:getValue("friend_boss_skip_report")

	if value and tonumber(value) == 1 then
		self.skipFriendBoss = true
	else
		self.skipFriendBoss = false
	end
end

function Friend:onRegister()
	Friend.super.onRegister(self)
	self:registerEvent(xyd.event.FRIEND_GET_INFO, handler(self, self.onGetInfo))
	self:registerEvent(xyd.event.FRIEND_APPLY, handler(self, self.onApplyFriend))
	self:registerEvent(xyd.event.FRIEND_ACCEPT, handler(self, self.onFriendAccept))
	self:registerEvent(xyd.event.FRIEND_DELETE, handler(self, self.onFriendDel))
	self:registerEvent(xyd.event.FRIEND_DELETE_REQUEST, handler(self, self.onDelRequest))
	self:registerEvent(xyd.event.FRIEND_RECOMMEND_LIST, handler(self, self.onGetRecommendList))
	self:registerEvent(xyd.event.FRIEND_SEND_GIFTS, handler(self, self.onSendGifts))
	self:registerEvent(xyd.event.FRIEND_GET_GIFTS, handler(self, self.onGetGifts))
	self:registerEvent(xyd.event.FRIEND_SEARCH_BOSS, handler(self, self.onSearchBoss))
	self:registerEvent(xyd.event.FRIEND_FIGHT_BOSS, handler(self, self.onFightBoss))
	self:registerEvent(xyd.event.FRIEND_SWEEP_BOSS, handler(self, self.onSweepBoss))
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedPoint))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.onSystemUpdate))
	self:registerEvent(xyd.event.GET_FRIEND_BOSS_INFO, handler(self, self.onGetFriendBossInfo))
	self:registerEvent(xyd.event.FRIEND_BOSS_FIGHT, handler(self, self.onFriendBossFight))
	self:registerEvent(xyd.event.GET_FRIEND_SHARED_PARTNER, handler(self, self.onGetFriendSharedPartner))
	self:registerEvent(xyd.event.SET_FRIEND_SHARED_PARTNER, handler(self, self.onSetFriendSharedPartner))
	self:registerEvent(xyd.event.LEV_CHANGE, handler(self, self.onLevUp))
end

function Friend:getInfo(isForce)
	local needReq = true

	if self.isLoad_ and not isForce then
		needReq = false
	end

	if self.loadTime_ and xyd.getServerTime() - self.loadTime_ >= 15 then
		needReq = true
	end

	if needReq then
		local msg = messages_pb.friend_get_info_req()

		xyd.Backend.get():request(xyd.mid.FRIEND_GET_INFO, msg)

		self.loadTime_ = xyd.getServerTime()

		return true
	else
		return false
	end
end

function Friend:onSystemUpdate()
	self.isLoad_ = false

	self:getInfo()
end

function Friend:onGetInfo(event)
	local data = event.data

	self:checkRedPoint(data)

	self.data_ = data
	local hasList = {}

	for idx, info2 in ipairs(self.requestList_) do
		hasList[info2.player_id] = true
	end

	for _, info in ipairs(self.data_.request_list) do
		if not hasList[info.player_id] then
			table.insert(self.requestList_, info)
		end
	end

	self:startTimeCount()

	self.isLoad_ = true
end

function Friend:startTimeCount()
	local leftTime = 86400
	local left1 = self:dateTimeCount()
	local left2 = self:energyTimeCount()

	self:bossTimeCount()

	if left1 < leftTime then
		leftTime = left1
	end

	if left2 < leftTime then
		leftTime = left2
	end

	if self.timeCount_ == nil and leftTime > 0 then
		local function onTimer()
			self:energyTimeCount()
			self:bossTimeCount()
			self:dateTimeCount()
		end

		self.timeCount_ = xyd.models.selfPlayer:addGlobalTimer(onTimer, leftTime)
	elseif self.timeCount_ then
		xyd.models.selfPlayer:removeGlobalTimer(self.timeCount_)

		local function onTimer()
			self:energyTimeCount()
			self:bossTimeCount()
			self:dateTimeCount()
		end

		self.timeCount_ = xyd.models.selfPlayer:addGlobalTimer(onTimer, leftTime)
	end
end

function Friend:onLevUp()
	self:bossTimeCount()
end

function Friend:energyTimeCount()
	if not self.isLoad_ then
		return 86400
	end

	local cd = xyd.tables.miscTable:getVal("friend_energy_cd")
	local baseInfo = self:getBaseInfo()
	local lastTime = baseInfo.energy_time or 0
	local duration = cd - (xyd.getServerTime() - lastTime)

	if duration <= 0 then
		self.isLoad_ = false
	end

	return duration
end

function Friend:bossTimeCount()
	local lev = xyd.models.backpack:getLev()
	local openLev = tonumber(xyd.tables.miscTable:getVal("friend_search_level"))

	if lev < openLev then
		return
	end

	local searchFlag = self:isSearchRed()
	local flag = self.isLoad_ and (self.isBoss_ or searchFlag)

	if flag then
		self:setRedMark()
	end
end

function Friend:dateTimeCount()
	local serverTime = xyd.getServerTime()
	local tomorrowTime = xyd.models.selfPlayer:getTomorrowTime()

	if serverTime - tomorrowTime >= 0 then
		self.isLoad_ = false

		xyd.models.selfPlayer:setTomorrowTime(tomorrowTime + 86400)
	end

	return tomorrowTime - serverTime
end

function Friend:isShowApplyTips(id)
	return self.lastApplyID_ == id
end

function Friend:setShowApplyTipsID(id)
	self.lastApplyID_ = id
end

function Friend:applyFriend(id, isRecommend, isShowTips)
	if isRecommend then
		self:delRecommendById(id)
	end

	if isShowTips then
		self:setShowApplyTipsID(id)
	end

	local msg = messages_pb.friend_apply_req()
	msg.friend_id = id

	xyd.Backend.get():request(xyd.mid.FRIEND_APPLY, msg)
end

function Friend:acceptFriend(id)
	local msg = messages_pb.friend_accept_req()
	msg.friend_id = id

	xyd.Backend.get():request(xyd.mid.FRIEND_ACCEPT, msg)
end

function Friend:delFriend(id)
	local msg = messages_pb.friend_delete_req()
	msg.friend_id = id

	xyd.Backend.get():request(xyd.mid.FRIEND_DELETE, msg)
end

function Friend:refuseFriends(ids)
	local msg = messages_pb.friend_delete_request_req()

	for _, id in ipairs(ids) do
		table.insert(msg.friend_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_DELETE_REQUEST, msg)
end

function Friend:reqRecommendList()
	local msg = messages_pb.friend_recommend_list_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_RECOMMEND_LIST, msg)
end

function Friend:onApplyFriend(event)
end

function Friend:onFriendDel(event)
	local playerID = event.data.friend_id
	local list = self:getFriendList()

	for idx, playerInfo in ipairs(list) do
		if playerInfo.player_id == playerID then
			table.remove(list, idx)

			break
		end
	end
end

function Friend:onGetRecommendList(event)
	self.recommendList_ = event.data.player_infos or {}
end

function Friend:getRecommendList()
	return self.recommendList_
end

function Friend:delRecommendById(id)
	local list = self:getRecommendList()

	for idx, info in ipairs(list) do
		if info.player_id == id then
			table.remove(list, idx)
		end
	end
end

function Friend:checkIsFriend(id, list)
	list = list or self:getFriendList()
	local flag = false

	for _, info in ipairs(list) do
		if info.player_id == id then
			flag = true

			break
		end
	end

	return flag
end

function Friend:isFullFriends()
	local list = self:getFriendList()
	local maxLen = tonumber(xyd.tables.miscTable:getVal("friend_max_num"))

	return maxLen <= #list
end

function Friend:getData()
	return self.data_ or {}
end

function Friend:getRequestList()
	return self.requestList_ or {}
end

function Friend:getFriendList()
	return self:getData().friend_list or {}
end

function Friend:getSendInfos()
	return self:getData().send_infos or {}
end

function Friend:getReceiveInfos()
	return self:getData().receive_infos or {}
end

function Friend:getBaseInfo()
	return self:getData().base_info or {}
end

function Friend:getBossInfos()
	return self:getData().boss_infos or {}
end

function Friend:getBossAwardEndTime()
	return self:getData().end_time or 0
end

function Friend:checkIsSend(id)
	local infos = self:getSendInfos()
	local flag = false

	for _, info in ipairs(infos) do
		if info.player_id == id then
			if info.status == 1 then
				flag = true
			end

			break
		end
	end

	return flag
end

function Friend:updateSendStatusByID(id, status)
	local infos = self:getSendInfos()
	local flag = false

	for _, info in ipairs(infos) do
		if info.player_id == id then
			info.status = status
			flag = true

			break
		end
	end

	if not flag then
		table.insert(infos, {
			player_id = id,
			status = status
		})
	end
end

function Friend:checkHasBoss(id)
	local infos = self:getBossInfos()
	local flag = false

	for _, info in ipairs(infos) do
		if info.player_id == id and info.boss_id > 0 then
			flag = true
		end
	end

	return flag
end

function Friend:getBossInfo(id)
	local infos = self:getBossInfos()
	local bossInfo = nil

	for _, info in ipairs(infos) do
		if info.player_id == id then
			bossInfo = info

			break
		end
	end

	return bossInfo
end

function Friend:updateReceiveStatusByID(id, status)
	local infos = self:getReceiveInfos()

	for _, info in ipairs(infos) do
		if info.player_id == id then
			info.status = status

			break
		end
	end
end

function Friend:getReceiveStatus(id)
	local infos = self:getReceiveInfos()
	local status = 0

	for _, info in ipairs(infos) do
		if info.player_id == id then
			status = info.status

			break
		end
	end

	return status
end

function Friend:delRequest(list)
	local requestList = self:getRequestList()

	if #list == #requestList then
		self.requestList_ = {}
	else
		for index = 1, #list do
			local id = list[index]

			for idx, info in ipairs(requestList) do
				if info.player_id == id then
					table.remove(requestList, idx)
				end
			end
		end
	end
end

function Friend:onFriendAccept(event)
	local data = event.data
	local playerInfo = data.player_info
	local friendList = self:getFriendList()

	table.insert(friendList, playerInfo)
	self:delRequest({
		playerInfo.player_id
	})

	self.isLoad_ = false
end

function Friend:onDelRequest(event)
	local data = event.data

	self:delRequest(data.friend_ids)
end

function Friend:getTili()
	local baseInfo = self:getBaseInfo()

	return baseInfo.energy or 0
end

function Friend:setTili(tili)
	local baseInfo = self:getBaseInfo()
	baseInfo.energy = tili
end

function Friend:sendGifts(ids)
	local msg = messages_pb.friend_send_gifts_req()

	for _, id in ipairs(ids) do
		table.insert(msg.friend_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_SEND_GIFTS, msg)
end

function Friend:getGifts(ids)
	local msg = messages_pb.friend_get_gifts_req()

	for _, id in ipairs(ids) do
		table.insert(msg.friend_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_GET_GIFTS, msg)
end

function Friend:onGetGifts(event)
	local fids = event.data.friend_ids

	for _, id in ipairs(fids) do
		self:updateReceiveStatusByID(id, 2)
	end

	local giftNum = event.data.gift_num
	local baseInfo = self:getBaseInfo()
	baseInfo.gift_num = giftNum
end

function Friend:onSendGifts(event)
	local fids = event.data.friend_ids

	for _, id in ipairs(fids) do
		self:updateSendStatusByID(id, 1)
	end
end

function Friend:searchBoss()
	local msg = messages_pb.friend_search_boss_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_SEARCH_BOSS, msg)
end

function Friend:fightBoss(id, partners, petID)
	partners = partners or self.friendFight[id]

	if not partners then
		return
	end

	petID = petID or self.friendPet_[id]
	self.friendFight_[id] = partners
	self.friendPet_[id] = petID
	local msg = messages_pb.friend_fight_boss_req()

	for _, partner in ipairs(partners) do
		local fightPartner = messages_pb.fight_partner()
		fightPartner.partner_id = partner.partner_id
		fightPartner.pos = partner.pos

		table.insert(msg.partners, fightPartner)
	end

	msg.friend_id = id
	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.FRIEND_FIGHT_BOSS, msg)
end

function Friend:fightFriend(id, partners, petID, team_index)
	partners = partners or self.friendFight_[id]

	if not partners then
		return
	end

	petID = petID or self.friendPet_[id]
	self.friendFight_[id] = partners
	self.friendPet_[id] = petID
	local msg = messages_pb.friend_fight_friend_req()

	if team_index then
		msg.formation_id = team_index
	else
		for _, partner in ipairs(partners) do
			local fightPartner = messages_pb.fight_partner()
			fightPartner.partner_id = partner.partner_id
			fightPartner.pos = partner.pos

			table.insert(msg.partners, fightPartner)
		end
	end

	msg.pet_id = petID
	msg.friend_id = id

	if UNITY_EDITOR and xyd.db.misc:getValue("test_index", -1) == "1" then
		msg.has_random = 1
	end

	xyd.Backend.get():request(xyd.mid.FRIEND_FIGHT_FRIEND, msg)
end

function Friend:onSearchBoss(event)
	local data = event.data

	if data.base_info then
		for key, value in pairs(data.base_info) do
			self:getData().base_info[key] = value
		end

		if data.base_info.boss_id > 0 then
			xyd.db.misc:addOrUpdate({
				key = "friend_boss",
				value = tostring(data.base_info.boss_id)
			})
		end
	end

	self:setRedMark()
end

function Friend:onFightBoss(event)
	local data = event.data
	local friendID = data.friend_id
	local baseInfo = self:getBaseInfo()

	if friendID == xyd.Global.playerID then
		for key, _ in pairs(baseInfo.enemies) do
			baseInfo.enemies[key] = nil
		end

		for key, value in pairs(data.enemies) do
			table.insert(baseInfo.enemies, value)
		end

		baseInfo.boss_id = data.boss_id
	else
		local bossInfo = self:getBossInfo(friendID)

		if bossInfo then
			for key, _ in pairs(bossInfo.enemies) do
				bossInfo.enemies[key] = nil
			end

			for _, value in pairs(data.enemies) do
				table.insert(bossInfo.enemies, value)
			end

			bossInfo.boss_id = data.boss_id
		end
	end

	baseInfo.energy = data.energy

	xyd.models.map:resetMapRank(xyd.MapType.FRIEND_RANK)
end

function Friend:clearBoss(playerID)
	local bossInfo = self:getBossInfo(playerID)

	if bossInfo then
		for key, _ in pairs(bossInfo.enemies) do
			bossInfo.enemies[key] = nil
		end

		bossInfo.boss_id = 0
	end
end

function Friend:sweepBoss(partners, id, num, petID)
	local msg = messages_pb.friend_sweep_boss_req()

	for _, partner in ipairs(partners) do
		local fightPartner = messages_pb.fight_partner()
		fightPartner.partner_id = partner.partner_id
		fightPartner.pos = partner.pos

		table.insert(msg.partners, fightPartner)
	end

	msg.friend_id = id
	msg.num = num
	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.FRIEND_SWEEP_BOSS, msg)
end

function Friend:onSweepBoss(event)
	local data = event.data
	local friendID = data.friend_id
	local baseInfo = self:getBaseInfo()

	if friendID == xyd.Global.playerID then
		for key, _ in pairs(baseInfo.enemies) do
			baseInfo.enemies[key] = nil
		end

		for _, value in pairs(data.enemies) do
			table.insert(baseInfo.enemies, value)
		end

		baseInfo.boss_id = data.boss_id
		baseInfo.search_time = 0
	else
		local bossInfo = self:getBossInfo(friendID)

		if bossInfo then
			for key, _ in pairs(bossInfo.enemies) do
				bossInfo.enemies[key] = nil
			end

			for _, value in pairs(data.enemies) do
				table.insert(bossInfo.enemies, value)
			end

			bossInfo.boss_id = data.boss_id
		end
	end

	baseInfo.energy = data.energy

	xyd.models.map:resetMapRank(xyd.MapType.FRIEND_RANK)
end

function Friend:getBossRank()
	local msg = messages_pb.friend_get_boss_rank_req()

	xyd.Backend.get():request(xyd.mid.FRIEND_GET_BOSS_RANK, msg)
end

function Friend:getLoveNum()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.FRIEND_LOVE)
end

function Friend:getGiftNum()
	local baseInfo = self:getBaseInfo()

	return baseInfo.gift_num or 0
end

function Friend:setRedMark()
	local flag = false

	if self:isRequestRed() or self.isLoad_ and self:isSearchRed() or self:isReceiveRed() or self:isFriendBossRed() then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.FRIEND, flag)
end

function Friend:onRedPoint(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funcID = event.data.function_id or 0

	if funcID == xyd.FunctionID.FRIEND then
		self.isLoad_ = false

		if event.data.value == self.redPointType.FRIENDBOSS then
			self.isFriendBossRed_ = true

			self:setRedMark()
		end
	end
end

function Friend:checkRedPoint(newData)
	local oldReceive = self:getReceiveInfos()
	local oldRequest = self:getRequestList()
	local oldFriends = self:getFriendList()
	local newReceive = newData.receive_infos or {}
	local newRequest = newData.request_list or {}
	local newFriends = newData.friend_list or {}

	if #oldReceive ~= #newReceive then
		local canReceive = false

		for _, receive in ipairs(newReceive) do
			if receive.status == 1 and self:checkIsFriend(receive.player_id, newFriends) then
				canReceive = true

				break
			end
		end

		self.isReceiveRed_ = canReceive
	end

	if #oldFriends ~= #newFriends and self.isLoad_ then
		self.isReceiveRed_ = true
	end

	if #oldRequest ~= #newRequest and tonumber(xyd.tables.miscTable:getVal("friend_max_num")) > #newFriends then
		self.isRequestRed_ = true
	end

	self:setRedMark()
end

function Friend:isRequestRed()
	return self.isRequestRed_
end

function Friend:setRequestRed(flag)
	self.isRequestRed_ = flag

	self:setRedMark()
end

function Friend:isReceiveRed()
	return self.isReceiveRed_
end

function Friend:setReceiveRed(flag)
	self.isReceiveRed_ = flag

	self:setRedMark()
end

function Friend:isSearchRed()
	return false
end

function Friend:isFriendBossRed()
	return self.isFriendBossRed_
end

function Friend:setFriendBossRed(flag)
	self.isFriendBossRed_ = flag

	self:setRedMark()
end

function Friend:onGetFriendSharedPartner(event)
	self.friendSharedPartnerList = event.data.shared_infos

	self:setClassifiedFriendSharedPartner()
end

function Friend:onGetFriendBossInfo(event)
	self.mySharedPartnerInfo = event.data
	self.unlockStage = event.data.unlock_stage
	self.sharedTimes = event.data.shared_times
	self.selfWinCounts = event.data.self_win_counts

	if event.data.is_done == 0 then
		self.bossIsAlive = true
	else
		self.bossIsAlive = false
	end

	if self.mySharedPartnerInfo.shared_partner ~= nil then
		-- Nothing
	end

	local lev = xyd.models.backpack:getLev()
	local openLev = tonumber(xyd.tables.miscTable:getVal("friend_search_level"))

	if not self.bossIsAlive or lev < openLev then
		self.isFriendBossRed_ = false
	end

	self:setRedMark()
	self:updateMaxCanJumpBattleLevel()
end

function Friend:updateMaxCanJumpBattleLevel()
	local needNum = tonumber(xyd.tables.miscTable:getVal("friend_boss_skip_limit"))

	if not self.selfWinCounts then
		return
	end

	for i = 1, #self.selfWinCounts do
		if needNum <= self.selfWinCounts[i] and self.maxCanJumpBattle < i then
			self.maxCanJumpBattle = i
		end
	end
end

function Friend:canJumpBattle(bossLev)
	if self.maxCanJumpBattle < tonumber(bossLev) then
		return false
	else
		return true
	end
end

function Friend:isSkipBattle()
	return self.skipFriendBoss
end

function Friend:skipFriendBossBattle(flag)
	self.skipFriendBoss = flag
	local value = nil

	if flag then
		value = 1
	else
		value = 0
	end

	xyd.db.misc:addOrUpdate({
		key = "friend_boss_skip_report",
		value = value
	})
end

function Friend:getUnlockStage()
	return self.unlockStage
end

function Friend:getMySharedPartner()
	return self.mySharedPartnerInfo
end

function Friend:getSharedTimes()
	return self.sharedTimes
end

function Friend:getPlayerSharedPartner(playerId)
	if self.classifiedFriendSharedPartnerList["0"] == nil then
		return nil
	end

	local i = 0

	while i < #self.classifiedFriendSharedPartnerList["0"] do
		if self.classifiedFriendSharedPartnerList["0"][i + 1].player_id == playerId then
			return self.classifiedFriendSharedPartnerList["0"][i + 1]
		end

		i = i + 1
	end

	return nil
end

function Friend:onSetFriendSharedPartner(event)
	local msg = messages_pb.get_friend_boss_info_req()

	xyd.Backend.get():request(xyd.mid.GET_FRIEND_BOSS_INFO, msg)
end

function Friend:getFriendSharedPartner()
	return self.friendSharedPartnerList
end

function Friend:setClassifiedFriendSharedPartner()
	local groupIds = xyd.tables.groupTable:getGroupIds()
	self.classifiedFriendSharedPartnerList = {
		["0"] = {}
	}

	for i = 1, #groupIds do
		self.classifiedFriendSharedPartnerList[tostring(groupIds[i])] = {}
	end

	local Partner = import("app.models.Partner")

	for i = 1, #self.friendSharedPartnerList do
		if self.friendSharedPartnerList[i].shared_partner ~= nil then
			local id = self.friendSharedPartnerList[i].shared_partner.partner_id
			local partner = Partner.new()

			partner:populate(self.friendSharedPartnerList[i].shared_partner)

			local partnerGroupId = partner:getGroup()

			table.insert(self.classifiedFriendSharedPartnerList[tostring(partnerGroupId)], self.friendSharedPartnerList[i])
			table.insert(self.classifiedFriendSharedPartnerList["0"], self.friendSharedPartnerList[i])
		end
	end
end

function Friend:getClassifiedFriendSharedPartner()
	return self.classifiedFriendSharedPartnerList
end

function Friend:setMySharedPartner(partnerId)
	local msg = messages_pb.set_friend_shared_partner_req()
	msg.partner_id = tonumber(partnerId)

	xyd.Backend.get():request(xyd.mid.SET_FRIEND_SHARED_PARTNER, msg)
end

function Friend:updateFriendBossInfo()
	local msg = messages_pb.get_friend_boss_info_req()

	xyd.Backend.get():request(xyd.mid.GET_FRIEND_BOSS_INFO, msg)
end

function Friend:updateFriendSharedPartner()
	local msg = messages_pb.get_friend_shared_partner_req()

	xyd.Backend.get():request(xyd.mid.GET_FRIEND_SHARED_PARTNER, msg)
end

function Friend:checkBossIsAlive()
	return self.bossIsAlive
end

function Friend:loadFriendBossInfo()
	self:updateFriendSharedPartner()
	self:updateFriendBossInfo()
end

function Friend:onFriendBossFight(event)
	self:updateFriendBossInfo()
end

function Friend:FightBoss(params)
	xyd.Backend.get():request(xyd.mid.FRIEND_BOSS_FIGHT, params)
end

function Friend:setSelectedBossLev(selectedBossLevel)
	self.selectedBossLevel = selectedBossLevel

	xyd.db.misc:setValue({
		key = "selectedBossLevel",
		value = self.selectedBossLevel
	})
end

function Friend:getSelectedBossLevel()
	if not self.selectedBossLevel then
		local selectedBossLevelTemp = tonumber(xyd.db.misc:getValue("selectedBossLevel"))

		if selectedBossLevelTemp ~= nil then
			self.selectedBossLevel = tonumber(selectedBossLevelTemp)
		else
			local unlockedMaxBossLevel = self:getUnlockStage()
			self.selectedBossLevel = unlockedMaxBossLevel

			xyd.db.misc:setValue({
				key = "selectedBossLevel",
				value = self.selectedBossLevel
			})
		end
	end

	return self.selectedBossLevel
end

function Friend:judgeOpenFriendBoss(event)
	local oldLev = event.data.oldLev
	local newLev = event.data.newLev
	local openLev = tonumber(xyd.tables.miscTable:getVal("friend_search_level"))

	if oldLev < openLev and openLev <= newLev then
		self.isFriendBossRed_ = true

		self:loadFriendBossInfo()
	end
end

return Friend
