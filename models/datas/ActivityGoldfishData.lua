local ActivityData = import("app.models.ActivityData")
local ActivityGoldfishData = class("ActivityGoldfishData", ActivityData, true)
local json = require("cjson")

function ActivityGoldfishData:ctor(params)
	ActivityGoldfishData.super.ctor(self, params)
end

function ActivityGoldfishData:getUpdateTime()
	return self:getEndTime()
end

function ActivityGoldfishData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_NET) > 0 then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SAND_SEARCH, true)

		return true
	end

	if self:checkCanBuyShop() then
		xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SAND_SEARCH, true)

		return true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SAND_SEARCH, false)

	return false
end

function ActivityGoldfishData:checkCanBuyShop()
	local awards = self.detail_.awarded or {}

	for i = 1, 4 do
		if self:checkUnlock(i) then
			local ids = xyd.tables.activityGoldfishShopTable:getIDsByLimitNum(i)

			for _, id in ipairs(ids) do
				local limit = xyd.tables.activityGoldfishShopTable:getLimit(id)
				local cost = xyd.tables.activityGoldfishShopTable:getCost(id)

				if awards[id] < limit and cost[2] <= xyd.models.backpack:getItemNumByID(xyd.ItemID.GOLDFISH_ICON) then
					return true
				end
			end
		end
	end

	return false
end

function ActivityGoldfishData:getPoint()
	return self.detail_.point
end

function ActivityGoldfishData:getHisCoin()
	return self.detail_.history_coin or 0
end

function ActivityGoldfishData:getStartSelect()
	local awards = self.detail_.awarded or {}
	local select = 1

	for i = 4, 1, -1 do
		if self:checkUnlock(i) then
			local ids = xyd.tables.activityGoldfishShopTable:getIDsByLimitNum(i)
			local buyNum = 0

			for _, id in ipairs(ids) do
				local limit = xyd.tables.activityGoldfishShopTable:getLimit(id)

				if limit <= awards[id] then
					buyNum = buyNum + 1
				end
			end

			if buyNum < #ids then
				return i
			end
		end
	end

	return select
end

function ActivityGoldfishData:checkUnlock(index)
	local point = self:getPoint()
	local limit_num = xyd.tables.activityGoldfishShopTable:getLimitNumByIndex(index)

	return limit_num <= point
end

function ActivityGoldfishData:getCoin()
	return self.detail_.coin
end

function ActivityGoldfishData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_GOLDFISH, function ()
		if data.activity_id == xyd.ActivityID.ACTIVITY_GOLDFISH then
			local detail = json.decode(data.detail)
			local info = detail.info
			self.detail_ = info

			if detail.type_id == 1 then
				self.needUpdateMission_ = true
			end
		end
	end)
end

function ActivityGoldfishData:checkNeedUpdate()
	if self.needUpdateMission_ then
		self.needUpdateMission_ = false

		return true
	end
end

return ActivityGoldfishData
