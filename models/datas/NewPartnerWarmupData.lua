local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local NewPartnerWarmupData = class("NewPartnerWarmupData", ActivityData, true)

function NewPartnerWarmupData:getUpdateTime()
	if self.update_time ~= "nil" then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function NewPartnerWarmupData:onAward(data)
	local rewards = xyd.split(data.detail, "|")

	for i = 1, #rewards do
		if self.detail.rewards[i] == 0 and tonumber(rewards[i]) ~= 0 then
			local item = xyd.tables.newPartnerWarmUpAwardTable:getAwards(i)

			xyd.itemFloat({
				{
					item_id = item[1],
					item_num = item[2]
				}
			}, nil, , 6500)
		end

		self.detail.rewards[i] = tonumber(rewards[i])
	end
end

return NewPartnerWarmupData
