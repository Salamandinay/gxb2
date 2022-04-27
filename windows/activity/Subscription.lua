local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local Subscription = class("Subscription", ActivityContent)

function Subscription:ctor(parentGO, params)
	Subscription.super.ctor(self, parentGO, params)

	self.displayType = self.activityData:displayType()

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	self.currentState = xyd.Global.lang

	self:getUIComponent()
	self:euiComplete()
end

function Subscription:getPrefabPath()
	if self.activityData:displayType() == xyd.ActivityID.MANA_WEEK_CARD then
		self.skinName = "ManaWeekCardSkin"
	elseif self.activityData:displayType() == xyd.ActivityID.SUBSCRIPTION then
		return "Prefabs/Windows/activity/subscription_pre"
	else
		self.skinName = "ManaSubscriptionSkin"
	end
end

function Subscription:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.allGroup = go:NodeByName("allGroup").gameObject
	self.allGroup_uiwidget = go:ComponentByName("allGroup", typeof(UIWidget))
	self.imgText02 = go:ComponentByName("imgText02", typeof(UISprite))
	self.imgText05 = go:ComponentByName("imgText05", typeof(UISprite))
	self.imgText01 = go:ComponentByName("imgText01", typeof(UITexture))
	self.imgText04 = go:ComponentByName("imgText04", typeof(UISprite))
	self.imgText03 = go:ComponentByName("imgText03", typeof(UITexture))
	self.labelText2 = self.allGroup:ComponentByName("labelText4/labelText2", typeof(UILabel))
	self.labelText3 = self.allGroup:ComponentByName("labelText5/labelText3", typeof(UILabel))
	self.labelText4 = self.allGroup:ComponentByName("labelText4", typeof(UILabel))
	self.labelText4_uiwidget = self.allGroup:ComponentByName("labelText4", typeof(UIWidget))
	self.labelText5 = self.allGroup:ComponentByName("labelText5", typeof(UILabel))
	self.labelText5_uiwidget = self.allGroup:ComponentByName("labelText5", typeof(UIWidget))
	self.labelText2_posSize = self.allGroup:ComponentByName("labelText2_posSize", typeof(UILabel))
	self.labelText2_posSize_uiwidget = self.allGroup:ComponentByName("labelText2_posSize", typeof(UIWidget))
	self.labelText3_posSize = self.allGroup:ComponentByName("labelText3_posSize", typeof(UILabel))
	self.labelText3_posSize_uiwidget = self.allGroup:ComponentByName("labelText3_posSize", typeof(UIWidget))
	self.helpBtn = go:ComponentByName("helpBtn", typeof(UISprite))
	self.downGroup = self.allGroup:NodeByName("downGroup").gameObject
	self.downGroupBg = self.downGroup:ComponentByName("downGroupBg", typeof(UISprite))
	self.labelQuarterExp = self.downGroup:ComponentByName("labelQuarterExp", typeof(UILabel))
	self.btnQuarter = self.downGroup:ComponentByName("btnQuarter", typeof(UISprite))
	self.btnQuarter_imgPurchased = self.btnQuarter:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnQuarter_button_label = self.btnQuarter:ComponentByName("button_label", typeof(UILabel))
	self.btnQuarter_boxCollider = self.btnQuarter:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnRecover = self.downGroup:ComponentByName("btnRecover", typeof(UISprite))
	self.btnRecover_imgPurchased = self.btnRecover:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnRecover_button_label = self.btnRecover:ComponentByName("button_label", typeof(UILabel))
	self.btnRecover_boxCollider = self.btnRecover:GetComponent(typeof(UnityEngine.BoxCollider))
	self.labelMonthExp = self.downGroup:ComponentByName("labelMonthExp", typeof(UILabel))
	self.btnMonth = self.downGroup:ComponentByName("btnMonth", typeof(UISprite))
	self.btnMonth_imgPurchased = self.btnMonth:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnMonth_button_label = self.btnMonth:ComponentByName("button_label", typeof(UILabel))
	self.btnMonth_boxCollider = self.btnMonth:GetComponent(typeof(UnityEngine.BoxCollider))
	self.labelWeekExp = self.downGroup:ComponentByName("labelWeekExp", typeof(UILabel))
	self.btnWeek = self.downGroup:ComponentByName("btnWeek", typeof(UISprite))
	self.btnWeek_imgPurchased = self.btnWeek:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnWeek_button_label = self.btnWeek:ComponentByName("button_label", typeof(UILabel))
	self.btnWeek_boxCollider = self.btnWeek:GetComponent(typeof(UnityEngine.BoxCollider))
	self.groupLeft = self.downGroup:NodeByName("groupLeft").gameObject
	self.labelText6 = self.groupLeft:ComponentByName("e:Group/labelText6", typeof(UILabel))
	self.labelText6_uiwidgt = self.groupLeft:ComponentByName("e:Group/labelText6", typeof(UIWidget))
	self.daysLabel = self.groupLeft:ComponentByName("e:Group/labelText6/daysLabel", typeof(UILabel))
	self.daysLabel_uiwidgt = self.groupLeft:ComponentByName("e:Group/labelText6/daysLabel", typeof(UIWidget))
	self.daysLabelPosSize = self.groupLeft:ComponentByName("e:Group/daysLabelPosSize", typeof(UILabel))
	self.daysLabelPosSize_uiwidgt = self.groupLeft:ComponentByName("e:Group/daysLabelPosSize", typeof(UIWidget))
	self.scroller = self.downGroup:NodeByName("scroller").gameObject
	self.scroller_uiPanel = self.downGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scroller_uiPanel.depth = self.scroller_uiPanel.depth + 1
	self.labelText1 = self.scroller:ComponentByName("e:Group/labelText1", typeof(UILabel))
	self.labelText7 = self.downGroup:ComponentByName("labelText7", typeof(UILabel))
	self.maskRect = go:NodeByName("maskRect").gameObject
