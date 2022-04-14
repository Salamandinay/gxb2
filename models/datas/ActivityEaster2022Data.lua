local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityEaster2022Data = class("ActivityEaster2022Data", ActivityData, true)

function ActivityEaster2022Data:getUpdateTime()
	return self:getEndTime()
end

function ActivityEaster2022Data:getRedMarkState()
	local red = false

	if not self:isFunctionOnOpen() then
		red = false

		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_EASTER2022, red)

		return red
	end

	if not red and self:isFirstRedMark() then
		red = true

		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_EASTER2022, red)

		return red
	end

	if not red and self:checkRedMarkOfRes() then
		red = true
	end

	if not red and self:checkRedMarkOfProgressAward() then
		red = true
	end

	if not red and self:checkRedMarkOfTask() then
		red = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_EASTER2022, red)

	return red
end

function ActivityEaster2022Data:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_EASTER2022 then
			local detail = json.decode(data.detail)
			local result = detail.result

			if result[1].xy then
				self.tempSpecialPos = result[#result].xy
				self.oldPosArr = self.detail.pos_arr
				self.detail = detail.info
			elseif result[1].y then
				for i = 1, #result do
					self.tempSpecialPos = {
						self.detail.pos_arr[result[1].y],
						result[1].y
					}
				end

				self.detail = detail.info
			else
				self.detail.point_awarded[tonumber(result[1].id)] = 1
			end

			self:getRedMarkState()
		end
	end)
end

function ActivityEaster2022Data:getOldPosArr()
	return self.oldPosArr
end

function ActivityEaster2022Data:getTempSpecialPos()
	return self.tempSpecialPos
end

function ActivityEaster2022Data:getResource1()
	local data = xyd.tables.miscTable:split2Cost("activity_easter2022_cost1", "value", "#")

	return data
end

function ActivityEaster2022Data:getResource2()
	local data = xyd.tables.miscTable:split2Cost("activity_easter2022_cost2", "value", "#")

	return data
end

function ActivityEaster2022Data:getSingleDrawLimit()
	return 100
end

function ActivityEaster2022Data:getCompleteValue(id)
	return self.detail.mission_awarded[id]
end

function ActivityEaster2022Data:getCurProgressValue(id)
	return self.detail.completes[id]
end

function ActivityEaster2022Data:getCurPoint()
	return self.detail.point
end

function ActivityEaster2022Data:getProgressAwardRecord(id)
	return self.detail.point_awarded[id]
end

function ActivityEaster2022Data:getEggData(row, col)
	if col == self.detail.pos_arr[row] then
		return tonumber(self.detail.ids[row])
	end

	return 0
end

function ActivityEaster2022Data:checkRedMarkOfRes()
	local red = false
	local res1 = self:getResource1()

	if res1[2] <= xyd.models.backpack:getItemNumByID(res1[1]) then
		return true
	end

	local res2 = self:getResource2()

	if res2[2] <= xyd.models.backpack:getItemNumByID(res2[1]) then
		return true
	end

	return red
end

function ActivityEaster2022Data:checkRedMarkOfProgressAward()
	local red = false
	local ids = xyd.tables.activityEaster2022AwardsTable:getIDs()

	for j in pairs(ids) do
		local data = {
			id = j,
			max_value = xyd.tables.activityEaster2022AwardsTable:getPoint(j),
			cur_value = self:getCurPoint()
		}

		if data.max_value < data.cur_value then
			data.cur_value = data.max_value
		end

		if self:getProgressAwardRecord(j) == 0 and data.cur_value == data.max_value then
			data.state = 1

			return true
		end
	end

	return red
end

function ActivityEaster2022Data:checkRedMarkOfTask()
	local red = false
	local timeStamp = xyd.db.misc:getValue("activity_easter2022_task_time_stamp")

	if timeStamp and xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		return false
	end

	local ids = xyd.tables.activityEaster2022MissionTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local info = {
			id = id,
			limitNum = xyd.tables.activityEaster2022MissionTable:getLimit(id),
			curCompleteNum = self:getCompleteValue(id)
		}

		if info.curCompleteNum < info.limitNum then
			return true
		end
	end

	return red
end

return ActivityEaster2022Data
