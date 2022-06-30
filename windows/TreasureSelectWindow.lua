local BaseWindow = import(".BaseWindow")
local TreasureSelectWindow = class("TreasureSelectWindow", BaseWindow)
local TreasureSelectItem = class("TreasureSelectItem", import("app.components.BaseComponent"))

function TreasureSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.type = params.type
	self.itemID = params.itemID
	self.equipedPartnerID = params.equipedPartnerID
	self.equipedPartner = params.equipedPartner
	self.afterItemID = params.afterItemID
	self.initSelectIndex = self.equipedPartner.select_treasure
	self.selectedIndex = self.equipedPartner.select_treasure
	self.quickItem_ = params.quickItem
end

function TreasureSelectWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initTreasures()
	self:register()
end

function TreasureSelectWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.titleLabel = groupAction:ComponentByName("titleLabel", typeof(UILabel))
	self.itemGroup = groupAction:NodeByName("itemGroup").gameObject
	self.coverBtn = groupAction:NodeByName("coverBtn").gameObject
	self.helpBtn = groupAction:NodeByName("helpBtn").gameObject
end

function TreasureSelectWindow:initUIComponent()
	if self.type == 1 then
		self.titleLabel.text = __("TREASURE_CHOOSE")
	elseif self.type == 2 then
		self.titleLabel.text = __("TREASURE_COVER_TITLE")
		self.window_:ComponentByName("groupAction/Bg_", typeof(UISprite)).height = 690

		self.itemGroup:Y(30)
		self.coverBtn:SetActive(true)

		self.coverBtn:ComponentByName("button_label", typeof(UILabel)).text = __("TREASURE_COVER")
	end
end

function TreasureSelectWindow:initTreasures()
	local cost = xyd.tables.miscTable:split2Cost("treasure_reserve_unlock", "value", "|#")

	if self.equipedPartner.treasures and self.equipedPartner.treasures[1] then
		self.treasures = self.equipedPartner.treasures
	else
		self.treasures = {
			self.itemID,
			-1,
			-1
		}
	end

	self.items = {}

	for i = 1, 3 do
		local params = {
			itemID = self.treasures[i],
			cost = cost[i],
			isSelect = i == self.initSelectIndex,
			index = i,
			partner_id = self.equipedPartnerID,
			type = self.type
		}
		local item = TreasureSelectItem.new(self.itemGroup, params, self)

		table.insert(self.items, item)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	self.selectedItem = self.items[self.selectedIndex]
end

function TreasureSelectWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_UNLOCK, handler(self, self.updateState))
	self.eventProxy_:addEventListener(xyd.event.TREASURE_SAVE, handler(self, self.onSave))

	UIEventListener.Get(self.coverBtn).onClick = function ()
		self:onCover()
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "TREASURE_HELP"
		})
	end
end

function TreasureSelectWindow:updateState(event)
	self.treasures = event.data.treasures

	for i = 1, #self.items do
		self.items[i]:updateLockState(self.treasures[i])
	end
end

function TreasureSelectWindow:onCover()
	local flag = false

	for i = 1, 3 do
		if self.afterItemID == self.treasures[i] then
			flag = true
		end
	end

	if flag then
		xyd.alert(xyd.AlertType.YES_NO, __("TREASURE_SAME_HELP"), function (yes)
			if yes then
				xyd.alert(xyd.AlertType.YES_NO, __("TREASURE_COVER_HELP"), function (yes)
					if yes then
						self.equipedPartner:treasureSave(self.selectedIndex)
					end
				end)
			end
		end)
	else
		xyd.alert(xyd.AlertType.YES_NO, __("TREASURE_COVER_HELP"), function (yes)
			if yes then
				self.equipedPartner:treasureSave(self.selectedIndex)
			end
		end)
	end
end

function TreasureSelectWindow:onSave(event)
	xyd.closeWindow("treasure_select_window")
end

