local DungeonBuyItemWindow = class("DungeonBuyItemWindow", import(".BaseWindow"))
local ResItem = import("app.components.ResItem")

function DungeonBuyItemWindow:ctor(name, params)
	DungeonBuyItemWindow.super.ctor(self, name, params)

	self.itemID_ = 0
	self.itemNum_ = 1
	self.callback = nil
	self.backpack = xyd.models.backpack
	self.cost_ = params.cost
	self.itemID_ = params.itemID
	self.itemNum_ = params.itemNum
	self.callback = params.callback
end

function DungeonBuyItemWindow:initWindow()
	DungeonBuyItemWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function DungeonBuyItemWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = main:ComponentByName("labelTitle_", typeof(UILabel))
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	local resCoinNode_ = main:NodeByName("resCoin_").gameObject
	self.groupIcon_ = main:NodeByName("groupIcon_").gameObject
	self.imgCoinIcon_ = main:ComponentByName("groupCost_/imgCoinIcon_", typeof(UISprite))
	self.labelCost_ = main:ComponentByName("groupCost_/labelCost_", typeof(UILabel))
	self.btnBuy_ = main:NodeByName("btnBuy_").gameObject
	self.resCoin_ = ResItem.new(resCoinNode_)
end

function DungeonBuyItemWindow:layout()
	self.labelTitle_.text = __("BUY")
	self.btnBuy_:ComponentByName("button_label", typeof(UILabel)).text = __("BUY")

	if self.backpack:getItemNumByID(self.cost_[1]) < self.cost_[2] then
		self.labelCost_.color = Color.New2(3422556671.0)
	end

	self.labelCost_.text = xyd.getRoughDisplayNumber(self.cost_[2])
	local icon = xyd.getItemIcon({
		itemID = self.itemID_,
		num = self.itemNum_,
		uiRoot = self.groupIcon_
	})

	self.resCoin_:setInfo({
		tableId = self.cost_[1]
	})
	self.resCoin_:hidePlus()
	xyd.setUISpriteAsync(self.imgCoinIcon_, nil, xyd.tables.itemTable:getIcon(self.cost_[1]))
end

function DungeonBuyItemWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.btnBuy_).onClick = handler(self, self.onBuyTouch)
end

function DungeonBuyItemWindow:onBuyTouch()
	local selfNum = self.backpack:getItemNumByID(self.cost_[1])

	if selfNum < self.cost_[2] then
		if self.cost_[1] == xyd.ItemID.MANA then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_MANA"))
		elseif self.cost_[1] == xyd.ItemID.CRYSTAL then
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))
		end

		return
	end

	if self.callback then
		self:callback()
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

return DungeonBuyItemWindow
