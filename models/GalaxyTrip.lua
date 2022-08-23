local BaseModel = import(".BaseModel")
local GalaxyTrip = class("GalaxyTrip", BaseModel, true)
local json = require("cjson")

function GalaxyTrip:ctor()
	BaseModel.ctor(self)

	self.ballInfoArr = {}
	self.timeArr = {}
	self.timeIndex = 1
end

function GalaxyTrip:onRegister()
	self:registerEvent(xyd.event.GALAXY_TRIP_GET_MAIN_INFO, self.onGetGalaxyTripGetMainBack, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_GET_MAP_INFO, self.onGetGalaxyTripMapInfoBack, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_SELECT_MAP, self.onGetGalaxyTripMapInfoBack, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_GET_MAP_AWARDS, self.onGetGalaxyTripMapAwardsBack, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_GRID_IDS, self.onGetGalaxyTripGridBack, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_SET_TEAMS, self.onSetGalaxyTripFormation, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_GET_RANK_LIST, self.onGetRankInfo, self)
	self:registerEvent(xyd.event.GALAXY_TRIP_STOP_BACK_GRID, self.onGalaxyTripStopBackGrid, self)
	self:registerEvent(xyd.event.FUNCTION_OPEN_MODEL, function (event)
		local funID = event.data.functionID

		if funID == xyd.FunctionID.GALAXY_TRIP then
			self:sendGalaxyTripGetMainBack()
		end
	end)
	BaseModel.onRegister(self)
end

function GalaxyTrip:getBossMapId()
	return 999
end

function GalaxyTrip:sendGalaxyTripGetMainBack()
	local msg = messages_pb:galaxy_trip_get_main_info_req()

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAIN_INFO, msg)
end

function GalaxyTrip:onGetGalaxyTripGetMainBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.mainInfo = data

	if self.mainInfo.next_time > 0 and self.mainInfo.map_id and self.mainInfo.map_id ~= 0 and self.ballInfoArr[self.mainInfo.map_id] == nil then
		self.needReqMainInfoAfterMapInfo = true
	end

	self:checkOpendWithAwards()

	if self.ballInfoArr[self.mainInfo.map_id] then
		self:checkNextTimeDeal()
	end

	self:updateMapShow()
	dump(self.mainInfo, "maininfo+==============")

	local curMapId = self.mainInfo.map_id

	if self.mainInfo.map_id > 0 and not self.ballInfoArr[curMapId] then
		local msg = messages_pb:galaxy_trip_get_map_info_req()
		msg.id = curMapId

		xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_INFO, msg)
	end
end

function GalaxyTrip:onGetGalaxyTripMapInfoBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.table_id then
		self.mainInfo.map_id = data.table_id
		self.mainInfo.ids = {}
		self.mainInfo.awards = {}

		if self.mainInfo.count == nil then
			self.mainInfo.count = 1
		end

		data = data.map_info
	end

	local ballId = data.id
	self.ballInfoArr[ballId] = data
	self.ballInfoArr[ballId].map = self:dealBallMapInfo(ballId, self.ballInfoArr[ballId].map)
	self.ballInfoArr[ballId].opened = require("cjson").decode(self.ballInfoArr[ballId].opened)

	if self.ballInfoArr[ballId].is_end == nil then
		self.ballInfoArr[ballId].is_end = 0
	end

	if self.ballInfoArr[ballId].is_boss == nil then
		self.ballInfoArr[ballId].is_boss = 0
	end

	if self.ballInfoArr[ballId].is_chest == nil then
		self.ballInfoArr[ballId].is_chest = 0
	end

	if self.ballInfoArr[ballId].chests == nil then
		self.ballInfoArr[ballId].chests = {}
	end

	if data.god_skills then
		self.ballInfoArr[ballId].god_skills = data.god_skills
	else
		self.ballInfoArr[ballId].god_skills = {}
	end

	if data.enemies then
		self.ballInfoArr[ballId].enemies = data.enemies

		for i in pairs(self.ballInfoArr[ballId].enemies) do
			self.ballInfoArr[ballId].enemies[i].status = require("cjson").decode(self.ballInfoArr[ballId].enemies[i].status)

			for k, info in pairs(self.ballInfoArr[ballId].enemies[i].status) do
				-- Nothing
			end
		end
	else
		self.ballInfoArr[ballId].enemies = nil
	end

	if self.ballInfoArr[ballId] and self.isSendGetBallMapInfoToOpenMap then
		self.isSendGetBallMapInfoToOpenMap = false

		self:openBallMapWindow(ballId)
	end

	self:checkNextTimeDeal()

	if self.needReqMainInfoAfterMapInfo then
		self.needReqMainInfoAfterMapInfo = false
		self.needDealNextTimeAfterMapInfoBack = true

		self:sendGalaxyTripGetMainBack()
	end

	self:checkRedPoint()
end

