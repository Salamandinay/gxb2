local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ActivityTowerFundGiftBag = class("ActivityTowerFundGiftBag", GiftBagData, true)

function ActivityTowerFundGiftBag:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.TOWER_FIGHT, handler(self, self.updateRedMarkState))
end

function ActivityTowerFundGiftBag:onAward(data)
	local giftBagId = tonumber(data)
	local charges = self.detail.charges

	for i = 1, #charges do
		if tonumber(charges[i].table_id) == giftBagId then
			charges[i].buy_times = charges[i].buy_times + 1
		end
	end
end

function ActivityTowerFundGiftBag:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	local hide = true
	local ids = xyd.tables.activityTowerFundGiftBagTable:getIds()

	for i = 1, #ids do
		local rewarded = tonumber(self.detail.awards_info.awarded[ids[i]]) or 0

		if rewarded and rewarded == 0 then
			hide = false

			break
		end
	end

	return hide
end

function ActivityTowerFundGiftBag:updateRedMarkState()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.TOWER_FUND_GIFTBAG, function ()
		self.holdRed = false
	end)
end

function ActivityTowerFundGiftBag:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		local lastLevel = xyd.db.misc:getValue("activity_tower_fund_giftbag")
		local maxLevel, _ = self:getMaxLevel()

		if self:isHide() then
			self.defRedMark = false
		elseif not lastLevel or tonumber(lastLevel) < maxLevel then
			self.defRedMark = true
		else
			self.defRedMark = false
		end

		local buyTimes = 0

		for i, charge in pairs(self.detail.charges) do
			if charge.buy_times >= 1 then
				buyTimes = buyTimes + 1
			end
		end

		if buyTimes >= #self.detail.charges then
			self.towerWindowMark = false
		else
			local lastViewTowerID = tonumber(xyd.db.misc:getValue("tower_fund_giftbag_view_towerid") or 0)
			local maxTowerID = 0
			local curTowerID = 0

			if buyTimes > 0 then
				for i, charge in pairs(self.detail.charges) do
					if charge.buy_times >= 1 then
						maxTowerID = math.max(maxTowerID, xyd.tables.activityTowerFundGiftBagTable:getMaxTowerIDByGiftbagID(charge.table_id))
					end
				end

				curTowerID = xyd.models.towerMap.stage - xyd.models.towerMap.stage % 20
			else
				local showRedTowerIDs = xyd.tables.miscTable:split2Cost("tower_giftbag_nopay_redmark", "value", "|") or {}

				for i, towerID in pairs(showRedTowerIDs) do
					if towerID <= xyd.models.towerMap.stage then
						curTowerID = math.max(curTowerID, towerID)
					end
				end
			end

			if math.max(maxTowerID, lastViewTowerID) < curTowerID then
				self.towerWindowMark = true
			else
				self.towerWindowMark = false
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.TOWER_FUND_GIFTBAG, self.towerWindowMark)

	return self.defRedMark
end

function ActivityTowerFundGiftBag:setRedState(maxLevel)
	xyd.db.misc:setValue({
		key = "activity_tower_fund_giftbag",
		value = maxLevel
	})
end

function ActivityTowerFundGiftBag:getMaxLevel()
	local stage1 = self.detail.awards_info.stage or 0
	local stage2 = xyd.models.towerMap.stage or 1
	stage2 = stage2 - 1
	local stage = xyd.checkCondition(stage2 < stage1, stage1, stage2)
	local maxId = 0
	local ids = xyd.tables.activityTowerFundGiftBagTable:getIds()
	local level = 1

	for i = 1, #ids do
		local id = ids[i]
		local tower_id = xyd.tables.activityTowerFundGiftBagTable:getTowerId(id)
		local levelMax = xyd.tables.activityTowerFundGiftBagTable:getLevel(id)
		level = levelMax

		if stage < tower_id then
			break
		else
			maxId = id
		end
	end

	return level, maxId, stage
end

function ActivityTowerFundGiftBag:backRank()
	local maxLevel = self:getMaxLevel()
	local state = true

	for i = 1, maxLevel do
		if self.detail.charges[i].buy_times ~= 1 then
			state = false

			break
		end
	end

	return state
end

return ActivityTowerFundGiftBag
