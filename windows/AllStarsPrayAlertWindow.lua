local AllStarsPrayAlertWindow = class("AllStarsPrayAlertWindow", import(".AlertWindow"))

function AllStarsPrayAlertWindow:ctor(name, params)
	AllStarsPrayAlertWindow.super.ctor(self, name, params)

	self.confirmText = params.confirmText or __("YES")
	self.cancelText = params.cancelText or __("NO")
end

function AllStarsPrayAlertWindow:setupButtons()
	AllStarsPrayAlertWindow.super.setupButtons(self)

	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = self.confirmText
	self.btnCancel_:ComponentByName("button_label", typeof(UILabel)).text = self.cancelText
end

return AllStarsPrayAlertWindow
