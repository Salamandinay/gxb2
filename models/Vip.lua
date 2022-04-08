local BaseModel = import(".BaseModel")
local Vip = class("Vip", BaseModel)

function Vip:ctor()
	BaseModel.ctor(self)

	self.awardData_ = {}
	self.timeCount_ = nil
	self.redPoint_ = false
end

function Vip:onRegister()
	BaseModel.onRegister(self)
	self:registerEvent(xyd.event.GET_VIP_AWARD_INFO, self.onGetVipAwardInfo, self)
	self:registerEvent(xyd.event.BUY_VIP_AWARD, self.onGetVipAwardInfo, self)
	self:registerEvent(xyd.event.GET_VIP_AWARD, self.onGetVipAwardInfo, self)
end

function Vip:onGetVipAwardInfo(event)
	self.awardData_ = event.data

	self:updateRedMark()
end

function Vip:updateRedMark()
	local flag = self:countRedMark()

	if flag ~= self.redPoint_ then
		xyd.models.redMark:setMark(xyd.RedMarkType.VIP_AWARD, flag)
	end

	self.redPoint_ = flag
end

function Vip:countRedMark()
	local flag = false
	local i = 1

	while i < xyd.models.backpack:getMaxVipLev() + 1 do
		if self:isCanPickAward(i) or self:isCanBuyGift(i) then
			flag = true

			break
		end

		i = i + 1
	end

	return flag
end

function Vip:isCanPickAward(id)
	id = tonumber(id)
	local vipLev = xyd.models.backpack:getVipLev()

	if vipLev < id then
		return false
	end

	local awardRecords = self.awardData_.award_records or {}
	local status = awardRecords[id] or 0

	if status == 0 then
		return true
	else
		return false
	end
end

function Vip:isCanBuyGift(id)
	id = tonumber(id)
	local vipLev = xyd.models.backpack:getVipLev()

	if vipLev < id then
		return false
	end

	local buyRecords = self.awardData_.buy_records or {}
	local status = buyRecords[id] or 0

	if status == 0 then
		return true
	else
		return false
	end
end

function Vip:buyVipAward(id)
	local msg = messages_pb:buy_vip_award_req()
	msg.id = id

	xyd.Backend.get():request(xyd.mid.BUY_VIP_AWARD, msg)
end

function Vip:getVipAward(id)
	local msg = messages_pb:get_vip_award_req()
	msg.id = id

	xyd.Backend.get():request(xyd.mid.GET_VIP_AWARD, msg)
end

return Vip
