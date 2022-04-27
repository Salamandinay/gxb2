local BaseWindow = import(".BaseWindow")
local SproutsAwardSelectWindow = class("SproutsAwardSelectWindow", BaseWindow)
local SproutsAwardSelectItem = class("SproutsAwardSelectItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function SproutsAwardSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selectedItemId = nil
	self.selectedItemIcon = nil
	self.award = params.award
	self.id = params.id
end

function SproutsAwardSelectWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.sureBtn = groupAction:NodeByName("sureBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.selectItem = groupAction:NodeByName("scroller/award_select_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.selectItem, SproutsAwardSelectItem, self)
end

function SproutsAwardSelectWindow:layout()
	self.labelTitle.text = __("SELECT_AWARD_PLEASE")
	self.sureBtn:ComponentByName("button_label", typeof(UILabel)).text = __("SURE")
end

function SproutsAwardSelectWindow:initItemGroup()
	self.wrapContent:setInfos(self.award, {})
end

function SproutsAwardSelectWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.sureBtn).onClick = handler(self, self.onSureBtn)
end

function SproutsAwardSelectWindow:initWindow()
	SproutsAwardSelectWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItemGroup()
	self:register()
end

function SproutsAwardSelectWindow:onSureBtn()
	if self.selectedItemId ~= nil then
		local msg = messages_pb.activity_sprouts_select_award_req()
		msg.activity_id = xyd.ActivityID.SPROUTS
		msg.table_id = self.id
		msg.select_index = self:getOptionIndex(self.selectedItemId)

		xyd.Backend.get():request(xyd.mid.ACTIVITY_SPROUTS_SELECT_AWARD, msg)
		xyd.WindowManager.get():closeWindow(self.window_.name)
	else
		xyd.alert(xyd.AlertType.TIPS, __("NO_SELECT_AWARD"))
	end
end

function SproutsAwardSelectWindow:getOptionIndex(chosenId)
	for count = 1, #self.award do
		if self.award[count][1] == chosenId then
			return count
		end
	end
end

function SproutsAwardSelectItem:ctor(go, parent)
	SproutsAwardSelectItem.super.ctor(self, go, parent)

	self.icon = self.go:NodeByName("icon").gameObject
	self.itemIcon = nil
end

function SproutsAwardSelectItem:updateInfo()
	if self.itemIcon == nil then
		self.itemIcon = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.icon,
			itemID = self.data[1],
			num = self.data[2]
		})
		UIEventListener.Get(self.itemIcon:getGameObject()).onClick = handler(self, self.onSelectItem)

		UIEventListener.Get(self.itemIcon:getGameObject()).onLongPress = function ()
			xyd.openWindow("award_item_tips_window", {
				itemID = self.data[1],
				itemNum = self.data[2],
				wndType = xyd.ItemTipsWndType.OPTIONAL_CHEST
			})
		end

		self.itemIcon:setDragScrollView()
	end

	self:updateSelect()
end

function SproutsAwardSelectItem:updateSelect()
	if self.parent.selectedItemId and self.parent.selectedItemId == self.data[1] then
		self.itemIcon:setChoose(true)
	else
		self.itemIcon:setChoose(false)
	end
end

function SproutsAwardSelectItem:onSelectItem()
	if self.parent.selectedItemId ~= nil and self.parent.selectedItemId == self.data[1] then
		self.itemIcon:setChoose(false)

		self.parent.selectedItemId = nil
		self.parent.selectedItemIcon = nil
	else
		self.parent.selectedItemId = self.data[1]

		self.itemIcon:setChoose(true)

		if self.parent.selectedItemIcon ~= nil then
			self.parent.selectedItemIcon:setChoose(false)
		end

		self.parent.selectedItemIcon = self.itemIcon
	end
end

return SproutsAwardSelectWindow
