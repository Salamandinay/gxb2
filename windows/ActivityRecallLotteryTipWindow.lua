local BaseWindow = import(".BaseWindow")
local ActivityRecallLotteryTipWindow = class("ActivityRecallLotteryTipWindow", BaseWindow)

function ActivityRecallLotteryTipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.winTitleText = params.winTitleText
	self.labelTipText = params.labelTipText
	self.labelCancelText = params.labelCancelText
	self.labelSureText = params.labelSureText
	self.imgUrl = params.imgUrl
	self.sureCallback = params.sureCallback
	self.cancelCallback = params.cancelCallback
	self.needCancelBtn = params.needCancelBtn

	if self.needCancelBtn == false then
		self.cancelCallback = self.sureCallback
	end
end

function ActivityRecallLotteryTipWindow:initWindow()
	self:getUIComponent()
	ActivityRecallLotteryTipWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityRecallLotteryTipWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject
	self.labelTip = groupMain:ComponentByName("labelTip", typeof(UILabel))
	self.imgStage = groupMain:ComponentByName("imgStage", typeof(UISprite))
	self.btnCancel = groupMain:NodeByName("btnCancel").gameObject
	self.labelCancel = self.btnCancel:ComponentByName("labelCancel", typeof(UILabel))
	self.btnSure = groupMain:NodeByName("btnSure").gameObject
	self.labelSure = self.btnSure:ComponentByName("labelSure", typeof(UILabel))
end

function ActivityRecallLotteryTipWindow:initUIComponent()
	self.labelTitle.text = self.winTitleText
	self.labelTip.text = self.labelTipText
	self.labelCancel.text = self.labelCancelText
	self.labelSure.text = self.labelSureText

	xyd.setUISpriteAsync(self.imgStage, nil, self.imgUrl, nil, , true)

	if self.needCancelBtn == false then
		self.btnCancel:SetActive(false)
		self.btnSure:X(0)
	end
end

function ActivityRecallLotteryTipWindow:register()
	ActivityRecallLotteryTipWindow.super.register(self)

	UIEventListener.Get(self.btnSure).onClick = function ()
		if self.sureCallback then
			self.sureCallback()
		end

		BaseWindow.close(self)
	end

	UIEventListener.Get(self.btnCancel).onClick = function ()
		if self.cancelCallback then
			self.cancelCallback()
		end

		BaseWindow.close(self)
	end
end

function ActivityRecallLotteryTipWindow:close()
	if self.cancelCallback then
		self.cancelCallback()
	end

	BaseWindow.close(self)
end

return ActivityRecallLotteryTipWindow
