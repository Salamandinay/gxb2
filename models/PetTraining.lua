local BaseModel = import(".BaseModel")
local Pet = import("app.models.Pet")
local PetTraining = class("PetTraining", BaseModel)

function PetTraining:ctor()
	PetTraining.super.ctor(self)

	self.infos = {}
	self.missionList = {}
	self.missionIds = {}
	self.trainingLevel = nil
	self.isInit = false
end

function PetTraining:reset()
	if PetTraining.INSTANCE then
		PetTraining.INSTANCE:removeEvents()
	end

	PetTraining.INSTANCE = nil
end

function PetTraining:onRegister()
	PetTraining.super.onRegister(self)
	self:registerEvent(xyd.event.PET_TRAINING_GET_INFO, handler(self, self.onGetPetTrainingInfo))
	self:registerEvent(xyd.event.PET_TRAINING_FIGHT, handler(self, self.onFight))
	self:registerEvent(xyd.event.PET_TRAINING_SELECT_BOSS, handler(self, self.onSelectBoss))
	self:registerEvent(xyd.event.PET_TRAINING_BUY_TIMES, handler(self, self.onBuyTimes))
	self:registerEvent(xyd.event.PET_TRAINING_START_MISSION, handler(self, self.onStartMission))
	self:registerEvent(xyd.event.PET_TRAINING_CANCEL_MISSION, handler(self, self.onCancelMission))
	self:registerEvent(xyd.event.PET_TRAINING_COMPLETE_MISSION, handler(self, self.onCompleteMission))
	self:registerEvent(xyd.event.PET_LEV_UP, handler(self, self.onPetLevUp))
	self:registerEvent(xyd.event.PET_TRAINING_GET_AWARD, handler(self, self.onGetTrainingAward))
end

function PetTraining:onGetPetTrainingInfo(event)
	local infos = event.data
	self.infos = infos

	for i = 1, 3 do
		self.missionIds[i] = tonumber(infos.missions[i]) or 0
		self.missionList[i] = infos.mission_list[i]
	end

	self.battleTimes = infos.times
	self.petBattleTimes = infos.pet_times
	self.buyTimeTimes = infos.buy_times
	self.bossID = infos.boss_id
	self.bossHp = infos.boss_hp
	self.hangTime = infos.hang_time
	self.isInit = true

	self:setRedMark()
end

function PetTraining:setRedMark()
	xyd.models.redMark:setMark(xyd.RedMarkType.PET, self:getRedMarkStatus())
end

function PetTraining:getRedMarkStatus()
	local level = self:getTrainingLevel()
	local maxHangTime = xyd.tables.petTrainingNewAwardsTable:getTime(level)
	local hangStartTime = self:getHangTime()

	if hangStartTime == 0 then
		return false
	end

	local nowTime = xyd.getServerTime(true)
	local show = false

	if maxHangTime <= nowTime - hangStartTime then
		show = true
	end

	return show
end

function PetTraining:onFight(event)
	local infos = event.data
	self.battleTimes = infos.times
	self.petBattleTimes = infos.pet_times
	self.buyTimeTimes = infos.buy_times
	self.bossHp = infos.boss_hp
end

function PetTraining:onSelectBoss(event)
	local infos = event.data
	self.bossID = infos.boss_id
	self.bossHp = xyd.tables.petTrainingBossTable:getHp(self.bossID)
end

function PetTraining:onBuyTimes(event)
	local infos = event.data
	self.battleTimes = infos.times
	self.petBattleTimes = infos.pet_times
	self.buyTimeTimes = infos.buy_times
end

function PetTraining:onStartMission(event)
	local info = event.data
	local pos = info.id
	local missionInfo = info.info
	local missionId = missionInfo.mission_id
	self.missionIds[pos] = missionId
	self.missionList[pos] = missionInfo
end

function PetTraining:onCancelMission(event)
	local info = event.data
	local pos = info.id
	self.missionIds[pos] = 0
	self.missionList[pos] = nil
end

function PetTraining:onCompleteMission(event)
	local info = event.data
	local pos = info.id
	self.missionIds[pos] = 0
	self.missionList[pos] = nil

	self:setRedMark()
end

function PetTraining:getMissionNum()
	local allNum = 0
	local completeNum = 0

	for pos, id in ipairs(self.missionIds) do
		if id > 0 then
			allNum = allNum + 1
			local missionInfo = self.missionList[pos]
			local missionId = missionInfo.mission_id
			local startTime = missionInfo.start_time
			local missionTime = xyd.tables.petTrainingLessonTable:getTime(missionId)
			local nowTime = xyd.getServerTime()
			local duration = nowTime - startTime

			if missionTime < duration then
				completeNum = completeNum + 1
			end
		end
	end

	return allNum, completeNum
end

function PetTraining:getHangTime()
	return self.hangTime or 0
end

function PetTraining:getBattleTimes()
	return self.battleTimes
end

function PetTraining:getPetBattleTimes()
	return self.petBattleTimes
end

function PetTraining:getBuyTimeTimes()
	return self.buyTimeTimes
