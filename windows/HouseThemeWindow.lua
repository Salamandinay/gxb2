local HouseThemeItem = class("HouseThemeItem")
local HouseFurnitureGroupTable = xyd.tables.houseFurnitureGroupTable
local JSON = require("cjson")

function HouseThemeItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()
end

function HouseThemeItem:getGameObject()
	return self.go
end

function HouseThemeItem:initUI()
	self.labelName_ = self.go:ComponentByName("labelName_", typeof(UILabel))
	self.img_ = self.go:ComponentByName("img_", typeof(UISprite))
	self.redMark = self.go:ComponentByName("redMark", typeof(UISprite))

	self.redMark:SetActive(false)
end

function HouseThemeItem:registerEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.onClick)
end

function HouseThemeItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.labelName_.text = HouseFurnitureGroupTable:getName(self.data)

	xyd.setUISpriteAsync(self.img_, nil, HouseFurnitureGroupTable:getImg(self.data))
end

function HouseThemeItem:onClick()
	local wnd = xyd.WindowManager.get():getWindow("house_theme_window")

	if wnd then
		wnd:selectTheme(self.data)
	end
end

local HouseThemeItemWithRed = class("HouseThemeItem", HouseThemeItem)

function HouseThemeItemWithRed:update(index, info)
	HouseThemeItemWithRed.super.update(self, index, info)
	self.redMark:SetActive(self:ifRedMark())
end

function HouseThemeItemWithRed:ifRedMark()
	local updateTime = HouseFurnitureGroupTable:getNewTime(self.data)
	local dbData = xyd.db.misc:getValue("house_shop_red_group")
	local groups = dbData ~= nil and JSON.decode(dbData) or {}

	for i = 1, #groups do
		if self.data == groups[i] then
			return false
		end
	end

	if updateTime ~= nil and xyd.getServerTime() < updateTime then
		return true
	end

	return false
end

function HouseThemeItemWithRed:onClick()
	xyd.models.house:setShopRedPoint(self.data)

	local win = xyd.WindowManager.get():getWindow("house_window")

	if win then
		win:updateShopRed()
	end

	HouseThemeItemWithRed.super.onClick(self)
end

local HouseThemeWindow = class("HouseThemeWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function HouseThemeWindow:ctor(name, params)
	HouseThemeWindow.super.ctor(self, name, params)

	self.callback = params.callback
	self.enterType = params.enterType
end

function HouseThemeWindow:initWindow()
	HouseThemeWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:updateItemList()
	self:registerEvent()
end

function HouseThemeWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.btnAll_ = winTrans:NodeByName("groupAction/btnAll_").gameObject
	local scrollView = winTrans:ComponentByName("groupAction/scroller_", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	self.houseThemeItem = scrollView:NodeByName("house_theme_item").gameObject

	if self.enterType ~= nil and self.enterType == "shop" then
		self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, self.houseThemeItem, HouseThemeItemWithRed, self)
	else
		self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, self.houseThemeItem, HouseThemeItem, self)
	end
end

function HouseThemeWindow:layout()
	self.btnAll_:ComponentByName("button_label", typeof(UILabel)).text = __("HOUSE_TEXT_13")
end

function HouseThemeWindow:registerEvent()
	UIEventListener.Get(self.btnAll_).onClick = handler(self, self.onAllTouch)
end

function HouseThemeWindow:onAllTouch()
	self:selectTheme(-1)
end

function HouseThemeWindow:selectTheme(id)
	if self.callback then
		self.callback(tonumber(id))
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function HouseThemeWindow:updateItemList()
	local ids = HouseFurnitureGroupTable:getIDs()
	local data = xyd.getCopyData(ids)

	table.sort(data, function (a, b)
		if tonumber(a) ~= tonumber(b) then
			return tonumber(b) < tonumber(a)
		end

		return false
	end)
	self.wrapContent_:setInfos(data, {})
end

return HouseThemeWindow
