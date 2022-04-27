local BaseWindow = import(".BaseWindow")
local ItemSellWindow = class("ItemSellWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function ItemSellWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.curNum_ = 1
end

function ItemSellWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function ItemSellWindow:getUIComponent()
	local go = self.window_
	self.groupIcon_ = go:NodeByName("main/groupIcon_").gameObject
	self.selectNumPos = go:NodeByName("main/selectNumPos").gameObject
	self.btnSell_ = go:NodeByName("main/btnSell_").gameObject
	self.btnSell_label = go:ComponentByName("main/btnSell_/button_label", typeof(UILabel))
	self.labelName_ = go:ComponentByName("main/labelName_", typeof(UILabel))
	self.labelTotalVal_ = go:ComponentByName("main/bg06/labelTotalVal_", typeof(UILabel))
end

function ItemSellWindow:initUIComponent()
	local name = xyd.tables.itemTable:getName(self.itemID)
	self.labelName_.text = name
	self.btnSell_label.text = __("ITEM_SELL")

	xyd.labelQulityColor(self.labelName_, self.itemID)

	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")

	self:initIcon()
	self:initTextInput()
end

function ItemSellWindow:initIcon()
	local params = {
		noClick = true,
		uiRoot = self.groupIcon_,
		itemID = self.itemID
	}
	self.icon = xyd.getItemIcon(params)
end

function ItemSellWindow:initTextInput()
	local function callback(num)
		self.curNum_ = num
		local prices = xyd.tables.itemTable:sellPrice(self.itemID)
		self.labelTotalVal_.text = tostring(xyd.getRoughDisplayNumber(num * prices[2]))
	end

	self.selectNum_:setInfo({
		maxNum = self.itemNum,
		curNum = self.itemNum,
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setPrompt(self.itemNum)
	self.selectNum_:setKeyboardPos(0, -350)

	local prices = xyd.tables.itemTable:sellPrice(self.itemID)
	self.labelTotalVal_.text = tostring(xyd.getRoughDisplayNumber(self.curNum_ * prices[2]))
end

function ItemSellWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnSell_, self, self.sellTouch)
end

function ItemSellWindow:sellTouch()
	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		xyd.models.backpack:sellItem(tonumber(self.itemID), self.curNum_)
		self:close()

		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end
	end
end

function ItemSellWindow:getItemId()
	return self.itemID
end

function ItemSellWindow:getItemNum()
	return self.itemNum
end

function ItemSellWindow:getCurNum()
	return self.curNum_
end

return ItemSellWindow
