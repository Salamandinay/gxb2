local BaseWindow = import(".BaseWindow")
local DropProbabilityWindow = class("AwardSelectWindow", BaseWindow)
local DropItem = class("DropItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local jobGiftBoxID = {
	[4601009.0] = 1,
	[152.0] = 1,
	[4601008.0] = 1,
	[151.0] = 1,
	[4601006.0] = 1,
	[4601005.0] = 1,
	[285.0] = 1,
	[4601014.0] = 1,
	[4601015.0] = 1,
	[4601016.0] = 1,
	[4601007.0] = 1,
	[243.0] = 1,
	[4601023.0] = 1,
	[242.0] = 1,
	[149.0] = 1,
	[150.0] = 1,
	[4601013.0] = 1,
	[4601010.0] = 1,
	[244.0] = 1,
	[153.0] = 1,
	[4601033.0] = 1
}

function DropProbabilityWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.box_id_ = params.box_id
	self.isShowProbalitity = params.isShowProbalitity
end

function DropProbabilityWindow:initWindow()
	DropProbabilityWindow.super.initWindow(self)
	self:getUIComponent()

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:onClickCloseButton()
	end

	if self.isShowProbalitity ~= nil and not self.isShowProbalitity then
		self.wrapContent.wrapContent_.itemSize = 125
		self.wrapContent.itemSize_ = 125

		self:initNoShowProbility()
	else
		self:initShowProbility()
	end
end

function DropProbabilityWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scroll = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.dropItem = groupAction:NodeByName("scroller/drop_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	self.jobGiftBoxDes = self.scroll:NodeByName("jobGiftBoxDes").gameObject
	self.jobGiftBoxArrow = self.scroll:NodeByName("jobGiftBoxArrow").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scroll, wrapContent, self.dropItem, DropItem, self)
end

function DropProbabilityWindow:initNoShowProbility()
	self:layoutOptionalTreasureChest()
	self:initItemGroupOptionalTreasureChest()
end

function DropProbabilityWindow:layoutOptionalTreasureChest()
	if jobGiftBoxID[self.params_.itemId] then
		self.labelTitle.text = __("CHEST_ALl_AWARD")
	else
		self.labelTitle.text = __("OPTIONAL_AWARD")
	end
end

function DropProbabilityWindow:initItemGroupOptionalTreasureChest()
	local itemsList = xyd.tables.giftBoxOptionalTable:getItems(self.params_.itemId)

	if jobGiftBoxID[self.params_.itemId] then
		local giftID = xyd.tables.itemTable:getGiftID(self.params_.itemId)
		local awards = xyd.tables.giftTable:getAwards(giftID)

		for i = 1, #awards do
			table.insert(itemsList, {
				itemID = awards[i][1],
				itemNum = awards[i][2]
			})
		end
	end

	self.wrapContent:setInfos(itemsList, {})

	for i = 1, #itemsList do
		if xyd.tables.itemTable:getType(itemsList[i].itemID) == xyd.ItemType.SKIN then
			if not self.collectionInfo then
				self.collectionInfo = {}
			end

			table.insert(self.collectionInfo, {
				skin_id = itemsList[i].itemID,
				tableID = xyd.tables.partnerTable:getPartnerIdBySkinId(tonumber(itemsList[i].itemID))[1]
			})
		end
	end
end

function DropProbabilityWindow:initShowProbility()
	self:layoutNormal()
	self:initItemGroupNormal()
end

function DropProbabilityWindow:layoutNormal()
	self.labelTitle.text = __("DROP_PROBABILITY_WINDOW_TITLE")

	if self.params.activityID == xyd.ActivityID.NEWYEAR_BAOXIANG then
		self.labelTitle.text = __("AWARD_LOOK_WINDOW_NEW")
	end
end

function DropProbabilityWindow:initItemGroupNormal()
	local DropboxShowTable = xyd.tables.dropboxShowTable
	local info = DropboxShowTable:getIdsByBoxId(self.box_id_)
	local all_proba = info.all_weight
	local list = info.list
	local items = {}

	for i = 1, #list do
		local table_id = list[i]
		local weight = DropboxShowTable:getWeight(table_id)

		if weight and weight > 0 then
			local item = {
				showType = "normal",
				table_id = table_id,
				all_proba = all_proba
			}

			table.insert(items, item)
		end
	end

	table.sort(items, function (a, b)
		return a.table_id < b.table_id
	end)
	self.wrapContent:setInfos(items, {})
end

function DropItem:ctor(go, parent)
	self.parent_ = parent

	DropItem.super.ctor(self, go, parent)
end

function DropItem:initUI()
	self.icon = self.go:NodeByName("icon").gameObject
	self.probabilityLabel = self.go:ComponentByName("probabilityLabel", typeof(UILabel))
end

