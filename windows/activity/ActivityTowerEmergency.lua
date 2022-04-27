local ActivityContent = import(".ActivityContent")
local ActivityTowerEmergency = class("ActivityTowerEmergency", ActivityContent)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable

function ActivityTowerEmergency:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items = {}
	self.currentState = xyd.Global.lang
	self.table_id_ = self.activityData.detail[self.type].charge.table_id

	self:getUIComponent()
	self:myRegister()
	self:layout()
end

function ActivityTowerEmergency:getPrefabPath()
	return "Prefabs/Windows/activity/activity_tower_emergency"
end

function ActivityTowerEmergency:getUIComponent()
	local go = self.go
	self.titleImg = go:ComponentByName("titleImg", typeof(UISprite))
	self.timerLabel = go:ComponentByName("timeGroup/timerLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.purchaseGroup = go:NodeByName("purchaseGroup").gameObject
	self.purchaseBtn = self.purchaseGroup:ComponentByName("btn", typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseGroup:ComponentByName("btn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = self.purchaseGroup:ComponentByName("btn/label", typeof(UILabel))
	self.limitLabel = self.purchaseGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.purchaseGroup:ComponentByName("vipLabel", typeof(UILabel))
	self.itemGroup1 = self.purchaseGroup:NodeByName("itemGroup1").gameObject
	self.itemGroup2 = self.purchaseGroup:NodeByName("itemGroup2").gameObject
end

function ActivityTowerEmergency:layout()
	local awards = nil
	awards = xyd.tables.giftTable:getAwards(self.table_id_)

	for i = 1, #awards do
		if awards[i][1] ~= xyd.ItemID.VIP_EXP then
			local params = {
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2],
				uiRoot = self.itemGroup2
			}

			if awards[i][1] == xyd.ItemID.CRYSTAL and #awards % 2 == 0 then
				params.uiRoot = self.itemGroup1
			end

			local icon = xyd.getItemIcon(params)

			icon:setScale(0.9, 0.9, 0.9)
		end
	end

	if #awards - 1 == 5 then
		self.itemGroup2:Y(80)
	elseif #awards - 1 == 2 then
		self.itemGroup2:Y(80)
	elseif #awards - 1 == 6 then
		self.purchaseGroup:ComponentByName("bg", typeof(UITexture)).height = 576

		self.itemGroup1:Y(180)
		self.itemGroup2:Y(0)
		self.vipLabel:Y(-180)
		self.limitLabel:Y(-140)
		self.purchaseBtn:Y(-240)
	end

	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timerLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	xyd.setUISpriteAsync(self.titleImg, nil, "tower_emergency_text_" .. xyd.Global.lang, nil, , true)

	self.endLabel.text = __("TEXT_END")
	self.vipLabel.text = "+" .. tostring(GiftBagTable:getVipExp(self.table_id_)) .. " VIP EXP"
	self.purchaseBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.table_id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id_))
	local limit = GiftBagTable:getBuyLimit(self.table_id_)
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail[1].charge.buy_times))

	if limit <= self.activityData.detail[1].charge.buy_times then
		self:btnSetGrey()
	end
end

function ActivityTowerEmergency:myRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.table_id_)
	end)
end

function ActivityTowerEmergency:onRecharge(event)
	local giftbagId = event.data.giftbag_id
	local limit = GiftBagTable:getBuyLimit(giftbagId)

	if limit <= self.activityData.detail[1].charge.buy_times then
		self:btnSetGrey()
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.activityData.detail[1].charge.buy_times))
end

function ActivityTowerEmergency:btnSetGrey()
	xyd.applyGrey(self.purchaseBtn)
	xyd.setTouchEnable(self.purchaseBtn.gameObject, false)
end

return ActivityTowerEmergency
