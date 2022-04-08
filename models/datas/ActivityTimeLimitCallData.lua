local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTimeLimitCallData = class("ActivityTimeLimitCallData", ActivityData, true)

function ActivityTimeLimitCallData:ctor(params)
	self.needChangeNum_ = true

	ActivityTimeLimitCallData.super.ctor(self, params)
end

function ActivityTimeLimitCallData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTimeLimitCallData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.SUMMON, handler(self, self.onSummonEvent))
	self.eventProxyOuter_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxyOuter_:addEventListener(xyd.event.LIMIT_GACHA_SHOP, handler(self, self.onShop))
end

function ActivityTimeLimitCallData:ondailyRed()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
		self:updateDailyRedMark()
	end)
	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
end

function ActivityTimeLimitCallData:setButNum(butNum)
	self.butNum = butNum
end

function ActivityTimeLimitCallData:onShop(event)
	self.detail_.shop_times[event.data.table_id] = self.detail_.shop_times[event.data.table_id] + self.butNum

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
		self:updateAwardRedMark()
	end)
	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
end

function ActivityTimeLimitCallData:onItemChange(event)
	local items = event.data.items

	for _, itemInfo in ipairs(items) do
		if itemInfo.item_id == xyd.ItemID.LIMIT_GACHA_ICON2 then
			self.needChangeNum_ = false

			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
				self.needChangeNum_ = true

				xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
			end)
		end

		if itemInfo.item_id == xyd.ItemID.LIMIT_GACHA_AWARD_ICON2 then
			xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
				self:updateAwardRedMark()
			end)
			xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
		end
	end
end

function ActivityTimeLimitCallData:onAward(data)
	local detailData = json.decode(data.detail)
	self.detail_ = detailData.info
	self.itemsInfo_ = detailData.items

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
		self:updateRedMarkPoint()
		self:updateRedMarkPartner()
		self:updateAwardRedMark()
	end)
	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
end

function ActivityTimeLimitCallData:getAwardItems()
	return self.itemsInfo_
end

function ActivityTimeLimitCallData:onSummonEvent(event)
	if event.data.summon_id == xyd.SummonType.TIME_LIMIT_CALL or event.data.summon_id == xyd.SummonType.TIME_LIMIT_CALL_TEN or tonumber(event.data.summon_id) == 10251 then
		local partners = event.data.summon_result.partners or {}
		self.detail_.times = self.detail_.times + #partners

		for i, partner in ipairs(partners) do
			local item_id = partner.table_id
			local liubeiId = xyd.tables.miscTable:split2num("activity_limit_gacha_security_time", "value", "|")[2]

			if tonumber(item_id) == liubeiId then
				self.detail_.times_pr = self.detail_.times_pr + 1

				if tonumber(event.data.summon_id) ~= 10251 then
					self.detail_.hit_times = 0
				end
			else
				self.detail_.hit_times = self.detail_.hit_times + 1
			end
		end

		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TIME_LIMIT_CALL, function ()
			self:updateRedMarkPoint()
			self:updateRedMarkPartner()
			self:updateAwardRedMark()
		end)
		xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, self:getRedMarkState())
	end
end

function ActivityTimeLimitCallData:updateRedMarkPoint()
	local pointIds = xyd.tables.activityLimitPointAwards:getIds()
	self.needRed1 = false

	for idx, id in ipairs(pointIds) do
		local point = xyd.tables.activityLimitPointAwards:getPoint(id)
		local hasComp = false
		local hasRewarded = false

		if point < self.detail_.times then
			hasComp = true
		end

		if self.detail_.awards[idx] and self.detail_.awards[idx] == 1 then
			hasRewarded = true
		end

		if hasComp and not hasRewarded then
			self.needRed1 = true

			return
		end
	end
end

function ActivityTimeLimitCallData:getRedMarkPoint()
	return self.needRed1
end

function ActivityTimeLimitCallData:updateRedMarkPartner()
	local pointIds = xyd.tables.activityLimitPartnerAwards:getIds()
	self.needRed2 = false

	for idx, id in ipairs(pointIds) do
		local point = xyd.tables.activityLimitPartnerAwards:getPoint(id)
		local hasComp = false
		local hasRewarded = false

		if point <= self.detail_.times_pr then
			hasComp = true
		end

		if self.detail_.awards_pr[idx] and self.detail_.awards_pr[idx] == 1 then
			hasRewarded = true
		end

		if hasComp and not hasRewarded then
			self.needRed2 = true

			return
		end
	end
end

function ActivityTimeLimitCallData:getRedMarkPartner()
	return self.needRed2
end

function ActivityTimeLimitCallData:updateDailyRedMark()
	self.dailyRed = false
	local timeStamp1 = xyd.db.misc:getValue("activity_time_limit_call")

	if not timeStamp1 or not xyd.isSameDay(tonumber(timeStamp1), xyd.getServerTime()) then
		self.dailyRed = true
	end
end

function ActivityTimeLimitCallData:getDailyRedMark()
	return self.dailyRed
end

function ActivityTimeLimitCallData:getMaxAwardIndex()
	local times = self.detail_.shop_times

	for i = 1, 5 do
		local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(i)

		for j = 1, #ids do
			if times[ids[j]] <= 0 then
				return i
			end
		end
	end

	return 5
end

function ActivityTimeLimitCallData:updateAwardRedMark()
	self.awardRed = false
	local ids = xyd.tables.activityLimitExchangeAwardTable:getIDs(self:getMaxAwardIndex())
	local lastID = xyd.tables.activityLimitExchangeAwardTable:getLastID()

	for i = 1, #ids do
		local id = ids[i]

		if (id ~= lastID or self:getUpdateTime() - xyd.getServerTime() < 86400) and self.detail_.shop_times[id] < xyd.tables.activityLimitExchangeAwardTable:getLimit(id) then
			local cost = xyd.tables.activityLimitExchangeAwardTable:getCost(id)

			if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				self.awardRed = true
			end
		end
	end
end

function ActivityTimeLimitCallData:getAwardRedMark()
	return self.awardRed
end

function ActivityTimeLimitCallData:getRedMarkState()
	if self.dailyRed == nil then
		self:updateDailyRedMark()
	end

	if self.awardRed == nil then
		self:updateAwardRedMark()
	end

	local flag = false

	if not self:isFunctionOnOpen() then
		flag = false
	elseif self:isFirstRedMark() then
		flag = true
	elseif self.needRed2 or self.needRed1 or self.awardRed or self.dailyRed then
		flag = true
	elseif xyd.models.backpack:getItemNumByID(xyd.ItemID.LIMIT_GACHA_ICON2) > 0 and self.needChangeNum_ then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.TIME_LIMIT_CALL, flag)

	return flag
end

return ActivityTimeLimitCallData