end

function PetTraining:getBossID()
	return self.bossID
end

function PetTraining:getBossHp()
	return self.bossHp
end

function PetTraining:getMissionInfo(pos)
	local id = tonumber(self.missionIds[pos]) or 0

	if id == 0 then
		return {
			pos = pos
		}
	end

	local missionData = {
		pos = pos
	}
	local mission = self.missionList[pos]

	if not mission then
		return {
			pos = pos
		}
	end

	missionData.startTime = mission.start_time
	missionData.missionId = mission.mission_id
	missionData.pets = {}

	for _, pet in ipairs(mission.pets) do
		table.insert(missionData.pets, pet)
	end

	return missionData
end

function PetTraining:cleanTempMission(pos)
	self.tempMissions = nil
	self.tempMissionPos = nil
end

function PetTraining:saveTempMission(pos)
	if not pos then
		return
	end

	if not self.tempMissions then
		self.tempMissions = {}
	end

	if not self.tempMissionPos then
		self.tempMissionPos = {}
	end

	local missionInfo = self:getMissionInfo(pos)

	dump(missionInfo)

	self.tempMissions[pos] = missionInfo

	table.insert(self.tempMissionPos, pos)
end

function PetTraining:startTempMission()
	if not self.tempMissions or not self.tempMissionPos then
		return
	end

	for _, pos in ipairs(self.tempMissionPos) do
		local missionInfo = self.tempMissions[pos]

		self:startMission(missionInfo.missionId, pos, missionInfo.pets)
	end
end

function PetTraining:isMissionRun(tableId, pos)
	local id = tonumber(self.missionIds[pos]) or 0

	if id == 0 then
		return false
	else
		return true
	end
end

function PetTraining:getMissionPets()
	local excludePets = {}

	for _, mission in pairs(self.missionList) do
		if mission and mission.pets then
			for _, pet in ipairs(mission.pets) do
				table.insert(excludePets, pet)
			end
		end
	end

	return excludePets
end

function PetTraining:onPetLevUp(event)
	local petInfo = event.data.pet_info
	local lev = petInfo.lev or petInfo.lv or 0

	if self.isInit then
		return
	end

	local openLv = xyd.tables.miscTable:getNumber("pet_training_boss_level", "value")

	if openLv <= lev then
		self:reqTrainingInfo()
	end
end

function PetTraining:onGetTrainingAward(event)
	self.hangTime = event.data.hang_time

	self:setRedMark()
end

function PetTraining:isTrainOpen()
	if self.isInit then
		return true
	end
end

function PetTraining:getTrainingLevel()
	local exp = xyd.models.backpack:getItemNumByID(xyd.ItemID.PET_TRAINING_EXP)
	local ids = xyd.tables.petTrainingTable:getIds()

	for i = 1, #ids - 1 do
		if xyd.tables.petTrainingTable:getExp(ids[i]) <= exp and exp < xyd.tables.petTrainingTable:getExp(ids[i + 1]) then
			if self.trainingLevel and self.trainingLevel ~= ids[i] then
				xyd.db.misc:setValue({
					value = 1,
					key = "pet_training_new_boss"
				})
			end

			self.trainingLevel = ids[i]

			return self.trainingLevel
		end
	end

	if self.trainingLevel and self.trainingLevel ~= ids[#ids] then
		xyd.db.misc:setValue({
			value = 1,
			key = "pet_training_new_boss"
		})
	end

	self.trainingLevel = ids[#ids]

	return self.trainingLevel
end

function PetTraining:fight(id)
	local msg = messages_pb.pet_training_fight_req()
	msg.pet_id = id

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_FIGHT, msg)
end

function PetTraining:selectBoss(id)
	local msg = messages_pb.pet_training_select_boss_req()
	msg.boss_id = id

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_SELECT_BOSS, msg)
end

function PetTraining:buyTimes(id)
	local msg = messages_pb.pet_training_buy_times_req()
	msg.pet_id = id

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_BUY_TIMES, msg)
end

function PetTraining:startMission(missionId, pos, pets)
	local msg = messages_pb.pet_training_start_mission_req()
	msg.id = pos
	msg.mission_id = missionId

	for _, petId in ipairs(pets) do
		table.insert(msg.pets, petId)
	end

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_START_MISSION, msg)
end

function PetTraining:cancelMission(missionId, pos)
	local msg = messages_pb.pet_training_cancel_mission_req()
	msg.id = pos

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_CANCEL_MISSION, msg)
end

function PetTraining:completeMission(pos)
	local msg = messages_pb.pet_training_complete_mission_req()
	msg.id = pos

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_COMPLETE_MISSION, msg)
end

function PetTraining:reqTrainingInfo()
	local msg = messages_pb.pet_training_get_info_req()

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_GET_INFO, msg)
end

function PetTraining:reqTrainingAward()
	local msg = messages_pb.pet_training_get_award_req()

	xyd.Backend.get():request(xyd.mid.PET_TRAINING_GET_AWARD, msg)
end

return PetTraining
