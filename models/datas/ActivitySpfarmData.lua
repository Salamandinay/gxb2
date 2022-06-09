local ActivityData = import("app.models.ActivityData")
local ActivitySpfarmData = class("ActivitySpfarmData", ActivityData, true)
local json = require("cjson")

function ActivitySpfarmData:ctor(params)
	ActivityData.ctor(self, params)

	self.partnerList_ = {}
	self.opponentArr = {}

	self:sendNewOpponentInfos()

	local viewingEndFiveMinsTips = xyd.db.misc:getValue("viewing_end_mins_tips")
	viewingEndFiveMinsTips = viewingEndFiveMinsTips and tonumber(viewingEndFiveMinsTips)

	if (not viewingEndFiveMinsTips or viewingEndFiveMinsTips and (viewingEndFiveMinsTips < self:startTime() or self:getEndTime() <= viewingEndFiveMinsTips)) and xyd.getServerTime() < self:getEndTime() - self:getViewTimeSec() - 300 then
		local disTime = self:getEndTime() - self:getViewTimeSec() - 300 - xyd.getServerTime()

		xyd.addGlobalTimer(function ()
			local mapRob = self:getMapRob()

			if mapRob and #mapRob > 0 then
				local activitySpfarmMapWd = xyd.WindowManager.get():getWindow("activity_spfarm_map_window")

				if activitySpfarmMapWd then
					xyd.alertConfirm(__("ACTIVITY_SPFARM_TEXT86"), nil, __("SURE"))
					xyd.db.misc:setValue({
						key = "viewing_end_mins_tips",
						value = xyd.getServerTime()
					})
				end
			end
		end, disTime, 1)
	end
end

