local BaseModel = import(".BaseModel")
local SoulLand = class("SoulLand", BaseModel, true)
local json = require("cjson")
local Partner = import("app.models.Partner")

function SoulLand:ctor()
	self.records = {}
	self.towerReports = {}

	BaseModel.ctor(self)
	self:checkBeforFirstTime()
end

function SoulLand:onRegister()
	self:registerEvent(xyd.event.SOUL_LAND_BASE_INFO, self.onSoulLandBaseInfoBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_HANG_INFO, self.onSoulLandHangInfoBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_GET_HANG_INFO, self.onGetAwardHangInfoBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_GET_SUMMON_INFO, self.onSummonBaseInfoBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_SUMMON, self.onSoulLandSummonBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_FIGHT, self.onSoulLandFightBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_GET_SHOP, self.onShopBaseInfoBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_SHOP_BUY, self.onBuyShopBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_CHECK_OPEN, self.onChckOpenBack, self)
	self:registerEvent(xyd.event.SOUL_LAND_RECORDS, handler(self, self.onSoulLandRecord))
	self:registerEvent(xyd.event.SOUL_LAND_REPORT, handler(self, self.onSoulLandReport))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
	self:registerEvent(xyd.event.SYSTEM_REFRESH, self.systemRefresh, self)
	BaseModel.onRegister(self)
end

function SoulLand:onSendLandBaseInfo()
	local msg = messages_pb:soul_land_base_info_req()

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_BASE_INFO, msg)
end

function SoulLand:systemRefresh()
	if not self.isCheckReqOpen then
		self:reqCheckOpen()
	end
end

function SoulLand:reqCheckOpen()
	local msg = messages_pb.soul_land_check_open_req()

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_CHECK_OPEN, msg)
end

function SoulLand:onChckOpenBack(event)
	self.isCheckReqOpen = true

	self:onSendLandBaseInfo()
end

function SoulLand:onSoulLandBaseInfoBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "soul_land_base_info")

	self.map_info = data.map_info
	self.map_list = data.map_list

	if not self.ifFirstReqHangeInfo then
		self:reqHangInfo()

		self.ifFirstReqHangeInfo = true
	end

	self:checkEndTime()
	self:onItemChangeBack()
	xyd.addGlobalTimer(self.onItemChangeBack, 3, 2)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

	if not activityData then
		dump("requir soul land battle pass msg ")

		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = xyd.ActivityID.SOUL_LAND_BATTLE_PASS

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)
	end
end

function SoulLand:getMapInfo()
	return self.map_info
end

function SoulLand:checkIsOpen()
	if self.map_list then
		return true
	end

	return false
end

function SoulLand:partnerLvUpCheckOpen(lev)
	if not self:checkIsOpen() and xyd.tables.miscTable:getNumber("soul_land_open_lvl", "value") <= lev then
		self:onSendLandBaseInfo()
	end
end

function SoulLand:getMapList()
	return self.map_list
end

function SoulLand:checkBeforFirstTime()
	local startTime = xyd.tables.miscTable:getNumber("soul_land_start_time", "value")

	if xyd.getServerTime() < startTime then
		xyd.addGlobalTimer(function ()
			self:reqCheckOpen()
		end, startTime - xyd.getServerTime() + 1, 1)
	end
end

function SoulLand:isBeforStartTime()
	local startTime = xyd.tables.miscTable:getNumber("soul_land_start_time", "value")

	if xyd.getServerTime() < startTime then
		return true
	end

	return false
end

function SoulLand:getEndTime()
	local endTime = 0
	local startTime = xyd.tables.miscTable:getNumber("soul_land_start_time", "value")
	local cycleTime = xyd.tables.miscTable:getNumber("soul_land_cycle_time", "value")
	local disTime = xyd.getServerTime() - startTime

	if disTime > 0 then
		local nowNum = math.floor(disTime / cycleTime) + 1
		endTime = startTime + nowNum * cycleTime
	end

	return endTime
end

function SoulLand:getCount()
	return self:getMapInfo().count
end

function SoulLand:reqFight(fortId, stageId, partners, petId)
	local tableId = stageId
	local msg = messages_pb.soul_land_fight_req()
	msg.stage_id = tableId

	xyd.getFightPartnerMsg(msg.partners, partners)

	msg.pet_id = petId or 0

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_FIGHT, msg)
end

function SoulLand:reqHangInfo()
	local msg = messages_pb.soul_land_hang_info_req()

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_HANG_INFO, msg)
end

function SoulLand:reqCheckHangInfo()
	if not self.lastGetHangInfoTime or xyd.getServerTime() - self.lastGetHangInfoTime > 300 then
		self:reqHangInfo()
	end
