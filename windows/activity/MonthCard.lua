local ActivityContent = import(".ActivityContent")
local MonthCard = class("MonthCard", ActivityContent)
local CountDown = import("app.components.CountDown")

function MonthCard:ctor(parentGO, params)
	self.activityData_1 = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD)
	self.activityData_2 = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)
	self.tableID_1 = self.activityData_1:getGiftBagID()
	self.tableID_2 = self.activityData_2:getGiftBagID()
	self.limitDiscountData1 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)
	self.limitDiscountData2 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)
	self.limitDiscountGiftbagID1 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)[1]
	self.limitDiscountGiftbagID2 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)[1]

	ActivityContent.ctor(self, parentGO, params)

	local nowTime = xyd.db.misc:getValue("month_card_dadian")

	if not nowTime or not xyd.isToday(tonumber(nowTime)) then
		local msg = messages_pb.log_partner_data_touch_req()
		msg.touch_id = xyd.DaDian.MONTH_CARD
		msg.desc = tostring(xyd.Global.playerID)

		xyd.Backend.get():request(xyd.mid.LOG_PARTNER_DATA_TOUCH, msg)
		xyd.db.misc:setValue({
			key = "month_card_dadian",
			value = xyd.getServerTime()
		})
	end
end

function MonthCard:getPrefabPath()
	return "Prefabs/Windows/activity/new_month_card"
end

function MonthCard:initUI()
	self:getUIComponent()
	self:layout()
	self:onRegisterEvent()
end

function MonthCard:getUIComponent()
	local go = self.go
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	local groupMain = go:NodeByName("groupMain").gameObject

	groupMain:Y(-566 + self.scale_num_ * 62)

	for i = 1, 2 do
		local month_card = groupMain:NodeByName("month_card_" .. i).gameObject
		self["textLogo_" .. i] = month_card:ComponentByName("textLogo", typeof(UISprite))
		self["textGet_" .. i] = month_card:ComponentByName("textGet", typeof(UISprite))
		self["labelGet_" .. i] = month_card:ComponentByName("labelGet", typeof(UILabel))
		self["labelGetNum_" .. i] = month_card:ComponentByName("getNumGroup/labelGetNum", typeof(UILabel))
		self["labelEveryday_" .. i] = month_card:ComponentByName("labelEveryday", typeof(UILabel))
		self["labelEverydayNum_" .. i] = month_card:ComponentByName("everydayNumGroup/labelEverydayNum", typeof(UILabel))
		self["labelVIP_" .. i] = month_card:ComponentByName("labelVIP", typeof(UILabel))
		self["btnPurchase_" .. i] = month_card:NodeByName("btnPurchase").gameObject
		self["originPrice_" .. i] = self["btnPurchase_" .. i]:ComponentByName("originPrice", typeof(UILabel))
		self["curPrice_" .. i] = self["btnPurchase_" .. i]:ComponentByName("curPrice", typeof(UILabel))
		self["line_" .. i] = self["btnPurchase_" .. i]:NodeByName("line_").gameObject
		self["discountPart_" .. i] = month_card:NodeByName("btnDiscountPart").gameObject
		self["discountPartLabel_" .. i] = self["discountPart_" .. i]:ComponentByName("label", typeof(UILabel))
		self["infoGroup_" .. i] = month_card:ComponentByName("infoGroup", typeof(UILayout))
		self["lockNode_" .. i] = self["infoGroup_" .. i]:NodeByName("lockNode").gameObject
		self["retLabel_" .. i] = self["infoGroup_" .. i]:ComponentByName("retLabel", typeof(UILabel))
		self["daysLabel_" .. i] = self["infoGroup_" .. i]:ComponentByName("daysLabel", typeof(UILabel))
		self["discountPart" .. i] = month_card:NodeByName("discountPart").gameObject
		self["labelDiscount" .. i] = self["discountPart" .. i]:ComponentByName("labelDiscount", typeof(UILabel))
		self["labelOff" .. i] = self["discountPart" .. i]:ComponentByName("labelOff", typeof(UILabel))
		self["discountTime" .. i] = month_card:NodeByName("discountTime").gameObject
		self["textLabel" .. i] = self["discountTime" .. i]:ComponentByName("textLabel", typeof(UILabel))
		self["timeLabel" .. i] = self["discountTime" .. i]:ComponentByName("timeLabel", typeof(UILabel))
		self["privilegeLabel" .. i] = month_card:ComponentByName("privilegeLabel", typeof(UILabel))
		self["labelTip" .. i] = month_card:ComponentByName("privilegeLabel/labelTip", typeof(UILabel))
	end

	self.awardBtn = groupMain:NodeByName("month_card_2").gameObject:NodeByName("awardBtn").gameObject