function ActivitySpfarmData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpfarmData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_SPFARM then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = json.decode(data.detail)

	dump(info, "data_back_300=----------------")

	local type = info.type

	if type == xyd.ActivitySpfarmType.EXPLORE then
		self.detail.map_rob[info.pos] = info.content
	elseif type == xyd.ActivitySpfarmType.GET_MATCH_INFO then
		self.opponentArr = info.match_infos

		if self.opponentArr then
			dump(#self.opponentArr, "math_len")
		end
	elseif type == xyd.ActivitySpfarmType.REMOVE_AWARD then
		local index = info.index

		table.remove(self.detail.slots_rob, index)
	elseif type == xyd.ActivitySpfarmType.OCCUPY then
		if xyd.arrayIndexOf(self.detail.slots_rob, info.id) <= 0 then
			table.insert(self.detail.slots_rob, info.id)
		end

		for i, robBuildInfo in pairs(self.detail.build_rob) do
			if robBuildInfo.id == info.id then
				robBuildInfo.is_rob = 1
			end
		end
	elseif type == xyd.ActivitySpfarmType.END_ROB then
		local items = {}

		for i, id in pairs(self.detail.slots_rob) do
			local robBuildInfo = self:getRobBuildBaseInfoWithId(id)
			local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(robBuildInfo.build_id)
			local canGetMisc = xyd.tables.miscTable:getNumber("activity_spfarm_invase_amount", "value")
			local canGetNum = math.floor(outCome[2] * robBuildInfo.lv * canGetMisc)

			table.insert(items, {
				item_id = outCome[1],
				item_num = canGetNum
			})
		end

		xyd.models.itemFloatModel:pushNewItems(items)

		self.detail.build_rob = {}
		self.detail.map_rob = {}
		self.detail.partners_rob = {}
		self.detail.rob_id = 0
		self.detail.slots_rob = {}

		self:sendNewOpponentInfos()
	elseif type == xyd.ActivitySpfarmType.START_ROB then
		self.detail.build_rob = info.info.build_rob
		self.detail.map_rob = info.info.map_rob
		self.detail.rob_id = info.info.rob_id
		self.detail.partners_rob = {}

		for _, partnerInfo in ipairs(self.tmpRobPartnerList) do
			partnerInfo.partnerInfo.status = nil

			table.insert(self.detail.partners_rob, partnerInfo.partnerInfo)
		end

		self.detail.rob_id = info.info.rob_id
		self.tmpRobPartnerList = nil
	elseif type == xyd.ActivitySpfarmType.POLICY then
		self.detail.policys = info.info.policys
	elseif type == xyd.ActivitySpfarmType.BUY then
		self.detail.buy_times = self.detail.buy_times + info.num
	elseif type == xyd.ActivitySpfarmType.BUILD then
		local oldLength = #self.detail.build_infos

		table.insert(self.detail.build_infos, {
			lv = 1,
			build_id = info.build_id,
			id = oldLength + 1
		})

		self.detail.map[info.pos] = oldLength + 1
	elseif type == xyd.ActivitySpfarmType.UP_GRADE then
		for i in pairs(self.detail.build_infos) do
			if self.detail.build_infos[i].id == info.id then
				self.detail.build_infos[i].lv = self.detail.build_infos[i].lv + info.num

				break
			end
		end
	elseif type == xyd.ActivitySpfarmType.CHANGE then
		xyd.alertTips(__("ACTIVITY_SPFARM_TEXT112"))

		for i in pairs(self.detail.build_infos) do
			if self.detail.build_infos[i].id == info.id then
				self.detail.build_infos[i].build_id = info.build_id

				break
			end
		end
	elseif type == xyd.ActivitySpfarmType.MOVE then
		xyd.alertTips(__("ACTIVITY_SPFARM_TEXT111"))

		local pos1Id = self.detail.map[info.pos1]
		local pos2Id = self.detail.map[info.pos2]

		if pos1Id > 0 and pos2Id > 0 then
			self.detail.map[info.pos1] = pos2Id
			self.detail.map[info.pos2] = pos1Id
		end

		if pos1Id > 0 and pos2Id == 0 then
			self.detail.map[info.pos1] = 0
			self.detail.map[info.pos2] = pos1Id
		end

		if pos1Id == 0 and pos2Id == 1 then
			self.detail.map[info.pos1] = pos2Id
			self.detail.map[info.pos2] = 0
		end

		local roundIds = self:getDoorRoundIds()

		for i, gridId in pairs(roundIds) do
			if self.detail.map[gridId] > 0 then
				self:getBuildBaseInfo(gridId).partners = nil
			end
		end
	elseif type == xyd.ActivitySpfarmType.SET_DEF then
		local id = info.id

		for i, buildInfo in pairs(self.detail.build_infos) do
			if buildInfo.id == id then
				buildInfo.partners = info.build_info.partners
			end
		end

		dump(info.build_info.partners)
	elseif type == xyd.ActivitySpfarmType.GET_HANG_AWARD then
		if info.items and #info.items > 0 then
			local items = info.items

			xyd.models.itemFloatModel:pushNewItems(items)
		end

		for i, buildInfo in pairs(self.detail.build_infos) do
			if buildInfo.items then
				buildInfo.items = nil
			end
		end
	elseif type == xyd.ActivitySpfarmType.FIGHT then
		local partners = info.partners

		for i, partnerInfo in pairs(partners) do
			local partner_id = partnerInfo.partner_id

			if not partner_id or not tonumber(partner_id) or tonumber(partner_id) <= 0 then
				partner_id = partnerInfo.partnerID
			end

			local partnerRobInfo = self.detail.partners_rob[partner_id]

			if partnerRobInfo then
				partnerRobInfo.status = info.battle_result.status.status_a[i]
			end
		end

		local robBuildInfos = self:getRobBuildBaseInfo(info.pos)

		for i, statusInfo in pairs(info.battle_result.status.status_b) do
			robBuildInfos.partners[i].status = statusInfo
		end

		xyd.BattleController.get():onSpfarmBattle(info.battle_result)
	elseif type == xyd.ActivitySpfarmType.FORCE_HANG then
		local id = info.id

		for i, buildInfo in pairs(self.detail.build_infos) do
			if buildInfo.id == id then
				buildInfo.force = self:getCurTimeDay()
				local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(buildInfo.build_id)

				xyd.models.itemFloatModel:pushNewItems({
					{
						item_id = outCome[1],
						item_num = outCome[2] * buildInfo.lv
					}
				})

				break
			end
		end
	elseif type == xyd.ActivitySpfarmType.GET_AWARD then
		local award_ids = info.award_ids

		for index, id in ipairs(award_ids) do
			self.detail_.awards[id] = 1
		end

		local itemList = {}

		for _, id in ipairs(award_ids) do
			local awardItem = xyd.tables.activitySpfarmAwardTable:getAwards(id)

			for _, itemInfo in ipairs(awardItem) do
				table.insert(itemList, {
					item_id = itemInfo[1],
					item_num = itemInfo[2]
				})
			end
		end

		xyd.itemFloat(itemList)
	elseif type == xyd.ActivitySpfarmType.RANK_LIST then
		self.rankList_ = info.list
	elseif type == xyd.ActivitySpfarmType.RANK_LIST_FRIEND then
		local friendList = info.list
		self.rankFriend_ = {
			list = {}
		}
		local friendInfos = xyd.models.friend:getFriendList()

		for index, data in ipairs(friendList) do
			local dataInfo = data.info
			local player_id = data.player_id
			local score = 0

			for key, build in pairs(dataInfo) do
				if tonumber(key) and tonumber(key) > 0 then
					score = score + build.lv
				end
			end

			for idx, playerInfo in ipairs(friendInfos) do
				if playerInfo.player_id == player_id then
					local getInfo = {
						avatar_frame_id = playerInfo.avatar_frame_id,
						avatar_id = playerInfo.avatar_id,
						lev = playerInfo.lev,
						player_id = playerInfo.player_id,
						player_name = playerInfo.player_name,
						score = playerInfo.score,
						server_id = playerInfo.server_id,
						dress_style = dataInfo.dress_style or {
							1000101,
							1000201,
							1000301,
							0,
							0
						},
						score = score
					}

					table.insert(self.rankFriend_.list, getInfo)

					break
				end
			end
		end

		self.rankFriend_.self_score = self:getAllBuildTotalLev()

		table.insert(self.rankFriend_.list, {
			avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
			avatar_id = xyd.models.selfPlayer:getAvatarID(),
			lev = xyd.models.backpack:getLev(),
			player_id = xyd.Global.playerID,
			player_name = xyd.models.selfPlayer:getPlayerName(),
			score = self:getAllBuildTotalLev(),
			server_id = xyd.models.selfPlayer:getServerID(),
			dress_style = xyd.models.dress:getEffectEquipedStyles()
		})
		table.sort(self.rankFriend_.list, function (a, b)
			return b.score < a.score
		end)

		local self_rank = 0

		for index, info in ipairs(self.rankFriend_.list) do
			if info.player_id == xyd.Global.playerID then
				self_rank = index - 1
			end
		end

		self.rankFriend_.self_rank = self_rank
	end
end

function ActivitySpfarmData:getMyMap()
	return self.detail.map
end

function ActivitySpfarmData:getMyBuildInfos()
	return self.detail.build_infos
end

function ActivitySpfarmData:getMapRob()
	return self.detail.map_rob
end

function ActivitySpfarmData:getBuildRob()
	return self.detail.build_rob
end

function ActivitySpfarmData:getFamousNum()
	local famousNum = 0
	local famousWithIds = xyd.tables.activitySpfarmPolicyTable:getFamousWithIds()

	for i = 1, #famousWithIds do
		local ids = famousWithIds[i]
		local isAdd = true

		for k, id in pairs(ids) do
			if not self.detail.policys[id] or self.detail.policys[id] and self.detail.policys[id] == 0 then
				isAdd = false
			end
		end

		if isAdd then
			famousNum = famousNum + 1
		else
			break
		end
	end

	return famousNum
end

function ActivitySpfarmData:getTypeBuildLimitLevUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildLev = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 1 and serchType == otherParam and self.detail.policys[id] and self.detail.policys[id] == 1 then
			buildLev = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildLev
end

function ActivitySpfarmData:getTypeBuildMaxLevUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildLev = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 1 and serchType == otherParam then
			buildLev = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildLev
end

function ActivitySpfarmData:getTypeBuildLimitNumUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 2 and serchType == otherParam and self.detail.policys[id] and self.detail.policys[id] == 1 then
			buildNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildNum
end

function ActivitySpfarmData:getTypeBuildMaxNumUp(serchType)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)
		local otherParam = xyd.tables.activitySpfarmPolicyTable:getParams(id)

		if type == 2 and serchType == otherParam then
			buildNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildNum
