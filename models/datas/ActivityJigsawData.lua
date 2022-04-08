local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityJigsawData = class("ActivityJigsawData", ActivityData)

function ActivityJigsawData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ActivityJigsawData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local buy_type = 40

	if xyd.models.backpack:getItemNumByID(buy_type) > 0 then
		local ids = xyd.tables.activityJigsawPicTable:getIds()

		for i = 1, #ids do
			if self.detail_["is_awarded_" .. tostring(ids[i])] == 0 then
				return true
			end
		end
	end

	return false
end

function ActivityJigsawData:onAward(data)
	local real_data = json.decode(data.detail)

	for key in pairs(real_data) do
		if key ~= "picture_id" then
			self.detail_[key] = real_data[key]
		end
	end

	local flag = 1
	local arr = self.detail_["picture_" .. tostring(real_data.picture_id)]

	for i = 1, #arr do
		if arr[i] ~= i then
			flag = 0

			break
		end
	end

	self.detail_["is_awarded_" .. tostring(real_data.picture_id)] = flag
end

return ActivityJigsawData
