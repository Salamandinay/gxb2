local cjson = require("cjson")
local ActivityData = import("app.models.ActivityData")
local ActivityPromotionLadder2Data = class("ActivityPromotionLadder2Data", ActivityData, true)

function ActivityPromotionLadder2Data:getUpdateTime()
	return self:getEndTime()
end

function ActivityPromotionLadder2Data:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxyOuter_:addEventListener(xyd.event.GET_SLOT_INFO, handler(self, self.onSlot))
end

function ActivityPromotionLadder2Data:onAward(data)
	if data.activity_id ~= xyd.ActivityID.ACTIVITY_PROMOTION_LADDER2 then
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

function ActivityPromotionLadder2Data:onSlot()
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
				local params = {
					items = {
						{
							noWays = true,
							item_num = 1,
							item_id = newPartner:getTableID(),
							star = newPartner:getStar(),
							lev = newPartner:getLevel()
						}
					}
				}

				function params.callback()
					if #self.originStarMaterial == 0 then
						return
					end

					local params = {
						items = self.originStarMaterial
					}

					dump(self.originStarMaterial)
					xyd.WindowManager.get():openWindow("alert_item_window", params)
				end

				xyd.WindowManager.get():openWindow("alert_award_window", params)
			end
		})
	end

	self.newPartnerInfo = nil
end

function ActivityPromotionLadder2Data:updateRedMark()
	self.holdRed = true

	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_PROMOTION_LADDER2, function ()
		self.holdRed = false
	end)
end

function ActivityPromotionLadder2Data:getRedMarkState()
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

function ActivityPromotionLadder2Data:recordPromoteTimes(times)
	self.promoteTimes = times
end

function ActivityPromotionLadder2Data:countOriginStarMaterial(partner)
	self.originStarMaterial = {}
	local info = partner:getDecompose()

	if info[1] then
		for item_id, item_num in pairs(info[1]) do
			if item_id == 359 or item_id == 360 then
				table.insert(self.originStarMaterial, {
					item_id = item_id,
					item_num = item_num
				})
			end
		end
	end
end

return ActivityPromotionLadder2Data
