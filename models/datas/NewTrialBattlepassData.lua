local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewTrialBattlepassData = class("NewTrialBattlepassData", ActivityData, true)

function NewTrialBattlepassData:checkBuy()
	return self.detail_.ex_buy and self.detail_.ex_buy == 1
end

function NewTrialBattlepassData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewTrialBattlepassData:getIndexChoose()
	return self.detail_.index or 0
end

function NewTrialBattlepassData:checkCanChangeAward()
	return self.detail_.is_awarded ~= 1
end

function NewTrialBattlepassData:getRestCanBuy()
	local max_can = tonumber(xyd.tables.miscTable:getVal("new_trial_battlepass_point_paid_limit"))

	return max_can - self.detail_.buy_times
end

function NewTrialBattlepassData:reqAward(ids)
	local info = {
		type = 1,
		ids = xyd.deepCopy(ids)
	}
	self.tempIds_ = ids
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS, params)
end

function NewTrialBattlepassData:reqSelectIndex(index)
	local info = {
		type = 3,
		index = index
	}
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS, params)
end

function NewTrialBattlepassData:buyPoint(num)
	local info = {
		type = 2,
		num = num
	}
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS, params)
end

function NewTrialBattlepassData:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function NewTrialBattlepassData:onAward(data)
	if tonumber(data) and tonumber(data) > 0 then
		return
	end

	if data.activity_id == xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS then
		local info = cjson.decode(data.detail)

		if info.type == 1 then
			local ids = info.ids

			for _, id in ipairs(self.tempIds_) do
				self.detail_.awarded[id] = 1

				if self:checkBuy() then
					self.detail_.ex_awarded[id] = 1
				end
			end

			self.tempIds_ = nil
			self.detail_.is_awarded = 1
		elseif info.type == 2 then
			self.detail_.point = self.detail_.point + info.num
			self.detail_.buy_times = self.detail_.buy_times + info.num
		else
			print("info.index  ", info.index)

			self.detail_.index = info.index
		end
	end
end

function NewTrialBattlepassData:onRecharge(event)
	if xyd.tables.giftBagTable:getActivityID(event.data.giftbag_id) ~= xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS then
		return
	end

	self.detail_.ex_buy = 1
end

function NewTrialBattlepassData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.newTrialBattlePassAwardsTable:getIDs()

	for _, id in ipairs(ids) do
		local need_point = xyd.tables.newTrialBattlePassAwardsTable:getExp(id)

		if need_point <= self.detail_.point and (self.detail_.awarded[id] ~= 1 or self:checkBuy() and self.detail_.ex_awarded[id] ~= 1) then
			return true
		end
	end

	return false
end

return NewTrialBattlepassData