end

function ActivitySpfarmData:getTypeDefLimitNum()
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local defNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)

		if type == 3 and self.detail.policys[id] and self.detail.policys[id] == 1 then
			defNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return defNum
end

function ActivitySpfarmData:getTypeDefMyNum()
	local myDefNum = 0

	for i, info in pairs(self.detail.build_infos) do
		if info.partners and #info.partners > 0 then
			myDefNum = myDefNum + 1
		end
	end

	return myDefNum
end

function ActivitySpfarmData:getTypeDefMaxNum()
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local maxNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)

		if type == 3 then
			maxNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return maxNum
end

function ActivitySpfarmData:getTypeBuildLimitNum(type_need)
	local ids = xyd.tables.activitySpfarmPolicyTable:getIDs()
	local buildNum = nil

	for i, id in pairs(ids) do
		local type = xyd.tables.activitySpfarmPolicyTable:getType(id)

		if type == type_need and self.detail.policys[id] and self.detail.policys[id] == 1 then
			buildNum = xyd.tables.activitySpfarmPolicyTable:getNum(id)
		end
	end

	return buildNum
end

function ActivitySpfarmData:getPartnerUse()
	return self.detail.partners_rob or {}
end

function ActivitySpfarmData:checkPartnerRobAllDie()
	if not self.detail.partners_rob or #self.detail.partners_rob <= 0 then
		return true
	end

	for _, info in ipairs(self.detail.partners_rob) do
		if not info.status or not info.status.hp or tonumber(info.status.hp) ~= 0 then
			return false
		end
	end

	return true
