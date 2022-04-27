local NewbeeFundPopupWindow = class("NewbeeFundPopupWindow", import(".BaseWindow"))

function NewbeeFundPopupWindow:ctor(name, params)
	NewbeeFundPopupWindow.super.ctor(self, name, params)
	xyd.db.misc:setValue({
		key = "newbee_fund_popup_check",
		value = xyd.getServerTime()
	})
end

function NewbeeFundPopupWindow:initWindow()
	self:getUIComponent()

	self.buyBtnLabel_.text = __("BUY")
	self.descLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT02")

	if xyd.Global.lang then
		self.descLabel_.fontSize = 20
	end
end

function NewbeeFundPopupWindow:playOpenAnimation(callback)
	NewbeeFundPopupWindow.super.playOpenAnimation(self, function ()
		self:waitForTime(1, function ()
			self.maskImg_:SetActive(false)
		end)

		if callback then
			callback()
		end
	end)
end

function NewbeeFundPopupWindow:getUIComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.bgImg_ = goTrans:ComponentByName("bgImg", typeof(UISprite))
	self.maskImg_ = goTrans:NodeByName("maskImg").gameObject

	self.maskImg_:SetActive(true)

	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.descLabel_ = goTrans:ComponentByName("descLabel", typeof(UILabel))

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
		xyd.WindowManager.get():openWindow("activity_window", {
			activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_NEWBEE_FUND)
		})
	end

	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_newbee_fund_popup_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.bgImg_, nil, "activity_newbee_fund_popup_bg", nil, , true)
end

function NewbeeFundPopupWindow:didClose()
	NewbeeFundPopupWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return NewbeeFundPopupWindow
