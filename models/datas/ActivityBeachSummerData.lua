local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBeachSummerData = class("ActivityBeachSummer", ActivityData, true)

function ActivityBeachSummerData:getRedMarkState()
	local starNum = self.detail_.star_num
	local awarded = self.detail_.awarded
	local ids = xyd.tables.activityBeachStarAwardTable:getIDs()
	local redState = self:getRedPointStar()
	local start_time = self:startTime()
	local value = xyd.db.misc:getValue("beach_island_next")

	if xyd.getServerTime() - start_time >= 604800 and tonumber(value) ~= 1 then
		redState = true
	end

	if self:isFirstRedMark() then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BEACH_SUMMER, redState)

	return redState
end

function ActivityBeachSummerData:getUpdateTime()
	return self.end_time
end

function ActivityBeachSummerData:getRedPointStar()
	local starNum = self.detail_.star_num
	local awarded = self.detail_.awarded
	local ids = xyd.tables.activityBeachStarAwardTable:getIDs()
	local redState = false

	for index, id in ipairs(ids) do
		local point = xyd.tables.activityBeachStarAwardTable:getPoint(id)

		if point <= starNum and awarded[index] ~= 1 then
			redState = true
		end
	end

	return redState
end

function ActivityBeachSummerData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_BEACH_SUMMER, function ()
		if not data then
			return
		end

		local details = require("cjson").decode(data.detail)
		local awardID = details.table_id
		self.detail_.awarded[awardID] = 1
	end)
end

function ActivityBeachSummerData:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local lastShowTime = xyd.db.misc:getValue("activity_summer_preview_show")

		if lastShowTime == nil or not xyd.isSameDay(lastShowTime, xyd.getServerTime()) then
			return true
		end
	else
		return false
	end
end

function ActivityBeachSummerData:doAfterPop()
	xyd.db.misc:setValue({
		key = "activity_summer_preview_show",
		value = xyd.getServerTime()
	})
end

function ActivityBeachSummerData:getPopWinName()
	return "activity_summer_preview_window"
end

return ActivityBeachSummerData
