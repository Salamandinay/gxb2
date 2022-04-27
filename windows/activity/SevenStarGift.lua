local ActivityContent = import(".ActivityContent")
local SevenStarGift = class("SevenStarGift", ActivityContent)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable
local GiftTable = xyd.tables.giftTable
local GiftBagTextTable = xyd.tables.giftBagTextTable

function SevenStarGift:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function SevenStarGift:getPrefabPath()
	return "Prefabs/Components/seven_star_gift"
end

function SevenStarGift:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("e:Group/mainGroup")
	self.timeLabel = go:ComponentByName("e:Group/mainGroup/groupTime/timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("e:Group/mainGroup/groupTime/endLabel", typeof(UILabel))
	self.addExpLabel = go:ComponentByName("e:Group/mainGroup/addExpLabel", typeof(UILabel))
	self.limitLabel = go:ComponentByName("e:Group/mainGroup/limitLabel", typeof(UILabel))
	self.buyBtn = go:NodeByName("e:Group/mainGroup/buyBtn").gameObject
	self.button_label = go:ComponentByName("e:Group/mainGroup/buyBtn/button_label", typeof(UILabel))
	self.itemGroup = go:ComponentByName("e:Group/mainGroup/itemGroup", typeof(UILayout))
	self.imgText01 = go:ComponentByName("e:Group/mainGroup/imgText01", typeof(UITexture))
end

function SevenStarGift:initUIComponent()
	local ret_time = self:retTime()

	xyd.setUITextureAsync(self.imgText01, "Textures/activity_text_web/activity_seven_gift_" .. xyd.Global.lang)

	self.button_label.text = tostring(GiftBagTextTable:getCurrency(self.table_id)) .. " " .. tostring(GiftBagTextTable:getCharge(self.table_id))
	self.addExpLabel.text = "+ " .. tostring(self.vip_exp) .. " VIP EXP"
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.activityData.detail.buy_times)

	if ret_time > 0 and self.activityData.detail.buy_times < self.limit_times then
		UIEventListener.Get(self.buyBtn).onClick = function ()
			xyd.SdkManager.get():showPayment(self.table_id)
		end
	else
		self:setBtnState(false)
	end

	self.endLabel.text = __("TEXT_END")

	if ret_time > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = ret_time
		})
	else
		self.timeLabel:SetActive(false)
	end
end

function SevenStarGift:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()
	self:initData()
	self:initUIComponent()
	self:setIcon()
end

function SevenStarGift:initData()
	self.table_id = self.activityData.detail.table_id
	self.price = GiftBagTable:getPrice(self.table_id)
	self.vip_exp = GiftBagTable:getVipExp(self.table_id)
	self.limit_times = GiftBagTable:getBuyLimit(self.table_id)
end

function SevenStarGift:setIcon()
	local giftID = GiftBagTable:getGiftID(self.table_id)
	local awards = GiftTable:getAwards(giftID)
	local delta = 0

	for i = 1, #awards do
		local cur_data = awards[i]

		if cur_data[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				itemID = cur_data[1],
				num = cur_data[2],
				uiRoot = self.itemGroup.gameObject,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end
	end
end

function SevenStarGift:setBtnState(can)
	if not can then
		xyd.setEnabled(self.buyBtn, false)
		self.limitLabel:SetActive(false)
	end
end

function SevenStarGift:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	if self.limit_times <= self.activityData.detail.buy_times then
		self:setBtnState(false)
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.activityData.detail.buy_times)
end

function SevenStarGift:retTime()
	local cur_time = xyd.getServerTime()

	return self:getUpdateTime() - cur_time
end

function SevenStarGift:getUpdateTime()
	local detail, tableID = nil

	if self.activityData.detail and self.activityData.detail[self.type] then
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

	return updateTime + GiftBagTable:getLastTime(tableID)
end

return SevenStarGift