end

function MonthCard:layout()
	for i = 1, 2 do
		xyd.setUISpriteAsync(self["textLogo_" .. i], nil, "new_month_card_" .. i .. "_" .. xyd.Global.lang)
		xyd.setUISpriteAsync(self["textGet_" .. i], nil, "new_month_card_get_" .. xyd.Global.lang)
	end

	for i = 1, 2 do
		local giftBagID = self["tableID_" .. i]
		self["curPrice_" .. i].text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftBagID))
		self["labelVIP_" .. i].text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(giftBagID)) .. " VIP EXP"
		self["labelGet_" .. i].text = __("MONTH_CARD_TEXT001")
		self["labelEveryday_" .. i].text = __("MONTH_CARD_TEXT002")
		self["labelDiscount" .. i].text = "66%"
		self["labelOff" .. i].text = "OFF"
		self["labelTip" .. i].text = __("MONTH_CARD_EXTRA_TEXT04")

		self:setLimitDiscount(i)
		self:setBtnState(i)

		if xyd.Global.lang == "de_de" then
			self["originPrice_" .. i].fontSize = 16
			self["discountPartLabel_" .. i].fontSize = 16
		elseif xyd.Global.lang == "en_en" then
			self["originPrice_" .. i].fontSize = 16
			self["discountPartLabel_" .. i].fontSize = 16

			self["discountPartLabel_" .. i].transform:Y(3)
		elseif xyd.Global.lang == "fr_fr" then
			self["discountPartLabel_" .. i].fontSize = 15
		elseif xyd.Global.lang == "ja_jp" then
			self["discountPartLabel_" .. i].width = 60
		elseif xyd.Global.lang == "zh_tw" then
			self["discountPartLabel_" .. i].width = 60
		end
	end

	self.privilegeLabel1.text = __("MONTH_CARD_EXTRA_TEXT01")
	self.privilegeLabel2.text = __("MONTH_CARD_EXTRA_TEXT02") .. "\n" .. __("MONTH_CARD_EXTRA_TEXT03")

	if xyd.Global.lang == "fr_fr" then
		self.privilegeLabel1.fontSize = 15
	end

	self.labelGetNum_1.text = "500"
	self.labelGetNum_2.text = "1500"
	self.labelEverydayNum_1.text = "150"
	self.labelEverydayNum_2.text = "450"
end

function MonthCard:setLimitDiscount(i)
	self:calRetTime(i)

	if self["tableID_" .. i] == self["limitDiscountGiftbagID" .. i] then
		self["discountPart" .. i]:SetActive(true)

		local originTableID = xyd.tables.giftBagTable:getParams(self["tableID_" .. i])[1]
		self["originPrice_" .. i].text = __("SALE_MONTH_GIFTBAG1") .. tostring(xyd.tables.giftBagTextTable:getCurrency(originTableID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(originTableID))

		self["discountTime" .. i]:SetActive(false)

		self["labelDiscount" .. i].text = i == 1 and "60%" or "33%"
	else
		self["discountPart" .. i]:SetActive(false)

		self["originPrice_" .. i].text = i == 1 and __("MINI_MONTH_CARD_TEXT04") or __("MONTH_CARD_TEXT04")

		self["discountTime" .. i]:SetActive(false)

		self["labelDiscount" .. i].text = "66%"
	end

	if self["tableID_" .. i] == 302 then
		self["discountPart" .. i]:SetActive(true)
	end
end

function MonthCard:onRegisterEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "MONTH_CARD_TEXT004"
		})
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("month_card_everyday_award_window")
	end

	for i = 1, 2 do
		UIEventListener.Get(self["btnPurchase_" .. i]).onClick = function ()
			xyd.SdkManager.get():showPayment(self["tableID_" .. i])
		end
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityData))
end

