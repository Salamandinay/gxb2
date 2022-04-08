local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySantaVisitData = class("ActivitySantaVisitData", ActivityData, true)

function ActivitySantaVisitData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySantaVisitData:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false
	end

	if not red and self:isFirstRedMark() then
		red = true
	end

	if not red and self:getRedPointOfDraw() == true then
		red = true
	end

	if not red and self:getRedPointOfCanGetLevelAward() == true then
		red = true
	end

	if not red and self:getRedPointOfPerSignin() == true then
		red = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SANTA_VISIT, red)

	return red
end

function ActivitySantaVisitData:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_SANTA_VISIT then
			local detail = json.decode(data.detail)

			if not detail.table_id then
				local award_ids = detail.award_ids

				for i = 1, #award_ids do
					local index = award_ids[i]
					local maxLevel = xyd.tables.activityChristmasSocksTable:getAwardMaxLevel(index)

					if self.detail.lvs[index] < maxLevel then
						self.detail.lvs[index] = self.detail.lvs[index] + 1
					end
				end

				local items = detail.items

				for i = 1, #items do
					local item = items[i]

					if not self.detail.items[tostring(item.item_id)] then
						self.detail.items[tostring(item.item_id)] = item.item_num
					else
						self.detail.items[tostring(item.item_id)] = self.detail.items[tostring(item.item_id)] + item.item_num
					end
				end
			else
				self.detail.awards[detail.table_id] = self.detail.awards[detail.table_id] + 1
			end
		end
	end)

	self.PerSignInRedPoint = true
end

function ActivitySantaVisitData:getAwardList()
	local ids = xyd.tables.activityChristmasSocksTable:getIDs()
	self.awardList = {}

	for i = 1, #ids do
		local lev = self.detail.lvs[i]
		local award = xyd.tables.activityChristmasSocksTable:getAward(i, lev)

		table.insert(self.awardList, {
			award[1],
			award[2],
			lev
		})
	end

	return self.awardList
end

function ActivitySantaVisitData:getResource1()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_cost", "value", "#")

	return data
end

function ActivitySantaVisitData:getResource2()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_get", "value", "#")

	return data
end

function ActivitySantaVisitData:getHaveGotAwardList()
	return self.detail.items
end

function ActivitySantaVisitData:getCurLevel()
	self.curLevel = 0

	for i = 1, #self.detail.lvs do
		self.curLevel = self.curLevel + self.detail.lvs[i]
	end

	return self.curLevel
end

function ActivitySantaVisitData:getLevelAwardedData()
	return self.detail.awards
end

function ActivitySantaVisitData:getSingleCost()
	local data = xyd.tables.miscTable:split2Cost("activity_christmas_socks_cost", "value", "#")

	return data
end

function ActivitySantaVisitData:getSingleDrawLimit()
	return xyd.tables.miscTable:getNumber("activity_christmas_socks_max", "value")
end

function ActivitySantaVisitData:getRedPointOfDraw()
	local flag = false
	local singleCost = self:getSingleCost()

	if singleCost[2] <= xyd.models.backpack:getItemNumByID(singleCost[1]) then
		flag = true
	end

	return flag
end

function ActivitySantaVisitData:getRedPointOfCanGetLevelAward()
	local flag = false
	local ids = xyd.tables.activityChristmasSocksLevelTable:getIDs()

	for j in pairs(ids) do
		local data = {
			max_value = xyd.tables.activityChristmasSocksLevelTable:getLevel(j),
			cur_value = self:getCurLevel()
		}

		if self:getLevelAwardedData()[j] == 0 and data.max_value <= data.cur_value then
			flag = true
		end
	end

	return flag
end

function ActivitySantaVisitData:getRedPointOfPerSignin()
	return self.PerSignInRedPoint
end

return ActivitySantaVisitData
