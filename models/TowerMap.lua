local BaseModel = import(".BaseModel")
local TowerMap = class("TowerMap", BaseModel, true)
TowerMap.____getters = {}
local cjson = require("cjson")

function TowerMap:ctor(...)
	local __args = {
		...
	}
	self.infos_ = {}
	self.records = {}
	self.towerReports = {}
	self.my_records = {}

	BaseModel.ctor(self)

	self.stage_ = 0
	self.towerTicketTime = 0
end

function TowerMap.____getters:stage()
	return self.stage_
end

function TowerMap.____getters:startRecordStage()
	return self.start_record_stage
end

function TowerMap.____getters:endRecordStage()
	return self.end_record_stage
end

function TowerMap:get()
	if TowerMap.INSTANCE == nil then
		TowerMap.INSTANCE = TowerMap.new()

		TowerMap.INSTANCE:onRegister()
	end

	return TowerMap.INSTANCE
end

function TowerMap:reset()
	if TowerMap.INSTANCE then
		TowerMap.INSTANCE:removeEvents()
	end

	TowerMap.INSTANCE = nil
end

function TowerMap:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.TOWER_MAP_INFO, handler(self, self.onTowerMapInfo))
	self:registerEvent(xyd.event.TOWER_FIGHT, handler(self, self.onTowerBattle))
	self:registerEvent(xyd.event.TOWER_RECORDS, handler(self, self.onTowerRecord))
	self:registerEvent(xyd.event.TOWER_SELF_REPORT, handler(self, self.onMyTowerReport))
	self:registerEvent(xyd.event.TOWER_REPORT, handler(self, self.onTowerReport))
	self:registerEvent(xyd.event.TOWER_PRACTICE, handler(self, self.onTowerPractice))
end

function TowerMap:reqMapInfo()
	local msg = messages_pb:tower_map_info_req()

	xyd.Backend.get():request(xyd.mid.TOWER_MAP_INFO, msg)
end

function TowerMap:onTowerMapInfo(event)
	self.mapInfo = event.data
	self.towerTicketTime = event.data.water_time
	self.stage_ = event.data.max_stage + 1
	self.stage_ = math.min(xyd.tables.miscTable:getNumber("tower_top", "value") + 1, self.stage_)
	self.start_record_stage = event.data.start_record_id
	self.end_record_stage = event.data.end_record_id

	xyd.models.oldSchool:checkOpenState(2)
end

function TowerMap:onTowerBattle(event)
	if event.data.is_win ~= 0 then
		local activity = xyd.models.activity:getActivity(xyd.ActivityID.TOWER_FUND_GIFTBAG)

		if activity then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TOWER_FUND_GIFTBAG, function ()
				self.stage_ = event.data.stage_id + 1
				self.stage_ = math.min(xyd.tables.miscTable:getNumber("tower_top", "value") + 1, self.stage_)
				self.end_record_stage = self.end_record_stage + 1
				self.end_record_stage = math.min(self.end_record_stage, self.stage_)
			end)
		else
			self.stage_ = event.data.stage_id + 1
			self.stage_ = math.min(xyd.tables.miscTable:getNumber("tower_top", "value") + 1, self.stage_)
			self.end_record_stage = self.end_record_stage + 1
			self.end_record_stage = math.min(self.end_record_stage, self.stage_)
		end
	end

	if event.data.water_time or event.data.water_time == 0 then
		self.towerTicketTime = event.data.water_time
	end

	if event.data.is_new == 1 then
		self.records[event.data.stage_id] = nil
	end

	xyd.models.oldSchool:checkOpenState(2)

	local needTowerStage = tonumber(xyd.tables.miscTable:getVal("shrine_open_limit", "value"))

	if needTowerStage <= self.stage_ then
		xyd.models.shrineHurdleModel:reqShineHurdleInfo()
		xyd.models.shrineHurdleModel:getHistoryInfo()
	end
end

function TowerMap:onTowerPractice(event)
	if event.data.is_new == 1 then
		self.records[event.data.stage_id] = nil
	end

	self.my_records[event.data.stage_id] = nil
end

function TowerMap:getTicket()
	if not xyd.getServerTime() then
		return xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET)
	end

	local time = xyd.getServerTime() - self.towerTicketTime
	local cd = xyd.tables.miscTable:getNumber("tower_water_cd", "value")

	if time < cd then
		return xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET)
	end

	local max = xyd.tables.miscTable:getNumber("tower_water_max", "value")
	local delta = math.floor(time / cd)
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET) + delta
	local min = math.min(max, num)

	return min
end

