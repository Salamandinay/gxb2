local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local AcademyAssessmentPushGiftbagData = class("AcademyAssessmentPushGiftbagData", ActivityData, true)

function AcademyAssessmentPushGiftbagData:onAward(giftBagID)
	if self.detail[1] then
		for i = 1, #self.detail do
			if self.detail[i].charge.table_id == giftBagID then
				self.detail[i].charge.buy_times = self.detail[i].charge.buy_times + 1
			end
		end
	end
end

return AcademyAssessmentPushGiftbagData
