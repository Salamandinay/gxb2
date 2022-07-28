local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivitySandSearchData = class("ActivitySandSearchData", ActivityData, true)

function ActivitySandSearchData:ctor(params)
	self.checkItemId = xyd.tables.miscTable:split2num("activity_sand_cost", "value", "#")[1]
	self.checkItemNeedNum = xyd.tables.miscTable:split2num("activity_sand_cost", "value", "#")[2]
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivitySandSearchData.super.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivitySandSearchData:getUpdateTime()
	return self:getEndTime()
end

function ActivitySandSearchData:getPoint()
	return self.detail_.point
end

function ActivitySandSearchData:getMapInfo()
	return self.detail_.map
end

function ActivitySandSearchData:getStageID()
	return self.detail_.stage_id
end

function ActivitySandSearchData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SAND_SEARCH, function ()
		local detail = cjson.decode(data.detail)

		self:updateTotalScore(detail.map)
	end)
end

function ActivitySandSearchData:updateTotalScore(map)
	local point = 0

	dump(map, "================map============")

	for index, id in ipairs(map) do
		local type = xyd.tables.activitySandSearchGambleTable:getType(id)

		if type == 1 then
			point = point + xyd.tables.activitySandSearchGambleTable:getParams(id)
		end
	end

	print("point    ", point)

	local pointStage = xyd.tables.activitySandSearchAwardTable:getPointStage()

	if pointStage[3] <= point then
		self.detail_.point = 0
		self.detail_.stage_id = self.detail_.stage_id + 1

		for index, id in ipairs(self.detail_.map) do
			self.detail_.map[index] = 0
		end
	else
		self.detail_.map = map
		self.detail_.point = point
	end
end

function ActivitySandSearchData:onItemChangeBack(event)
	for i = 1, #event.data.items do
		local itemId = event.data.items[i].item_id

		if itemId == self.checkItemId then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SAND_SEARCH, function ()
				self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)
			end)

			break
		end
	end
end

function ActivitySandSearchData:getRedMarkState()
	local redState = self.checkBackpackItemNum > 0

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SAND_SEARCH, redState)

	return redState
end

function ActivitySandSearchData:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local lastShowTime = xyd.db.misc:getValue("activity_summer_preview_show")

		if lastShowTime == nil or not xyd.isSameDay(lastShowTime, xyd.getServerTime()) then
			return true
		else
			return false
		end
	else
		return false
	end
end

function ActivitySandSearchData:doAfterPop()
	xyd.db.misc:setValue({
		key = "activity_summer_preview_show",
		value = xyd.getServerTime()
	})
end

function ActivitySandSearchData:getPopWinName()
	return "activity_summer_preview_window"
end

return ActivitySandSearchData
