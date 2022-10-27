local MapsModel = class("MapsModel", import("app.models.BaseModel"))
local ItemInfo = import("app.models.ItemInfo")
local TeamFormation = import("app.models.TeamFormation")

function MapsModel:ctor(...)
	MapsModel.super.ctor(self, ...)

	self.infos_ = {}
	self.isRefreshHang_ = false
	self.mapList_ = {}
	self.mapRankList_ = {}
end

function MapsModel:onRegister()
	self:registerEvent(xyd.event.GET_MAP_INFO, handler(self, self.onMapsInfo))
	self:registerEvent(xyd.event.STAGE_HANG, handler(self, self.onMapsInfo))
	self:registerEvent(xyd.event.MAP_FIGHT, handler(self, self.onFightResult))
	self:registerEvent(xyd.event.GET_MAP_RANK, handler(self, self.onMapRank))
	self:registerEvent(xyd.event.GET_MAP_HANG_ITEMS_INFO, handler(self, self.onMapHangItemsInfo))
	self:registerEvent(xyd.event.GET_HANG_ITEM, handler(self, self.onGetHangItems))
	self:registerEvent(xyd.event.SET_HANG_TEAM, handler(self, self.onSetHangTeam))
	self:registerEvent(xyd.event.FRIEND_GET_RANK, handler(self, self.onFriendRank))
	self:registerEvent(xyd.event.GET_FAIRY_RANK_LIST, handler(self, self.onFairyRank))
	self:registerEvent(xyd.event.LIMIT_GACHA_BOSS_ACTIVITY_GET_RANK_LIST, handler(self, self.onLimitCallBossRank))
	self:registerEvent(xyd.event.GET_SOUL_LAND_MAP_RANK, handler(self, self.onSoulLandMapRank))
end

function MapsModel:populate(params)
end

function MapsModel:reqMapInfo(map_type)
	local msg = messages_pb.get_map_info_req()
	msg.map_type = map_type

	xyd.Backend.get():request(xyd.mid.GET_MAP_INFO, msg)
end

function MapsModel:hang(stageId)
	local msg = messages_pb.stage_hang_req()
	msg.stage_id = tonumber(stageId)

	xyd.Backend.get():request(xyd.mid.STAGE_HANG, msg)
end

function MapsModel:getHangItem(itemType)
	local msg = messages_pb.get_hang_item_req()
	msg.item_type = tonumber(itemType)

	xyd.Backend.get():request(xyd.mid.GET_HANG_ITEM, msg)
end

function MapsModel:getRank(mapType)
	if mapType == xyd.MapType.FRIEND_RANK then
		xyd.Backend.get():request(xyd.mid.FRIEND_GET_RANK)
	elseif mapType == xyd.MapType.ACTIVITY_FAIRT_TALE then
		local msg = messages_pb.get_fairy_rank_list_req()
		msg.activity_id = xyd.ActivityID.FAIRY_TALE

		xyd.Backend.get():request(xyd.mid.GET_FAIRY_RANK_LIST, msg)
	elseif mapType == xyd.MapType.LIMIT_CALL_BOSS then
		local msg = messages_pb.limit_gacha_boss_activity_get_rank_list_req()
		msg.activity_id = xyd.ActivityID.LIMIT_CALL_BOSS

		xyd.Backend.get():request(xyd.mid.LIMIT_GACHA_BOSS_ACTIVITY_GET_RANK_LIST, msg)
	elseif mapType == xyd.MapType.SOUL_LAND then
		local msg = messages_pb.get_soul_land_map_rank_req()

		xyd.Backend.get():request(xyd.mid.GET_SOUL_LAND_MAP_RANK, msg)
	else
		local msg = messages_pb:get_map_rank_req()
		msg.map_type = tonumber(mapType)

		xyd.Backend.get():request(xyd.mid.GET_MAP_RANK, msg)
	end
end

function MapsModel:getMapHangItemsInfo()
	xyd.Backend.get():request(xyd.mid.GET_MAP_HANG_ITEMS_INFO)
end

function MapsModel:setHangTeam(teamFormation)
	local msg = messages_pb.set_hang_team_req()

	for _, teamInfo in pairs(teamFormation) do
		local teamMsg = messages_pb.team_formation()
		teamMsg.partner_id = teamInfo.partner_id
		teamMsg.pos = teamInfo.pos

		table.insert(msg.partners, teamMsg)
	end

	xyd.Backend.get():request(xyd.mid.SET_HANG_TEAM, msg)
