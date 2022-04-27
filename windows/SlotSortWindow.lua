local BaseWindow = import(".BaseWindow")
local SlotSortWindow = class("SlotSortWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local SortItem = class("SortItem", import("app.components.CopyComponent"))

function SortItem:ctor(goItem, itemdata)
	self.goItem_ = goItem
	self.goItem_.name = "tab_" .. itemdata
	local transGo = goItem.transform
end

function SlotSortWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	local a = 0
	self.indexArr = xyd.tables.miscTable:split2Cost("slot_sort_type_show_list", "value", "|")
	self.entranceWin = xyd.WindowManager.get():getWindow("activity_entrance_test_slot_window")

	if self.entranceWin then
		self.indexArr = xyd.tables.miscTable:split2Cost("entrance_test_slot_sort_type_show_list", "value", "|")
	end

	self.sortType = params.sortType
end

function SlotSortWindow:initWindow()
	self:getUIConponent()
	BaseWindow.initWindow(self)
	self:layout()
	self:registerEvent()
	self:initNav()
end

function SlotSortWindow:getUIConponent()
	local trans = self.window_.transform
	local allgroup = trans:NodeByName("groupAction").gameObject
	self.baseGroup_ = allgroup:NodeByName("baseGroup").gameObject
	self.labelWinTitle_ = self.baseGroup_:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn_ = self.baseGroup_:NodeByName("closeBtn").gameObject
	self.sortItemScroller_ = allgroup:NodeByName("sortItemScroller").gameObject
	self.sortItemScroller_uipanel = allgroup:ComponentByName("sortItemScroller", typeof(UIPanel))
	self.sortItemScroller_uiscroller = allgroup:ComponentByName("sortItemScroller", typeof(UIScrollView))
	self.nav_ = self.sortItemScroller_:NodeByName("nav").gameObject
	self.nav_layout = self.sortItemScroller_:ComponentByName("nav", typeof(UILayout))
	self.explainGroup_ = allgroup:NodeByName("explainGroup").gameObject
	self.sortTypeNameLabel_ = self.explainGroup_:ComponentByName("sortTypeNameLabel", typeof(UILabel))
	self.cancelBtn_ = allgroup:NodeByName("cancelBtn").gameObject
	self.cancelBtn_label = allgroup:ComponentByName("cancelBtn/button_label", typeof(UILabel))
	self.sureBtn_ = allgroup:NodeByName("sureBtn").gameObject
	self.sureBtn_label = allgroup:ComponentByName("sureBtn/button_label", typeof(UILabel))
	self.tab_1 = allgroup:NodeByName("tab_1").gameObject
	self.sortItem = allgroup:NodeByName("tab_1").gameObject
end

function SlotSortWindow:layout()
	self.labelWinTitle_.text = __("SORT_TEXT1")
	self.sortTypeNameLabel_.text = __("SORT_TEXT2")
	self.cancelBtn_label.text = __("CANCEL_2")
	self.sureBtn_label.text = __("SURE")

	NGUITools.DestroyChildren(self.nav_.transform)

	for i in pairs(self.indexArr) do
		local tmp = NGUITools.AddChild(self.nav_.gameObject, self.sortItem.gameObject)
		local item = SortItem.new(tmp, i)
	end
end

function SlotSortWindow:registerEvent()
	UIEventListener.Get(self.closeBtn_.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.cancelBtn_.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.sureBtn_.gameObject).onClick = handler(self, self.onSureBtn)
end

function SlotSortWindow:onSureBtn()
	local slotWindow = xyd.WindowManager.get():getWindow("slot_window") or self.entranceWin

	if slotWindow then
		slotWindow:changeSortType(self.sortType + 1)
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function SlotSortWindow:initNav()
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
	self.tab = CommonTabBar.new(self.nav_.gameObject, index, function (index)
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
		table.insert(labelText, __("SLOT_SORT" .. self.indexArr[i]))

		if self.entranceWin and self.indexArr[i] == xyd.partnerSortType.SHENXUE then
			labelText[i] = __("ENTRANCE_TEST_SORT")
		end
	end

	self.tab:setTexts(labelText)
	self.nav_layout:Reposition()
	self:waitForFrame(1, function ()
		self.sortItemScroller_uiscroller:ResetPosition()
	end)
end

function SlotSortWindow:updateNav(num)
	local changeType = self.indexArr[num]

	if changeType ~= self.sortType then
		self.sortType = changeType
	end
end

function SlotSortWindow:willClose(params)
	BaseWindow.willClose(self, params)
end

return SlotSortWindow