end

function SoulLand:onSoulLandHangInfoBack(event)
	self.hangInfo = xyd.decodeProtoBuf(event.data)
	self.lastGetHangInfoTime = xyd.getServerTime()

	self:updateNextReqHang(self.hangInfo.hang_time)
end

function SoulLand:getSoulLandHangInfo()
	return self.hangInfo
end

function SoulLand:reqGetAwardHangInfo()
	local msg = messages_pb.soul_land_get_hang_info_req()

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_GET_HANG_INFO, msg)
end

function SoulLand:onGetAwardHangInfoBack(event)
	xyd.models.itemFloatModel:pushNewItems(event.data.economy_items)

	self.hangInfo.economy_items = nil
	self.hangInfo.hang_time = event.data.hang_time

	self:updateNextReqHang(self.hangInfo.hang_time)
end

function SoulLand:updateNextReqHang(time)
	local timeDis = xyd.getServerTime() - time

	if timeDis > 88200 then
		return
	end

	local afterTime = 300 - timeDis % 300

	if timeDis < 0 then
		afterTime = 299
	end

	print("next time===:", afterTime)

	if afterTime <= 0 then
		afterTime = 1
	end

	if afterTime > 0 then
		if self.hangTimeKey then
			xyd.removeGlobalTimer(self.hangTimeKey)
		end

		local allStage = 0

		for i in pairs(self:getMapList()) do
			allStage = allStage + tonumber(self:getMapList()[i].max_stage)
		end

		if allStage > 0 then
			self.hangTimeKey = xyd.addGlobalTimer(function ()
				self:reqHangInfo()
			end, afterTime + 1, 1)
		end
	end
end

function SoulLand:saveFortInfo(fortInfo)
	for i in pairs(self:getMapList()) do
		if self:getMapList()[i].fort_id == fortInfo.fort_id then
			self:getMapList()[i] = fortInfo
		end
	end
end

function SoulLand:saveMapInfo(mapInfo)
	self.map_info = mapInfo
end

function SoulLand:onSoulLandFightBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	local isWin = data.battle_report.isWin

	if isWin == 1 then
		if data.fort_info then
			self:saveFortInfo(data.fort_info)

			local stage = data.fort_info.max_stage
			local id = xyd.tables.soulLandTable:getFortArr()[tonumber(data.fort_info.fort_id)][tonumber(stage)]
			local battlePassPoint = xyd.tables.soulLandTable:getBattlePassPoint(id)

			self:addBattlePassPoint(battlePassPoint)
		end

		if data.map_info then
			self:saveMapInfo(data.map_info)
		end
	end
end

function SoulLand:openFightWindow(fortId)
	local fortArr = xyd.tables.soulLandTable:getFortArr()
	local mapList = xyd.models.soulLand:getMapList()

	if tonumber(mapList[fortId].max_stage) < #fortArr[fortId] then
		xyd.WindowManager.get():openWindow("soul_land_fight_window", {
			fortId = fortId
		})
	else
		xyd.alertTips(__("SOUL_LAND_TEXT20"))
	end
end

function SoulLand:reqSummonBaseInfo()
	if not self.summonBaseInfo then
		local msg = messages_pb:soul_land_get_summon_info_req()

		xyd.Backend.get():request(xyd.mid.SOUL_LAND_GET_SUMMON_INFO, msg)
	end
end

function SoulLand:onSummonBaseInfoBack(event)
	self.summonBaseInfo = xyd.decodeProtoBuf(event.data)
end

function SoulLand:getSummonBaseInfo()
	return self.summonBaseInfo
end

function SoulLand:reqSummon(summonId, times)
	local cost = xyd.tables.soulLandEquip2GachaTable:getCost(summonId)

	if xyd.models.backpack:getItemNumByID(cost[1]) < times * cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	local spaceDis = xyd.tables.miscTable:getNumber("soul_equip_limit", "value") - xyd.models.slot:getSoulEquipLength()

	if times > spaceDis then
		xyd.alertTips(__("SOUL_EQUIP_BAGMAX_TIPS"))

		return
	end

	self.lastSummonTimes = times
	local msg = messages_pb:soul_land_summon_req()
	msg.summon_id = summonId
	msg.times = times

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_SUMMON, msg)
end

