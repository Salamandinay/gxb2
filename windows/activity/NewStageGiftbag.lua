local ActivityContent = import(".ActivityContent")
local NewStageGiftBagData = class("NewStageGiftBagData", ActivityContent)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable

function NewStageGiftBagData:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}
	self.currentState = xyd.Global.lang
	self.table_id_ = self.activityData.detail[self.type].charge.table_id

	self:getUIComponent()
	self:myRegister()
	self:layout()
end

function NewStageGiftBagData:getPrefabPath()
	return "Prefabs/Windows/activity/new_stage_gift_bag"
end

function NewStageGiftBagData:getUIComponent()
	local go = self.go
	self.titleImg = go:ComponentByName("titleImg", typeof(UITexture))
	self.timerLabel = go:ComponentByName("timerLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("endLabel", typeof(UILabel))
	self.purchaseGroup = go:NodeByName("purchaseGroup").gameObject
	self.purchaseBtn = self.purchaseGroup:ComponentByName("btn", typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseGroup:ComponentByName("btn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = self.purchaseGroup:ComponentByName("btn/label", typeof(UILabel))
	self.limitLabel = self.purchaseGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.purchaseGroup:ComponentByName("vipLabel", typeof(UILabel))
	self.itemGroup = self.purchaseGroup:NodeByName("itemGroup").gameObject
end

function NewStageGiftBagData:layout()
	local awards = nil
	awards = xyd.tables.giftTable:getAwards(self.table_id_)

	for i = 1, #awards do
		if awards[i][1] ~= xyd.ItemID.VIP_EXP then
			local params = {
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2],
				uiRoot = self.itemGroup
			}
			local icon = xyd.getItemIcon(params)

			icon:setScale(0.9, 0.9, 0.9)
		end
	end

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timerLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	xyd.setUITextureByNameAsync(self.titleImg, "new_stage_giftbag_text01_" .. xyd.Global.lang, true)

	self.endLabel.text = __("TEXT_END")
	self.vipLabel.text = "+" .. tostring(GiftBagTable:getVipExp(self.table_id_)) .. " VIP EXP"
	self.purchaseBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.table_id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id_))
	local limit = GiftBagTable:getBuyLimit(self.table_id_)
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail[1].charge.buy_times))

	if limit <= self.activityData.detail[1].charge.buy_times then
		self:btnSetGrey()
	end

	if xyd.Global.lang == "de_de" then
		self.timerLabel:X(105)
	end

	if xyd.Global.lang == "fr_fr" then
		self.timerLabel:X(145)
	end

	if xyd.Global.lang == "ko_kr" then
		self.timerLabel:X(170)
	end

	if xyd.Global.lang == "ja_jp" then
		self.titleImg:Y(-435)
	end
end

function NewStageGiftBagData:myRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.table_id_)
	end)
end

function NewStageGiftBagData:onRecharge(event)
	local giftbagId = event.data.giftbag_id
	local limit = GiftBagTable:getBuyLimit(giftbagId)

	if limit <= self.activityData.detail[1].charge.buy_times then
		self:btnSetGrey()
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail[1].charge.buy_times))
end

function NewStageGiftBagData:btnSetGrey()
	xyd.applyGrey(self.purchaseBtn)
	xyd.setTouchEnable(self.purchaseBtn.gameObject, false)
end

return NewStageGiftBagData
