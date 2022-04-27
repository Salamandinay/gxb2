local BaseWindow = import(".BaseWindow")
local ActivityRedeemCodeWindow = class("ActivityRedeemCodeWindow", BaseWindow)
local NewFirstRechargeTable = xyd.tables.newFirstRechargeTable

function ActivityRedeemCodeWindow:ctor(name, params)
	ActivityRedeemCodeWindow.super.ctor(self, name, params)
end

function ActivityRedeemCodeWindow:initWindow()
	self:getUIComponent()
	ActivityRedeemCodeWindow.super.initWindow(self)
	self:layout()
	self:updateRed()
	self:register()
end

function ActivityRedeemCodeWindow:getUIComponent()
	local mainGroup = self.window_:NodeByName("groupAction/mainGroup").gameObject
	self.label1 = mainGroup:ComponentByName("label1", typeof(UILabel))
	self.label3 = mainGroup:ComponentByName("label3", typeof(UILabel))
	self.label4 = mainGroup:ComponentByName("label4", typeof(UILabel))
	self.goBtn = mainGroup:NodeByName("goBtn").gameObject
	self.goBtnLabel = self.goBtn:ComponentByName("button_label", typeof(UILabel))
	self.copyBtn = mainGroup:NodeByName("copyBtn").gameObject
	self.textImg = mainGroup:ComponentByName("textImg", typeof(UISprite))
end

function ActivityRedeemCodeWindow:layout()
	self.label1.text = __("CDKEY_TEXT01") .. " :"
	self.label3.text = __("CDKEY_TEXT02")
	self.label4.text = __("CDKEY_TEXT03")
	self.goBtnLabel.text = __("CDKEY_TEXT04")

	xyd.setUISpriteAsync(self.textImg, nil, "activity_redeem_code_logo_" .. xyd.Global.lang)
end

function ActivityRedeemCodeWindow:updateRed()
	local timeDesc = os.date("!*t", xyd.getServerTime())
	local time = tostring(timeDesc.year) .. tostring(timeDesc.hour >= 8 and timeDesc.yday or timeDesc.yday - 1)
	local stamp = xyd.db.misc:getValue("activity_redeem_code")

	if not stamp or stamp ~= time then
		xyd.db.misc:setValue({
			key = "activity_redeem_code",
			value = time
		})
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_REDEEM_CODE, false)
end

function ActivityRedeemCodeWindow:register()
	ActivityRedeemCodeWindow.super.register(self)

	UIEventListener.Get(self.copyBtn).onClick = handler(self, function ()
		xyd.SdkManager:get():copyToClipboard("GXB222")
		xyd.showToast(__("COPY_SELF_ID_SUCCESSFUL"))
	end)
	UIEventListener.Get(self.goBtn).onClick = handler(self, function ()
		local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)

		if mapInfo and mapInfo.max_stage and mapInfo.max_stage < 11 then
			xyd.showToast(xyd.tables.errorInfoTextTable:getText(6051))
		else
			xyd.openWindow("setting_up_window", nil, function ()
				local wnd = xyd.openWindow("setting_up_award_window")
				wnd.textInput_.value = "GXB222"
			end)
		end

		xyd.closeWindow(self.name_)
	end)
end

function ActivityRedeemCodeWindow:willOpen()
	ActivityRedeemCodeWindow.super.willOpen(self)
end

function ActivityRedeemCodeWindow:didClose()
	ActivityRedeemCodeWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return ActivityRedeemCodeWindow
