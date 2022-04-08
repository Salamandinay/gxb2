local ActivityData = import("app.models.ActivityData")
local ActivityFoolClockGiftbagData = class("ActivityFoolClockGiftbagData", ActivityData, true)
local json = require("cjson")

function ActivityFoolClockGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function ActivityFoolClockGiftbagData:onAward(event)
end

function ActivityFoolClockGiftbagData:getDiamondBuyTimes()
	return tonumber(self.detail_.buy_times) or 0
end

function ActivityFoolClockGiftbagData:getGiftbagCharges(giftbagId)
	local charges = self.detail_.charges
	local res = nil

	for i = 1, #charges do
		if tonumber(charges[i].table_id) == tonumber(giftbagId) then
			local chooseIndex = tonumber(self.detail_[tostring(giftbagId)]) or 0
			res = {
				giftbag_id = giftbagId,
				limit_times = charges[i].limit_times,
				buy_times = charges[i].buy_times,
				choose_index = chooseIndex
			}

			break
		end
	end

	return res
end

function ActivityFoolClockGiftbagData:updateGiftbagBuyTimes(giftbagId)
	local charges = self.detail_.charges
	local res = nil

	for i = 1, #charges do
		if tonumber(charges[i].table_id) == tonumber(giftbagId) then
			charges[i].buy_times = charges[i].buy_times + 1

			break
		end
	end
end

function ActivityFoolClockGiftbagData:updateChooseIndex(giftbagId, index)
	self.detail_[tostring(giftbagId)] = index
end

function ActivityFoolClockGiftbagData:getChooseIndex(giftbagId)
	return tonumber(self.detail_[tostring(giftbagId)]) or 0
end

function ActivityFoolClockGiftbagData:selectSpecialAward(giftbagId, chooseIndex)
	local msg = messages_pb.giftbag_set_attach_index_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_FOOL_CLOCK_GIFTBAG

	table.insert(msg.indexs, chooseIndex)

	msg.giftbag_id = giftbagId

	xyd.Backend.get():request(xyd.mid.GIFTBAG_SET_ATTACH_INDEX, msg)
	self:updateChooseIndex(giftbagId, chooseIndex)
end

return ActivityFoolClockGiftbagData
