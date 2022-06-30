local ModifyAccountWindow = class("ModifyAccountWindow", import(".BaseWindow"))

function ModifyAccountWindow:ctor(name, params)
	ModifyAccountWindow.super.ctor(self, name, params)

	self.curType_ = params.winType or xyd.ModifyAccountWindowType.CHANGE_ACCOUNT
end

function ModifyAccountWindow:initWindow()
	ModifyAccountWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ModifyAccountWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.main_ = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.main_:ComponentByName("top/labelTitle_", typeof(UILabel))
	self.closeBtn = self.main_:NodeByName("top/closeBtn").gameObject
	self.helpBtn = self.main_:NodeByName("top/helpBtn").gameObject
	self.deleteBtn = self.main_:NodeByName("top/deleteBtn").gameObject
	self.mid = self.main_:NodeByName("mid").gameObject
	self.btnFacebook_ = self.mid:NodeByName("btnFacebook_").gameObject
	self.btnGoogle_ = self.mid:NodeByName("btnGoogle_").gameObject
	self.btnLine_ = self.mid:NodeByName("btnLine_").gameObject
	self.btnGameCenter_ = self.mid:NodeByName("btnGameCenter_").gameObject
	self.bot = self.main_:NodeByName("bot").gameObject
	self.btnOther_ = self.bot:NodeByName("btnOther_").gameObject
	self.btnApple_ = self.mid:NodeByName("btnApple_").gameObject
	self.mainWidget = self.main_:GetComponent(typeof(UIWidget))
end

function ModifyAccountWindow:layout()
	local btnOtherlabel, labelTitletext, btnFacebooklabel, btnGooglelabel, btnLinelabel, btnGameCenterlabel, btnApplelabel = nil

	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT then
		btnOtherlabel = __("FAST_LOGING")
		labelTitletext = __("CHANGE_ACCOUNT")
		btnFacebooklabel = __("FACEBOOK_LOGING")
		btnGooglelabel = __("GOOGLE_LOGING")
		btnLinelabel = __("LINE_LOGING")
		btnGameCenterlabel = __("GAMECENTER_LOGING")
		btnApplelabel = "Sign in with Apple"

		self.deleteBtn:SetActive(true)
	elseif self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		btnOtherlabel = __("FAST_LOGING_1")
		labelTitletext = __("CHANGE_ACCOUNT_1")
		btnFacebooklabel = __("FACEBOOK_LOGING")
		btnGooglelabel = __("GOOGLE_LOGING")
		btnLinelabel = __("LINE_LOGING")
		btnGameCenterlabel = __("GAMECENTER_LOGING")
		btnApplelabel = "Sign in with Apple"

		self.deleteBtn:SetActive(false)
	else
		btnOtherlabel = __("REGISTER_ACCOUNT")
		labelTitletext = __("REGISTER_WINDOW")
		btnFacebooklabel = __("FACEBOOK_REGISTER")
		btnGooglelabel = __("GOOGLE_REGISTER")
		btnLinelabel = __("LINE_REGISTER")
		btnGameCenterlabel = __("GAMECENTER_REGISTER")
		btnApplelabel = "Sign in with Apple"
	end

	self.btnOther_:ComponentByName("button_label", typeof(UILabel)).text = btnOtherlabel
	self.labelTitle_.text = labelTitletext
	self.btnFacebook_:ComponentByName("button_label", typeof(UILabel)).text = btnFacebooklabel
	self.btnGoogle_:ComponentByName("button_label", typeof(UILabel)).text = btnGooglelabel
	self.btnLine_:ComponentByName("button_label", typeof(UILabel)).text = btnLinelabel
	self.btnGameCenter_:ComponentByName("button_label", typeof(UILabel)).text = btnGameCenterlabel
	self.btnApple_:ComponentByName("button_label", typeof(UILabel)).text = btnApplelabel

	self:changeSize()
end

function ModifyAccountWindow:changeSize()
	local totalH = 620
	local isRegister = self.curType_ == xyd.ModifyAccountWindowType.REGISTER

	if not UNITY_IOS and not XYDUtils.IsTest() then
		self.btnApple_:SetActive(false)
		self.btnGameCenter_:SetActive(false)

		totalH = 450

		if isRegister then
			-- Nothing
		end
	elseif not isRegister then
		self.btnApple_:SetActive(true)
		self.btnGameCenter_:SetActive(true)
	end

	self.mainWidget.height = totalH
end

function ModifyAccountWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnFacebook_).onClick = handler(self, self.onFacebookTouch)
	UIEventListener.Get(self.btnGoogle_).onClick = handler(self, self.onGoogleTouch)
	UIEventListener.Get(self.btnOther_).onClick = handler(self, self.onOtherTouch)
	UIEventListener.Get(self.btnLine_).onClick = handler(self, self.onLineTouch)
	UIEventListener.Get(self.btnGameCenter_).onClick = handler(self, self.onGameCenterTouch)
	UIEventListener.Get(self.btnApple_).onClick = handler(self, self.onAppleTouch)
	UIEventListener.Get(self.helpBtn).onClick = handler(self, self.onHelpTouch)

	UIEventListener.Get(self.deleteBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("delete_account_window", {})
	end
end

function ModifyAccountWindow:onFacebookTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT or self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.SdkManager.get():tpLogin("fb")
	else
		xyd.SdkManager.get():tpBind("fb")
	end
end

function ModifyAccountWindow:onGoogleTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT or self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.SdkManager.get():tpLogin("google")
	else
		xyd.SdkManager.get():tpBind("google")
	end
end

function ModifyAccountWindow:onAppleTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT or self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.SdkManager.get():tpLogin("appleLogin")
	else
		xyd.SdkManager.get():tpBind("apple")
	end
end

function ModifyAccountWindow:onOtherTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT then
		xyd.WindowManager.get():openWindow("login_up_window", {
			winType = xyd.LoginUpWindowType.SWITCH_ACCOUNT
		})
	elseif self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.WindowManager.get():openWindow("login_up_window", {
			winType = xyd.LoginUpWindowType.LOGIN
		})
	else
		xyd.WindowManager.get():openWindow("register_window")
	end
end

function ModifyAccountWindow:onLineTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT or self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.SdkManager.get():tpLogin("line")
	else
		xyd.SdkManager.get():tpBind("line")
	end
end

function ModifyAccountWindow:onGameCenterTouch()
	if self.curType_ == xyd.ModifyAccountWindowType.CHANGE_ACCOUNT or self.curType_ == xyd.ModifyAccountWindowType.LOGIN then
		xyd.SdkManager.get():tpLogin("gamecenter")
	else
		xyd.SdkManager.get():tpBind("agc")
	end
end

function ModifyAccountWindow:onHelpTouch()
	xyd.WindowManager.get():openWindow("help_window", {
		key = "ACCOUNT_HELP"
	})
end

return ModifyAccountWindow
