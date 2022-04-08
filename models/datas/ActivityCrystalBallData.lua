local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityCrystalBallData = class("ActivityCrystalBallData", ActivityData, true)

function ActivityCrystalBallData:ctor(params)
	ActivityCrystalBallData.super.ctor(self, params)
	xyd.EventDispatcher.outer():addEventListener(xyd.event.CRYSTAL_BALL_READ_PLOT, handler(self, self.onGetPlot))
end

function ActivityCrystalBallData:onAward(data)
	if not data then
		return
	end

	local details = require("cjson").decode(data.detail)
	self.detail_ = details
end

function ActivityCrystalBallData:getUpdateTime()
	return self:getEndTime()
end

function ActivityCrystalBallData:getRedMarkState()
	return self:getQAFinishRed() or self:getStoryAwardRed()
end

function ActivityCrystalBallData:getStoryAwardRed()
	local nowDay = math.ceil((xyd.getServerTime() - self.start_time) / 86400)

	for i = 1, nowDay do
		local finish_plot = xyd.tables.activityCrystalBallTable:getUnlockPlot(i)
		local is_finish = xyd.arrayIndexOf(self.detail_.plot_ids, finish_plot)

		if is_finish > 0 and (not self.detail_.awards[i] or self.detail_.awards[i] == 0) and finish_plot then
			return true
		end
	end

	return false
end

function ActivityCrystalBallData:getQAFinishRed()
	local nowDay = math.ceil((xyd.getServerTime() - self.start_time) / 86400)

	for i = 1, nowDay do
		local finish_plot = xyd.tables.activityCrystalBallTable:getUnlockPlot(i)
		local is_finish = xyd.arrayIndexOf(self.detail_.plot_ids, finish_plot)

		if is_finish <= 0 and finish_plot then
			return true
		end
	end

	return false
end

function ActivityCrystalBallData:getIndexByEnd(endID)
	for _, id in ipairs(self.ids_) do
		local finifshPlot = xyd.tables.activityCrystalBallTable:getFinishPlot(id)

		if xyd.arrayIndexOf(finifshPlot, endID) > 0 then
			return id
		end
	end

	return -1
end

function ActivityCrystalBallData:getLafData()
	local LafData = {}
	local ids = xyd.tables.activityCrystalBallTable:getIds()

	for i = 1, #ids do
		local id = ids[i]
		local finish_plot = xyd.tables.activityCrystalBallTable:getUnlockPlot(id)
		local is_finish = xyd.arrayIndexOf(self.detail_.plot_ids, finish_plot)
		local nowDay = math.ceil((xyd.getServerTime() - self.start_time) / 86400)

		table.insert(LafData, {
			id = id,
			is_finish = xyd.checkCondition(is_finish > 0, true, false),
			canShow = i <= nowDay
		})
	end

	return LafData
end

function ActivityCrystalBallData:getStoryData()
	local StoryData = {}
	local ids = xyd.tables.activityCrystalBallTable:getIds()

	for i = 1, #ids do
		local id = ids[i]
		local unlock_plot = xyd.tables.activityCrystalBallTable:getUnlockPlot(id)
		local is_unlock = xyd.arrayIndexOf(self.detail_.plot_ids, unlock_plot)

		table.insert(StoryData, {
			id = id,
			is_unlock = xyd.checkCondition(is_unlock > 0, true, false),
			is_awarded = xyd.checkCondition(self.detail_.awards[i] == 1, true, false)
		})
	end

	return StoryData
end

function ActivityCrystalBallData:onGetPlot(event)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.CRYSTAL_BALL, function ()
		self.detail_.awards = event.data.awards
		self.detail_.plot_ids = event.data.plot_ids
	end)
end

function ActivityCrystalBallData:onAward(data)
	local detail = json.decode(data.detail)

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.CRYSTAL_BALL, function ()
		self.detail_.awards = detail.info.awards
		self.detail_.plot_ids = detail.info.plot_ids
	end)
end

function ActivityCrystalBallData:checkUnlock(plot_id)
	return xyd.arrayIndexOf(self.detail_.plot_ids, plot_id) > 0
end

return ActivityCrystalBallData
