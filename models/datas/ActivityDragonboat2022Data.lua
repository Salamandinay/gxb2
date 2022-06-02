local ActivityData = import("app.models.ActivityData")
local ActivityDragonboat2022Data = class("ActivityDragonboat2022Data", ActivityData, true)
local cjson = require("cjson")

function ActivityDragonboat2022Data:getUpdateTime()
	return self:getEndTime()
end

function ActivityDragonboat2022Data:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_DRAGONBOAT2022 then
		return
	end

	local detail = cjson.decode(data.detail)

	if detail.info then
		self.detail = detail.info

		if self.gachaTime then
			local data = {}
			local coolAward = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_extra_awards", "value", "#")

			for i = 1, self.gachaTime do
				local awards = detail[tostring(i)]

				for _, award in pairs(awards) do
					table.insert(data, {
						item_id = award[1],
						item_num = award[2],
						cool = coolAward[1] == award[1] and 1 or 0
					})
				end
			end

			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 7,
				data = data
			})
		end
	end

	if detail.chosen_ids then
		self.detail.chosen_ids = detail.chosen_ids
	end

	if detail.point then
		self.detail.point = detail.point
	end

	if detail.awarded_chosen then
		self.detail.awarded_chosen = detail.awarded_chosen
	end

	if self.award_id then
		local awards = xyd.tables.activityDragonboat2022ChoseTable:getAwards(self.award_id)
		local awardChosen = awards[self.detail.chosen_ids[self.award_id]]
		local datas = {}

		table.insert(datas, {
			item_id = awardChosen[1],
			item_num = awardChosen[2]
		})
		xyd.models.itemFloatModel:pushNewItems(datas)

		self.award_id = nil
	end
end

function ActivityDragonboat2022Data:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_DRAGONBOAT2022, function ()
		self.holdRed = false
	end)
end

function ActivityDragonboat2022Data:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false

		for i = 1, 3 do
			local point = xyd.tables.activityDragonboat2022ChoseTable:getPoint(i)

			if point <= self.detail.point and (not self.detail.awarded_chosen or not self.detail.awarded_chosen[i] or self.detail.awarded_chosen[i] == 0) then
				self.defRedMark = true
			end
		end

		local cost = xyd.tables.miscTable:split2Cost("activity_dragonboat2022_cost", "value", "#")

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			self.defRedMark = true
		end
	end

	return self.defRedMark
end

return ActivityDragonboat2022Data
