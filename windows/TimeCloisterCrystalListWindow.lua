local TimeCloisterCrystalListWindow = class("TimeCloisterCrystalListWindow", import(".BaseWindow"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local CardItem = class("CardItem", import("app.components.CopyComponent"))
local TimeCloisterScienceCard = import("app.components.TimeCloisterScienceCard")

function TimeCloisterCrystalListWindow:ctor(name, params)
	TimeCloisterCrystalListWindow.super.ctor(self, name, params)
end

function TimeCloisterCrystalListWindow:initWindow()
	self:getUIComponent()
	TimeCloisterCrystalListWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function TimeCloisterCrystalListWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.nav = self.groupAction:NodeByName("nav").gameObject

	for i = 1, 5 do
		self["tab_" .. i] = self.nav:NodeByName("tab_" .. i).gameObject

		if i == 1 then
			self["label" .. i] = self["tab_" .. i]:ComponentByName("label", typeof(UILabel))
		else
			self["icon" .. i] = self["tab_" .. i]:ComponentByName("icon", typeof(UISprite))
		end
	end

	self.itemCon = self.groupAction:NodeByName("itemCon").gameObject
	self.itemScroller = self.groupAction:NodeByName("itemScroller").gameObject
	self.itemScrollerUIScrollView = self.groupAction:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemGroup = self.itemScroller:NodeByName("itemGroup").gameObject
	self.itemGroupUIWrapContent = self.itemScroller:ComponentByName("itemGroup", typeof(UIWrapContent))
	self.itemGroupUIWrapContent = FixedMultiWrapContent.new(self.itemScrollerUIScrollView, self.itemGroupUIWrapContent, self.itemCon, CardItem, self)
end

function TimeCloisterCrystalListWindow:registerEvent()
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function TimeCloisterCrystalListWindow:layout()
	self.labelTitle.text = __("TIME_CLOISTER_TEXT97")
	self.label1.text = __("TIME_CLOISTER_TEXT98")

	self:initNav()
end

function TimeCloisterCrystalListWindow:initNav()
	self.tabBar = CommonTabBar.new(self.nav, 5, function (index)
		self:updatePage(index)
	end, nil, , 5)
end

function TimeCloisterCrystalListWindow:updatePage(index)
	if self.tabIndex and self.tabIndex == index then
		return
	end

	self.tabIndex = index

	self:choicePage(index)
	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)
end

function TimeCloisterCrystalListWindow:choicePage(index)
	local arr = xyd.models.timeCloisterModel:getThreeCrystalTypeWithCardsIndex(index - 1)

	self.itemGroupUIWrapContent:setInfos(arr, {})
	self.itemScrollerUIScrollView:ResetPosition()
end

function CardItem:ctor(go, parent)
	self.parent = parent

	CardItem.super.ctor(self, go)
end

function CardItem:initUI()
end

function CardItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if not self.card then
		self.card = TimeCloisterScienceCard.new(self.go, {})

		self.card:SetLocalScale(0.95, 0.95, 0.95)
		self.card:AddUIDragScrollView()
	end

	self.index = info

	self.card:setInfo({
		index = self.index
	})
end

return TimeCloisterCrystalListWindow
