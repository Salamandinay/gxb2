local BaseWindow = import(".BaseWindow")
local DatesAlertWindow = class("DatesAlertWindow", BaseWindow)

function DatesAlertWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.callback = params.callback
	self.noClose = params.noClose
	self.title_ = params.title
	self.desc_ = params.desc
	self.itemInfo_ = params.itemInfo
	self.itemYPos_ = params.itemPos
	self.descYPos_ = params.descPos
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
	self.iconLayout = groupAction:ComponentByName("groupIcon", typeof(UILayout))
end

function DatesAlertWindow:layout()
	if not self.itemInfo_ then
		local num = xyd.models.backpack:getItemNumByID(xyd.ItemID.DATES_RING)
		local icon = xyd.getItemIcon({
			itemID = xyd.ItemID.DATES_RING,
			num = num,
			uiRoot = self.groupIcon
		})
	else
		for _, item in ipairs(self.itemInfo_) do
			xyd.getItemIcon({
				num = item[2],
				itemID = item[1],
				uiRoot = self.groupIcon,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end

		self.iconLayout:Reposition()
	end

	self.labelDesc_.text = self.desc_ or __("DATES_TEXT23")
	self.labelTitle_.text = self.title_ or __("TIPS")

	if self.descYPos_ then
		self.labelDesc_.transform:Y(self.descYPos_)
	end

	if self.itemYPos_ then
		self.groupIcon.transform:Y(self.itemYPos_)
	end
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
