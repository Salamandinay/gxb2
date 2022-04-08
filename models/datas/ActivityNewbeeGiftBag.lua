local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityNewbeeGiftBag = class("ActivityNewbeeGiftBag", ActivityData, true)

function ActivityNewbeeGiftBag:getUpdateTime()
	return self.detail_.info.start_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityNewbeeGiftBag:getEndTime()
	return self.detail_.info.start_time + xyd.TimePeriod.WEEK_TIME
end

function ActivityNewbeeGiftBag:onAward(params)
	if type(params) == "number" then
		local giftbagID = params

		for i = 1, 3 do
			if tonumber(self.detail_.charges[i].table_id) == giftbagID then
				self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

				break
			end
		end
	else
		local detail = json.decode(params.detail)
		self.detail_.info = detail.info
	end
end

return ActivityNewbeeGiftBag
