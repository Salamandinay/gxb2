local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLafuliCastleData = class("ActivityLafuliCastleData", ActivityData, true)
local taskAwardLimit = xyd.tables.miscTable:getNumber("activity_lflcastle_task_award_limit", "value")
local resItemID = xyd.tables.miscTable:split2Cost("activity_lflcastle_score", "value", "|")
local partnerAwardEnergyNeed = xyd.tables.miscTable:getNumber("activity_lflcastle_energy", "value")

function ActivityLafuliCastleData:ctor(params)
	ActivityData.ctor(self, params)

	self.detail.m_point = math.min(self.detail.m_point, taskAwardLimit - self.detail.times)
end

function ActivityLafuliCastleData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLafuliCastleData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateRedMark))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateRedMark))
	xyd.EventDispatcher.inner():addEventListener(xyd.event.ON_MAIN_MAP_LOADED, handler(self, self.delayShow))
end

function ActivityLafuliCastleData:setData(params)
	ActivityData.setData(self, params)

	self.detail.m_point = math.min(self.detail.m_point, taskAwardLimit - self.detail.times)
end

function ActivityLafuliCastleData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_LAFULI_CASTLE then
		return
	end

	local detail = cjson.decode(data.detail)

	if detail.type == 1 then
		self.detail.points[self.reqParams.index] = self.detail.points[self.reqParams.index] + self.reqParams.num
		self.detail.energy = self.detail.energy + self.reqParams.num
	elseif detail.type == 2 then
		self.detail.awards[self.reqParams.id] = 1
		local award = xyd.tables.activityLflcastleAwardTable:getAward(self.reqParams.id)

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = award[1],
				item_num = award[2]
			}
		})
	elseif detail.type == 3 then
		self.detail.m_point = 0
		self.detail.times = self.detail.times + self.reqParams.num

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = resItemID[2],
				item_num = self.reqParams.num
			}
		})
	elseif detail.type == 4 then
		self.detail.energy = self.detail.energy - self.reqParams.num * xyd.tables.miscTable:getNumber("activity_lflcastle_energy", "value")

		xyd.alertItems(detail.items)
	end

	self:updateRedMark()
end

function ActivityLafuliCastleData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_LAFULI_CASTLE, function ()
		self.holdRed = false
	end)
end

function ActivityLafuliCastleData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false

		for i in pairs(resItemID) do
			if xyd.models.backpack:getItemNumByID(resItemID[i]) > 0 then
				self.defRedMark = true
			end
		end

		if partnerAwardEnergyNeed <= self.detail.energy then
			self.defRedMark = true
		end

		if self.detail.m_point > 0 then
			self.defRedMark = true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_LAFULI_CASTLE, self.defRedMark)

	return self.defRedMark
end

function ActivityLafuliCastleData:sendReq(params)
	self.reqParams = params

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LAFULI_CASTLE, cjson.encode(params))
end

function ActivityLafuliCastleData:delayShow()
	local delayShowFlag = xyd.db.misc:getValue("activity_lafuli_castle_delay_show" .. self:getUpdateTime())

	if delayShowFlag and tonumber(delayShowFlag) == 1 then
		return
	end

	for i in ipairs(self.detail.is_completeds) do
		local completeTime = self.detail.is_completeds[i]

		if completeTime and completeTime > 0 then
			local awards = xyd.tables.activityLflcastleTaskTable:getAwards(i)
			local data = {}

			for u, award in pairs(awards) do
				table.insert(data, {
					item_id = award[1],
					item_num = award[2] * completeTime
				})
			end

			xyd.models.itemFloatModel:pushNewItems(data)
		end
	end

	xyd.db.misc:setValue({
		value = 1,
		key = "activity_lafuli_castle_delay_show" .. self:getUpdateTime()
	})
end

return ActivityLafuliCastleData
