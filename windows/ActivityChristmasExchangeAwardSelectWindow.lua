local BaseWindow = import(".BaseWindow")
local ActivityChristmasExchangeAwardSelectWindow = class("ActivityChristmasExchangeAwardSelectWindow", BaseWindow)
local ActivityChristmasExchangeAwardSelectItem = class("ActivityChristmasExchangeAwardSelectItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function ActivityChristmasExchangeAwardSelectWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.selectedIndexId = params.selectedIndexId
	self.selectedItemIcon = nil
	self.sureCallback = params.sureCallback
	self.itemsInfo = params.itemsInfo
	self.type = params.type
	self.titleLabel = params.titleLabel
	self.selectedGroup = params.selectedGroup or 1
	self.hideFilter = params.hideFilter
	self.itemNum = self.params_.itemNum
	self.itemID = self.params_.itemID
	self.itemType = self.params_.itemType
end

function ActivityChristmasExchangeAwardSelectWindow:initWindow()
	ActivityChristmasExchangeAwardSelectWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItemGroup()
	self:updateFilterGroup()
	self:register()
end

function ActivityChristmasExchangeAwardSelectWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelTips = groupAction:ComponentByName("labelTips", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.selectItem = groupAction:NodeByName("scroller/award_select_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.selectItem, ActivityChristmasExchangeAwardSelectItem, self)
	self.filterGroup = groupAction:NodeByName("filterGroup").gameObject
	self.partnerFilterGroup = self.filterGroup:NodeByName("partnerFilterGroup").gameObject
	self.equipFilterGroup = self.filterGroup:NodeByName("equipFilterGroup").gameObject
	self.groupNone = groupAction:NodeByName("groupNone").gameObject
	self.gotoBtn = self.groupNone:NodeByName("gotoBtn").gameObject
	self.labelGotoBtn = self.gotoBtn:ComponentByName("labelGotoBtn", typeof(UILabel))
end

function ActivityChristmasExchangeAwardSelectWindow:layout()
	self.labelTitle.text = __("SELECT_AWARD_PLEASE")
	self.labelTips.text = __("ACTIVITY_ICE_SECRET_ITEM_TIPS")
	self.labelGotoBtn.text = __("GO")

	if self.titleLabel then
		self.labelTitle.text = self.titleLabel
	end

	if self.itemsInfo and #self.itemsInfo > 0 then
		self.groupNone:SetActive(false)
	end

	if self.type == 1 then
		self.groupNone:ComponentByName("labelNoneTips_", typeof(UILabel)).text = __("ACTIVITY_SOCKS_CHANGE_TEXT07")
	end

	if self.type == 2 then
		self.groupNone:ComponentByName("labelNoneTips_", typeof(UILabel)).text = __("ACTIVITY_SOCKS_CHANGE_TEXT04")
	end

	if self.type == 3 then
		self.groupNone:ComponentByName("labelNoneTips_", typeof(UILabel)).text = __("ACTIVITY_SOCKS_CHANGE_TEXT08")
	end

	if self.type == 1 or self.type == 2 then
		self.partnerFilterGroup:SetActive(true)

		for i = 1, 6 do
			self["filterGroup" .. i] = self.partnerFilterGroup:NodeByName("group" .. i).gameObject
		end
	elseif self.type == 3 then
		self.equipFilterGroup:SetActive(true)

		for i = 1, 6 do
			self["filterGroup" .. i] = self.equipFilterGroup:NodeByName("group" .. i).gameObject
		end
	end

	if self.hideFilter then
		self.partnerFilterGroup:SetActive(false)
		self.equipFilterGroup:SetActive(false)

		self.selectedGroup = 0
	end
end

function ActivityChristmasExchangeAwardSelectWindow:initItemGroup()
	local itemsList = nil

	if self.itemsInfo then
		self:toFilterData()

		itemsList = self.filterData
	end

	self.wrapContent:setInfos(itemsList, {})
end

function ActivityChristmasExchangeAwardSelectWindow:toFilterData()
	self.filterData = {}

	if self.selectedGroup == 0 then
		self.filterData = self.itemsInfo
	elseif self.type == 1 then
		for i = 1, #self.itemsInfo do
			local group = xyd.tables.partnerTable:getGroup(self.itemsInfo[i].itemID)

			if group == self.selectedGroup then
				table.insert(self.filterData, self.itemsInfo[i])
			end
		end
	elseif self.type == 2 then
		for i = 1, #self.itemsInfo do
			local partnerTableID = xyd.tables.partnerPictureTable:getSkinPartner(self.itemsInfo[i].itemID)[1]
			local group = xyd.tables.partnerTable:getGroup(partnerTableID)

			if group == self.selectedGroup then
				table.insert(self.filterData, self.itemsInfo[i])
			end
		end
	elseif self.type == 3 then
		for i = 1, #self.itemsInfo do
			local star = xyd.tables.equipTable:getStar(self.itemsInfo[i].itemID)

			if star == self.selectedGroup then
				table.insert(self.filterData, self.itemsInfo[i])
			end
		end
	end
end

function ActivityChristmasExchangeAwardSelectWindow:register()
	BaseWindow.register(self)

	for i = 1, 6 do
		UIEventListener.Get(self["filterGroup" .. i]).onClick = function ()
			self:onSelectGroup(i)
		end
	end

	UIEventListener.Get(self.gotoBtn).onClick = function ()
		if self.type == 1 then
			xyd.goWay(xyd.GoWayId.summon)
			xyd.closeWindow("activity_christmas_exchange_award_select_window")
		elseif self.type == 2 then
			xyd.goWay(xyd.GoWayId.slot)
			xyd.closeWindow("activity_christmas_exchange_award_select_window")
		elseif self.type == 3 then
			xyd.goWay(xyd.GoWayId.slot)
			xyd.closeWindow("activity_christmas_exchange_award_select_window")
		end
	end
end

function ActivityChristmasExchangeAwardSelectWindow:updateFilterGroup()
	for j = 1, 6 do
		self["filterGroup" .. j]:NodeByName("chosen").gameObject:SetActive(j == self.selectedGroup)
	end
end

function ActivityChristmasExchangeAwardSelectWindow:onSelectGroup(groupID)
	if self.selectedGroup == groupID then
		self.selectedGroup = 0
	else
		self.selectedGroup = groupID

		for j = 1, 6 do
			self["filterGroup" .. j]:NodeByName("chosen").gameObject:SetActive(j == groupID)
		end
	end

	self:initItemGroup()
	self:updateFilterGroup()
end

function ActivityChristmasExchangeAwardSelectWindow:dispose()
	self.sureCallback(self.selectedIndexId)
	ActivityChristmasExchangeAwardSelectWindow.super.dispose(self)
end

function ActivityChristmasExchangeAwardSelectItem:ctor(go, parent)
	ActivityChristmasExchangeAwardSelectItem.super.ctor(self, go, parent)

	self.iconPos = self.go:NodeByName("iconPos").gameObject
end

function ActivityChristmasExchangeAwardSelectItem:updateInfo()
	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			noClick = true,
			uiRoot = self.iconPos,
			itemID = self.data.itemID,
			num = self.data.itemNum,
			lev = self.data.lev,
			dragScrollView = self.parent.scrollView
		})
		UIEventListener.Get(self.iconPos).onClick = handler(self, self.onSelectItem)
		UIEventListener.Get(self.iconPos).onLongPress = handler(self, self.onLongClick)
	else
		self.itemIcon:setInfo({
			noClick = true,
			itemID = self.data.itemID,
			num = self.data.itemNum,
			lev = self.data.lev,
			dragScrollView = self.parent.scrollView
		})
	end

	if self.parent.selectedIndexId == self.data.indexID then
		self.parent.selectedItemIcon = self.itemIcon
	end

	self:updateSelect()

	if self.data.lock == true then
		self.itemIcon:setLock(true)
	else
		self.itemIcon:setLock(false)
	end

	if self.parent.selectedIndexId and self.parent.selectedIndexId == self.data.indexID then
		self.itemIcon:setChoose(true)
	end
end

function ActivityChristmasExchangeAwardSelectItem:updateSelect()
	if self.parent.selectedIndexId and self.parent.selectedIndexId == self.data.indexID then
		self.itemIcon:setChoose(true)
	else
		self.itemIcon:setChoose(false)
	end
end

function ActivityChristmasExchangeAwardSelectItem:onSelectItem()
	if self.parent.selectedIndexId ~= nil and self.parent.selectedIndexId == self.data.indexID then
		self.itemIcon:setChoose(false)

		self.parent.selectedIndexId = nil
		self.parent.selectedItemIcon = nil
	else
		if self.parent.type == 1 and self.data.lock == true then
			local partner = xyd.models.slot:getPartner(self.data.indexID)

			if xyd.checkLast(partner) then
				xyd.showToast(__("UNLOCK_FAILED"))
			elseif xyd.checkDateLock(partner) then
				xyd.showToast(__("DATE_LOCK_FAIL"))
			elseif xyd.checkQuickFormation(partner) then
				xyd.showToast(__("QUICK_FORMATION_TEXT21"))
			elseif xyd.checkGalaxyFormation(partner) then
				xyd.showToast(__("GALAXY_TRIP_TIPS_20"))
			else
				local str = __("IF_UNLOCK_HERO_3")

				xyd.alert(xyd.AlertType.YES_NO, str, function (yes_no)
					if yes_no then
						local succeed = xyd.partnerUnlock(partner)

						if succeed then
							self.itemIcon:setLock(false)

							self.data.lock = false
						else
							xyd.showToast(__("UNLOCK_FAILED"))
						end
					end
				end)
			end

			return
		end

		self.parent.selectedIndexId = self.data.indexID

		if self.parent.selectedItemIcon ~= nil then
			self.parent.selectedItemIcon:setChoose(false)
		end

		self.parent.selectedItemIcon = self.itemIcon

		self.itemIcon:setChoose(true)
	end
end

function ActivityChristmasExchangeAwardSelectItem:onLongClick()
	if self.parent.type == 3 then
		local params = {
			itemID = self.data.itemID,
			itemNum = self.data.itemNum,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	elseif self.parent.type == 1 then
		local params = {
			partners = {
				{
					table_id = self.data.itemID
				}
			},
			table_id = self.data.itemID
		}
		local wndName = "guide_detail_window"

		xyd.openWindow(wndName, params)
	elseif self.parent.type == 2 then
		local params = {
			skin_id = self.data.itemID,
			closeCallBack = function ()
				xyd.WindowManager.get():closeWindow("collection_skin_window")
			end
		}

		xyd.WindowManager.get():openWindow("collection_skin_window", {}, function ()
			xyd.WindowManager.get():openWindow("collection_skin_detail_window", params, function ()
			end)
		end)
	end
end

return ActivityChristmasExchangeAwardSelectWindow
