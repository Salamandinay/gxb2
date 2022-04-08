local Shrine = class("Shrine", import(".BaseModel"))
local chimeTable = xyd.tables.chimeTable

function Shrine:ctor()
	Shrine.super.ctor(self)

	self.chimeInfo = {}
	self.achievements = {}
	self.missions_ = {}
	self.ranks = {}
	self.awards = {}
	local ids = chimeTable:getIDs()

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if not self.chimeInfo[id] then
			self.chimeInfo[id] = {
				lev = -1,
				chime_id = id,
				buffs = {
					0,
					0,
					0,
					0
				}
			}
		end
	end
end

function Shrine:onRegister()
	Shrine.super.onRegister(self)
	self:registerEvent(xyd.event.GET_CHIME_INFO, handler(self, self.onGetMsgInfo))
	self:registerEvent(xyd.event.ACTIVE_CHIME, handler(self, self.onGetMsgUnlock))
	self:registerEvent(xyd.event.LEV_UP_CHIME, handler(self, self.onGetMsgLevelUp))
	self:registerEvent(xyd.event.ACTIVE_CHIME_BUFF, handler(self, self.onGetMsgActive))
	self:registerEvent(xyd.event.EXCHANGE_CHIME_PIECE, handler(self, self.onGetMsgExchangePiece))
	self:registerEvent(xyd.event.GET_SHRINE_ACHIEVEMENT_AWARD, handler(self, self.onGetAchieveAward))
	self:registerEvent(xyd.event.GET_SHRINE_ACHIEVEMENT_LIST, handler(self, self.onGetAchieveData))
	self:registerEvent(xyd.event.GET_SHRINE_MISSION_INFO, handler(self, self.onGetMissionData))
	self:registerEvent(xyd.event.GET_SHRINE_MISSION_AWARD, handler(self, self.onGetMissionAward))
	self:registerEvent(xyd.event.SHRINE_HURDLE_GET_RANK_LIST, handler(self, self.onGetRankList))
	self:registerEvent(xyd.event.RED_POINT, handler(self, self.onRedPoint))
end

function Shrine:getChimeAttrByHeros(heros)
end

function Shrine:getChimeAttr(hero)
	return xyd.models.heroAttr:getChimeAttr(hero, self.chimeInfo)
end

function Shrine:refreshShopInfo(type)
	if type == 2 then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHRINE1)
	else
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHRINE2)
	end
end

function Shrine:getShopData(type)
	local items = {}
	local shopType = xyd.ShopType.SHRINE2
	local theTable = xyd.tables.shopShrine2Table

	if type == 2 then
		shopType = xyd.ShopType.SHRINE1
		theTable = xyd.tables.shopShrine1Table
	end

	local modeInfo = xyd.models.shop:getShopInfo(shopType)
	local ids = theTable:getIds()

	if modeInfo.items then
		for i = 1, #ids do
			local limitTime = theTable:getBuyTime(i)
			local buyTime = modeInfo.items[i].buy_times or 0
			local data = {
				index = i,
				limitTime = limitTime,
				leftTime = limitTime - buyTime,
				cost = theTable:getCost(i),
				item = theTable:getItem(i),
				shopType = shopType
			}

			table.insert(items, data)
		end
	end

	return items
end

function Shrine:onGetMissionAward(event)
	local mission_id = event.data.id

	for _, data in ipairs(self.missions_) do
		if mission_id == data.mission_id then
			data.is_awarded = 1

			break
		end
	end

	self:sortMission()

	if event.data and tostring(event.data) ~= nil then
		xyd.models.itemFloatModel:pushNewItems(event.data.items)
	end

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.UPDATE_SHRINE_NOTICE,
		params = {
			tag = xyd.ShrineNoticeTag.MISSION
		}
	})
end

function Shrine:getMissionData()
	local msg = messages_pb.get_shrine_mission_info_req()

	xyd.Backend.get():request(xyd.mid.GET_SHRINE_MISSION_INFO, msg)
end

function Shrine:getMissionAward(id)
	local msg = messages_pb.get_shrine_mission_award_req()
	msg.id = id

	xyd.Backend.get():request(xyd.mid.GET_SHRINE_MISSION_AWARD, msg)
end

