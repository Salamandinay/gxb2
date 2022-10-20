local BaseWindow = import(".BaseWindow")
local SoulEquipExPreviewWindow = class("SoulEquipExPreviewWindow", BaseWindow)
local SoulEquipComfirmExchangeItem = class("SoulEquipComfirmExchangeItem", import("app.components.CopyComponent"))

function SoulEquipExPreviewWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.equip = params.equip
	self.slotIndex = params.slotIndex
	self.oldExID = params.oldExID

	dump(self.slotIndex)

	self.newExID = self.equip:getReplaces()[self.slotIndex]

	dump(self.newExID)
end

function SoulEquipExPreviewWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulEquipExPreviewWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.labelWindowTitle = self.groupAction:ComponentByName("labelWindowTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.topGoup = self.groupAction:NodeByName("topGoup").gameObject
	self.resItem1 = self.topGoup:NodeByName("resItem1").gameObject
	self.iconRes1 = self.resItem1:ComponentByName("icon", typeof(UISprite))
	self.labelRes1 = self.resItem1:ComponentByName("labelRes", typeof(UILabel))
	self.resItem2 = self.topGoup:NodeByName("resItem2").gameObject
	self.iconRes2 = self.resItem2:ComponentByName("icon", typeof(UISprite))
	self.labelRes2 = self.resItem2:ComponentByName("labelRes", typeof(UILabel))
	self.midGroup = self.groupAction:NodeByName("midGroup").gameObject
	self.arrow = self.midGroup:ComponentByName("arrow", typeof(UISprite))
	self.oldContent = self.midGroup:NodeByName("oldContent").gameObject
	self.labelTitleOld = self.oldContent:ComponentByName("labelTitle", typeof(UILabel))
	self.labelAttrOld = self.oldContent:ComponentByName("labelAttr", typeof(UILabel))
	self.newContent = self.midGroup:NodeByName("newContent").gameObject
	self.labelTitleNew = self.newContent:ComponentByName("labelTitle", typeof(UILabel))
	self.labelAttrNew = self.newContent:ComponentByName("labelAttr", typeof(UILabel))
	self.labelUnknowNew = self.newContent:ComponentByName("labelUnknow", typeof(UILabel))
	self.effectPos = self.newContent:ComponentByName("effectPos", typeof(UITexture))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.costGroup = self.bottomGroup:NodeByName("costGroup").gameObject
	self.costGroupLayout = self.bottomGroup:ComponentByName("costGroup", typeof(UILayout))
	self.costItem1 = self.costGroup:NodeByName("costItem1").gameObject
	self.iconCost1 = self.costItem1:ComponentByName("icon", typeof(UISprite))
	self.labelCost1 = self.costItem1:ComponentByName("labelCost", typeof(UILabel))
	self.costItem2 = self.costGroup:NodeByName("costItem2").gameObject
	self.iconCost2 = self.costItem2:ComponentByName("icon", typeof(UISprite))
	self.labelCost2 = self.costItem2:ComponentByName("labelCost", typeof(UILabel))
	self.btnSave = self.bottomGroup:NodeByName("btnSave").gameObject
	self.labelSave = self.btnSave:ComponentByName("labelSave", typeof(UILabel))
	self.btnExchange = self.bottomGroup:NodeByName("btnExchange").gameObject
	self.labelExchange = self.btnExchange:ComponentByName("labelExchange", typeof(UILabel))
end

function SoulEquipExPreviewWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnSave).onClick = function ()
		xyd.models.slot:reqSaveExBuff1(self.equip:getSoulEquipID(), self.slotIndex, function ()
			self.equip:setExAttr(self.newExID, self.slotIndex)
			self.equip:setReplace(nil, self.slotIndex)

			self.oldExID = self.newExID
			self.newExID = nil

			self:close()
		end)
	end

	UIEventListener.Get(self.btnExchange).onClick = function ()
		local cost = nil

		if (not self.oldExID or self.oldExID <= 0) and (not self.newExID or self.newExID <= 0) then
			cost = xyd.tables.miscTable:split2Cost("soul_equip1_ex_first_cost", "value", "|#")
		else
			cost = xyd.tables.miscTable:split2Cost("soul_equip1_ex_cost", "value", "|#")
		end

		for i = 1, #cost do
			if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[i][1])))

				return
			end
		end

		if self.haveClick then
			return
		end

		self.haveClick = true

		xyd.models.slot:reqChangeExBuff1(self.equip:getSoulEquipID(), self.slotIndex, function (newExID)
			if not self.oldExID or self.oldExID <= 0 then
				self.equip:setExAttr(newExID, self.slotIndex)

				self.oldExID = newExID
				self.newExID = nil
			else
				self.newExID = newExID

				self.equip:setReplace(newExID, self.slotIndex)
			end

			local effect = self.onChangeEffect

			if effect == nil then
				effect = xyd.Spine.new(self.effectPos.gameObject)
				self.onChangeEffect = effect

				effect:setInfo("anniuzhuanhuan", function ()
					if not self then
						return
					end

					effect:SetLocalPosition(-174, 9, 0)
					effect:SetLocalScale(1, 1, 1)
					effect:play("texiao01", 1)
					effect:play("texiao01", 1, 1, function ()
						self:update()

						self.haveClick = false
					end, true)
				end)
			else
				effect:play("texiao01", 1, 1, function ()
					self:update()

					self.haveClick = false
				end, true)
			end
		end)
	end
