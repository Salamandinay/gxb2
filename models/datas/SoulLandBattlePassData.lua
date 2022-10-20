local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local SoulLandBattlePassData = class("SoulLandBattlePassData", ActivityData, true)

function SoulLandBattlePassData:ctor(params)
	ActivityData.ctor(self, params)
	self:setRedMark()
end

function SoulLandBattlePassData:getUpdateTime()
	if self.update_time then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function SoulLandBattlePassData:getScoreNow()
	return self.detail.point
end

function SoulLandBattlePassData:isBassAwardedById(id)
	if self.detail.awarded[id] and self.detail.awarded[id] > 0 then
		return true
	end

	return false
end

function SoulLandBattlePassData:isExAwardedById(id)
	if self.detail.ex_awarded[id] and self.detail.ex_awarded[id] > 0 then
		return true
	end

	return false
end

function SoulLandBattlePassData:getBuyTimes()
	return self.detail.buy_times
end

function SoulLandBattlePassData:getGiftBagID()
	return tonumber(self.detail.charges[1].table_id)
end

function SoulLandBattlePassData:checkBuy()
	if self.detail and self.detail.ex_buy == 1 then
		return true
	end

	return false
end

function SoulLandBattlePassData:getRestCanBuy()
	local cost = xyd.tables.miscTable:split2Cost("soul_land_battlepass_point", "value", "|#")
	local maxCan = tonumber(cost[1][1])
	local max1 = maxCan - self.detail.buy_times
	local max2 = xyd.tables.soulLandBattlePassAwardsTable:getMaxScoreCanHold() - self.detail.point

	if max2 <= 0 then
		max2 = 0
	end

	local result = math.min(max1, max2)

	return result
end

function SoulLandBattlePassData:checkFullScore()
	local maxScoreCanHold = xyd.tables.soulLandBattlePassAwardsTable:getMaxScoreCanHold()

	if maxScoreCanHold <= self.detail.point then
		return true
	end

	return false
end

function SoulLandBattlePassData:getCost()
	local cost = xyd.tables.miscTable:split2Cost("soul_land_battlepass_point", "value", "|#")

	return cost[2]
end

function SoulLandBattlePassData:getMaxScoreCanBuy()
	local cost = xyd.tables.miscTable:split2Cost("soul_land_battlepass_point", "value", "|#")
	local maxCan = tonumber(cost[1][1])

	return maxCan
end

function SoulLandBattlePassData:buyScore(num)
	local info = {
		type = 2,
		num = num
	}
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SOUL_LAND_BATTLE_PASS, params)
end

function SoulLandBattlePassData:reqAward(ids)
	local info = {
		type = 1,
		ids = xyd.deepCopy(ids)
	}
	self.tempIds_ = ids
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.SOUL_LAND_BATTLE_PASS, params)
end

function SoulLandBattlePassData:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function SoulLandBattlePassData:onAward(data)
	if tonumber(data) and tonumber(data) > 0 then
		return
	end

	if data.activity_id == xyd.ActivityID.SOUL_LAND_BATTLE_PASS then
		local info = cjson.decode(data.detail)

		if info.type == 1 then
			for _, id in ipairs(self.tempIds_) do
				self.detail_.awarded[id] = 1

				if self:checkBuy() then
					self.detail_.ex_awarded[id] = 1
				end
			end

			self.tempIds_ = nil
		elseif info.type == 2 then
			self.detail.point = self.detail.point + info.num
			self.detail.buy_times = self.detail.buy_times + info.num
		else
			print("error msg")
		end
	end
end

function SoulLandBattlePassData:onRecharge(event)
	if xyd.tables.giftBagTable:getActivityID(event.data.giftbag_id) ~= xyd.ActivityID.SOUL_LAND_BATTLE_PASS then
		return
	end

	self.detail.ex_buy = 1
end

function SoulLandBattlePassData:addScore(num)
	self.detail.point = self.detail.point + num
end

function SoulLandBattlePassData:getRedMarkState()
	local ids = xyd.tables.soulLandBattlePassAwardsTable:getIDs()
	local fundItemList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			scoreNow = self.detail.point,
			scoreNeed = xyd.tables.soulLandBattlePassAwardsTable:getExp(id),
			exBuy = self:checkBuy(),
			isBaseAwarded = self:isBassAwardedById(id),
			isAdvanceAwarded = self:isExAwardedById(id)
		}

		table.insert(fundItemList, params)
	end

	for _, info in ipairs(fundItemList) do
		if info.scoreNeed <= info.scoreNow and info.isBaseAwarded == false or info.scoreNeed <= info.scoreNow and info.isAdvanceAwarded == false and info.exBuy == true then
			return true
		end
	end

	return false
end

function SoulLandBattlePassData:setRedMark()
	local flag = self:getRedMarkState()

	xyd.models.redMark:setMark(xyd.RedMarkType.SOUL_LAND_BATTLE_PASS_GET, flag)
end

return SoulLandBattlePassData
