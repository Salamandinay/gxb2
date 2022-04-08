local ActivityData = import("app.models.ActivityData")
local ActivityEnconterStoryData = class("ActivityEnconterStoryData", ActivityData, true)

function ActivityEnconterStoryData:getRedPointStar()
	local starNum = self.detail_.star_num
	local awarded = self.detail_.awarded
	local ids = xyd.tables.activityEnconterStarAwardsTable:getIDs()
	local redState = false

	for index, id in ipairs(ids) do
		local point = xyd.tables.activityEnconterStarAwardsTable:getPoint(id)

		if point <= starNum and awarded[index] ~= 1 then
			redState = true
		end
	end

	return redState
end

function ActivityEnconterStoryData:getFightRed()
	local start_time = self:startTime()
	local ids = xyd.tables.activityEnconterBattleTable:getIDs()
	local redState = false
	local stageNow = self.detail_.stage

	for _, id in ipairs(ids) do
		local openDay = xyd.tables.activityEnconterBattleTable:getOpenDay(id)

		if stageNow <= id and xyd.getServerTime() >= openDay * xyd.DAY_TIME + start_time and stageNow > 0 then
			redState = true

			break
		end
	end

	return redState
end

function ActivityEnconterStoryData:getUpdateTime()
	return self.end_time
end

function ActivityEnconterStoryData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BEACH_SUMMER, function ()
		if not data then
			return
		end

		local details = require("cjson").decode(data.detail)
		local awardID = details.table_id
		self.detail_.awarded[awardID] = 1
	end)
end

function ActivityEnconterStoryData:ctor(params)
	ActivityEnconterStoryData.super.ctor(self, params)

	self.isNeedDeal = false
end

function ActivityEnconterStoryData:register()
	ActivityEnconterStoryData.super.register(self)
	self:registerEvent(xyd.event.ENCOUNTER_UNLOCK_PLOT, handler(self, self.unLockPlotBack))
	self:registerEvent(xyd.event.ENCOUNTER_FIGHT, handler(self, self.fightBack))
end

function ActivityEnconterStoryData:unLockPlotBack(event)
	self:setRedMarkCheck(true)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ENCONTER_STORY, function ()
		self:setRedMarkCheck(false)

		local data = xyd.decodeProtoBuf(event.data)
		self.detail.plots[data.table_id] = 1
	end)
end

function ActivityEnconterStoryData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local state = false

	if not self.story_item_num then
		self.story_item_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ENCONTER_STORY)
	end

	if not self.isNeedDeal then
		self.story_item_num = xyd.models.backpack:getItemNumByID(xyd.ItemID.ENCONTER_STORY)
	end

	for i = 1, 5 do
		local cost = xyd.tables.activityEnconterStoryTable:getCost(i)

		if cost[2] <= self.story_item_num and self.detail.plots[i] == 0 then
			state = true

			break
		end
	end

	local redState = self:getRedPointStar()
	local fightRed = self:getFightRed()
	state = state or fightRed or redState

	xyd.models.redMark:setMark(xyd.RedMarkType.ENCONTER_STORY, state)

	return state
end

function ActivityEnconterStoryData:setRedMarkCheck(state)
	self.isNeedDeal = state
end

function ActivityEnconterStoryData:fightBack(event)
	self:setRedMarkCheck(true)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ENCONTER_STORY, function ()
		self:setRedMarkCheck(false)
	end)
end

return ActivityEnconterStoryData
