local RegisterWindow = class("RegisterWindow", import(".BaseWindow"))
local json = require("cjson")

function RegisterWindow:ctor(name, params)
	RegisterWindow.super.ctor(self, name, params)

	self.password_ = ""
	self.confirmedPassword_ = ""
end

function RegisterWindow:initWindow()
	RegisterWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function RegisterWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain_ = winTrans:NodeByName("groupMain_").gameObject
	self.closeBtn = self.groupMain_:NodeByName("closeBtn").gameObject
	self.btnLeft_ = self.groupMain_:NodeByName("btnLeft_").gameObject
	self.btnRight_ = self.groupMain_:NodeByName("btnRight_").gameObject
	self.labelTitle_ = self.groupMain_:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelAccount_ = self.groupMain_:ComponentByName("labelAccount_", typeof(UILabel))
	self.labelPassword_ = self.groupMain_:ComponentByName("labelPassword_", typeof(UILabel))
	self.labelConfirmedPassword_ = self.groupMain_:ComponentByName("labelConfirmedPassword_", typeof(UILabel))
	self.inputAccount_ = self.groupMain_:ComponentByName("inputAccount_", typeof(UILabel))
	self.inputPassword_ = self.groupMain_:ComponentByName("inputPassword_", typeof(UILabel))
	self.inputConfirmedPassword_ = self.groupMain_:ComponentByName("inputConfirmedPassword_", typeof(UILabel))

	xyd.addTextInput(self.inputAccount_, {
		limit = 50,
		type = xyd.TextInputArea.InputSingleLine
	})
	xyd.addTextInput(self.inputPassword_, {
		limit = 16,
		type = xyd.TextInputArea.InputSingleLine,
		inputType = UIInput.InputType.Password,
		callback = handler(self, self.onPswChange),
		getText = function ()
			return self.password_
		end
	})
	xyd.addTextInput(self.inputConfirmedPassword_, {
		limit = 16,
		type = xyd.TextInputArea.InputSingleLine,
		inputType = UIInput.InputType.Password,
		callback = handler(self, self.onConfirmedPswChange),
		getText = function ()
			return self.confirmedPassword_
		end
	})
end

function RegisterWindow:initUIComponent()
	self.labelTitle_.text = __("REGISTER_ACCOUNT")
	self.labelAccount_.text = __("SETTING_UP_USER_NAME")
	self.labelPassword_.text = __("SETTING_UP_PASSWORD")
	self.labelConfirmedPassword_.text = __("SETTING_UP_CONFIRM_PASSWORD")
	self.btnLeft_:ComponentByName("button_label", typeof(UILabel)).text = __("CANCEL")
	self.btnRight_:ComponentByName("button_label", typeof(UILabel)).text = __("REGISTER")
end

function RegisterWindow:register()
	RegisterWindow.super.register(self)

	UIEventListener.Get(self.btnLeft_).onClick = handler(self, self.onLeftTouch)
	UIEventListener.Get(self.btnRight_).onClick = handler(self, self.onRightTouch)
end

function RegisterWindow:onLeftTouch()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function RegisterWindow:onRightTouch()
	if not self.inputPassword_.text or self.inputPassword_.text == "" then
		xyd.alert(xyd.AlertType.TIPS, __("INPUT_NULL"))

		return
	end

	if not self.password_ or self.password_ == "" then
		xyd.alert(xyd.AlertType.TIPS, __("INPUT_NULL"))

		return
	end

	if not self.confirmedPassword_ or self.confirmedPassword_ == "" then
		xyd.alert(xyd.AlertType.TIPS, __("INPUT_NULL"))

		return
	end

	if self.password_ ~= self.confirmedPassword_ then
		xyd.alert(xyd.AlertType.TIPS, __("TWICE_NOT_SAME"))

		return
	end

	local szReg = "^%w+@%w+%.%w+$"
	local account = self.inputAccount_.text

	if string.match(account, szReg) then
		xyd.SdkManager.get():anonyUpgrade(account, self.password_, self.confirmedPassword_)
	else
		xyd.alert(xyd.AlertType.TIPS, __("ACCOUNT_INVALID"))

		return
	end
end

function RegisterWindow:onPswChange(isCancel)
	if isCancel then
		return
	end

	local newStr = self.inputPassword_.text
	self.password_ = newStr
	local str = ""

	for i = 1, #newStr do
		str = str .. "●"
	end

	self.inputPassword_.text = str
end

function RegisterWindow:onConfirmedPswChange(isCancel)
	if isCancel then
		return
	end

	local newStr = self.inputConfirmedPassword_.text
	self.confirmedPassword_ = newStr
	local str = ""

	for i = 1, #newStr do
		str = str .. "●"
	end

	self.inputConfirmedPassword_.text = str
end

return RegisterWindow
