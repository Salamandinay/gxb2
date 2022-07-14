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
	self.scrollViewFr_ = winTrans:ComponentByName("scrollViewFr", typeof(UIScrollView))
	self.ListContainer = winTrans:NodeByName("scrollViewFr/ListContainer").gameObject
	self.ListContainerTable = self.ListContainer:GetComponent(typeof(UITable))
	self.listLabel = self.ListContainer:NodeByName("label").gameObject
end

function DelectAccountWindow:layout()
	self.titleLabel_.text = __("DELETE_ACCOUNT_TEXT01")
	self.btnDeleteLabel_.text = __("DELETE_ACCOUNT_TEXT02")
	self.descLabel_.text = __("DELETE_ACCOUNT_TEXT08")

	if xyd.Global.lang == "fr_fr" then
		self.scrollView_.gameObject:SetActive(false)
		self.scrollViewFr_.gameObject:SetActive(true)

		local str_list = xyd.split(xyd.tables.translationTable:translate("DELETE_ACCOUNT_TEXT14"), "|")

		if not str_list or #str_list <= 0 then
			return
		end

		for _, str in ipairs(str_list) do
			local labelObj = NGUITools.AddChild(self.ListContainer, self.listLabel)
			local label = labelObj:GetComponent(typeof(UILabel))
			label.text = str
		end

		self.ListContainerTable:Reposition()
		self.scrollViewFr_:ResetPosition()
	end

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
