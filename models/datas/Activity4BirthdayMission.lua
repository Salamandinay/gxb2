local ActivityData = import("app.models.ActivityData")
local Activity4BirthdayMission = class("Activity4BirthdayMission", ActivityData, true)
local json = require("cjson")
local extrasReqList = {
	{
		1,
		5,
		9
	},
	{
		2,
		6,
		10
	},
	{
		3,
		7,
		11
	},
	{
		4,
		8,
		12
	},
	{
		1,
		2,
		3,
		4
	},
	{
		5,
		6,
		7,
		8
	},
	{
		9,
		10,
		11,
		12
	},
	{
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10,
		11,
		12
	}
}

function Activity4BirthdayMission:getUpdateTime()
	return self:getEndTime()
end

function Activity4BirthdayMission:getExtraActiveList()
	local active_list = {}
	local extras = self.detail_.extras
	local awards = self.detail_.awards

	for i = 1, 7 do
		if not extras[i] or extras[i] < 1 then
			local list = extrasReqList[i]
			local flag = true

			for _, id in ipairs(list) do
				if not awards[id] or awards[id] <= 0 then
					flag = false

					break
				end
			end

			if flag then
				table.insert(active_list, i)
			end
		end
	end

	return active_list
end

function Activity4BirthdayMission:getFinalActive()
	local is_big = self.detail_.big_award

	if is_big and is_big == 1 then
		return false
	else
		for i = 1, 12 do
			if self.detail_.awards[i] <= 0 then
				return false
			end
		end
	end

	return true
end

function Activity4BirthdayMission:onAward(data)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_4BIRTHDAY_MISSION, function ()
		local detail = json.decode(data.detail)
		local type = detail.type

		if type == 1 and self.tempOpenCard_ then
			self.detail_.awards[self.tempOpenCard_] = 1
		elseif type == 2 then
			local indexs = detail.indexs

			for _, id in ipairs(indexs) do
				self.detail_.extras[id] = 1
			end
		elseif type == 3 then
			self.detail_.big_award = 1
		end
	end)
	self:getRedMarkState()
end

function Activity4BirthdayMission:setOpenCard(index)
	self.tempOpenCard_ = index
end

function Activity4BirthdayMission:clearTempOpenCard()
	self.tempOpenCard_ = nil
end

function Activity4BirthdayMission:getTempOpenCard()
	return self.tempOpenCard_
end

function Activity4BirthdayMission:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_4birthday_task_cost"), "#", true)
	local can_open = false

	for i = 1, 12 do
		if self.detail_.awards[i] <= 0 then
			can_open = true
		end
	end

	local redState = false

	if can_open and cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
		redState = true
	end

	local active_list = self:getExtraActiveList()

	if active_list and #active_list > 0 then
		redState = true
	end

	if self:getFinalActive() then
		redState = true
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_4BIRTHDAY_MISSION, redState)

	return redState
end

return Activity4BirthdayMission
