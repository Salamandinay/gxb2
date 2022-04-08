local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityGropupGiftBag = class("ActivityGropupGiftBag", ActivityData, true)

function ActivityGropupGiftBag:setData(params)
	ActivityGropupGiftBag.super.setData(self, params)
	self:changeDetailPart()
end

function ActivityGropupGiftBag:ctor(params)
	ActivityGropupGiftBag.super.ctor(self, params)
	self:changeDetailPart()
end

function ActivityGropupGiftBag:changeDetailPart()
	local params = {
		charge = {}
	}

	for i = 1, 2 do
		params.charge[i] = {
			buy_times = 0,
			start_time = 0,
			table_id = 186 + i
		}
	end

	if #self.detail_ == 1 then
		if self.detail_[1] and tonumber(self.detail_[1].charge.table_id) == 188 then
			params.charge[2] = self.detail_[1].charge
			params.charge[1].buy_times = 1
		elseif self.detail_[1] and tonumber(self.detail_[1].charge.table_id) == 187 then
			params.charge[1] = self.detail_[1].charge
			params.charge[2].buy_times = 1
		end
	elseif #self.detail_ == 2 then
		for i = 1, 2 do
			if self.detail_[i] then
				params.charge[i] = self.detail_[i].charge
			end
		end
	end

	params.update_time = self.detail_[1].update_time
	self.detail_ = params
end

function ActivityGropupGiftBag:checkPop()
	if xyd.GuideController.get():isGuideComplete() then
		local value = tonumber(xyd.db.misc:getValue("gropup_pop_up_window_check"))

		if not value or not xyd.isSameDay(value, xyd.getServerTime()) then
			return true
		end
	end

	return false
end

function ActivityGropupGiftBag:doAfterPop()
	xyd.db.misc:setValue({
		key = "gropup_pop_up_window_check",
		value = xyd.getServerTime()
	})
end

function ActivityGropupGiftBag:getPopWinName()
	return "limit_gropup_giftbag_pop_up_window"
end

function ActivityGropupGiftBag:getUpdateTime()
	if not self.detail_.update_time or self.detail_.update_time == 0 then
		return self:getEndTime()
	end

	return self.detail_.update_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityGropupGiftBag:isShow()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:getUpdateTime() < xyd.getServerTime() then
		return false
	else
		return true
	end
end

function ActivityGropupGiftBag:onAward(giftbag_id)
	for i = 1, 2 do
		local table_id = self.detail_.charge[i].table_id

		if tonumber(table_id) == tonumber(giftbag_id) then
			self.detail_.charge[i].buy_times = self.detail_.charge[i].buy_times + 1
		end
	end
end

return ActivityGropupGiftBag