function MonthCard:onActivityData()
	self.activityData_1 = xyd.models.activity:getActivity(xyd.ActivityID.MINI_MONTH_CARD)
	self.activityData_2 = xyd.models.activity:getActivity(xyd.ActivityID.MONTH_CARD)
	self.tableID_1 = self.activityData_1:getGiftBagID()
	self.tableID_2 = self.activityData_2:getGiftBagID()
	self.limitDiscountData1 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)
	self.limitDiscountData2 = xyd.models.activity:getActivity(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)
	self.limitDiscountGiftbagID1 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MINI_MONTH_CARD)[1]
	self.limitDiscountGiftbagID2 = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.LIMIT_DISCOUNT_MONTH_CARD)[1]

	self:layout()
end

function MonthCard:setBtnState(i)
	if self["tableID_" .. i] == 1 or self["tableID_" .. i] == 2 then
		self["originPrice_" .. i]:SetActive(false)
		self["line_" .. i]:SetActive(false)
		self["curPrice_" .. i].transform:Y(0)
		self["discountPart_" .. i]:SetActive(false)
	elseif self["tableID_" .. i] == 302 then
		self["discountPart_" .. i]:SetActive(false)
	else
		self["discountPart_" .. i]:SetActive(true)

		self["discountPartLabel_" .. i].text = (self["tableID_" .. i] == 283 or self["tableID_" .. i] == 282) and __("MONTHLY_CARD_OFFER_FIRST") or __("SALE_MAIN_TITLE")
	end
end

function MonthCard:calRetTime(i)
	local endTime = self["activityData_" .. i].detail_.charges[2].end_time or 0

	if self["activityData_" .. i].detail_.charges[1] and self["activityData_" .. i].detail_.charges[1].end_time then
		endTime = self["activityData_" .. i].detail_.charges[1].end_time
	end

	local days = math.floor((endTime - xyd:getServerTime() + xyd:getServerTime() % 86400) / 86400)

	if days > 0 then
		self["infoGroup_" .. i]:SetActive(true)

		self["clockEffect_" .. i] = xyd.Spine.new(self["lockNode_" .. i])

		self["clockEffect_" .. i]:setInfo("fx_ui_shizhong", function ()
			self["clockEffect_" .. i]:play("texiao1", 0)
			self["clockEffect_" .. i]:SetLocalScale(0.9, 0.9, 0.9)
		end)

		self["retLabel_" .. i].text = __("RET_TIME_TEXT")
		self["daysLabel_" .. i].text = __("DAY", days)

		self["infoGroup_" .. i]:Reposition()
	else
		self["infoGroup_" .. i]:SetActive(false)
	end
end

function MonthCard:onRecharge(event)
	local giftBagID = event.data.giftbag_id
	local actID = xyd.tables.giftBagTable:getActivityID(giftBagID)

	if actID == xyd.ActivityID.MONTH_CARD or actID == xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT then
		self.tableID_2 = self.activityData_2:getGiftBagID()

		self:setBtnState(2)
		self:setLimitDiscount(2)
	end

	if actID == xyd.ActivityID.MINI_MONTH_CARD then
		self.tableID_1 = self.activityData_1:getGiftBagID()

		self:setBtnState(1)
		self:setLimitDiscount(1)
	end
end

return MonthCard
