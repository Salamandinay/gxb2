local CommonShopWindow = class("CommonShopWindow", import(".BaseWindow"))
local CommonShopGroupItem = class("CommonShopGroupItem", import("app.components.BaseComponent"))
local CommonShopItem = class("CommonShopItem", import("app.components.BaseComponent"))
local ResItem = import("app.components.ResItem")
local shopModel = xyd.models.shop

function CommonShopWindow:ctor(name, params)
	CommonShopWindow.super.ctor(self, name, params)

	self.curNav_ = params.curNav or 1
	self.helpKey_ = params.helpKey
	self.shopTypes_ = params.shopTypes or {}
	self.tabText_ = params.tabText
	self.tab2RedPointType_ = params.tab2RedPointType
	self.resIDs_ = params.resIDs
	self.calculateLeftTimeCallbacks_ = params.calculateLeftTimeCallbacks
	self.pointDatas_ = params.pointDatas
	self.titleUnlockText_ = params.titleUnlockText
	self.titleLockText_ = params.titleLockText
	self.hideFirstTitle = params.hideFirstTitle
	self.hideBtnHelp = params.hideBtnHelp
	self.labelWinTitleText = params.labelWinTitleText
	self.itemList_ = {
		{},
		{}
	}
	self.groupList_ = {
		{},
		{}
	}
end

function CommonShopWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.dragScroll_ = winTrans:ComponentByName("dragBg", typeof(UIDragScrollView))
	self.effectNode_ = winTrans:NodeByName("topItemsNode/effectNode").gameObject

	self.effectNode_:SetActive(false)

	self.timeLabel_ = winTrans:ComponentByName("topItemsNode/timeLabel", typeof(UILabel))

	self.timeLabel_:SetActive(false)

	self.resNode1_ = winTrans:NodeByName("topItemsNode/resNode1").gameObject
	self.resNode2_ = winTrans:NodeByName("topItemsNode/resNode2").gameObject
	self.navRoot_ = winTrans:NodeByName("topItemsNode/navBtns").gameObject
	self.labelWinTitle = winTrans:ComponentByName("e:group/labelWinTitle", typeof(UILabel))
	self.helpBtn_ = winTrans:NodeByName("e:group/helpBtn").gameObject
	self.closeBtn_ = winTrans:NodeByName("e:group/closeBtn").gameObject
	self.scrollView1_ = winTrans:ComponentByName("scrollView_1", typeof(UIScrollView))
	self.gridList1_ = winTrans:ComponentByName("scrollView_1/gridList", typeof(UILayout))
	self.scrollView2_ = winTrans:ComponentByName("scrollView_2", typeof(UIScrollView))
	self.gridList2_ = winTrans:ComponentByName("scrollView_2/gridList", typeof(UILayout))
	self.tab = import("app.common.ui.CommonTabBar").new(self.navRoot_, 2, function (index)
		self:onTouchNav(index)
	end)
	local tabText = self.tabText_

	self.tab:setTexts(tabText)

	self.tab2_redPoint = self.navRoot_:NodeByName("tab_2/redPoint").gameObject
end

function CommonShopWindow:initWindow()
	CommonShopWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:layout()
end

function CommonShopWindow:addTitle()
	self.labelWinTitle.text = self.labelWinTitleText or __("HOUSE_TEXT_9")
end

function CommonShopWindow:register()
	CommonShopWindow.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = self.helpKey_
		})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		if self.resItem1_ then
			self.resItem1_:refresh()
		end

		if self.resItem2_ then
			self.resItem2_:refresh()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, handler(self, self.onGetShopInfo))
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, handler(self, self.buyItemRes))
	xyd.models.redMark:setMarkImg(self.tab2RedPointType_, self.tab2_redPoint)
end

function CommonShopWindow:onGetShopInfo(evt)
	if evt.data.shop_type == self.shopTypes_[1] and self.curNav_ == 1 then
		if self.tab then
			self.tab:setTabActive(self.curNav_, true)
		end
	elseif evt.data.shop_type == self.shopTypes_[2] and self.curNav_ == 2 and self.tab then
		self.tab:setTabActive(self.curNav_, true)
	end
