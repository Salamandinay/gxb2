local AgreementWindow = class("AgreementWindow", import(".BaseWindow"))

function AgreementWindow:ctor(name, params)
	AgreementWindow.super.ctor(self, name, params)

	self.type_ = params.type
end

function AgreementWindow:initWindow()
	AgreementWindow.super.initWindow(self)
	self:getUIComponent()
	AgreementWindow.super.register(self)
	self:initUIComponent()
end

function AgreementWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("main/labelTitle", typeof(UILabel))
	self.labelText01_ = winTrans:ComponentByName("main/scrollview/labelText01", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("main/closeBtn").gameObject
end

function AgreementWindow:initUIComponent()
	if self.type_ == 1 then
		self.labelTitle_.text = __("AGREEMENT_CHOOSE_TEXT03")
		self.labelText01_.text = __("AGREEMENT_TEXT02")
	end
end

return AgreementWindow
