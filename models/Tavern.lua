local Tavern = class("Tavern", import(".BaseModel"))

function Tavern:ctor()
	Tavern.super.ctor(self)

	self.datas_ = {}
	self.missions_ = {}
	self.missionsSort_ = {}
	self.partners_ = {}
	self.endTime_ = 0
	self.timeCount_ = nil
	self.redPoint_ = false
end

function Tavern:onRegister()
	Tavern.super.onRegister(self)
	self:registerEvent(xyd.event.PUB_GET_LIST, handler(self, self.onPubInfo))
	self:registerEvent(xyd.event.PUB_REFRESH, handler(self, self.onRefreshPubInfo))
	self:registerEvent(xyd.event.PUB_LOCK_MISSION, handler(self, self.onLockPubInfo))
	self:registerEvent(xyd.event.PUB_START_MISSION, handler(self, self.onStartPubInfo))
	self:registerEvent(xyd.event.PUB_CANCEL_MISSION, handler(self, self.onCancelPubInfo))
	self:registerEvent(xyd.event.PUB_COMPLETE_MISSION, handler(self, self.onCompletePubInfo))
	self:registerEvent(xyd.event.PUB_SPEED_MISSION, handler(self, self.onCompletePubInfo))
	self:registerEvent(xyd.event.PUB_USE_SCROLL, handler(self, self.onUseScroll))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, handler(self, self.onSystemUpdate))
	self:registerEvent(xyd.event.PUB_INFOS, handler(self, self.onStartMultiMissions))
	self:registerEvent(xyd.event.BATCH_COMPLETE_PUB_MISSIONS, handler(self, self.onCompleteMultiMissions))
end

function Tavern:reqPubInfo()
	local msg = messages_pb.pub_get_list_req()

	xyd.Backend.get():request(xyd.mid.PUB_GET_LIST, msg)
end

function Tavern:onSystemUpdate()
	self:reqPubInfo()
end

function Tavern:lockMission(missionID, isLock)
	local msg = messages_pb.pub_lock_mission_req()
	msg.mission_id = missionID
	msg.is_lock = isLock

	xyd.Backend.get():request(xyd.mid.PUB_LOCK_MISSION, msg)
end

function Tavern:startMission(missionID, partnerIds)
	local msg = messages_pb.pub_start_mission_req()
	msg.mission_id = missionID

	for _, id in ipairs(partnerIds) do
		table.insert(msg.partner_ids, id)
	end

	xyd.Backend.get():request(xyd.mid.PUB_START_MISSION, msg)
end

function Tavern:cancelMission(missionID)
	local msg = messages_pb.pub_cancel_mission_req()
	msg.mission_id = missionID

	xyd.Backend.get():request(xyd.mid.PUB_CANCEL_MISSION, msg)
end

function Tavern:completeMission(missionID)
	local msg = messages_pb.pub_complete_mission_req()
	msg.mission_id = missionID

	xyd.Backend.get():request(xyd.mid.PUB_COMPLETE_MISSION, msg)
end

function Tavern:speedMission(missionID)
	local msg = messages_pb.pub_speed_mission_req()
	msg.mission_id = missionID

	xyd.Backend.get():request(xyd.mid.PUB_SPEED_MISSION, msg)
end

function Tavern:refreshMission()
	local msg = messages_pb.pub_refresh_req()

	xyd.Backend.get():request(xyd.mid.PUB_REFRESH, msg)
end

function Tavern:useScroll(index, num)
	local msg = messages_pb.pub_use_scroll_req()
	msg.index = index
	msg.num = num or 1

	xyd.Backend.get():request(xyd.mid.PUB_USE_SCROLL, msg)
end

function Tavern:startMultiMissions(missionList)
	local msg = messages_pb.pub_infos_req()

	for _, item in ipairs(missionList) do
		table.insert(msg.mission_ids, item.missionID)

		local msg1 = messages_pb.partnerids()

		for _, partnerId in ipairs(item.partners) do
			table.insert(msg1.partner_ids, partnerId)
		end

		table.insert(msg.batch_partner_ids, msg1)
	end

	xyd.Backend.get():request(xyd.mid.PUB_INFOS, msg)
