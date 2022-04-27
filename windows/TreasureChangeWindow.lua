local BaseWindow = import(".BaseWindow")
local TreasureChangeWindow = class("TreasureChangeWindow", BaseWindow)
local ResItem = import("app.components.ResItem")
local ItemIcon = import("app.components.ItemIcon")

function TreasureChangeWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.Effects = {}
	self.itemID = params.itemID
	self.equipedPartnerID = params.equipedPartnerID
	self.equipedPartner = params.equipedPartner
	self.afterItemID = params.tmpTreasure
end

function TreasureChangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	local top = winTrans:NodeByName("top").gameObject
	self.backBtn = top:NodeByName("backBtn").gameObject
	self.labelTitle = top:ComponentByName("labelTitle", typeof(UILabel))
	local resGroup = winTrans:NodeByName("resGroup").gameObject
	local res1 = resGroup:NodeByName("res1").gameObject
	self.res1 = ResItem.new(res1)
	local res2 = resGroup:NodeByName("res2").gameObject
	self.res2 = ResItem.new(res2)
	local changeGroup = winTrans:NodeByName("changeGroup").gameObject
	local before = changeGroup:NodeByName("beforeGroup").gameObject
	local beforeIcon = before:NodeByName("beforeIcon").gameObject
	self.beforeIcon = ItemIcon.new(beforeIcon)

	self.beforeIcon:setScale(0.5)

	self.beforeAttr = before:NodeByName("beforeAttr").gameObject
	self.beforeAttrTable = self.beforeAttr:GetComponent(typeof(UITable))
	self.beforeName = before:ComponentByName("beforeName", typeof(UILabel))
	self.attrLabelObj = before:NodeByName("attrLabel").gameObject
	local after = changeGroup:NodeByName("afterGroup").gameObject
	self.unknownTreasure = after:NodeByName("unknownTreasure").gameObject
	self.labelUnknown = self.unknownTreasure:ComponentByName("labelUnknown", typeof(UILabel))
	self.afterTreasure = after:NodeByName("afterTreasure").gameObject
	local afterIcon = self.afterTreasure:NodeByName("afterIcon").gameObject
	self.afterIcon = ItemIcon.new(afterIcon)

	self.afterIcon:setScale(0.5)

	self.afterName = self.afterTreasure:ComponentByName("afterName", typeof(UILabel))
	self.afterAttr = self.afterTreasure:NodeByName("afterAttr").gameObject
	self.afterAttrTable = self.afterAttr:GetComponent(typeof(UITable))
	self.groupEffect = changeGroup:NodeByName("groupEffect").gameObject
	self.saveEffect = changeGroup:NodeByName("saveEffect").gameObject
	local costGroup = winTrans:NodeByName("costGroup").gameObject
	self.labelCostRes1 = costGroup:ComponentByName("labelCostRes1", typeof(UILabel))
	self.labelCostRes2 = costGroup:ComponentByName("labelCostRes2", typeof(UILabel))
	local btnGroup = winTrans:NodeByName("btnGroup").gameObject
	self.btnGroupGride = btnGroup:GetComponent(typeof(UIGrid))
	self.btnChangeGroup = btnGroup:NodeByName("btnChangeGroup").gameObject
	self.btnChange = self.btnChangeGroup:NodeByName("btnChange").gameObject
	self.btnChangeLabel = self.btnChange:ComponentByName("button_label", typeof(UILabel))
	self.btnSaveGroup = btnGroup:NodeByName("btnSaveGroup").gameObject
	self.btnSave = self.btnSaveGroup:NodeByName("btnSave").gameObject
	self.btnSaveLabel = self.btnSave:ComponentByName("button_label", typeof(UILabel))
	self.labelSkip = winTrans:ComponentByName("labelSkip", typeof(UILabel))
end

function TreasureChangeWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initTreasureGroup()
	self:initCost()
	self:setAfterTreasureGroup()

	self.labelSkip.text = __("CLICK_WHITE_AREA_SKIP")

	self.labelSkip:SetActive(false)
	self.saveEffect:SetActive(false)

	if self.equipedPartner.treasures and self.equipedPartner.treasures[1] then
		self.btnSaveLabel.text = __("TREASURE_CHOOSE")
		UIEventListener.Get(self.btnSave).onClick = handler(self, self.onclickBtnSelect)
	else
		self.btnSaveLabel.text = __("SAVE")
		UIEventListener.Get(self.btnSave).onClick = handler(self, self.onclickBtnSave)
	end

	xyd.setBgColorType(self.btnSave, xyd.ButtonBgColorType.blue_btn_65_65)

	self.btnChangeLabel.text = __("TRANSFORM")

	xyd.setBgColorType(self.btnChange, xyd.ButtonBgColorType.blue_btn_65_65)

	self.labelUnknown.text = __("UNKNOWN_TREASURE")
	UIEventListener.Get(self.btnChange).onClick = handler(self, self.onclickBtnChange)
	UIEventListener.Get(self.saveEffect.gameObject).onClick = handler(self, self.onSaveEffectCallBack)

	self:setCloseBtn(self.backBtn)

	self.labelTitle.text = __("TREASURE_CHANGE_TITLE")

	self:registerEvent()
