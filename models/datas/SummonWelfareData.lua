local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local SummonWelfareData = class("SummonWelfareData", ActivityData, true)

function SummonWelfareData:onAward(giftBagID)
	if #self.detail > 1 then
		for i = 1, #self.detail_ do
			if self.detail[i].charge.table_id == giftBagID then
				self.detail[i].charge.buy_times = self.detail[i].charge.buy_times + 1
			end
		end

		return
	end

	if self.detail.table_id ~= giftBagID then
		return
	end

	self.detail.buy_times = self.detail_.buy_times + 1
end

function SummonWelfareData:getUpdateTime()
	return self.detail.update_time + xyd.tables.giftBagTable:getLastTime(self.detail.table_id)
end

return SummonWelfareData
