local ShrineHurdleShopWindow = class("ShrineHurdleShopWindow", import(".BaseWindow"))
local ShrineShopItem = class("ShrineShopItem")
local ResItem = import("app.components.ResItem")

function ShrineShopItem:ctor(node, parent)
	self.parent_ = parent
	self.go = node

	self:getComponent()
end

function ShrineShopItem:show(status)
	self.go:SetActive(status)
end

function ShrineShopItem:getComponent()
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

function ShrineShopItem:setInfo(params, group)
	self.cost_ = params.cost
	self.item_ = params.item
	self.shopType_ = params.shopType
	self.leftTime = params.leftTime or 0
	self.index_ = params.index
	self.limitTime_ = params.limitTime
	self.drag.scrollView = self.parent_["scrollView" .. group .. "_"]
	self.drag2.scrollView = self.parent_["scrollView" .. group .. "_"]

	self:layout()
end

function ShrineShopItem:onTouch()
	if self.leftTime <= 0 then
		return
	end

	xyd.WindowManager:get():openWindow("item_buy_window", {
		hide_min_max = true,
		show_item_num = true,
		cost = self.cost_,
		max_num = self.leftTime,
		itemParams = {
			itemID = self.item_[1],
			num = self.item_[2]
		},
		buyCallback = function (num)
			xyd.models.shop:buyShopItem(self.shopType_, self.index_, num)

			self.leftTime = self.leftTime - num

			self:updateShadow()
		end
	})
end