end

function Subscription:euiComplete()
	local height = xyd.Global.getRealHeight()

	if height >= 1559 then
		height = 1559
	end

	local scale = (1559 - height) / 279

	self.imgText01:SetLocalPosition(110, -448 + 147 * scale, 0)
	self.imgText02:SetLocalPosition(349, -406 + 147 * scale, 0)
	self.imgText03:SetLocalPosition(120, -523 + 167 * scale, 0)
	self.imgText04:SetLocalPosition(124, -527 + 167 * scale, 0)

	if self.imgText05 then
		self.imgText05:SetLocalPosition(153, -203 + 78 * scale, 0)
	end

	if self.helpBtn then
		self.helpBtn:SetLocalPosition(305, -392 + 147 * scale, 0)
	end

	self:setText()
	self:setBtnState()
	self:solveMultiLang()
	self:listenEvent()
end

function Subscription:setText()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:setTextManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:setTextSub()
	else
		self:setTextManaSub()
	end
end

function Subscription:setTextSub()
	local WeekGiftBagID = xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION
	local MonthGiftBagID = xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION
	local QuarterGiftBagID = xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION
	local res_prefix = "Textures/activity_text_web/"

	xyd.setUITextureByNameAsync(self.imgText01, "mana_week_card_text02_" .. xyd.Global.lang, true)
	xyd.setUITextureByNameAsync(self.imgText03, "mana_week_card_text03_" .. xyd.Global.lang, true)

	local res_prefix_bg = "Textures/scenes_web/"

	xyd.setUITextureAsync(self.imgBg, res_prefix_bg .. "mana_week_card_bg03")

	if xyd.Global.lang == "en_en" then
		self.imgText01:X(100)
		self.imgText03:X(100)
	elseif xyd.Global.lang == "fr_fr" then
		self.imgText01:X(-28)
		self.imgText03:X(25)

		if self.activityData:displayType() == xyd.ActivityID.SUBSCRIPTION then
			self.imgText01:X(-18)
			self.imgText03:X(93)
			self.imgText03.transform:SetLocalScale(0.8, 0.8, 0.8)
		end
	elseif xyd.Global.lang == "ja_jp" then
		self.imgText01:X(100)
		self.imgText03:X(100)
	elseif xyd.Global.lang == "de_de" then
		self.imgText01:X(80)
		self.imgText03:X(100)
	end

	self.labelText4.text = __("TERMS_SERVICE")
	self.labelText5.text = __("PRIVACY_POLICY")
	self.labelText7.text = __("SUBSCRIPTION_CANCEL_TIP")
	self.labelWeekExp.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(WeekGiftBagID)) .. " VIP EXP"
	self.labelMonthExp.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(MonthGiftBagID)) .. " VIP EXP"
	self.labelQuarterExp.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(QuarterGiftBagID)) .. " VIP EXP"
	self.btnWeek_button_label.text = __("WEEK_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(WeekGiftBagID), xyd.tables.giftBagTextTable:getCharge(WeekGiftBagID))
	self.btnMonth_button_label.text = __("MONTH_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(MonthGiftBagID), xyd.tables.giftBagTextTable:getCharge(MonthGiftBagID))
	self.btnQuarter_button_label.text = __("QUARTER_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(QuarterGiftBagID), xyd.tables.giftBagTextTable:getCharge(QuarterGiftBagID))

	if xyd.Global.isReview ~= 0 then
		self.btnRecover_button_label.text = __("SUBSCRIPTION_RECOVER")
		UIEventListener.Get(self.btnRecover.gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("SUBSCRIPTION_RECOVER_CONFIRM")
			})
		end)

		self.btnRecover:SetActive(true)
	end

	local serviceUrlKey = "TERMS_SERVICE_URL"
	local policyUrlKey = "PRIVACY_POLICY_URL"

	if UNITY_IOS and not xyd.isH5() then
		serviceUrlKey = serviceUrlKey .. "_UNITY_IOS"
		policyUrlKey = policyUrlKey .. "_UNITY_IOS"
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelText2.text = xyd.getUnderlineText(__("FRANCE_TAP_TO_GO"))
		self.labelText3.text = xyd.getUnderlineText(__("FRANCE_TAP_TO_GO"))
	else
		self.labelText2.text = xyd.getUnderlineText(__(serviceUrlKey))
		self.labelText3.text = xyd.getUnderlineText(__(policyUrlKey))
	end

	UIEventListener.Get(self.labelText2.gameObject).onClick = handler(self, function ()
		UnityEngine.Application.OpenURL(__(serviceUrlKey))
	end)
	UIEventListener.Get(self.labelText3.gameObject).onClick = handler(self, function ()
		UnityEngine.Application.OpenURL(__(policyUrlKey))
	end)
	self.labelText6.text = __("RET_TIME_TEXT")

	if UNITY_IOS then
		self.labelText1.text = __("SUBSCRIPTION_TEXT01_IOS")
	else
		self.labelText1.text = __("SUBSCRIPTION_TEXT01_AND")
	end

	self:changeURLLabelPos()
end

function Subscription:setTextManaSub()
	local giftBagID = xyd.GIFTBAG_ID.MANA_SUBSCRIPTION
	self.imgText01.source = "mana_week_card_text02_" .. tostring(xyd.Global.lang) .. "_png"
	self.imgText03.source = "mana_week_card_text03_" .. tostring(xyd.Global.lang) .. "_png"
	self.labelText1.text = __("MANA_WEEK_CARD_TEXT01_IOS")
	self.labelText4.text = __("TERMS_SERVICE")
	self.labelText5.text = __("PRIVACY_POLICY")
	self.btnPurchase.label = tostring(__("WEEKCARD_BTN_LABEL")) .. " " .. tostring(xyd.tabels.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
	local serviceUrlKey = "TERMS_SERVICE_URL"
	local policyUrlKey = "PRIVACY_POLICY_URL"

	if UNITY_IOS and not xyd.isH5() then
		serviceUrlKey = serviceUrlKey .. "_UNITY_IOS"
		policyUrlKey = policyUrlKey .. "_UNITY_IOS"
	end

	self.labelText2.text = xyd.getUnderlineText(__(serviceUrlKey))
	self.labelText3.text = xyd.getUnderlineText(__(policyUrlKey))
	self.labelText6.text = __("RET_TIME_TEXT")

	self:changeURLLabelPos()
end

function Subscription:setTextManaCard()
	self.imgText01.source = "mana_week_card_text02_" .. tostring(xyd.Global.lang) .. "_png"
	self.imgText03.source = "mana_week_card_text03_" .. tostring(xyd.Global.lang) .. "_png"
	self.labelText1.text = __("MANA_WEEK_CARD_TEXT01")
	self.retLabel.text = __("RET_TIME_TEXT")
	local giftBagID = xyd.GIFTBAG_ID.MANA_WEEK_CARD
	self.labelPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
end

function Subscription:calRetTimeManaSub()
	local endTime = self.activityData.detail.end_time
	local time = endTime - xyd:getServerTime()
	self.labelText6.visible = time > 0
	self.daysLabel.visible = time > 0

	if time <= 0 then
		return
	end

	local day = math.floor(time / 86400)
	local hour = math.floor(time % 86400 / 3600)

	if day > 0 and hour > 0 then
		self.daysLabel.text = __("DAY_HOUR", day, hour)
	elseif day > 0 then
		self.daysLabel.text = __("DAY", day)
	elseif hour > 0 then
		self.daysLabel.text = __("HOUR", hour)
	end

	self:changeDayLabelPos()
end

function Subscription:calRetTimeManaCard()
	local endTime = self.activityData.detail.end_time
	local time = endTime - xyd:getServerTime()
	self.groupLeft.visible = time > 0

	if time <= 0 then
		return
	end

	local day = math.floor(time / 86400)
	local hour = math.floor(time % 86400 / 3600)

	if day > 0 and hour > 0 then
		self.daysLabel.text = __("DAY_HOUR", day, hour)
	elseif day > 0 then
		self.daysLabel.text = __("DAY", day)
	elseif hour > 0 then
		self.daysLabel.text = __("HOUR", hour)
	end

	self:changeDayLabelPos()
end

function Subscription:calRetTimeSub()
	local endTime = self.activityData.detail.end_time
	local time = endTime - xyd.getServerTime()

	self.labelText6:SetActive(time > 0)
	self.daysLabel:SetActive(time > 0)
	self.groupLeft:SetActive(time > 0)

	local data = self.activityData.detail

	if time > 0 then
		if data.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION or data.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND or data.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_FREE or data.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND_FREE then
			self.groupLeft:SetLocalPosition(223, -161, 0)
		elseif data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_FREE or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND_FREE then
			self.groupLeft:SetLocalPosition(18, -161, 0)
		elseif data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_FREE or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND_FREE then
			self.groupLeft:SetLocalPosition(-185, -161, 0)
		else
			self.groupLeft:SetLocalPosition(223, -161, 0)
		end
	end

	if time <= 0 then
		return
	end

	local day = math.floor(time / 86400)
	local hour = math.floor(time % 86400 / 3600)

	if day > 0 and hour > 0 then
		self.daysLabel.text = __("DAY_HOUR", day, hour)
	elseif day > 0 then
		self.daysLabel.text = __("DAY", day)
	elseif hour > 0 then
		self.daysLabel.text = __("HOUR", hour)
	end

	self:changeDayLabelPos()
end

function Subscription:setBtnState()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:setBtnStateManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:setBtnStateSub()
	else
		self:setBtnStateManaSub()
	end
end

function Subscription:setBtnStateSub()
	local data = self.activityData.detail

	self.btnWeek_imgPurchased:SetActive(false)
	self.btnMonth_imgPurchased:SetActive(false)
	self.btnQuarter_imgPurchased:SetActive(false)

	self.btnWeek_boxCollider.enabled = true
	self.btnMonth_boxCollider.enabled = true
	self.btnQuarter_boxCollider.enabled = true

	xyd.setUISpriteAsync(self.btnWeek, nil, "mana_week_card_btn01", nil, )

	if xyd.getServerTime() < data.end_time then
		if data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_FREE or data.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND_FREE then
			self.btnMonth_boxCollider.enabled = false

			self.btnMonth_imgPurchased:SetActive(true)
		elseif data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_FREE or data.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND_FREE then
			self.btnQuarter_boxCollider.enabled = false

			self.btnQuarter_imgPurchased:SetActive(true)
		else
			self.btnWeek_boxCollider.enabled = false

			self.btnWeek_imgPurchased:SetActive(true)
		end
	end

	if not UNITY_IOS then
		local isFree = self.activityData.detail.is_use_free <= 0 and data.end_time < xyd:getServerTime()
		local WeekGiftBagID = xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION
		local priceText = __("WEEK_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(WeekGiftBagID), xyd.tables.giftBagTextTable:getCharge(WeekGiftBagID))
		local freeText = __("WEEK_SUBSCRIPTION_FREE_BTN_LABEL")

		if isFree == true then
			xyd.setUISpriteAsync(self.btnWeek, nil, "green_btn_192_67", nil, )

			self.btnWeek_button_label.color = Color.New2(4294967295.0)
			self.btnWeek_button_label.effectColor = Color.New2(560209151)
			self.btnWeek_button_label.text = freeText

			self.labelWeekExp:SetActive(false)
		else
			xyd.setUISpriteAsync(self.btnWeek, nil, "mana_week_card_btn01", nil, )

			self.btnWeek_button_label.color = Color.New2(3224980479.0)
			self.btnWeek_button_label.effectColor = Color.New2(4294967295.0)
			self.btnWeek_button_label.text = priceText

			self.labelWeekExp:SetActive(true)
		end
	end

	self:calRetTimeSub()
end

function Subscription:setBtnStateManaCard()
	self.btnPurchase.label = __("BUY")
	local data = self.activityData.detail

	if xyd:getServerTime() < data.end_time then
		xyd:applyGrey(self.btnPurchase)
		self.btnPurchase:setTouchEnabled(false)
	else
		xyd:applyOrigin(self.btnPurchase)
		self.btnPurchase:setTouchEnabled(true)
	end

	self:calRetTimeManaCard()
end

function Subscription:setBtnStateManaSub()
	local data = self.activityData.detail

	if xyd:getServerTime() < data.end_time then
		self.btnPurchase.label = __("ALREADY_SUBSCRIBE")

		xyd:applyGrey(self.btnPurchase)
		self.btnPurchase:setTouchEnabled(false)
	else
		xyd:applyOrigin(self.btnPurchase)
		self.btnPurchase:setTouchEnabled(true)
	end

	self:calRetTimeManaSub()
end

function Subscription:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:setBtnState()
end

function Subscription:solveMultiLang()
	if self.displayType == xyd.ActivityID.SUBSCRIPTION or self.displayType == xyd.ActivityID.MANA_SUBSCRIPTION then
		if xyd.Global.lang == "en_en" then
			self.labelText1.spacingY = 2
		elseif xyd.Global.lang == "zh_cn" or xyd.Global.lang == "zh_tw" then
			self.labelText1.spacingY = 12
		elseif xyd.Global.lang == "ko_kr" then
			self.labelText1.considerEast = false
		end
	end
end

function Subscription:listenEvent()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:listenEventManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:listenEventSub()
	else
		self:listenEventManaSub()
	end
end

function Subscription:listenEventManaCard()
	self.btnPurchase:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		self:requirePayment(xyd.GIFTBAG_ID.MANA_WEEK_CARD)
	end, self)
end

function Subscription:listenEventManaSub()
	self.btnPurchase:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		self:requirePayment(xyd.GIFTBAG_ID.MANA_SUBSCRIPTION)
	end, self)
	self.helpBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "MANA_WEEK_CARD_HELP_IOS"
		})
	end, self)
