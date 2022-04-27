local AgreementChooseWindow = class("AgreementChooseWindow", import(".BaseWindow"))

function AgreementChooseWindow:ctor(name, params)
	AgreementChooseWindow.super.ctor(self, name, params)
end

function AgreementChooseWindow:initWindow()
	AgreementChooseWindow.super.initWindow(self)
	self:getUIComponent()
	AgreementChooseWindow.super.register(self)
	self:initUIComponent()
	self:registerEvent()
end

function AgreementChooseWindow:registerEvent()
	UIEventListener.Get(self.btn1).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("agreement_window", {
			type = 1
		})
	end)
	UIEventListener.Get(self.btn2).onClick = handler(self, function ()
		xyd.SdkManager.get():openBrowser(__("TERMS_SERVICE_URL"))
	end)
	UIEventListener.Get(self.btn3).onClick = handler(self, function ()
		xyd.SdkManager.get():openBrowser(__("PRIVACY_POLICY_URL"))
	end)
end

function AgreementChooseWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupAction/labelTitle", typeof(UILabel))
	self.labelText01_ = winTrans:ComponentByName("groupAction/labelText01_", typeof(UILabel))
	self.btn1 = winTrans:NodeByName("groupAction/btn1").gameObject
	self.btn2 = winTrans:NodeByName("groupAction/btn2").gameObject
	self.btn3 = winTrans:NodeByName("groupAction/btn3").gameObject
	self.btn1Label = winTrans:ComponentByName("groupAction/btn1/button_label", typeof(UILabel))
	self.btn2Label = winTrans:ComponentByName("groupAction/btn2/button_label", typeof(UILabel))
	self.btn3Label = winTrans:ComponentByName("groupAction/btn3/button_label", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupAction/closeBtn").gameObject
end

function AgreementChooseWindow:initUIComponent()
	self.labelTitle_.text = __("SETTING_UP_AGREEMENT")
	self.labelText01_.text = __("AGREEMENT_CHOOSE_TEXT02")
	self.btn1Label.text = __("AGREEMENT_CHOOSE_TEXT03")
	self.btn2Label.text = __("AGREEMENT_CHOOSE_TEXT04")
	self.btn3Label.text = __("AGREEMENT_CHOOSE_TEXT05")
end

return AgreementChooseWindow
