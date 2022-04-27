local BaseWindow = import(".BaseWindow")
local TreasureUpWindow = class("TreasureUpWindow", BaseWindow)
local ResItem = import("app.components.ResItem")
local ItemIcon = import("app.components.ItemIcon")

function TreasureUpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.Effects = {}
	self.itemID = params.itemID
	self.itemIDLock = xyd.tables.equipTable:getTreasureLock(self.itemID)
	self.equipedPartnerID = params.equipedPartnerID
	self.equipedPartner = params.equipedPartner
	self.is_uping = false
end

function TreasureUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.labelSkip = content:ComponentByName("labelSkip", typeof(UILabel))
	local top = content:NodeByName("top").gameObject
	self.backBtn = top:NodeByName("backBtn").gameObject
	self.labelTitle = top:ComponentByName("labelTitle", typeof(UILabel))
	local resGroup = content:NodeByName("resGroup").gameObject
	local res1 = resGroup:NodeByName("res1").gameObject
	self.res1 = ResItem.new(res1)
	local res2 = resGroup:NodeByName("res2").gameObject
	self.res2 = ResItem.new(res2)
	local res3 = resGroup:NodeByName("res3").gameObject
	self.res3 = ResItem.new(res3)
	local changeGroup = content:NodeByName("changeGroup").gameObject
	local before = changeGroup:NodeByName("before").gameObject
	local beforeIcon = before:NodeByName("beforeIcon").gameObject
	self.beforeIcon = ItemIcon.new(beforeIcon)

	self.beforeIcon:setScale(0.5)

	self.beforeAttr = before:NodeByName("beforeAttr").gameObject
	self.beforeAttrTable = self.beforeAttr:GetComponent(typeof(UITable))
	self.beforeName = before:ComponentByName("beforeName", typeof(UILabel))
	self.attrLabelObj = before:NodeByName("attrLabel").gameObject
	local after = changeGroup:NodeByName("after").gameObject
	self.groupUnknown = after:NodeByName("groupUnknown").gameObject
	self.labelUnknown = self.groupUnknown:ComponentByName("labelUnknown", typeof(UILabel))
	self.groupKnown = after:NodeByName("groupKnown").gameObject
	local afterIcon = self.groupKnown:NodeByName("afterIcon").gameObject
	self.afterIcon = ItemIcon.new(afterIcon)

	self.afterIcon:setScale(0.5)

	self.afterName = self.groupKnown:ComponentByName("afterName", typeof(UILabel))
	self.afterAttr = self.groupKnown:NodeByName("afterAttr").gameObject
	self.afterAttrTable = self.afterAttr:GetComponent(typeof(UITable))
	self.effectGroup = changeGroup:NodeByName("effectGroup").gameObject
	local costGroup = content:NodeByName("costGroup").gameObject
	self.labelCostRes1 = costGroup:ComponentByName("labelCostRes1", typeof(UILabel))
	self.labelCostRes2 = costGroup:ComponentByName("labelCostRes2", typeof(UILabel))
	local lockGroup = content:NodeByName("lockGroup").gameObject
	self.lockAttr = lockGroup:NodeByName("lockAttr").gameObject
	self.noLockAttr = lockGroup:NodeByName("noLockAttr").gameObject
	self.labelLockAttr = lockGroup:ComponentByName("labelLockAttr", typeof(UILabel))
	local btnGroup = content:NodeByName("btnGroup").gameObject
	self.btnUp = btnGroup:NodeByName("btnUp").gameObject
	self.btnUpLabel = self.btnUp:ComponentByName("button_label", typeof(UILabel))
	self.lockCost = btnGroup:NodeByName("btnUp/lockCost").gameObject
	self.labelLockCost = self.lockCost:ComponentByName("labelLockCost", typeof(UILabel))
	self.lockIcon = self.lockCost:ComponentByName("lockIcon", typeof(UISprite))
end

function TreasureUpWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initTreasureGroup()
	self:initLockAttr()
	self:initCost()

	self.labelSkip.text = __("CLICK_WHITE_AREA_SKIP")

	self.labelSkip:SetActive(false)
	self.effectGroup:SetActive(false)

	self.labelTitle.text = __("LEV_UP")
	self.btnUpLabel.text = __("LEV_UP")

	xyd.setBgColorType(self.btnUp, xyd.ButtonBgColorType.blue_btn_65_65)

	self.labelUnknown.text = __("UNKNOWN_TREASURE")

	UIEventListener.Get(self.btnUp).onClick = function ()
		self:checkCrystal(self.is_lockattr)
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.effectGroup.gameObject).onClick = function ()
		self:effectPlayCallback()
	end

	self:registerEvent()
end

function TreasureUpWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.TREASURE_UPGRADE, self.onUpgrade, self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, self.updateTextColor, self)
end

function TreasureUpWindow:initTreasureGroup()
	self:initDesc(self.itemID, self.beforeAttr)
	self:initDesc(self.itemIDLock, self.afterAttr)
	self.beforeAttrTable:Reposition()
	self.afterAttrTable:Reposition()
	self.groupKnown:SetActive(self.is_lockattr)
	self.groupUnknown:SetActive(not self.is_lockattr)
	self:initIcon()
end

function TreasureUpWindow:initLockAttr()
	self.lockAttr:SetActive(false)
	self.noLockAttr:SetActive(true)
	self.lockCost:SetActive(false)
	self.lockCost:SetActive(false)

	self.labelLockAttr.text = __("LOCK_NOW_ATTR")

	UIEventListener.Get(self.lockAttr).onClick = function ()
		self.lockAttr:SetActive(false)
		self.noLockAttr:SetActive(true)
		self.lockCost:SetActive(false)

		self.is_lockattr = false

		self.groupKnown:SetActive(false)
		self.groupUnknown:SetActive(true)
	end

	UIEventListener.Get(self.noLockAttr).onClick = function ()
		self.lockAttr:SetActive(true)
		self.noLockAttr:SetActive(false)
		self.lockCost:SetActive(true)

		self.is_lockattr = true

		self.groupKnown:SetActive(true)
		self.groupUnknown:SetActive(false)
	end
end

function TreasureUpWindow:initCost()
	local cost = xyd.tables.equipTable:getTreasureUpCost(self.itemID)
	self.labelCostRes1.text = xyd.getRoughDisplayNumber(cost[xyd.ItemID.MANA])
	local magic_dust_num = cost[xyd.ItemID.MAGIC_DUST]
	magic_dust_num = math.ceil(tonumber(magic_dust_num) * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))
	self.labelCostRes2.text = tostring(magic_dust_num)
	local path = tostring(xyd.tables.itemTable:getIcon(xyd.ItemID.CRYSTAL)) .. "_small"

	xyd.setUISprite(self.lockIcon, "icon_image", path)

	self.labelLockCost.text = xyd.tables.equipTable:getTreasureLockCost(self.itemID)
	self.btnUpLabel.text = __("LEV_UP")

	if self.lockAttr.activeSelf then
		self.lockCost:SetActive(true)
	else
		self.lockCost:SetActive(false)
	end

	self:updateTextColor()
	self.res1:setInfo({
		stroke = 0,
		tableId = xyd.ItemID.MANA
	})
	self.res2:setInfo({
		stroke = 0,
		tableId = xyd.ItemID.CRYSTAL
	})
	self.res3:setInfo({
		hidePlus = true,
		stroke = 0,
		tableId = xyd.ItemID.MAGIC_DUST
	})

	self.resItemList = {}

	table.insert(self.resItemList, self.res1)
	table.insert(self.resItemList, self.res2)
	table.insert(self.resItemList, self.res3)
end

function TreasureUpWindow:effectPlayCallback()
	if not self or not self.onUpgradeEffect or not self.upGrageEvent then
		return
	end

	local items = {}
	self.itemID = self.upGrageEvent.data.partner_info.equips[xyd.EquipPos.TREASURE]

	table.insert(items, {
		item_num = 1,
		item_id = self.itemID
	})

	local cost = xyd.tables.equipTable:getTreasureUpCost(self.itemID)

	if cost then
		self.itemIDLock = xyd.tables.equipTable:getTreasureLock(self.itemID)

		xyd.alertItems(items)
		self:initTreasureGroup()
		self:initCost()

		UIEventListener.Get(self.btnUp).onClick = function ()
			self:checkCrystal(self.is_lockattr)
		end
	else
		xyd.alertItems(items, function ()
			self:close()
		end)
	end

	self.labelSkip:SetActive(false)
	self.onUpgradeEffect:stop()
	self.effectGroup:SetActive(false)
	xyd.setTouchEnable(self.btnUp, true)