end

function Tavern:completeMultiMission(missionList)
	local msg = messages_pb.batch_complete_pub_missions_req()

	for _, missionID in ipairs(missionList) do
		table.insert(msg.mission_ids, missionID)
	end

	msg.is_speedup = 0

	xyd.Backend.get():request(xyd.mid.BATCH_COMPLETE_PUB_MISSIONS, msg)
end

function Tavern:onPubInfo(event)
	local datas = event.data
	self.missions_ = {}
	self.missionsSort_ = {}
	self.partners_ = datas.partner_ids
	self.endTime_ = datas.end_time

	self:setMissions(datas.missions)
	self:sortMissions()
	self:updateRedMark()
end

function Tavern:setMissions(missions)
	for _, mission in ipairs(missions) do
		self.missions_[mission.mission_id] = mission

		table.insert(self.missionsSort_, mission.mission_id)
	end
end

function Tavern:onRefreshPubInfo(event)
	local params = event.data
	local missions = params.missions
	local oldMissions = self:getMissions()

	local function getCurData(id)
		for _, mission in ipairs(missions) do
			if mission.mission_id == id then
				return mission
			end
		end

		return nil
	end

	for _, missionid in ipairs(oldMissions) do
		local mission = self:getMissionById(missionid)

		if mission.is_lock ~= 1 then
			local newMission = getCurData(mission.mission_id)

			if newMission then
				self.missions_[mission.mission_id] = newMission
				mission = newMission
			end
		end

		local star = xyd.tables.pubMissionTable:getStar(mission.table_id)

		if star >= 6 and mission.is_lock ~= 1 then
			self:lockMission(mission.mission_id, 1)
		end
	end

	self:sortMissions()
end

function Tavern:sortMissions()
	table.sort(self.missionsSort_, function (missionIDA, missionIDB)
		local missionA = self:getMissionById(missionIDA)
		local missionB = self:getMissionById(missionIDB)
		local aStar = xyd.tables.pubMissionTable:getStar(missionA.table_id) * 10
		local bStar = xyd.tables.pubMissionTable:getStar(missionB.table_id) * 10
		local aVal = 0
		local bVal = 0

		if missionA.status == 0 then
			aVal = aVal + 10000
			aVal = aStar + aVal
		elseif missionA.status == 2 then
			aVal = aVal + 1000
			aVal = -aStar + aVal
		else
			aVal = aStar + aVal
		end

		if missionA.is_lock == 1 then
			aVal = aVal + 1
		end

		if missionB.status == 0 then
			bVal = bVal + 10000
			bVal = bStar + bVal
		elseif missionB.status == 2 then
			bVal = bVal + 1000
			bVal = -bStar + bVal
		else
			bVal = bStar + bVal
		end

		if missionB.is_lock == 1 then
			bVal = bVal + 1
		end

		if aVal ~= bVal then
			return bVal < aVal
		end

		return missionB.mission_id < missionA.mission_id
	end)
end

function Tavern:onStartPubInfo(event)
	local data = event.data
	local missions = self:getMissions()

	for _, missionid in ipairs(missions) do
		local mission = self:getMissionById(missionid)

		if mission.mission_id == data.mission_id then
			mission.start_time = data.start_time
			mission.is_lock = data.is_lock

			for _, info in ipairs(data.partner_ids) do
				table.insert(mission.partner_ids, info)
			end

			mission.status = data.status
			mission.partner_details = data.partner_details
		end
	end

	self:addPartners(data.partner_ids)
end

function Tavern:onStartMultiMissions(event)
	local infos = event.data.pub_infos
	local missions = self:getMissions()

	for _, data in ipairs(infos) do
		for _, missionid in ipairs(missions) do
			local mission = self:getMissionById(missionid)

			if mission.mission_id == data.mission_id then
				mission.start_time = data.start_time
				mission.is_lock = data.is_lock

				for _, info in ipairs(data.partner_ids) do
					table.insert(mission.partner_ids, info)
				end

				mission.status = data.status
				mission.partner_details = data.partner_details

				break
			end
		end

		self:addPartners(data.partner_ids)
	end
