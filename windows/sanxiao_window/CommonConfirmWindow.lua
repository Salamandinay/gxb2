local CommonConfirmWindow = class("CommonConfirmWindow", import(".BaseWindow"))

function CommonConfirmWindow:ctor(name, params)
	CommonConfirmWindow.super.ctor(self, name, params)

	self.callback = params.callback
	self.desc = params.desc
end

function CommonConfirmWindow:initWindow()
	CommonConfirmWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
end

function CommonConfirmWindow:getUIComponent()
	local winTrans = self.window_.transform
	self._desc = winTrans:ComponentByName("e:Skin/main_group/_desc", typeof(UILabel))
	self._confirmBtn = winTrans:NodeByName("e:Skin/main_group/group_btnconfirm").gameObject
	self._closeBtn = winTrans:NodeByName("e:Skin/main_group/group_close").gameObject
	self.btn_text = winTrans:ComponentByName("e:Skin/main_group/group_btnconfirm/btn_text", typeof(UILabel))
end

function CommonConfirmWindow:initUIComponent()
	xyd.setDarkenBtnBehavior(self._closeBtn, self, self.close)
	xyd.setDarkenBtnBehavior(self._confirmBtn, self, self._onConfirm)

	self._desc.text = self.desc
	self.btn_text.text = __("CONFIRM")
end

function CommonConfirmWindow:_onConfirm()
	if self.callback then
		self.callback()
	end

	self:close()
end

return CommonConfirmWindow
