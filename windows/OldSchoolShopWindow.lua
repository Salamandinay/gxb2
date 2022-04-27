local OldSchoolShopWindow = class("OldSchoolShopWindow", import(".BaseWindow"))
local OldSchoolShopGroupItem = class("OldSchoolShopGroupItem", import("app.components.BaseComponent"))
local OldSchoolShopItem = class("OldSchoolShopItem", import("app.components.BaseComponent"))
local ResItem = import("app.components.ResItem")
local shopModel = xyd.models.shop
local oldSchool = xyd.models.oldSchool

function OldSchoolShopWindow:ctor(name, params)
	OldSchoolShopWindow.super.ctor(self, name, params)

	self.curNav_ = params.curNav or 1
	self.itemList_ = {
		{},
		{}
	}
	self.groupList_ = {
		{},
		{}
	}

	oldSchool:reqShopInfo()
end

function OldSchoolShopWindow:getComponent()
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
	self.closeBtn_ = winTrans:NodeByName("e:group/closeBtn").gameObject
	self.scrollView1_ = winTrans:ComponentByName("scrollView_1", typeof(UIScrollView))
	self.gridList1_ = winTrans:ComponentByName("scrollView_1/gridList", typeof(UIGrid))
	self.scrollView2_ = winTrans:ComponentByName("scrollView_2", typeof(UIScrollView))
	self.gridList2_ = winTrans:ComponentByName("scrollView_2/gridList", typeof(UIGrid))
	self.tab2_redPoint = self.navRoot_:NodeByName("tab_2/redPoint").gameObject
end

function OldSchoolShopWindow:initWindow()
	OldSchoolShopWindow.super.initWindow(self)
	self:getComponent()
	self:register()
end

function OldSchoolShopWindow:register()
	OldSchoolShopWindow.super.register(self)

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
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_GET_SHOP_INFO, handler(self, self.onGetShopInfo))
	self.eventProxy_:addEventListener(xyd.event.OLD_BUILDING_GET_SHOP_AWARD, handler(self, self.buyItemRes))
	self.tab2_redPoint:SetActive(false)
end

function OldSchoolShopWindow:onGetShopInfo(evt)
	self.buyTimes1 = {}
	self.buyTimes2 = {}
	local buyTimes1 = evt.data.buy_times1

	for _, num in ipairs(buyTimes1) do
		table.insert(self.buyTimes1, num)
	end

	local buyTimes2 = evt.data.buy_times2

	for _, num in ipairs(buyTimes2) do
		table.insert(self.buyTimes2, num)
	end

	self.tab = import("app.common.ui.CommonTabBar").new(self.navRoot_, 2, function (index)
		self:onTouchNav(index)
	end)
	local tabText = {
		__("OLD_SCHOOL_SHOP_TEXT1"),
		__("OLD_SCHOOL_SHOP_TEXT2")
	}

	self.tab:setTexts(tabText)
	self:layout()
	self:waitForFrame(0.1, function ()
		if self.tab then
			self.tab:setTabActive(self.curNav_, true)
		end
	end)
end

function OldSchoolShopWindow:layout()
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
end

function OldSchoolShopWindow:initTime()
	self.clockEffect_ = xyd.Spine.new(self.effectNode_)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
	end)
end

function OldSchoolShopWindow:onTouchNav(index)
	self.scrollView1_.gameObject:SetActive(index == 1)
	self.scrollView2_.gameObject:SetActive(index == 2)

	self.curNav_ = index

	if index == 2 then
		self.timeLabel_.gameObject:SetActive(false)
		self.effectNode_:SetActive(false)
	else
		self.timeLabel_.gameObject:SetActive(true)
		self.effectNode_:SetActive(true)

		local leftTime = xyd.models.oldSchool:getShowEndTime() - xyd.getServerTime()
		self.timeLabelCount_ = import("app.components.CountDown").new(self.timeLabel_)

		self.timeLabelCount_:setInfo({
			duration = leftTime,
			callback = function ()
				self:close()
			end
		})
	end

	self.dragScroll_.scrollView = self["scrollView" .. index .. "_"]
	local list = self:getSortData(index)

	for i = 1, #list do
		local shopGropItem = self.groupList_[index][i]

		if not self.groupList_[index][i] then
			shopGropItem = OldSchoolShopGroupItem.new(self["gridList" .. index .. "_"].gameObject, self)
			self.groupList_[index][i] = shopGropItem
		end

		shopGropItem:setInfo({
			index = i,
			itemInfo = list[i],
			group = self.curNav_,
			num = list[i][1].num,
			point = list[i][1].point
		})
	end

	self["gridList" .. index .. "_"]:Reposition()
	self["scrollView" .. index .. "_"]:ResetPosition()