end

function MapsModel:onMapsInfo(event)
	local params = event.data

	if self.mapList_[params.map_type] == nil then
		self.mapList_[params.map_type] = {}
	end

	local mapInfo = {
		map_type = params.map_type
	}
	local updateMainActivityEnter = false

	if self:getMapInfo(xyd.MapType.CAMPAIGN) and self:getMapInfo(xyd.MapType.CAMPAIGN).max_stage and params.max_stage and self:getMapInfo(xyd.MapType.CAMPAIGN).max_stage < params.max_stage then
		updateMainActivityEnter = true
	end

	mapInfo.max_stage = params.max_stage
	mapInfo.current_stage = params.current_stage
	mapInfo.hang_time = params.hang_time
	mapInfo.first_hang_time = params.first_hang_time
	mapInfo.max_hang_stage = params.max_hang_stage
	mapInfo.drop_hang_time = params.drop_hang_time
	mapInfo.drop_award_time = params.drop_award_time
	mapInfo.economy_items = {}
	mapInfo.drop_items = {}
	mapInfo.hang_team = {}

	for i = 1, #params.economy_items do
		table.insert(mapInfo.economy_items, ItemInfo.new(params.economy_items[i]))
	end

	for i = 1, #params.drop_items do
		table.insert(mapInfo.drop_items, ItemInfo.new(params.drop_items[i]))
	end

	for i = 1, #params.hang_team do
		table.insert(mapInfo.hang_team, TeamFormation.new(params.hang_team[i]))
	end

	self.mapList_[params.map_type] = mapInfo

	if mapInfo.map_type == xyd.MapType.CAMPAIGN then
		local hangTeam = mapInfo.hang_team

		if hangTeam and #hangTeam >= 1 then
			local hangPartner = hangTeam[1]

			if not hangPartner.partner_id then
				local num = math.min(3, #hangTeam)
				local setHangTeamParams = {}

				for i = 1, num do
					if hangTeam[i] >= 0 then
						table.insert(setHangTeamParams, {
							partner_id = hangTeam[i],
							pos = i + 1
						})
					end
				end

				self:setHangTeam(setHangTeamParams)
			end
		end
	end

	if self.isRefreshHang_ then
		self:checkHangTeam()
	end

	if updateMainActivityEnter then
		xyd.models.activity:updateNeedOpenActivityAloneEnter(xyd.AcitvityLimt.STAGE, params.max_stage)
	end

	if params.map_type == xyd.MapType.CAMPAIGN then
		local data = {
			name = xyd.event.UPDATE_MAX_SATGE_TO_UPDATE_FUNCTION_OPEN,
			params = {}
		}

		xyd.EventDispatcher.outer():dispatchEvent(data)
	end
end

function MapsModel:checkHangTeam()
	local mapInfo = self:getMapInfo(xyd.MapType.CAMPAIGN)

	if xyd.Global.playerID % 3 ~= 1 or not xyd.GuideController.get():isGuideComplete() or mapInfo.max_stage > 10 then
		self.isRefreshHang_ = false

		return
	end

	self.isRefreshHang_ = false
	local unLockNum = 3
	local selectedList = {}
	local selectedPosList = mapInfo.hang_team or {}

	for i = 1, #selectedPosList do
		if selectedPosList[i].partner_id then
			table.insert(selectedList, selectedPosList[i].partner_id)
		else
			table.insert(selectedList, selectedPosList[i])
		end
	end

	for i = #selectedList, 1, -1 do
		local sPartnerID = tonumber(selectedList[i + 1])

		if not xyd.models.slot:getPartner(sPartnerID) then
			table.remove(selectedList, i)
		end
	end

	if unLockNum > #selectedList then
		local needNum = unLockNum - #selectedList
		local maxpower = 0
		local selects = {}
		local partners = xyd.models.slot:getPartners()

		for id in pairs(partners) do
			if xyd.tableContains(selectedList, tonumber(id)) then
				if needNum > #selects then
					table.insert(selects, partners[id])
				else
					table.sort(selects, function (a, b)
						return a:getPower() - b:getPower()
					end)

					if selects[1]:getPower() < partners[id]:getPower() then
						selects[1] = partners[id]
					end
				end
			end
		end

		if #selects > 0 then
			selectedList = {}

			for i = 1, #selects do
				local partner = selects[i + 1]

				table.insert(selectedList, {
					partner_id = partner:getPartnerID(),
					pos = i + 1
				})
			end

			self:setHangTeam(selectedList)
		end
	end
end

function MapsModel:onFightResult(event)
	local is_win = event.data.is_win

	if is_win == 1 then
		self:reqMapInfo(1)

		self.isRefreshHang_ = true
		local stageId = event.data.stage_id

		if stageId then
			local fortId = xyd.tables.stageTable:getFortID(stageId)
			local stageName = xyd.tables.stageTable:getName(stageId)
			local trackStr = "stage_" .. fortId .. "_" .. stageName
			local trackList = {
				"stage_1_9",
				"stage_3_6",
				"stage_5_2",
				"stage_7_2",
				"stage_10_3",
				"stage_13_7",
				"stage_17_7"
			}
			local index = xyd.arrayIndexOf(trackList, trackStr)

			if index > -1 then
				xyd.SdkManager.get():eventTracking(trackStr)
			end

			if stageId == 6 then
				xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_SIMULATION_GACHA)
			end
		end
	end
