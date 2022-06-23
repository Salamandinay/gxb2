local ActivityData = import("app.models.ActivityData")
local ActivityLostSpaceData = class("ActivityLostSpaceData", ActivityData, true)
local json = require("cjson")

function ActivityLostSpaceData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLostSpaceData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_LOST_SPACE then
		return
	end

	local data = xyd.decodeProtoBuf(data)
	local info = json.decode(data.detail)

	if info.type == xyd.ActivityLostSpaceType.OPEN_GRID then
		self:getContentArr()[info.id] = info.content

		if type(info.content) == "number" and info.content > 10000 and self.detail.is_double > 0 then
			self.detail.is_double = self.detail.is_double - 1
		end

		self:changeMapState(info.id)

		self.detail.last_id = info.id
	elseif info.type == xyd.ActivityLostSpaceType.GET_AWARD or info.type == xyd.ActivityLostSpaceType.TREASURE_GET_AWARD then
		for i, id in pairs(info.ids) do
			self:changeMapState(id)
		end

		local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")
		local touchType = xyd.ActivityLostSpaceTouchType.DEFAULT

		if activityLostSpaceMapWd then
			touchType = activityLostSpaceMapWd:getOnTouchGetAwardType()
		end

		if touchType == xyd.ActivityLostSpaceTouchType.GRID and #info.ids == 1 then
			local awardId = self:getContentArr()[info.ids[1]]
			local doubleNum = 1

			if awardId > 10000 then
				doubleNum = 2
			end

			awardId = awardId % 10000
			local awards = xyd.tables.activityLostSpaceBoxesTable:getAward(tonumber(awardId))

			xyd.models.itemFloatModel:pushNewItems({
				{
					item_id = awards[1],
					item_num = awards[2] * doubleNum
				}
			})
		elseif touchType == xyd.ActivityLostSpaceTouchType.AUTO_GET_ALL then
			local itemsArr = {}

			for i, id in pairs(info.ids) do
				local awardId = self:getContentArr()[info.ids[i]]
				local doubleNum = 1

				if awardId > 10000 then
					doubleNum = 2
				end

				awardId = awardId % 10000
				local awards = xyd.tables.activityLostSpaceBoxesTable:getAward(tonumber(awardId))

				table.insert(itemsArr, {
					item_id = awards[1],
					item_num = awards[2] * doubleNum
				})
			end

			xyd.alertItems(itemsArr)
		end
	elseif info.type == xyd.ActivityLostSpaceType.USE_EVENT or info.type == xyd.ActivityLostSpaceType.TREASURE_USE_EVENT then
		self:changeMapState(info.id)

		if info.content then
			self:getContentArr()[info.id] = info.content
		end

		local content = self:getContentArr()[info.id]

		if type(content) == "string" and #content > 0 then
			local events = xyd.split(content, "#")

			if events[1] == "e" then
				local eventId = tonumber(events[2])

				if eventId == xyd.ActivityLostSpaceEventType.DOUBLE then
					self.detail.is_double = self.detail.is_double + 1
					local pushItemId = xyd.tables.activityLostSpaceEventTable:getItemId(eventId)

					if pushItemId and pushItemId > 0 then
						xyd.models.itemFloatModel:pushNewItems({
							{
								item_num = 1,
								item_id = pushItemId
							}
						})
					end
				elseif eventId == xyd.ActivityLostSpaceEventType.SEEK then
					local searchPos = info.extra.pos
					self:getMapArr()[searchPos] = xyd.ActivityLostSpaceGridState.KNOW_POS
				elseif eventId == xyd.ActivityLostSpaceEventType.ENERGY_TWO or eventId == xyd.ActivityLostSpaceEventType.ENERGY_FOUR then
					local num = xyd.tables.activityLostSpaceEventTable:getEnergyNum(tonumber(eventId))

					xyd.models.itemFloatModel:pushNewItems({
						{
							item_id = xyd.ItemID.ACTIVITY_LOST_SPACE_SKILL_ENERGY,
							item_num = num
						}
					})
				elseif eventId == xyd.ActivityLostSpaceEventType.EXIT then
					local isTreaSure = self:getIsTreasure()
					self.detail = info.extra.info

					if self.detail.stage_id > #xyd.tables.activityLostSpaceAwardsTable:getIDs() then
						xyd.alertConfirm(__("ACTIVITY_LOST_SPACE_SKILL_PASS_TIPS"))
					end

					local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

					if activityLostSpaceMapWd then
						if isTreaSure then
							activityLostSpaceMapWd:updateGridState()
						else
							activityLostSpaceMapWd:updateGridState(true)
						end
					end
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_ENTER then
					self.detail = info.extra.award_info
					local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

					if activityLostSpaceMapWd then
						activityLostSpaceMapWd:updateGridState()
					end
				elseif eventId == xyd.ActivityLostSpaceEventType.TREASURE_PART then
					self.detail.piece = self.detail.piece + 1

					if self:getAutoUseTreasurePartNum() <= self.detail.piece then
						self.detail.piece = 0
						self:getContentArr()[info.id] = "e#" .. xyd.ActivityLostSpaceEventType.TREASURE_ENTER
						self:getMapArr()[info.id] = xyd.ActivityLostSpaceGridState.CAN_GET
						local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

						if activityLostSpaceMapWd then
							activityLostSpaceMapWd:autoUseTreasurePart(info.id)
						end
					end

					local pushItemId = xyd.tables.activityLostSpaceEventTable:getItemId(eventId)

					if pushItemId and pushItemId > 0 then
						xyd.models.itemFloatModel:pushNewItems({
							{
								item_num = 1,
								item_id = pushItemId
							}
						})
					end
				end
			end
		end
	elseif info.type == xyd.ActivityLostSpaceType.CHOICE_SKILL then
		self.detail.skill = info.id
	elseif info.type == xyd.ActivityLostSpaceType.USE_SKILL then
		local ids = {}
		local activityLostSpaceMapWd = xyd.WindowManager.get():getWindow("activity_lost_space_map_window")

		if activityLostSpaceMapWd then
			ids = activityLostSpaceMapWd:getSkillIds(self:getChooseSkill())
		end

		if self:getChooseSkill() == xyd.ActivityLostSpaceSkillId.FIVE then
			ids = {}

			for i, state in pairs(self:getMapArr()) do
				if (state == xyd.ActivityLostSpaceGridState.NO_OPEN or state == xyd.ActivityLostSpaceGridState.KNOW_POS) and info.info.map[i] == xyd.ActivityLostSpaceGridState.CAN_GET then
					table.insert(ids, i)
				end
			end
		end

		self.detail = info.info

		if activityLostSpaceMapWd then
			activityLostSpaceMapWd:updateSkillBack(ids)
		end
	elseif info.type == xyd.ActivityLostSpaceType.BUY_MOVE_ENERGY then
		self.detail.buy_times = self.detail.buy_times + info.num

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = xyd.ItemID.ACTIVITY_LOST_SPACE_MOVE_ENERGY,
				item_num = info.num
			}
		})
	elseif info.type == xyd.ActivityLostSpaceType.STORY_OLOT then
		local plotId = info.id

		if xyd.arrayIndexOf(self.detail.plots, plotId) < 0 then
			table.insert(self.detail.plots, plotId)
		end
	end
