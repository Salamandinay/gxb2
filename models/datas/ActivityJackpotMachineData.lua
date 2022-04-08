local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityJackpotMachineData = class("ActivityJackpotMachineData", ActivityData, true)

function ActivityJackpotMachineData:getUpdateTime()
	return self:getEndTime()
end

function ActivityJackpotMachineData:getRedMarkState()
	self.defRedMark = false

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	end

	local freeIDs = xyd.tables.activityJackpotExchangeTable:getIDs()

	for i = 1, #freeIDs do
		if self.detail.buy_times[freeIDs[i]] < xyd.tables.activityJackpotExchangeTable:getLimit(freeIDs[i]) and not self.giftbagRed then
			self.defRedMark = true
		end
	end

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_JACKPOT_ENERGY) > 0 then
		self.defRedMark = true
	end

	local ids = xyd.tables.activityJackpotAwardTable:getIDs()

	for i = 1, #ids do
		if self.detail.award_ids[i] == 0 and xyd.tables.activityJackpotAwardTable:getComplete(ids[i]) <= tonumber(self.detail.senior_energy) then
			self.defRedMark = true
		end
	end

	return self.defRedMark
end

function ActivityJackpotMachineData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onJackpotAward))
end

function ActivityJackpotMachineData:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	for i = 1, #self.detail.charges do
		if self.detail.charges[i].table_id == giftBagID then
			self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1
		end
	end
end

function ActivityJackpotMachineData:onJackpotAward(event)
	if event.data.activity_id ~= xyd.ActivityID.JACKPOT_MACHINE then
		return
	end

	local detail = json.decode(event.data.detail)

	if detail.award_type == 4 then
		self.detail.award_ids[self.awardTableID] = self.detail.award_ids[self.awardTableID] + 1
		local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

		if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.JACKPOT_MACHINE then
			common_progress_award_window_wn:updateItemState(self.awardTableID, 3)
		end

		xyd.itemFloat(detail.items)
	else
		self.detail = detail.act_info

		if detail.award_type == 2 then
			xyd.itemFloat(detail.items)
		end
	end
end

function ActivityJackpotMachineData:setMachineType(machineType)
	self.machineType = machineType
end

function ActivityJackpotMachineData:setGiftbagRed(state)
	self.giftbagRed = state
end

function ActivityJackpotMachineData:setAwardTableID(awardTableID)
	self.awardTableID = awardTableID
end

function ActivityJackpotMachineData:setSeniorMachineGuideFlag(flag)
	self.seniorMachineGuideFlag = flag
end

function ActivityJackpotMachineData:getSeniorMachineGuideFlag()
	return self.seniorMachineGuideFlag
end

return ActivityJackpotMachineData
