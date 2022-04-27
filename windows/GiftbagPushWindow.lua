local BaseWindow = import(".BaseWindow")
local MonthCardPushWindow = class("MonthCardPushWindow", BaseWindow)
local cjson = require("cjson")
local BaseGiftbagPushWindowItem = class("BaseGiftbagPushWindowItem", import("app.components.BaseComponent"))
local MonthCardPushItem = class("MonthCardPushItem", BaseGiftbagPushWindowItem)
local ManaMonthCardPushItem = class("ManaMonthCardPushItem", BaseGiftbagPushWindowItem)
local FirstRechargePushItem = class("FirstRechargePushItem", BaseGiftbagPushWindowItem)
local SubscriptionPushItem = class("SubscriptionPushItem", BaseGiftbagPushWindowItem)
local FundationPushItem = class("FundationPushItem", BaseGiftbagPushWindowItem)
local SubscriptionPushSingleItem = class("SubscriptionPushSingleItem", import("app.components.BaseComponent"))
local FundationPushSingleItem = class("FundationPushSingleItem", import("app.components.BaseComponent"))
local VipPushSingleItem = class("VipPushSingleItem", import("app.components.BaseComponent"))

function MonthCardPushWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.list_ = {}
	self.is_single_ = false
	self.not_log_ = false
	self.list_ = params.list
	self.not_log_ = params.not_log
	self.skinName = "MonthCardPushWindowSkin"
end

function MonthCardPushWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.titleLabel.text = __("GIFTBAG_PUSH_TEXT01")

	self:initItem()

	UIEventListener.Get(self.closeBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function MonthCardPushWindow:getUIComponent()
	self.trans = self.window_.transform
	self.groupAction = self.trans:NodeByName("groupAction").gameObject
	self.groupAction_UIWidget = self.trans:ComponentByName("groupAction", typeof(UIWidget))
	self.groupActionLittle = self.groupAction:NodeByName("groupActionLittle").gameObject
	self.groupActionLittle_UIWidget = self.groupAction:ComponentByName("groupActionLittle", typeof(UIWidget))
	self.Image = self.groupActionLittle:ComponentByName("Image", typeof(UITexture))
	self.titleLabel = self.groupActionLittle:ComponentByName("titleLabel", typeof(UILabel))
	self.closeBtn = self.groupActionLittle:NodeByName("closeBtn").gameObject
	self.button_label = self.closeBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = self.groupActionLittle:NodeByName("itemGroup").gameObject
	self.itemGroup_UILayout = self.groupActionLittle:ComponentByName("itemGroup", typeof(UILayout))
	self.itemGroup_UIWidget = self.groupActionLittle:ComponentByName("itemGroup", typeof(UIWidget))
end

function MonthCardPushWindow:initItem()
	if not self.list_ then
		return
	end

	local countNum = 0

	for i in pairs(self.list_) do
		local id = self.list_[i]
		local data = xyd.models.activity:getActivity(id)

		if data or id == -1 then
			self:addItem(id)

			countNum = countNum + 1
		end
	end

	if countNum > 1 then
		self.itemGroup_UIWidget.height = 265 * countNum
		self.groupActionLittle_UIWidget.height = 265 * countNum + 65

		self.groupActionLittle:Y(self.groupActionLittle_UIWidget.height / 2)

		self.groupAction_UIWidget.height = self.groupActionLittle_UIWidget.height

		self.itemGroup:Y(-65)
	elseif countNum == 1 then
		self.itemGroup_UIWidget.height = 879 * countNum
		self.groupActionLittle_UIWidget.height = 879 * countNum + 65

		self.groupActionLittle:Y(self.groupActionLittle_UIWidget.height / 2)

		self.groupAction_UIWidget.height = self.groupActionLittle_UIWidget.height

		self.itemGroup:Y(-65)
	end

	if not self.is_single_ and not self.not_log_ then
		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.POPUP_MULTI_OPEN
		msg.desc = cjson.encode(self.list_)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

function MonthCardPushWindow:addItem(id)
	id = tonumber(id)
	local item = nil
	local params = {
		close_window = self,
		giftbag_push_list = self.list_
	}

	if id == xyd.ActivityID.MONTH_CARD then
		item = MonthCardPushItem.new(self.itemGroup.gameObject, params, self)
	elseif id == xyd.ActivityID.MINI_MONTH_CARD then
		item = ManaMonthCardPushItem.new(self.itemGroup.gameObject, params, self)
	elseif id == xyd.ActivityID.FIRST_RECHARGE then
		item = FirstRechargePushItem.new(self.itemGroup.gameObject, params, self)
	elseif id == xyd.ActivityID.SUBSCRIPTION then
		if #self.list_ == 1 then
			item = SubscriptionPushSingleItem.new(self.itemGroup.gameObject, params, self)

			if not self.not_log_ then
				local msg = messages_pb:log_partner_data_touch_req()
				msg.touch_id = xyd.DaDian.POPUP_SUBSCRIPTION_SINGLE_OPEN

				xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
			end

			self.is_single_ = true
		else
			item = SubscriptionPushItem.new(self.itemGroup.gameObject, params, self)
		end
	elseif id == xyd.ActivityID.LEVEL_FUND then
		if #self.list_ == 1 then
			item = FundationPushSingleItem.new(self.itemGroup.gameObject, params, self)

			if not self.not_log_ then
				local msg = messages_pb:log_partner_data_touch_req()
				msg.touch_id = xyd.DaDian.POPUP_FUND_OPEN_SINGLE_OPEN

				xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
			end

			self.is_single_ = true
		else
			item = FundationPushItem.new(self.itemGroup.gameObject, params, self)
		end
	elseif id == -1 and #self.list_ == 1 then
		item = VipPushSingleItem.new(self.itemGroup.gameObject, params, self)

		if not self.not_log_ then
			local msg = messages_pb:log_partner_data_touch_req()
			msg.touch_id = xyd.DaDian.POPUP_VIP_SINGLE_OPEN

			xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		end

		self.is_single_ = true
	end
end

function BaseGiftbagPushWindowItem:ctor(parentGO, params, parent)
	self.close_window_ = params.close_window
	self.giftbag_push_list_ = params.giftbag_push_list
	self.skinName = "MonthCardPushWindowItemSkin"
	self.parent = parent

	BaseGiftbagPushWindowItem.super.ctor(self, parentGO)
end

function BaseGiftbagPushWindowItem:getPrefabPath()
	return "Prefabs/Components/month_card_push_window_item"
end

function BaseGiftbagPushWindowItem:initUI()
	self:getUIComponent()
	BaseGiftbagPushWindowItem.super.initUI(self)

	UIEventListener.Get(self.go.gameObject).onClick = handler(self, self.onclickSelf)

	self:setTime()
	xyd.setUITextureByNameAsync(self.bgImg, self:getImg(), true)
end

function BaseGiftbagPushWindowItem:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UITexture))
	self.titleLabel = self.groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.descLabel = self.groupAction:ComponentByName("descLabel", typeof(UILabel))
	self.descLabel2 = self.groupAction:ComponentByName("descLabel2", typeof(UILabel))
	self.timeLabel = self.groupAction:ComponentByName("timeLabel", typeof(UILabel))
	self.itemGroup = self.groupAction:NodeByName("itemGroup").gameObject
	self.itemGroup_UILayout = self.groupAction:ComponentByName("itemGroup", typeof(UILayout))
end

function BaseGiftbagPushWindowItem:onclickSelf()
	xyd.WindowManager.get():closeWindow(self.parent.name_)
end

function BaseGiftbagPushWindowItem:setTime()
end

function BaseGiftbagPushWindowItem:getTime(timestamp)
end

function BaseGiftbagPushWindowItem:getImg()
	return ""
end

function MonthCardPushItem:ctor(parentGO, params, parent)
	MonthCardPushItem.super.ctor(self, parentGO, params, parent)
end

function MonthCardPushItem:initUI()
	BaseGiftbagPushWindowItem.initUI(self)

	self.descLabel.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_MONTH_CARD_TEXT01"))
	self.titleLabel.text = __("GIFTBAG_PUSH_MONTH_TITLE")
end

function MonthCardPushItem:onclickSelf()
	MonthCardPushItem.super.onclickSelf(self)
	xyd.WindowManager.get():openWindow("vip_window", {
		dadian_id = xyd.DaDian.POPUP_CLICK_IN_MONTH_CARD,
		giftbag_push_list = self.giftbag_push_list_
	})

	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.POPUP_CLICK_MONTH_CARD

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function MonthCardPushItem:setTime()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)

	if data then
		local day = data.detail.charges[1].days

		if day <= 0 then
			self.timeLabel:SetActive(false)
		else
			self.timeLabel:SetActive(true)

			self.timeLabel.text = __("TIME_LEFT_DAY", day)
		end
	else
		self.timeLabel:SetActive(false)
	end
