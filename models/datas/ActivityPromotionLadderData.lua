local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityPromotionLadderData = class("ActivityPromotionLadderData", ActivityData, true)

function ActivityPromotionLadderData:getUpdateTime()
	return self:getEndTime()
end

function ActivityPromotionLadderData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_SLOT_INFO, handler(self, self.onSlot))
end

function ActivityPromotionLadderData:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_PROMOTION_LADDER then
		return
	end

	self.detail.times = self.detail.times + self.promoteTimes
	local detail = cjson.decode(data.detail)
	self.newPartnerInfo = {
		tableID = detail.replace_id,
		partnerID = detail.partner_id
	}
	local msg = messages_pb.get_slot_info_req()

	xyd.Backend.get():request(xyd.mid.GET_SLOT_INFO, msg)
end

function ActivityPromotionLadderData:onSlot()
	if self.newPartnerInfo then
		local newPartner = xyd.models.slot:getPartner(self.newPartnerInfo.partnerID)

		xyd.onGetNewPartnersOrSkins({
			partners = {
				newPartner:getTableID()
			},
			partnerDatas = {
				newPartner
			},
			callback = function ()
				local datas = {
					{
						noWays = true,
						item_num = 1,
						item_id = newPartner:getTableID(),
						star = newPartner:getStar(),
						lev = newPartner:getLevel()
					}
				}

				xyd.WindowManager.get():openWindow("alert_award_window", {
					items = datas
				})
			end
		})
	end

	self.newPartnerInfo = nil
end

function ActivityPromotionLadderData:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_PROMOTION_LADDER, function ()
		self.holdRed = false
	end)
end

function ActivityPromotionLadderData:getRedMarkState()
	if self.holdRed then
		return self.defRedMark
	end

	if not self:isFunctionOnOpen() then
		self.defRedMark = false
	elseif self:isFirstRedMark() then
		self.defRedMark = true
	else
		self.defRedMark = false
	end

	return self.defRedMark
end

function ActivityPromotionLadderData:recordPromoteTimes(times)
	self.promoteTimes = times
end

return ActivityPromotionLadderData
