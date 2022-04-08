local BaseModel = import(".BaseModel")
local StoryListModel = class("StoryListModel", BaseModel)
local MainPlotEpisodeTable = xyd.tables.mainPlotEpisodeTable
local MainPlotFortTable = xyd.tables.mainPlotFortTable
local MainPlotListTable = xyd.tables.mainPlotListTable
local ActivityPlotFortTable = xyd.tables.activityPlotFortTable
local ActivityPlotListTable = xyd.tables.activityPlotListTable

function StoryListModel:ctor()
	StoryListModel.super.ctor(self)

	self.episodeItems = {}
	self.main_fort = {}
	self.main_list = {}
	self.activity_fort = {}
	self.activity_list = {}
	self.main_fort_red = {}
	self.main_list_red = {}
	self.activity_fort_red = {}
	self.activity_list_red = {}
	self.unlock_plot_ids = {}
	self.unlock_act_plot_ids = {}
	self.keys = 0
	self.last_update_time = 0
	self.redMarkState = false
	self.key_limit = xyd.tables.miscTable:getNumber("plot_unlock_item_limit", "value")
end

function StoryListModel:onRegister()
	StoryListModel.super.onRegister(self)
	self:registerEvent(xyd.event.GET_PLOT_INFO, self.onGetPlotInfo, self)
	self:registerEvent(xyd.event.UNLOCK_MAIN_PLOT, self.onGetMainPlotInfo, self)
	self:registerEvent(xyd.event.UNLOCK_ACTIVITY_PLOT, self.onGetActivityPlotInfo, self)
end

function StoryListModel:reqPlotInfo()
	local msg = messages_pb.get_plot_info_req()

	xyd.Backend.get():request(xyd.mid.GET_PLOT_INFO, msg)
end

function StoryListModel:reqUnlock(listId)
	local msg = messages_pb.unlock_main_plot_req()
	msg.id = listId

	xyd.Backend.get():request(xyd.mid.UNLOCK_MAIN_PLOT, msg)
end

function StoryListModel:reqUnlockActivity(listId)
	local msg = messages_pb.unlock_activity_plot_req()
	msg.id = listId

	xyd.Backend.get():request(xyd.mid.UNLOCK_ACTIVITY_PLOT, msg)
end

function StoryListModel:onGetPlotInfo(event)
	local data = event.data
	self.unlock_plot_ids = data.plot_ids or {}
	self.unlock_act_plot_ids = data.act_plot_ids or {}
	self.keys = data.keys or 0
	self.last_update_time = data.update_time or 0
	self.max_stage = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN).max_stage

	self:onGetMainUnlockList()
	self:onGetActivityUnlockList()
	self:updateRedMarkState()
end

function StoryListModel:onGetMainPlotInfo(event)
	local data = event.data
	local id = data.id or 0
	self.keys = data.keys or 0
	self.last_update_time = data.update_time or 0

	table.insert(self.unlock_plot_ids, id)
	self:onGetMainUnlockList()
	self:updateRedMarkState()
end

function StoryListModel:onGetActivityPlotInfo(event)
	local data = event.data
	local id = data.id or 0
	self.keys = data.keys or 0
	self.last_update_time = data.update_time or 0

	table.insert(self.unlock_act_plot_ids, id)
	self:onGetActivityUnlockList()
	self:updateRedMarkState()
end

function StoryListModel:onGetMainUnlockList()
	local episodeIDs = MainPlotEpisodeTable:getIDs()

	for i = 1, #episodeIDs do
		local episodeId = episodeIDs[i]
		self.episodeItems[i] = false
		local fortIDs = MainPlotFortTable:getIDsByEpisodeID(episodeId)

		for j = 1, #fortIDs do
			local fortId = fortIDs[j]
			self.main_fort[fortId] = false
			local listIDs = MainPlotListTable:getIDsByFortID(fortId)

			for k = 1, #listIDs do
				local listId = listIDs[k]
				local flag = self:checkUnlock(listId)
				self.main_list[listId] = flag

				if flag then
					self.main_fort[fortId] = true
					self.episodeItems[i] = true
				end
			end

			local formerId = MainPlotListTable:getUnlockFormerListID(listIDs[1])

			if formerId == 0 or self.main_list[formerId] then
				self.main_fort[fortId] = true
				self.episodeItems[i] = true
			end
		end
	end
end

function StoryListModel:onGetActivityUnlockList()
	local fortIDs = ActivityPlotFortTable:getIds()
	local nowTime = xyd.getServerTime()

	for i = 1, #fortIDs do
		self.activity_fort[i] = false
		local fortId = fortIDs[i]
		local listIDs = ActivityPlotListTable:getIdsByFort(fortId)

		if listIDs and listIDs[1] and ActivityPlotListTable:checkIsShow(listIDs[1]) then
			for j = 1, #listIDs do
				local listId = listIDs[j]
				local flag = self:checkUnlock(listId, true)
				self.activity_list[listId] = flag

				if flag then
					self.activity_fort[i] = true
				elseif self:checkCanUnlockByListID(listId, true) then
					local endTime = ActivityPlotListTable:getRedMarkTime(listId)

					if nowTime < endTime then
						self.activity_fort_red[i] = true
						self.activity_list_red[listId] = true
					end
				end
			end

			local formerId = ActivityPlotListTable:getUnlockFormerListID(listIDs[1])

			if formerId == 0 or self.activity_list[formerId] then
				self.activity_fort[i] = true
			end
		end
	end
end