function DropItem:updateInfo()
	self.table_id_ = self.data.table_id
	self.all_proba_ = self.data.all_proba
	self.showType = self.data.showType
	local data = xyd.tables.dropboxShowTable:getItem(self.table_id_)
	self.itemID = data and data[1] or self.data.itemID
	self.num = data and data[2] or self.data.itemNum
	local noClick = true

	if self.table_id_ then
		local proba = xyd.tables.dropboxShowTable:getWeight(self.table_id_)
		local show_proba = math.ceil(proba * 1000000 / self.all_proba_)
		show_proba = show_proba / 10000
		self.probabilityLabel.text = tostring(show_proba) .. "%"
		noClick = false
	end

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT then
		noClick = true
	end

	NGUITools.DestroyChildren(self.icon.transform)

	self.icon_ = xyd.getItemIcon({
		not_show_ways = true,
		uiRoot = self.icon,
		itemID = self.itemID,
		num = self.num,
		noClick = noClick
	})

	self.icon_:setDragScrollView(self.scroll)

	if xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.ARTIFACT then
		UIEventListener.Get(self.icon_:getGameObject()).onClick = function ()
			xyd.WindowManager.get():openWindow("award_item_tips_window", {
				itemID = self.itemID,
				parent_item = self.parent_.params_.itemId
			})
		end
	elseif self.showType == "normal" and self.icon_ and (self.icon_.class.__cname == "ItemIcon" or self.icon_.class.__cname == "HeroIcon" and xyd.tables.itemTable:getType(self.itemID) ~= xyd.ItemType.HERO) then
		local item_tips_wd = xyd.WindowManager.get():getWindow("item_tips_window")

		if item_tips_wd then
			UIEventListener.Get(self.icon_:getGameObject()).onClick = function ()
				xyd.WindowManager.get():openWindow("award_item_tips_window", {
					show_has_num = true,
					itemID = self.itemID,
					parent_item = self.parent_.params_.itemId,
					collectionInfo = self.parent_.collectionInfo
				})
			end
		end
	end

	if self.icon_.labelNum_ then
		local num = self.icon_.labelNum_.text

		if string.find(num, "K") and string.len(num) == 3 then
			self.icon_.labelNum_.text = self.num
		end
	end

	if not self.showType then
		if jobGiftBoxID[self.itemID] then
			if not self.parent.jobGiftBoxItemList then
				self.parent.jobGiftBoxItemList = {}
				local giftID = xyd.tables.itemTable:getGiftID(self.itemID)
				local awards = xyd.tables.giftTable:getAwards(giftID)

				for i = 1, #awards do
					local icon = xyd.getItemIcon({
						uiRoot = self.parent.jobGiftBoxDes
					})

					icon:SetLocalScale(0.9, 0.9, 0.9)
					table.insert(self.parent.jobGiftBoxItemList, icon)
				end

				self.parent.jobGiftBoxDes:GetComponent(typeof(UIWidget)).width = 108 * #awards + 20
			end

			UIEventListener.Get(self.icon_:getGameObject()).onClick = handler(self, self.onClickJobGiftBox)

			UIEventListener.Get(self.icon_:getGameObject()).onLongPress = function ()
				xyd.WindowManager.get():openWindow("award_item_tips_window", {
					show_has_num = true,
					itemID = self.itemID,
					parent_item = self.parent_.params_.itemId,
					wndType = xyd.checkCondition(xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.SKIN, xyd.ItemTipsWndType.OPTIONAL_CHEST, nil),
					collectionInfo = self.parent_.collectionInfo
				})
			end
		else
			UIEventListener.Get(self.icon_:getGameObject()).onClick = function ()
				xyd.WindowManager.get():openWindow("award_item_tips_window", {
					show_has_num = true,
					itemID = self.itemID,
					parent_item = self.parent_.params_.itemId,
					wndType = xyd.checkCondition(xyd.tables.itemTable:getType(self.itemID) == xyd.ItemType.SKIN, xyd.ItemTipsWndType.OPTIONAL_CHEST, nil),
					collectionInfo = self.parent_.collectionInfo
				})
			end
		end
	end
end

function DropItem:onClickJobGiftBox()
	if self.parent.selectedItemId ~= nil and self.parent.selectedItemId == self.itemID then
		self.parent.jobGiftBoxDes:SetActive(false)
		self.parent.jobGiftBoxArrow:SetActive(false)

		self.parent.selectedItemId = nil
	else
		local giftID = xyd.tables.itemTable:getGiftID(self.itemID)
		local awards = xyd.tables.giftTable:getAwards(giftID)
		self.parent.selectedItemId = self.itemID

		self.parent.jobGiftBoxDes:SetActive(true)
		self.parent.jobGiftBoxArrow:SetActive(true)

		local itemGroupX = self.parent.itemGroup.transform.localPosition.x
		local offsetX = self.go.transform.localPosition.x
		local offsetY = self.go.transform.localPosition.y

		self.parent.jobGiftBoxArrow:X(itemGroupX + offsetX)

		local x = itemGroupX + offsetX + 165 < 90 and itemGroupX + offsetX + 165 or 90

		if #awards == 5 then
			if offsetX == 0 then
				x = -40
			else
				x = 40
			end
		end

		self.parent.jobGiftBoxDes:X(x)
		self.parent.jobGiftBoxDes:Y(-140 + offsetY)
		self.parent.jobGiftBoxArrow:Y(-77 + offsetY)

		for i = 1, #awards do
			self.parent.jobGiftBoxItemList[i]:setInfo({
				itemID = awards[i][1],
				num = awards[i][2],
				callback = function ()
					xyd.WindowManager.get():openWindow("award_item_tips_window", {
						itemID = awards[i][1],
						wndType = xyd.ItemTipsWndType.BACKPACK
					})
				end
			})
		end

		self.parent.jobGiftBoxDes:GetComponent(typeof(UIGrid)):Reposition()
	end
end

return DropProbabilityWindow
