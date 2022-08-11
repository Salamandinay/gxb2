local CollectionShopWindow = class("CollectionShopWindow", import(".BaseWindow"))
local CollectionShopGroupItem = class("CollectionShopGroupItem", import("app.components.BaseComponent"))
local CollectionShopItem = class("CollectionShopItem", import("app.components.BaseComponent"))
local ResItem = import("app.components.ResItem")
local shopModel = xyd.models.shop

function CollectionShopWindow:ctor(name, params)
	CollectionShopWindow.super.ctor(self, name, params)

	self.curNav_ = params.curNav or 1
	self.itemList_ = {
		{},
		{}
	}
	self.groupList_ = {
		{},
		{}
	}
end

function CollectionShopWindow:getComponent()
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
	self.gridList1_ = winTrans:ComponentByName("scrollView_1/gridList", typeof(UIGrid))
	self.scrollView2_ = winTrans:ComponentByName("scrollView_2", typeof(UIScrollView))
	self.gridList2_ = winTrans:ComponentByName("scrollView_2/gridList", typeof(UIGrid))
	self.tab = import("app.common.ui.CommonTabBar").new(self.navRoot_, 2, function (index)
		self:onTouchNav(index)
	end)
	local tabText = xyd.split(__("COLLECTION_SHOP_TAGS"), "|")

	self.tab:setTexts(tabText)

	self.tab2_redPoint = self.navRoot_:NodeByName("tab_2/redPoint").gameObject
end

function CollectionShopWindow:initWindow()
	CollectionShopWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:layout()
end

function CollectionShopWindow:register()
	CollectionShopWindow.super.register(self)

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "COLLECTION_SHOP_HELP"
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
	xyd.models.redMark:setMarkImg(xyd.RedMarkType.COLLECTION_SHOP_2, self.tab2_redPoint)
end

function CollectionShopWindow:onGetShopInfo(evt)
	if evt.data.shop_type == xyd.ShopType.SHOP_COLLECTION2 then
		self:waitForFrame(0.1, function ()
			if self.tab then
				self.tab:setTabActive(self.curNav_, true)
			end
		end)
	end
end

function CollectionShopWindow:layout()
	self:initTime()

	self.resItem1_ = ResItem.new(self.resNode1_)

	self.resItem1_:setInfo({
		hideBg = true,
		tableId = xyd.ItemID.CRYSTAL
	})
	self.resItem1_:showBothLine(true)

	self.resItem2_ = ResItem.new(self.resNode2_)

	self.resItem2_:setInfo({
		no_red = true,
		hideBg = true,
		tableId = xyd.ItemID.MANA
	})
	self.resItem2_:showBothLine(false, "left")
	self.resItem2_:showBothLine(true, "right")

	if self.curNav_ == 2 then
		shopModel:refreshShopInfo(xyd.ShopType.SHOP_COLLECTION1)
		shopModel:refreshShopInfo(xyd.ShopType.SHOP_COLLECTION2)
	else
		self.tab:setTabActive(self.curNav_, true)
	end
end

function CollectionShopWindow:initTime()
	self.clockEffect_ = xyd.Spine.new(self.effectNode_)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
	end)
end

function CollectionShopWindow:onTouchNav(index)
	self.scrollView1_.gameObject:SetActive(index == 1)
	self.scrollView2_.gameObject:SetActive(index == 2)

	self.curNav_ = index
	local shopType = nil

	if index == 1 then
		shopType = xyd.ShopType.SHOP_COLLECTION1

		self.timeLabel_.gameObject:SetActive(false)
		self.effectNode_:SetActive(false)
	else
		shopType = xyd.ShopType.SHOP_COLLECTION2

		self.timeLabel_.gameObject:SetActive(true)
		self.effectNode_:SetActive(true)

		local leftTime = xyd.calcTimeToNextWeek() - xyd.getServerTime()

		if leftTime <= 0 then
			if not self.hasRefresh then
				self.hasRefresh = true

				shopModel:refreshShopInfo(shopType)
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

						shopModel:refreshShopInfo(shopType)
					end
				end
			})
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
			shopGropItem = CollectionShopGroupItem.new(self["gridList" .. index .. "_"].gameObject, self)
			self.groupList_[index][i] = shopGropItem
		end

		shopGropItem:setInfo({
			index = i,
			itemInfo = list[i],
			group = self.curNav_
		})
	end

	self["gridList" .. index .. "_"]:Reposition()
	self["scrollView" .. index .. "_"]:ResetPosition()

	if index == 2 then
		xyd.db.misc:setValue({
			key = "collection_point_shop_monday",
			value = xyd.calcTimeToNextWeek()
		})
		xyd.models.backpack:checkCollectionShopRed()
	end
end

