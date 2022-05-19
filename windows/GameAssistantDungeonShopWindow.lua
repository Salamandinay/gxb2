local BaseWindow = import(".BaseWindow")
local GameAssistantDungeonShopWindow = class("GameAssistantDungeonShopWindow", BaseWindow)
local GameAssistantDungeonShopItem = class("GameAssistantDungeonShopItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function GameAssistantDungeonShopWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model = xyd.models.dungeon
end

function GameAssistantDungeonShopWindow:getPrefabPath()
	return "Prefabs/Windows/game_assistant_dungeon_shop_window"
end

function GameAssistantDungeonShopWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:Register()
	self:initUIComponent()
end

function GameAssistantDungeonShopWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject

	for i = 1, 3 do
		self["bg_" .. i] = self.groupAction:ComponentByName("bg_" .. i, typeof(UISprite))
	end

	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.ResGroup = self.groupAction:ComponentByName("ResGroup", typeof(UISprite))
	self.iconGold = self.ResGroup:ComponentByName("iconGold", typeof(UISprite))
	self.labelGold = self.ResGroup:ComponentByName("labelGold", typeof(UILabel))
	self.iconCrystal = self.ResGroup:ComponentByName("iconCrystal", typeof(UISprite))
	self.labelCrystal = self.ResGroup:ComponentByName("labelCrystal", typeof(UILabel))
	self.scroller = self.groupAction:NodeByName("scroller").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.item = self.scroller:NodeByName("item").gameObject
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.tabGroup = self.groupAction:NodeByName("tabGroup").gameObject
	self.tabGroupLayout = self.groupAction:ComponentByName("tabGroup", typeof(UILayout))
	self.groupNone = self.groupAction:NodeByName("groupNone_").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNoneTips_", typeof(UILabel))

	for i = 1, 3 do
		self["tab" .. i] = self.tabGroup:NodeByName("tab" .. i).gameObject
		self["labelTab" .. i] = self["tab" .. i]:ComponentByName("label", typeof(UILabel))
		self["imgChosen" .. i] = self["tab" .. i]:ComponentByName("imgChosen", typeof(UISprite))
	end
end

function GameAssistantDungeonShopWindow:initUIComponent()
	self.labelTitle.text = __("GAME_ASSISTANT_TEXT35")
	self.labelTab1.text = __("GAME_ASSISTANT_TEXT40")
	self.labelTab2.text = __("GAME_ASSISTANT_TEXT41")
	self.labelTab3.text = __("GAME_ASSISTANT_TEXT42")
	self.labelNone.text = __("GAME_ASSISTANT_TEXT98")
	self.labelGold.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA))
	self.labelCrystal.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL))

	xyd.setUISpriteAsync(self.iconGold, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.MANA))
	xyd.setUISpriteAsync(self.iconCrystal, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.CRYSTAL))
	self:initData()

	for i = 1, 3 do
		if #self["shop" .. i .. "Item"] > 0 then
			self.curTabIndex = i

			self:chooseTab(self.curTabIndex)

			break
		end
	end

	self:updateTabGroup()
end

function GameAssistantDungeonShopWindow:Register()
	self.eventProxy_:addEventListener(xyd.event.DUNGEON_BUY_ITEM, handler(self, self.onBuyItem))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.labelGold.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.MANA))
		self.labelCrystal.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL))
	end)

	UIEventListener.Get(self.btnClose).onClick = function ()
		xyd.closeWindow(self.name_)
	end

	for i = 1, 3 do
		UIEventListener.Get(self["tab" .. i]).onClick = function ()
			self:chooseTab(i)
		end
	end
end

function GameAssistantDungeonShopWindow:initData()
	self.shopItems = xyd.models.dungeon:getShopItems()
	self.shop1ItemTemp = {}
	self.shop2ItemTemp = {}
	self.shop3ItemTemp = {}

	for i = 1, #self.shopItems do
		local id = self.shopItems[i]
		local type = xyd.tables.dungeonShopTable:getType(id)

		if type then
			table.insert(self["shop" .. type .. "ItemTemp"], {
				tableID = id,
				index = i,
				item = xyd.tables.dungeonShopTable:getItem(id),
				cost = xyd.tables.dungeonShopTable:getCost(id)
			})
		end
	end

	self.shop1Item = self:getMultiItems(self.shop1ItemTemp)
	self.shop2Item = self:getMultiItems(self.shop2ItemTemp)
	self.shop3Item = self:getMultiItems(self.shop3ItemTemp)
