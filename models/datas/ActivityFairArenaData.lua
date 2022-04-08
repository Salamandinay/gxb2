local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityFairArenaData = class("ActivityFairArenaData", ActivityData, true)

function ActivityFairArenaData:ctor(params)
	ActivityFairArenaData.super.ctor(self, params)
end

function ActivityFairArenaData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.FAIR_ARENA_EXPLORE, handler(self, self.onExplore))
	self.eventProxyOuter_:addEventListener(xyd.event.FAIR_ARENA_SELECT, handler(self, self.onSelect))
	self.eventProxyOuter_:addEventListener(xyd.event.FAIR_ARENA_BATTLE, handler(self, self.onBattle))
	self.eventProxyOuter_:addEventListener(xyd.event.FAIR_ARENA_BATTLE, handler(self, self.onReset))
end

function ActivityFairArenaData:onExplore(event)
	local data = event.data

	self:updateArenaInfo(data.info)
end

function ActivityFairArenaData:onSelect(event)
	local data = event.data

	self:updateArenaInfo(data.info)
end

function ActivityFairArenaData:onBattle(event)
	local data = event.data

	self:updateArenaInfo(data.info)
end

function ActivityFairArenaData:onReset(event)
	local data = event.data

	self:updateArenaInfo(data.info)
end

function ActivityFairArenaData:updateArenaInfo(info)
	self.detail = {
		explore_times = info.explore_times or 0,
		times = info.times,
		test_times = info.test_times,
		fail_times = info.fail_times,
		explore_type = info.explore_type,
		explore_stage = info.explore_stage,
		is_fail = info.is_fail or 0,
		partners = info.partners,
		equips = info.equips,
		buffs = info.buffs,
		score = info.score,
		cur_history = info.cur_history,
		history_explore = info.history_explore,
		enemy_infos = info.enemy_infos,
		box_partners = info.box_partners,
		box_equips = info.box_equips,
		box_buffs = info.box_buffs,
		self_rank = info.self_rank,
		history_rank = info.history_rank
	}

	if self.detail.buy_times then
		self.detail.buy_times = info.buy_times or self.detail.buy_times
	else
		self.detail.buy_times = info.buy_times or 0
	end
end

function ActivityFairArenaData:getUpdateTime()
	return self:getEndTime()
end

function ActivityFairArenaData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:getEndTime() - xyd.getServerTime() < xyd.TimePeriod.DAY_TIME then
		return false
	end

	if self.detail.explore_type > 0 then
		return true
	end

	local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
	local cost_num = xyd.models.backpack:getItemNumByID(cost_id)

	if cost_num > 0 then
		return true
	end

	return false
end

return ActivityFairArenaData