end

function TreasureChangeWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.TREASURE_REFRESH, self.onChange, self)
	self.eventProxy_:addEventListener(xyd.event.TREASURE_SAVE, self.onSave, self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, self.updateTextColor, self)
end

function TreasureChangeWindow:initTreasureGroup()
	self:initDesc()
	self:initIcon()
end

function TreasureChangeWindow:setAfterTreasureGroup()
	if self.afterItemID and self.afterItemID ~= 0 then
		local data = self:getDesc(self.afterItemID)
		local descs_ = {}

		NGUITools.DestroyChildren(self.afterAttr.transform)

		if data.text ~= "" then
			local labelObj = NGUITools.AddChild(self.afterAttr, self.attrLabelObj)
			local label = labelObj:GetComponent(typeof(UILabel))
			label.color = Color.New2(data.color)
			label.text = data.text

			table.insert(descs_, label)
		end

		self.afterAttrTable:Reposition()
		self.afterIcon:setInfo({
			itemID = self.afterItemID
		})

		self.afterName.text = __(xyd.tables.itemTable:getName(self.afterItemID))

		self.afterTreasure:SetActive(true)
		self.unknownTreasure:SetActive(false)
		self.btnSaveGroup:SetActive(true)
		print("==============================")
	else
		self.afterTreasure:SetActive(false)
		self.afterTreasure:SetActive(false)
		self.unknownTreasure:SetActive(true)
		self.btnSaveGroup:SetActive(false)
	end

	self.btnGroupGride:Reposition()
	self:setTimeout(function ()
		xyd.setTouchEnable(self.btnChange, true)
	end, self, 500)
end

function TreasureChangeWindow:initCost()
	print(self.itemID)

	local cost = xyd.tables.equipTable:getTreasureChangeCost(self.itemID)
	self.labelCostRes1.text = xyd.getRoughDisplayNumber(cost[xyd.ItemID.MANA])
	local magic_dust_num = cost[xyd.ItemID.MAGIC_DUST]
	magic_dust_num = math.ceil(tonumber(magic_dust_num) * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))
	self.labelCostRes2.text = tostring(magic_dust_num)

	self:updateTextColor()
	self.res1:setInfo({
		stroke = 0,
		tableId = xyd.ItemID.MANA
	})
	self.res2:setInfo({
		hidePlus = true,
		stroke = 0,
		tableId = xyd.ItemID.MAGIC_DUST
	})

	self.resItemList = {}

	table.insert(self.resItemList, self.res1)
	table.insert(self.resItemList, self.res2)
end

function TreasureChangeWindow:updateTextColor()
	local cost = xyd.tables.equipTable:getTreasureChangeCost(self.itemID)
	local bp = xyd.models.backpack
	local own_MANA = bp:getItemNumByID(xyd.ItemID.MANA)
	local own_MAGIC_DUST = bp:getItemNumByID(xyd.ItemID.MAGIC_DUST)

	if own_MANA < cost[xyd.ItemID.MANA] then
		self.labelCostRes1.color = Color.New2(3422556671.0)
	else
		self.labelCostRes1.color = Color.New2(1432789759)
	end

	local magic_dust_num = cost[xyd.ItemID.MAGIC_DUST]
	magic_dust_num = math.ceil(tonumber(magic_dust_num) * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))

	if own_MAGIC_DUST < magic_dust_num then
		self.labelCostRes2.color = Color.New2(3422556671.0)
	else
		self.labelCostRes2.color = Color.New2(1432789759)
	end

	self.res1:setItemNum(own_MANA)
	self.res2:setItemNum(own_MAGIC_DUST)
end

