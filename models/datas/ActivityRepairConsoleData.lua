local ActivityData = import("app.models.ActivityData")
local ActivityRepairConsole = class("ActivityRepairConsole", ActivityData, true)
local json = require("cjson")
local mainAwardReqList = {
	1,
	7,
	13,
	19,
	25
}

function ActivityRepairConsole:ctor(params)
	self.checkItemId = xyd.tables.miscTable:split2num("activity_repair_console_cost", "value", "#")[1]
	self.checkItemNeedNum = xyd.tables.miscTable:split2num("activity_repair_console_cost", "value", "#")[2]
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivityRepairConsole.super.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityRepairConsole:getUpdateTime()
	return self:getEndTime()
end

function ActivityRepairConsole:checkLine(line, mapData)
	local targets = xyd.tables.activityRepairConsoleAwardTable:getTarget(line)

	for i = 1, 5 do
		local target = targets[i]

		if mapData[target] == 0 then
			return false
		end
	end

	return true
end

function ActivityRepairConsole:onAward(data)
	local detail = json.decode(data.detail)
	local prev_map_data = self.detail_.map_data
	local prev_round = self.detail_.round
	self.onOpenNextRound = false
	self.jumpToNextRound = false
	self.detail_.map_data = detail.info.map_data
	self.detail_.round = detail.info.round
	self.openCards = {}
	self.blueCards = {}
	self.activateLines = {}
	self.normalAwards = {}
	self.surpriseAwards = {}

	dump(self.activateLines)

	for index, j in ipairs(detail.items) do
		local id = detail.ids[index]
		local awardRank = xyd.tables.activityRepairConsoleAwardTable:getRank(id)

		if awardRank == 11 then
			table.insert(self.surpriseAwards, detail.items[index])
		else
			table.insert(self.normalAwards, detail.items[index])
		end
	end

	if detail.type == 0 and prev_round ~= detail.info.round then
		self.jumpToNextRound = true
	else
		self.jumpToNextRound = false
	end

	for i = 1, 11 do
		if self.jumpToNextRound then
			if self:checkLine(i, detail.info.map_data) == self:checkLine(i, prev_map_data) then
				table.insert(self.activateLines, i)
			end
		elseif self:checkLine(i, detail.info.map_data) ~= self:checkLine(i, prev_map_data) then
			table.insert(self.activateLines, i)
		end
	end

	if detail.type == 0 then
		local prevState = 0
		local nowState = 0

		for i = 1, 25 do
			if self.jumpToNextRound then
				if prev_map_data[i] == detail.info.map_data[i] then
					table.insert(self.openCards, i)
				end
			elseif prev_map_data[i] ~= detail.info.map_data[i] then
				table.insert(self.openCards, i)
			end

			if prev_map_data[i] == 0 then
				table.insert(self.blueCards, i)
			end
		end

		for i = 1, #mainAwardReqList do
			prevState = prevState + prev_map_data[mainAwardReqList[i]]
			nowState = nowState + detail.info.map_data[mainAwardReqList[i]]
		end

		if prevState ~= 5 and nowState == 5 then
			self.onOpenNextRound = true
		else
			self.onOpenNextRound = false
		end
	end
end

function ActivityRepairConsole:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_repair_console_cost"), "#", true)
	local redState = false

	if cost[2] <= self.checkBackpackItemNum then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_REPAIR_CONSOLE, redState)

	return redState
end

function ActivityRepairConsole:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == self.checkItemId then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_REPAIR_CONSOLE, function ()
				self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)
			end)

			break
		end
	end
end

return ActivityRepairConsole