function SoulLand:onSoulLandSummonBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.summonBaseInfo = data.summon_info
	local num = 1

	if self.lastSummonTimes == 10 then
		num = 10
	end

	local cost = xyd.tables.soulLandEquip2GachaTable:getCost(data.summon_id)
	local items = {}

	for i, data in pairs(data.summon_result.items) do
		data.soulEquipID = data.equip_id

		table.insert(items, {
			item_num = 1,
			show_has_num = false,
			item_id = data.table_id,
			soulEquipInfo = data
		})
	end

	xyd.openWindow("gamble_rewards_window", {
		wnd_type = 4,
		data = items,
		cost = {
			cost[1],
			num * cost[2]
		},
		btnLabelText = __("GACHA_LIMIT_CALL_TIMES", num),
		buyCallback = function ()
			if xyd.models.backpack:getItemNumByID(cost[1]) < num * cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			self:reqSummon(data.summon_id, num)
		end
	})
end

function SoulLand:reqShopBaseInfo()
	if not self.shopBaseInfo then
		local msg = messages_pb:soul_land_get_shop_req()

		xyd.Backend.get():request(xyd.mid.SOUL_LAND_GET_SHOP, msg)
	end
end

function SoulLand:onShopBaseInfoBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.shopBaseInfo = data
end

function SoulLand:getShopBaseInfo()
	return self.shopBaseInfo
end

function SoulLand:reqBuyShop(tableId, num)
	local msg = messages_pb:soul_land_shop_buy_req()
	msg.table_id = tableId
	msg.num = num

	xyd.Backend.get():request(xyd.mid.SOUL_LAND_SHOP_BUY, msg)
end

function SoulLand:onBuyShopBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.shopBaseInfo.buy_times = data.buy_times

	xyd.models.itemFloatModel:pushNewItems(data.items)
	xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
end

function SoulLand:checkEndTime()
	local endTime = self:getEndTime()
	local dis = endTime - xyd.getServerTime()

	if dis >= 0 then
		if self.endTimeKey then
			xyd.removeGlobalTimer(self.endTimeKey)
		end

		self.endTimeKey = xyd.addGlobalTimer(function ()
			self:timeEndDeal()
		end, dis + 1, 1)
	end
end

function SoulLand:timeEndDeal()
	self.shopBaseInfo = nil
	self.summonBaseInfo = nil
	self.ifFirstReqHangeInfo = nil

	self:onSendLandBaseInfo()

	local soul_land_main_wd = xyd.WindowManager.get():getWindow("soul_land_main_window")

	if soul_land_main_wd then
		xyd.WindowManager.get():closeWindow("soul_land_main_window")
		xyd.WindowManager.get():closeWindow("soul_land_fight_window")
		xyd.WindowManager.get():closeWindow("soul_land_probability_window")
		xyd.WindowManager.get():closeWindow("soul_land_shop_window")
		xyd.WindowManager.get():closeWindow("soul_land_summon_window")
		xyd.alertConfirm(__("SOUL_LAND_TEXT22"), nil, __("SURE"))
	end

	local msg = messages_pb:get_activity_info_by_id_req()
	msg.activity_id = xyd.ActivityID.SOUL_LAND_BATTLE_PASS

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
end

function SoulLand:addBattlePassPoint(point)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

	activityData:addScore(point)
end

function SoulLand:reqStageRecord(stageID)
	local msg = messages_pb:soul_land_records_req()
	msg.stage_id = stageID

	xyd.Backend:get():request(xyd.mid.SOUL_LAND_RECORDS, msg)
end

function SoulLand:onSoulLandRecord(event)
	local stage_id = event.data.stage_id

	if not stage_id then
		return
	end

	self.records[stage_id] = event.data.records
end

function SoulLand:getSoulLandRecord(stageID)
	return self.records[stageID]
end

function SoulLand:reqSoulLandReport(stageID, recordID)
	local msg = messages_pb:soul_land_report_req()
	msg.stage_id = stageID
	msg.record_id = recordID

	xyd.Backend:get():request(xyd.mid.SOUL_LAND_REPORT, msg)
end

function SoulLand:onSoulLandReport(event)
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

function SoulLand:getSoulLandReport(stageID, recordID)
	local key = tostring(stageID) .. "_" .. tostring(recordID)

	return self.towerReports[key]
end

function SoulLand:onItemChangeBack(event)
	local cost1 = xyd.tables.soulLandEquip2GachaTable:getCost(1)
	local cost2 = xyd.tables.soulLandEquip2GachaTable:getCost(2)
	local hasTen = false

	if xyd.models.backpack:getItemNumByID(cost1[1]) >= 10 then
		hasTen = true
	elseif xyd.models.backpack:getItemNumByID(cost2[1]) >= 10 then
		hasTen = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.SOUL_LAND_SUMMON_TEN, hasTen)
end

return SoulLand
