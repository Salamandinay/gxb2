local BaseWindow = import(".BaseWindow")
local DatesAlertWindow = class("DatesAlertWindow", BaseWindow)

function DatesAlertWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = params.callback
	self.noClose = params.noClose
end

function DatesAlertWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setupButtons()
	self:registerEvent()
	self:layout()
end

function DatesAlertWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.btnCancel = groupAction:NodeByName("btnCancel").gameObject
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.labelDesc_ = groupAction:ComponentByName("labelDesc_", typeof(UILabel))
	self.groupIcon = groupAction:NodeByName("groupIcon").gameObject
end

function DatesAlertWindow:layout()
	local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.DATES_RING)
	local icon = xyd.getItemIcon({
		itemID = xyd.ItemID.DATES_RING,
		num = num,
		uiRoot = self.groupIcon
	})
	self.labelDesc_.text = __("DATES_TEXT23")
	self.labelTitle_.text = __("TIPS")
end

function DatesAlertWindow:registerEvent()
	UIEventListener.Get(self.btnSure).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnCancel).onClick = handler(self, self.cancelTouch)
end

function DatesAlertWindow:sureTouch()
	if not self.noClose then
		xyd.closeWindow(self.name_)
	end

	if self.callback then
		self.callback(true)
	end
end

function DatesAlertWindow:cancelTouch()
	if not self.noClose then
		xyd.closeWindow(self.name_)
	end

	if self.callback then
		self.callback(false)
	end
end

function DatesAlertWindow:setupButtons()
	xyd.setBtnLabel(self.btnSure, {
		text = __("YES")
	})
	xyd.setBtnLabel(self.btnCancel, {
		text = __("NO")
	})
end

return DatesAlertWindow
