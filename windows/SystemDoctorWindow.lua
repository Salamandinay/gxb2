local BaseWindow = import(".BaseWindow")
local SystemDoctorWindow = class("SystemDoctorWindow", BaseWindow)

function SystemDoctorWindow:ctor(name, params)
	SystemDoctorWindow.super.ctor(self, name, params)

	self.skinName = "SystemDoctorWindowSkin"
end

function SystemDoctorWindow:initWindow()
	SystemDoctorWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function SystemDoctorWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.labelTitle_ = self.groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.btnRepair_ = self.groupAction:NodeByName("btnRepair_").gameObject
	self.btnRepairLabel = self.btnRepair_:ComponentByName("button_label", typeof(UILabel))
	self.btnNetwork_ = self.groupAction:NodeByName("btnNetwork_").gameObject
	self.btnNetworkLabel = self.btnNetwork_:ComponentByName("button_label", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
end

function SystemDoctorWindow:layout()
	self.labelTitle_.text = __("GAME_CHECK")
	self.btnRepairLabel.text = __("GAME_REPAIR")
	self.btnNetworkLabel.text = __("GAME_NETWORK_CHECK")
end

function SystemDoctorWindow:registerEvent()
	SystemDoctorWindow.super.register(self)

	UIEventListener.Get(self.btnRepair_).onClick = handler(self, self.onRepairTouch)
	UIEventListener.Get(self.btnNetwork_).onClick = handler(self, self.onNetworkTouch)
end

function SystemDoctorWindow:onRepairTouch()
	xyd.openWindow("system_repair_doctor_window")
end

function SystemDoctorWindow:onNetworkTouch()
	xyd.openWindow("network_doctor_window")
end

return SystemDoctorWindow