function ShrineShopItem:layout()
	self.has_buy_words_.text = __("ALREADY_BUY")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "fr_fr" then
		self.name_text_.fontSize = 16
	end

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			show_has_num = true,
			notShowGetWayBtn = true,
			uiRoot = self.iconNode_,
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	else
		self.itemIcon_:setInfo({
			show_has_num = true,
			notShowGetWayBtn = true,
			itemID = self.item_[1],
			avatar_frame_id = self.item_[1],
			num = self.item_[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	xyd.setUISpriteAsync(self.res_icon_, nil, xyd.tables.itemTable:getIcon(self.cost_[1]))

	self.res_text_.text = xyd.getRoughDisplayNumber(self.cost_[2])
	self.name_text_.text = __("BUY_GIFTBAG_LIMIT", self.leftTime)

	self:updateShadow()
end

function ShrineShopItem:updateShadow()
	self.shadow_:SetActive(self.leftTime <= 0)
	self.buyNode_:SetActive(self.leftTime <= 0)

	self.name_text_.text = __("BUY_GIFTBAG_LIMIT", self.leftTime)
end

function ShrineHurdleShopWindow:ctor(name, params)
	ShrineHurdleShopWindow.super.ctor(self, name, params)

	self.curNav_ = 1
	self.curTabIndex = 1
	self.canClickTab = true
	self.itemList_ = {
		{},
		{},
		{}
	}
	self.groupList_ = {
		{},
		{},
		{}
	}
end

function ShrineHurdleShopWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.dragScroll_ = winTrans:ComponentByName("dragBg", typeof(UIDragScrollView))
	self.listItem_ = self.window_:NodeByName("list_item").gameObject
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
	self.dragScroll1_ = winTrans:ComponentByName("drag_1", typeof(UIDragScrollView))
	self.gridList1_ = winTrans:ComponentByName("scrollView_1/gridList", typeof(UIGrid))
	self.scrollView2_ = winTrans:ComponentByName("scrollView_2", typeof(UIScrollView))
	self.dragScroll2_ = winTrans:ComponentByName("drag_2", typeof(UIDragScrollView))
	self.gridList2_ = winTrans:ComponentByName("scrollView_2/gridList", typeof(UIGrid))
	self.scrollView3_ = winTrans:ComponentByName("scrollView_3", typeof(UIScrollView))
	self.dragScroll3_ = winTrans:ComponentByName("drag_3", typeof(UIDragScrollView))
	self.gridList3_ = winTrans:ComponentByName("scrollView_3/gridList", typeof(UIGrid))
	local chosen = {
		color = Color.New2(4160223231.0),
		effectColor = Color.New2(1012112383)
	}
	local unchosen = {
		color = Color.New2(4160223231.0),
		effectColor = Color.New2(876106751)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab = import("app.common.ui.CommonTabBar").new(self.navRoot_, 3, function (index)
		self:touchForRefresh(index)
	end, nil, colorParams)
	local tabText = {
		__("SHRINE_POOL_TEXT01"),
		__("SHRINE_POOL_TEXT02"),
		__("SHRINE_POOL_TEXT04")
	}

	self.tab:setTexts(tabText)

	self.tab2_redPoint = self.navRoot_:NodeByName("tab_2/redPoint").gameObject
end

function ShrineHurdleShopWindow:touchForRefresh(index)
	if not self.canClickTab then
		return
	end

	if index == 1 then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHRINE2)
	elseif index == 2 then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHRINE1)
	elseif index == 3 then
		xyd.models.shop:refreshShopInfo(xyd.ShopType.SHRINE2)
	end

	self.curTabIndex = index
	self.canClickTab = false

	self:waitForFrame(0.5, function ()
		self.canClickTab = true
	end)
end

function ShrineHurdleShopWindow:initWindow()
	ShrineHurdleShopWindow.super.initWindow(self)
	self:getComponent()
	self:register()
	self:layout()
end

function ShrineHurdleShopWindow:register()
	ShrineHurdleShopWindow.super.register(self)

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
end

function ShrineHurdleShopWindow:onGetShopInfo(evt)
	local index = 0

	if evt.data.shop_type == xyd.ShopType.SHRINE2 then
		index = 1
	elseif evt.data.shop_type == xyd.ShopType.SHRINE1 then
		index = 2
		self.curTabIndex = 2
	end

	dump(xyd.decodeProtoBuf(evt.data))

	if index > 0 then
		self:waitForFrame(0.1, function ()
			self:onTouchNav(self.curTabIndex)
		end)
	end
end

function ShrineHurdleShopWindow:layout()
	self:initTime()

	self.resItem1_ = ResItem.new(self.resNode1_)

	self.resItem1_:setInfo({
		hideBg = true,
		hidePlus = true,
		tableId = xyd.ItemID.SHRINE_COIN
	})
	self.resItem1_:showBothLine(true)
	self.resItem1_:SetActive(true)
	self.resNode1_:SetActive(self.curNav_ ~= 3)

	self.resItem2_ = ResItem.new(self.resNode2_)

	self.resItem2_:setInfo({
		hideBg = true,
		hidePlus = true,
		tableId = 373
	})
	self.resItem2_:showBothLine(true)
	self.resItem2_:SetActive(true)
	self.resNode2_:SetActive(self.curNav_ == 3)
	self.tab:setTabActive(self.curNav_, true)
end

function ShrineHurdleShopWindow:initTime()
	self.clockEffect_ = xyd.Spine.new(self.effectNode_)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
	end)
end

function ShrineHurdleShopWindow:onTouchNav(index)
	self.scrollView1_.gameObject:SetActive(index == 1)
	self.scrollView2_.gameObject:SetActive(index == 2)
	self.scrollView3_.gameObject:SetActive(index == 3)
	self.dragScroll1_:SetActive(index == 1)
	self.dragScroll2_:SetActive(index == 2)
	self.dragScroll3_:SetActive(index == 3)
	self.resNode1_:SetActive(index ~= 3)
	self.resNode2_:SetActive(index == 3)

	self.curNav_ = index

	xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

	local shopType = nil

	if index == 1 or index == 3 then
		shopType = xyd.ShopType.SHRINE2

		self.timeLabel_.gameObject:SetActive(true)
		self.effectNode_:SetActive(true)

		local startTime = xyd.models.shrineHurdleModel:getStartTime()
		local timeSet = xyd.tables.miscTable:split2num("shrine_time_interval", "value", "|")
		local timePass = math.fmod(xyd.getServerTime() - startTime, (timeSet[1] + timeSet[2]) * xyd.DAY_TIME)
		local leftTime = (timeSet[1] + timeSet[2]) * xyd.DAY_TIME - timePass

		if leftTime <= 0 then
			if not self.hasRefresh then
				self.hasRefresh = true

				xyd.models.shop:refreshShopInfo(shopType)
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

						xyd.models.shop:refreshShopInfo(shopType)
					end
				end
			})
		end
	elseif index == 2 then
		shopType = xyd.ShopType.SHRINE1

		self.timeLabel_.gameObject:SetActive(false)
		self.effectNode_:SetActive(false)
	end

	local shopInfo = xyd.models.shop:getShopInfo(shopType)

	if not shopInfo then
		return
	end

	local list = xyd.models.shrine:getShopData(index)

	dump(list, "shopdatas=================================")
	table.sort(list, function (infoA, infoB)
		if infoA.leftTime == 0 and infoB.leftTime == 0 then
			return infoA.index < infoB.index
		elseif infoA.leftTime == 0 then
			return false
		elseif infoB.leftTime == 0 then
			return true
		else
			return infoA.index < infoB.index
		end
	end)

	for i = 1, #list do
		local shopDatas = list[i]
		local shopGropItem = self.groupList_[index][i]

		if not shopGropItem then
			local node = NGUITools.AddChild(self["gridList" .. index .. "_"].gameObject, self.listItem_)

			node:SetActive(true)

			shopGropItem = ShrineShopItem.new(node, self)
			self.groupList_[index][i] = shopGropItem
		end

		shopGropItem:setInfo(shopDatas, index)
		shopGropItem:show(true)
	end

	if #self.groupList_[index] > #list then
		for i = #list + 1, #self.groupList_[index] do
			self.groupList_[index]:show(false)
		end
	end

	self["gridList" .. index .. "_"]:Reposition()
	self["scrollView" .. index .. "_"]:ResetPosition()
end

function ShrineHurdleShopWindow:buyItemRes(evt)
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

return ShrineHurdleShopWindow
