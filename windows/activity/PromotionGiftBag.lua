local ActivityContent = import(".ActivityContent")
local PromotionGiftBag = class("PromotionGiftBag", ActivityContent)
local CountDown = import("app.components.CountDown")

function PromotionGiftBag:ctor(parentGo, params)
	PromotionGiftBag.super.ctor(self, parentGo, params)
end

function PromotionGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/promotion_gift_bag"
end

function PromotionGiftBag:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	xyd.setUITextureAsync(self.titleImg_, "Textures/activity_text_web/activity_christmas_giftbag_logo_" .. xyd.Global.lang)

	self.desLabel_.text = __("ACTIVITY_GERMANY_GIFTBAG_TEXT")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" then
		self.desLabel_.height = 76
		self.desLabel_.fontSize = 24

		self.desLabel_:Y(27)
	end

	if xyd.Global.lang == "fr_fr" then
		self.timeLabel_.color = Color.New2(2784231423.0)
		self.endLabel_.color = Color.New2(2684334079.0)
		self.timeLabel_.text = __("END")

		CountDown.new(self.endLabel_, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.endLabel_.text = __("END")

		CountDown.new(self.timeLabel_, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	end

	self:updateStatus()
	self:initItems()
	self:register()
end

function PromotionGiftBag:getUIComponent()
	local go = self.go
	self.bg = go:NodeByName("imgBg").gameObject
	self.titleImg_ = go:ComponentByName("titleImg_", typeof(UITexture))
	self.groupTime = go:NodeByName("titleImg_/groupTime").gameObject
	self.groupDes = go:NodeByName("groupDes").gameObject
	self.timeLabel_ = go:ComponentByName("titleImg_/groupTime/timeLabel_", typeof(UILabel))
	self.endLabel_ = go:ComponentByName("titleImg_/groupTime/endLabel_", typeof(UILabel))
	self.desLabel_ = go:ComponentByName("groupDes/desLabel_", typeof(UILabel))
	self.groupBottom0 = go:NodeByName("groupBottom0").gameObject
	self.purchaseBtn0 = go:NodeByName("groupBottom0/purchaseBtn0").gameObject
	self.purchaseBtnLabel0 = self.purchaseBtn0:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel0 = go:ComponentByName("groupBottom0/limitLabel0", typeof(UILabel))
	self.vipLabel0 = go:ComponentByName("groupBottom0/vipLabel0", typeof(UILabel))
	self.itemGroup0 = go:NodeByName("groupBottom0/itemGroup0").gameObject
	self.groupBottom1 = go:NodeByName("groupBottom1").gameObject
	self.purchaseBtn1 = go:NodeByName("groupBottom1/purchaseBtn1").gameObject
	self.purchaseBtnLabel1 = self.purchaseBtn1:ComponentByName("button_label", typeof(UILabel))
	self.limitLabel1 = go:ComponentByName("groupBottom1/limitLabel1", typeof(UILabel))
	self.vipLabel1 = go:ComponentByName("groupBottom1/vipLabel1", typeof(UILabel))
	self.itemGroup1 = go:NodeByName("groupBottom1/itemGroup1").gameObject
end

function PromotionGiftBag:initItems()
	local data = self.activityData

	for i = 1, #data.detail.charges do
		local awards = self:getAwards(data.detail.charges[i].table_id)
		local isFirst = true

		for j = 1, #awards do
			local award = awards[j]

			if award[1] ~= xyd.ItemID.VIP_EXP then
				local icon = xyd.getItemIcon({
					scale = 0.7,
					uiRoot = self["itemGroup" .. tostring(i - 1)],
					itemID = award[1],
					num = award[2]
				})
			end
		end
	end
end

function PromotionGiftBag:register()
	local data = self.activityData

	for i = 1, #data.detail.charges do
		local id = self.activityData.detail.charges[i].table_id

		UIEventListener.Get(self["purchaseBtn" .. tostring(i - 1)]).onClick = function ()
			xyd.SdkManager.get():showPayment(id)
		end

		self["purchaseBtnLabel" .. tostring(i - 1)].text = xyd.tables.giftBagTextTable:getCurrency(id) .. " " .. xyd.tables.giftBagTextTable:getCharge(id)
	end

	self:registerEvent(xyd.event.RECHARGE, function (evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		self:updateStatus()
	end, self)
end

function PromotionGiftBag:updateStatus()
	local activityData = self.activityData

	for i = 1, #activityData.detail.charges do
		local buyTimes = activityData.detail.charges[i].buy_times
		local limit = activityData.detail.charges[i].limit_times
		local tableId = activityData.detail.charges[i].table_id

		if limit <= buyTimes then
			xyd.applyGrey(self["purchaseBtn" .. tostring(i - 1)]:GetComponent(typeof(UISprite)))
			xyd.setTouchEnable(self["purchaseBtn" .. tostring(i - 1)], false)
			self["purchaseBtnLabel" .. tostring(i - 1)]:ApplyGrey()
		end

		self["vipLabel" .. tostring(i - 1)].text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(tableId)) .. " VIP EXP"
		self["limitLabel" .. tostring(i - 1)].text = __("BUY_GIFTBAG_LIMIT", tostring(limit - buyTimes))
	end
end

function PromotionGiftBag:getAwards(id)
	return xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(id))
end

function PromotionGiftBag:resizeToParent()
	PromotionGiftBag.super.resizeToParent(self)
	self:resizePosY(self.titleImg_, 12, -17)
	self:resizePosY(self.groupBottom0, -363, -465)
	self:resizePosY(self.groupBottom1, -702, -834)

	if xyd.Global.lang == "de_de" then
		self.groupTime:X(172)
	end
end

return PromotionGiftBag
