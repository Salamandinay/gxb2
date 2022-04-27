local ActivityContent = import(".ActivityContent")
local LevelUpGiftBag = class("LevelUpGiftBag", ActivityContent)

function LevelUpGiftBag:ctor(params)
	ActivityContent.ctor(self, params)

	self.skinName = "LevelUpGiftBagSkin"

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	self.giftBagID = self.activityData.detail.charge.table_id
	self.currentState = xyd.Global.lang
end

function LevelUpGiftBag:euiComplete()
	ActivityContent.euiComplete(self)
	self:setBtnState(true)
	self:initBtn()
	self:setText()
	self:setIcon()

	local numLevel = GiftBagTable:get():getParams(self.giftBagID)

	self.numLevel:setInfo({
		iconName = "level_up_giftbag",
		num = numLevel[0]
	})
end

function LevelUpGiftBag:initBtn()
	self.buyBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.SdkManager:get():showPayment(self.giftBagID)
	end, self)

	if GiftBagTable:get():getBuyLimit(self.giftBagID) <= self.activityData.detail.charge.buy_times or self.activityData:getUpdateTime() <= xyd:getServerTime() then
		self:setBtnState(false)
	end
end

function LevelUpGiftBag:setText()
	if self.activityData:getUpdateTime() - xyd:getServerTime() > 0 then
		self.timeLabel:setCountDownTime(self.activityData:getUpdateTime() - xyd:getServerTime())
	else
		self.timeLabel.visible = false
	end

	self.buyBtn.label = tostring(GiftBagTextTable:get():getCurrency(self.giftBagID)) .. " " .. tostring(GiftBagTextTable:get():getCharge(self.giftBagID))
	self.addExpLabel.text = "+ " .. tostring(GiftBagTable:get():getVipExp(self.giftBagID)) .. " VIP EXP"
	local limit = GiftBagTable:get():getBuyLimit(self.giftBagID) - self.activityData.detail.charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)
	self.imgText01.source = "level_up_giftbag_text01_" .. tostring(xyd.Global.lang) .. "_png"
	self.groupText_.width = 337
end

function LevelUpGiftBag:setIcon()
	local giftID = GiftBagTable:get():getGiftID(self.giftBagID)
	local awards = GiftTable:get():getAwards(giftID)
	local i = 0

	while i < awards.length do
		local cur_data = awards[i]

		if cur_data[0] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				itemID = cur_data[0],
				num = cur_data[1],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}
			local icon = xyd:getItemIcon(item)
			icon.scaleX = self.itemGroup.height / icon.width
			icon.scaleY = self.itemGroup.height / icon.height

			self.itemGroup:addChild(icon)
		end

		i = i + 1
	end
end

function LevelUpGiftBag:setBtnState(can)
	if not can then
		xyd:applyGrey(self.buyBtn)

		self.limitLabel.visible = false
		self.buyBtn.touchEnabled = false
	end
end

function LevelUpGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if GiftBagTable:get():getActivityID(giftBagID) ~= self.id then
		return
	end

	local limit = GiftBagTable:get():getBuyLimit(self.giftBagID) - self.activityData.detail.charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)

	if GiftBagTable:get():getBuyLimit(self.giftBagID) <= self.activityData.detail.charge.buy_times then
		self:setBtnState(false)
	end
end

function LevelUpGiftBag:returnCommonScreen()
	ActivityContent.returnCommonScreen(self)

	local ____TS_obj = self.mainGroup
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 58
end

local ActivityContent = import(".ActivityContent")
local NewLevelUpGiftBag = class("NewLevelUpGiftBag", ActivityContent)

function NewLevelUpGiftBag:ctor(params)
	ActivityContent.ctor(self, params)

	self.skinName = "LevelUpGiftBagSkin"

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	self.giftBagID = self.activityData.detail[self.type].charge.table_id
	self.currentState = xyd.Global.lang
end