end

function MonthCardPushItem:getImg()
	return "popup_month_card"
end

function ManaMonthCardPushItem:ctor(parentGO, params, parent)
	ManaMonthCardPushItem.super.ctor(self, parentGO, params, parent)
end

function ManaMonthCardPushItem:initUI()
	BaseGiftbagPushWindowItem.initUI(self)

	self.descLabel.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_MINI_MONTH_CARD_TEXT01"))
	self.titleLabel.text = __("GIFTBAG_PUSH_MINI_MONTH_CARD_TITLE")
end

function ManaMonthCardPushItem:onclickSelf()
	ManaMonthCardPushItem.super.onclickSelf(self)
	xyd.WindowManager.get():openWindow("vip_window", {
		dadian_id = xyd.DaDian.POPUP_CLICK_IN_MINI_MONTH_CARD,
		giftbag_push_list = self.giftbag_push_list_
	})

	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.POPUP_CLICK_MINI_MONTH_CARD

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function ManaMonthCardPushItem:setTime()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD)

	if data then
		local day = data.detail.charges[1].days

		if day <= 0 then
			self.timeLabel:SetActive(false)
		else
			self.timeLabel:SetActive(true)

			self.timeLabel.text = __("TIME_LEFT_DAY", day)
		end
	else
		self.timeLabel:SetActive(false)
	end
end

function ManaMonthCardPushItem:getImg()
	return "popup_mana_month_card"
end

function SubscriptionPushItem:ctor(parentGO, params, parent)
	SubscriptionPushItem.super.ctor(self, parentGO, params, parent)
end

function SubscriptionPushItem:initUI()
	SubscriptionPushItem.super.initUI(self)

	self.timeLabel.color = Color.New2(4294967295.0)
	self.timeLabel.effectColor = Color.New2(2570024703.0)
	self.descLabel.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_SUBSCRIPTION_TEXT01"))
	self.descLabel2.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_SUBSCRIPTION_TEXT02"))
	self.titleLabel.text = __("GIFTBAG_PUSH_SUBSCRIPTION_TITLE")
end

function SubscriptionPushItem:onclickSelf()
	SubscriptionPushItem.super.onclickSelf(self)
	xyd.WindowManager.get():openWindow("activity_window", {
		select = xyd.ActivityID.SUBSCRIPTION,
		giftbag_push_list = self.giftbag_push_list_
	})

	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.POPUP_CLICK_SUBSCRIPTION

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function SubscriptionPushItem:setTime()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.SUBSCRIPTION)

	if data then
		local last_time = data.detail.end_time - xyd.getServerTime()
		local day = math.floor(last_time / 86400)

		if day <= 0 then
			self.timeLabel:SetActive(false)
		else
			self.timeLabel:SetActive(true)

			self.timeLabel.text = __("TIME_LEFT_DAY", day)
		end
	else
		self.timeLabel:SetActive(false)
	end
end

function SubscriptionPushItem:getImg()
	return "popup_subscription"
end

function FundationPushItem:ctor(parentGO, params, parent)
	FundationPushItem.super.ctor(self, parentGO, params, parent)
end

function FundationPushItem:initUI()
	FundationPushItem.super.initUI(self)

	self.descLabel.color = Color.New2(3790263551.0)
	self.descLabel.effectColor = Color.New2(659697919)
	self.descLabel.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_FUND_TEXT01"))
	self.descLabel2.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_FUND_TEXT02"))
	self.titleLabel.text = __("GIFTBAG_PUSH_FUND_TITLE")
end

function FundationPushItem:onclickSelf()
	FundationPushItem.super.onclickSelf(self)
	xyd.WindowManager:openWindow("activity_window", {
		select = xyd.ActivityID.LEVEL_FUND,
		giftbag_push_list = self.giftbag_push_list_
	})

	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.POPUP_CLICK_FUND

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function FundationPushItem:setTime()
	self.timeLabel:SetActive(false)
end

function FundationPushItem:getImg()
	return "popup_fundation"
end

function FirstRechargePushItem:ctor(parentGO, params, parent)
	FirstRechargePushItem.super.ctor(self, parentGO, params, parent)
end

