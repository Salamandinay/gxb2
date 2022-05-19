local BaseWindow = import(".BaseWindow")
local AwardSelectWindow = class("AwardSelectWindow", BaseWindow)
local AwardSelectItem = class("AwardSelectItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local SelectNum = import("app.components.SelectNum")
local jobGiftBoxID = {
	[152.0] = 1,
	[153.0] = 1,
	[149.0] = 1,
	[150.0] = 1,
	[151.0] = 1
}

function AwardSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selectedItemId = nil
	self.selectedItemIcon = nil
	self.sureCallback = params.sureCallback
	self.itemsInfo = params.itemsInfo
	self.longPressItemCallback = params.longPressItemCallback or nil
	self.titleLabel = params.titleLabel
	self.useMaxNum = 1000
	self.usedTotalNum = 0
	self.curUsedNum = 0
	self.itemNum = self.params_.itemNum or 0
	self.itemID = self.params_.itemID or 0
	self.itemType = self.params_.itemType or xyd.ItemType.NORMAL
	self.curNum_ = 1
	self.selectMinNum = params.selectMinNum
end

function AwardSelectWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.sureBtn = groupAction:NodeByName("sureBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.jobGiftBoxDes = self.scrollView:NodeByName("jobGiftBoxDes").gameObject
	self.jobGiftBoxArrow = self.scrollView:NodeByName("jobGiftBoxArrow").gameObject
	self.selectItem = groupAction:NodeByName("scroller/award_select_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.selectItem, AwardSelectItem, self)
	self.selectNumPos = groupAction:NodeByName("selectRoot").gameObject
	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")
end

function AwardSelectWindow:layout()
	self.labelTitle.text = __("SELECT_AWARD_PLEASE")

	if self.titleLabel then
		self.labelTitle.text = self.titleLabel
	end

	self.sureBtn:ComponentByName("button_label", typeof(UILabel)).text = __("SURE")

	local function callback(num)
		self.curNum_ = num
	end

	local param = {
		maxNum = self.itemNum,
		curNum = math.min(self.itemNum, self.useMaxNum),
		callback = callback
	}

	if self.selectMinNum then
		param.minNum = self.selectMinNum
	end

	self.selectNum_:setInfo(param)
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -180)

	local value = math.min(self.itemNum, self.useMaxNum)

	self.selectNum_:setPrompt(value)
	self.selectNum_:setMaxNum(value)

	if self.itemID == xyd.ItemID.DATES_GIFTBAG then
		self.selectNum_:setMaxNum(math.min(self.itemNum, 1000))
		self.selectNum_:setCurNum(math.min(self.itemNum, 1000))

		self.curNum_ = math.min(self.itemNum, 1000)

		return
	end

	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
end

function AwardSelectWindow:initItemGroup()
	local itemsList = nil

	if self.itemsInfo then
		itemsList = self.itemsInfo
	else
		itemsList = xyd.tables.giftBoxOptionalTable:getItems(self.params_.itemID)
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

function AwardSelectWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.sureBtn).onClick = handler(self, self.onSureBtn)

	self.eventProxy_:addEventListener(xyd.event.USE_ITEM, handler(self, self.useCallback))
end

function AwardSelectWindow:initWindow()
	AwardSelectWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItemGroup()
	self:register()
end

function AwardSelectWindow:useCallback(event)
	if tonumber(event.data.used_item_id) == xyd.ItemID.DATES_GIFTBAG then
		for _, data in ipairs(event.data.items) do
			if not self.allAwards[data.item_id] then
				self.allAwards[data.item_id] = 0
			end

			self.allAwards[data.item_id] = self.allAwards[data.item_id] + data.item_num
		end

		if self.usedTotalNum < self.curNum_ then
			self.curUsedNum = math.min(self.useMaxNum, self.curNum_ - self.usedTotalNum)
			self.usedTotalNum = self.usedTotalNum + self.curUsedNum

			xyd.models.backpack:useItem(tonumber(self.itemID), self.curUsedNum)
		else
			self:hideEffect(function ()
				if xyd.WindowManager.get():isOpen("item_tips_window") then
					xyd.WindowManager.get():closeWindow("item_tips_window")
				end

				if xyd.WindowManager.get():isOpen("award_item_tips_window") then
					xyd.WindowManager.get():closeWindow("award_item_tips_window")
				end

				xyd.closeWindow("item_use_window")
			end)
		end
	else
		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end

		if xyd.WindowManager.get():isOpen("award_item_tips_window") then
			xyd.WindowManager.get():closeWindow("award_item_tips_window")
		end

		self:close(function ()
			local items = event.data.items

			if #items > 0 then
				xyd.alertItems(items)
			end
		end)
	end
end

function AwardSelectWindow:onSureBtn()
	if self.selectedItemId ~= nil then
		if self.sureCallback then
			self.sureCallback(self.selectedItemId, self.curNum_)
		else
			local chooseItemID = self.selectedItemId
			local itemType = xyd.tables.itemTable:getType(chooseItemID)

			if itemType == xyd.ItemType.DRESS then
				local dress_id = xyd.tables.senpaiDressItemTable:getDressId(chooseItemID)
				local dressGot = xyd.models.dress:getHasStyles(dress_id)

				if not dressGot or #dressGot <= 0 then
					self:useFunction()
				else
					xyd.alertYesNo(__("SENPAI_DRESS_GIFTBOX_WARN"), function (yes_no)
						if yes_no then
							self:useFunction()
						end
					end)
				end
			else
				self:useFunction()
			end
		end
	else
		xyd.alert(xyd.AlertType.TIPS, __("NO_SELECT_AWARD"))
	end
end

function AwardSelectWindow:useFunction()
	if self.itemType == xyd.ItemType.OPTIONAL_TREASURE_CHEST then
		if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
			xyd.models.backpack:useOptionalGiftBox(self.itemID, self.curNum_, self:getOptionIndex(self.selectedItemId), self.selectedItemId)
			self:close()

			if xyd.WindowManager.get():isOpen("item_tips_window") then
				xyd.WindowManager.get():closeWindow("item_tips_window")
			end

			if xyd.WindowManager.get():isOpen("award_select_window") then
				xyd.WindowManager.get():closeWindow("award_select_window")
			end
		end

		return
	end

	if self.itemID == xyd.ItemID.DATES_GIFTBAG then
		if self.useMaxNum < self.curNum_ then
			self.loadingText.text = __("ITEM_GIFTBAG_OPEN_TIPS")
			local effect = xyd.Spine.new(self.loadingEffect)

			effect:setInfo("loading", function ()
				effect:SetLocalScale(0.95, 0.95, 0.95)
				effect:play("idle", 0, 1)
			end)

			self.effect = effect

			self.loadingComponent:SetActive(true)
		end

		self.curUsedNum = math.min(self.useMaxNum, self.curNum_ - self.usedTotalNum)
		self.usedTotalNum = self.usedTotalNum + self.curUsedNum

		xyd.models.backpack:useItem(tonumber(self.itemID), self.curUsedNum)

		return
	end

	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		xyd.models.backpack:useItem(tonumber(self.itemID), self.curNum_)
	end
end

function AwardSelectWindow:getOptionIndex(chosenId)
	local itemsList = xyd.tables.giftBoxOptionalTable:getItems(self.params_.itemID)

	for count = 1, #itemsList do
		if itemsList[count].itemID == chosenId then
			return count
		end
	end

	return nil
end

function AwardSelectItem:ctor(go, parent)
	AwardSelectItem.super.ctor(self, go, parent)

	self.icon = self.go:NodeByName("icon").gameObject
end

function AwardSelectItem:updateInfo()
	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.icon,
			itemID = self.data.itemID,
			num = self.data.itemNum
		})
		UIEventListener.Get(self.itemIcon:getGameObject()).onClick = handler(self, self.onSelectItem)

		UIEventListener.Get(self.itemIcon:getGameObject()).onLongPress = function ()
			if self.parent.longPressItemCallback then
				self.parent.longPressItemCallback(self.data.itemID)
			else
				xyd.openWindow("award_item_tips_window", {
					show_has_num = true,
					itemID = self.data.itemID,
					itemNum = self.data.itemNum,
					collectionInfo = self.parent.collectionInfo
				})
			end
		end

		self.itemIcon:setDragScrollView()
	else
		self.itemIcon:setInfo({
			noClick = true,
			itemID = self.data.itemID,
			num = self.data.itemNum
		})
	end

	self:updateSelect()