end

function OldSchoolShopWindow:getSortData(index)
	local shopTable, buyTimes = nil

	if index == 1 then
		shopTable = xyd.tables.oldBuildingShop1Table
		buyTimes = self.buyTimes1
	else
		shopTable = xyd.tables.oldBuildingShop2Table
		buyTimes = self.buyTimes2
	end

	local pointArr = shopTable:getPointsArr()
	local pointParams = {}
	local list = {}

	for i = 1, #pointArr do
		pointParams[pointArr[i]] = i
		list[i] = {}
	end

	local ids = shopTable:getIds()

	for _, id in ipairs(ids) do
		local tempItem = {
			item = shopTable:getItem(id),
			cost = shopTable:getCost(id),
			buy_times = buyTimes[id],
			point = shopTable:getPoint(id),
			num = shopTable:getNum(id),
			id = id
		}
		local key = tempItem.num * 10000 + tempItem.point

		if pointParams[key] then
			table.insert(list[pointParams[key]], tempItem)
		end
	end

	return list
end

function OldSchoolShopWindow:buyItemRes(evt)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUY_ITEM)

	local items = evt.data.items

	xyd.alertItems(items)
end

function OldSchoolShopGroupItem:ctor(parentGo, parent)
	self.parent_ = parent

	OldSchoolShopGroupItem.super.ctor(self, parentGo)
end

function OldSchoolShopGroupItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_group"
end

function OldSchoolShopGroupItem:initUI()
	OldSchoolShopGroupItem.super.initUI(self)
	self:getComponent()
end

function OldSchoolShopGroupItem:getComponent()
	local goTrans = self.go.transform
	self.okImg_ = goTrans:NodeByName("okImg").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.textLabel_ = goTrans:ComponentByName("textLabel", typeof(UILabel))
	self.groupItem_ = goTrans:ComponentByName("groupItem", typeof(UIGrid))
	self.drag = self.go:AddComponent(typeof(UIDragScrollView))
end

function OldSchoolShopGroupItem:setInfo(params)
	self.index = params.index
	local isLock = nil

	if params.group == 1 then
		local pointArr = xyd.tables.oldBuildingShop1Table:getPointsArr()
		local point = pointArr[self.index] % 10000
		isLock = xyd.models.oldSchool:getAllInfo().score < point

		if isLock then
			self.textLabel_.text = __("OLD_SCHOOL_SHOP_TEXT3", point)
		else
			self.textLabel_.text = xyd.split(__("OLD_SCHOOL_SHOP_TEXT5"), "|")[self.index]
		end
	else
		local hisScores = xyd.models.oldSchool:getAllInfo().history_scores
		local curScores = xyd.models.oldSchool:getAllInfo().score
		local hasNum = 0

		if hisScores then
			for _, score in pairs(hisScores) do
				if params.point <= score then
					hasNum = hasNum + 1
				end
			end
		end

		if params.point <= curScores then
			hasNum = hasNum + 1
		end

		isLock = hasNum < params.num

		if isLock then
			self.textLabel_.text = __("OLD_SCHOOL_SHOP_TEXT4", params.num, hasNum, params.num, params.point)
		else
			self.textLabel_.text = xyd.split(__("OLD_SCHOOL_SHOP_TEXT6"), "|")[self.index]
		end

		if xyd.Global.lang == "fr_fr" then
			self.textLabel_.fontSize = 18
		end
	end

	self.lockImg_:SetActive(isLock)
	self.okImg_:SetActive(not isLock)

	self.drag.scrollView = self.parent_["scrollView" .. params.group .. "_"]

	self:refreshItem(params.itemInfo, params.group)
end

function OldSchoolShopGroupItem:refreshItem(itemInfo, group)
	local itemList = self.parent_.itemList_[group]

	for _, itemData in ipairs(itemInfo) do
		local idx = itemData.id
		local shopItem = nil

		if not itemList[idx] then
			shopItem = OldSchoolShopItem.new(self.groupItem_.gameObject, self.parent_)
			itemList[idx] = shopItem
		else
			shopItem = itemList[idx]
		end

		shopItem:setInfo(itemData, group)
	end

	self.groupItem_:Reposition()
end

function OldSchoolShopItem:ctor(parentGo, parent)
	self.parent_ = parent

	OldSchoolShopItem.super.ctor(self, parentGo)
