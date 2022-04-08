local BaseModel = import(".BaseModel")
local NewbieCamp = class("NewbieCamp", BaseModel)

function NewbieCamp:ctor()
	NewbieCamp.super.ctor(self)

	self.list_ = {}
	self.structure_data_list_ = {}
	self.count_by_phase_ = {}
	self.lost_missions_ = {}
	self.award_final_ = {}

	self:onRegister()
end

function NewbieCamp:onRegister()
	self:registerEvent(xyd.event.GET_ROOKIE_MISSION_LIST, handler(self, self.onGetMissionList))
	self:registerEvent(xyd.event.GET_ROOKIE_MISSION_AWARD, handler(self, self.onGetMissionAward))
end

function NewbieCamp:onGetMissionList(event)
	self:onGetData(event)
	self:sortList()
end

function NewbieCamp:onGetMissionAward(event)
	self:onGetAward(event)
	self:sortList()
end

function NewbieCamp:reqData()
	local msg = messages_pb.get_rookie_mission_list_req()

	xyd.Backend.get():request(xyd.mid.GET_ROOKIE_MISSION_LIST, msg)
end

function NewbieCamp:reqAward(mission_id)
	local msg = messages_pb.get_rookie_mission_award_req()
	msg.mission_id = mission_id

	xyd.Backend.get():request(xyd.mid.GET_ROOKIE_MISSION_AWARD, msg)
end

function NewbieCamp:onGetData(event)
	local list = event.data.missions
	self.structure_data_list_ = {}
	self.count_by_phase_ = {}

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBIE_CAMP, function ()
		xyd.models.redMark:setMark(xyd.RedMarkType.NEWBIE_CAMP, false)

		for i = 1, #list do
			local data = list[i]
			local phase_id = xyd.tables.newbieCampTable:getPhaseId(data.mission_id)

			if not self.structure_data_list_[phase_id] then
				self.structure_data_list_[phase_id] = {}
			end

			if not self.count_by_phase_[phase_id] then
				self.count_by_phase_[phase_id] = 0
			end

			local status = 0

			if tonumber(data.is_completed) == 1 then
				status = status + 1
			end

			if tonumber(data.is_awarded) == 1 then
				status = status + 1
			end

			if status ~= 0 and xyd.tables.newbieCampTable:getIsHide(data.mission_id) ~= 1 then
				self.count_by_phase_[phase_id] = self.count_by_phase_[phase_id] + 1
			end

			local params = {
				id = data.mission_id,
				value = data.value,
				status = status
			}

			if status == 1 and xyd.tables.newbieCampTable:getIsHide(data.mission_id) ~= 1 then
				xyd.models.redMark:setMark(xyd.RedMarkType.NEWBIE_CAMP, true)
			end

			if status == 2 then
				self.award_final_[data.mission_id] = true
			end

			if xyd.tables.newbieCampTable:getIsHide(data.mission_id) ~= 1 then
				table.insert(self.structure_data_list_[phase_id], params)
			elseif status == 1 then
				table.insert(self.lost_missions_, data.mission_id)
			end
		end
	end)
	xyd.models.activity:updateFuncEntry(xyd.ActivityID.NEWBIE_CAMP)
end

function NewbieCamp:sortList()
	for i = 1, #self.structure_data_list_ do
		if self.structure_data_list_[i] then
			local list = self.structure_data_list_[i]

			table.sort(list, function (a, b)
				if a.status == 1 and b.status == 1 then
					return xyd.tables.newbieCampTable:getRank(a.id) < xyd.tables.newbieCampTable:getRank(b.id)
				elseif a.status == 1 then
					return true
				elseif b.status == 1 then
					return false
				else
					if a.status ~= b.status then
						return a.status < b.status
					end

					return xyd.tables.newbieCampTable:getRank(a.id) < xyd.tables.newbieCampTable:getRank(b.id)
				end
			end)
		end
	end
end

function NewbieCamp:reqLostAward()
	for i = 1, #self.lost_missions_ do
		local id = self.lost_missions_[i]
		local phase_id = xyd.tables.newbieCampTable:getPhaseId(id)

		if self:checkAllAwardByPhase(phase_id) then
			self:reqAward(id)
		end
	end

	self.lost_missions_ = {}
end

function NewbieCamp:onGetAward(event)
	local id = event.data.mission_id
	self.award_final_[id] = true

	if xyd.tables.newbieCampTable:getIsHide(id) == 1 then
		self:alertItems(id)

		return
	end

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEWBIE_CAMP, function ()
		local phase_id = xyd.tables.newbieCampTable:getPhaseId(id)
		local list = self.structure_data_list_[phase_id]

		xyd.models.redMark:setMark(xyd.RedMarkType.NEWBIE_CAMP, false)

		for i = 1, #list do
			if list[i].id == id then
				list[i].status = 2

				self:alertItems(id)
			end

			if list[i].status == 1 then
				xyd.models.redMark:setMark(xyd.RedMarkType.NEWBIE_CAMP, true)
			end
		end

		for i = 1, 3 do
			local list = self.structure_data_list_[i]

			for j = 1, #list do
				if list[j].status == 1 then
					xyd.models.redMark:setMark(xyd.RedMarkType.NEWBIE_CAMP, true)

					break
				end
			end
		end

		if self:checkAllAwardByPhase(phase_id) then
			local ids = xyd.tables.newbieCampTable:getIdsByPhase(phase_id)
			local mission_id = nil

			for i = 1, #ids do
				local id = ids[i]

				if xyd.tables.newbieCampTable:getIsHide(id) == 1 then
					mission_id = id
				end
			end

			if mission_id and not self.award_final_[mission_id] then
				self:reqAward(mission_id)
			end
		end
	end)
end

function NewbieCamp:alertItems(id)
	local items_data = xyd.tables.newbieCampTable:getAward(id)
	local items = {}

	for i = 1, #items_data do
		table.insert(items, {
			item_id = items_data[i][1],
			item_num = items_data[i][2]
		})
	end

	local win_list = xyd.WindowManager.get():getWindow("newbie_camp_list_window")

	xyd.itemFloat(items, nil, win_list.floatRoot_)
end

function NewbieCamp:getAwardInfo()
	return self.award_final_
end

function NewbieCamp:getStructureDataByPhase(phase_id)
	return self.structure_data_list_[phase_id] or {}
end

function NewbieCamp:getCountByPhase(phase_id)
	return self.count_by_phase_[phase_id] or {}
end

function NewbieCamp:checkCompletPhase(phase_id)
	local all_count = xyd.tables.newbieCampTable:getCountByPhase(phase_id)

	return all_count == self:getCountByPhase(phase_id)
end

function NewbieCamp:checkLockByPhase(phase_id)
	local limit_lev = xyd.tables.newbieCampBoardTable:getUnlockLev(phase_id)
	local cur_lev = xyd.models.backpack:getLev()

	if limit_lev <= cur_lev then
		return false
	end

	local limit_phase = phase_id - 1

	if limit_phase > 0 then
		return not self:checkCompletPhase(phase_id - 1)
	end

	return true
end

function NewbieCamp:checkAllAwardByPhase(phase_id)
	local list = self:getStructureDataByPhase(phase_id)

	for i = 1, #list do
		local data = list[i]

		if data.status ~= 2 then
			return false
		end
	end

	return true
end

return NewbieCamp