function StoryListModel:checkUnlock(listId, isActivity)
	if not isActivity then
		local stageId = MainPlotListTable:getStageID(listId)

		if stageId > 0 and stageId <= self.max_stage then
			return true
		end

		for i = 1, #self.unlock_plot_ids do
			if listId == self.unlock_plot_ids[i] then
				return true
			end
		end

		listId = MainPlotListTable:getActivityPlotId(listId) or 0
	end

	if listId ~= 0 then
		for i = 1, #self.unlock_act_plot_ids do
			if listId == self.unlock_act_plot_ids[i] then
				return true
			end
		end
	end

	return false
end

function StoryListModel:updateRedMarkState()
	local limit = xyd.tables.miscTable:getNumber("plot_unlock_item_limit", "value")

	if self:getKeys() < limit then
		self.redMarkState = false
	else
		self.redMarkState = false

		for i = 1, #self.activity_fort_red do
			if self.activity_fort_red[i] then
				self.redMarkState = true

				break
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.STORY_LIST_MEMORY, self.redMarkState)
end

function StoryListModel:getUnlockStateByEpisodeID(episodeId)
	return self.episodeItems[episodeId]
end

function StoryListModel:getUnlockStateByFortID(fortId, isActivity)
	if not isActivity then
		return self.main_fort[fortId]
	else
		return self.activity_fort[fortId]
	end
end

function StoryListModel:getUnlockStateByListID(listId, isActivity)
	if not isActivity then
		return self.main_list[listId]
	else
		return self.activity_list[listId]
	end
end

function StoryListModel:getProgressByFortID(fortId, isActivity)
	local value = 0
	local limit = 0
	local table = {}
	local listIDs = {}

	if not isActivity then
		table = self.main_list
		listIDs = MainPlotListTable:getIDsByFortID(fortId)
	else
		table = self.activity_list
		listIDs = ActivityPlotListTable:getIdsByFort(fortId)
	end

	for i = 1, #listIDs do
		local listId = listIDs[i]
		limit = limit + 1

		if table[listId] then
			value = value + 1
		end
	end

	return value, limit
end

function StoryListModel:checkEpisodeIsClear(episodeId)
	local fortIDs = MainPlotFortTable:getIDsByEpisodeID(episodeId)

	for j = 1, #fortIDs do
		local fortId = fortIDs[j]
		local listIDs = MainPlotListTable:getIDsByFortID(fortId)

		for k = 1, #listIDs do
			local listId = listIDs[k]

			if not self.main_list[listId] then
				return false
			end
		end
	end

	return true
end

function StoryListModel:checkCanUnlockByListID(listId, isActivity)
	if not isActivity then
		local formerId = MainPlotListTable:getUnlockFormerListID(listId)
		local activityPlotListId = MainPlotListTable:getActivityPlotId(listId) or 0

		if formerId == 0 then
			return true
		elseif formerId > 0 and activityPlotListId == 0 then
			return self.main_list[formerId]
		end

		if activityPlotListId > 0 then
			for i = formerId, 1, -1 do
				if not self.main_list[i] then
					return false
				end
			end

			return true
		end
	else
		local formerId = ActivityPlotListTable:getUnlockFormerListID(listId)

		if formerId == 0 then
			return true
		elseif formerId > 0 then
			return self.activity_list[formerId]
		end
	end
end

function StoryListModel:checkCanShowByFortID(fortId, isActivity)
	local listId = 0

	if not isActivity then
		if self.main_fort[fortId] then
			return true
		end

		local listIDs = MainPlotListTable:getIDsByFortID(fortId)
		local formerListId = MainPlotListTable:getUnlockFormerListID(listIDs[1])

		return self.main_fort[MainPlotListTable:getPlotFortID(formerListId)]
	else
		if self.activity_fort[fortId] then
			return true
		end

		local listIDs = ActivityPlotListTable:getIdsByFort(fortId)
		local formerListId = ActivityPlotListTable:getUnlockFormerListID(listIDs[1])

		return self.activity_fort[ActivityPlotListTable:getFortId(formerListId)]
	end
end

function StoryListModel:checkCanShowByListID(listId, isActivity)
	if not isActivity then
		if self.main_list[listId] then
			return true
		end

		local formerId = MainPlotListTable:getUnlockFormerListID(listId)
		local formerId_2 = MainPlotListTable:getUnlockFormerListID(formerId)

		if formerId == 0 or formerId_2 == 0 or self.main_list[formerId_2] then
			return true
		end
	else
		if self.activity_list[listId] then
			return true
		end

		local formerId = ActivityPlotListTable:getUnlockFormerListID(listId)
		local formerId_2 = ActivityPlotListTable:getUnlockFormerListID(formerId)

		if formerId == 0 or formerId_2 == 0 or self.activity_list[formerId_2] then
			return true
		end
	end

	return false
end

function StoryListModel:getKeys()
	local num = self.keys
	local recover = xyd.tables.miscTable:split2num("plot_unlock_item_recover", "value", "#")
	local add = math.floor((xyd.getServerTime() - self.last_update_time) / recover[1]) * recover[2]

	if add > 0 then
		num = num + add
	end

	if self.key_limit < num then
		return self.key_limit
	end

	return num
end

function StoryListModel:getLastUpdateTime()
	return self.last_update_time
end

function StoryListModel:getRedMarkStateByFortID(fortId, isActivity)
	if self:getKeys() ~= self.key_limit then
		return false
	end

	if not isActivity then
		return false
	else
		return self.activity_fort_red[fortId]
	end
end

function StoryListModel:getRedMarkStateByListID(listId, isActivity)
	if self:getKeys() ~= self.key_limit then
		return false
	end

	if not isActivity then
		return false
	else
		return self.activity_list_red[listId]
	end
end

return StoryListModel
