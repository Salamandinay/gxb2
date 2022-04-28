local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySpaceExploreData = class("ActivitySpaceExploreData", ActivityData, true)

function ActivitySpaceExploreData:ctor(params)
	ActivityData.ctor(self, params)
	self:registerEvent(xyd.event.SPACE_EXPLORE_OPEN_GRID, handler(self, self.openGridBack))
	self:registerEvent(xyd.event.SPACE_EXPLORE_GRID_EVENT, handler(self, self.onGridEventBack))
	self:registerEvent(xyd.event.SPACE_EXPLORE_LEVEL_UP, handler(self, self.levelUpBack))

	local partner_ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

	for i in pairs(partner_ids) do
		if not self.detail_.partners[i] then
			table.insert(self.detail.partners, i, 0)
		end
	end
end

function ActivitySpaceExploreData:setData(params)
	ActivitySpaceExploreData.super.setData(self, params)

	local partner_ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

	for i in pairs(partner_ids) do
		if not self.detail_.partners[i] then
			table.insert(self.detail.partners, i, 0)
		end
	end
end

function ActivitySpaceExploreData:setDataNodecode(params)
	ActivitySpaceExploreData.super.setDataNodecode(self, params)

	local partner_ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

	for i in pairs(partner_ids) do
		if not self.detail_.partners[i] then
			table.insert(self.detail.partners, i, 0)
		end
	end
end

function ActivitySpaceExploreData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySpaceExploreData:onAward(event)
end

function ActivitySpaceExploreData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = true

	return false
end

function ActivitySpaceExploreData:openGridBack(event)
	local data = xyd.decodeProtoBuf(event.data)
	self.detail.map_content[data.id] = data.content

	if self.detail.map[data.id] == 0 then
		self.detail.map[data.id] = 1
	elseif self.detail.map[data.id] == 1 then
		self.detail.map[data.id] = 3
	elseif self.detail.map[data.id] == 4 then
		self.detail.map[data.id] = 1
	end

	if data.content == "" then
		self.detail.map[data.id] = 3
	end
end

function ActivitySpaceExploreData:onGridEventBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "格子事件返回======")

	if data.is_win then
		if data.is_win == 1 then
			self.detail.map[data.id] = 3
		elseif data.is_win == 0 then
			self.detail.hurt_time = xyd.getServerTime() + xyd.tables.miscTable:getNumber("space_explore_hurt_time", "value")
		end
	elseif data.map and data.map_content then
		if data.items and #data.items > 0 then
			xyd.models.itemFloatModel:pushNewItems(data.items)
		end
	else
		if data.items and #data.items > 0 then
			xyd.models.itemFloatModel:pushNewItems(data.items)
		end

		self.detail.map[data.id] = 3
	end

	if data.items then
		if not self.detail.items then
			self.detail.items = {}
		end

		for i in pairs(data.items) do
			if self.detail.items[tostring(data.items[i].item_id)] then
				self.detail.items[tostring(data.items[i].item_id)] = self.detail.items[tostring(data.items[i].item_id)] + tonumber(data.items[i].item_num)
			else
				self.detail.items[tostring(data.items[i].item_id)] = tonumber(data.items[i].item_num)
			end
		end
	end
end

function ActivitySpaceExploreData:updateDoorBack(data)
	self.detail.map = data.map
	self.detail.map_content = data.map_content
	self.detail.stage_id = self.detail.stage_id + 1

	if data.place_id then
		self.detail.place_id = data.place_id
	end
end

function ActivitySpaceExploreData:levelUpBack(event)
	local data = xyd.decodeProtoBuf(event.data)

	dump(data, "升级事件返回======")

	local index = -1
	local ids = xyd.tables.activitySpaceExplorePartnerTable:getIDs()

	for i in pairs(ids) do
		if data.table_id == tonumber(ids[i]) then
			index = i

			break
		end
	end

	if index ~= -1 then
		if data.num > 0 then
			self.detail.partners[index] = self.detail.partners[index] + 1
			local max_lev = xyd.tables.activitySpaceExplorePartnerTable:getMaxLv(data.table_id)

			if max_lev < self.detail.partners[index] then
				self.detail.partners[index] = max_lev
			end
		else
			self.detail.partners[index] = self.detail.partners[index] + data.num

			if self.detail.partners[index] < 1 then
				self.detail.partners[index] = 1
			end
		end
	end

	local activitySpaceExploreMapWd = xyd.WindowManager.get():getWindow("activity_space_explore_map_window")

	if activitySpaceExploreMapWd then
		activitySpaceExploreMapWd:updateTeamInfoShow()
	end
end

return ActivitySpaceExploreData
