local ActivityContent = import(".ActivityContent")
local GrowUpGiftBag = class("GrowUpGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")

function GrowUpGiftBag:ctor(parentGo, params)
	GrowUpGiftBag.super.ctor(self, parentGo, params)

	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)
end

function GrowUpGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/grow_up_gift_bag"
end

function GrowUpGiftBag:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("imgBg").gameObject
	self.titleImg_ = go:ComponentByName("titleImg_", typeof(UITexture))
	self.groupTime = go:NodeByName("groupTime").gameObject
	self.timeLabel_ = go:ComponentByName("groupTime/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("groupTime/endLabel_", typeof(UILabel))
	self.groupBottom0 = go:NodeByName("groupBottom0").gameObject
	self.purchaseBtn0 = go:NodeByName("groupBottom0/purchaseBtn0").gameObject
	self.purchaseBtnLabel0 = self.purchaseBtn0:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel0 = go:ComponentByName("groupBottom0/limitLabel0", typeof(UILabel))
	self.vipLabel0 = go:ComponentByName("groupBottom0/vipLabel0", typeof(UILabel))
	self.itemGroup0 = go:NodeByName("groupBottom0/itemGroup0").gameObject
end

function GrowUpGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	xyd.setUITextureByNameAsync(self.titleImg_, "grow_up_giftbag_text01_" .. xyd.Global.lang, true)

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel_, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	self.endLabel_.text = __("END")

	dump(self.activityData)
	self:updateStatus()
	self:initItems()
	self:register()
end

function GrowUpGiftBag:initItems()
	local data = self.activityData
	local awards = self:getAwards(data.detail.charge.table_id)
	local isFirst = true

	for j = 1, #awards do
		local award = awards[j]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local icon = xyd.getItemIcon({
				scale = 1,
				uiRoot = self.itemGroup0,
				itemID = award[1],
				num = award[2]
			})
		end
	end
end

function GrowUpGiftBag:register()
	local data = self.activityData
	local id = data.detail.charge.table_id

	UIEventListener.Get(self.purchaseBtn0).onClick = function ()
		xyd.SdkManager.get():showPayment(id)
	end

	self.purchaseBtnLabel0.text = xyd.tables.giftBagTextTable:getCurrency(id) .. " " .. xyd.tables.giftBagTextTable:getCharge(id)

	self:registerEvent(xyd.event.RECHARGE, function (evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		self:updateStatus()
	end, self)
end

function GrowUpGiftBag:updateStatus()
	local activityData = self.activityData
	local buyTimes = activityData.detail.charge.buy_times
	local tableId = activityData.detail.charge.table_id
	local limit = xyd.tables.giftBagTable:getBuyLimit(tableId)

	if limit <= buyTimes then
		xyd.applyChildrenGrey(self.purchaseBtn0)
		xyd.setTouchEnable(self.purchaseBtn0, false)
	end

	self.vipLabel0.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(tableId)) .. " VIP EXP"
	self.limitLabel0.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - buyTimes))
end

function GrowUpGiftBag:getAwards(id)
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(id))
end

function GrowUpGiftBag:resizeToParent()
	GrowUpGiftBag.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height

	self.bg:Y(-0.4663 * allHeight + 488)

	if xyd.Global.lang == "de_de" then
		self.endLabel_.fontSize = 20
		self.timeLabel_.fontSize = 20
	end
end

return GrowUpGiftBag