function Shrine:onGetRankList(event)
	local params = event.data
	local rankType = params.id

	if not self.ranks[rankType] then
		self.ranks[rankType] = {}
	end

	local infos = {}

	if params.self_rank then
		infos.rank = params.self_rank + 1
	else
		infos.rank = 0
	end

	infos.score = params.self_score or 0
	infos.id = rankType
	infos.list = {}
	local index = 0

	for i = 1, #params.list do
		local list = params.list[i]
		local dress_style = {}

		for k, v in ipairs(list.dress_style) do
			table.insert(dress_style, v)
		end

		if list.score > 0 then
			index = index + 1
			infos.list[i] = {
				score = list.score,
				player_name = list.player_name,
				avatar_id = list.avatar_id,
				avatar_frame_id = list.avatar_frame_id,
				lev = list.lev,
				player_id = list.player_id,
				time = list.time,
				server_id = list.server_id,
				dress_style = dress_style,
				rank = index
			}
		end
	end

	self.ranks[rankType] = infos

	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.UPDATE_SHRINE_NOTICE,
		params = {
			tag = xyd.ShrineNoticeTag.RANK,
			type = rankType
		}
	})
end

function Shrine:onGetMissionData(event)
	self.missions_ = {}
	local datas = event.data

	for k, v in ipairs(datas.awards) do
		local mission = {
			mission_id = k,
			is_completed = datas.mission_completes[k] or 0,
			is_awarded = v,
			value = datas.mission_values[k] or 0
		}

		table.insert(self.missions_, mission)
	end

	self:sortMission()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.UPDATE_SHRINE_NOTICE,
		params = {
			tag = xyd.ShrineNoticeTag.MISSION
		}
	})
end

function Shrine:getRankName(index)
	local count = xyd.models.shrineHurdleModel:getCount()
	count = math.fmod(count - 1, 3) + 1
	local routeId = xyd.tables.shrineHurdleRouteTable:getEnviroment(index, count)[1]

	return xyd.tables.shrineHurdleRouteTextTable:getTitle(routeId) or ""
end

function Shrine:getRankList(type)
	return self.ranks[type] or {
		score = 0,
		rank = 0,
		list = {}
	}
end

function Shrine:getAwardsList(type)
	if not self.awards[type] then
		self.awards[type] = {}
		local ids = xyd.tables.shrineHurdleRankTable:getIDs()

		for k, v in ipairs(ids) do
			table.insert(self.awards[type], {
				id = k,
				selectType = type
			})
		end
	end

	return self.awards[type]
end

function Shrine:getMissions()
	return self.missions_
end

function Shrine:sortMission()
	table.sort(self.missions_, function (a, b)
		local ranka = a.mission_id
		local rankb = b.mission_id

		if ranka and rankb then
			local weight_a = a.is_awarded * 100 + (1 - a.is_completed) * 10 + ranka / 100
			local weight_b = b.is_awarded * 100 + (1 - b.is_completed) * 10 + rankb / 100

			return weight_a < weight_b
		elseif ranka and not rankb then
			return false
		elseif not ranka and rankb then
			return true
		else
			if a.is_completed == 1 and b.is_completed ~= 1 then
				return false
			elseif a.is_completed ~= 1 and b.is_completed == 1 then
				return true
			end

			return false
		end
	end)
	self:updateNoticeRedPoint(1)
end

function Shrine:getAchieveData()
	local msg = messages_pb.get_shrine_achievement_list_req()

	xyd.Backend.get():request(xyd.mid.GET_SHRINE_ACHIEVEMENT_LIST, msg)
end

function Shrine:getAchievementList()
	return self.achievements
end

function Shrine:onGetAchieveData(event)
	self.achievements = {}
	local achievements = event.data.achievements
	local a_t = xyd.tables.shrineAchievementTable

	for _, info in pairs(achievements) do
		local achievement = {
			achieve_id = 0,
			sub_value = 0,
			achieve_type = 0,
			value = 0
		}

		for hashkey, _ in pairs(achievement) do
			achievement[hashkey] = info[hashkey]
		end

		if achievement.achieve_id == 0 or a_t:hasID(achievement.achieve_id) then
			table.insert(self.achievements, achievement)
		end
	end

	self:sortAchievement()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.UPDATE_SHRINE_NOTICE,
		params = {
			tag = xyd.ShrineNoticeTag.ACHIEVE
		}
	})
end

function Shrine:getRankListData(type_id)
	local msg = messages_pb.shrine_hurdle_get_rank_list_req()
	msg.id = type_id

	xyd.Backend.get():request(xyd.mid.SHRINE_HURDLE_GET_RANK_LIST, msg)
end

function Shrine:getAchieveAward(type_id)
	local msg = messages_pb.get_shrine_achievement_award_req()
	msg.achievement_type = type_id

	xyd.Backend.get():request(xyd.mid.GET_SHRINE_ACHIEVEMENT_AWARD, msg)
end