end

function CommonShopWindow:layout()
	self:initTime()

	if self.resIDs_[1] then
		self.resItem1_ = ResItem.new(self.resNode1_)

		self.resItem1_:setInfo({
			hideBg = true,
			tableId = self.resIDs_[1]
		})
		self.resItem1_:showBothLine(true)
		self.resNode1_:X(224)
	end

	if self.resIDs_[2] then
		self.resItem2_ = ResItem.new(self.resNode2_)

		self.resItem2_:setInfo({
			no_red = true,
			hideBg = true,
			tableId = self.resIDs_[2]
		})
		self.resNode1_:X(2)
		self.resItem2_:showBothLine(false, "left")
		self.resItem2_:showBothLine(true, "right")
	end

	local shopInfo1 = shopModel:getShopInfo(self.shopTypes_[1])

	if not shopInfo1 then
		shopModel:refreshShopInfo(self.shopTypes_[1])
	elseif self.curNav_ == 1 then
		self.tab:setTabActive(self.curNav_, true)
	end

	local shopInfo2 = shopModel:getShopInfo(self.shopTypes_[2])

	if not shopInfo2 then
		shopModel:refreshShopInfo(self.shopTypes_[2])
	elseif self.curNav_ == 2 then
		self.tab:setTabActive(self.curNav_, true)
	end

	if self.hideBtnHelp then
		self.helpBtn_:SetActive(false)
	end
end

function CommonShopWindow:initTime()
	self.clockEffect_ = xyd.Spine.new(self.effectNode_)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
	end)
end

function CommonShopWindow:onTouchNav(index)
	self.scrollView1_.gameObject:SetActive(index == 1)
	self.scrollView2_.gameObject:SetActive(index == 2)

	self.curNav_ = index
	local shopType = nil

	if index == 1 then
		shopType = self.shopTypes_[1]

		if self.calculateLeftTimeCallbacks_ and self.calculateLeftTimeCallbacks_[1] then
			self.timeLabel_.gameObject:SetActive(true)
			self.effectNode_:SetActive(true)

			local leftTime = self.calculateLeftTimeCallbacks_[1]()

			if leftTime <= 0 then
				if not self.hasRefresh1 then
					self.hasRefresh1 = true

					shopModel:refreshShopInfo(self.shopTypes_[1])
				end
			else
				if not self.timeLabelCount_ then
					self.timeLabelCount_ = import("app.components.CountDown").new(self.timeLabel_)
				end

				self.timeLabelCount_:setInfo({
					duration = leftTime,
					callback = function ()
						if not self.hasRefresh then
							self.hasRefresh = true

							shopModel:refreshShopInfo(self.shopTypes_[1])
						end
					end
				})
			end
		else
			self.timeLabel_.gameObject:SetActive(false)
			self.effectNode_:SetActive(false)
		end
	else
		shopType = self.shopTypes_[2]

		if self.calculateLeftTimeCallbacks_ and self.calculateLeftTimeCallbacks_[2] then
			self.timeLabel_.gameObject:SetActive(true)
			self.effectNode_:SetActive(true)

			local leftTime = self.calculateLeftTimeCallbacks_[2]()

			if leftTime <= 0 then
				if not self.hasRefresh1 then
					self.hasRefresh1 = true

					shopModel:refreshShopInfo(self.shopTypes_[2])
				end
			else
				if not self.timeLabelCount_ then
					self.timeLabelCount_ = import("app.components.CountDown").new(self.timeLabel_)
				end

				self.timeLabelCount_:setInfo({
					duration = leftTime,
					callback = function ()
						if not self.hasRefresh then
							self.hasRefresh = true

							shopModel:refreshShopInfo(self.shopTypes_[2])
						end
					end
				})
			end
		else
			self.timeLabel_.gameObject:SetActive(false)
			self.effectNode_:SetActive(false)
		end
	end

	local shopInfo = shopModel:getShopInfo(shopType)

	if not shopInfo then
		return
	end

	self.dragScroll_.scrollView = self["scrollView" .. index .. "_"]
	local list = self:getSortData(shopInfo, shopType)

	for i = 1, #list do
		local shopGropItem = self.groupList_[index][i]

		if not self.groupList_[index][i] then
			shopGropItem = CommonShopGroupItem.new(self["gridList" .. index .. "_"].gameObject, self)
			self.groupList_[index][i] = shopGropItem
		end

		shopGropItem:setInfo({
			index = i,
			itemInfo = list[i],
			group = self.curNav_,
			layerKey = self.pointDatas_[self.curNav_].layerRankArr[i],
			unlock = self.pointDatas_[self.curNav_].unlockRankData[i]
		})
	end

	self["gridList" .. index .. "_"]:Reposition()
	self["scrollView" .. index .. "_"]:ResetPosition()
