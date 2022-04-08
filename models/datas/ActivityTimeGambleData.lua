local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityTimeGambleData = class("ActivityTimeGambleData", ActivityData, true)

function ActivityTimeGambleData:register()
	self:registerEvent(xyd.event.TIME_REFRESH, self.onTimeRefresh, self)
end

function ActivityTimeGambleData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_TIME_GAMBLE, function ()
		if data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_GAMBLE then
			return
		end

		local detail = json.decode(data.detail)
		local tableIds = detail.table_ids
		local num = 1

		if detail.type == 2 then
			local refreshAwards = detail.refresh_awards

			if refreshAwards and next(refreshAwards) then
				self.detail_.refreshAwards = refreshAwards
			else
				self.detail_.times = self.detail_.times + #tableIds
			end

			for _, id in ipairs(tableIds) do
				local cool = xyd.tables.activityTimeGambleTable:getCool(id)

				if cool == 1 then
					self.detail_.awards[id] = self.detail_.awards[id] .. "#1"
				end
			end
		elseif detail.type == 1 then
			if detail.num and detail.num > 1 then
				num = detail.num
			end

			for _, id in ipairs(tableIds) do
				self.detail_.buy_times[id] = self.detail_.buy_times[id] + num
			end
		end
	end)
end

function ActivityTimeGambleData:refreshAwardsData()
	if self.detail_.refreshAwards and next(self.detail_.refreshAwards) then
		self.detail_.awards = self.detail_.refreshAwards
		self.detail_.refreshAwards = nil
		self.detail_.times = 0
	end
end

function ActivityTimeGambleData:getUpdateTime()
	return self:getEndTime()
end

function ActivityTimeGambleData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local itemNum1 = xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_GAMBLE_COIN)
	local flag = false
	local shopRedState = self:getShopState()

	if itemNum1 > 0 or shopRedState then
		flag = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_TIME_GAMBLE, flag)

	return flag
end

function ActivityTimeGambleData:getShopState()
	local buy_times = self.detail_.buy_times

	for i = 1, 4 do
		local ids = xyd.tables.activityTimeShopTable:getListByTab(i)
		local conditions = xyd.tables.activityTimeShopTable:getConditions(ids[1])
		local flag = true

		for _, id in ipairs(conditions) do
			local limit = xyd.tables.activityTimeShopTable:getLimit(id)

			if buy_times[id] < limit then
				flag = false

				break
			end
		end

		for _, id in ipairs(ids) do
			local limit = xyd.tables.activityTimeShopTable:getLimit(id)
			local cost = xyd.tables.activityTimeShopTable:getCost(id)

			if limit - buy_times[id] > 0 and flag and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				return true
			end
		end
	end

	return false
end

function ActivityTimeGambleData:onTimeRefresh(event)
	local awards = event.data.awards
	self.detail_.awards = awards
	local refreshFreeTimes = tonumber(xyd.tables.miscTable:getVal("activity_time_refresh_free"))

	if self.detail_.refresh < refreshFreeTimes then
		self.detail_.refresh = self.detail_.refresh + 1
	end
end

return ActivityTimeGambleData
