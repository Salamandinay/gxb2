local ActivitySpfarmBuildWindow = class("ActivitySpfarmBuildWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local BuildItem = class("BuildItem", import("app.components.CopyComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ActivitySpfarmBuildWindow:ctor(name, params)
	ActivitySpfarmBuildWindow.super.ctor(self, name, params)

	self.type = params.type
end

function ActivitySpfarmBuildWindow:initWindow()
	self:getUIComponent()
	ActivitySpfarmBuildWindow.super.initWindow(self)
	self:reSize()
	self:registerEvent()
	self:layout()
end

function ActivitySpfarmBuildWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.topGroup = self.groupAction:NodeByName("topGroup").gameObject
	self.labelWinTitle = self.topGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.helpBtn = self.topGroup:NodeByName("helpBtn").gameObject
	self.closeBtn = self.topGroup:NodeByName("closeBtn").gameObject
	self.navBtns = self.groupAction:NodeByName("navBtns").gameObject
	self.buildItem = self.groupAction:NodeByName("buildItem").gameObject
	self.scrollView = self.groupAction:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.scrollContent = self.scrollView:NodeByName("scrollContent").gameObject
	self.scrollContentMultiRowWrapContent = self.scrollView:ComponentByName("scrollContent", typeof(MultiRowWrapContent))
	self.multiWrap = require("app.common.ui.FixedMultiWrapContent").new(self.scrollViewUIScrollView, self.scrollContentMultiRowWrapContent, self.buildItem, BuildItem, self)
	self.downGroup = self.groupAction:NodeByName("downGroup").gameObject
	self.btn = self.downGroup:NodeByName("btn").gameObject
	self.btnLable = self.btn:ComponentByName("btnLable", typeof(UILabel))
	self.resItem = self.downGroup:NodeByName("resItem").gameObject
	self.resItemBg = self.resItem:ComponentByName("resItemBg", typeof(UISprite))
	self.resItemIcon = self.resItem:ComponentByName("resItemIcon", typeof(UISprite))
	self.resItemLabel = self.resItem:ComponentByName("resItemLabel", typeof(UILabel))
end

function ActivitySpfarmBuildWindow:reSize()
end

function ActivitySpfarmBuildWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

function ActivitySpfarmBuildWindow:layout()
	if self.type == xyd.ActivitySpfarmBuildWindowType.BUILD then
		self.labelWinTitle.text = __("ACTIVITY_SPFARM_TEXT09")
		self.btnLable.text = __("ACTIVITY_SPFARM_TEXT09")
	elseif self.type == xyd.ActivitySpfarmBuildWindowType.CHANGE then
		self.labelWinTitle.text = __("ACTIVITY_SPFARM_TEXT10")
		self.btnLable.text = __("ACTIVITY_SPFARM_TEXT10")
	end

	self:initNav()
end

function ActivitySpfarmBuildWindow:initNav()
	self.sortTab = CommonTabBar.new(self.navBtns, 3, function (index)
		self:changeNav(index)
	end)
end

function ActivitySpfarmBuildWindow:changeNav(index)
	if self.pageIndex and self.pageIndex == index then
		return
	end

	self.pageIndex = index
	local arr = {}

	if index == 1 then
		arr = xyd.tables.activitySpfarmBuildingTable:getCommonBuildIds()
	elseif index == 2 then
		arr = xyd.tables.activitySpfarmBuildingTable:getHighBuildArr()
	elseif index == 3 then
		arr = xyd.tables.activitySpfarmBuildingTable:getSpecialBuildArr()
	end

	self.multiWrap:setInfos(arr, {})
	self.scrollViewUIScrollView:ResetPosition()

	self.selectId = arr[1]
end

function BuildItem:ctor(goItem, parent)
	self.goItem_ = goItem
	self.parent = parent

	BuildItem.super.ctor(self, goItem)
end

function BuildItem:initUI()
	self.bottomBg = self.go:ComponentByName("bottomBg", typeof(UISprite))
	self.buildImg = self.go:ComponentByName("buildImg", typeof(UISprite))
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))
	self.infoBg = self.go:ComponentByName("infoBg", typeof(UISprite))
	self.levLabel = self.infoBg:ComponentByName("levLabel", typeof(UILabel))
	self.numLabel = self.infoBg:ComponentByName("numLabel", typeof(UILabel))
	self.lockCon = self.go:NodeByName("lockCon").gameObject
	self.lockImg1 = self.lockCon:ComponentByName("lockImg1", typeof(UISprite))
	self.lockImg2 = self.lockCon:ComponentByName("lockImg2", typeof(UISprite))
	self.selectImg = self.go:ComponentByName("selectImg", typeof(UISprite))
end

function BuildItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.buildId = info
	local buildImg = xyd.tables.activitySpfarmBuildingTable:getIcon(self.buildId)

	xyd.setUISpriteAsync(self.buildImg, nil, buildImg)
end

return ActivitySpfarmBuildWindow
