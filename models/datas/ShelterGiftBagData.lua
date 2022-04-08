local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local ShelterGiftBagData = class("ShelterGiftBagData", ActivityData, true)

function ShelterGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function ShelterGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	for i = 1, #self.detail.awarded do
		if not self.detail.awarded[i] then
			return self.defRedMark
		end
	end

	return false
end

function ShelterGiftBagData:onAward(data)
	local real_data = json.decode(data.detail)
	self.detail.awarded = real_data.awarded

	for i = 1, #real_data.material_ids do
		xyd.models.slot:deletePartner(real_data.material_ids[i])
	end
end

return ShelterGiftBagData