end

function Subscription:listenEventSub()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, function (self, event)
		local id = event.data.act_info.activity_id

		if id ~= self.id then
			return
		end

		local data = xyd.models.activity:getActivity(id)

		data:setData(event.data.act_info)
		self:setBtnState()
	end))

	UIEventListener.Get(self.btnWeek.gameObject).onClick = handler(self, function ()
		local giftBagID = xyd.checkCondition(UNITY_ANDROID, xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND, xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION)

		self:requirePayment(giftBagID)
	end)
	UIEventListener.Get(self.btnMonth.gameObject).onClick = handler(self, function ()
		local giftBagID = xyd.checkCondition(UNITY_ANDROID, xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND, xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION)

		self:requirePayment(giftBagID)
	end)
	UIEventListener.Get(self.btnQuarter.gameObject).onClick = handler(self, function ()
		local giftBagID = xyd.checkCondition(UNITY_ANDROID, xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND, xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION)

		self:requirePayment(giftBagID)
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		if UNITY_IOS then
			xyd.WindowManager.get():openWindow("help_window", {
				key = "SUBSCRIPTION_HELP_IOS"
			})
		else
			xyd.WindowManager.get():openWindow("help_window", {
				key = "SUBSCRIPTION_HELP_AND"
			})
		end
	end)
