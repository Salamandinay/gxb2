local BaseWindow = import(".BaseWindow")
local ItemSellWindow = class("ItemSellWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local SoulEquip1 = import("app.models.SoulEquip1")
local SoulEquip2 = import("app.models.SoulEquip2")

function ItemSellWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.soulEquipInfo = params.soulEquipInfo
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
	self.imgGold = go:ComponentByName("main/bg06/imgGold", typeof(UISprite))
end

function ItemSellWindow:initUIComponent()
	local name = xyd.tables.itemTable:getName(self.itemID)
	self.labelName_.text = name
	self.btnSell_label.text = __("ITEM_SELL")

	if self.soulEquipInfo and self.soulEquipInfo.soulEquipID then
		if self.soulEquipInfo.soulEquipID and xyd.models.slot:getSoulEquip(self.soulEquipInfo.soulEquipID) then
			self.equip = xyd.models.slot:getSoulEquip(self.soulEquipInfo.soulEquipID)
			self.labelName_.color = xyd.getQualityColor(self.equip:getQlt())
			self.itemNum = 1
		else
			xyd.alertTips(__("ERROR"))
			self:close()
		end
	else
		xyd.labelQulityColor(self.labelName_, self.itemID)
	end

	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")

	self:initIcon()
	self:initTextInput()
end

function ItemSellWindow:initIcon()
	local params = {
		noClick = true,
		uiRoot = self.groupIcon_,
		itemID = self.itemID,
		soulEquipInfo = self.soulEquipInfo
	}
	self.icon = xyd.getItemIcon(params)
end

function ItemSellWindow:initTextInput()
	local function callback(num)
		self.curNum_ = num
		local prices = xyd.tables.itemTable:sellPrice(self.itemID)
		self.labelTotalVal_.text = tostring(xyd.getRoughDisplayNumber(num * prices[2]))

		xyd.setUISpriteAsync(self.imgGold, nil, xyd.tables.itemTable:getIcon(prices[1]))
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

	xyd.setUISpriteAsync(self.imgGold, nil, xyd.tables.itemTable:getIcon(prices[1]))
end

function ItemSellWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnSell_, self, self.sellTouch)
end

function ItemSellWindow:sellTouch()
	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		if self.equip then
			if self.equip:getIsLock() then
				xyd.alertTips(__("SOUL_EQUIP_LOCK_TIPS"))

				return
			end

			xyd.models.slot:reqSellSoulEquip({
				self.soulEquipInfo.soulEquipID
			}, function (items)
				if items and #items > 0 then
					xyd.itemFloat(items)
				end

				local wnd2 = xyd.getWindow("backpack_window")

				if wnd2 then
					wnd2.is_soulequip_first_data = true

					wnd2:onTabTouch(xyd.BackpackShowType.SOUL_EUQIP)
				end

				self:close()

				if xyd.WindowManager.get():isOpen("item_tips_window") then
					xyd.WindowManager.get():closeWindow("item_tips_window")
				end
			end)
		else
			xyd.models.backpack:sellItem(tonumber(self.itemID), self.curNum_)
			self:close()

			if xyd.WindowManager.get():isOpen("item_tips_window") then
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end
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
