local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTimeMissionData = class("ActivityTimeMissionData", ActivityData, true)

function ActivityTimeMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTimeMissionData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_MISSION then
		return
	end

	local detail = json.decode(data.detail)

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_TIME_MISSION, function ()
		if detail.type == 1 then
			self.detail_.m_awards[detail.table_id] = 1
			local can_get_point = xyd.tables.activityTimeMissionTable:getPoint(detail.table_id)

			if can_get_point and can_get_point > 0 then
				self.detail_.point = self.detail_.point + can_get_point
			end

			local awrads = xyd.tables.activityTimeMissionTable:getAwards(detail.table_id)
			local items = {}

			for _, info in ipairs(awrads) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
		end

		if detail.type == 2 then
			self.detail_.p_awards[detail.table_id] = 1
			local awrads = xyd.tables.activityTimePointAwardTable:getAwards(detail.table_id)
			local items = {}

			for _, info in ipairs(awrads) do
				local item = {
					item_id = info[1],
					item_num = info[2]
				}

				table.insert(items, item)
			end

			xyd.models.itemFloatModel:pushNewItems(items)
		end
	end)
end

function ActivityTimeMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local flag = false

	for i, value in pairs(self.detail.p_awards) do
		local needPoint = xyd.tables.activityTimePointAwardTable:getPoint(i)

		if value == 0 and needPoint <= self.detail.point then
			flag = true

			break
		end
	end

	local timeDis = xyd.getServerTime() - self:startTime()
	local day = math.ceil(timeDis / 86400)

	for i, value in pairs(self.detail.m_awards) do
		local compelte_num = xyd.tables.activityTimeMissionTable:getComplete(i)

		if value == 0 and compelte_num <= self.detail.values[i] and xyd.tables.activityTimeMissionTable:getTime(i) <= day then
			flag = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TIME_MISSION, flag)

	return flag
end

return ActivityTimeMissionData