function Shrine:onGetAchieveAward(event)
	local achievement_info = event.data

	for key, _ in pairs(self.achievements) do
		if achievement_info.achieve_type == self.achievements[key].achieve_type then
			self.achievements[key].achieve_id = achievement_info.achieve_id

			break
		end
	end

	self:sortAchievement()
	xyd.EventDispatcher.inner():dispatchEvent({
		name = xyd.event.SHRINE_ACHIEVEMENT_GET_AWARD,
		params = event
	})
end

function Shrine:sortAchievement()
	local a_t = xyd.tables.shrineAchievementTable
	local b_t = xyd.tables.shrineAchievementTypeTable

	table.sort(self.achievements, function (a, b)
		local all_done_a = a.achieve_id == 0 and 1 or 0
		local all_done_b = b.achieve_id == 0 and 1 or 0
		local aValue = a_t:getCompleteValue(a.achieve_id) or 0
		local bValue = a_t:getCompleteValue(b.achieve_id) or 0
		local not_completed_a = a.value < aValue and 1 or 0
		local not_completed_b = b.value < bValue and 1 or 0
		local rank_a = b_t:getShowRank(a.achieve_type) or 0
		local rank_b = b_t:getShowRank(b.achieve_type) or 0
		local rank_done_a = b_t:getShowRankDone(a.achieve_type)
		local rank_done_b = b_t:getShowRankDone(b.achieve_type)

		if all_done_a ~= all_done_b then
			return all_done_a < all_done_b
		elseif not_completed_a ~= not_completed_b then
			return not_completed_a < not_completed_b
		elseif all_done_a == 1 then
			return rank_done_a < rank_done_b
		else
			return rank_a < rank_b
		end
	end)
	self:updateNoticeRedPoint(2)
end

function Shrine:reqChimeInfo()
	local msg = messages_pb:get_chime_info_req()

	xyd.Backend.get():request(xyd.mid.GET_CHIME_INFO, msg)
end

function Shrine:onGetMsgInfo(event)
	local data = event.data
	local infos = data.results

	dump(data.results)

	for i = 1, #infos do
		local info = infos[i]

		dump(info)

		self.chimeInfo[tonumber(info.chime_id)] = info
	end

	self:updateRedPoint()
end

function Shrine:onGetMsgUnlock(event)
	local data = event.data
	self.chimeInfo[data.chime_id] = data
end

function Shrine:onGetMsgLevelUp(event)
	local data = event.data
	self.chimeInfo[data.chime_id].lev = data.lev
end

function Shrine:onGetMsgActive(event)
	local data = event.data
	self.chimeInfo[data.chime_id] = data
end

function Shrine:onGetMsgExchangePiece(event)
	local data = event.data
end

function Shrine:getChimeInfo()
	return self.chimeInfo
end

function Shrine:getChimeInfoByTableID(tableID)
	return self.chimeInfo[tonumber(tableID)]
end

function Shrine:updateRedPoint()
	local flag = false
	flag = flag or self:updateChimeRedPoint()

	return flag
end

function Shrine:updateChimeRedPoint()
	local flag = false

	for chimeID, info in pairs(self.chimeInfo) do
		local unlockCost = xyd.tables.chimeTable:getUnlock(chimeID)

		if info.lev < 0 and unlockCost[2] <= xyd.models.backpack:getItemNumByID(unlockCost[1]) then
			flag = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.SHRINE_CHIME, flag)

	return flag
end

function Shrine:onRedPoint(event)
	if not xyd.Global.isLoadingFinish then
		return
	end

	local funID = event.data.function_id

	if funID ~= xyd.FunctionID.SHRINE_HURDLE then
		return
	end

	if event.data.value ~= -1 then
		self.needAchieve = true
	else
		self.needAchieve = false
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.SHRINE_NOTICE, true)
end

function Shrine:getRedType()
	local type = 0

	if not xyd.models.redMark:getRedState(xyd.RedMarkType.SHRINE_NOTICE) then
		return type
	end

	if self.needAchieve then
		return 1
	end
end

function Shrine:updateNoticeRedPoint(type)
	self.needAchieve = false
	local flag = false

	for k, v in ipairs(self.missions_) do
		if v.is_completed == 1 and v.is_awarded ~= 1 then
			flag = true

			break
		end
	end

	if not flag then
		local a_t = xyd.tables.shrineAchievementTable

		for k, v in ipairs(self.achievements) do
			local complete_value = a_t:getCompleteValue(v.achieve_id) or 0

			if v.achieve_id ~= 0 and complete_value <= v.value then
				flag = true
				self.needAchieve = true

				break
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.SHRINE_NOTICE, flag)
end

return Shrine
