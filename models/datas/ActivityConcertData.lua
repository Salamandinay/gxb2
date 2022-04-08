local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityConcertData = class("ActivityConcertData", ActivityData, true)

function ActivityConcertData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityConcertData:onAward(data)
	local detail = json.decode(data.detail)
	local real_data = json.decode(data.detail).music_info
	local table_id = real_data.music_id
	self.detail.music_list[table_id - 1].hit_rate = real_data.hit_rate
	self.detail.music_list[table_id - 1].score = real_data.score
	self.detail.music_list[table_id - 1].complete_count = self.detail.music_list[table_id - 1].complete_count + 1

	if detail.unlock_music_id ~= 0 then
		self.detail.music_list[detail.unlock_music_id - 1].is_lock = 0
	end
end

return ActivityConcertData
