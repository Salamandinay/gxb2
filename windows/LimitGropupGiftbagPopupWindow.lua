local LimitGropupGiftbagPopupWindow = class("LimitGropupGiftbagPopupWindow", import(".BaseWindow"))

function LimitGropupGiftbagPopupWindow:ctor(name, params)
	LimitGropupGiftbagPopupWindow.super.ctor(self, name, params)
	xyd.db.misc:setValue({
		key = "gropup_pop_up_window_check",
		value = xyd.getServerTime()
	})
	xyd.GiftbagPushController.get():checkGropupRechargePop()
end

function LimitGropupGiftbagPopupWindow:initWindow()
	LimitGropupGiftbagPopupWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function LimitGropupGiftbagPopupWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.textImg_ = winTrans:ComponentByName("textImg", typeof(UITexture))
	self.buyBtn_ = winTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = winTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.descLabel_ = winTrans:ComponentByName("descLabel", typeof(UILabel))
end

function LimitGropupGiftbagPopupWindow:layout()
	self.descLabel_.text = __("GROPUP_GIFTBAG_TIPS")
	self.buyBtnLabel_.text = __("NEW_RECHARGE_TEXT08")

	xyd.setUITextureByNameAsync(self.textImg_, "activity_gropup_giftbag_tanchuang_logo_" .. xyd.Global.lang)

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.GiftbagPushController.get().isJumping = true

		xyd.WindowManager.get():clearStackWindow()
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.WindowManager.get():openWindow("activity_window", {
			activity_type = xyd.EventType.COOL,
			select = xyd.ActivityID.TULIN_GROWUP_GIFTBAG
		}, function ()
			xyd.GiftbagPushController.get().isJumping = false
		end)
	end

	if xyd.Global.lang == "fr_fr" or xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" then
		self.descLabel_.transform:Y(225)
	end
end

return LimitGropupGiftbagPopupWindow
