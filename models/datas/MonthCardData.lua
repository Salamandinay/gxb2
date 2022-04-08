local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local GiftBagData = import("app.models.datas.GiftBagData")
local MonthCardData = class("MonthCardData", GiftBagData, true)

function MonthCardData:ctor(params)
	GiftBagData.ctor(self, params)
end

function MonthCardData:getRedMarkState()
	local tableID_1 = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD):getGiftBagID()
	local tableID_2 = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD):getGiftBagID()
	local limitDiscountGiftbagID1 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)[1]
	local limitDiscountGiftbagID2 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)[1]

	if tableID_1 == limitDiscountGiftbagID1 or tableID_2 == limitDiscountGiftbagID2 then
		xyd.models.redMark:setMark(xyd.RedMarkType.LIMIT_DISCOUNT_MONTH_CARD, true)
	else
		xyd.models.redMark:setMark(xyd.RedMarkType.LIMIT_DISCOUNT_MONTH_CARD, false)
	end

	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	return false
end

function MonthCardData:onAward(event)
	local giftBagID = type(event) == "number" and event or event.data.giftbag_id

	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			if xyd.Global.lang == "ja_jp" then
				xyd.GiftbagPushController2.get():addTimeOut(function ()
					xyd.GiftbagPushController2.get():openMultiWindow({
						xyd.PopupType.MONTH_CARD,
						xyd.PopupType.FUNDATION,
						xyd.PopupType.SUBSCRIPTION
					})
				end)
			end

			local msg = messages_pb:get_activity_info_by_id_req()
			msg.activity_id = self.id

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

			break
		end
	end
end

function MonthCardData:getGiftBagID()
	if self.activity_id == xyd.ActivityID.MONTH_CARD then
		local retData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)

		if retData then
			local charges = retData.detail_.charges
			local giftID = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)[1]

			for _, giftInfo in ipairs(charges) do
				if giftInfo.table_id == giftID and giftInfo.buy_times == 0 then
					return giftID
				end
			end
		end
	end

	if self.detail_.charges[2] and tonumber(self.detail_.charges[2].buy_times) == 0 then
		return self.detail_.charges[2].table_id
	end

	return self.detail_.charges[1].table_id
end

function MonthCardData:getCheckData(choiseId)
	if choiseId then
		return xyd.models.activity:getActivity(choiseId)
	else
		return self
	end
end

function MonthCardData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

return MonthCardData