function GalaxyTrip:dealBallMapInfo(ballId, map)
	local newMap = {}
	self.ballInfoArr[ballId].posIdFromGridIdArr = {}
	local mapSize = xyd.tables.galaxyTripMapTable:getSize(ballId)

	for i in pairs(map) do
		local row = math.floor((i - 1) / mapSize[1]) + 1
		row = mapSize[2] + 1 - row

		if not newMap[row] then
			newMap[row] = {}
		end

		table.insert(newMap[row], {
			info = map[i],
			gridId = i
		})
	end

	local returnArr = {}

	for i, littleArr in pairs(newMap) do
		for k in pairs(littleArr) do
			table.insert(returnArr, littleArr[k])
		end
	end

	for i in pairs(returnArr) do
		self.ballInfoArr[ballId].posIdFromGridIdArr[returnArr[i].gridId] = i
	end

	return returnArr
end

function GalaxyTrip:getBallInfo(ballId)
	return self.ballInfoArr[ballId]
end

function GalaxyTrip:getPosIdFromGridId(ballId, gridId)
	return self.ballInfoArr[ballId].posIdFromGridIdArr[gridId]
end

function GalaxyTrip:openBallMapWindow(ballId)
	if self:getGalaxyTripGetCurMap() == ballId then
		if self.ballInfoArr[ballId] then
			xyd.WindowManager.get():openWindow("galaxy_trip_map_window", {
				ballId = ballId
			})
		else
			self.isSendGetBallMapInfoToOpenMap = true
			local msg = messages_pb:galaxy_trip_get_map_info_req()
			msg.id = ballId

			xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_INFO, msg)
		end
	else
		self.isSendGetBallMapInfoToOpenMap = true
		local msg = messages_pb:galaxy_trip_select_map_req()
		msg.table_id = ballId

		xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_SELECT_MAP, msg)
	end
end

function GalaxyTrip:getMainInfo()
	return self.mainInfo
end

function GalaxyTrip:getGalaxyTripGetMainAwards()
	return self.mainInfo.awards or {}
end

function GalaxyTrip:getGalaxyTripGetCurMap()
	return self.mainInfo.map_id
end

function GalaxyTrip:getGalaxyTripGetMaxMap()
	return self.mainInfo.max_id
end

function GalaxyTrip:addGalaxyTripGetMaxMap()
	__TRACE("加了幾次========")

	self.mainInfo.max_id = self.mainInfo.max_id + 1
end

function GalaxyTrip:getGalaxyTripGetMainIds()
	return self.mainInfo.ids or {}
end

function GalaxyTrip:getGalaxyTripGetMainNextTime()
	return self.mainInfo.next_time
end

function GalaxyTrip:getGalaxyTripGetMainScore()
	return self.mainInfo.score
end

function GalaxyTrip:setGalaxyTripGetMainNextTime(time)
	self.mainInfo.next_time = time

	self:checkNextTimeDeal()
end

function GalaxyTrip:getGalaxyTripGetMainTeamsInfo()
	return self.mainInfo.teams
end

function GalaxyTrip:getGalaxyTripGetMainTicket()
	return self.mainInfo.ticket
end

function GalaxyTrip:useGalaxyTripGetMainTicket()
	self.mainInfo.ticket = self.mainInfo.ticket - 1
end

function GalaxyTrip:getGalaxyTripGetMainCount()
	return self.mainInfo.count
end

function GalaxyTrip:getGalaxyTripEnemiesHpInfo(gridId)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
	local enemies = ballMapInfo.enemies

	if enemies then
		for i in pairs(enemies) do
			if enemies[i].id == gridId then
				return enemies[i]
			end
		end
	end

	return nil
end

function GalaxyTrip:setGalaxyTripEnemiesHpInfo(gridId, pos, statusInfo)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
	local enemies = ballMapInfo.enemies

	if enemies then
		local isSearchId = false

		for i in pairs(enemies) do
			if enemies[i].id == gridId then
				isSearchId = true
				local isSearchPos = false

				for k in pairs(enemies[i].status) do
					if tonumber(enemies[i].status[k].pos) == tonumber(pos) then
						isSearchPos = true
						enemies[i].status[k].hp = statusInfo.hp
					end
				end

				if not isSearchPos then
					table.insert(enemies[i].status, {
						pos = pos,
						hp = statusInfo.hp
					})
				end
			end
		end

		if not isSearchId then
			local status = {}

			table.insert(status, {
				pos = pos,
				hp = statusInfo.hp
			})
			table.insert(enemies, {
				id = gridId,
				status = status
			})
		end
	else
		enemies = {}
		local status = {}

		table.insert(status, {
			pos = pos,
			hp = statusInfo.hp
		})
		table.insert(enemies, {
			id = gridId,
			status = status
		})

		ballMapInfo.enemies = enemies
	end
end

function GalaxyTrip:removeGalaxyTripEnemiesHpInfo(gridId)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
	local enemies = ballMapInfo.enemies

	if enemies then
		local isSearchId = false

		for i in pairs(enemies) do
			if enemies[i].id == gridId then
				table.remove(enemies, i)

				break
			end
		end
	end
end

function GalaxyTrip:setFightWin(gridId)
	local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
	ballMapInfo.opened[tostring(gridId)] = "1#1"
end

