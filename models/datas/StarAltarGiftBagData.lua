local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local StarAltarGiftBagData = class("StarAltarGiftBagData", GiftBagData, true)

function StarAltarGiftBagData:getUpdateTime()
	if not self.update_time then
		return self:getEndTime()
	end

	return self.update_time + 604800
end

function StarAltarGiftBagData:onAward(event)
	local giftBagID = type(event) == "number" and event or event.data.giftbag_id

	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			self.detail_.charges[i].buy_times = self.detail_.charges[i].buy_times + 1

			if self.detail_.charges[i].buy_times == self.detail_.charges[i].limit_times and xyd.tables.giftBagTable:getParams(giftBagID) and xyd.tables.giftBagTable:getParams(giftBagID)[1] then
				local msg = messages_pb:get_activity_info_by_id_req()
				msg.activity_id = self.id

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
				self:setGiftbagID(giftBagID)
			end
		end
	end
end

function StarAltarGiftBagData:isOpen()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_STAR_ALTAR_MISSION)

	print("=============================activityData:isOpen()====================  ", activityData:isOpen())

	return xyd.checkFunctionOpen(xyd.FunctionID.STARRY_ALTAR) or activityData and activityData:isOpen()
end

return StarAltarGiftBagData