function TreasureChangeWindow:onclickBtnChange()
	local cost = xyd.tables.equipTable:getTreasureChangeCost(self.itemID)
	local bp = xyd.models.backpack
	local magic_dust_num = cost[xyd.ItemID.MAGIC_DUST]
	magic_dust_num = math.ceil(tonumber(magic_dust_num) * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))

	if bp:getItemNumByID(xyd.ItemID.MANA) < cost[xyd.ItemID.MANA] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

		return
	elseif bp:getItemNumByID(xyd.ItemID.MAGIC_DUST) < magic_dust_num then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MAGIC_DUST)))

		return
	end

	xyd.setTouchEnable(self.btnChange, false)
	self.equipedPartner:treasureRefresh()
end

function TreasureChangeWindow:onChange(event)
	local partner_id = event.data.partner_id

	if partner_id == self.equipedPartner:getPartnerID() then
		self.afterItemID = event.data.tmp_treasure
		local effect = self.onChangeEffect

		if effect == nil then
			effect = xyd.Spine.new(self.groupEffect)

			effect:setInfo("anniuzhuanhuan", function ()
				if not self then
					return
				end

				self.onChangeEffect = effect

				effect:SetLocalPosition(0, 0, 0)
				effect:SetLocalScale(1, 1, 1)
				effect:setRenderTarget(self.groupEffect:GetComponent(typeof(UIWidget)), 1)
				effect:play("texiao01", 1)
				self:setTimeout(function ()
					self:setAfterTreasureGroup()
				end, self, 500)
			end)
		else
			effect:play("texiao01", 1)
			self:setTimeout(function ()
				self:setAfterTreasureGroup()
			end, self, 500)
		end
	end
end

function TreasureChangeWindow:onclickBtnSave()
	self.equipedPartner:treasureSave()
end

function TreasureChangeWindow:onclickBtnSelect()
	xyd.openWindow("treasure_select_window", {
		type = 2,
		afterItemID = self.afterItemID,
		equipedPartnerID = self.equipedPartnerID,
		equipedPartner = self.equipedPartner
	})
end

function TreasureChangeWindow:onSaveEffectCallBack()
	if not self then
		return
	end

	self.onSaveEffect:stop()
	self.saveEffect:SetActive(false)
	self.labelSkip:SetActive(false)

	event = self.saveEvent

	if event.data.partner_info.partner_id == self.equipedPartner:getPartnerID() then
		self.itemID = event.data.partner_info.equips[xyd.EquipPos.TREASURE]
		self.afterItemID = nil

		self:initCost()
		self:initTreasureGroup()
		self:setAfterTreasureGroup()

		local items = {}

		table.insert(items, {
			item_num = 1,
			item_id = event.data.treasure
		})
		xyd.alertItems(items)
	end
end

function TreasureChangeWindow:onSave(event)
	self.saveEffect:SetActive(true)
	self.labelSkip:SetActive(true)

	self.saveEvent = event

	xyd.setTouchEnable(self.btnChange, false)

	local effect = self.onSaveEffect

	if effect == nil then
		effect = xyd.Spine.new(self.saveEffect)

		effect:setInfo("fx_ui_jinjie", function ()
			self.onSaveEffect = effect

			effect:SetLocalPosition(0, 0, 0)
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(self.saveEffect:GetComponent(typeof(UIWidget)), 1)
			effect:play("texiao01", 1, 1, function ()
				self:onSaveEffectCallBack()
			end)
		end)
	else
		effect:play("texiao01", 1, 1, function ()
			self:onSaveEffectCallBack()
		end)
	end

	self:setTimeout(function ()
		xyd.setTouchEnable(self.btnChange, true)
	end, self, 3000)
end

function TreasureChangeWindow:getDesc(itemID)
	itemID = itemID or self.itemID
	local desc = ""
	local color = 960513791
	desc = xyd.tables.equipTable:getDesc(itemID)

	return {
		text = desc,
		color = color
	}
end

function TreasureChangeWindow:initDesc()
	local data = self:getDesc(self.itemID)
	local descs_ = {}

	NGUITools.DestroyChildren(self.beforeAttr.transform)

	if data.text ~= "" then
		local labelObj = NGUITools.AddChild(self.beforeAttr, self.attrLabelObj)
		local label = labelObj:GetComponent(typeof(UILabel))
		label.color = Color.New2(data.color)
		label.text = data.text

		table.insert(descs_, label)
	end

	self.beforeAttrTable:Reposition()
end

function TreasureChangeWindow:initIcon()
	self.beforeIcon:setInfo({
		itemID = self.itemID
	})

	self.beforeName.text = __(xyd.tables.itemTable:getName(self.itemID))
end

function TreasureChangeWindow:willClose()
	BaseWindow.willClose(self)

	for i = 1, #self.Effects do
	end
end

return TreasureChangeWindow