function GalaxyTrip:getGalaxyTripGetMainIsBatch()
	if self.mainInfo.is_batch and self.mainInfo.is_batch == 1 and self:getGalaxyTripGetMainNextTime() <= xyd.getServerTime() then
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
		local ballOpened = ballMapInfo.opened
		local isAllGet = true
		local ids = self:getGalaxyTripGetMainIds()

		for i in pairs(ballOpened) do
			local isHasInIds = false

			for k in pairs(ids) do
				if tonumber(ids[k]) == tonumber(i) then
					isHasInIds = true
				end
			end

			if isHasInIds and type(ballOpened[i]) == "string" then
				local eventArr = xyd.split(ballOpened[i], "|", true)

				if eventArr and #eventArr > 0 then
					isAllGet = false

					break
				end

				local eventArr = xyd.split(ballOpened[i], "#", true)

				if eventArr and #eventArr > 0 then
					isAllGet = false

					break
				end
			end
		end

		if isAllGet then
			self.mainInfo.is_batch = 0
		end
	end

	return self.mainInfo.is_batch
end

function GalaxyTrip:getGridState(gridId, ballId)
	local mapInfo = self:getBallInfo(ballId)
	local opened = mapInfo.opened

	if opened[tostring(gridId)] then
		local idsArr = self:getGalaxyTripGetMainIds()

		if type(opened[tostring(gridId)]) == "number" then
			return xyd.GalaxyTripGridStateType.GET_YET
		else
			local isSearch = false

			for i in pairs(idsArr) do
				if idsArr[i] == gridId then
					isSearch = true
				end
			end

			if not isSearch then
				return xyd.GalaxyTripGridStateType.CAN_GET
			end
		end

		local awardsArr = self:getGalaxyTripGetMainAwards()

		for i in pairs(idsArr) do
			if idsArr[i] == gridId then
				if awardsArr[i] == nil and i == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 0 then
					return xyd.GalaxyTripGridStateType.SEARCH_ING
				elseif awardsArr[i] == 1 then
					return xyd.GalaxyTripGridStateType.CAN_GET
				elseif awardsArr[i] == 0 then
					return xyd.GalaxyTripGridStateType.NO_OPEN
				end
			end
		end

		return xyd.GalaxyTripGridStateType.NO_OPEN
	else
		local idsArr = self:getGalaxyTripGetMainIds()
		local awardsArr = self:getGalaxyTripGetMainAwards()

		for i in pairs(idsArr) do
			if idsArr[i] == gridId then
				if xyd.getServerTime() <= self:getGalaxyTripGetMainNextTime() then
					if awardsArr[i] == nil and i == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 0 then
						return xyd.GalaxyTripGridStateType.SEARCH_ING
					end

					return xyd.GalaxyTripGridStateType.NOT_YET_SEARCH
				elseif awardsArr[1] == nil then
					return xyd.GalaxyTripGridStateType.NO_OPEN
				end
			end
		end
	end

	return xyd.GalaxyTripGridStateType.NO_OPEN
end

function GalaxyTrip:onGetGalaxyTripGridBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	local ids = data.ids
	local next_time = data.next_time
	self.mainInfo.ids = ids
	self.mainInfo.awards = {}

	if data.is_batch then
		self.mainInfo.is_batch = data.is_batch
	end

	self:setGalaxyTripGetMainNextTime(next_time)
	xyd.WindowManager.get():closeWindow("galaxy_trip_common_event_window")
	xyd.WindowManager.get():closeWindow("galaxy_trip_buff_window")
end

function GalaxyTrip:checkNextTimeDeal()
	local disTime = tonumber(self.mainInfo.next_time - xyd.getServerTime())
	local cloneTimeIndex = self.timeIndex
	local cloneTimeArr = xyd.cloneTable(self.timeArr)

	for i = 1, cloneTimeIndex do
		if cloneTimeArr[i] and cloneTimeArr[i] ~= -1 then
			xyd.removeGlobalTimer(cloneTimeArr[i])

			cloneTimeArr[i] = -1
		end
	end

	if disTime > 0 then
		self.timeIndex = self.timeIndex + 1
		local nextGolbalTimerKey = xyd.addGlobalTimer(function ()
			local idsArr = self:getGalaxyTripGetMainIds()
			local awardsArr = self:getGalaxyTripGetMainAwards()

			for i in pairs(idsArr) do
				self:checkOpendWithAwards()
				print("回來了")

				if awardsArr[i] == nil and i == 1 or awardsArr[i] == nil and awardsArr[i - 1] == 1 then
					print("置入了1")

					awardsArr[i] = 1
					self.ballInfoArr[self:getGalaxyTripGetCurMap()].opened[tostring(idsArr[i])] = "1#1"

					self:checkOpendWithAwards()

					if idsArr[i + 1] ~= nil and awardsArr[i + 1] == nil then
						local nextGridId = idsArr[i + 1]
						local nextPosId = self:getPosIdFromGridId(self:getGalaxyTripGetCurMap(), nextGridId)
						local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
						local ballMap = ballMapInfo.map
						local eventArr = xyd.split(ballMap[nextPosId].info, "#", true)
						local eventId = eventArr[1]
						local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)
						local needTime = xyd.tables.galaxyTripEventTypeTable:getTime(eventType)

						self:setGalaxyTripGetMainNextTime(xyd.getServerTime() + needTime)
					end

					self:checkCurMapLockInfo({
						idsArr[i]
					})
					self:updateMapShow()

					break
				end
			end
		end, disTime, 1)
		self.timeArr[self.timeIndex] = nextGolbalTimerKey
	end
end

