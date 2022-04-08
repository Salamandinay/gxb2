local ActivityData = import("app.models.ActivityData")
local ActivityVampireTaskData = class("ActivityVampireTaskData", ActivityData, true)
local json = require("cjson")

function ActivityVampireTaskData:ctor(params)
	ActivityData.ctor(self, params)

	self.giftBagId = xyd.tables.miscTable:getNumber("activity_vampire_giftbag", "value")
	self.levItemId = xyd.tables.miscTable:getNumber("activity_vampire_battlepass_item", "value")
	self.lastNum = 0
end

function ActivityVampireTaskData:getUpdateTime()
	return self:getEndTime()
end

function ActivityVampireTaskData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local flag = false
	local ids = xyd.tables.activityVampireBattlepassTable:getIDs()
	local buy_times = self.detail.charges[1].buy_times
	local num = xyd.models.backpack:getItemNumByID(self.levItemId)

	if self.isCheckOld then
		num = self.lastNum
	else
		self.lastNum = num
	end

	local lev = xyd.tables.activityVampireBattlepassTable:getLev(num)

	for i, id in pairs(ids) do
		if id <= lev then
			if self.detail.awarded[id] == 0 then
				flag = true

				break
			end

			if buy_times > 0 and self.detail.paid_awarded[id] == 0 then
				flag = true

				break
			end
		end
	end

	return flag
end

function ActivityVampireTaskData:setIsCheckOld(state)
	self.isCheckOld = state
end

function ActivityVampireTaskData:onAward(data)
	if type(data) == "number" then
		local giftbagID = data

		if giftbagID ~= self.giftBagId then
			return
		end

		xyd.models.activity:updateRedMarkCount(self.activity_id, function ()
			self.detail.charges[1].buy_times = self.detail.charges[1].buy_times + 1
		end)
	else
		if data.activity_id ~= self.activity_id then
			return
		end

		xyd.models.activity:updateRedMarkCount(self.activity_id, function ()
			local floatItems = {}
			local skins = {}
			local detailsObj = json.decode(data.detail)

			if not detailsObj then
				return
			end

			for _, item_ in ipairs(detailsObj.batch_result) do
				floatItems = xyd.tableConcat(floatItems, item_.items)

				if item_.index == 1 then
					self.detail.awarded[item_.id] = 1
				else
					self.detail.paid_awarded[item_.id] = 1
				end
			end

			xyd.models.itemFloatModel:pushNewItems(floatItems)
		end)
	end
end

return ActivityVampireTaskData
