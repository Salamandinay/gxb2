local ActivityData = import("app.models.ActivityData")
local ActivityStarAltarMissionData = class("ActivityStarAltarMissionData", ActivityData, true)

function ActivityStarAltarMissionData:getUpdateTime()
	return self:getEndTime()
end

function ActivityStarAltarMissionData:onClickNav()
	xyd.db.misc:setValue({
		key = "star_altar_click_time1",
		value = xyd.getServerTime()
	})
end

function ActivityStarAltarMissionData:getRedStateMission()
	local clickTime = xyd.db.misc:getValue("star_altar_click_time1")

	if not clickTime or not xyd.isSameDay(tonumber(clickTime), xyd.getServerTime()) then
		return true
	else
		return false
	end
end

function ActivityStarAltarMissionData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	return self:getRedStateShop() or self:getRedStateMission()
end

function ActivityStarAltarMissionData:getRedStateShop()
	local itemIDs = xyd.tables.activityStarAltarExchangeTable:getIDs()
	local expItem = 0
	local expCost = 0

	for i = 1, #itemIDs do
		local limit = xyd.tables.activityStarAltarExchangeTable:getLimit(i)

		if self.detail_.buy_times[i] < limit then
			local cost = xyd.tables.activityStarAltarExchangeTable:getCost(i)

			if expCost < cost[2] then
				expItem = i
				expCost = cost[2]
			end
		end
	end

	if expItem and expItem > 0 then
		return expCost <= xyd.models.backpack:getItemNumByID(xyd.ItemID.STAR_ALTER_EXCHANGE_COIN)
	else
		return false
	end
end

function ActivityStarAltarMissionData:setAwardID(id)
	self.awardID = id
end

return ActivityStarAltarMissionData
