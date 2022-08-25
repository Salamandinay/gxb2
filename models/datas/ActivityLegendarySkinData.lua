local ActivityData = import("app.models.ActivityData")
local ActivityLegendarySkinData = class("ActivityLegendarySkinData", ActivityData, true)
local json = require("cjson")

function ActivityLegendarySkinData:ctor(params)
	self.checkItemId = xyd.ItemID.LEGENDARY_SKIN_ICON1
	self.checkBackpackItemNum = xyd.models.backpack:getItemNumByID(self.checkItemId)

	ActivityData.ctor(self, params)
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.onItemChangeBack))
end

function ActivityLegendarySkinData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLegendarySkinData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false
	local Intime = tonumber(xyd.db.misc:getValue("activity_legendary_time"))

	if self.checkBackpackItemNum > 10 and not xyd.isSameDay(Intime, xyd.getServerTime()) then
		flag = true
	end

	if self:checkShopRed() then
		flag = true
	end

	return flag
end

function ActivityLegendarySkinData:checkShopRed()
	local ids = xyd.tables.activityLengarySkinShopTable:getIDs()
	local buy_times = self.detail.buy_times

	for index, id in ipairs(ids) do
		local limit = xyd.tables.activityLengarySkinShopTable:getLimit(id)
		local cost = xyd.tables.activityLengarySkinShopTable:getCost(id)

		if limit == 1 and (not buy_times[index] or buy_times[index] <= 0) and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			return true
		end
	end

	return false
end

function ActivityLegendarySkinData:getSkinID()
	return 1
end

function ActivityLegendarySkinData:getValue()
	return self.detail_.value or 0
end

function ActivityLegendarySkinData:getItems(id)
	return self.detail_.items
end

function ActivityLegendarySkinData:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN, function ()
		if data.activity_id == xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN then
			local data = xyd.decodeProtoBuf(data)
			local info = {}

			if data.detail and tostring(data.detail) ~= "" then
				info = json.decode(data.detail)
			end

			local type = info.type

			print("type   ", type)

			if type == 1 then
				local awards = info.awards

				for i = 1, #awards do
					local id = awards[i]
					local award = xyd.tables.activityLengarySkinAwardTable:getAward(id)

					if self.detail_.items[tostring(award[1])] then
						self.detail_.items[tostring(award[1])] = self.detail_.items[tostring(award[1])] + award[2]
					else
						self.detail_.items[tostring(award[1])] = award[2]
					end
				end
			end
		end
	end)
end

function ActivityLegendarySkinData:onItemChangeBack(event)
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

return ActivityLegendarySkinData
