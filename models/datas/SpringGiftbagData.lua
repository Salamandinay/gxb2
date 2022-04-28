local ActivityData = import("app.models.ActivityData")
local SpringGiftbagData = class("SpringGiftbagData", ActivityData, true)
local json = require("cjson")

function SpringGiftbagData:getUpdateTime()
	return self:getEndTime()
end

function SpringGiftbagData:onAward(giftbagId)
	for _, charge in pairs(self.detail_.charges) do
		if charge.table_id == giftbagId then
			charge.buy_times = charge.buy_times + 1
		end
	end
end

function SpringGiftbagData:updateChooseIndex(giftbagId, index)
	for i, charge in pairs(self.detail_.charges) do
		if charge.table_id == giftbagId then
			self.detail_.charges[i].attach = index
		end
	end
end

function SpringGiftbagData:getChooseIndex(giftbagId)
	for _, charge in pairs(self.detail_.charges) do
		if charge.table_id == giftbagId then
			return charge.attach or {}
		end
	end
end

function SpringGiftbagData:selectSpecialAward(giftbagId, chooseIndex)
	local needSendReq = true
	local msg = messages_pb.giftbag_set_attach_index_req()
	msg.activity_id = xyd.ActivityID.SPRING_GIFTBAG

	for _, index in ipairs(chooseIndex) do
		table.insert(msg.indexs, index)

		if not index or index == 0 then
			needSendReq = false
		end
	end

	msg.giftbag_id = giftbagId

	if needSendReq then
		xyd.Backend.get():request(xyd.mid.GIFTBAG_SET_ATTACH_INDEX, msg)
	end

	self:updateChooseIndex(giftbagId, chooseIndex)
end

return SpringGiftbagData
