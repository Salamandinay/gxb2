local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityLegendarySkinGiftBagData = class("ActivityLegendarySkinGiftBagData", ActivityData, true)

function ActivityLegendarySkinGiftBagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityLegendarySkinGiftBagData:onAward(data)
	dump(data)

	if type(data) == "number" then
		for i = 1, #self.detail.charges do
			if data == self.detail.charges[i].table_id then
				self.detail.charges[i].buy_times = self.detail.charges[i].buy_times + 1

				break
			end
		end
	else
		local detail = json.decode(data.detail)
		local awards = detail.info.award
		local charges = detail.info.charges
		self.detail.award = awards

		for i = 1, #charges do
			self.detail.charges[i].buy_times = charges[i].buy_times
		end
	end
end

function ActivityLegendarySkinGiftBagData:getRedMarkState()
	self.defRedMark = false

	return self.defRedMark
end

return ActivityLegendarySkinGiftBagData