end

function Subscription:requirePayment(giftBagID)
	if self.reqGiftbag ~= nil then
		local secs = self.reqGiftbag + 5 - xyd.getServerTime()

		if secs <= 5 and secs > 0 then
			xyd.showToast(__("SUBSCRIPTION_TEXT01", secs))

			return
		end
	end

	local win = xyd.WindowManager.get():getWindow("activity_window")

	if win and win:ifNeedDaDian() then
		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.POPUP_CLICK_IN_SUBSCRIPTION
		msg.desc = cjson.encode(giftBagID)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	local data = self.activityData.detail

	if xyd.getServerTime() < data.end_time then
		if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
			xyd.showToast(__("WEEKCARD_REPEAT_ERROR"))

			return
		end

		if self.displayType == xyd.ActivityID.MANA_SUBSCRIPTION then
			xyd.showToast(__("SUBSCRIPTION_REPEAT_ERROR"))

			return
		end

		if self.displayType == xyd.ActivityID.SUBSCRIPTION and not UNITY_ANDROID and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_FREE and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_FREE and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_FREE then
			xyd.showToast(__("SUBSCRIPTION_REPEAT_ERROR"))

			return
		end

		if self.displayType == xyd.ActivityID.SUBSCRIPTION and UNITY_ANDROID and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND_FREE and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND_FREE and self.activityData.detail.cur_giftbag_id ~= xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND_FREE then
			xyd.showToast(__("SUBSCRIPTION_REPEAT_ERROR"))

			return
		end

		if self.displayType == xyd.ActivityID.SUBSCRIPTION and UNITY_ANDROID and (self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND or self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND or self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND or self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION_AND_FREE or self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION_AND_FREE or self.activityData.detail.cur_giftbag_id == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION_AND_FREE) then
			xyd.showToast(__("WEEKCARD_REPEAT_ERROR_AND"))

			return
		end
	end

	local isFree = self.activityData.detail.is_use_free <= 0 and data.end_time < xyd.getServerTime()

	if isFree and UNITY_IOS then
		local tips = ""

		if giftBagID == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION then
			tips = __("SUBSCRIPTION_CANCEL_TIP1")
		elseif giftBagID == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION then
			tips = __("SUBSCRIPTION_CANCEL_TIP2")
		elseif giftBagID == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION then
			tips = __("SUBSCRIPTION_CANCEL_TIP3")
		end

		xyd.WindowManager.get():openWindow("alert_window", {
			alertType = xyd.AlertType.YES_NO,
			message = tips,
			callback = function (yes)
				if yes then
					xyd.SdkManager.get():buySubscription(giftBagID)
				end
			end
		})
	elseif giftBagID == xyd.GIFTBAG_ID.MANA_WEEK_CARD then
		xyd.SdkManager.get():showPayment(giftBagID)
	else
		xyd.SdkManager.get():buySubscription(giftBagID)
	end

	self.reqGiftbag = xyd.getServerTime()

	if giftBagID == xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION or giftBagID == xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION or giftBagID == xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION then
		local isFree = self.activityData.detail.is_use_free == 0 and data.end_time < xyd.getServerTime()

		if isFree then
			self.activityData.detail.cur_giftbag_id = giftBagID

			self:setBtnStateSub()
		end
	end
