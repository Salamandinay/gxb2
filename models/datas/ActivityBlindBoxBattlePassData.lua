local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityBlindBoxBattlePassData = class("ActivityBlindBoxBattlePassData", ActivityData, true)

function ActivityBlindBoxBattlePassData:getRedMarkState()
	local ids = xyd.tables.activityBlindBoxBattlePassTable:getIDs()
	local fundItemList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			dayNow = self:getPassedDayRound(),
			dayNeed = id,
			baseAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards1(id),
			advanceAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards2(id),
			superAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards3(id),
			giftBag1Buy = self:checkGiftBag1Buy(),
			giftBag2Buy = self:checkGiftBag2Buy(),
			isBaseAwarded = self:isBaseAwardedById(id),
			isAdvanceAwarded = self:isAdvAwardedById(id),
			isSuperAwarded = self:isSuperAwardedById(id)
		}

		table.insert(fundItemList, params)
	end

	for _, info in ipairs(fundItemList) do
		if info.dayNeed <= info.dayNow and info.isBaseAwarded == false or info.dayNeed <= info.dayNow and info.isAdvanceAwarded == false and info.giftBag1Buy == true or info.dayNeed <= info.dayNow and info.isSuperAwarded == false and info.giftBag2Buy == true then
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BLIND_BOX_BATTLE_PASS, true)

			return true
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_BLIND_BOX_BATTLE_PASS, false)

	return false
end

function ActivityBlindBoxBattlePassData:isBaseAwardedById(id)
	if self.detail.awarded1 and self.detail.awarded1[id] and self.detail.awarded1[id] == 1 then
		return true
	end

	return false
end

function ActivityBlindBoxBattlePassData:isAdvAwardedById(id)
	if self.detail.awarded2 and self.detail.awarded2[id] and self.detail.awarded2[id] == 1 then
		return true
	end

	return false
end

function ActivityBlindBoxBattlePassData:isSuperAwardedById(id)
	if self.detail.awarded3 and self.detail.awarded3[id] and self.detail.awarded3[id] == 1 then
		return true
	end

	return false
end

function ActivityBlindBoxBattlePassData:checkGiftBag1Buy()
	if self.detail and self.detail.ex_buy and self.detail.ex_buy[1] == 1 then
		return true
	end

	return false
end

function ActivityBlindBoxBattlePassData:checkGiftBag2Buy()
	if self.detail and self.detail.ex_buy and self.detail.ex_buy[2] == 1 then
		return true
	end

	return false
end

function ActivityBlindBoxBattlePassData:reqAward(ids)
	local info = {
		ids = xyd.deepCopy(ids)
	}
	self.tempIds_ = ids
	local params = cjson.encode(info)

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_BLIND_BOX_BATTLE_PASS, params)
end

function ActivityBlindBoxBattlePassData:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityBlindBoxBattlePassData:onAward(data)
	if tonumber(data) and tonumber(data) > 0 then
		return
	end

	if data.activity_id == xyd.ActivityID.ACTIVITY_BLIND_BOX_BATTLE_PASS then
		local info = cjson.decode(data.detail)

		for _, id in ipairs(self.tempIds_) do
			self.detail_.awarded1[id] = 1

			if self:checkGiftBag1Buy() then
				self.detail_.awarded2[id] = 1
			end

			if self:checkGiftBag2Buy() then
				self.detail_.awarded3[id] = 1
			end
		end

		self.tempIds_ = nil
	end
end

function ActivityBlindBoxBattlePassData:onRecharge(event)
	if xyd.tables.giftBagTable:getActivityID(event.data.giftbag_id) ~= xyd.ActivityID.ACTIVITY_BLIND_BOX_BATTLE_PASS then
		return
	end

	local giftBagID = event.data.giftbag_id

	if giftBagID == self.detail.charges[1].table_id then
		self.detail.ex_buy[1] = 1
	elseif giftBagID == self.detail.charges[2].table_id then
		self.detail.ex_buy[2] = 1
	end
end

return ActivityBlindBoxBattlePassData