end

function TreasureUpWindow:onUpgrade(event)
	self.upGrageEvent = event

	self.labelSkip:SetActive(true)
	self.effectGroup:SetActive(true)

	local effect = self.onUpgradeEffect

	if effect == nil then
		effect = xyd.Spine.new(self.effectGroup)

		effect:setInfo("fx_ui_jinjie", function ()
			self.onUpgradeEffect = effect

			effect:SetLocalPosition(0, 0, 0)
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(self.effectGroup:GetComponent(typeof(UIWidget)), 1)
			effect:play("texiao01", 1, 1, function ()
				self:effectPlayCallback()
			end)
		end)
	else
		effect:play("texiao01", 1, 1, function ()
			self:effectPlayCallback()
		end)
	end
end

function TreasureUpWindow:updateTextColor()
	local cost = xyd.tables.equipTable:getTreasureUpCost(self.itemID)
	local bp = xyd.models.backpack

	if bp:getItemNumByID(xyd.ItemID.MANA) < cost[xyd.ItemID.MANA] then
		self.labelCostRes1.color = Color.New2(3422556671.0)
	else
		self.labelCostRes1.color = Color.New2(1432789759)
	end

	local magic_dust_num = cost[xyd.ItemID.MAGIC_DUST]
	magic_dust_num = math.ceil(tonumber(magic_dust_num) * (1 - xyd.models.dress:getBuffTypeAttr(xyd.DressBuffAttrType.CRYSTAL_KNIFE)))

	if bp:getItemNumByID(xyd.ItemID.MAGIC_DUST) < magic_dust_num then
		self.labelCostRes2.color = Color.New2(3422556671.0)
	else
		self.labelCostRes2.color = Color.New2(1432789759)
	end
end

function TreasureUpWindow:checkCrystal()
	local cost = xyd.tables.equipTable:getTreasureUpCost(self.itemID)
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

	if self.is_lockattr then
		if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < xyd.tables.equipTable:getTreasureLockCost(self.itemID) then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.CRYSTAL)))

			return
		end

		local checkTips = xyd.db.misc:getValue("treasure_up_time_stamp")

		if tonumber(checkTips) and xyd.isSameDay(tonumber(checkTips), xyd.getServerTime()) then
			self:onclickBtnUp()
		else
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "treasure_up",
				callback = function ()
					self:onclickBtnUp()
				end,
				text = __("TREASURE_EXCHANGE_WARN")
			})
		end
	else
		self:onclickBtnUp()
	end
end

function TreasureUpWindow:onclickBtnUp()
	xyd.setTouchEnable(self.btnUp, false)
	self.equipedPartner:treasureUpgrade(self.is_lockattr)
end

function TreasureUpWindow:getDesc(color, itemID)
	local desc = ""
	color = color or 960513791
	desc = xyd.tables.equipTable:getDesc(itemID or self.itemID)

	return {
		text = desc,
		color = color
	}
end

function TreasureUpWindow:initDesc(itemID, container)
	local data = self:getDesc(nil, itemID)

	NGUITools.DestroyChildren(container.transform)

	local descs_ = {}

	if data.text ~= "" then
		local labelObj = NGUITools.AddChild(container, self.attrLabelObj)
		local label = labelObj:GetComponent(typeof(UILabel))
		label.color = Color.New2(data.color)
		label.text = data.text

		if xyd.Global.lang == "fr_fr" then
			label.fontSize = 18
		end

		table.insert(descs_, label)
	end
end

function TreasureUpWindow:initIcon()
	self.beforeIcon:setInfo({
		itemID = self.itemID
	})

	self.beforeName.text = __(xyd.tables.itemTable:getName(self.itemID))

	self.afterIcon:setInfo({
		itemID = self.itemIDLock
	})

	self.afterName.text = __(xyd.tables.itemTable:getName(self.itemIDLock))
end

function TreasureUpWindow:willClose()
	BaseWindow.willClose(self)

	for i = 1, #self.Effects do
	end
end

return TreasureUpWindow