end

function AwardSelectItem:updateSelect()
	if self.parent.selectedItemId and self.parent.selectedItemId == self.data.itemID then
		self.itemIcon:setChoose(true)
	else
		self.itemIcon:setChoose(false)
	end
end

function AwardSelectItem:onSelectItem()
	if self.parent.selectedItemId ~= nil and self.parent.selectedItemId == self.data.itemID then
		self.itemIcon:setChoose(false)

		self.parent.selectedItemId = nil
		self.parent.selectedItemIcon = nil

		if jobGiftBoxID[self.data.itemID] then
			self.parent.jobGiftBoxDes:SetActive(false)
			self.parent.jobGiftBoxArrow:SetActive(false)
		end
	else
		self.parent.selectedItemId = self.data.itemID

		self.itemIcon:setChoose(true)

		if self.parent.selectedItemIcon ~= nil then
			self.parent.selectedItemIcon:setChoose(false)
		end

		self.parent.selectedItemIcon = self.itemIcon

		if jobGiftBoxID[self.data.itemID] then
			if not self.parent.jobGiftBoxItemList then
				self.parent.jobGiftBoxItemList = {}

				for i = 1, 4 do
					local icon = xyd.getItemIcon({
						uiRoot = self.parent.jobGiftBoxDes
					})

					icon:SetLocalScale(0.9, 0.9, 0.9)
					table.insert(self.parent.jobGiftBoxItemList, icon)
				end
			end

			self.parent.jobGiftBoxDes:SetActive(true)
			self.parent.jobGiftBoxArrow:SetActive(true)

			local itemGroupX = self.parent.itemGroup.transform.localPosition.x
			local offsetX = self.go.transform.localPosition.x

			self.parent.jobGiftBoxArrow:X(itemGroupX + offsetX)

			local x = itemGroupX + offsetX + 165 < 90 and itemGroupX + offsetX + 165 or 90

			self.parent.jobGiftBoxDes:X(x)

			local giftID = xyd.tables.itemTable:getGiftID(self.data.itemID)
			local awards = xyd.tables.giftTable:getAwards(giftID)

			for i = 1, 4 do
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
end

return AwardSelectWindow