function FirstRechargePushItem:initUI()
	FirstRechargePushItem.super.initUI(self)
	self.descLabel:Y(82)

	self.descLabel.fontSize = 20
	self.descLabel.color = Color.New2(4125090559.0)
	self.descLabel.effectColor = Color.New2(2235715071.0)
	self.descLabel.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_FIRST_RECHARGE_TEXT01"))
	self.titleLabel.text = __("GIFTBAG_PUSH_FIRST_RECHARGE_TITLE")
	local awards = xyd.tables.miscTable:split2Cost("first_charge_awards", "value", "|#")
	local cur_cnt = 1

	for i in pairs(awards) do
		local cur_data = awards[i]

		if cur_data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				itemID = cur_data[1],
				num = cur_data[2],
				uiRoot = self.itemGroup.gameObject
			}
			local icon = xyd.getItemIcon(item)

			if cur_cnt ~= 1 then
				icon:setScale(0.7037037037037037)
			else
				icon:setScale(0.8981481481481481)
			end

			cur_cnt = cur_cnt + 1
		end
	end
end

function FirstRechargePushItem:onclickSelf()
	FirstRechargePushItem.super.onclickSelf(self)
	xyd.WindowManager.get():openWindow("vip_window", {
		dadian_id = xyd.DaDian.POPUP_CLICK_IN_FIRST_RECHARGE,
		giftbag_push_list = self.giftbag_push_list_
	})

	local msg = messages_pb:log_partner_data_touch_req()
	msg.touch_id = xyd.DaDian.POPUP_CLICK_FIRST_RECHARGE

	xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
end

function FirstRechargePushItem:setTime()
	self.timeLabel:SetActive(false)
end

function FirstRechargePushItem:getImg()
	return "popup_first_recharge"
end

function SubscriptionPushSingleItem:ctor(parentGO, params, parent)
	self.displayType = xyd.ActivityID.SUBSCRIPTION
	self.skinName = "SubscriptionPushSingleItemSkin"
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SUBSCRIPTION)

	SubscriptionPushSingleItem.super.ctor(self, parentGO, params, parent)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function SubscriptionPushSingleItem:getPrefabPath()
	return "Prefabs/Components/subscription_pop"
end

function SubscriptionPushSingleItem:getUIComponent()
	self.allGroup = self.go:NodeByName("allGroup").gameObject
	self.allGroup_uiwidget = self.go:ComponentByName("allGroup", typeof(UIWidget))
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
	self.helpBtn = self.go:ComponentByName("helpBtn", typeof(UISprite))
	self.downGroup = self.allGroup:NodeByName("downGroup").gameObject
	self.downGroupBg = self.downGroup:ComponentByName("downGroupBg", typeof(UISprite))
	self.btnQuarter = self.downGroup:ComponentByName("btnQuarter", typeof(UISprite))
	self.btnQuarter_imgPurchased = self.btnQuarter:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnQuarter_button_label = self.btnQuarter:ComponentByName("button_label", typeof(UILabel))
	self.btnQuarter_boxCollider = self.btnQuarter:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnRecover = self.downGroup:ComponentByName("btnRecover", typeof(UISprite))
	self.btnRecover_imgPurchased = self.btnRecover:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnRecover_button_label = self.btnRecover:ComponentByName("button_label", typeof(UILabel))
	self.btnRecover_boxCollider = self.btnRecover:GetComponent(typeof(UnityEngine.BoxCollider))
	self.btnMonth = self.downGroup:ComponentByName("btnMonth", typeof(UISprite))
	self.btnMonth_imgPurchased = self.btnMonth:ComponentByName("imgPurchased", typeof(UISprite))
	self.btnMonth_button_label = self.btnMonth:ComponentByName("button_label", typeof(UILabel))
	self.btnMonth_boxCollider = self.btnMonth:GetComponent(typeof(UnityEngine.BoxCollider))
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
end

function SubscriptionPushSingleItem:initUI()
	self:getUIComponent()
	SubscriptionPushSingleItem.super.initUI(self)
	self:setText()
	self:setBtnState()
	self:solveMultiLang()
	self:listenEvent()
end

function SubscriptionPushSingleItem:setText()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:setTextManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:setTextSub()
	else
		self:setTextManaSub()
	end
end

