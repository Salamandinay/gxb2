local Activity4birthdayMusicAwardViewWindow = class("Activity4birthdayMusicAwardViewWindow", import(".BaseWindow"))
local ShowItem = class("ShowItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")

function Activity4birthdayMusicAwardViewWindow:ctor(name, params)
	Activity4birthdayMusicAwardViewWindow.super.ctor(self, name, params)
end

function Activity4birthdayMusicAwardViewWindow:initWindow()
	self:getUIComponent()
	Activity4birthdayMusicAwardViewWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function Activity4birthdayMusicAwardViewWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.titleText = self.groupAction:ComponentByName("titleText", typeof(UILabel))
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.scrollView = self.groupAction:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.wrapContentUIWrapContent = self.scrollView:ComponentByName("wrapContent", typeof(UIWrapContent))
	self.showLittleItem = self.groupAction:NodeByName("showItem").gameObject
	self.wrapContent = FixedMultiWrapContent.new(self.scrollViewUIScrollView, self.wrapContentUIWrapContent, self.showLittleItem, ShowItem, self)
end

function Activity4birthdayMusicAwardViewWindow:registerEvent()
	UIEventListener.Get(self.btnClose.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function Activity4birthdayMusicAwardViewWindow:layout()
	self.titleText.text = __("ACTIVITY_AWARD_PREVIEW_TITLE")

	self:initNav()
end

function Activity4birthdayMusicAwardViewWindow:initNav()
	local labelStates = {
		chosen = {
			color = Color.New2(4278124287.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.smallTab = CommonTabBar.new(self.nav.gameObject, 3, function (index)
		self:updateNav(index)
	end, nil, labelStates)
	local texts = {
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD01"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD02"),
		__("ACTIVITY_4BIRTHDAY_GAMBLE_AWARD03")
	}

	self.smallTab:setTexts(texts)
	self.smallTab:setTabActive(3, true, false)
end

function Activity4birthdayMusicAwardViewWindow:updateNav(index)
	if self.index == index then
		return
	end

	self.index = index

	self.wrapContent:setInfos(self:getInfos(), {})
	self.scrollViewUIScrollView:ResetPosition()
end

function Activity4birthdayMusicAwardViewWindow:getInfos()
	return xyd.tables.activity4birthdayGambleTable:getShowViewInfos(self.index)
end

function ShowItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent

	ShowItem.super.ctor(self, goItem)
end

function ShowItem:getUIComponent()
	self.itemCon = self.go:NodeByName("itemCon").gameObject
end

function ShowItem:initUI()
	self:getUIComponent()
end

function ShowItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.data = info
	self.itemId = info[1]
	self.itemNum = info[2]
	local params = {
		isAddUIDragScrollView = true,
		noClickSelected = true,
		scale = 1,
		uiRoot = self.itemCon.gameObject,
		itemID = self.itemId,
		num = self.itemNum
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.icon:setInfo(params)
	end
end

return Activity4birthdayMusicAwardViewWindow