end

function SoulEquipExPreviewWindow:layout()
	self.labelWindowTitle.text = __("SOUL_EQUIP_TEXT55")
	self.labelSave.text = __("SOUL_EQUIP_TEXT58")
	self.labelExchange.text = __("SOUL_EQUIP_TEXT55")
	self.labelUnknowNew.text = __("SOUL_EQUIP_TEXT57")
	self.labelTitleOld.text = __("SOUL_EQUIP_TEXT" .. 49 + self.slotIndex)
	self.labelTitleNew.text = __("SOUL_EQUIP_TEXT" .. 49 + self.slotIndex)

	self:update()
end

function SoulEquipExPreviewWindow:update()
	local cost = nil

	if (not self.oldExID or self.oldExID <= 0) and (not self.newExID or self.newExID <= 0) then
		cost = xyd.tables.miscTable:split2Cost("soul_equip1_ex_first_cost", "value", "|#")
	else
		cost = xyd.tables.miscTable:split2Cost("soul_equip1_ex_cost", "value", "|#")
	end

	xyd.setUISpriteAsync(self.iconCost1, nil, xyd.tables.itemTable:getIcon(cost[1][1]))
	xyd.setUISpriteAsync(self.iconCost2, nil, xyd.tables.itemTable:getIcon(cost[2][1]))

	for i = 1, 2 do
		if xyd.models.backpack:getItemNumByID(cost[i][1]) < cost[i][2] then
			self["labelCost" .. i].color = Color.New2(3422556671.0)
		else
			self["labelCost" .. i].color = Color.New2(960513791)
		end
	end

	self.labelCost1.text = cost[1][2]
	self.labelCost2.text = cost[2][2]

	xyd.setUISpriteAsync(self.iconRes1, nil, xyd.tables.itemTable:getIcon(cost[1][1]))
	xyd.setUISpriteAsync(self.iconRes2, nil, xyd.tables.itemTable:getIcon(cost[2][1]))

	self.labelRes1.text = xyd.models.backpack:getItemNumByID(cost[1][1])
	self.labelRes2.text = xyd.models.backpack:getItemNumByID(cost[2][1])

	if not self.oldExID or self.oldExID <= 0 then
		self.labelAttrOld.text = __("SOUL_EQUIP_TEXT57")
	else
		local attr = {}
		local exID = self.oldExID
		local buff = xyd.tables.soulEquip1ExBuffTable:getBuff(exID)
		local baseAttr = xyd.tables.soulEquip1ExBuffTable:getBase(exID)
		local singleGrow = xyd.tables.soulEquip1ExBuffTable:getGrow(exID)
		local buffValue = baseAttr + singleGrow * self.equip:getLevel()
		attr = {
			buff,
			buffValue
		}
		local valueText = attr[2]
		local bt = xyd.tables.dBuffTable

		if bt:isShowPercent(attr[1]) then
			local factor = bt:getFactor(attr[1])
			valueText = string.format("%.2f", valueText * 100 / bt:getFactor(attr[1]))
			valueText = tostring(valueText) .. "%"
		else
			valueText = math.floor(valueText)
		end

		self.labelAttrOld.text = "+" .. valueText .. " " .. xyd.tables.dBuffTable:getDesc(attr[1])
	end

	if not self.newExID or self.newExID <= 0 then
		self.labelTitleNew:SetActive(false)
		self.labelAttrNew:SetActive(false)
		self.labelUnknowNew:SetActive(true)
		self.btnSave:SetActive(false)
		self.btnExchange:X(0)
	else
		self.labelTitleNew:SetActive(true)
		self.labelAttrNew:SetActive(true)
		self.labelUnknowNew:SetActive(false)
		self.btnSave:SetActive(true)
		self.btnExchange:X(-133)
		self.btnSave:X(133)

		local attr = {}
		local exID = self.newExID
		local buff = xyd.tables.soulEquip1ExBuffTable:getBuff(exID)
		local baseAttr = xyd.tables.soulEquip1ExBuffTable:getBase(exID)
		local singleGrow = xyd.tables.soulEquip1ExBuffTable:getGrow(exID)
		local buffValue = baseAttr + singleGrow * self.equip:getLevel()
		attr = {
			buff,
			buffValue
		}
		local valueText = attr[2]
		local bt = xyd.tables.dBuffTable

		if bt:isShowPercent(attr[1]) then
			local factor = bt:getFactor(attr[1])
			valueText = string.format("%.1f", valueText * 100 / bt:getFactor(attr[1]))
			valueText = tostring(valueText) .. "%"
		end

		self.labelAttrNew.text = "+" .. valueText .. " " .. xyd.tables.dBuffTable:getDesc(attr[1])
	end
end

function SoulEquipExPreviewWindow:dispose()
	SoulEquipExPreviewWindow.super.dispose(self)

	local wnd = xyd.getWindow("soul_equip1_strengthen_window")

	if wnd then
		wnd:updateContent3()
	end
end

return SoulEquipExPreviewWindow