function GalaxyTrip:checkOpendWithAwards()
	if self.mainInfo.ids then
		for i in pairs(self.mainInfo.ids) do
			if self.mainInfo.awards and self.mainInfo.awards[i] and self.mainInfo.awards[i] == 1 and self.mainInfo.map_id and self.mainInfo.map_id ~= 0 and self.ballInfoArr[self.mainInfo.map_id] and not self.ballInfoArr[self.mainInfo.map_id].opened[tostring(self.mainInfo.ids[i])] then
				print("置入了2")

				self.ballInfoArr[self.mainInfo.map_id].opened[tostring(self.mainInfo.ids[i])] = "1#1"
			end

			if self.mainInfo.map_id and self.mainInfo.map_id ~= 0 and self.ballInfoArr[self.mainInfo.map_id] and self.ballInfoArr[self.mainInfo.map_id].opened[tostring(self.mainInfo.ids[i])] then
				if not self.mainInfo.awards then
					self.mainInfo.awards = {}
				end

				self.mainInfo.awards[i] = 1
			end
		end
	end
end

function GalaxyTrip:onGetGalaxyTripMapAwardsBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	local award3Arr = {}

	if not data.items then
		data.items = {}
	end

	for i, id in pairs(data.ids) do
		self.ballInfoArr[self:getGalaxyTripGetCurMap()].opened[tostring(id)] = 1
		local posId = self:getPosIdFromGridId(self:getGalaxyTripGetCurMap(), id)
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(self:getGalaxyTripGetCurMap())
		local ballMap = ballMapInfo.map
		local eventArr = xyd.split(ballMap[posId].info, "#", true)
		local eventId = eventArr[1]
		local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

		if self:getIsBuff(eventType) then
			local skillId = xyd.tables.galaxyTripEventTable:getSkillId(eventId)

			table.insert(ballMapInfo.god_skills, skillId)
		end

		local getExplorePoint = xyd.tables.galaxyTripEventTable:getExplorePoints(eventId)

		self:setAddCurSeasonScore(getExplorePoint)

		ballMapInfo.score = ballMapInfo.score + getExplorePoint

		if self:getIsMonster(eventType) then
			local posArr = {}

			for k in pairs(eventArr) do
				if k > 2 then
					table.insert(posArr, eventArr[k])
				end
			end

			for k in pairs(posArr) do
				self.ballInfoArr[self:getGalaxyTripGetCurMap()].opened[tostring(posArr[k])] = 1
			end
		end

		local awards3 = xyd.tables.galaxyTripEventTable:getAward3(eventId)

		for j in pairs(awards3) do
			local isSearch = false

			for k in pairs(award3Arr) do
				if award3Arr[k].item_id == awards3[j][1] then
					award3Arr[k].item_num = award3Arr[k].item_num + awards3[j][2]
					isSearch = true
				end
			end

			if not isSearch then
				table.insert(award3Arr, {
					item_id = awards3[j][1],
					item_num = awards3[j][2]
				})
			end
		end
	end

	for i in pairs(award3Arr) do
		table.insert(data.items, award3Arr[i])
	end

	xyd.models.itemFloatModel:pushNewItems(data.items)
	xyd.WindowManager.get():closeWindow("galaxy_trip_common_event_window")
	xyd.WindowManager.get():closeWindow("galaxy_trip_buff_window")
	xyd.WindowManager.get():closeWindow("galaxy_trip_fight_window")
	xyd.WindowManager.get():closeWindow("galaxy_trip_result_window")

	if self.mainInfo.is_batch == 1 then
		for i in pairs(self.mainInfo.ids) do
			local isSearch = false

			for k in pairs(data.ids) do
				if self.mainInfo.ids[i] == data.ids[i] then
					isSearch = true

					break
				end
			end

			if not isSearch then
				self.ballInfoArr[self:getGalaxyTripGetCurMap()].opened[tostring(self.mainInfo.ids[i])] = nil
			end
		end

		self.mainInfo.awards = {}
		self.mainInfo.ids = {}

		self:setGalaxyTripGetMainNextTime(0)
	end

	self.mainInfo.is_batch = 0

	self:checkCurMapLockInfo(data.ids)
	self:checkRedPoint()
end