end

function GameAssistantDungeonShopWindow:chooseTab(index)
	self.curTabIndex = index

	self:updateTabGroup()
	self:initData()
	self:updateContentGoup()
end

function GameAssistantDungeonShopWindow:updateTabGroup()
	if not self.initFlag then
		for i = 1, 3 do
			self["tab" .. i]:SetActive(#self["shop" .. i .. "Item"] > 0)
		end

		self.initFlag = true
	end

	for i = 1, 3 do
		self["imgChosen" .. i]:SetActive(self.curTabIndex == i)
		self["bg_" .. i]:SetActive(self.curTabIndex == i)
	end

	self.tabGroupLayout:Reposition()
end

function GameAssistantDungeonShopWindow:updateContentGoup()
	local data = self["shop" .. self.curTabIndex .. "Item"]
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))

	if self.wrapContent == nil then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item, GameAssistantDungeonShopItem, self)
	end

	local function sort_func(a, b)
		return a.tableID < b.tableID
	end

	table.sort(data, sort_func)
	self.wrapContent:setInfos(data, {})
	self.groupNone:SetActive(#data == 0)
end

function GameAssistantDungeonShopWindow:getMultiItems(items)
	local multiItems = {}

	for i = 1, #items do
		local curItem = items[i]
		local newItemFlag = true

		for j = 1, #multiItems do
			if curItem.tableID == multiItems[j].tableID then
				table.insert(multiItems[j].index, curItem.index)

				newItemFlag = false
			end
		end

		if newItemFlag then
			table.insert(multiItems, {
				tableID = curItem.tableID,
				index = {
					curItem.index
				},
				item = curItem.item,
				cost = curItem.cost
			})
		end
	end

	return multiItems
end

function GameAssistantDungeonShopWindow:onBuyItem(event)
	local item = event.data.item

	xyd.alertItems({
		item
	})
	self:initData()
	self:updateContentGoup()
end

function GameAssistantDungeonShopItem:ctor(go, parent)
	GameAssistantDungeonShopItem.super.ctor(self, go, parent)

	self.parent = parent
end

function GameAssistantDungeonShopItem:initUI()
	local go = self.go
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.btnBuy = self.go:NodeByName("btnBuy").gameObject
	self.labelBuy = self.btnBuy:ComponentByName("labelBuy", typeof(UILabel))
	self.iconCost = self.btnBuy:ComponentByName("iconCost", typeof(UISprite))
	self.labelCost = self.btnBuy:ComponentByName("labelCost", typeof(UILabel))
	UIEventListener.Get(self.btnBuy).onClick = handler(self, self.buyItem)
end

function GameAssistantDungeonShopItem:updateInfo()
	self.tableID = self.data.tableID
	self.item = self.data.item
	self.cost = self.data.cost
	self.index = self.data.index
	self.labelBuy.text = __("BUY2")
	self.labelCost.text = xyd.getRoughDisplayNumber(self.cost[2])

	xyd.setUISpriteAsync(self.iconCost, nil, xyd.tables.itemTable:getIcon(self.cost[1]))

	self.label.text = __("BUY_GIFTBAG_LIMIT_2") .. " " .. #self.index
	local params = {
		show_has_num = false,
		scale = 0.6481481481481481,
		notShowGetWayBtn = true,
		uiRoot = self.iconPos,
		itemID = self.item[1],
		num = self.item[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.parent.scrollView
	}

	if self.icon == nil then
		self.icon = AdvanceIcon.new(params)
	else
		self.icon:setInfo(params)
	end
end

function GameAssistantDungeonShopItem:buyItem()
	local cost = xyd.tables.dungeonShopTable:getCost(self.data.tableID)
	local mana = xyd.models.backpack:getMana()
	local crystal = xyd.models.backpack:getCrystal()

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

				xyd.models.dungeon:reqBuyItem(self.data.index[1], indexs)
			end
		})
	end
end

return GameAssistantDungeonShopWindow
