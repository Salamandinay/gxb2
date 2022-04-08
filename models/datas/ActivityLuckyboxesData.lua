local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLuckyboxesData = class("ActivityLuckyboxesData", ActivityData, true)

function ActivityLuckyboxesData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLuckyboxesData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self:getRedPointOfSingleDraw() == true then
		red = true
	end

	if self:getRedPointOfTenDraw() == true then
		red = true
	end

	if self:getRedPointOfGiftbag() == true then
		red = true
	end

	if self:getRedPointOfChooseSpecialAward() == true then
		red = true
	end

	return red
end

function ActivityLuckyboxesData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_LUCKYBOXES then
			local detail = json.decode(data.detail)

			if detail.info.cur_select[2] == 0 then
				local list = self:getSpecialAwardList()
				self.lastSelect = self.detail.cur_select
			else
				self.lastSelect = nil
			end

			self.detail = detail.info
		end
	end)
	self:registerEvent(xyd.event.LABA_SELECT_AWARD, function (event)
		local data = event.data
		self.detail.cur_select[1] = data.cur_select[1]
		self.detail.cur_select[2] = data.cur_select[2]
	end)
end

function ActivityLuckyboxesData:getNormalAwardList()
	if not self.normalAwardList then
		self.normalAwardList = {}
		local ids = xyd.tables.dropboxShowTable:getIdsByBoxId(32008).list

		for i = 1, 12 do
			local id = ids[i]
			local award = {
				xyd.tables.dropboxShowTable:getItem(id)[1],
				xyd.tables.dropboxShowTable:getItem(id)[2]
			}

			table.insert(self.normalAwardList, award)
		end
	end

	return self.normalAwardList
end

function ActivityLuckyboxesData:getSpecialAwardList()
	self.specialAwardList = {}
	local ids = xyd.tables.activityLuckyboxesAwardTable:getIDs()

	for i = 1, #ids do
		local id = i
		local awards = xyd.tables.activityLuckyboxesAwardTable:getAwards(id)

		for j = 1, #awards do
			awards[j].awarded = false
		end

		table.insert(self.specialAwardList, awards)
	end

	for i = 1, #self.detail.big_records do
		for j = 1, #self.detail.big_records[i] do
			local index = self.detail.big_records[i][j]
			self.specialAwardList[i][index].awarded = true
		end
	end

	return self.specialAwardList
end

function ActivityLuckyboxesData:getSingleDrawCost()
	if not self.singleDrawCost then
		self.singleDrawCost = {
			309,
			1
		}
	end

	return self.singleDrawCost
end

function ActivityLuckyboxesData:getTenDrawCost()
	if not self.tenDrawCost then
		self.tenDrawCost = {
			309,
			10
		}
	end

	return self.tenDrawCost
end

function ActivityLuckyboxesData:getNormalAwardData()
	local data = {}

	if not self.detail.records then
		return {}
	end

	for key, value in pairs(self.detail.records) do
		data[key] = value
	end

	return data
end

function ActivityLuckyboxesData:getSpecialAwardData()
	if self.detail.cur_select[2] == 0 then
		return nil
	end

	return self.detail.cur_select
end

function ActivityLuckyboxesData:getCurSpecialAwardItem()
	if self:getSpecialAwardData() == nil then
		return nil
	end

	local list = self:getSpecialAwardList()
	local select = self:getSpecialAwardData()

	return list[select[1]][select[2]]
end

function ActivityLuckyboxesData:getLuckyValue()
	return self.detail.point
end

function ActivityLuckyboxesData:getMaxLuckyValue()
	return xyd.tables.miscTable:getNumber("activity_luckyboxes_pointmax", "value")
end

function ActivityLuckyboxesData:getRedPointOfSingleDraw()
	local cost = self:getSingleDrawCost()

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		return true
	else
		return false
	end
end

function ActivityLuckyboxesData:getRedPointOfTenDraw()
	local cost = self:getTenDrawCost()

	if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		return true
	else
		return false
	end
end

function ActivityLuckyboxesData:getRedPointOfGiftbag()
	local giftbagData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LUCKYBOXES_GIFTBAG)

	if giftbagData then
		return giftbagData:getRedPointOfGiftbag()
	else
		return false
	end
end

function ActivityLuckyboxesData:getRedPointOfChooseSpecialAward()
	local data = self:getSpecialAwardData()

	if data then
		return false
	else
		return true
	end
end

function ActivityLuckyboxesData:getCurLayerSpecialAward()
	local curLayer = 1
	local curLayerRecord = {}

	for i = 1, #self.detail.big_records do
		if #self.detail.big_records[i] < 3 then
			break
		else
			curLayer = curLayer + 1
		end
	end

	if curLayer > #self.detail.big_records then
		curLayer = #self.detail.big_records
	end

	local list = self:getSpecialAwardList()
	local awards = list[curLayer]

	return awards
end

function ActivityLuckyboxesData:getCurLayer()
	local curLayer = 1
	local curLayerRecord = {}

	for i = 1, #self.detail.big_records do
		if #self.detail.big_records[i] < 3 then
			break
		else
			curLayer = curLayer + 1
		end
	end

	if curLayer > #self.detail.big_records then
		curLayer = #self.detail.big_records
	end

	return curLayer
end

return ActivityLuckyboxesData