function GalaxyTrip:checkCurMapLockInfo(ids)
	local curMapId = self:getGalaxyTripGetCurMap()

	if curMapId == self:getGalaxyTripGetMaxMap() then
		local mapSize = xyd.tables.galaxyTripMapTable:getSize(curMapId)
		local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(curMapId)
		local ballMap = ballMapInfo.map

		for i, gridId in pairs(ids) do
			if self.ballInfoArr[curMapId].is_end == 0 or self.ballInfoArr[curMapId].is_boss == 0 or self.ballInfoArr[curMapId].is_chest == 0 then
				local posId = self:getPosIdFromGridId(curMapId, gridId)
				local eventArr = xyd.split(ballMap[posId].info, "#", true)
				local eventId = eventArr[1]
				local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

				if tonumber(eventId) ~= -1 and ballMapInfo.opened[tostring(ballMap[posId].gridId)] then
					if self.ballInfoArr[curMapId].is_end == 0 and math.floor((posId - 1) / mapSize[1]) == 0 then
						self.ballInfoArr[curMapId].is_end = 1
					end

					if self.ballInfoArr[curMapId].is_boss == 0 and eventType == xyd.GalaxyTripGridEventType.COMMON_BOSS then
						self.ballInfoArr[curMapId].is_boss = 1
					end

					if self.ballInfoArr[curMapId].is_chest == 0 and eventType == xyd.GalaxyTripGridEventType.BOX then
						local gridId = ballMap[posId].gridId

						if xyd.arrayIndexOf(self.ballInfoArr[curMapId].chests, gridId) <= 0 then
							table.insert(self.ballInfoArr[curMapId].chests, gridId)
						end

						if self:getNeedChestMaxNum(curMapId) <= #self.ballInfoArr[curMapId].chests then
							self.ballInfoArr[curMapId].is_chest = 1
						end
					end
				end
			else
				break
			end
		end

		if self.ballInfoArr[curMapId].is_end == 1 and self.ballInfoArr[curMapId].is_boss == 1 and self.ballInfoArr[curMapId].is_chest == 1 then
			self:addGalaxyTripGetMaxMap()
		end
	end
end

function GalaxyTrip:updateMapShow()
	local galaxyTripMapWd = xyd.WindowManager.get():getWindow("galaxy_trip_map_window")

	if galaxyTripMapWd then
		galaxyTripMapWd:updateGridShow()
	end
end

function GalaxyTrip:setGridBattleFight(gridId, partners, petID)
	local msg = messages_pb:galaxy_trip_grid_battle_req()
	msg.id = gridId

	for _, v in pairs(partners) do
		table.insert(msg.partners, self:addMsgPartners(v))
	end

	msg.pet_id = petID

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GRID_BATTLE, msg)
end

function GalaxyTrip:addMsgPartners(info)
	local PartnersMsg = messages_pb:partners_info()
	PartnersMsg.partner_id = info.partner_id
	PartnersMsg.pos = info.pos

	return PartnersMsg
end

function GalaxyTrip:getIsMonster(eventType)
	if eventType == xyd.GalaxyTripGridEventType.COMMON_ENEMY or eventType == xyd.GalaxyTripGridEventType.ELITE_ENEMY or eventType == xyd.GalaxyTripGridEventType.COMMON_BOSS or eventType == xyd.GalaxyTripGridEventType.ROBBER_ENEMY or eventType == xyd.GalaxyTripGridEventType.BLACK_HOLE_BOSS then
		return true
	end

	return false
end

function GalaxyTrip:getIsBuff(eventType)
	if eventType == xyd.GalaxyTripGridEventType.BUFF_4 or eventType == xyd.GalaxyTripGridEventType.BUFF_5 or eventType == xyd.GalaxyTripGridEventType.BUFF_6 or eventType == xyd.GalaxyTripGridEventType.BUFF_7 or eventType == xyd.GalaxyTripGridEventType.BUFF_8 then
		return true
	end

	return false
end

function GalaxyTrip:setFormation(partners)
	local msg = messages_pb:galaxy_trip_set_teams_req()

	for i = 1, 3 do
		local teamOne = messages_pb:set_partners_req()
		local tmpPartner = xyd.slice(partners, (i - 1) * 6 + 1, (i - 1) * 6 + 6)

		for j = 1, #tmpPartner do
			if tmpPartner[j] ~= nil then
				local fight_partner = messages_pb:fight_partner()
				fight_partner.partner_id = tmpPartner[j].partner_id
				fight_partner.pos = tmpPartner[j].pos

				table.insert(teamOne.partners, fight_partner)
			end
		end

		table.insert(msg.teams, teamOne)
	end

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_SET_TEAMS, msg)
end

function GalaxyTrip:onSetGalaxyTripFormation(event)
	local data = xyd.decodeProtoBuf(event.data)

	if self.mainInfo.teams and #self.mainInfo.teams > 0 then
		for i = 1, 3 do
			local team = self.mainInfo.teams[i]

			if team and team.partners then
				for key, value in pairs(team.partners) do
					local partnerID = value.partner_id
					local partner = xyd.models.slot:getPartner(partnerID)

					partner:setLock(0, xyd.PartnerFlag.GALAXY_TRIP_FORMATION)
					dump(partnerID)
				end
			end
		end
	end

	self.mainInfo.teams = data.teams

	for i = 1, 3 do
		local team = self.mainInfo.teams[i]

		if team and team.partners then
			for key, value in pairs(team.partners) do
				local partnerID = value.partner_id
				local partner = xyd.models.slot:getPartner(partnerID)

				partner:setLock(1, xyd.PartnerFlag.GALAXY_TRIP_FORMATION)
			end
		end
	end
end

function GalaxyTrip:getBuffPlaceAddNum()
	local text = ""
	local timecut = 0
	local placeAdd = 0
	local teams = self:getGalaxyTripGetMainTeamsInfo()

	if teams and teams[2] and teams[2].partners then
		local totalAwakeStar = 0

		for j = 1, 6 do
			local index = j

			if teams[2].partners[index] then
				local partner = xyd.models.slot:getPartner(tonumber(teams[2].partners[index].partner_id))
				local star = partner:getStar()

				if star > 10 then
					totalAwakeStar = totalAwakeStar + star - 10
				end
			end
		end

		text, timecut, placeAdd = xyd.tables.galaxyTripTeamTable:getDesc(totalAwakeStar, 2)
	end

	return placeAdd