end

function OldSchoolShopItem:getPrefabPath()
	return "Prefabs/Components/collection_shop_item"
end

function OldSchoolShopItem:initUI()
	OldSchoolShopItem.super.initUI(self)
	self:getComponent()
end

function OldSchoolShopItem:getComponent()
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

function OldSchoolShopItem:setInfo(params, group)
	self.needPoint_ = params.point
	self.cost_ = params.cost
	self.item_ = params.item
	self.buyTimes_ = params.buy_times or 0
	self.id = params.id
	self.group = group
	self.num = params.num
	self.drag.scrollView = self.parent_["scrollView" .. group .. "_"]
	self.drag2.scrollView = self.parent_["scrollView" .. group .. "_"]
	local shopTable = nil

	if group == 1 then
		shopTable = xyd.tables.oldBuildingShop1Table
	else
		shopTable = xyd.tables.oldBuildingShop2Table
	end

	self.limit = shopTable:getBuyTime(self.id)

	self:layout()
end

function OldSchoolShopItem:onTouch()
	if self.limit > 0 and self.buyTimes_ and self.limit <= self.buyTimes_ then
		return
	end

	local cost = self.cost_

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	if self.limit - self.buyTimes_ == 1 then
		xyd.alertYesNo(__("CONFIRM_BUY"), function (yes_no)
			if yes_no then
				local msg = messages_pb:old_building_get_shop_award_req()
				msg.table_id = tonumber(self.id)
				msg.type = tonumber(self.group)
				msg.num = 1

				xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_SHOP_AWARD, msg)

				self.buyTimes_ = self.buyTimes_ + 1
				self.parent_["buyTimes" .. self.group][self.id] = self.parent_["buyTimes" .. self.group][self.id] + 1

				self:updateShaddow()
			end
		end)
	else
		local params = {
			hasMaxMin = true,
			buyType = self.item_[1],
			buyNum = self.item_[2],
			costType = cost[1],
			costNum = cost[2]
		}

		function params.purchaseCallback(_, num)
			local msg = messages_pb:old_building_get_shop_award_req()
			msg.table_id = tonumber(self.id)
			msg.type = tonumber(self.group)
			msg.num = num

			xyd.Backend.get():request(xyd.mid.OLD_BUILDING_GET_SHOP_AWARD, msg)

			self.buyTimes_ = self.buyTimes_ + num
			self.parent_["buyTimes" .. self.group][self.id] = self.parent_["buyTimes" .. self.group][self.id] + num

			self:updateShaddow()
		end

		params.titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(self.item_[1]))
		params.limitNum = self.limit - self.buyTimes_
		params.eventType = xyd.event.OLD_BUILDING_GET_SHOP_AWARD

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function OldSchoolShopItem:layout()
	self.has_buy_words_.text = __("ALREADY_BUY")

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "ja_jp" or xyd.Global.lang == "fr_fr" then
		self.name_text_.fontSize = 16
	end

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			notSciNotation = true,
			uiRoot = self.iconNode_,
			itemID = self.item_[1],
			num = self.item_[2],
			dragScrollView = self.parent_["scrollView" .. self.group .. "_"]
		})
	else
		self.itemIcon_:setInfo({
			notSciNotation = true,
			itemID = self.item_[1],
			num = self.item_[2]
		})
	end

	xyd.setUISpriteAsync(self.res_icon_, nil, "icon_" .. self.cost_[1])

	self.res_text_.text = xyd.getRoughDisplayNumber(self.cost_[2])

	self:updateShaddow()
end

function OldSchoolShopItem:updateShaddow()
	self.name_text_.text = __("BUY_GIFTBAG_LIMIT", self.buyTimes_ .. "/" .. self.limit)
	local hideBg = nil

	if self.group == 1 then
		hideBg = xyd.models.oldSchool:getAllInfo().score < self.needPoint_
	else
		local hisScores = xyd.models.oldSchool:getAllInfo().history_scores
		local curScores = xyd.models.oldSchool:getAllInfo().score
		local hasNum = 0

		if hisScores then
			for _, score in pairs(hisScores) do
				if self.needPoint_ <= score then
					hasNum = hasNum + 1
				end
			end
		end

		if self.needPoint_ <= curScores then
			hasNum = hasNum + 1
		end

		hideBg = hasNum < self.num
	end

	self.shadow_:SetActive(self.limit <= self.buyTimes_ or hideBg)
	self.buyNode_:SetActive(self.limit <= self.buyTimes_)
end

return OldSchoolShopWindow