end

function Tavern:onCompleteMultiMissions(event)
	local infos = event.data.pub_infos
	local num = 0

	for _, data in ipairs(infos) do
		xyd.models.activityPointTips:updateData3(self:getMissionById(data.mission_id).table_id)
		self:delMissionByID(data.mission_id)

		num = num + 1
	end

	xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.COMPLETE_STAR4_HEROTASK, num)
end

function Tavern:onLockPubInfo(event)
	local data = event.data
	local mission = self:getMissionById(data.mission_id)

	if mission then
		mission.is_lock = data.is_lock
	end
end

function Tavern:addPartners(partnerIDs)
	for _, id in ipairs(partnerIDs) do
		table.insert(self.partners_, id)
	end
end

function Tavern:onCancelPubInfo(event)
	local data = event.data

	self:delMissionByID(data.mission_id)
end

function Tavern:delMissionByID(id)
	local mission = self:getMissionById(id)

	self:removePartners(mission.partner_ids)
	self:deleteMission(id)
end

function Tavern:getMissions()
	return self.missionsSort_
end

function Tavern:getPartners()
	return self.partners_
end

function Tavern:getMissionById(id)
	return self.missions_[id]
end

function Tavern:getEndTime()
	return self.endTime_
end

function Tavern:deleteMission(id)
	self.missions_[id] = nil

	for idx, missionID in ipairs(self.missionsSort_) do
		if missionID == id then
			table.remove(self.missionsSort_, idx)

			break
		end
	end
end

function Tavern:getMissionsByStar(star)
	local missionIDs = self:getMissions()

	if not star then
		return missionIDs
	end

	local tempMissionIDs = {}

	for _, id in ipairs(missionIDs) do
		local mission = self:getMissionById(id)

		if xyd.tables.pubMissionTable:getStar(mission.table_id) == star then
			table.insert(tempMissionIDs, id)
		end
	end

	return tempMissionIDs
end

function Tavern:onCompletePubInfo(event)
	local data = event.data

	xyd.models.activityPointTips:updateData3(self:getMissionById(data.mission_id).table_id)
	self:delMissionByID(data.mission_id)
	xyd.models.advertiseComplete:achieve(xyd.ACHIEVEMENT_TYPE.COMPLETE_STAR4_HEROTASK, 1)
end

function Tavern:onUseScroll(event)
	local missionInfos = event.data.mission_infos

	for _, missionInfo in ipairs(missionInfos) do
		table.insert(self.missionsSort_, 1, missionInfo.mission_id)

		self.missions_[missionInfo.mission_id] = missionInfo
	end
end

function Tavern:removePartners(partnerIDs)
	local partners = self:getPartners()

	for _, id in ipairs(partnerIDs) do
		for idx, partnerID in ipairs(partners) do
			if partnerID == id then
				table.remove(partners, idx)

				break
			end
		end
	end
end

function Tavern:checkHeroIsSelect(partnerID)
	local partners = self:getPartners()

	for _, id in ipairs(partners) do
		if id == partnerID then
			return true
		end
	end

	return false
end

function Tavern:startTimeCount()
	if not self.timeCount_ then
		self.timeCount_ = Timer.New(handler(self, self.updateRedMark), 1000, -1, false)

		self.timeCount_:Start()
	end
end

function Tavern:showRedPoint()
	return self.redPoint_
end

function Tavern:updateRedMark()
	local flag = self:countRedMark()

	if not xyd.checkFunctionOpen(xyd.FunctionID.TAVERN, true) then
		flag = false
	end

	if flag ~= self.redPoint_ then
		xyd.models.redMark:setMark(xyd.RedMarkType.TAVERN, flag)
	end

	self.redPoint_ = flag
end

function Tavern:countRedMark()
	local missionsID = self:getMissions()
	local flag = false

	for _, missionID in ipairs(missionsID) do
		if self:getMissionById(missionID).status == 0 then
			flag = true

			break
		end
	end

	return flag
end

return Tavern