end

function GalaxyTrip:getBuffExploreTimeCut()
	local text = ""
	local timecut = 0
	local placeAdd = 0
	local teams = self:getGalaxyTripGetMainTeamsInfo()

	if teams and teams[2] and teams[2].partners then
		local totalAwakeStar = 0

		for j = 1, 6 do
			local index = j

			if teams[2].partners[index] then
				local partner = xyd.models.slot:getPartner(tonumber(teams[2].partners[index].partner_id))
				local star = partner:getStar()

				if star > 10 then
					totalAwakeStar = totalAwakeStar + star - 10
				end
			end
		end

		text, timecut, placeAdd = xyd.tables.galaxyTripTeamTable:getDesc(totalAwakeStar, 2)
	end

	return timecut
end

function GalaxyTrip:getPalningNum()
	local defaultNum = xyd.tables.miscTable:getNumber("galaxy_trip_explore_place", "value") + self:getBuffPlaceAddNum()

	return defaultNum
end

function GalaxyTrip:getAwardNumWithBuff(num, awardID)
	local text = ""
	local add1 = 0
	local add2 = 0
	local teams = self:getGalaxyTripGetMainTeamsInfo()

	if teams and teams[3] and teams[3].partners then
		local totalAwakeStar = 0

		for j = 1, 6 do
			local index = j

			if teams[3].partners[index] then
				local partner = xyd.models.slot:getPartner(tonumber(teams[3].partners[index].partner_id))
				local star = partner:getStar()

				if star > 10 then
					totalAwakeStar = totalAwakeStar + star - 10
				end
			end
		end

		text, add1, add2 = xyd.tables.galaxyTripTeamTable:getDesc(totalAwakeStar, 3)
	end

	if awardID == 1 then
		return math.ceil(num + add1 * num)
	elseif awardID == 2 then
		return math.ceil(num + add2 * num)
	end

	return num
end

function GalaxyTrip:getCurSeasonScore()
	return self.mainInfo.score or 0
end

function GalaxyTrip:setAddCurSeasonScore(score)
	self.mainInfo.score = self.mainInfo.score + score
end

function GalaxyTrip:getHistorySeasonScore()
	return self.mainInfo.history_scores or {}
end

function GalaxyTrip:getShopData()
	local curSeason = self:getGalaxyTripGetMainCount()
	local layerRankArr1 = xyd.tables.galaxyTripStore1Table:getLayerRankArr(curSeason)
	local layerRankArr2 = xyd.tables.galaxyTripStore2Table:getLayerRankArr(curSeason)
	local itemLayerKeyData1 = xyd.tables.galaxyTripStore1Table:getItemLayerKeyData(curSeason)
	local itemLayerKeyData2 = xyd.tables.galaxyTripStore2Table:getItemLayerKeyData(curSeason)
	local unlockRankData1 = {}
	local unlockRankData2 = {}
	local titleUnlockText1 = {}
	local titleUnlockText2 = {}
	local titleLockText1 = {}
	local titleLockText2 = {}

	for i = 1, #layerRankArr1 do
		local curScore = self:getCurSeasonScore()
		unlockRankData1[i] = layerRankArr1[i] <= curScore
		local text = xyd.tables.galaxyTripStoreTextTable:getDesc(xyd.tables.galaxyTripStore1Table:getTextId(i))
		titleUnlockText1[i] = xyd.stringFormat(text, layerRankArr1[i])
		titleLockText1[i] = xyd.stringFormat(text, layerRankArr1[i])
	end

	for i = 1, #layerRankArr2 do
		local historyScore = self:getHistorySeasonScore()
		local arr = xyd.splitToNumber(layerRankArr2[i], "_", true)
		local needSeasons = arr[1]
		local needPoint = arr[2]
		local count = 0

		for j = 1, #historyScore do
			if needPoint <= historyScore[j] then
				count = count + 1
			end
		end

		local text = xyd.tables.galaxyTripStoreTextTable:getDesc(xyd.tables.galaxyTripStore2Table:getTextId(i))
		unlockRankData2[i] = needSeasons <= count
		titleUnlockText2[i] = xyd.stringFormat(text, needSeasons, needPoint)
		titleLockText2[i] = xyd.stringFormat(text, needSeasons, needPoint)
	end

	local params = {
		helpKey = "wqdqd",
		hideBtnHelp = true,
		hideFirstTitle = true,
		labelWinTitleText = __("GALAXY_TRIP_TEXT68"),
		shopTypes = {
			xyd.ShopType.GALAXY_TRIP_SHOP1,
			xyd.ShopType.GALAXY_TRIP_SHOP2
		},
		tabText = {
			__("OLD_SCHOOL_SHOP_TEXT1"),
			__("OLD_SCHOOL_SHOP_TEXT2")
		},
		tab2RedPointType = xyd.RedMarkType.GALAXY_TRIP_SHOP2,
		resIDs = {
			398
		},
		calculateLeftTimeCallbacks = {
			function ()
				return self:getLeftTime()
			end
		},
		pointDatas = {
			{
				unlockRankData = unlockRankData1,
				layerRankArr = xyd.tables.galaxyTripStore1Table:getLayerRankArr(self:getGalaxyTripGetMainCount()),
				itemLayerKeyData = xyd.tables.galaxyTripStore1Table:getItemLayerKeyData(self:getGalaxyTripGetMainCount())
			},
			{
				unlockRankData = unlockRankData2,
				layerRankArr = xyd.tables.galaxyTripStore2Table:getLayerRankArr(self:getGalaxyTripGetMainCount()),
				itemLayerKeyData = xyd.tables.galaxyTripStore2Table:getItemLayerKeyData(self:getGalaxyTripGetMainCount())
			}
		},
		titleUnlockText = {
			titleUnlockText1,
			titleUnlockText2
		},
		titleLockText = {
			titleLockText1,
			titleLockText2
		}
	}

	return params