end

function ActivityLostSpaceData:changeMapState(id)
	if self:getMapArr()[id] == xyd.ActivityLostSpaceGridState.NO_OPEN then
		self:getMapArr()[id] = xyd.ActivityLostSpaceGridState.CAN_GET
	elseif self:getMapArr()[id] == xyd.ActivityLostSpaceGridState.CAN_GET then
		self:getMapArr()[id] = xyd.ActivityLostSpaceGridState.EMPTY
	elseif self:getMapArr()[id] == xyd.ActivityLostSpaceGridState.KNOW_POS then
		self:getMapArr()[id] = xyd.ActivityLostSpaceGridState.CAN_GET
	end
end

function ActivityLostSpaceData:getAutoUseTreasurePartNum()
	return 3
end

function ActivityLostSpaceData:getMapArr()
	if self.detail.award_map and #self.detail.award_map > 0 then
		return self.detail.award_map
	end

	if #self.detail.map == 0 then
		local emptyArr = {}

		for i = 1, 66 do
			table.insert(emptyArr, xyd.ActivityLostSpaceGridState.EMPTY)
		end

		return emptyArr
	end

	return self.detail.map
end

function ActivityLostSpaceData:getContentArr()
	if self.detail.award_content and #self.detail.award_content > 0 then
		return self.detail.award_content
	end

	return self.detail.map_content
end

function ActivityLostSpaceData:getIsTreasure()
	if self.detail.award_map and #self.detail.award_map > 0 then
		return true
	end

	return false
end

function ActivityLostSpaceData:getChooseSkill()
	return self.detail.skill or 0
end

function ActivityLostSpaceData:getLevel(skill_id)
	return self.detail.lvs[skill_id] or 0
end

function ActivityLostSpaceData:getBackendSkillIds()
	local ids = xyd.cloneTable(self.detail.skill_ids)

	table.sort(ids)

	return ids
end

return ActivityLostSpaceData
