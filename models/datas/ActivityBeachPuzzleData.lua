local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBeachPuzzleData = class("ActivityBeachPuzzleData", ActivityData, true)

function ActivityBeachPuzzleData:getRedMarkState()
	local cost = xyd.tables.miscTable:split2num("activity_beach_puzzle_cost", "value", "#")
	local redState = false
	local awardParts = self.detail_.awarded_zones
	local linePos = xyd.tables.activityBeachPuzzleTable:getLinePos(self.detail_.beach_id)
	local partNum = #linePos

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) or #awardParts == #linePos then
		redState = true
	end

	if self:isFirstRedMark() then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BEACH_PUZZLE, redState)

	return redState
end

function ActivityBeachPuzzleData:register()
	self:registerEvent(xyd.event.OPEN_NEW_BEACH_PUZZLE, self.onOpenNewBeach, self)
end

function ActivityBeachPuzzleData:getUpdateTime()
	return self.end_time
end

function ActivityBeachPuzzleData:onOpenNewBeach(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BEACH_PUZZLE, function ()
		self.detail_.beach_id = event.data.beach_id
		self.detail_.awarded_zones = {}
		self.detail_.areas = {}
	end)
end

function ActivityBeachPuzzleData:initAreaData()
	local round = self:getRound()
	local areaData = xyd.tables.activityBeachPuzzleTable:getArea(round)

	if not self.areaList_ then
		self.areaList_ = {}
	end

	if not self.areaList_[tonumber(round)] then
		self.areaList_[tonumber(round)] = {}
	end

	for index, data in ipairs(areaData) do
		for i = 1, #data do
			if not self.areaList_[tonumber(round)][index] then
				self.areaList_[tonumber(round)][index] = {}
			end

			local num = data[i]
			self.areaList_[tonumber(round)][index][num] = 0
		end
	end
end

function ActivityBeachPuzzleData:onAward(data)
	if not data then
		return
	end

	self.changeAreas = {}
	self.changeZones = {}
	local details = require("cjson").decode(data.detail)

	dump(details, "details")

	for _, id in ipairs(details.info.areas) do
		if xyd.arrayIndexOf(self.detail_.areas, id) <= 0 then
			table.insert(self.changeAreas, id)
		end
	end

	self.detail_.areas = details.info.areas

	for _, id in ipairs(details.info.awarded_zones) do
		if xyd.arrayIndexOf(self.detail_.awarded_zones, id) <= 0 then
			table.insert(self.changeZones, id)
		end
	end

	self.detail_.awarded_zones = details.info.awarded_zones
end

function ActivityBeachPuzzleData:getNewUnlockData()
	return self.changeAreas, self.changeZones
end

return ActivityBeachPuzzleData
