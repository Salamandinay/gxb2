local BaseWindow = import(".BaseWindow")
local SettingUpAwardWindow = class("SettingUpAwardWindow", BaseWindow)

function SettingUpAwardWindow:ctor(name, params)
	SettingUpAwardWindow.super.ctor(self, name, params)
end

function SettingUpAwardWindow:getUIComponent()
	local groupAction = self.window_.transform:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = groupAction:ComponentByName("labelDesc_", typeof(UILabel))
	self.textInput_ = groupAction:ComponentByName("editGroup/input", typeof(UIInput))
	self.editLabel = groupAction:ComponentByName("editGroup/label", typeof(UILabel))
	self.btnSure_ = groupAction:NodeByName("btnSure_").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.textInput_.value = ""
	self.textInput_.defaultText = ""
	self.editLabel.text = ""
end

function SettingUpAwardWindow:initWindow()
	SettingUpAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function SettingUpAwardWindow:layout()
	self.labelTitle_.text = __("SETTING_UP_AWARD_1")
	self.labelDesc_.text = __("SETTING_UP_AWARD_5")
	self.btnSure_:ComponentByName("button_label", typeof(UILabel)).text = __("SETTING_UP_AWARD_4")
end

function SettingUpAwardWindow:registerEvent()
	SettingUpAwardWindow.super.register(self)

	UIEventListener.Get(self.btnSure_).onClick = handler(self, self.onSureTouch)

	self.eventProxy_:addEventListener(xyd.event.GET_GIFTCODE_AWARD, handler(self, self.onSuccess))
end

function SettingUpAwardWindow:onSureTouch()
	local str = self.textInput_.value

	if #str <= 0 then
		return
	end

	if str == "yuanmeng is rio2685" then
		xyd.Global.useNewPayment = true

		xyd.alertTips("Turn On~")

		return
	elseif str == "yuanmeng is not rio7349" then
		xyd.Global.useNewPayment = false

		xyd.alertTips("Turn Off!")

		return
	end

	local msg = messages_pb.get_giftcode_award_req()
	msg.code = str

	xyd.Backend.get():request(xyd.mid.GET_GIFTCODE_AWARD, msg)

	self.textInput_.value = ""
	self.editLabel.text = ""
end

function SettingUpAwardWindow:onSuccess(event)
	xyd.alertItems(event.data.items)
end

return SettingUpAwardWindow