end

function MapsModel:onMapRank(event)
	local params = event.data

	if self.mapRankList_[params.map_type] == nil then
		self.mapRankList_[params.map_type] = {}
	end

	local infos = {
		rank = params.rank,
		score = params.score,
		map_type = params.map_type,
		list = {}
	}

	for i = 1, #params.list do
		local list = params.list[i]
		infos.list[i] = {
			score = list.score,
			player_name = list.player_name,
			avatar_id = list.avatar_id,
			avatar_frame_id = list.avatar_frame_id,
			lev = list.lev,
			player_id = list.player_id,
			time = list.time,
			mapType = params.map_type,
			rank = i
		}
	end

	self.mapRankList_[params.map_type] = infos
end

function MapsModel:onSoulLandMapRank(event)
	local params = event.data

	if self.mapRankList_[xyd.MapType.SOUL_LAND] == nil then
		self.mapRankList_[xyd.MapType.SOUL_LAND] = {}
	end

	local infos = {
		rank = params.rank,
		score = params.score,
		map_type = xyd.MapType.SOUL_LAND,
		list = {}
	}

	for i = 1, #params.list do
		local list = params.list[i]
		infos.list[i] = {
			score = list.score,
			player_name = list.player_name,
			avatar_id = list.avatar_id,
			avatar_frame_id = list.avatar_frame_id,
			lev = list.lev,
			player_id = list.player_id,
			time = list.time,
			mapType = params.map_type,
			rank = i
		}
	end

	self.mapRankList_[xyd.MapType.SOUL_LAND] = infos
end

function MapsModel:onFriendRank(event)
	local params = event.data

	if self.mapRankList_[xyd.MapType.FRIEND_RANK] == nil then
		self.mapRankList_[xyd.MapType.FRIEND_RANK] = {}
	end

	local data = {
		score = params.score,
		rank = params.rank,
		list = {}
	}

	for i = 1, #params.list do
		data.list[i] = {
			mapType = xyd.MapType.FRIEND_RANK,
			rank = i,
			score = params.list[i].score,
			player_name = params.list[i].player_name,
			avatar_id = params.list[i].avatar_id,
			avatar_frame_id = params.list[i].avatar_frame_id,
			lev = params.list[i].lev,
			player_id = params.list[i].player_id
		}
	end

	self.mapRankList_[xyd.MapType.FRIEND_RANK] = data
end

function MapsModel:onFairyRank(event)
	local params = event.data.rank_list

	if self.mapRankList_[xyd.MapType.ACTIVITY_FAIRT_TALE] == nil then
		self.mapRankList_[xyd.MapType.ACTIVITY_FAIRT_TALE] = {}
	end

	local data = {
		list = {}
	}

	for i = 1, #params do
		local player = {
			score = params[i].score,
			player_id = params[i].player_id,
			rank = i,
			avatar_id = params[i].avatar_id,
			avatar_frame_id = params[i].avatar_frame_id,
			player_name = params[i].player_name,
			lev = params[i].lev,
			server_id = params[i].server_id
		}

		table.insert(data.list, player)
	end

	data.rank = event.data.rank
	self.mapRankList_[xyd.MapType.ACTIVITY_FAIRT_TALE] = data