function CollectionShopWindow:getSortData(shopInfo, shopType)
	local pointArr = xyd.tables.miscTable:split2num("collection_point_level", "value", "|")
	local pointParams = {}
	local list = {}

	for i = 1, #pointArr do
		pointParams[pointArr[i]] = i
		list[i] = {}
	end

	for idx, item in ipairs(shopInfo.items) do
		local tempItem = {
			item = item.item,
			cost = item.cost,
			shopType = shopType,
			buy_times = item.buy_times,
			collection_point = item.collection_point,
			index = idx
		}

		if pointParams[item.collection_point] then
			table.insert(list[pointParams[item.collection_point]], tempItem)
		end
	end

	return list
end

function CollectionShopWindow:buyItemRes(evt)
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

function CollectionShopGroupItem:ctor(parentGo, parent)
	self.parent_ = parent

	CollectionShopGroupItem.super.ctor(self, parentGo)
end

function CollectionShopGroupItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_group"
end

function CollectionShopGroupItem:initUI()
	CollectionShopGroupItem.super.initUI(self)
	self:getComponent()
end

function CollectionShopGroupItem:getComponent()
	local goTrans = self.go.transform
	self.okImg_ = goTrans:NodeByName("okImg").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.textLabel_ = goTrans:ComponentByName("textLabel", typeof(UILabel))
	self.groupItem_ = goTrans:ComponentByName("groupItem", typeof(UIGrid))
	self.drag = self.go:AddComponent(typeof(UIDragScrollView))
end

function CollectionShopGroupItem:setInfo(params)
	self.index = params.index
	local pointArr = xyd.tables.miscTable:split2num("collection_point_level", "value", "|")
	local point = pointArr[self.index]
	local isLock = xyd.models.collection:getNowCollectionPoint() < point

	self.lockImg_:SetActive(isLock)
	self.okImg_:SetActive(not isLock)

	if isLock then
		self.textLabel_.text = __("COLLECTION_SHOP_TITLE_LOCK", point)
	else
		self.textLabel_.text = xyd.split(__("COLLECTION_SHOP_TITLES"), "|")[self.index]
	end

	self.drag.scrollView = self.parent_["scrollView" .. params.group .. "_"]

	self:refreshItem(params.itemInfo, params.group)
end

function CollectionShopGroupItem:refreshItem(itemInfo, group)
	local itemList = self.parent_.itemList_[group]

	for _, itemData in ipairs(itemInfo) do
		local idx = itemData.index
		local shopItem = nil

		if not itemList[idx] then
			shopItem = CollectionShopItem.new(self.groupItem_.gameObject, self.parent_)
			itemList[idx] = shopItem
		else
			shopItem = itemList[idx]
		end

		shopItem:setInfo(itemData, group)

		if _ == 1 then
			shopItem:checkNameHeight()
		end
	end

	self.groupItem_:Reposition()
end

function CollectionShopItem:ctor(parentGo, parent)
	self.parent_ = parent

	CollectionShopItem.super.ctor(self, parentGo)
end

function CollectionShopItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_item"
end

function CollectionShopItem:initUI()
	CollectionShopItem.super.initUI(self)
	self:getComponent()
end

function CollectionShopItem:getComponent()
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

function CollectionShopItem:setInfo(params, group)
	self.needPoint_ = params.collection_point
	self.cost_ = params.cost
	self.item_ = params.item
	self.shopType_ = params.shopType
	self.buyTimes_ = params.buy_times or 0
	self.index_ = params.index
	self.drag.scrollView = self.parent_["scrollView" .. group .. "_"]
	self.drag2.scrollView = self.parent_["scrollView" .. group .. "_"]

	self:layout()
end

function CollectionShopItem:onTouch()
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

			self:updateShaddow()
		end
	end)
end

function CollectionShopItem:layout()
	self.has_buy_words_.text = __("ALREADY_BUY")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "fr_fr" then
		self.name_text_.fontSize = 16
	end

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			uiRoot = self.iconNode_,
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2]
		})
	else
		self.itemIcon_:setInfo({
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2]
		})
	end

	xyd.setUISpriteAsync(self.res_icon_, nil, "icon_" .. self.cost_[1])

	self.res_text_.text = xyd.getRoughDisplayNumber(self.cost_[2])
	self.name_text_.text = xyd.tables.itemTable:getName(self.item_[1])

	self:updateShaddow()
end

function CollectionShopItem:updateShaddow()
	local hideBg = xyd.models.collection:getNowCollectionPoint() < self.needPoint_
	local limit = xyd.tables.shopConfigTable:getSlotBuyTimes(self.shopType_, self.index_)

	self.shadow_:SetActive(limit <= self.buyTimes_ or hideBg)
	self.buyNode_:SetActive(limit <= self.buyTimes_)
end

function CollectionShopItem:checkNameHeight()
	if xyd.Global.lang == "de_de" then
		self.name_text_.height = 44
	end
end

return CollectionShopWindow
