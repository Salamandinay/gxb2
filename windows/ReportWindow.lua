local ReportWindow = class("ReportWindow", import(".BaseWindow"))

function ReportWindow:ctor(name, params)
	ReportWindow.super.ctor(self, name, params)

	self.data_ = params.data
end

function ReportWindow:initWindow()
	ReportWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
end

function ReportWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.winTitle_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.cancelBtn_ = winTrans:NodeByName("cancelBtn").gameObject
	self.cancelLabel_ = winTrans:ComponentByName("cancelBtn/label", typeof(UILabel))
	self.applyBtn_ = winTrans:NodeByName("applyBtn").gameObject
	self.applyLabel_ = winTrans:ComponentByName("applyBtn/label", typeof(UILabel))
	local selectGroup = winTrans:NodeByName("groupSelect")

	for i = 1, 6 do
		self["itemR_" .. i] = selectGroup:NodeByName("itemR_" .. i).gameObject
		self["itemR_Label" .. i] = self["itemR_" .. i]:ComponentByName("label", typeof(UILabel))
		self["itemR_iconSelect" .. i] = self["itemR_" .. i]:NodeByName("iconSelect").gameObject
	end
end

function ReportWindow:layout()
	self.winTitle_.text = __("REPORT")
	self.cancelLabel_.text = __("PROPHET_BTN_CANCEL")
	self.applyLabel_.text = __("REPORT")
	self.selectType = xyd.Report_Type.ADVERTISE

	for i = 1, 6 do
		self["itemR_Label" .. i].text = __("REPORT_TEXT_" .. i)

		UIEventListener.Get(self["itemR_" .. i]).onClick = function ()
			self:onSelect(i)
		end
	end

	UIEventListener.Get(self.cancelBtn_).onClick = function ()
		xyd.SoundManager.get():playSound(xyd.SoundID.CLOSED)
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.applyBtn_).onClick = handler(self, self.onReport)

	self:updateSelectState()
end

function ReportWindow:updateSelectState()
	for i = 1, 6 do
		self["itemR_iconSelect" .. i]:SetActive(i == self.selectType)
	end
end

function ReportWindow:onSelect(idx)
	if idx ~= self.selectType then
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		self.selectType = idx

		self:updateSelectState()
	end
end

function ReportWindow:onReport()
	if not self.data_.hasReported then
		local message = xyd.models.chat:createReportMessage(self.data_)

		xyd.models.chat:reportMessage(self.data_.sender_id, self.selectType, message)
		xyd.alertTips(__("REPORT_SUCCESS"))
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		xyd.EventDispatcher.inner():dispatchEvent({
			name = xyd.event.REPORT_MESSAGE
		})
		xyd.alertTips(__("REPORT_SUCCESS"))
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return ReportWindow