function TreasureSelectWindow:willClose()
	BaseWindow.willClose(self)

	if self.quickItem_ then
		if self.type == 1 and self.selectedIndex and self.selectedIndex ~= self.initSelectIndex then
			self.equipedPartner.select_treasure = self.selectedIndex
			self.equipedPartner.equipments[xyd.EquipPos.TREASURE] = self.equipedPartner.treasures[self.selectedIndex]

			self.quickItem_:updateEquips()

			local win = xyd.WindowManager.get():getWindow("quick_formation_partner_detail_window")

			if win then
				win:updateWindowShow()
			end
		end

		return
	end

	if self.type == 1 and self.selectedIndex and self.selectedIndex ~= self.initSelectIndex then
		local msg = messages_pb.treasure_select_req()
		msg.partner_id = self.equipedPartnerID
		msg.index = self.selectedIndex

		xyd.Backend.get():request(xyd.mid.TREASURE_SELECT, msg)
	end
end

function TreasureSelectItem:ctor(parentGO, params, parent)
	self.itemID = params.itemID
	self.cost = params.cost
	self.isSelect = params.isSelect
	self.index = params.index
	self.partner_id = params.partner_id
	self.type = params.type
	self.parent = parent
	self.waitingForBackUp = false
	self.waitingForDelete = false

	TreasureSelectItem.super.ctor(self, parentGO)
end

function TreasureSelectItem:getPrefabPath()
	return "Prefabs/Components/treasure_select_item"
end

function TreasureSelectItem:initUI()
	TreasureSelectItem.super.initUI(self)

	self.itemNode = self.go:NodeByName("itemGroup/itemNode").gameObject
	self.selectItem = self.go:ComponentByName("selectItem", typeof(UISprite))
	self.selectMask_ = self.go:NodeByName("selectMask_").gameObject
	self.deleteBtn = self.go:NodeByName("deleteBtn").gameObject
	self.nameLabel = self.go:ComponentByName("nameLabel", typeof(UILabel))

	if self.itemID > 0 then
		local item = xyd.getItemIcon({
			uiRoot = self.itemNode,
			itemID = self.itemID
		})

		item:setLockLowerRight(self.index ~= 1)

		self.desLabel = self.go:ComponentByName("desLabel", typeof(UILabel))

		if self.index == 1 then
			self.nameLabel.text = xyd.tables.itemTable:getName(self.itemID)
		else
			self.nameLabel.text = __("TREASURE_RESERVE", xyd.tables.itemTable:getName(self.itemID))
		end

		xyd.labelQulityColor(self.nameLabel, self.itemID)

		self.desLabel.text = xyd.tables.equipTable:getDesc(self.itemID)

		self.desLabel:SetActive(true)

		if self.index ~= 1 then
			self.deleteBtn:SetActive(true)
		end
	else
		self.nameLabel.text = __("TREASURE_RESERVE_NUM", self.index - 1)

		self.deleteBtn:SetActive(false)
	end

	UIEventListener.Get(self.selectMask_.gameObject).onClick = handler(self, self.onSelect)
	UIEventListener.Get(self.deleteBtn).onClick = handler(self, self.onDelete)

	self:registerEvent(xyd.event.TREASURE_BACKUP, handler(self, self.updateState))
	self:registerEvent(xyd.event.TREASURE_DEL, handler(self, self.DeleteTreasure))
	self:updateLockState()
end

function TreasureSelectItem:updateState(event)
	if self.waitingForBackUp then
		self.waitingForBackUp = false
		self.itemID = event.data.treasure

		self.parent.equipedPartner:updateIndexedTreasure(self.index, event.data.treasure)
		self:initUI()
	end
end