end

function Subscription:changeDayLabelPos()
	self.daysLabelPosSize.text = self.daysLabel.text
	local allWidth = self.labelText6_uiwidgt.width + self.daysLabelPosSize.width + 4

	self.labelText6:SetLocalPosition((148 - allWidth) / 2, -11, 0)
end

function Subscription:changeURLLabelPos()
	self.labelText2_posSize.text = self.labelText2.text
	self.labelText3_posSize.text = self.labelText3.text
	local allWidth_group = self.allGroup_uiwidget.width
	local allWidth_2 = self.labelText2_posSize.width + self.labelText4.width + 7
	local allWidth_3 = self.labelText3_posSize.width + self.labelText5.width + 7

	if allWidth_2 < allWidth_3 then
		self.labelText5:SetLocalPosition((allWidth_group - allWidth_3) / 2 - allWidth_group / 2, -858, 0)
		self.labelText4:SetLocalPosition(self.labelText5.transform.localPosition.x + self.labelText5.width - self.labelText4.width, -831, 0)
	else
		self.labelText4:SetLocalPosition((allWidth_group - allWidth_2) / 2 - allWidth_group / 2, -831, 0)
		self.labelText5:SetLocalPosition(self.labelText4.transform.localPosition.x + self.labelText4.width - self.labelText5.width, -858, 0)
	end
end

return Subscription
