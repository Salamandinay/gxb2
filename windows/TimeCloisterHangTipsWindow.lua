local TimeCloisterHangTipsWindow = class("TimeCloisterHangTipsWindow", import(".BaseWindow"))

function TimeCloisterHangTipsWindow:ctor(name, params)
	TimeCloisterHangTipsWindow.super.ctor(self, name, params)

	self.isSelect_ = false
end

function TimeCloisterHangTipsWindow:initWindow()
	TimeCloisterHangTipsWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function TimeCloisterHangTipsWindow:getUIComponent()
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

function TimeCloisterHangTipsWindow:layout()
	self.labelTitle_.text = __("PRIVACY_WARNING_TEXT01")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.labelDesc_.fontSize = 16
	end

	if xyd.Global.lang == "ko_kr" then
		self.labelDesc_.width = 500
	end

	if xyd.Global.lang == "de_de" then
		self.labelDesc_.fontSize = 18
	end

	self.labelDesc_.text = __("TIME_CLOISTER_TEXT08")
	self.btnConfirmLabel_.text = __("CONFIRM")
	self.chooseLabel.text = __("PRIVACY_WARNING_TEXT03")

	if xyd.Global.lang == "fr_fr" then
		self.chooseLabel.fontSize = 24
	end
end

function TimeCloisterHangTipsWindow:register()
	TimeCloisterHangTipsWindow.super.register(self)

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnConfirm_).onClick = handler(self, self.onConfirm)
	UIEventListener.Get(self.chooseImg_.gameObject).onClick = handler(self, self.onSelect)
end

function TimeCloisterHangTipsWindow:onConfirm()
	if self.isSelect_ then
		xyd.db.misc:setValue({
			value = 1,
			key = "time_cloister_hang_tips"
		})
	end

	self.params_.callback()
	xyd.WindowManager.get():closeWindow(self.name_)
end

function TimeCloisterHangTipsWindow:onSelect()
	self.isSelect_ = not self.isSelect_

	if self.isSelect_ then
		xyd.setUISprite(self.chooseImg_, nil, "setting_up_pick")
	else
		xyd.setUISprite(self.chooseImg_, nil, "setting_up_unpick")
	end
end

return TimeCloisterHangTipsWindow