function SubscriptionPushSingleItem:setTextSub()
	local WeekGiftBagID = xyd.GIFTBAG_ID.WEEK_SUBSCRIPTION
	local MonthGiftBagID = xyd.GIFTBAG_ID.MONTH_SUBSCRIPTION
	local QuarterGiftBagID = xyd.GIFTBAG_ID.QUARTER_SUBSCRIPTION
	self.labelText2.text = xyd.getUnderlineText(__("TERMS_SERVICE_URL"))
	self.labelText3.text = xyd.getUnderlineText(__("PRIVACY_POLICY_URL"))
	self.labelText4.text = __("TERMS_SERVICE")
	self.labelText5.text = __("PRIVACY_POLICY")
	self.labelText7.text = __("SUBSCRIPTION_CANCEL_TIP")
	self.btnWeek_button_label.text = __("WEEK_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(WeekGiftBagID), xyd.tables.giftBagTextTable:getCharge(WeekGiftBagID))
	self.btnMonth_button_label.text = __("MONTH_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(MonthGiftBagID), xyd.tables.giftBagTextTable:getCharge(MonthGiftBagID))
	self.btnQuarter_button_label.text = __("QUARTER_SUBSCRIPTION_BTN_LABEL", xyd.tables.giftBagTextTable:getCurrency(QuarterGiftBagID), xyd.tables.giftBagTextTable:getCharge(QuarterGiftBagID))

	if xyd.Global.isReview ~= 0 then
		self.btnRecover_button_label.label = __("SUBSCRIPTION_RECOVER")
		UIEventListener.Get(self.btnRecover.gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("alert_window", {
				alertType = xyd.AlertType.TIPS,
				message = __("SUBSCRIPTION_RECOVER_CONFIRM")
			})
		end)

		self.btnRecover:SetActive(true)
	end

	local content1 = ""
	local content2 = ""

	if xyd.Global.lang == "fr_fr" then
		content1 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("TERMS_SERVICE_URL"), __("FRANCE_TAP_TO_GO"))
		content2 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("PRIVACY_POLICY_URL"), __("FRANCE_TAP_TO_GO"))
		self.labelText2.text = xyd.getUnderlineText(__("FRANCE_TAP_TO_GO"))
		self.labelText3.text = xyd.getUnderlineText(__("FRANCE_TAP_TO_GO"))
	else
		content1 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("TERMS_SERVICE_URL"), __("TERMS_SERVICE_URL"))
		content2 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("PRIVACY_POLICY_URL"), __("PRIVACY_POLICY_URL"))
		self.labelText2.text = xyd.getUnderlineText(__("TERMS_SERVICE_URL"))
		self.labelText3.text = xyd.getUnderlineText(__("PRIVACY_POLICY_URL"))
	end

	UIEventListener.Get(self.labelText2.gameObject).onClick = handler(self, function ()
		UnityEngine.Application.OpenURL(__("TERMS_SERVICE_URL"))
	end)
	UIEventListener.Get(self.labelText3.gameObject).onClick = handler(self, function ()
		UnityEngine.Application.OpenURL(__("PRIVACY_POLICY_URL"))
	end)
	self.labelText6.text = __("RET_TIME_TEXT")

	if UNITY_IOS then
		self.labelText1.text = __("SUBSCRIPTION_TEXT01_IOS")
	else
		self.labelText1.text = __("SUBSCRIPTION_TEXT01_AND")
	end

	self:changeURLLabelPos()
end

function SubscriptionPushSingleItem:setTextManaSub()
	local giftBagID = xyd.GIFTBAG_ID.MANA_SUBSCRIPTION
	self.imgText01.source = "mana_week_card_text02_" .. tostring(xyd.Global.lang) .. "_png"
	self.imgText03.source = "mana_week_card_text03_" .. tostring(xyd.Global.lang) .. "_png"
	self.labelText1.text = __("MANA_WEEK_CARD_TEXT01_IOS")
	self.labelText2.text = __("TERMS_SERVICE_URL")
	self.labelText3.text = __("PRIVACY_POLICY_URL")
	self.labelText4.text = __("TERMS_SERVICE")
	self.labelText5.text = __("PRIVACY_POLICY")
	self.btnPurchase.label = tostring(__("WEEKCARD_BTN_LABEL")) .. " " .. tostring(xyd.tabels.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
	local content1 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("TERMS_SERVICE_URL"), __("TERMS_SERVICE_URL"))
	local content2 = xyd.stringFormat("<a href=\"{1}\"><u>{2}</u></a>", __("PRIVACY_POLICY_URL"), __("PRIVACY_POLICY_URL"))
	self.labelText2.text = xyd.getUnderlineText(__("TERMS_SERVICE_URL"))
	self.labelText3.text = xyd.getUnderlineText(__("PRIVACY_POLICY_URL"))
	self.labelText6.text = __("RET_TIME_TEXT")

	self:changeURLLabelPos()
