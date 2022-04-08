local ActivityData = import("app.models.ActivityData")
local ActivityJackpotLotteryData = class("ActivityJackpotLotteryData", ActivityData, true)
local json = require("cjson")

function ActivityJackpotLotteryData:getUpdateTime()
	return self:getEndTime()
end

function ActivityJackpotLotteryData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY then
		return
	end

	local detail = json.decode(data.detail)

	if detail.award_type == 4 then
		self.detail.award_ids[self.awardTableID] = self.detail.award_ids[self.awardTableID] + 1
		local common_progress_award_window_wn = xyd.WindowManager.get():getWindow("common_progress_award_window")

		if common_progress_award_window_wn and common_progress_award_window_wn:getWndType() == xyd.CommonProgressAwardWindowType.ACTIVITY_JACKPOT_LOTTERY then
			common_progress_award_window_wn:updateItemState(self.awardTableID, 3)
		end

		xyd.itemFloat(detail.items)
	elseif detail.award_type ~= 3 then
		self.detail = detail.info

		if detail.items and #detail.items > 0 then
			local num = 0

			if detail.award_type == 1 then
				for i = 1, #self.detail.awards do
					num = num + self.detail.awards[i].num
				end
			else
				for i = 1, #self.detail.senior_awards do
					num = num + self.detail.senior_awards[i].num
				end
			end

			if detail.num == 1 then
				num = 1
			elseif num > 10 then
				num = 10
			end

			local cost = detail.award_type == 1 and xyd.tables.miscTable:split2num("activity_jackpot_normal", "value", "#") or xyd.tables.miscTable:split2num("activity_jackpot_updated", "value", "#")

			xyd.openWindow("gamble_rewards_window", {
				wnd_type = 4,
				data = detail.items,
				cost = {
					cost[1],
					num * cost[2]
				},
				btnLabelText = __("ACTIVITY_3BIRTHDAY_TEXT12", num),
				buyCallback = function ()
					if xyd.models.backpack:getItemNumByID(cost[1]) < num * cost[2] then
						xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

						return
					end

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_JACKPOT_LOTTERY, json.encode({
						award_type = detail.award_type,
						num = num
					}))
				end
			})
		end
	end
end

function ActivityJackpotLotteryData:getRedMarkState()
	self.defRedMark = false

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	end

	local upCostOne = xyd.tables.miscTable:split2num("activity_jackpot_normal", "value", "#")
	local downCostOne = xyd.tables.miscTable:split2num("activity_jackpot_updated", "value", "#")

	if upCostOne[2] <= xyd.models.backpack:getItemNumByID(upCostOne[1]) or downCostOne[2] <= xyd.models.backpack:getItemNumByID(downCostOne[1]) then
		self.defRedMark = true
	end

	return self.defRedMark
end

function ActivityJackpotLotteryData:setAwardTableID(awardTableID)
	self.awardTableID = awardTableID
end

return ActivityJackpotLotteryData
