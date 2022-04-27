local BaseWindow = import(".BaseWindow")
local FairArenaChooseEquipWindow = class("ChooseEquipWindow", BaseWindow)
local ItemIcon = import("app.components.ItemIcon")
local ItemCard = class("ItemCard")
local ArtifactBoxTable = xyd.tables.activityFairArenaBoxEquipTable

function FairArenaChooseEquipWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.partnerID = params.partnerID
	self.partner = xyd.models.fairArena:getPartnerByID(self.partnerID)
	self.equipID = self.partner:getEquipment()[6] or 0
	self.equips = xyd.models.fairArena:getEquips()
end

function FairArenaChooseEquipWindow:getUIComponent()
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

function FairArenaChooseEquipWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	if #self.equips == 0 then
		self.noEquip:SetActive(true)

		self.noEquipLabel.text = __("HAS_NO_EQUIP")
	else
		self.noEquip:SetActive(false)

		local infos = {}

		for i = 1, #self.equips do
			local id = self.equips[i].id
			local partner_id = self.equips[i].partner_id

			if not partner_id or partner_id ~= self.partnerID then
				local itemID = ArtifactBoxTable:getEquipID(id)
				local avatar_src = nil

				if self.equips[i].table_id then
					avatar_src = xyd.tables.partnerTable:getAvatar(self.equips[i].table_id)
				end

				table.insert(infos, {
					num = 1,
					itemID = itemID,
					avatar_src = avatar_src,
					callback = function ()
						self:onclickIcon(i, itemID, self.equips[i].partner_id)
					end
				})
			end
		end

		self.multiWrap_:setInfos(infos, {})
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	self.labelTitle.text = __("ChooseEquipWindow")

	self:register()
end

function FairArenaChooseEquipWindow:register()
	FairArenaChooseEquipWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EQUIP, handler(self, function ()
		xyd.WindowManager.get():closeWindow("fair_arena_choose_equip_window")
	end))
end

function FairArenaChooseEquipWindow:onclickIcon(index, itemID, partner_id)
	if self.equipID > 0 then
		local params = {
			btnLayout = 0,
			itemID = self.equipID,
			equipedOn = self.partner:getInfo(),
			equipedPartner = self.partner
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	local params = {
		btnLayout = 1,
		itemID = itemID,
		midColor = xyd.ButtonBgColorType.blue_btn_65_65,
		midCallback = function ()
			xyd.models.fairArena:reqEquip(self.partnerID, index)
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end,
		midLabel = self.equipID > 0 and __("REPLACE") or __("EQUIP_ON")
	}

	if partner_id then
		params.equipedOn = xyd.models.fairArena:getPartnerByID(partner_id):getInfo()
	end

	local itemTipsWindow = xyd.WindowManager.get():getWindow("item_tips_window")

	if itemTipsWindow == nil then
		xyd.WindowManager.get():openWindow("item_tips_window", params)
	else
		itemTipsWindow:addTips(params)
	end
end

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

return FairArenaChooseEquipWindow
