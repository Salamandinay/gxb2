local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local FairyTaleData = class("FairyTaleData", ActivityData, true)

function FairyTaleData:onAward(data)
	local realData = json.decode(data.detail)

	if realData.table_id then
		self.detail_.shop_infos[realData.table_id].buy_times = tonumber(self.detail_.shop_infos[realData.table_id].buy_times + realData.num)
	end
end

function FairyTaleData:reqMapInfo(map_id)
	local msg = messages_pb.get_fairy_map_info_req()
	msg.activity_id = xyd.ActivityID.FAIRY_TALE
	msg.map_id = map_id

	xyd.Backend.get():request(xyd.mid.GET_FAIRY_MAP_INFO, msg)

	if not self.mapInfoTimes_ then
		self.mapInfoTimes_ = {}
	end

	self.mapInfoTimes_[map_id] = xyd.getServerTime()
end

function FairyTaleData:reqCellInfo(cell_id)
	local msg = messages_pb.get_cell_info_req()
	msg.activity_id = xyd.ActivityID.FAIRY_TALE
	msg.cell_id = cell_id

	xyd.Backend.get():request(xyd.mid.GET_CELL_INFO, msg)

	if not self.cellInfoTimes_ then
		self.cellInfoTimes_ = {}
	end

	self.cellInfoTimes_[cell_id] = xyd.getServerTime()
end

function FairyTaleData:checkRefreshMap(map_id)
	if not self.mapInfoTimes_ or not self.mapInfoTimes_[map_id] then
		return true
	elseif self.mapInfoTimes_[map_id] + 120 < xyd.getServerTime() then
		return true
	else
		return false
	end
end

function FairyTaleData:checkRefreshCell(table_id)
	if not self.cellInfoTimes_ or not self.cellInfoTimes_[table_id] then
		return true
	elseif self.cellInfoTimes_[table_id] + 120 < xyd.getServerTime() then
		return true
	else
		return false
	end
end

function FairyTaleData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_FAIRY_MAP_INFO, handler(self, self.refreshMapInfo))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_CELL_INFO, handler(self, self.refreshCellInfo))
	self.eventProxyOuter_:addEventListener(xyd.event.FAIRY_CHALLENGE, handler(self, self.onCellChallenge))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxyOuter_:addEventListener(xyd.event.FAIRY_SELECT_BUFF, handler(self, self.onBuffChange))
end

function FairyTaleData:onBuffChange(event)
	self:updateBuffIds(json.decode(event.data.buff_ids))
end

function FairyTaleData:onCellChallenge(event)
	local data = event.data

	if data.is_video then
		return
	end

	local cellInfos = data.info
	local self_info = json.decode(data.self_info)

	self:refreshCellInfo({
		data = cellInfos
	})

	self.detail_.rank = self_info.rank
	self.detail_.score = self.detail_.score + data.score
	self.detail_.sta = self_info.sta
	local lev = self.detail_.lv
	local levNew = self_info.lv

	if levNew and lev < levNew then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.FAIRY_TALE)
	else
		self:updateMissionValue(cellInfos.table_id)
	end

	local mapId = xyd.tables.activityFairyTaleCellTable:getMapId(cellInfos.table_id)

	self:updateMission16(mapId)
end

function FairyTaleData:getEnergy()
	return xyd.models.backpack:getItemNumByID(xyd.ItemID.FAIRY_TALE_ENERGY)
end

function FairyTaleData:updateMissionValue(cell_id)
	local type = xyd.tables.activityFairyTaleCellTable:getCellType(cell_id)
	local isMain = xyd.tables.activityFairyTaleCellTable:getIsMain(cell_id)

	if isMain and isMain == 1 then
		self:updateMission(1)
	end

	if type == 2 or type == 5 then
		self:updateMission(2)
	elseif type == 3 then
		self:updateMission(3)
	elseif type == 4 then
		self:updateMission(4)
	end
end

function FairyTaleData:onItemChange(event)
	local items = event.data.items

	for _, item in ipairs(items) do
		if item.item_id == xyd.ItemID.FAIRY_TALE_ICON then
			self:updateMission(9, item.item_num)
		end
	end
end

function FairyTaleData:updateMission(type, num)
	local missions = self.detail_.mission_infos

	for _, info in ipairs(missions) do
		local mission_id = info.table_id
		local missionType = xyd.tables.activityFairyTaleMissionTable:getMissionType(mission_id)
		local compValue = xyd.tables.activityFairyTaleMissionTable:getCompleteValue(mission_id)
		local num = num or 1
		local isComp = info.is_completed

		if type and type == missionType then
			info.value = info.value + num
		end

		if compValue <= info.value then
			info.is_completed = 1
			info.value = compValue
		end

		if isComp ~= info.is_completed and info.is_completed == 1 then
			xyd.models.activity:reqActivityByID(xyd.ActivityID.FAIRY_TALE)

			break
		end
	end
end