end

function CommonShopWindow:getSortData(shopInfo, shopType)
	local layerRankArr = self.pointDatas_[self.curNav_].layerRankArr
	local itemLayerKeyData = self.pointDatas_[self.curNav_].itemLayerKeyData
	local layerRankHelpArr = {}
	local unlockRankData = self.pointDatas_[self.curNav_].unlockRankData
	local list = {}

	for i = 1, #layerRankArr do
		layerRankHelpArr[layerRankArr[i]] = i
		list[i] = {}
	end

	dump(shopInfo.items)
	dump(self.curNav_)
	dump(itemLayerKeyData)
	dump(layerRankArr)

	for idx, item in ipairs(shopInfo.items) do
		local layerKey = itemLayerKeyData[idx]
		local layerIndex = layerRankHelpArr[layerKey]
		local tempItem = {
			item = item.item,
			cost = item.cost,
			shopType = shopType,
			buy_times = item.buy_times,
			layerKey = layerKey,
			unlock = unlockRankData[layerIndex],
			index = idx
		}

		dump(tempItem)

		if layerIndex then
			table.insert(list[layerIndex], tempItem)
		end
	end

	return list
end

function CommonShopWindow:buyItemRes(evt)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUY_ITEM)

	local params = evt.data
	local index = params.index
	local items = params.items
	local num = params.num
	local buyItem = items[index]
	local itemData = buyItem.item

	xyd.alertItems({
		{
			item_id = itemData[1],
			item_num = itemData[2] * num
		}
	})
end

function CommonShopGroupItem:ctor(parentGo, parent)
	self.parent_ = parent

	CommonShopGroupItem.super.ctor(self, parentGo)
end

function CommonShopGroupItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_group"
end

function CommonShopGroupItem:initUI()
	CommonShopGroupItem.super.initUI(self)
	self:getComponent()
end

function CommonShopGroupItem:getComponent()
	local goTrans = self.go.transform
	self.okImg_ = goTrans:NodeByName("okImg").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.textLabel_ = goTrans:ComponentByName("textLabel", typeof(UILabel))
	self.groupItem_ = goTrans:ComponentByName("groupItem", typeof(UIGrid))
	self.drag = self.go:AddComponent(typeof(UIDragScrollView))
end

function CommonShopGroupItem:setInfo(params)
	self.index = params.index
	self.layerKey = params.layerKey
	local isLock = not params.unlock
	self.isLock = isLock

	self.lockImg_:SetActive(isLock)
	self.okImg_:SetActive(not isLock)

	if isLock then
		self.textLabel_.text = self.parent_.titleLockText_[self.parent_.curNav_][self.index]
		self.textLabel_.effectColor = Color.New2(1583978239)
		self.textLabel_.color = Color.New2(4294967295.0)
	else
		self.textLabel_.text = self.parent_.titleUnlockText_[self.parent_.curNav_][self.index]
		self.textLabel_.effectColor = Color.New2(1671294207)
		self.textLabel_.color = Color.New2(4294967295.0)
	end

	if self.index == 1 and self.parent_.hideFirstTitle then
		self.okImg_:SetActive(false)
		self.textLabel_:SetActive(false)

		self.go:ComponentByName("", typeof(UIWidget)).height = 260

		self.groupItem_:Y(0)
	end

	self.drag.scrollView = self.parent_["scrollView" .. params.group .. "_"]

	self:refreshItem(params.itemInfo, params.group)
