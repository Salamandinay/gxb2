local json = require("cjson")
local ActivityData = import("app.models.ActivityData")
local PpivilegeCardData = class("PpivilegeCardData", ActivityData, true)

function PpivilegeCardData:ctor(params)
	ActivityData.ctor(self, params)
end

function PpivilegeCardData:register()
	self.eventProxyOuter_ = xyd.EventDispatcher.outer()

	self.eventProxyOuter_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityData))
end

function PpivilegeCardData:getRedMarkState()
	local limitDiscountRedState = false
	local discountGiftBagIDs = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_PRIVILEGE_CARD)

	for i = 1, #self.detail_.charges do
		for j = 1, #discountGiftBagIDs do
			if self.detail_.charges[i].table_id == discountGiftBagIDs[j] then
				limitDiscountRedState = true
			end
		end
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.LIMIT_DISCOUNT_PRIVILEGE_CARD, limitDiscountRedState)

	if not self:isFunctionOnOpen() then
		return false
	end

	if self:isFirstRedMark() then
		return true
	end

	if self:isHide() then
		return false
	end

	local pivilegeCardTemp_red = tonumber(xyd.db.misc:getValue("pivilegeCardTemp_red"))

	if pivilegeCardTemp_red == nil then
		return true
	else
		return false
	end

	return false
end

function PpivilegeCardData:onActivityData()
	local trialEnterWindow = xyd.WindowManager.get():getWindow("trial_enter_window")

	if trialEnterWindow then
		trialEnterWindow:updatePrivilegeCard()
	end

	local dungeonWindow = xyd.WindowManager.get():getWindow("dungeon_window")

	if dungeonWindow then
		dungeonWindow:updatePrivilegeCard()
	end

	local battleChooseWindow = xyd.WindowManager.get():getWindow("battle_choose_window")

	if battleChooseWindow then
		battleChooseWindow:updatePrivilegeSign()
	end
end

function PpivilegeCardData:onAward(event)
	local giftBagID = type(event) == "number" and event or event.data.giftbag_id

	for i = 1, #self.detail_.charges do
		if self.detail_.charges[i].table_id == giftBagID then
			local msg = messages_pb:get_activity_info_by_id_req()
			msg.activity_id = xyd.ActivityID.PRIVILEGE_CARD

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

			break
		end
	end
end

function PpivilegeCardData:getStateById(giftById)
	local datas = self.detail.charges

	for i in pairs(datas) do
		local serverTime = xyd.getServerTime()
		local timeDis = (datas[i].end_time or 0) - serverTime
		local countDays = 0

		if timeDis > 0 then
			countDays = math.ceil(timeDis / 86400)
		end

		if (datas[i].table_id == giftById or xyd.tables.giftBagTable:getParams(datas[i].table_id) and xyd.tables.giftBagTable:getParams(datas[i].table_id)[1] == giftById) and tonumber(countDays) > 0 then
			return true
		end
	end

	return false
end

function PpivilegeCardData:isHide()
	if not self:isFunctionOnOpen() then
		return true
	end

	local openStateIdArr = xyd.tables.miscTable:split2Cost("activity_privileged_card_function_open", "value", "|")

	for j in pairs(openStateIdArr) do
		if xyd.checkFunctionOpen(tonumber(openStateIdArr[j]), true) then
			return false
		end
	end

	return true
end

function PpivilegeCardData:isOpen()
	if not self:isFunctionOnOpen() then
		return false
	end

	return true
end

return PpivilegeCardData