end

function MapsModel:onLimitCallBossRank(event)
	local params = event.data.list

	if self.mapRankList_[xyd.MapType.LIMIT_CALL_BOSS] == nil then
		self.mapRankList_[xyd.MapType.LIMIT_CALL_BOSS] = {}
	end

	local data = {
		list = {}
	}

	for i = 1, #params do
		local player = {
			score = params[i].score,
			player_id = params[i].player_id,
			rank = i,
			avatar_id = params[i].avatar_id,
			avatar_frame_id = params[i].avatar_frame_id,
			player_name = params[i].player_name,
			lev = params[i].lev,
			server_id = params[i].server_id
		}

		table.insert(data.list, player)
	end

	data.rank = event.data.self_rank
	data.score = event.data.self_score
	self.mapRankList_[xyd.MapType.LIMIT_CALL_BOSS] = data
end

function MapsModel:onMapHangItemsInfo(event)
	local params = event.data
	local mapType = params.map_type

	if self.mapList_[mapType] == nil then
		self.mapList_[mapType] = {}
	end

	local dropItems = {}
	local economyItems = {}

	for i = 1, #params.economy_items do
		table.insert(economyItems, ItemInfo.new(params.economy_items[i]))
	end

	for i = 1, #params.drop_items do
		table.insert(dropItems, ItemInfo.new(params.drop_items[i]))
	end

	self.mapList_[mapType].drop_items = dropItems
	self.mapList_[mapType].economy_items = economyItems
end

function MapsModel:onGetHangItems(event)
	local params = event.data
	local item_type = params.item_type

	if item_type == xyd.CampaignHangItemType.ECONOMY_ITEMS then
		self.mapList_[xyd.MapType.CAMPAIGN].economy_items = {}
		local time = xyd.getServerTime() + xyd.tables.deviceNotifyTable:getDelayTime(xyd.DEVICE_NOTIFY.CAMPAIGN_GET_EXP)

		xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.CAMPAIGN_GET_EXP, time)
	else
		self.mapList_[xyd.MapType.CAMPAIGN].drop_items = {}
	end
end

function MapsModel:onSetHangTeam(event)
	local params = event.data
	local hangTeam = {}

	for k, team_formation in ipairs(params.hang_team) do
		local data = {
			partner_id = team_formation.partner_id,
			pos = team_formation.pos
		}

		table.insert(hangTeam, data)
	end

	self.mapList_[xyd.MapType.CAMPAIGN].hang_team = hangTeam
end

function MapsModel:getMapInfo(mapType)
	return self.mapList_[mapType] or nil
end

function MapsModel:getMapRank(mapType)
	return self.mapRankList_[mapType] or nil
end

function MapsModel:resetMapRank(mapType)
	self.mapRankList_[mapType] = nil
end

function MapsModel:getSelfPlayerID()
	local playerModel = xyd.models.selfPlayer
	local playerID = playerModel:getPlayerID()

	return playerID
end

function MapsModel:getTeamPower()
	local hangPosTeam = self.mapList_[xyd.MapType.CAMPAIGN].hang_team
	local hangTeam = {}

	for i = 1, #hangPosTeam do
		if hangPosTeam[i].partner_id then
			table.insert(hangTeam, hangPosTeam[i].partner_id)
		else
			table.insert(hangTeam, hangPosTeam[i])
		end
	end

	local power = 0

	if not hangTeam or #hangTeam == 0 then
		return power
	end

	local SlotModel = xyd.models.slot

	for i = 1, #hangTeam do
		local partnerID = hangTeam[i]
		local p = SlotModel:getPartner(partnerID)

		if p then
			power = power + p:getPower()
		end
	end

	return power
end

function MapsModel:checkIsCampaignEnd()
	local mapInfo = self:getMapInfo(xyd.MapType.CAMPAIGN)

	if not mapInfo then
		return true
	end

	local maxStageID = xyd.tables.stageTable:getMaxID()

	if maxStageID <= mapInfo.max_stage then
		return true
	end

	local nextStageId = mapInfo.max_stage + 1
	local needLv = xyd.tables.stageTable:getLv(nextStageId)
	local playerLv = xyd.models.backpack:getLev()

	if needLv <= playerLv then
		return false
	else
		return true
	end
end

return MapsModel
