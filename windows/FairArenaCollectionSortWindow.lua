local BaseWindow = import(".BaseWindow")
local FairArenaCollectionSortWindow = class("FairArenaCollectionSortWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local SortItem = class("SortItem", import("app.components.CopyComponent"))

function SortItem:ctor(goItem, itemdata)
	self.goItem_ = goItem
	self.goItem_.name = "tab_" .. itemdata
end

function FairArenaCollectionSortWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.indexArr = xyd.tables.miscTable:split2Cost("fair_arena_collection_sort_type_show_list", "value", "|")
	self.sortType = params.sortType
end

function FairArenaCollectionSortWindow:initWindow()
	self:getUIConponent()
	self:layout()
	self:initNav()
	self:register()
end

function FairArenaCollectionSortWindow:getUIConponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelWinTitle_ = winTrans:ComponentByName("baseGroup/labelWinTitle", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("baseGroup/closeBtn").gameObject
	self.scroller = winTrans:ComponentByName("sortItemScroller", typeof(UIScrollView))
	self.nav_ = winTrans:NodeByName("sortItemScroller/nav").gameObject
	self.nav_layout = winTrans:ComponentByName("sortItemScroller/nav", typeof(UILayout))
	self.sortTypeNameLabel_ = winTrans:ComponentByName("explainGroup/sortTypeNameLabel", typeof(UILabel))
	self.cancelBtn_ = winTrans:NodeByName("cancelBtn").gameObject
	self.cancelBtn_label = winTrans:ComponentByName("cancelBtn/button_label", typeof(UILabel))
	self.sureBtn_ = winTrans:NodeByName("sureBtn").gameObject
	self.sureBtn_label = winTrans:ComponentByName("sureBtn/button_label", typeof(UILabel))
	self.sortItem = winTrans:NodeByName("tab_1").gameObject
end

function FairArenaCollectionSortWindow:layout()
	self.labelWinTitle_.text = __("SORT_TEXT1")
	self.sortTypeNameLabel_.text = __("SORT_TEXT2")
	self.cancelBtn_label.text = __("CANCEL_2")
	self.sureBtn_label.text = __("SURE")

	NGUITools.DestroyChildren(self.nav_.transform)

	for i in pairs(self.indexArr) do
		local tmp = NGUITools.AddChild(self.nav_, self.sortItem)
		local item = SortItem.new(tmp, i)
	end
end

function FairArenaCollectionSortWindow:initNav()
	local index = #self.indexArr
	local labelText = {}
	local labelStates = {
		chosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.nav_, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)
	local defaultType = 1

	for i in pairs(self.indexArr) do
		if self.sortType == self.indexArr[i] then
			defaultType = i

			break
		end
	end

	self.tab:setTabActive(defaultType, true, false)

	for i = 1, index do
		if self.indexArr[i] == xyd.partnerSortType.PARTNER_ID then
			table.insert(labelText, __("SLOT_SORT_DEFAULT"))
		else
			table.insert(labelText, __("SLOT_SORT" .. self.indexArr[i]))
		end
	end

	self.tab:setTexts(labelText)
	self.nav_layout:Reposition()
	self:waitForFrame(1, function ()
		self.scroller:ResetPosition()
	end)
end

function FairArenaCollectionSortWindow:register()
	FairArenaCollectionSortWindow.super.register(self)

	UIEventListener.Get(self.cancelBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.sureBtn_).onClick = handler(self, self.onSureBtn)
end

function FairArenaCollectionSortWindow:onSureBtn()
	local win = xyd.WindowManager.get():getWindow("fair_arena_collection_window")

	if win then
		win:setPartnerAttrSort(self.sortType)
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function FairArenaCollectionSortWindow:updateNav(num)
	local changeType = self.indexArr[num]

	if changeType ~= self.sortType then
		self.sortType = changeType
	else
		self.sortType = xyd.partnerSortType.PARTNER_ID
	end
end

return FairArenaCollectionSortWindow
