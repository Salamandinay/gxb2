local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local QiXiGiftBagData = class("QiXiGiftBagData", ActivityData, true)
QiXiGiftBagData.choose_queue = {}

function QiXiGiftBagData:setChoose(id)
	table.insert(QiXiGiftBagData.choose_queue, id)
end

function QiXiGiftBagData:getUpdateTime()
	if not self.update_time or self.update_time == 0 then
		return self:getEndTime()
	end

	return self.update_time + xyd.tables.activityTable:getLastTime(self.activity_id)
end

function QiXiGiftBagData:getRedMarkState()
	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	local ids = xyd.tables.activityGiftBoxTable:getIDs()

	for i = 1, #ids do
		if self.detail.buy_times[i] < xyd.tables.activityGiftBoxTable:getLimit(ids[i]) then
			return self.defRedMark
		end
	end

	return false
end

function QiXiGiftBagData:onAward(event)
	local count = 1

	while #QiXiGiftBagData.choose_queue > 0 do
		self.detail.buy_times[QiXiGiftBagData.choose_queue[1]] = self.detail.buy_times[QiXiGiftBagData.choose_queue[1]] + 1

		table.remove(QiXiGiftBagData.choose_queue, 1)

		count = count + 1

		if count > 10 then
			break
		end
	end
end

return QiXiGiftBagData
