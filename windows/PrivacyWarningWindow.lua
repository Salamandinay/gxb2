local PrivacyWarningWindow = class("PrivacyWarningWindow", import(".BaseWindow"))

function PrivacyWarningWindow:ctor(name, params)
	PrivacyWarningWindow.super.ctor(self, name, params)

	self.isSelect_ = false
end

function PrivacyWarningWindow:initWindow()
	PrivacyWarningWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function PrivacyWarningWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.btnConfirm_ = self.groupAction:NodeByName("btnConfirm").gameObject
	self.btnConfirmLabel_ = self.btnConfirm_:ComponentByName("label", typeof(UILabel))
	self.groupChoose_uiLayout = self.groupAction:ComponentByName("groupChoose", typeof(UILayout))
	self.chooseImg_ = self.groupAction:ComponentByName("groupChoose/chooseImg", typeof(UISprite))
	self.chooseLabel = self.groupAction:ComponentByName("groupChoose/label", typeof(UILabel))
	self.labelDesc_ = self.groupAction:ComponentByName("labelDesc_", typeof(UILabel))
end

function PrivacyWarningWindow:layout()
	self.labelTitle_.text = __("PRIVACY_WARNING_TEXT01")
	self.labelDesc_.text = __("PRIVACY_WARNING_TEXT02")
	self.btnConfirmLabel_.text = __("CONFIRM")
	self.chooseLabel.text = __("PRIVACY_WARNING_TEXT03")
end

function PrivacyWarningWindow:register()
	PrivacyWarningWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnConfirm_).onClick = handler(self, self.onConfirm)
	UIEventListener.Get(self.chooseImg_.gameObject).onClick = handler(self, self.onSelect)
end

function PrivacyWarningWindow:onConfirm()
	if self.isSelect_ then
		xyd.models.chat:setBlockWarning()

		local win = xyd.WindowManager.get():getWindow("chat_window")

		if win then
			win:setWarningVisible(0)
		end
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function PrivacyWarningWindow:onSelect()
	self.isSelect_ = not self.isSelect_

	if self.isSelect_ then
		xyd.setUISprite(self.chooseImg_, nil, "setting_up_pick")
	else
		xyd.setUISprite(self.chooseImg_, nil, "setting_up_unpick")
	end
end

return PrivacyWarningWindow
