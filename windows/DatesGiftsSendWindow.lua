local BaseWindow = import(".BaseWindow")
local DatesGiftsSendWindow = class("DatesGiftsSendWindow", BaseWindow)

function DatesGiftsSendWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.itemID = params.item_id or 0
	self.itemNum = params.item_num or 0
	self.itemTable = xyd.tables.itemTable
	self.curNum_ = 1
end

function DatesGiftsSendWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DatesGiftsSendWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelWinTitle = groupAction:ComponentByName("top/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("top/closeBtn").gameObject
	self.labelName = groupAction:ComponentByName("labelName", typeof(UILabel))
	self.groupIcon_ = groupAction:NodeByName("groupIcon_").gameObject
	self.selectNumNode_ = groupAction:NodeByName("selectNum_").gameObject
	self.btnSure = groupAction:NodeByName("btnSure").gameObject
end

function DatesGiftsSendWindow:layout()
	local name = self.itemTable:getName(self.itemID)
	self.labelName.text = name

	xyd.setBgColorType(self.btnSure, xyd.ButtonBgColorType.blue_btn_70_70)
	xyd.setBtnLabel(self.btnSure, {
		text = __("DATES_GIFTES_TIP01")
	})
	self:initIcon()
	self:initTextInput()
end

function DatesGiftsSendWindow:initIcon()
	local icon = xyd.getItemIcon({
		noClick = true,
		itemID = self.itemID,
		uiRoot = self.groupIcon_
	})
end

function DatesGiftsSendWindow:initTextInput()
	self.selectNum_ = require("app.components.SelectNum").new(self.selectNumNode_, "minmax")

	local function callback(num)
		self.curNum_ = num
	end

	self.selectNum_:setInfo({
		curNum = 1,
		maxNum = self.itemNum,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -320)
	self.selectNum_:setSelectBG(false)
	self.selectNum_:setSelectBG2(true)
	self.selectNum_:setInputLabel({
		color = 4294967295.0
	})
end

function DatesGiftsSendWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnSure).onClick = handler(self, self.sellTouch)
end

function DatesGiftsSendWindow:sellTouch()
	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		local wnd = xyd.WindowManager.get():getWindow("dates_window")

		if not wnd then
			return
		end

		wnd:sendDatesGifts(tonumber(self.itemID), self.curNum_)
		xyd.closeWindow(self.name_)

		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.closeWindow("item_tips_window")
		end
	end
end

return DatesGiftsSendWindow
