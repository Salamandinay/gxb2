local ActivityContent = import(".ActivityContent")
local SummonWelfare = class("SummonWelfare", ActivityContent)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable

function SummonWelfare:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}
	self.currentState = xyd.Global.lang
	self.table_id_ = self.activityData.detail.table_id

	self:getUIComponent()
	self:register()
	self:layout()
end

function SummonWelfare:getPrefabPath()
	return "Prefabs/Windows/activity/summon_welfare"
end

function SummonWelfare:getUIComponent()
	local go = self.go
	self.titleImg = go:ComponentByName("titleImg", typeof(UISprite))
	self.timerLabel = go:ComponentByName("timerLabel", typeof(UILabel))
	self.infoLabel = go:ComponentByName("infoLabel", typeof(UILabel))
	self.purchaseGroup = go:NodeByName("purchaseGroup").gameObject
	self.purchaseBtn = self.purchaseGroup:ComponentByName("btn", typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseGroup:ComponentByName("btn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = self.purchaseGroup:ComponentByName("btn/label", typeof(UILabel))
	self.limitLabel = self.purchaseGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.purchaseGroup:ComponentByName("vipLabel", typeof(UILabel))
	self.coinNum = self.purchaseGroup:ComponentByName("coinNum", typeof(UILabel))
end

function SummonWelfare:layout()
	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timerLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	xyd.setUISpriteAsync(self.titleImg, nil, "summon_welfare_text01_" .. xyd.Global.lang, nil, , true)

	self.infoLabel.text = __("ACTIVITY_PROPEL_GACHA")
	self.vipLabel.text = "+" .. tostring(GiftBagTable:getVipExp(self.table_id_)) .. " VIP EXP"
	self.coinNum.text = "x" .. tostring(xyd.tables.giftTable:getAwards(self.table_id_)[2][2])
	self.purchaseBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.table_id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id_))
	local limit = GiftBagTable:getBuyLimit(self.table_id_)
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail.buy_times))

	if limit <= self.activityData.detail.buy_times then
		self:btnSetGrey()
	end

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.go:Y(-(p_height - 867) / 2)

	if xyd.Global.lang == "en_en" then
		self.infoLabel:X(160)

		self.infoLabel.width = 380
	elseif xyd.Global.lang == "fr_fr" then
		self.titleImg:X(115)

		self.infoLabel.width = 320

		self.purchaseGroup:Y(-600)
	elseif xyd.Global.lang == "zh_tw" then
		self.titleImg:X(115)

		self.infoLabel.width = 280

		self.purchaseGroup:Y(-600)
	elseif xyd.Global.lang == "ja_jp" or xyd.Global.lang == "ko_kr" then
		self.infoLabel:X(140)

		self.infoLabel.width = 320

		self.purchaseGroup:Y(-600)
	elseif xyd.Global.lang == "de_de" then
		self.infoLabel:X(145)

		self.infoLabel.fontSize = 22
		self.infoLabel.spacingY = 3
	end
end

function SummonWelfare:register()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.table_id_)
	end)
end

function SummonWelfare:onRecharge(event)
	local giftbagId = event.data.giftbag_id
	local limit = GiftBagTable:getBuyLimit(giftbagId)

	if limit <= self.activityData.detail.buy_times then
		self:btnSetGrey()
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail.buy_times))
end

function SummonWelfare:btnSetGrey()
	xyd.applyGrey(self.purchaseBtn)
	xyd.setTouchEnable(self.purchaseBtn.gameObject, false)
end

return SummonWelfare
