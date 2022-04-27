local DungeonShopTable = xyd.tables.dungeonShopTable
local DungeonShopItem = class("DungeonShopItem")

function DungeonShopItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()

	self.dungeon = xyd.models.dungeon
	self.backpack = xyd.models.backpack
end

function DungeonShopItem:getGameObject()
	return self.go
end

function DungeonShopItem:initUI()
	self.groupIcon_ = self.go:NodeByName("groupIcon_").gameObject
	self.btnBuy_ = self.go:NodeByName("btnBuy_").gameObject
	self.labelNum_ = self.go:ComponentByName("labelNum_", typeof(UILabel))
	self.labelCost_ = self.btnBuy_:ComponentByName("labelCost_", typeof(UILabel))
	self.imgIcon = self.btnBuy_:ComponentByName("imgIcon", typeof(UISprite))
	self.btnBuy_:ComponentByName("button_label", typeof(UILabel)).text = __("BUY")

	xyd.setDragScrollView(self.btnBuy_, self.parent.scrollView)
end

function DungeonShopItem:registerEvent()
	UIEventListener.Get(self.btnBuy_).onClick = handler(self, self.buyItem)
end

function DungeonShopItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function DungeonShopItem:updateInfo()
	NGUITools.DestroyChildren(self.groupIcon_.transform)

	local icon = xyd.getItemIcon({
		show_has_num = true,
		itemID = self.data.item[1],
		num = self.data.item[2],
		uiRoot = self.groupIcon_,
		dragScrollView = self.parent.scrollView
	})
	local cost = DungeonShopTable:getCost(self.data.id)

	xyd.setUISpriteAsync(self.imgIcon, nil, "icon_" .. tostring(cost[1]))

	self.labelCost_.text = xyd.getRoughDisplayNumber(cost[2])
	self.labelNum_.text = __("SKIN_TEXT11", #self.data.index)
end

function DungeonShopItem:buyItem()
	local cost = DungeonShopTable:getCost(self.data.id)
	local mana = self.backpack:getMana()
	local crystal = self.backpack:getCrystal()

	if cost[1] == xyd.ItemID.MANA and mana < tonumber(cost[2]) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_MANA"))

		return
	end

	if cost[1] == xyd.ItemID.CRYSTAL and crystal < tonumber(cost[2]) then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))

		return
	end

	if self.data then
		xyd.WindowManager.get():openWindow("item_buy_window", {
			hide_min_max = false,
			show_item_num = true,
			item_no_click = false,
			cost = cost,
			max_num = #self.data.index,
			itemParams = {
				itemID = self.data.item[1],
				num = self.data.item[2]
			},
			buyCallback = function (num)
				local indexs = {}

				for i = 1, num do
					table.insert(indexs, self.data.index[i])
				end

				self.dungeon:reqBuyItem(self.data.index[1], indexs)
			end
		})
	end
end

local DungeonShopDetailWindow = class("DungeonShopDetailWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function DungeonShopDetailWindow:ctor(name, params)
	DungeonShopDetailWindow.super.ctor(self, name, params)

	self.dungeon = xyd.models.dungeon
	self.backpack = xyd.models.backpack
	self.index_ = params.index
end

function DungeonShopDetailWindow:initWindow()
	DungeonShopDetailWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:refreshItem()
	self:initItems(false)
	self:registerEvent()
end

function DungeonShopDetailWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.labelTitle_ = winTrans:ComponentByName("groupMain/labelTitle_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("groupMain/closeBtn").gameObject
	self.labelTopTips1_ = winTrans:ComponentByName("groupMain/groupTotal/labelTopTips1_", typeof(UILabel))
	self.labelTotal_ = winTrans:ComponentByName("groupMain/groupTotal/labelTotal_", typeof(UILabel))
	local groupCoin = winTrans:NodeByName("groupMain/groupCoin").gameObject
	self.labelMana_ = groupCoin:ComponentByName("labelMana_", typeof(UILabel))
	self.labelCrystal_ = groupCoin:ComponentByName("labelCrystal_", typeof(UILabel))
	self.groupNone_ = winTrans:NodeByName("groupMain/groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.scrollView = winTrans:ComponentByName("groupMain/scroller_", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("groupItems_", typeof(UIWrapContent))
	local item = self.scrollView:NodeByName("item").gameObject
	self.wrapContent_ = FixedWrapContent.new(self.scrollView, wrapContent, item, DungeonShopItem, self)
end

function DungeonShopDetailWindow:layout()
	self.labelTitle_.text = __("DUNGEON_SHOP_DETAIL", __("DUNGEON_SHOP_LEV_" .. tostring(self.index_)))
	self.labelTopTips1_.text = __("DUNGEON_SHOP_TIPS_1")
	self.labelNoneTips_.text = __("DUNGEON_SHOP_TIPS_2")
end

function DungeonShopDetailWindow:registerEvent()
	self:register()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refreshItem))
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_BUY_ITEM, handler(self, self.onBuyItem))
end

function DungeonShopDetailWindow:onBuyItem(event)
	local item = event.data.item

	xyd.alertItems({
		item
	})
	self:initItems(true)
end

function DungeonShopDetailWindow:refreshItem()
	self.labelMana_.text = xyd.getRoughDisplayNumber(self.backpack:getMana())
	self.labelCrystal_.text = self.backpack:getCrystal()
end

function DungeonShopDetailWindow:getMultiItems(items)
	local multiItems = {}

	for i = 1, #items do
		local curItem = items[i]
		local newItemFlag = true

		for j = 1, #multiItems do
			if curItem.id == multiItems[j].id then
				table.insert(multiItems[j].index, curItem.index)

				newItemFlag = false
			end
		end

		if newItemFlag then
			table.insert(multiItems, {
				id = curItem.id,
				index = {
					curItem.index
				},
				item = curItem.item
			})
		end
	end

	return multiItems
end

function DungeonShopDetailWindow:initItems(bottom)
	local shopItems = self.dungeon:getShopItems()
	local curShopItems = {}

	for i = 1, #shopItems do
		local id = shopItems[i]

		if DungeonShopTable:getType(id) == self.index_ then
			table.insert(curShopItems, {
				id = id,
				index = i,
				item = DungeonShopTable:getItem(id)
			})
		end
	end

	curShopItems = self:getMultiItems(curShopItems)

	table.sort(curShopItems, function (a, b)
		if a.item[1] ~= b.item[1] then
			return a.item[1] < b.item[1]
		else
			return a.item[2] < b.item[2]
		end
	end)

	if bottom then
		self.wrapContent_:setInfos(curShopItems, {
			keepPosition = true
		})
	else
		self.wrapContent_:setInfos(curShopItems, {})
	end

	if #curShopItems <= 0 then
		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end

	self.labelTotal_.text = #curShopItems
end

return DungeonShopDetailWindow