function NewLevelUpGiftBag:euiComplete()
	ActivityContent.euiComplete(self)
	self:setBtnState(true)
	self:initBtn()
	self:setText()
	self:setIcon()

	local numLevel = GiftBagTable:get():getParams(self.giftBagID)

	self.numLevel:setInfo({
		iconName = "level_up_giftbag",
		num = numLevel[0]
	})

	local delayFrame = FrameDelay.new()

	delayFrame:delayCall(2, function ()
		if xyd.Global.lang == "en_en" then
			if numLevel[0] >= 100 then
				self.numLevel.scaleX = function (o, i, v)
					o[i] = v

					return v
				end(self.numLevel, "scaleY", 0.7)
			end
		elseif xyd.Global.lang == "ja_jp" then
			if numLevel[0] >= 100 then
				self.numLevel.scaleX = function (o, i, v)
					o[i] = v

					return v
				end(self.numLevel, "scaleY", 0.7)
				self.numLevel.bottom = 0
			end
		elseif xyd.Global.lang == "fr_fr" and numLevel[0] >= 100 then
			self.groupText_.horizontalCenter = 90
		end
	end, self)
end

function NewLevelUpGiftBag:getUpdateTime()
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
		return detail.end_time
	end

	return updateTime + GiftBagTable:get():getLastTime(tableID)
end

function NewLevelUpGiftBag:initBtn()
	self.buyBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.SdkManager:get():showPayment(self.giftBagID)
	end, self)

	if GiftBagTable:get():getBuyLimit(self.giftBagID) <= self.activityData.detail[self.type].charge.buy_times or self:getUpdateTime() <= xyd:getServerTime() then
		self:setBtnState(false)
	end
end

function NewLevelUpGiftBag:setText()
	if self:getUpdateTime() - xyd:getServerTime() > 0 then
		self.timeLabel:setCountDownTime(self:getUpdateTime() - xyd:getServerTime())
	else
		self.timeLabel.visible = false
	end

	self.buyBtn.label = tostring(GiftBagTextTable:get():getCurrency(self.giftBagID)) .. " " .. tostring(GiftBagTextTable:get():getCharge(self.giftBagID))
	self.addExpLabel.text = "+ " .. tostring(GiftBagTable:get():getVipExp(self.giftBagID)) .. " VIP EXP"
	local limit = GiftBagTable:get():getBuyLimit(self.giftBagID) - self.activityData.detail[self.type].charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)
	self.imgText01.source = "level_up_giftbag_text01_" .. tostring(xyd.Global.lang) .. "_png"
end

function NewLevelUpGiftBag:setIcon()
	local giftID = GiftBagTable:get():getGiftID(self.giftBagID)
	local awards = GiftTable:get():getAwards(giftID)
	local i = 0

	while i < awards.length do
		local cur_data = awards[i]

		if cur_data[0] ~= xyd.ItemID.VIP_EXP then
			local item = {
				show_has_num = true,
				itemID = cur_data[0],
				num = cur_data[1],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}
			local icon = xyd:getItemIcon(item)
			icon.scaleX = self.itemGroup.height / icon.width
			icon.scaleY = self.itemGroup.height / icon.height

			self.itemGroup:addChild(icon)
		end

		i = i + 1
	end
end

function NewLevelUpGiftBag:setBtnState(can)
	if not can then
		xyd:applyGrey(self.buyBtn)

		self.limitLabel.visible = false
		self.buyBtn.touchEnabled = false
	end
end

function NewLevelUpGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if GiftBagTable:get():getActivityID(giftBagID) ~= self.id then
		return
	end

	local limit = GiftBagTable:get():getBuyLimit(self.giftBagID) - self.activityData.detail[self.type].charge.buy_times
	self.limitLabel.text = __(_G, "BUY_GIFTBAG_LIMIT", limit)

	if GiftBagTable:get():getBuyLimit(self.giftBagID) <= self.activityData.detail[self.type].charge.buy_times then
		self:setBtnState(false)
	end
end

function NewLevelUpGiftBag:returnCommonScreen()
	ActivityContent.returnCommonScreen(self)

	local ____TS_obj = self.mainGroup
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 58
end

return LevelUpGiftBag
