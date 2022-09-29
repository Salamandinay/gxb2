local ActivityData = import("app.models.ActivityData")
local ActivityPirateData = class("ActivityPirateData", ActivityData, true)

function ActivityPirateData:ctor(params)
	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_pirate_explore_cost"), "#", true)
	self.checkItemId = cost[1]
	self.checkItemNeedNum = cost[2]
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivityPirateData.super.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityPirateData:onItemChangeBack(event)
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

function ActivityPirateData:getGiftbagRedMarkState()
	local redState = false

	if self:getGiftbagProgress() == 1 and self:getFreeLeftTime() ~= 0 then
		redState = true
	end

	return redState
end

function ActivityPirateData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local redState = false

	if self.checkItemNeedNum <= self.checkBackpackItemNum then
		redState = true
	end

	if not self:checkFinishStory() and (not self.touchTime or not xyd.isSameDay(self.touchTime, xyd.getServerTime())) then
		redState = true
	end

	if self:getGiftbagRedMarkState() then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_PIRATE, redState)

	return redState
end

function ActivityPirateData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPirateData:checkFinishStory()
	local ids = xyd.tables.activityPiratePlotListTable:getIDs()

	for _, id in ipairs(ids) do
		local text_type = xyd.tables.activityPiratePlotListTable:getTextType(id)

		if text_type == 1 and xyd.arrayIndexOf(self.detail_.story_ids, id) < 0 then
			return false
		end
	end

	return true
end

function ActivityPirateData:onAward(data)
	if type(data) == "number" then
		for _, charge in pairs(self.detail_.charges) do
			if charge.table_id == data then
				charge.buy_times = charge.buy_times + 1
			end
		end
	else
		local detail = require("cjson").decode(data.detail)

		if detail.type == 0 then
			self.detail_.story_ids = detail.info.story_ids
		elseif detail.type == 1 then
			self.detail_ = detail.info
			local items = detail.items
			local shopData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE_SHOP)

			if shopData then
				local mission_infos = shopData.detail.missions

				for index, itemInfo in ipairs(items) do
					local item_id = itemInfo.item_id

					for __, missionData in ipairs(mission_infos) do
						local needItemID = xyd.tables.activityPirateMissionTable:getNeedItem(missionData.mission_id)

						if needItemID == tonumber(item_id) then
							local completeValue = xyd.tables.activityPirateMissionTable:getCompleteValue(missionData.mission_id)
							missionData.value = missionData.value + tonumber(itemInfo.item_num)

							if completeValue <= missionData.value then
								missionData.is_awarded = 1
								missionData.is_compelete = 1
							end
						end
					end
				end
			end
		elseif detail.type == 2 then
			self.detail_.free_award = detail.info.free_award
		end
	end
end

function ActivityPirateData:getPaidLeftTime()
	local charges = self.detail_.charges[1]
	local leftTime = charges.limit_times - charges.buy_times

	return leftTime
end

function ActivityPirateData:getFreeLeftTime()
	local limit = xyd.tables.miscTable:getNumber("activity_pirate_giftbag_free_awards_limit", "value")
	local leftTime = limit - self.detail_.free_award

	return leftTime
end

function ActivityPirateData:getMinute()
	return math.ceil((xyd.getServerTime() - self.start_time) / 60)
end

function ActivityPirateData:getCountsByMinute(minute)
	local tmp_a = 1.773336438199
	local tmp_b = 1.000005134437
	local tmp_c = -1164453.499
	local tmp_d = 125
	local tmp_e = 70000
	local tmp_f = 50
	local count = 0

	if minute >= 1440 then
		count = 250000

		return count
	end

	if minute < 660 then
		count = math.pow(minute, tmp_a)
	elseif minute >= 660 and minute < 1320 then
		count = math.log10(minute) / math.log10(tmp_b) + tmp_c
	elseif minute >= 1320 and minute < 1440 then
		math.randomseed(minute)

		count = tmp_d * minute + tmp_e + math.random(-tmp_f, tmp_f)
	end

	return math.min(250000, count)
end

function ActivityPirateData:getGiftbagProgress()
	local minute = self:getMinute()
	local progress = self:getCountsByMinute(minute) / 250000

	return progress
end

return ActivityPirateData