end

function GalaxyTrip:needReqRankInfo()
	if not self.rankInfo or not self.reqRankTime or xyd.getServerTime() - self.reqRankTime > 30 then
		self:reqRankInfo()

		return true
	end
end

function GalaxyTrip:reqRankInfo()
	local msg = messages_pb:galaxy_trip_get_rank_list_req()

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_RANK_LIST, msg)
end

function GalaxyTrip:onGetRankInfo(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.rankInfo = {
		list = data.list,
		self_rank = data.self_rank,
		self_score = data.self_score
	}
	self.reqRankTime = xyd.getServerTime()
end

function GalaxyTrip:getRankData()
	local ids = xyd.tables.galaxyTripRankTable:getIDs()
	local awardData = {
		list = {},
		self_data = {
			rankText = "",
			awards = {}
		}
	}
	local selfRank = self.rankInfo.self_rank
	selfRank = selfRank and selfRank + 1

	for i = 1, #ids do
		local id = ids[i]
		local items = xyd.tables.galaxyTripRankTable:getSeasonAwards(id)
		local rank = xyd.tables.galaxyTripRankTable:getRank(id)
		local titleText = xyd.tables.galaxyTripRankTable:getRankFront(id)

		table.insert(awardData.list, {
			items = items,
			rank = rank,
			titleText = titleText
		})

		if selfRank and selfRank <= rank and awardData.self_data.rankText == "" then
			awardData.self_data.awards = items
			awardData.self_data.rankText = titleText
		end
	end

	local params = {
		rankData = {
			list = self.rankInfo.list,
			self_rank = selfRank,
			self_score = self.rankInfo.self_score
		},
		awardData = awardData,
		durationTime = self:getLeftTime(),
		timeDescText = __("ARENA_RANK_DESC2"),
		RankDescText = __("GALAXY_TRIP_TEXT47")
	}

	return params
end

function GalaxyTrip:getCurBallProress(ballID)
	return self:getGalaxyProgress(ballID) / 100
end

function GalaxyTrip:getAwards(gridIds)
	local msg = messages_pb:galaxy_trip_get_map_awards_req()

	for i in pairs(gridIds) do
		table.insert(msg.ids, gridIds[i])
	end

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_AWARDS, msg)
end

function GalaxyTrip:getLeftTime()
	if self.mainInfo and self.mainInfo.start_time then
		local periodTime = xyd.tables.miscTable:getNumber("galaxy_trip_time", "value")

		return periodTime + self.mainInfo.start_time - xyd.getServerTime()
	end

	return 0
end

function GalaxyTrip:onGalaxyTripStopBackGrid(event)
	local data = xyd.decodeProtoBuf(event.data)
	local ids = data.ids
	local awards = data.awards

	if ids then
		self.mainInfo.ids = ids
	else
		self.mainInfo.ids = {}
	end

	if awards then
		self.mainInfo.awards = awards
	else
		self.mainInfo.awards = {}
	end

	for i, id in pairs(self.mainInfo.ids) do
		if self.mainInfo.awards[i] and self.mainInfo.awards[i] == 1 then
			local ballMapInfo = self:getBallInfo(self:getGalaxyTripGetCurMap())
			local opened = ballMapInfo.opened
			opened[tostring(id)] = "1#1"
		end
	end

	self:setGalaxyTripGetMainNextTime(0)
end

function GalaxyTrip:getGalaxyProgress(ballId)
	if self:getGalaxyTripGetCurMap() == ballId then
		local ballMapInfo = self:getBallInfo(ballId)

		if not ballMapInfo then
			return 0
		end

		local ballMap = ballMapInfo.map
		local opened = ballMapInfo.opened
		local allGetNum = 0
		local allNum = 0

		for i in pairs(ballMap) do
			local gridId = ballMap[i].gridId

			if opened[tostring(gridId)] and type(opened[tostring(gridId)]) == "number" then
				allGetNum = allGetNum + 1
			end

			local eventArr = xyd.split(ballMap[i].info, "#", true)
			local eventId = eventArr[1]
			local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

			if eventType and eventType > 0 then
				allNum = allNum + 1
			end
		end

		if allNum < allGetNum then
			allGetNum = allNum
		end

		return math.floor(allGetNum / allNum * 100 + 0.1)
	end

	return 0
end

function GalaxyTrip:reqMapInfo(ballId)
	local msg = messages_pb:galaxy_trip_get_map_info_req()
	msg.id = ballId

	xyd.Backend.get():request(xyd.mid.GALAXY_TRIP_GET_MAP_INFO, msg)