end

function CommonShopGroupItem:refreshItem(itemInfo, group)
	local itemList = self.parent_.itemList_[group]

	for _, itemData in ipairs(itemInfo) do
		local idx = itemData.index
		local shopItem = nil

		if not itemList[idx] then
			shopItem = CommonShopItem.new(self.groupItem_.gameObject, self.parent_)
			itemList[idx] = shopItem
		else
			shopItem = itemList[idx]
		end

		shopItem:setInfo(itemData, group, self.isLock)
	end

	self.groupItem_:Reposition()
end

function CommonShopItem:ctor(parentGo, parent)
	self.parent_ = parent

	CommonShopItem.super.ctor(self, parentGo)
end

function CommonShopItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_item"
end

function CommonShopItem:initUI()
	CommonShopItem.super.initUI(self)
	self:getComponent()
end

function CommonShopItem:getComponent()
	local goTrans = self.go.transform
	self.mainNode_ = goTrans:NodeByName("mainNode").gameObject
	self.iconNode_ = goTrans:NodeByName("mainNode/iconNode").gameObject
	self.name_text_ = goTrans:ComponentByName("mainNode/name_text", typeof(UILabel))
	self.res_text_ = goTrans:ComponentByName("mainNode/res_text", typeof(UILabel))
	self.res_icon_ = goTrans:ComponentByName("mainNode/res_icon", typeof(UISprite))
	self.shadow_ = goTrans:NodeByName("shadow").gameObject
	self.buyNode_ = goTrans:NodeByName("buyNode").gameObject
	self.has_buy_words_ = goTrans:ComponentByName("buyNode/has_buy_words", typeof(UILabel))
	self.drag = self.mainNode_:AddComponent(typeof(UIDragScrollView))
	self.drag2 = self.shadow_:AddComponent(typeof(UIDragScrollView))
	UIEventListener.Get(self.mainNode_).onClick = handler(self, self.onTouch)
end

function CommonShopItem:setInfo(params, group, isLock)
	self.needPoint_ = params.point
	self.cost_ = params.cost
	self.item_ = params.item
	self.shopType_ = params.shopType
	self.buyTimes_ = params.buy_times or 0
	self.index_ = params.index
	self.isLock = isLock
	self.drag.scrollView = self.parent_["scrollView" .. group .. "_"]
	self.drag2.scrollView = self.parent_["scrollView" .. group .. "_"]

	self:layout()
end

function CommonShopItem:onTouch()
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.shopType_, self.index_)

	if limit > 0 and self.buyTimes_ and limit <= self.buyTimes_ then
		return
	end

	local cost = self.cost_

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
		if yes_no then
			shopModel:buyShopItem(self.shopType_, self.index_)

			self.buyTimes_ = self.buyTimes_ + 1
			self.name_text_.text = __("LIMIT_BUY", xyd.tables.shopConfigTable:getSlotBuyTimes(self.shopType_, self.index_) - self.buyTimes_)

			self:updateShaddow()
		end
	end)
end

function CommonShopItem:layout()
	self.has_buy_words_.text = __("ALREADY_BUY")

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			uiRoot = self.iconNode_,
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2],
			dragScrollView = self.drag2.scrollView
		})
	else
		self.itemIcon_:setInfo({
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2],
			dragScrollView = self.drag2.scrollView
		})
	end

	xyd.setUISpriteAsync(self.res_icon_, nil, "icon_" .. self.cost_[1])

	self.res_text_.text = xyd.getRoughDisplayNumber(self.cost_[2])
	self.name_text_.text = __("LIMIT_BUY", xyd.tables.shopConfigTable:getSlotBuyTimes(self.shopType_, self.index_) - self.buyTimes_)

	self:updateShaddow()
end

function CommonShopItem:updateShaddow()
	local hideBg = self.isLock
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.shopType_, self.index_)

	self.shadow_:SetActive(limit <= self.buyTimes_ or hideBg)
	self.buyNode_:SetActive(limit <= self.buyTimes_)
end

return CommonShopWindow