end

function SubscriptionPushSingleItem:setTextManaCard()
	self.labelText1.text = __("MANA_WEEK_CARD_TEXT01")
	self.retLabel.text = __("RET_TIME_TEXT")
	local giftBagID = xyd.GIFTBAG_ID.MANA_WEEK_CARD
	self.labelPrice.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
end

function SubscriptionPushSingleItem:calRetTimeManaSub()
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

function SubscriptionPushSingleItem:calRetTimeManaCard()
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

function SubscriptionPushSingleItem:calRetTimeSub()
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

function SubscriptionPushSingleItem:setBtnState()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:setBtnStateManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:setBtnStateSub()
	else
		self:setBtnStateManaSub()
	end
end

function SubscriptionPushSingleItem:setBtnStateSub()
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
		else
			xyd.setUISpriteAsync(self.btnWeek, nil, "mana_week_card_btn01", nil, )

			self.btnWeek_button_label.color = Color.New2(3224980479.0)
			self.btnWeek_button_label.effectColor = Color.New2(4294967295.0)
			self.btnWeek_button_label.text = priceText
		end
	end

	self:calRetTimeSub()
end

function SubscriptionPushSingleItem:setBtnStateManaCard()
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

function SubscriptionPushSingleItem:setBtnStateManaSub()
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

function SubscriptionPushSingleItem:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= xyd.ActivityID.SUBSCRIPTION then
		return
	end

	self:setBtnState()
end

function SubscriptionPushSingleItem:solveMultiLang()
	if self.displayType == xyd.ActivityID.SUBSCRIPTION or self.displayType == xyd.ActivityID.MANA_SUBSCRIPTION then
		if xyd.Global.lang == "en_en" then
			self.labelText1.spacingY = 2
		elseif xyd.Global.lang == "zh_cn" or xyd.Global.lang == "zh_tw" then
			self.labelText1.spacingY = 12
		end
	end
end

function SubscriptionPushSingleItem:listenEvent()
	if self.displayType == xyd.ActivityID.MANA_WEEK_CARD then
		self:listenEventManaCard()
	elseif self.displayType == xyd.ActivityID.SUBSCRIPTION then
		self:listenEventSub()
	else
		self:listenEventManaSub()
	end
end

function SubscriptionPushSingleItem:listenEventManaCard()
	self.btnPurchase:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		self:requirePayment(xyd.GIFTBAG_ID.MANA_WEEK_CARD)
	end, self)
end

function SubscriptionPushSingleItem:listenEventManaSub()
	self.btnPurchase:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		self:requirePayment(xyd.GIFTBAG_ID.MANA_SUBSCRIPTION)
	end, self)
	self.helpBtn:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = __("MANA_WEEK_CARD_HELP_IOS")
		})
	end, self)
end

function SubscriptionPushSingleItem:listenEventSub()
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

function SubscriptionPushSingleItem:requirePayment(giftBagID)
	if self.reqGiftbag ~= nil then
		local secs = self.reqGiftbag + 5 - xyd.getServerTime()

		if secs <= 5 and secs > 0 then
			xyd.showToast(__("SUBSCRIPTION_TEXT01", secs))

			return
		end
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

function SubscriptionPushSingleItem:changeDayLabelPos()
	self.daysLabelPosSize.text = self.daysLabel.text
	local allWidth = self.labelText6_uiwidgt.width + self.daysLabelPosSize.width + 4

	self.labelText6:SetLocalPosition((148 - allWidth) / 2, -11, 0)
end

function SubscriptionPushSingleItem:changeURLLabelPos()
	self.labelText2_posSize.text = self.labelText2.text
	self.labelText3_posSize.text = self.labelText3.text
	local allWidth_group = self.allGroup_uiwidget.width
	local allWidth_2 = self.labelText2_posSize.width + self.labelText4.width + 7
	local allWidth_3 = self.labelText3_posSize.width + self.labelText5.width + 7

	if allWidth_2 < allWidth_3 then
		self.labelText5:SetLocalPosition((allWidth_group - allWidth_3) / 2 - allWidth_group / 2, -866, 0)
		self.labelText4:SetLocalPosition(self.labelText5.transform.localPosition.x + self.labelText5.width - self.labelText4.width, -843, 0)
	else
		self.labelText4:SetLocalPosition((allWidth_group - allWidth_2) / 2 - allWidth_group / 2, -843, 0)
		self.labelText5:SetLocalPosition(self.labelText4.transform.localPosition.x + self.labelText4.width - self.labelText5.width, -866, 0)
	end