end

function ActivitySpfarmData:getcurBuildNum(serchBuildId)
	local curNum = 0

	for i, info in pairs(self.detail.build_infos) do
		local buildId = info.build_id

		if buildId == serchBuildId then
			curNum = curNum + 1
		end
	end

	return curNum
end

function ActivitySpfarmData:getAllBuildTotalLev()
	local totalLev = 0

	for i, info in pairs(self.detail.build_infos) do
		if i ~= 1 then
			totalLev = totalLev + info.lv
		end
	end

	return totalLev
end

function ActivitySpfarmData:getBuildBaseInfo(gridId)
	local infoIndexId = self.detail.map[gridId]

	for i, info in pairs(self.detail.build_infos) do
		if info.id == infoIndexId then
			return info
		end
	end
end

function ActivitySpfarmData:getRobBuildBaseInfo(gridId)
	local infoIndexId = self.detail.map_rob[gridId]

	for i, info in pairs(self.detail.build_rob) do
		if info.id == infoIndexId then
			return info
		end
	end
end

function ActivitySpfarmData:getRobBuildBaseInfoWithId(id)
	for i, info in pairs(self.detail.build_rob) do
		if info.id == id then
			return info
		end
	end
end

function ActivitySpfarmData:getPartnerList()
	return self.partnerList_
end

function ActivitySpfarmData:getHp(partner_id)
	if not self.detail.partners_rob then
		return 100
	end

	for _, info in ipairs(self.detail.partners_rob) do
		if (info.partner_id == partner_id or info.partnerID == partner_id) and info.status and info.status.hp and tonumber(info.status.hp) then
			return tonumber(info.status.hp)
		end
	end

	return 100
end

function ActivitySpfarmData:checkRobbing()
	return self.detail_.rob_id ~= 0
end

function ActivitySpfarmData:startRob(player_id, partnerList)
	local partners = {}
	self.tmpRobPartnerList = partnerList

	for _, info in ipairs(partnerList) do
		table.insert(partners, info.partnerInfo.partnerID)
	end

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.START_ROB,
		player_id = player_id,
		partners = partners
	}))
end

function ActivitySpfarmData:reqPolicy(policy_id)
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.POLICY,
		table_id = policy_id
	}))
end

function ActivitySpfarmData:getDoorRoundIds()
	return {
		8,
		12,
		14,
		18
	}
end

function ActivitySpfarmData:getDoorPos()
	return 13
end

function ActivitySpfarmData:sendNewOpponentInfos()
	self.opponentIndex = 1

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.GET_MATCH_INFO
	}))
end

function ActivitySpfarmData:getNewOpponentInfos()
	if not self.opponentIndex then
		self.opponentIndex = 1
	end

	local tempArr = {}

	for i = self.opponentIndex, self.opponentIndex + 2 do
		table.insert(tempArr, self.opponentArr[i])
	end

	self.opponentIndex = self.opponentIndex + 3

	if #self.opponentArr >= 3 and #self.opponentArr < 6 then
		self.opponentIndex = 1
	elseif #self.opponentArr >= 6 and #self.opponentArr < 9 then
		if self.opponentIndex >= 7 then
			self.opponentIndex = 1
		end
	elseif #self.opponentArr >= 9 and self.opponentIndex >= 10 then
		self.opponentIndex = 1
	end

	print("test:", self.opponentIndex)

	return tempArr
