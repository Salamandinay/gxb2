local ActivityContent = import(".ActivityContent")
local StageGiftBag = class("StageGiftBag", ActivityContent)

function StageGiftBag:ctor(params)
	ActivityContent.ctor(self, params)

	self.giftbag_id = ActivityTable:get():getGiftBag(self.id)[0]
	self.limit = GiftBagTable:get():getBuyLimit(self.giftbag_id)
	self.gift_id = GiftBagTable:get():getGiftID(self.giftbag_id)
	self.award = GiftTable:get():getAwards(self.gift_id)
	self.vip = GiftBagTable:get():getVipExp(self.giftbag_id)
	self.skinName = "StageGiftBagSkin"
	self.currentState = xyd.Global.lang
end

function StageGiftBag:euiComplete()
	ActivityContent.euiComplete(self)

	local end_time = self.activityData:getUpdateTime()
	local cur_time = xyd:getServerTime()

	if end_time <= cur_time then
		self.timeLabel.visible = false
	else
		self.timeLabel:setCountDownTime(end_time - cur_time)
	end

	self.textImg.source = "stage_giftbag_text01_" .. tostring(xyd.Global.lang:toLowerCase()) .. "_png"

	self:setText()
	self:setItems()
	self.purchaseBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.SdkManager:get():showPayment(self.activityData.detail.charge.table_id)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	if self.limit <= self.activityData.detail.charge.buy_times or self.activityData:getUpdateTime() <= xyd:getServerTime() then
		self:setBtnState(false)
	else
		self:setBtnState(true)
	end
end

function StageGiftBag:setBtnState(flag)
	if not flag then
		xyd:applyGrey(self.purchaseBtn)

		self.limitLabel.visible = false
		self.purchaseBtn.touchEnabled = false
	end
end

function StageGiftBag:setText()
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", self.limit)
	self.vipLabel.text = "+ " .. tostring(self.vip) .. " VIP EXP"
	self.purchaseBtn.label = tostring(GiftBagTextTable:get():getCurrency(self.activityData.detail.charge.table_id)) .. " " .. tostring(GiftBagTextTable:get():getCharge(self.activityData.detail.charge.table_id))
end

function StageGiftBag:setItems()
	local award = self.award
	local itemGroup = self.itemGroup
	local i = 0
	local length = award.length

	while i < length do
		local data = award[i]

		if data[0] ~= xyd.ItemID.VIP_EXP then
			local item = xyd:getItemIcon({
				show_has_num = true,
				itemID = data[0],
				num = data[1],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
			item.scaleX = 0.8981481481481481
			item.scaleY = 0.8981481481481481

			itemGroup:addChild(item)
		end

		i = i + 1
	end
end

function StageGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if GiftBagTable:get():getActivityID(giftBagID) ~= self.id then
		return
	end

	local limit = GiftBagTable:get():getBuyLimit(self.activityData.detail.charge.table_id) - self.activityData.detail.charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)

	if GiftBagTable:get():getBuyLimit(self.activityData.detail.charge.table_id) <= self.activityData.detail.charge.buy_times then
		self:setBtnState(false)
	end
end

function StageGiftBag:returnCommonScreen()
	ActivityContent.returnCommonScreen(self)

	local ____TS_obj = self.contentGroup
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 115
end

local ActivityContent = import(".ActivityContent")
local NewStageGiftBag = class("NewStageGiftBag", ActivityContent)

function NewStageGiftBag:ctor(params)
	ActivityContent.ctor(self, params)

	self.skinName = "NewStageGiftBagSkin"
	self.currentState = xyd.Global.lang
end

function NewStageGiftBag:euiComplete()
	ActivityContent.euiComplete(self)

	local end_time = self:getUpdateTime()
	local cur_time = xyd:getServerTime()
	local id = self.activityData.detail[self.type].charge.table_id
	local limit = GiftBagTable:get():getBuyLimit(id)

	if end_time <= cur_time then
		self.timeLabel.visible = false
	else
		self.timeLabel:setCountDownTime(end_time - cur_time)
	end

	self:setText()
	self:setItems()
	self.purchaseBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.SdkManager:get():showPayment(self.activityData.detail[self.type].charge.table_id)
	end, self)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	if limit <= self.activityData.detail[self.type].charge.buy_times or self:getUpdateTime() <= xyd:getServerTime() then
		self:setBtnState(false)
	else
		self:setBtnState(true)
	end
end

function NewStageGiftBag:getUpdateTime()
	local detail, tableID = nil

	if Array:isArray(self.activityData.detail) then
		detail = self.activityData.detail[self.type]
		tableID = self.activityData.detail[self.type].charge.table_id
	else
		detail = self.activityData.detail
		tableID = self.activityData.detail.table_id
	end

	local updateTime = nil

	if detail.update_time then
		updateTime = detail.update_time
	else
		updateTime = 0
	end

	if not updateTime then
		return detail.charge.end_time
	end

	return updateTime + GiftBagTable:get():getLastTime(tableID)
end

function NewStageGiftBag:setBtnState(flag)
	if not flag then
		xyd:applyGrey(self.purchaseBtn)

		self.limitLabel.visible = false
		self.purchaseBtn.touchEnabled = false
	end
end

function NewStageGiftBag:setText()
	local id = self.activityData.detail[self.type].charge.table_id
	local limit = GiftBagTable:get():getBuyLimit(id)
	local vip = GiftBagTable:get():getVipExp(id)
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)
	self.vipLabel.text = "+ " .. tostring(vip) .. " VIP EXP"
	self.endLabel.text = __(_G, "TEXT_END")
	self.purchaseBtn.label = tostring(GiftBagTextTable:get():getCurrency(self.activityData.detail[self.type].charge.table_id)) .. " " .. tostring(GiftBagTextTable:get():getCharge(self.activityData.detail[self.type].charge.table_id))
end

function NewStageGiftBag:setItems()
	local id = self.activityData.detail[self.type].charge.table_id
	local award = GiftTable:get():getAwards(id)
	local itemGroup = self.itemGroup
	local i = 0
	local length = award.length

	while i < length do
		local data = award[i]

		if data[0] ~= xyd.ItemID.VIP_EXP then
			local item = xyd:getItemIcon({
				show_has_num = true,
				itemID = data[0],
				num = data[1],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
			item.scaleX = 0.8981481481481481
			item.scaleY = 0.8981481481481481

			itemGroup:addChild(item)
		end

		i = i + 1
	end
end

function NewStageGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if GiftBagTable:get():getActivityID(giftBagID) ~= self.id then
		return
	end

	local limit = GiftBagTable:get():getBuyLimit(self.activityData.detail[self.type].charge.table_id) - self.activityData.detail[self.type].charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)

	if GiftBagTable:get():getBuyLimit(self.activityData.detail[self.type].charge.table_id) <= self.activityData.detail[self.type].charge.buy_times then
		self:setBtnState(false)
	end
end

function NewStageGiftBag:returnCommonScreen()
	ActivityContent.returnCommonScreen(self)

	local ____TS_obj = self.contentGroup
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 49 * self.scale_num_
end

return StageGiftBag