function FairyTaleData:updateMission16(map_id)
	local missions = self.detail_.mission_infos

	for _, info in ipairs(missions) do
		local mission_id = info.table_id
		local missionType = xyd.tables.activityFairyTaleMissionTable:getMissionType(mission_id)
		local isComp = info.is_completed

		if missionType == 7 then
			local compValue = xyd.tables.activityFairyTaleMissionTable:getCompleteValue(mission_id)
			local index = xyd.arrayIndexOf(self.challengedMapIds_, map_id)

			if index < 0 then
				table.insert(self.challengedMapIds_, map_id)

				info.value = info.value + 1

				if compValue <= info.value then
					info.is_completed = 1
					info.value = compValue
				end

				if isComp ~= info.is_completed and info.is_completed == 1 then
					xyd.models.activity:reqActivityByID(xyd.ActivityID.FAIRY_TALE)

					break
				end
			end
		end
	end
end

function FairyTaleData:setEnergy(sta)
	self.detail_.sta = sta

	xyd.models.backpack:updateItems({
		{
			item_id = xyd.ItemID.FAIRY_TALE_ENERGY,
			item_num = sta
		}
	})
end

function FairyTaleData:setData(params)
	FairyTaleData.super.setData(self, params)
	self:updateSta()
	self:updateChallengeMapId()
end

function FairyTaleData:updateChallengeMapId()
	local tempIds = self.detail_.challenge_maps
	tempIds = xyd.split(tempIds, "|")
	local mapIds = {}

	for _, id in pairs(tempIds) do
		if id and id ~= "" and tonumber(id) > 0 then
			table.insert(mapIds, tonumber(id))
		end
	end

	self.challengedMapIds_ = mapIds
end

function FairyTaleData:updateSta()
	local sta = self.detail_.sta or 0
	local updateTime = self.detail_.update_time
	local maxSta = xyd.tables.miscTable:getVal("activity_fairytale_energy_max")

	if sta and tonumber(maxSta) < tonumber(sta) then
		return
	end

	local staTime = xyd.tables.miscTable:getVal("activity_fairytale_energy_cd")
	local addSta, _ = math.modf((xyd.getServerTime() - updateTime) / staTime)
	local newSta = sta + addSta

	if tonumber(maxSta) < newSta then
		newSta = tonumber(maxSta)
	end

	self.detail_.sta = newSta

	xyd.models.backpack:updateItems({
		{
			item_id = xyd.ItemID.FAIRY_TALE_ENERGY,
			item_num = newSta
		}
	})
end

function FairyTaleData:refreshMapInfo(event)
	local data = event.data
	local cellInfoList = data.cell_infos

	if cellInfoList then
		for _, info in ipairs(cellInfoList) do
			if not self.cellInfoList_ then
				self.cellInfoList_ = {}
			end

			self.cellInfoList_[tonumber(info.table_id)] = {
				table_id = info.table_id,
				is_completed = info.is_completed,
				is_unlock = info.is_unlock,
				value = info.value,
				detail = info.detail,
				battle_results = info.battle_results
			}

			if self.cellInfoList_[tonumber(info.table_id)].detail then
				print(self.cellInfoList_[tonumber(info.table_id)].detail)

				local word = string.sub(self.cellInfoList_[tonumber(info.table_id)].detail, 1, 1)

				if word ~= "|" then
					print(self.cellInfoList_[tonumber(info.table_id)].detail)

					self.cellInfoList_[tonumber(info.table_id)].detail = json.decode(info.detail)
				end
			end
		end
	end
end

function FairyTaleData:checkRefreshActivity()
	if not self.reqAcTime_ or xyd.getServerTime() - self.reqAcTime_ > 120 then
		self.reqAcTime_ = xyd.getServerTime()

		return true
	else
		return false
	end
end

function FairyTaleData:reqGetRecords(map_id)
	local msg = messages_pb.get_log_list_req()
	msg.activity_id = xyd.ActivityID.FAIRY_TALE
	msg.map_id = map_id

	xyd.Backend.get():request(xyd.mid.GET_LOG_LIST, msg)
end

function FairyTaleData:refreshCellInfo(event)
	local cellInfo = event.data
	local params = {
		table_id = cellInfo.table_id,
		is_completed = cellInfo.is_completed,
		is_unlock = cellInfo.is_unlock,
		value = cellInfo.value,
		detail = cellInfo.detail,
		battle_results = cellInfo.battle_results
	}

	if not self.cellInfoList_ then
		self.cellInfoList_ = {}
	end

	if cellInfo.detail and cellInfo.detail ~= "" then
		local word = string.sub(cellInfo.detail, 1, 1)

		if word ~= "|" then
			params.detail = json.decode(cellInfo.detail)
		end
	end

	self.cellInfoList_[tonumber(cellInfo.table_id)] = params
end

function FairyTaleData:getCellInfo()
	return self.cellInfoList_
end

function FairyTaleData:getCellInfoByTableId(id)
	return self.cellInfoList_[id]
end

function FairyTaleData:updatePlotList(mapid, newid)
	if self.detail.plot_ids then
		self.detail.plot_ids[mapid] = newid
	end
end

function FairyTaleData:updateBuffIds(buff_ids)
	self.detail.buff_ids = buff_ids
end

return FairyTaleData
