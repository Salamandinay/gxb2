local CommonEquipSuitChooseWindow = class("CommonEquipSuitChooseWindow", import(".BaseWindow"))
local CommonEquipSuitChooseItem = class("CommonEquipSuitChooseItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function CommonEquipSuitChooseWindow:ctor(name, params)
	CommonEquipSuitChooseWindow.super.ctor(self, name, params)

	self.title_text = params.title_text
	self.selectedSuit = params.selectedSuit
	self.show_num = params.show_num
	self.show_select_group = params.show_select_group
	self.items_info = {}
	self.callback = params.callback
	self.sortFunc = params.sortFunc
	self.selectedSuitObject = nil
	self.selectedGroup = nil
	self.tempTable = nil
	local tempTable = params.items_info

	for i = 1, #tempTable do
		table.insert(self.items_info, tempTable[i])
	end
end

function CommonEquipSuitChooseWindow:initWindow()
	self:getUIComponent()
	self:initUI()
	self:register()
end

function CommonEquipSuitChooseWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.confirmBtn = groupAction:NodeByName("confirmBtn").gameObject
	self.confirmLabel = self.confirmBtn:ComponentByName("label", typeof(UILabel))
	self.item = groupAction:NodeByName("item").gameObject
	self.contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.scroller = self.contentGroup:NodeByName("scroller").gameObject
	self.scrollView = self.scroller:ComponentByName("", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.selectGroup = groupAction:NodeByName("selectGroup").gameObject
end

function CommonEquipSuitChooseWindow:initUI()
	if self.title_text then
		self.titleLabel.text = self.title_text
	end

	self.confirmLabel.text = __("FOR_SURE")

	if self.show_select_group then
		self.selectGroup:SetActive(true)
	else
		self.selectGroup:SetActive(false)

		self.window_:ComponentByName("groupAction", typeof(UIWidget)).height = 782
		self.scroller:ComponentByName("", typeof(UIPanel)).baseClipRegion.w = 622
	end

	if self.sortFunc then
		table.sort(self.items_info, self.sortFunc)
	else
		local function sort_func(a, b)
			local a_star = xyd.tables.equipTable:getStar(a.equips_info[1].itemID)
			local b_star = xyd.tables.equipTable:getStar(b.equips_info[1].itemID)

			if a_star ~= b_star then
				if a_star == 6 then
					return true
				elseif b_star == 6 then
					return false
				else
					return a_star < b_star
				end
			end

			return xyd.tables.equipTable:getJob(a.equips_info[1].itemID) < xyd.tables.equipTable:getJob(b.equips_info[1].itemID)
		end

		table.sort(self.items_info, sort_func)
	end

	if self.wrapContent == nil then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item, CommonEquipSuitChooseItem, self)
	end

	self.wrapContent:setInfos(self.items_info, {})
end

function CommonEquipSuitChooseWindow:register()
	CommonEquipSuitChooseWindow.super.register(self)

	UIEventListener.Get(self.confirmBtn).onClick = function ()
		if self.selectedSuit == nil or self.selectedSuit == 0 then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_4"))
		else
			for i = 1, #self.items_info do
				if self.items_info[i].id == self.selectedSuit and self.callback then
					self.callback(self.items_info[i])
				end
			end

			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end

	for i = 1, 5 do
		local btn = self.selectGroup:NodeByName("gridOfGroup/itemGroup" .. i).gameObject

		UIEventListener.Get(btn).onClick = function ()
			if self.selectedGroup == nil or self.selectedGroup == 0 then
				self.selectedGroup = i
			elseif self.selectedGroup == i then
				self.selectedGroup = 0
			else
				self.selectedGroup = i
			end

			for j = 1, 5 do
				if j == self.selectedGroup then
					self.selectGroup:NodeByName("gridOfGroup/itemGroup" .. j .. "/groupChosen").gameObject:SetActive(true)
				else
					self.selectGroup:NodeByName("gridOfGroup/itemGroup" .. j .. "/groupChosen").gameObject:SetActive(false)
				end
			end

			if self.selectedGroup == 0 then
				self.wrapContent:setInfos(self.items_info, {})

				return
			end

			local newData = {}

			for j = 1, #self.items_info do
				local info = self.items_info[j]

				if xyd.tables.equipTable:getJob(info.equips_info[1].itemID) == self.selectedGroup then
					table.insert(newData, info)
				end
			end

			self.wrapContent:setInfos(newData, {})
		end
	end
end

function CommonEquipSuitChooseItem:ctor(go, parent)
	CommonEquipSuitChooseItem.super.ctor(self, go, parent)

	self.parent = parent
end

function CommonEquipSuitChooseItem:initUI()
	self.itemGrid = self.go:NodeByName("itemGrid").gameObject
	self.grid = self.go:ComponentByName("itemGrid", typeof(UIGrid))
	self.equip1 = self.itemGrid:NodeByName("equip1").gameObject
	self.equip2 = self.itemGrid:NodeByName("equip2").gameObject
	self.equip3 = self.itemGrid:NodeByName("equip3").gameObject
	self.equip4 = self.itemGrid:NodeByName("equip4").gameObject
	self.selectBtn = self.go:NodeByName("selectBtn").gameObject
	self.selected_icon = self.selectBtn:ComponentByName("selected_icon", typeof(UISprite))
end

function CommonEquipSuitChooseItem:updateInfo()
	print(tostring(self.data))

	self.id = self.data.id
	self.equips_info = self.data.equips_info

	for i = 1, 4 do
		NGUITools.DestroyChildren(self["equip" .. i].transform)

		local equip = self["equip" .. i]
		local info = self.equips_info[i]
		local icon = xyd.getItemIcon({
			scale = 1,
			uiRoot = equip,
			itemID = info.itemID,
			num = info.needNum,
			dragScrollView = self.parent.scrollView
		})

		if self.parent.show_num then
			local hasNum = xyd.models.backpack:getItemNumByID(info.itemID)
			icon.labelNum_.text = hasNum .. "/" .. info.needNum

			if hasNum < info.needNum then
				icon.labelNum_.color = Color.New2(3422556671.0)
				icon.labelNum_.effectStyle = UILabel.Effect.Outline
				icon.labelNum_.effectColor = Color.New2(4294967295.0)
			else
				icon.labelNum_.color = Color.New2(4294967295.0)
			end
		end
	end

	self.selected_icon:SetActive(self.parent.selectedSuit == self.id)

	if self.parent.selectedSuit == self.id then
		self.parent.selectedSuitObject = self.selected_icon
	end

	UIEventListener.Get(self.selectBtn).onClick = function ()
		if self.parent.selectedSuit == self.id then
			self.selected_icon:SetActive(false)

			self.parent.selectedSuit = 0
		else
			if self.parent.selectedSuit ~= 0 and self.parent.selectedSuitObject ~= nil then
				self.parent.selectedSuitObject:SetActive(false)
			end

			self.parent.selectedSuit = self.id

			self.selected_icon:SetActive(true)

			self.parent.selectedSuitObject = self.selected_icon
		end
	end
end

return CommonEquipSuitChooseWindow
