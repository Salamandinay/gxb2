local BaseWindow = import(".BaseWindow")
local ChooseEquipWindow = class("ChooseEquipWindow", BaseWindow)
local ItemTips = import("app.windows.ItemTips")
local ItemTipsWindow = import("app.windows.ItemTipsWindow")
local ItemIcon = import("app.components.ItemIcon")
local ItemCard = class("ItemCard")

function ItemCard:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.itemIcon = ItemIcon.new(go)

	self.itemIcon:setDragScrollView(parent.scrollView)
end

function ItemCard:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self.itemIcon:setInfo(info)
end

function ItemCard:getGameObject()
	return self.go
end

function ChooseEquipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.equips = params.equips or {}
	self.now_equip = params.now_equip
	self.equipedOn = params.equipedOn
	self.equipedPartner = params.equipedPartner

	self:sortEquips()
end

function ChooseEquipWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.backBtn = content:NodeByName("backBtn").gameObject
	self.labelTitle = content:ComponentByName("labelTitle", typeof(UILabel))
	local middle = content:NodeByName("middle").gameObject
	self.noEquip = middle:NodeByName("noEquip").gameObject
	self.noEquipLabel = self.noEquip:ComponentByName("noEquipLabel", typeof(UILabel))
	self.diffBg = winTrans:NodeByName("diffBg").gameObject
	self.equipDiff = winTrans:NodeByName("equipDiff").gameObject
	local mainContainer = content:NodeByName("main_container").gameObject
	self.scrollView = mainContainer:ComponentByName("scroll_view", typeof(UIScrollView))
	self.wrapContent_ = self.scrollView:ComponentByName("wrap_content", typeof(MultiRowWrapContent))
	local itemContainer = mainContainer:NodeByName("itemContainer").gameObject

	itemContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.wrapContent_, itemContainer, ItemCard, self)
end

function ChooseEquipWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	if #self.equips == 0 then
		self.noEquip:SetActive(true)

		self.noEquipLabel.text = __("HAS_NO_EQUIP")
	else
		self.noEquip:SetActive(false)

		local infos = {}

		for key = 1, #self.equips do
			local itemID = self.equips[key].itemID
			local partner_id = self.equips[key].partner_id

			if not partner_id or partner_id ~= self.equipedPartner:getPartnerID() then
				table.insert(infos, {
					itemID = itemID,
					num = tonumber(self.equips[key].itemNum),
					partner_id = partner_id,
					callback = function ()
						self:onclickIcon(itemID, partner_id)
					end
				})
			end
		end

		self.multiWrap_:setInfos(infos, {})
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.diffBg).onClick = function ()
		self.diffBg:SetActive(false)
		NGUITools.DestroyChildren(self.equipDiff.transform)
		self.equipDiff:SetActive(false)
	end

	self.labelTitle.text = __("ChooseEquipWindow")
end

function ChooseEquipWindow:sortEquips()
	table.sort(self.equips, function (a, b)
		local aLev = xyd.tables.equipTable:getItemLev(a.itemID)
		local bLev = xyd.tables.equipTable:getItemLev(b.itemID)

		if aLev < bLev then
			return false
		elseif aLev == bLev and a.itemID <= b.itemID then
			return false
		end

		return true
	end)
end

function ChooseEquipWindow:onclickIcon(itemID, partner_id)
	if self.now_equip and self.now_equip > 0 then
		local params = {
			btnLayout = 0,
			equipedOn = self.equipedOn,
			equipedPartner = self.equipedPartner,
			itemID = self.now_equip
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	local params = {
		btnLayout = 1,
		itemID = itemID,
		midColor = xyd.ButtonBgColorType.blue_btn_65_65,
		midCallback = function ()
			local now_equip = self.equipedPartner:getEquipment()

			if partner_id then
				local timeStamp = xyd.db.misc:getValue("rob_equip_confirm")

				if timeStamp and xyd.isSameDay(xyd.getServerTime(), timeStamp, true) then
					self.equipedPartner:equipRob(itemID, partner_id, self.equipedPartner:getPartnerID())
				else
					xyd.WindowManager.get():openWindow("rob_equip_confirm_window", {
						item_id = itemID,
						partner_id = partner_id,
						callback = function ()
							self.equipedPartner:equipRob(itemID, partner_id, self.equipedPartner:getPartnerID())
						end
					})
				end
			else
				self.equipedPartner:equipSingle(itemID)
			end

			self:close()
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end,
		midLabel = self.equipedOn and __("REPLACE") or __("EQUIP_ON")
	}

	if partner_id then
		params.equipedOn = xyd.models.slot:getPartner(partner_id)
	end

	local itemTipsWindow = xyd.WindowManager.get():getWindow("item_tips_window")

	if itemTipsWindow == nil then
		xyd.WindowManager.get():openWindow("item_tips_window", params)
	else
		itemTipsWindow:addTips(params)
	end
end

function ChooseEquipWindow:iosTestChangeUI()
	local winTrans = self.window_.transform

	xyd.iosSetUISprite(winTrans:ComponentByName("content/bg", typeof(UISprite)), "9gongge21_ios_test")
	xyd.iosSetUISprite(winTrans:ComponentByName("content/middle/e:Image", typeof(UISprite)), "9gongge23_ios_test")
end

return ChooseEquipWindow
