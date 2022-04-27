local BaseWindow = import(".BaseWindow")
local OtherWindow = class("OtherWindow", BaseWindow)

function OtherWindow:ctor(name, params)
	OtherWindow.super.ctor(self, name, params)
end

function OtherWindow:initWindow()
	OtherWindow.super.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function OtherWindow:getUIComponent()
	local win = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle_ = win:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = win:NodeByName("closeBtn").gameObject
	self.numTipsBtn = win:NodeByName("numTipsBtn").gameObject
	self.numTipsBtnLabel = self.numTipsBtn:ComponentByName("button_label", typeof(UILabel))
	self.battleReportBtn = win:NodeByName("battleReportBtn").gameObject
	self.battleReportBtnLabel = self.battleReportBtn:ComponentByName("button_label", typeof(UILabel))
	self.fpsBtn = win:NodeByName("fpsBtn").gameObject
	self.fpsBtnLabel = self.fpsBtn:ComponentByName("button_label", typeof(UILabel))
	self.floatMessageBtn = win:NodeByName("floatMessageBtn").gameObject
	self.floatMessageBtnLabel = self.floatMessageBtn:ComponentByName("button_label", typeof(UILabel))
end

function OtherWindow:initLayout()
	self.labelTitle_.text = __("SETTING_UP_OTHER")
	self.numTipsBtnLabel.text = __("SELECT_BATTLE_NUM_BUTTON")
	self.battleReportBtnLabel.text = __("SETTING_UP_BATTLE_RESULT")
	self.fpsBtnLabel.text = __("SETTING_UP_FPS_TITLE")
	self.floatMessageBtnLabel.text = __("SETTING_UP_NOTICE_TITLE")
end

function OtherWindow:registerEvent()
	OtherWindow.super.register(self)

	UIEventListener.Get(self.numTipsBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("select_battle_num_window")
	end

	UIEventListener.Get(self.battleReportBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("setting_up_battle_result_window")
	end

	UIEventListener.Get(self.fpsBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("setting_up_fps_window")
	end

	UIEventListener.Get(self.floatMessageBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("setting_up_float_message_window")
	end
end

return OtherWindow