end

function FundationPushSingleItem:ctor(parentGO, params, parent)
	self.id = xyd.ActivityID.LEVEL_FUND
	self.skinName = "FundationPushSingleItemSkin"
	local gift_bag_id = tonumber(xyd.tables.activityTable:getGiftBag(self.id))
	self.giftBagId_ = gift_bag_id
	self.activityData = xyd.models.activity:getActivity(self.id)

	FundationPushSingleItem.super.ctor(self, parentGO, params, parent)
end

function FundationPushSingleItem:getPrefabPath()
	return "Prefabs/Components/fundation_push_single_item"
end

function FundationPushSingleItem:getUIComponent()
	self.labelDesc_ = self.trans:ComponentByName("labelDesc_", typeof(UILabel))
	self.labelDesc2 = self.trans:ComponentByName("labelDesc2", typeof(UILabel))
	self.e_Group = self.trans:NodeByName("e:Group").gameObject
	self.labelLimit_ = self.e_Group:ComponentByName("labelLimit_", typeof(UILabel))
	self.labelVip_ = self.e_Group:ComponentByName("labelVip_", typeof(UILabel))
	self.btnBuy_ = self.e_Group:NodeByName("btnBuy_").gameObject
	self.btnBuyLabel_ = self.btnBuy_:ComponentByName("button_label", typeof(UILabel))
end

function FundationPushSingleItem:initUI()
	self:getUIComponent()
	FundationPushSingleItem.super.initUI(self)
	self:layout()
	self:initData()
	self:registerEvent()
end

function FundationPushSingleItem:registerEvent()
	UIEventListener.Get(self.btnBuy_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagId_)

		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.POPUP_CLICK_IN_FUND

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end

	self:registerEvent(xyd.event.RECHARGE, function (self, evt)
		local gift_bag_id = evt.data.giftbag_id

		if xyd.tables.giftBagTable:getActivityID(gift_bag_id) ~= self.id then
			return
		end

		xyd.models.activity:reqActivityByID(xyd.ActivityID.LEVEL_FUND)
	end)
end

function FundationPushSingleItem:layout()
	self.btnBuyLabel_.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagId_) .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagId_))
	self.labelDesc_.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_FUND_TEXT03"))
	self.labelDesc2.text = xyd.getUnderlineText(__("GIFTBAG_PUSH_FUND_TEXT03"))
	self.labelVip_.text = "+" .. tostring(tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagId_))) .. " VIP EXP"
end

function FundationPushSingleItem:initData()
	self:updateState()
end

function FundationPushSingleItem:updateState()
	local activityData = self.activityData
	local buyTimes = activityData.detail.charges[1].buy_times
	local limit = activityData.detail.charges[1].limit_times

	if limit <= buyTimes then
		xyd.applyChildrenGrey(self.btnBuy_.gameObject)

		self.btnBuy_:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end

	self.labelLimit_.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - buyTimes))
end

function VipPushSingleItem:ctor(parentGO, params, parent)
	self.close_window = params.close_window
	self.skinName = "VipPushSingleItemSkin"
	self.parent = parent

	VipPushSingleItem.super.ctor(self, parentGO, params, parent)
end

function VipPushSingleItem:getPrefabPath()
	return "Prefabs/Components/vip_push_single_item"
end

function VipPushSingleItem:getUIComponent()
	self.goBtn = self.go:NodeByName("goBtn").gameObject
	self.button_label = self.goBtn:ComponentByName("button_label", typeof(UILabel))
end

function VipPushSingleItem:initUI()
	self:getUIComponent()
	VipPushSingleItem.super.initUI(self)

	self.button_label.text = __("GO")

	UIEventListener.Get(self.goBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.parent.name_)
		xyd.WindowManager.get():openWindow("vip_window", {
			dadian_id = xyd.DaDian.POPUP_CLICK_IN_VIP
		})

		local msg = messages_pb:log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.POPUP_CLICK_VIP

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
	end
end

return MonthCardPushWindow
