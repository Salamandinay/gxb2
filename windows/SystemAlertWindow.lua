xyd = xyd or {}
local SYSTEM_ALERT_WINDOW_NAME = "system_alert_window"

function xyd.systemAlert(alertType, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
	local params = {
		alertType = alertType,
		message = message,
		callback = callback,
		closeCallBack = closeCallback,
		confirmText = confirmText,
		noClose = noClose,
		cost = cost,
		title = title,
		tipsInitY_ = tipsInitY_
	}

	if xyd.WindowManager.get():getWindow(SYSTEM_ALERT_WINDOW_NAME) then
		xyd.WindowManager.get():closeWindow(SYSTEM_ALERT_WINDOW_NAME)
	end

	return xyd.WindowManager.get():openWindow(SYSTEM_ALERT_WINDOW_NAME, params)
end

function xyd.systemAlertTips(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
	xyd.systemAlert(xyd.AlertType.TIPS, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
end

function xyd.systemAlertYesNo(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
	xyd.systemAlert(xyd.AlertType.YES_NO, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
end

function xyd.systemAlertConfirm(message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
	xyd.systemAlert(xyd.AlertType.CONFIRM, message, callback, confirmText, noClose, cost, title, tipsInitY_, closeCallback)
end

local SystemAlertWindow = class("SystemAlertWindow", import("app.windows.AlertWindow"))

function SystemAlertWindow:ctor(name, params)
	SystemAlertWindow.super.ctor(self, name, params)
end

function SystemAlertWindow:setupButtons()
	SystemAlertWindow.super.setupButtons(self)
	self.closeBtn:SetActive(false)
end

function SystemAlertWindow:closeTips()
	local wnd = xyd.WindowManager.get():getWindow(SYSTEM_ALERT_WINDOW_NAME)

	if wnd and wnd:getType() == xyd.AlertType.TIPS then
		xyd.WindowManager.get():closeWindow(SYSTEM_ALERT_WINDOW_NAME)
	end
end

return SystemAlertWindow
