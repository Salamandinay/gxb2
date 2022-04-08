local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityMusicJigsawData = class("ActivityMusicJigsawData", ActivityData, true)

function ActivityMusicJigsawData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityMusicJigsawData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local list = self.detail.piece_list

	for i = 1, #list do
		if list[i].is_complete and not list[i].is_reward and self:checkTime(list[i].table_id) then
			return true
		end
	end

	return self.defRedMark
end

function ActivityMusicJigsawData:onAward(data)
	local real_data = json.decode(data.detail)
	self.detail.piece_list[real_data.table_id - 1].is_reward = 1
	self.detail.plot_info.plot_count = real_data.plot_count
end

function ActivityMusicJigsawData:checkTime(table_id)
	local cur_time = xyd.getServerTime()
	local delta_time = xyd.tables.activityMusicDayTable:getUnlockingTime(table_id)
	local st_time = self.start_time
	local unlock_time = st_time + delta_time

	if cur_time < unlock_time then
		return false
	end

	return true
end

return ActivityMusicJigsawData
