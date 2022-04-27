local ActivityReturnDiscountWindow = class("ActivityReturnDiscountWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function ActivityReturnDiscountWindow:ctor(name, params)
	ActivityReturnDiscountWindow.super.ctor(self, name, params)
end

function ActivityReturnDiscountWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
	xyd.db.misc:setValue({
		key = "activity_return_discount_red_time",
		value = xyd.getServerTime()
	})

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_RESIDENT_RETURN)

	if activityData then
		activityData:setRedMarkState(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_3)
	end
end

function ActivityReturnDiscountWindow:getUIComponent()
	self.group1 = self.window_:NodeByName("group1").gameObject
	self.textLogo_1 = self.group1:ComponentByName("textLogo", typeof(UISprite))
	self.labelDesc1_1 = self.group1:ComponentByName("labelDesc1", typeof(UILabel))
	self.labelGetNum = self.group1:ComponentByName("getNumGroup/labelGetNum", typeof(UILabel))
	self.labelDesc2_1 = self.group1:ComponentByName("labelDesc2", typeof(UILabel))
	self.labelEverydayNum = self.group1:ComponentByName("everydayNumGroup/labelEverydayNum", typeof(UILabel))
	self.groupDiscount1 = self.group1:NodeByName("groupDiscount").gameObject
	self.labelDiscount_1 = self.group1:ComponentByName("groupDiscount/labelDiscount", typeof(UILabel))
	self.labelOff_1 = self.group1:ComponentByName("groupDiscount/labelOff", typeof(UILabel))
	self.originPrice_1 = self.group1:ComponentByName("originPrice", typeof(UILabel))
	self.curPrice_1 = self.group1:ComponentByName("curPrice", typeof(UILabel))
	self.labelVIP_1 = self.group1:ComponentByName("labelVIP", typeof(UILabel))
	self.btnGo_1 = self.group1:NodeByName("btnGo").gameObject
	self.labelGo_1 = self.btnGo_1:ComponentByName("labelGo", typeof(UILabel))
	self.group2 = self.window_:NodeByName("group2").gameObject
	self.textLogo_2 = self.group2:ComponentByName("textLogo", typeof(UISprite))
	self.labelDesc_2 = self.group2:ComponentByName("labelDesc", typeof(UILabel))
	self.groupDiscount2 = self.group2:NodeByName("groupDiscount").gameObject
	self.labelDiscount_2 = self.group2:ComponentByName("groupDiscount/labelDiscount", typeof(UILabel))
	self.labelOff_2 = self.group2:ComponentByName("groupDiscount/labelOff", typeof(UILabel))
	self.originPrice_2 = self.group2:ComponentByName("originPrice", typeof(UILabel))
	self.curPrice_2 = self.group2:ComponentByName("curPrice", typeof(UILabel))
	self.labelVIP_2 = self.group2:ComponentByName("labelVIP", typeof(UILabel))
	self.btnGo_2 = self.group2:NodeByName("btnGo").gameObject
	self.labelGo_2 = self.btnGo_2:ComponentByName("labelGo", typeof(UILabel))
	self.labelWait = self.window_:ComponentByName("group3/labelWait", typeof(UILabel))
end

function ActivityReturnDiscountWindow:layout()
	self:initTopGroup()
	xyd.setUISpriteAsync(self.textLogo_1, nil, "new_month_card_get_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.textLogo_2, nil, "activity_return_discount_text02" .. "_" .. xyd.Global.lang, function ()
		self.textLogo_2:MakePixelPerfect()
	end)

	if xyd.Global.lang == "en_en" then
		self.originPrice_1.fontSize = 16
		self.labelDesc_2.spacingY = 5

		self.groupDiscount2:X(-252)
		self.groupDiscount2:Y(-160)

		self.originPrice_2.fontSize = 18

		self.originPrice_2:X(-103)
	elseif xyd.Global.lang == "fr_fr" then
		self.originPrice_1.fontSize = 15
		self.labelDesc_2.spacingY = 2

		self.groupDiscount2:X(-252)
		self.groupDiscount2:Y(-160)

		self.originPrice_2.fontSize = 18

		self.originPrice_2:X(-103)
	elseif xyd.Global.lang == "de_de" then
		self.originPrice_1.fontSize = 18
		self.labelDesc_2.spacingY = 2

		self.groupDiscount2:X(-252)
		self.groupDiscount2:Y(-160)
		self.originPrice_2:X(-102)
	elseif xyd.Global.lang == "ja_jp" or xyd.Global.lang == "ko_kr" then
		self.groupDiscount2:X(-252)
		self.groupDiscount2:Y(-160)
	end

	self.labelDesc1_1.text = __("MONTH_CARD_TEXT001")
	self.labelDesc2_1.text = __("MONTH_CARD_TEXT002")
	self.labelGetNum.text = "900"
	self.labelEverydayNum.text = "370"
	self.originPrice_1.text = __("MONTH_CARD_TEXT04")
	self.curPrice_1.text = tostring(xyd.tables.giftBagTextTable:getCurrency(302)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(302))
	self.labelVIP_1.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(302)) .. " VIP EXP"
	self.labelDiscount_1.text = "66%"
	self.labelOff_1.text = "OFF"
	self.labelGo_1.text = __("GO")
	self.labelDesc_2.text = __("ACTIVITY_MONTHLY_TEXT01")
	self.originPrice_2.text = __("ACTIVITY_RETURN2_ADD_TEXT12")
	self.curPrice_2.text = tostring(xyd.tables.giftBagTextTable:getCurrency(303)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(303))
	self.labelVIP_2.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(303)) .. " VIP EXP"
	self.labelDiscount_2.text = "80%"
	self.labelOff_2.text = "OFF"
	self.labelGo_2.text = __("GO")

	self.labelWait:SetActive(false)
end

function ActivityReturnDiscountWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, nil, , function ()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		self:close()
	end)
	local items = {
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.MANA
		},
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.windowTop:setItem(items)
end

function ActivityReturnDiscountWindow:registerEvent()
	UIEventListener.Get(self.btnGo_1).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_window", {
			select = 6
		})
	end

	UIEventListener.Get(self.btnGo_2).onClick = function ()
		if xyd.checkFunctionOpen(xyd.FunctionID.LIMIT, false) then
			xyd.WindowManager.get():openWindow("activity_window", {
				select = 75
			})
		end
	end
end

return ActivityReturnDiscountWindow
