local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local BattlePass = class("BattlePass", ActivityData, true)

function BattlePass:getUpdateTime()
	if not self.update_time then
		return self.getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function BattlePass:onAward(data)
	if not data then
		return
	elseif type(data) == "number" then
		for _, info in ipairs(self.detail_.charges) do
			if tonumber(info.table_id) == data and info.buy_times == 0 then
				info.buy_times = info.buy_times + 1

				break
			end
		end

		return
	end

	local details = require("cjson").decode(data.detail)

	for _, detail in ipairs(details) do
		local index = detail.index
		local id = detail.id

		if tonumber(index) == 1 then
			self.detail_.awarded[id - 1] = 1
		else
			self.detail_.paid_awarded[id - 1] = 1
		end
	end
end

function BattlePass:updateInfo(data)
end

function BattlePass:updatePaidRecord(data)
	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == data.id then
			self.detail_.charges[i].buy_times = 1
		end
	end
end

function BattlePass:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	local charges = self.detail_.charges
	local is_extra = charges[1].buy_times > 0 or charges[3].buy_times > 0 or charges[1].buy_times > 0 and charges[2].buy_times > 0
	local cur_lev = xyd.getBpLev()
	local flag = false
	local battlePassAwardTable = xyd.models.activity:getBattlePassTable(xyd.BATTLE_PASS_TABLE.AWARD)

	for i = 1, cur_lev do
		local index = self.detail_.awarded[i]
		local index2 = self.detail_.paid_awarded[i]
		local award = battlePassAwardTable:getFreeAward(i)

		if award and award[1] and award[1][1] and (not index or index == 0) or is_extra and (not index2 or index2 == 0) then
			flag = true

			break
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.BATTLE_PASS, flag)

	return false
end

return BattlePass
