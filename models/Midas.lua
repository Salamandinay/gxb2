local Midas = class("Midas", import(".BaseModel"))

function Midas:ctor()
	Midas.super.ctor(self)

	self.isBuy_ = {}
	self.nextBuyTime_ = 0
	self.buy_times = 0
	self.update_time = 0
	self.is_free_award = 0
end

function Midas:getIsBuy()
	return self.isBuy_
end

function Midas:getNextBuyTime()
	return self.nextBuyTime_
end

function Midas:setIsBuy(params)
	self.isBuy_ = params
end

function Midas:setNextBuyTime(time)
	self.nextBuyTime_ = time
end

function Midas:onRegister()
	Midas.super.onRegister(self)
	self:registerEvent(xyd.event.GET_MIDAS_INFO_2, handler(self, self.onMidasInfoNew))
	self:registerEvent(xyd.event.MIDAS_BUY_2, handler(self, self.onBuyNew))
end

function Midas:reqMidasInfoNew()
	local msg = messages_pb:get_midas_info_2_req()

	xyd.Backend.get():request(xyd.mid.GET_MIDAS_INFO_2, msg)
end

function Midas:buyNew(buyIndex)
	local msg = messages_pb:midas_buy_2_req()
	msg.buy_index = buyIndex

	xyd.Backend.get():request(xyd.mid.MIDAS_BUY_2, msg)
end

function Midas:onMidasInfoNew(event)
	self.buy_times = event.data.buy_times
	self.update_time = event.data.update_time
	self.is_free_award = event.data.is_free_award

	xyd.models.redMark:setMark(xyd.RedMarkType.MIDAS, self.is_free_award == 0)
	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.MIDAS, xyd.getTomorrowTime())
end

function Midas:onBuyNew(event)
	self.buy_times = event.data.buy_times
	self.update_time = event.data.update_time
	self.is_free_award = event.data.is_free_award

	xyd.models.redMark:setMark(xyd.RedMarkType.MIDAS, self.is_free_award == 0)
	xyd.models.deviceNotify:setNotifyTime(xyd.DEVICE_NOTIFY.MIDAS, xyd.getTomorrowTime())
end

return Midas
