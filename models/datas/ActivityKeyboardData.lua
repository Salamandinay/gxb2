local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityKeyboardData = class("ActivityKeyboardData", ActivityData, true)
local awardTable = xyd.tables.activityKeyboardTable

function ActivityKeyboardData:ctor(params)
	ActivityData.ctor(self, params)

	local ids = awardTable:getIds()
	self.tableIDByLayer = {}
	self.lockNeed = {}

	for i = 1, #ids do
		local id = i
		local layer = awardTable:getLayer(id)

		if not self.tableIDByLayer[layer] then
			self.tableIDByLayer[layer] = {}
		end

		self.lockNeed[layer] = awardTable:getUnlock(id)

		table.insert(self.tableIDByLayer[layer], id)
	end
end

function ActivityKeyboardData:getUpdateTime()
	return self:getEndTime()
end

function ActivityKeyboardData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local val = xyd.db.misc:getValue("key_board_redmark")

	if not val or xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_KEYBOARD_ITEM) > 0 then
		return true
	end

	return false
end

function ActivityKeyboardData:onAward(data)
	local detail = json.decode(data.detail)
	self.detail_.awards = detail.info.awards
	self.detail_.senior_awards = detail.info.senior_awards

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_KEYBOARD, function ()
	end)
end

function ActivityKeyboardData:getCurLayer()
	return self.detail.curLayer or 1
end

function ActivityKeyboardData:getCurLayerItemsNum()
	return #self.tableIDByLayer[self:getCurLayer()]
end

function ActivityKeyboardData:getTableID(layer, index)
	return self.tableIDByLayer[layer][index]
end

function ActivityKeyboardData:getCurLayerTableIDs(layer)
	return self.tableIDByLayer[layer]
end

function ActivityKeyboardData:curLayerCanGetAward(layer)
	local result = false
	local ids = self:getCurLayerTableIDs(layer)

	for i = 1, #ids do
		local tableID = ids[i]

		for j = 1, #self.detail.senior_awards do
			if self.detail.senior_awards[j] == tableID then
				result = true

				return result
			end
		end
	end

	return result
end

function ActivityKeyboardData:checkLayerIsLock(layer)
	local result = false
	local num = #awardTable:getIds(2) - #self.detail.senior_awards

	if num < self.lockNeed[layer] then
		result = true
	end

	return result
end

function ActivityKeyboardData:getNeedToUnlock(layer)
	local num = #awardTable:getIds(2) - #self.detail.senior_awards

	return self.lockNeed[layer] - num
end

function ActivityKeyboardData:getMaxCanLayer()
	for i = #self.tableIDByLayer, 1, -1 do
		if self:checkLayerIsLock(i) == false and self:curLayerCanGetAward(i) == true then
			return i
		end
	end

	return 1
end

function ActivityKeyboardData:haveNewUnlock()
	local num = #awardTable:getIds(2) - #self.detail.senior_awards

	for i = 1, #self.lockNeed do
		if num == self.lockNeed[i] then
			return true
		end
	end

	return false
end

return ActivityKeyboardData
