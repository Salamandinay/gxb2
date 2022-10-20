local BaseWindow = import(".BaseWindow")
local SoulEquipSortWindow = class("SoulEquipSortWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local SortItem = class("SortItem", import("app.components.CopyComponent"))

function SortItem:ctor(goItem, parent, index)
	self.goItem_ = goItem
	self.goItem_.name = "tab_" .. index
	self.parent = parent
	local transGo = goItem.transform
	self.chosen = self.goItem_:ComponentByName("chosen", typeof(UISprite))
	self.unchosen = self.goItem_:ComponentByName("unchosen", typeof(UISprite))
	self.label = self.goItem_:ComponentByName("label", typeof(UILabel))
	self.redMark = self.goItem_:ComponentByName("redMark", typeof(UISprite))

	UIEventListener.Get(self.goItem_.gameObject).onClick = function ()
		self.data.clickCallBack()
	end
end

function SortItem:setInfo(data)
	self.data = data
	self.label.text = data.title

	self.chosen:SetActive(data.isChosen)

	if xyd.Global.lang == "de_de" then
		self.label.fontSize = 20
	end

	if xyd.Global.lang == "fr_fr" then
		self.label.height = 52
	end

	if data.isChosen then
		self.label.color = Color.New2(960513791)
		self.label.effectColor = Color.New2(4294967295.0)
	else
		self.label.color = Color.New2(960513791)
		self.label.effectColor = Color.New2(4294967295.0)
	end
end

function SoulEquipSortWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.indexArr = {}
	self.indexHelpArr = {}
	self.items = {}
	local ids = xyd.tables.soulEquip2BaseBuffTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local buff = xyd.tables.soulEquip2BaseBuffTable:getBuff(id)

		if not self.indexHelpArr[buff] then
			self.indexHelpArr[buff] = 1

			table.insert(self.indexArr, buff)
		end
	end

	ids = xyd.tables.soulEquip2ExBuffTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local buff = xyd.tables.soulEquip2ExBuffTable:getBuff(id)

		if not self.indexHelpArr[buff] then
			self.indexHelpArr[buff] = 1

			table.insert(self.indexArr, buff)
		end
	end

	local filterAttrs = params.filterAttrs or {}
	self.filterAttrsHelpArr = {}
	self.filterAttrs = {}

	for k, v in pairs(filterAttrs) do
		self.filterAttrsHelpArr[v] = 1
		self.filterAttrs[k] = v
	end
end

function SoulEquipSortWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipSortWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.baseGroup = self.groupAction:NodeByName("baseGroup").gameObject
	self.labelWindowTitle = self.baseGroup:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.baseGroup:NodeByName("closeBtn").gameObject
	self.sortItemScroller = self.groupAction:NodeByName("sortItemScroller").gameObject
	self.sortItemScrollView = self.groupAction:ComponentByName("sortItemScroller", typeof(UIScrollView))
	self.nav = self.sortItemScroller:NodeByName("nav").gameObject
	self.navGrid = self.sortItemScroller:ComponentByName("nav", typeof(UIGrid))
	self.drag = self.groupAction:NodeByName("drag").gameObject
	self.explainGroup = self.groupAction:NodeByName("explainGroup").gameObject
	self.sortTypeNameLabel = self.explainGroup:ComponentByName("sortTypeNameLabel", typeof(UILabel))
	self.cancelBtn = self.groupAction:NodeByName("cancelBtn").gameObject
	self.labelCancel = self.cancelBtn:ComponentByName("button_label", typeof(UILabel))
	self.sureBtn = self.groupAction:NodeByName("sureBtn").gameObject
	self.labelSure = self.sureBtn:ComponentByName("button_label", typeof(UILabel))
	self.tab_item = self.groupAction:NodeByName("tab_1").gameObject
end

function SoulEquipSortWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT10")
	self.labelCancel.text = __("CANCEL_2")
	self.labelSure.text = __("SURE")

	self:update()
end

function SoulEquipSortWindow:register()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.cancelBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.sureBtn.gameObject).onClick = handler(self, self.onSureBtn)
end

function SoulEquipSortWindow:onSureBtn()
	local wnd = xyd.WindowManager.get():getWindow("soul_equip2_strengthen_window")

	if wnd then
		wnd:changefilterAttrs(self.filterAttrs)
	else
		local wnd1 = xyd.WindowManager.get():getWindow("soul_equip_info_window")

		if wnd1 then
			wnd1:changefilterAttrs(self.filterAttrs)
		end
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function SoulEquipSortWindow:update(keepPosition)
	for i in pairs(self.indexArr) do
		if not self.items[i] then
			local tmp = NGUITools.AddChild(self.nav.gameObject, self.tab_item.gameObject)
			local item = SortItem.new(tmp, self, i)
			self.items[i] = item
		end

		local isChosen = self.filterAttrs[1] == self.indexArr[i]

		self.items[i]:setInfo({
			title = xyd.tables.dBuffTable:getDesc(self.indexArr[i]),
			isChosen = isChosen,
			clickCallBack = function ()
				self:updateNav(i)
				self:update(true)
			end
		})
	end

	if not keepPosition then
		self.navGrid:Reposition()
		self.sortItemScrollView:ResetPosition()
	end
end

function SoulEquipSortWindow:updateNav(num)
	local buff = self.indexArr[num]

	if buff ~= self.filterAttrs[1] then
		self.filterAttrs[1] = buff
	else
		self.filterAttrs[1] = nil
	end
end

function SoulEquipSortWindow:willClose(params)
	BaseWindow.willClose(self, params)
end

return SoulEquipSortWindow
