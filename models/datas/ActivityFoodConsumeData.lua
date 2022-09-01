local ActivityData = import("app.models.ActivityData")
local ActivityFoodConsumeData = class("ActivityFoodConsumeData", ActivityData, true)
local json = require("cjson")

function ActivityFoodConsumeData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local red = false

	if not red and self:isFirstRedMark() then
		red = true
	end

	if self:checkAllNavRedPoint() then
		red = true
	end

	return red
end

function ActivityFoodConsumeData:getLeftTime(id)
	return xyd.tables.activityFoodConsumeTable:getLimit(id) - self.detail_.buy_times[id]
end

function ActivityFoodConsumeData:getUpdateTime(id)
	return self:getEndTime()
end

function ActivityFoodConsumeData:getReqTableID()
	return self.reqTableID
end

function ActivityFoodConsumeData:onAward(data)
	if data.activity_id == xyd.ActivityID.ACTIVITY_FOOD_CONSUME then
		self.detail_.buy_times[self.reqTableID] = self.detail_.buy_times[self.reqTableID] + 1
	end
end

function ActivityFoodConsumeData:reqExchangePartner(partnerID, type, tableID)
	self.reqTableID = tableID
	local params = json.encode({
		partner_id = tonumber(partnerID),
		award_id = tableID
	})

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FOOD_CONSUME, params)
end

function ActivityFoodConsumeData:checkAllNavRedPoint()
	for i = 1, 3 do
		if self:checkRedPointByNav(i) then
			return true
		end
	end
end

function ActivityFoodConsumeData:checkRedPointByNav(nav)
	local ids = xyd.tables.activityFoodConsumeTable:getIDsByType(nav)

	for i = 1, #ids do
		local id = ids[i]

		if self:checkRedPointByTableID(id) then
			return true
		end
	end
end

function ActivityFoodConsumeData:checkRedPointByTableID(tableID)
	local cost = xyd.tables.activityFoodConsumeTable:getCost(tableID)
	local partnerTableID = cost[1]
	local leftTime = self:getLeftTime(tableID)

	if leftTime <= 0 then
		return false
	end

	local recordValue = self:getRecordRedPoint(tableID)

	if recordValue then
		return false
	end

	local partners = xyd.models.slot:getPartners()

	if partnerTableID % 1000 == 999 then
		local star = xyd.tables.partnerIDRuleTable:getStar(partnerTableID)
		local group = xyd.tables.partnerIDRuleTable:getGroup(partnerTableID)

		for key, partner in pairs(partners) do
			if partner:getStar() == star and partner:getGroup() ~= 7 and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) then
				return true
			end
		end
	else
		for key, partner in pairs(partners) do
			local partnerTableID1 = partner:getTableID()

			if partnerTableID1 == partnerTableID and partner:getStar() == 6 and partner:getGroup() ~= 7 and not xyd.tables.partnerTable:checkPuppetPartner(partner:getTableID()) then
				return true
			end
		end
	end
end

function ActivityFoodConsumeData:getRecordRedPoint(tableID)
	if not self.recordRedPointArr then
		self.recordRedPointArr = {}
	end

	return self.recordRedPointArr[tableID] or false
end

function ActivityFoodConsumeData:setRecordRedPoint(tableID)
	if not self.recordRedPointArr then
		self.recordRedPointArr = {}
	end

	self.recordRedPointArr[tableID] = true
end

return ActivityFoodConsumeData
