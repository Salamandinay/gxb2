local DelectAccountWindow = class("DelectAccountWindow", import(".BaseWindow"))

function DelectAccountWindow:ctor(name, params)
	DelectAccountWindow.super.ctor(self, name, params)
end

function DelectAccountWindow:initWindow()
	DelectAccountWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function DelectAccountWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.descLabel_ = winTrans:ComponentByName("scrollView/label", typeof(UILabel))
	self.btnDelete_ = winTrans:NodeByName("btnDelete").gameObject
	self.btnDeleteLabel_ = winTrans:ComponentByName("btnDelete/label", typeof(UILabel))
end

function DelectAccountWindow:layout()
	self.titleLabel_.text = __("DELETE_ACCOUNT_TEXT01")
	self.btnDeleteLabel_.text = __("DELETE_ACCOUNT_TEXT02")
	self.descLabel_.text = __("DELETE_ACCOUNT_TEXT08")

	self.scrollView_:ResetPosition()
end

function DelectAccountWindow:setGrey()
	xyd.setEnabled(self.btnDelete_, false)
end

function DelectAccountWindow:register()
	UIEventListener.Get(self.btnDelete_).onClick = function ()
		xyd.WindowManager.get():openWindow("delete_warning_window", {})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		self:close()
	end
end

return DelectAccountWindow
