local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityRecallLotteryData = class("ActivityRecallLotteryData", ActivityData, true)

function ActivityRecallLotteryData:getUpdateTime()
	return self:getEndTime()
end

function ActivityRecallLotteryData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
end

function ActivityRecallLotteryData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_RECALL_LOTTERY then
		return
	end

	local detail = json.decode(data.detail)

	if detail.type == 1 then
		if detail.index and detail.index ~= 0 and detail.index ~= -1 then
			self:judgeBigAward(detail.index)
			table.remove(self.detail.awards[self.curStage], detail.index)

			if #self.detail.awards[self.curStage] == 0 then
				local unlockProb = xyd.tables.activityVampireGambleTable:getUnlockProb(self.curStage)

				if unlockProb == 0 then
					self.detail.level = math.min(6, self.detail.level + 1)
				end
			end
		else
			self.detail.probs[self.curStage] = -1
			self.detail.level = math.min(6, self.detail.level + 1)
		end

		if not self.detail.awards[self.detail.level] then
			self.detail.awards[self.detail.level] = {}
			local awards = xyd.tables.activityVampireGambleTable:getAward(self.detail.level)

			for i = 1, #awards do
				table.insert(self.detail.awards[self.detail.level], i)
			end
		end
	elseif detail.type == 2 then
		self.detail.point = self.detail.point + detail.num
	elseif detail.type == 3 then
		self.detail.gets[detail.id] = 1
	end
end

function ActivityRecallLotteryData:onItemChange()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_RECALL_LOTTERY, function ()
		self.holdRed = false
	end)
end

function ActivityRecallLotteryData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	self.defRedMark = false

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local awakeCost = xyd.tables.miscTable:split2Cost("activity_vampire_awake", "value", "|#")[1]

		if awakeCost[2] <= xyd.models.backpack:getItemNumByID(awakeCost[1]) then
			self.defRedMark = true
		end

		for i = 1, 6 do
			local recallCost = xyd.tables.activityVampireGambleTable:getCost(i)

			if recallCost[2] <= xyd.models.backpack:getItemNumByID(recallCost[1]) then
				self.defRedMark = true
			end
		end
	end

	return self.defRedMark
end

function ActivityRecallLotteryData:setCurStage(stage)
	self.curStage = stage
end

function ActivityRecallLotteryData:getCurStage()
	return self.curStage
end

function ActivityRecallLotteryData:judgeBigAward(index)
	local bigAwardNum = xyd.tables.activityVampireGambleTable:getBigAwardNum(self.curStage)

	if self.detail.awards[self.curStage][index] <= bigAwardNum then
		self.isBigAward = true
	else
		self.isBigAward = false
	end
end

function ActivityRecallLotteryData:getBigAwardJudge()
	return self.isBigAward
end

return ActivityRecallLotteryData
