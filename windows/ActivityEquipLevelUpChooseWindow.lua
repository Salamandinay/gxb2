local ActivityEquipLevelUpChooseWindow = class("ActivityEquipLevelUpChooseWindow", import(".BaseWindow"))

function ActivityEquipLevelUpChooseWindow:ctor(name, params)
	ActivityEquipLevelUpChooseWindow.super.ctor(self, name, params)

	self.callback = params.callback
	self.selectedSuit = tonumber(params.selectedSuit)
	self.chosenGroup = params.chosenGroup
	self.chosenStar = params.chosenStar
	self.show_num = params.show_num
end

function ActivityEquipLevelUpChooseWindow:initWindow()
	self:getUIComponent()
	self:initUI()
	self:register()
end

function ActivityEquipLevelUpChooseWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.confirmBtn = groupAction:NodeByName("confirmBtn").gameObject
	self.confirmLabel = self.confirmBtn:ComponentByName("label", typeof(UILabel))
	self.item = groupAction:NodeByName("item").gameObject
	self.itemGroup = groupAction:NodeByName("itemGroup").gameObject
end

function ActivityEquipLevelUpChooseWindow:initUI()
	self.titleLabel.text = __("EQUIP_LEVELUP_TITLE_1")
	self.confirmLabel.text = __("FOR_SURE")
	self.itemList = xyd.tables.activityEquipLevelUpSuitTable:getIds()
	local selectList = {}

	for i = 1, #self.itemList do
		local id = self.itemList[i]
		local suit = xyd.tables.activityEquipLevelUpSuitTable:getSuit(id)
		local item = NGUITools.AddChild(self.itemGroup, self.item)
		local itemGrid = item:NodeByName("itemGrid").gameObject

		for j = 1, 4 do
			local equip = itemGrid:NodeByName("equip" .. j).gameObject
			local icon = xyd.getItemIcon({
				scale = 0.8,
				uiRoot = equip,
				itemID = suit[j][1],
				num = suit[j][2]
			})

			if self.show_num then
				local hasNum = xyd.models.backpack:getItemNumByID(suit[j][1])

				if self.chosenStar == 1 and self.chosenGroup == i then
					hasNum = hasNum - 1 > 0 and hasNum - 1 or 0
				end

				icon.labelNum_.text = hasNum .. "/" .. suit[j][2]

				if hasNum < suit[j][2] then
					icon.labelNum_.color = Color.New2(3422556671.0)
					icon.labelNum_.effectStyle = UILabel.Effect.Outline
					icon.labelNum_.effectColor = Color.New2(4294967295.0)
				else
					icon.labelNum_.color = Color.New2(4294967295.0)
				end
			end
		end

		local selectBtn = item:NodeByName("selectBtn").gameObject
		local selected_icon = selectBtn:NodeByName("selected_icon").gameObject

		selected_icon:SetActive(self.selectedSuit == i)

		UIEventListener.Get(selectBtn).onClick = function ()
			if self.selectedSuit == i then
				selected_icon:SetActive(false)

				self.selectedSuit = 0
			else
				if self.selectedSuit ~= 0 then
					selectList[self.selectedSuit]:SetActive(false)
				end

				self.selectedSuit = i

				selected_icon:SetActive(true)
			end
		end

		table.insert(selectList, selected_icon)
	end

	self.itemGroup:GetComponent(typeof(UIGrid)):Reposition()
end

function ActivityEquipLevelUpChooseWindow:register()
	ActivityEquipLevelUpChooseWindow.super.register(self)

	UIEventListener.Get(self.confirmBtn).onClick = function ()
		if self.selectedSuit == 0 then
			xyd.showToast(__("EQUIP_LEVELUP_TEXT_4"))
		else
			if self.callback then
				self.callback(self.itemList[self.selectedSuit])
			end

			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end
end

return ActivityEquipLevelUpChooseWindow