end

function ActivitySpfarmData:checkHasOpponentArr()
	if self.opponentArr and #self.opponentArr >= 3 then
		return true
	end

	return false
end

function ActivitySpfarmData:reqRecord()
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.RECORD
	}))
end

function ActivitySpfarmData:endRob()
	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
		type = xyd.ActivitySpfarmType.END_ROB
	}))
end

function ActivitySpfarmData:reqRankList()
	if not self.reqRankTime or xyd.getServerTime() - self.reqRankTime > 60 then
		self.reqRankTime = xyd.getServerTime()

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.RANK_LIST
		}))

		return true
	else
		return false
	end
end

function ActivitySpfarmData:getRankList()
	return self.rankList_ or {}
end

function ActivitySpfarmData:reqFriendRank()
	if not self.reqRankTime2 or xyd.getServerTime() - self.reqRankTime2 > 60 then
		self.reqRankTime2 = xyd.getServerTime()
		local friendList = xyd.models.friend:getFriendList() or {}
		local reqList = {}

		for _, info in ipairs(friendList) do
			table.insert(reqList, info.player_id)
		end

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SPFARM, json.encode({
			type = xyd.ActivitySpfarmType.RANK_LIST_FRIEND,
			player_ids = reqList
		}))

		return true
	else
		return false
	end
end

function ActivitySpfarmData:getRankFriend()
	return self.rankFriend_ or {}
end

function ActivitySpfarmData:getSlotsRob()
	return self.detail.slots_rob
end

function ActivitySpfarmData:getTreeBuildId()
	return 2
end

function ActivitySpfarmData:checkIsOnlyBuildId2IsOne()
	local build2num = 0

	for i, buildInfo in pairs(self.detail.build_infos) do
		if buildInfo.build_id == self:getTreeBuildId() then
			build2num = build2num + 1
		end
	end

	if build2num == 1 then
		return true
	end

	return false
end

function ActivitySpfarmData:isViewing()
	if xyd.getServerTime() < self:getEndTime() and xyd.getServerTime() >= self:getEndTime() - self:getViewTimeSec() then
		return true
	end

	return false
end

function ActivitySpfarmData:isEnd()
	if self:getEndTime() <= xyd.getServerTime() then
		return true
	end

	return false
end

function ActivitySpfarmData:checkCanAddPolicy()
	local level = self:getFamousNum()
	local policy_level = nil

	if level >= 15 then
		policy_level = level
	else
		policy_level = level + 1
	end

	local policyIds = xyd.tables.activitySpfarmPolicyTable:getFamousWithIds()[policy_level]
	local policyData = self.detail_.policys
	local canAdd = false

	for i = 1, 3 do
		local params = {}
		local policy_id = policyIds[i]
		local level = policyData[policy_id]
		local cost = xyd.tables.activitySpfarmPolicyTable:getCost(policy_id)

		if (not level or level < 1) and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			canAdd = true

			break
		end
	end

	return canAdd
end

function ActivitySpfarmData:getViewTimeDay()
	return xyd.tables.miscTable:split2num("activity_spfarm_time", "value", "|")[2]
end

function ActivitySpfarmData:getViewTimeSec()
	return xyd.DAY_TIME * self:getViewTimeDay()
end

function ActivitySpfarmData:getCurTimeDay()
	local disTime = xyd.getServerTime() - self:startTime()
	local day = math.ceil(disTime / xyd.DAY_TIME)

	return day
end

function ActivitySpfarmData:isGridAllEmpty()
	local robMap = self:getMapRob()

	if xyd.arrayIndexOf(robMap, -1) > 0 then
		return false
	end

	local robBuilds = self:getBuildRob()

	for i = 2, #robBuilds do
		local buildId = robBuilds[i].build_id
		local outCome = xyd.tables.activitySpfarmBuildingTable:getOutcome(buildId)

		if outCome and #outCome > 0 then
			if not robBuilds[i].is_rob or robBuilds[i].is_rob ~= 1 then
				return false
			end
		end
	end

	return true
end

return ActivitySpfarmData
