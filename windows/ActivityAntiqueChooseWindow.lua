local BaseWindow = import(".BaseWindow")
local ActivityAntiqueChooseWindow = class("ActivityAntiqueChooseWindow", BaseWindow)
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

	if info.isSelect then
		self.itemIcon:setChoose(true)
	else
		self.itemIcon:setChoose(false)
	end
end

function ItemCard:getGameObject()
	return self.go
end

function ActivityAntiqueChooseWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.antiques = params.antiques or {}
	self.now_antique = params.now_antique
	self.type = params.type or 1
	self.callback = params.callback
	self.cost_item = params.cost_item or 0
end

function ActivityAntiqueChooseWindow:getUIComponent()
	local winTrans = self.window_.transform
	local content = winTrans:NodeByName("content").gameObject
	self.backBtn = content:NodeByName("backBtn").gameObject
	self.labelTitle = content:ComponentByName("labelTitle", typeof(UILabel))
	local middle = content:NodeByName("middle").gameObject
	self.noEquip = middle:NodeByName("noEquip").gameObject
	self.noEquipLabel = self.noEquip:ComponentByName("noEquipLabel", typeof(UILabel))
	local mainContainer = content:NodeByName("main_container").gameObject
	self.scrollView = mainContainer:ComponentByName("scroll_view", typeof(UIScrollView))
	self.wrapContent_ = self.scrollView:ComponentByName("wrap_content", typeof(MultiRowWrapContent))
	local itemContainer = mainContainer:NodeByName("itemContainer").gameObject

	itemContainer:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.wrapContent_, itemContainer, ItemCard, self)
end

function ActivityAntiqueChooseWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local infos = {}

	if self.type == 1 then
		for _, itemID in ipairs(self.antiques) do
			table.insert(infos, {
				num = 1,
				itemID = itemID,
				isSelect = itemID == self.now_antique,
				callback = function ()
					self:onclickIcon(itemID)
				end
			})
		end
	else
		local equipsOfPartners = xyd.models.slot:getEquipsOfPartners()

		for _, itemID in ipairs(self.antiques) do
			local num = xyd.models.backpack:getItemNumByID(itemID)

			if itemID ~= self.cost_item and num > 0 or itemID == self.cost_item and num > 1 then
				table.insert(infos, {
					itemID = itemID,
					num = num,
					isSelect = itemID == self.now_antique,
					callback = function ()
						self:onclickIcon(itemID)
					end
				})
			end

			for key in pairs(equipsOfPartners) do
				if tonumber(key) == itemID then
					for _, partner_id in ipairs(equipsOfPartners[key]) do
						table.insert(infos, {
							num = 1,
							itemID = itemID,
							partner_id = partner_id,
							callback = function ()
								self:onclickIcon(itemID, partner_id)
							end
						})
					end
				end
			end
		end
	end

	if #infos == 0 then
		self.noEquip:SetActive(true)

		self.noEquipLabel.text = __("NO_ARTIFACT")
	else
		self.noEquip:SetActive(false)
		self.multiWrap_:setInfos(infos, {})
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		self:close()
	end

	self.labelTitle.text = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT03")
end

function ActivityAntiqueChooseWindow:onclickIcon(itemID, partner_id)
	local params = {
		btnLayout = 1,
		itemID = itemID,
		midColor = xyd.ButtonBgColorType.blue_btn_65_65,
		midCallback = function ()
			if partner_id then
				local timeStamp = xyd.db.misc:getValue("rob_equip_confirm")

				local function callback()
					self.callback(itemID)

					local partner = xyd.models.slot:getPartner(partner_id)

					partner:unEquipSingle(itemID)
				end

				if timeStamp and xyd.isSameDay(xyd.getServerTime(), timeStamp, true) then
					callback()
				else
					xyd.WindowManager.get():openWindow("rob_equip_confirm_window", {
						item_id = itemID,
						partner_id = partner_id,
						callback = callback,
						title = __("ACTIVITY_ANTIQUE_LEVELUP_TEXT16")
					})
				end
			elseif self.now_antique == itemID then
				self.callback(0)
			else
				self.callback(itemID)
			end

			self:close()
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end
	}

	if partner_id then
		params.equipedOn = xyd.models.slot:getPartner(partner_id)
		params.midLabel = __("SELECT")
	else
		params.midLabel = self.now_antique == itemID and __("CANCEL_2") or __("SELECT")
		params.midColor = self.now_antique == itemID and xyd.ButtonBgColorType.red_btn_65_65 or xyd.ButtonBgColorType.blue_btn_65_65
	end

	xyd.WindowManager.get():openWindow("item_tips_window", params)
end

return ActivityAntiqueChooseWindow
