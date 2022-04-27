local BaseWindow = import(".BaseWindow")
local AlertItemsWithDesWindow = class("AlertItemsWithDesWindow", BaseWindow)

function AlertItemsWithDesWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.title = params.title or __("AWARD_ITEM")
	self.des = params.des
	self.items = params.items
	self.callback = params.callback
end

function AlertItemsWithDesWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function AlertItemsWithDesWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel_ = groupAction:ComponentByName("titleLabel_", typeof(UILabel))
	self.desLabel_ = groupAction:ComponentByName("desLabel_", typeof(UILabel))
	self.itemGroup = groupAction:NodeByName("itemGroup").gameObject
	self.sureBtn = groupAction:NodeByName("sureBtn").gameObject
end

function AlertItemsWithDesWindow:initUIComponent()
	self.titleLabel_.text = self.title
	self.desLabel_.text = self.des
	self.sureBtn:ComponentByName("button_label", typeof(UILabel)).text = __("SURE_2")

	for i = 1, #self.items do
		local item = self.items[i]

		xyd.getItemIcon({
			hideText = true,
			scale = 0.7,
			uiRoot = self.itemGroup,
			itemID = item.item_id,
			num = item.item_num
		})
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function AlertItemsWithDesWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.sureBtn).onClick = function ()
		self:onClickCloseButton()
	end
end

return AlertItemsWithDesWindow