function TreasureSelectItem:updateLockState(itemID)
	if itemID then
		self.itemID = itemID
	end

	if self.itemID >= 0 then
		self.isUnlock = true
	else
		self.isUnlock = false
	end

	local unlockLabel = self.go:ComponentByName("unlockLabel", typeof(UILabel))
	local unlockBtn = self.go:NodeByName("unlockBtn").gameObject

	if self.itemID > 0 or self.type == 2 and self.isUnlock then
		self.selectItem:SetActive(true)
	end

	if self.isUnlock then
		self.go:ComponentByName("itemGroup/lock", typeof(UISprite)):SetActive(false)

		if self.isSelect then
			xyd.setUISpriteAsync(self.selectItem, nil, "setting_up_pick")
			self.deleteBtn:SetActive(false)
		else
			xyd.setUISpriteAsync(self.selectItem, nil, "setting_up_unpick")
		end

		unlockBtn:SetActive(false)
		unlockLabel:SetActive(false)
	else
		unlockLabel.text = __("TREASURE_NOT_UNLOCK")
		unlockBtn:ComponentByName("button_label", typeof(UILabel)).text = __("TREASURE_UNLOCK")

		xyd.setUISpriteAsync(unlockBtn:ComponentByName("icon", typeof(UISprite)), nil, "icon_" .. self.cost[1] .. "_small")

		unlockBtn:ComponentByName("numLabel", typeof(UILabel)).text = self.cost[2]

		UIEventListener.Get(unlockBtn).onClick = function ()
			self:unLockItem()
		end

		unlockBtn:SetActive(true)
		unlockLabel:SetActive(true)
		self.deleteBtn:SetActive(false)
	end

	if self.parent.quickItem_ then
		unlockBtn:SetActive(false)
		self.deleteBtn:SetActive(false)
	end
end

function TreasureSelectItem:unLockItem()
	if xyd.models.backpack:getItemNumByID(self.cost[1]) < self.cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1])))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("TREASURE_UNLOCK_HELP", self.cost[2]), function (yes)
		if yes then
			local msg = messages_pb.treasure_unlock_req()
			msg.partner_id = self.partner_id
			msg.index = self.index

			xyd.Backend.get():request(xyd.mid.TREASURE_UNLOCK, msg)
		end
	end)
end

function TreasureSelectItem:onSelect()
	if self.itemID > 0 or self.type == 2 and self.isUnlock then
		if not self.parent.selectedIndex or self.parent.selectedIndex ~= self.index then
			xyd.setUISpriteAsync(self.selectItem, nil, "setting_up_pick")
			self.deleteBtn:SetActive(false)

			self.parent.selectedIndex = self.index

			if self.parent.selectedItem ~= nil then
				if self.parent.selectedItem.index ~= 1 and not self.parent.quickItem_ then
					self.parent.selectedItem.deleteBtn:SetActive(true)
				end

				xyd.setUISpriteAsync(self.parent.selectedItem.selectItem, nil, "setting_up_unpick")
			end

			self.parent.selectedItem = self
		end
	elseif self.type == 1 and self.itemID <= 0 then
		if not self.isUnlock then
			return
		end

		if self.parent.quickItem_ then
			xyd.alertTips(__("QUICK_FORMATION_TEXT02"))

			return
		end

		xyd.alert(xyd.AlertType.YES_NO, __("TREASURE_RESERVE_EMPTY", self.index - 1), function (yes)
			if yes then
				self.waitingForBackUp = true
				local msg = messages_pb:treasure_backup_req()
				msg.partner_id = self.partner_id
				msg.index = self.index

				xyd.Backend.get():request(xyd.mid.TREASURE_BACKUP, msg)
			end
		end)
	end
end

function TreasureSelectItem:onDelete()
	xyd.alertYesNo(__("TREASURE_RESERVE_DETELE"), function (yes)
		if yes then
			self.waitingForDelete = true
			local msg = messages_pb.treasure_del_req()
			msg.partner_id = self.partner_id
			msg.index = self.index

			xyd.Backend.get():request(xyd.mid.TREASURE_DEL, msg)
		end
	end)
end

function TreasureSelectItem:DeleteTreasure(event)
	if self.waitingForDelete then
		self.waitingForDelete = false
		self.itemID = 0

		NGUITools.DestroyChildren(self.itemNode.transform)

		self.nameLabel.text = __("TREASURE_RESERVE_NUM", self.index - 1)
		self.nameLabel.color = Color.New2(960513791)

		self.desLabel:SetActive(false)
		self.deleteBtn:SetActive(false)
	end
end

return TreasureSelectWindow