function TowerMap:getLeftTime()
	local max = xyd.tables.miscTable:getNumber("tower_water_max", "value")

	if max <= self:getTicket() then
		return 0
	end

	local time = xyd.getServerTime() - self.towerTicketTime
	local cd = xyd.tables.miscTable:getNumber("tower_water_cd", "value")
	local leftTime = cd - time % cd

	return leftTime
end

function TowerMap:reqStageRecord(stageID)
	local msg = messages_pb:tower_records_req()
	msg.stage_id = stageID

	xyd.Backend:get():request(xyd.mid.TOWER_RECORDS, msg)
end

function TowerMap:onMyTowerReport(event)
	local stage_id = event.data.stage_id
	local battleReport = event.data.battle_report

	if battleReport and not battleReport.teamA[1] then
		return
	end

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(event.data.battle_report)
		report.battle_version = battleReport.battle_version
		self.my_records[stage_id] = {
			stage_id = stage_id,
			battle_report = report
		}
	else
		self.my_records[stage_id] = event.data
	end
end

function TowerMap:getMyTowerReport(stageID)
	return self.my_records[stageID]
end

function TowerMap:reqMyTowerReport(stageID)
	local msg = messages_pb:tower_self_report_req()
	msg.stage_id = stageID

	xyd.Backend:get():request(xyd.mid.TOWER_SELF_REPORT, msg)
end

function TowerMap:onTowerRecord(event)
	local stage_id = event.data.stage_id

	if not stage_id then
		return
	end

	self.records[stage_id] = event.data.records
end

function TowerMap:getTowerRecord(stageID)
	return self.records[stageID]
end

function TowerMap:reqTowerReport(stageID, recordID)
	local msg = messages_pb:tower_report_req()
	msg.stage_id = stageID
	msg.record_id = recordID

	xyd.Backend:get():request(xyd.mid.TOWER_REPORT, msg)
end

function TowerMap:onTowerReport(event)
	local data = event.data
	local recordID = data.record_id
	local stageID = data.stage_id
	local battleReport = data.battle_report

	if battleReport and battleReport.random_seed and battleReport.random_seed > 0 then
		local report = xyd.BattleController.get():createReport(data.battle_report)
		local params = {
			stage_id = stageID,
			record_id = recordID,
			battle_report = report
		}
		self.towerReports[tostring(stageID) .. "_" .. tostring(recordID)] = params
	else
		self.towerReports[tostring(stageID) .. "_" .. tostring(recordID)] = data
	end
end

function TowerMap:getTowerReport(stageID, recordID)
	local key = tostring(stageID) .. "_" .. tostring(recordID)

	return self.towerReports[key]
end

function TowerMap:isRequireTowerInfo()
	local time = xyd.getServerTime() - self.towerTicketTime
	local cd = xyd.tables.miscTable:getNumber("tower_water_cd", "value")
	local max = xyd.tables.miscTable:getNumber("tower_water_max", "value")
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.TOWER_TICKET)

	return cd <= time and num < max
end

function TowerMap:readStorageFormation()
	local dbVal = xyd.db.formation:getValue(xyd.BattleType.TOWER)

	if not dbVal then
		return false
	end

	local data = require("cjson").decode(dbVal)

	if not data.partners then
		return false
	end

	self.pet = data.pet_id or 0
	local tmpPartnerList = data.partners
	local nowPartnerList = {}

	for i = #tmpPartnerList, 1, -1 do
		local sPartnerID = tonumber(tmpPartnerList[i])

		if xyd.models.slot:getPartner(sPartnerID) then
			nowPartnerList[i] = {
				partner_id = sPartnerID,
				pos = i
			}
		end
	end

	return nowPartnerList
end

local function addFightPartnerMsg(protoMsg, partnerParams)
	for i, partnerInfo in pairs(partnerParams) do
		local fightPartnerMsg = messages_pb.fight_partner()
		fightPartnerMsg.partner_id = partnerInfo.partner_id
		fightPartnerMsg.pos = partnerInfo.pos

		table.insert(protoMsg.partners, fightPartnerMsg)
	end
end

function TowerMap:TowerBattle(stage_id)
	local msg = messages_pb.tower_fight_req()
	msg.pet_id = self.pet or 0
	local formation_id = xyd.db.misc:getValue("tower_battle_formation")

	if formation_id and tonumber(formation_id) > 0 then
		msg.formation_id = tonumber(formation_id)
	else
		local partnerParams = self:readStorageFormation()

		addFightPartnerMsg(msg, partnerParams)
	end

	xyd.Backend.get():request(xyd.mid.TOWER_FIGHT, msg)
end

function TowerMap:isSkipReport(state)
	if state == xyd.BattleType.TOWER and self.stage_ < 200 then
		return false
	end

	local state = xyd.db.misc:getValue("tower_skip_report")

	if state and tonumber(state) == 1 then
		return true
	else
		return false
	end
end

return TowerMap