end

function GalaxyTrip:getBallIsUnLock(ballId)
	local maxid = self:getGalaxyTripGetMaxMap()

	if maxid < ballId then
		return false
	elseif ballId < maxid then
		return true
	else
		local ballID = maxid

		if not self.ballInfoArr[ballID] then
			self:reqMapInfo()

			return nil
		else
			local info = self.ballInfoArr[ballID]

			return info.is_end == 1 and info.is_boss == 1 and info.is_chest == 1
		end
	end
end

function GalaxyTrip:getNeedChestMaxNum(mapID, eventType)
	local num = 0
	local eventType = eventType or xyd.GalaxyTripGridEventType.BOX
	local eventIDs = xyd.tables.galaxyTripEventTable:getIDsByMap(mapID)

	for j = 1, #eventIDs do
		local type = xyd.tables.galaxyTripEventTable:getType(eventIDs[j])

		if eventType == type then
			num = num + xyd.tables.galaxyTripEventTable:getAmount(eventIDs[j])
		end
	end

	return num
end

function GalaxyTrip:getGalaxyGridAllGetNum(ballId)
	if self:getGalaxyTripGetCurMap() == ballId then
		local ballMapInfo = self:getBallInfo(ballId)

		if not ballMapInfo then
			return 0
		end

		local ballMap = ballMapInfo.map
		local opened = ballMapInfo.opened
		local allGetNum = 0
		local allNum = 0

		for i in pairs(ballMap) do
			local gridId = ballMap[i].gridId

			if opened[tostring(gridId)] and type(opened[tostring(gridId)]) == "number" then
				allGetNum = allGetNum + 1
			end

			local eventArr = xyd.split(ballMap[i].info, "#", true)
			local eventId = eventArr[1]
			local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

			if eventType and eventType > 0 then
				allNum = allNum + 1
			end
		end

		if allNum < allGetNum then
			allGetNum = allNum
		end

		return allGetNum
	end

	return 0
end

function GalaxyTrip:getGalaxyGridAllNum(ballId)
	if self:getGalaxyTripGetCurMap() == ballId then
		local ballMapInfo = self:getBallInfo(ballId)

		if not ballMapInfo then
			return 0
		end

		local ballMap = ballMapInfo.map
		local opened = ballMapInfo.opened
		local allNum = 0

		for i in pairs(ballMap) do
			local gridId = ballMap[i].gridId
			local eventArr = xyd.split(ballMap[i].info, "#", true)
			local eventId = eventArr[1]
			local eventType = xyd.tables.galaxyTripEventTable:getType(eventId)

			if eventType and eventType > 0 then
				allNum = allNum + 1
			end
		end

		return allNum
	end

	return 0
end

function GalaxyTrip:checkRedPoint()
	local isHasGetPoint = false

	if self.mainInfo then
		local curMapId = self.mainInfo.map_id

		if curMapId and curMapId > 0 then
			local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(curMapId)
			local ballMap = ballMapInfo.map

			if self.mainInfo.is_batch and self.mainInfo.is_batch == 1 then
				if self.mainInfo.ids then
					local isBatchAllCheck = true

					for i in pairs(self.mainInfo.ids) do
						if not self.mainInfo.awards or not self.mainInfo.awards[i] or self.mainInfo.awards[i] ~= 1 then
							isBatchAllCheck = false

							break
						end
					end

					if isBatchAllCheck then
						isHasGetPoint = true
					end
				end
			else
				for i in pairs(ballMap) do
					local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, curMapId)

					if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
						isHasGetPoint = true

						break
					end
				end
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GALAXY_TRIP_MAP_CAN_GET_POINT, isHasGetPoint)

	local isHasPassPoint = false
	local activityGalaxyTripMissionData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_GALAXY_TRIP_MISSION)

	if activityGalaxyTripMissionData and activityGalaxyTripMissionData:checkRedMaskOfAward() then
		isHasPassPoint = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.GALAXY_TRIP, isHasPassPoint)
end

function GalaxyTrip:getIsHasCanGetPoint()
	local isHasRed = false

	if self.mainInfo then
		local curMapId = self.mainInfo.map_id

		if curMapId and curMapId > 0 then
			if self.mainInfo.is_batch and self.mainInfo.is_batch == 1 then
				if self.mainInfo.ids then
					local isBatchAllCheck = true

					for i in pairs(self.mainInfo.ids) do
						if not self.mainInfo.awards or not self.mainInfo.awards[i] or self.mainInfo.awards[i] ~= 1 then
							isBatchAllCheck = false

							break
						end
					end

					if isBatchAllCheck then
						isHasRed = true
					end
				end
			else
				local ballMapInfo = xyd.models.galaxyTrip:getBallInfo(curMapId)
				local ballMap = ballMapInfo.map

				for i in pairs(ballMap) do
					local gridState = xyd.models.galaxyTrip:getGridState(ballMap[i].gridId, curMapId)

					if gridState == xyd.GalaxyTripGridStateType.CAN_GET then
						isHasRed = true
					end
				end
			end
		end
	end

	return isHasRed
end

function GalaxyTrip:countOverDeal()
end

return GalaxyTrip
