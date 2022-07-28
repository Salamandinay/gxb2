local ActivityData = class("ActivityData", nil, true)
local json = require("cjson")
local handlers_ = {}

function ActivityData:ctor(params)
	self.win_list_ = {}
	self.defRedMark = false
	self.activity_id = params.activity_id
	self.days = params.days
	self.start_time = params.start_time
	self.end_time = params.end_time
	self.is_open = params.is_open

	if xyd.IndependentActivityID[params.activity_id] ~= nil then
		self.detail_ = {}
	else
		self.detail_ = json.decode(params.detail)
	end

	self.isValid = true

	self:register()
end

function ActivityData:register()
end

function ActivityData:registerEvent(eventName, callback, this)
	if this then
		callback = handler(this, callback)
	end

	local tmpHandler = xyd.EventDispatcher.outer():addEventListener(eventName, callback)

	table.insert(handlers_, tmpHandler)

	return tmpHandler
end

function ActivityData.____getters:id()
	return self.activity_id
end

function ActivityData.____getters:detail()
	return self.detail_
end

function ActivityData.____getters:update_time()
	if self.detail_.update_time then
		return self.detail_.update_time
	end

	return 0
end

function ActivityData.____getters:valid()
	return self.isValid
end

function ActivityData.____getters:startTime()
	return self.start_time
end

function ActivityData.____setters:valid(bool)
	self.isValid = bool
end

function ActivityData:setData(params)
	if params.days ~= nil then
		self.days = params.days
	end

	if params.start_time ~= nil then
		self.start_time = params.start_time
	end

	if params.end_time ~= nil then
		self.end_time = params.end_time
	end

	if params.is_open ~= nil then
		self.is_open = params.is_open
	end

	if params.detail ~= nil then
		self.detail_ = json.decode(params.detail)
	end
end

function ActivityData:setDataNodecode(params)
	if params.days ~= nil then
		self.days = params.days
	end

	if params.start_time ~= nil then
		self.start_time = params.start_time
	end

	if params.end_time ~= nil then
		self.end_time = params.end_time
	end

	if params.is_open ~= nil then
		self.is_open = params.is_open
	end

	if params.detail ~= nil then
		self.detail_ = params.detail
	end
end

function ActivityData:getDays()
	return self.days
end

function ActivityData:getEndTime()
	return self.end_time
end

function ActivityData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	return self.defRedMark
end

function ActivityData:getUpdateTime()
	return self.update_time
end

function ActivityData:setDefRedMark(bool)
	self.defRedMark = bool
end

function ActivityData:onAward(data)
end

function ActivityData:updateInfo(data)
end

function ActivityData:onActivityByID(data)
	self:setData(data)
end

function ActivityData:backRank()
	return false
end

function ActivityData:isShow()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

function ActivityData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	if (self.is_open == 1 or self.is_open == true) and (self.days and self.days < 0 or xyd.getServerTime() < self.end_time) then
		return true
	end

	return false
end

function ActivityData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	return false
end

function ActivityData:startTime()
	return self.start_time
end

function ActivityData:checkPop()
end

function ActivityData:doAfterPop()
end

function ActivityData:getPassedDayRound()
	local startTime = self:startTime()
	local passedTotalTime = xyd.getServerTime() - startTime

	return math.ceil(passedTotalTime / xyd.TimePeriod.DAY_TIME)
end

function ActivityData:isFunctionOnOpen()
	local functionOnArr = xyd.tables.activityTable:getLimit(self.activity_id)
	local isOpen = true

	if functionOnArr and #functionOnArr > 0 then
		local playerLev = xyd.models.backpack:getLev()
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
		local maxStage = 0

		if mapInfo then
			maxStage = mapInfo.max_stage
		end

		for i in pairs(functionOnArr) do
			if functionOnArr[i][1] == xyd.AcitvityLimt.STAGE and maxStage < tonumber(functionOnArr[i][2]) then
				isOpen = false

				xyd.models.activity:setNeedOpenActivityAloneEnter(xyd.AcitvityLimt.STAGE, tonumber(functionOnArr[i][2]))

				return isOpen
			end

			if functionOnArr[i][1] == xyd.AcitvityLimt.LV and playerLev < tonumber(functionOnArr[i][2]) then
				isOpen = false

				xyd.models.activity:setNeedOpenActivityAloneEnter(xyd.AcitvityLimt.LV, tonumber(functionOnArr[i][2]))

				return isOpen
			end
		end
	end

	if xyd.tables.activityTable:getType(self.activity_id) and xyd.tables.activityTable:getType(self.activity_id) == xyd.EventType.COOL and xyd.tables.activityTable:getType2(self.activity_id) == 2 and not xyd.checkFunctionOpen(xyd.FunctionID.COOL, true) then
		return false
	end

	if xyd.tables.activityTable:getType(self.activity_id) and xyd.tables.activityTable:getType(self.activity_id) == xyd.EventType.LIMIT and xyd.tables.activityTable:getType2(self.activity_id) == 3 and not xyd.checkFunctionOpen(xyd.FunctionID.LIMIT, true) then
		return false
	end

	return isOpen
end

function ActivityData:isFirstRedMark()
	local days = xyd.tables.activityTable:getDays(self.activity_id)

	if days and days > 0 and not xyd.db.misc:getValue("ActivityFirstRedMark_" .. self.activity_id .. "_" .. self.end_time) then
		return true
	end

	return false
end

return ActivityData
