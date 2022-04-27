local DressShowShopWindow = class("DressShowShopWindow", import(".BaseWindow"))
local CountDown = require("app.components.CountDown")
local DressShowShop1Item = class("DressShowShop1Item", import("app.components.CopyComponent"))
local DressShowShop2PartItem = class("DressShowShop2PartItem", import("app.components.CopyComponent"))
local DressShowShop2Item = class("DressShowShop2Item", import("app.components.CopyComponent"))
local DressShowShop3PartItem = class("DressShowShop3PartItem", import("app.components.CopyComponent"))
local DressShowShop3Item = class("DressShowShop3Item", import("app.components.CopyComponent"))
local CommonTabBar = import("app.common.ui.CommonTabBar")

function DressShowShopWindow:ctor(name, params)
	DressShowShopWindow.super.ctor(self, name, params)
end

function DressShowShopWindow:initWindow()
	DressShowShopWindow.super.initWindow()

	self.activityData = xyd.models.dressShow

	self.activityData:refreshShop2Info()
	self.activityData:refreshShop3Info()
	self:getUIComponent()
	self:registerEvent()

	self.firstTime = {
		false,
		false,
		false
	}
end

function DressShowShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn = self.groupAction:NodeByName("helpBtn").gameObject
	self.labelWinTitle = self.groupAction:ComponentByName("labelWinTitle", typeof(UILabel))
	self.nav = self.groupAction:NodeByName("nav").gameObject
	self.tab_1 = self.nav:NodeByName("tab_1").gameObject
	self.tab_2 = self.nav:NodeByName("tab_2").gameObject
	self.tab_3 = self.nav:NodeByName("tab_3").gameObject
	self.content = self.groupAction:NodeByName("content").gameObject
	self.resourcesGroup = self.content:NodeByName("resourcesGroup").gameObject
	self.resource1Group = self.resourcesGroup:NodeByName("resource1Group").gameObject
	self.imgResource1 = self.resource1Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource1 = self.resource1Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn1 = self.resource1Group:NodeByName("addBtn").gameObject
	self.resource2Group = self.resourcesGroup:NodeByName("resource2Group").gameObject
	self.imgResource2 = self.resource2Group:ComponentByName("img_", typeof(UISprite))
	self.labelResource2 = self.resource2Group:ComponentByName("label_", typeof(UILabel))
	self.addBtn2 = self.resource2Group:NodeByName("addBtn").gameObject
	self.timeGroup = self.resourcesGroup:NodeByName("timeGroup").gameObject
	self.timeEffectPos = self.timeGroup:ComponentByName("timeEffectPos", typeof(UITexture))
	self.labelTime = self.timeGroup:ComponentByName("label", typeof(UILabel))
	self.content1Group = self.content:NodeByName("content1Group").gameObject
	self.scroller1 = self.content1Group:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup1 = self.scroller1:ComponentByName("itemGroup", typeof(UIGrid))
	self.item1 = self.scroller1:NodeByName("item").gameObject
	self.content2Group = self.content:NodeByName("content2Group").gameObject
	self.scroller2 = self.content2Group:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup2 = self.scroller2:ComponentByName("itemGroup", typeof(UILayout))
	self.PartItem2 = self.scroller2:NodeByName("lockPart").gameObject
	self.PartItem2ItemGroup = self.PartItem2:ComponentByName("itemGroup", typeof(UIGrid))
	self.lockPart = self.scroller2:NodeByName("lockPart").gameObject
	self.titleGroup = self.lockPart:NodeByName("titleGroup").gameObject
	self.labelUnlockTitle = self.titleGroup:ComponentByName("labelUnlockTitle", typeof(UILabel))
	self.itemGroupLock = self.lockPart:ComponentByName("itemGroup", typeof(UIGrid))
	self.item2 = self.scroller2:NodeByName("item").gameObject
	self.content3Group = self.content:NodeByName("content3Group").gameObject
	self.scroller3 = self.content3Group:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup3 = self.scroller3:ComponentByName("itemGroup", typeof(UILayout))
	self.PartItem3 = self.scroller3:NodeByName("lockPart").gameObject
	self.PartItem3ItemGroup = self.PartItem3:ComponentByName("itemGroup", typeof(UIGrid))
	self.lockPart = self.scroller3:NodeByName("lockPart").gameObject
	self.titleGroup = self.lockPart:NodeByName("titleGroup").gameObject
	self.labelUnlockTitle = self.titleGroup:ComponentByName("labelUnlockTitle", typeof(UILabel))
	self.itemGroupLock = self.lockPart:ComponentByName("itemGroup", typeof(UIGrid))
	self.item3 = self.scroller3:NodeByName("item").gameObject
	self.tabIndex = 1
	self.tabBar = CommonTabBar.new(self.nav, 3, function (index)
		self.tabIndex = index

		self.content1Group:SetActive(false)
		self.content2Group:SetActive(false)
		self.content3Group:SetActive(false)
		self.timeGroup:SetActive(self.tabIndex ~= 2)
		self["content" .. self.tabIndex .. "Group"]:SetActive(true)
		self["itemGroup" .. self.tabIndex]:Reposition()
		self["scroller" .. self.tabIndex]:ResetPosition()
	end, nil, , 15)
end

function DressShowShopWindow:addTitle()
	if self.labelWinTitle then
		self.labelWinTitle.text = __("SHOW_WINDOW_TEXT30")
	end
end

function DressShowShopWindow:layout()
	self.labelWinTitle.text = __("SHOW_WINDOW_TEXT30")
	self.tabBar.tabs[1].label.text = __("SHOW_WINDOW_TEXT31")
	self.tabBar.tabs[2].label.text = __("SHOW_WINDOW_TEXT32")
	self.tabBar.tabs[3].label.text = __("SHOW_WINDOW_TEXT33")
	local effect = xyd.Spine.new(self.timeEffectPos.gameObject)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.countDownTime = CountDown.new(self.labelTime)
	local duration = xyd.calcTimeToNextWeek() - xyd.getServerTime()

	if duration >= 3 * xyd.DAY_TIME then
		duration = duration - 3 * xyd.DAY_TIME
	else
		duration = 4 * xyd.DAY_TIME + duration
	end

	self.countDownTime:setInfo({
		duration = duration
	})
	self:initContentGroup1()
	self:initContentGroup2()
	self:initContentGroup3()
	self:updateResGroup()
end

function DressShowShopWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function (event)
		self:updateResGroup()
	end)
	self.eventProxy_:addEventListener(xyd.event.SHOW_WINDOW_BUY_BUFF, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local tableID = data.table_id
		local num = data.num
		local itemID = xyd.tables.dressShowWindowShop1Table:getItemIcon(tableID)

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = itemID,
				item_num = num
			}
		})
		self:initContentGroup1(true)
	end)
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, function (event)
		local data = xyd.decodeProtoBuf(event.data)
		local tableID = data.table_id
		local num = data.num
		local itemID = xyd.tables.dressShowWindowShop1Table:getItemIcon(tableID)

		xyd.models.itemFloatModel:pushNewItems({
			self.needAlertItems
		})
		self:initContentGroup2(true)
		self:initContentGroup3(true)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, function ()
		local data2 = xyd.models.shop:getShopInfo(xyd.ShopType.DRESS_SHOW_SHOP2)
		local data3 = xyd.models.shop:getShopInfo(xyd.ShopType.DRESS_SHOW_SHOP3)

		if not data2 or not data3 then
			return
		end

		self:layout()
	end)

	UIEventListener.Get(self.addBtn1).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = self.resData[self.tabIndex][1],
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.addBtn2).onClick = function ()
		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = self.resData[self.tabIndex][2],
			wndType = xyd.ItemTipsWndType.NORMAL
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.closeWindow("dress_show_shop_window")
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SHOW_WINDOW_SHOP_HELP"
		})
	end
end

function DressShowShopWindow:initContentGroup1(keepPos)
	self.shop1Data = self.activityData:getShop1Data()

	if not self.shop1Items then
		self.shop1Items = {}
	end

	for i = 1, #self.shop1Data do
		if not self.shop1Items[i] then
			local tran = NGUITools.AddChild(self.itemGroup1.gameObject, self.item1)
			local item = DressShowShop1Item.new(tran, self)

			item:setInfo(self.shop1Data[i])
			table.insert(self.shop1Items, item)
		else
			self.shop1Items[i]:setInfo(self.shop1Data[i])
		end
	end

	self.itemGroup1:Reposition()

	if not keepPos then
		local sp = self.scroller1.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = self.initPos

		SpringPanel.Stop(self.scroller1.gameObject)
		SpringPanel.Begin(self.scroller1.gameObject, Vector3(0, -202, 0), 128)
	end
end

function DressShowShopWindow:initContentGroup2(keepPos)
	self.shop2Data = self.activityData:getShop2Data()

	if not self.shop2PartItems then
		self.shop2PartItems = {}
	end

	for i = 1, #self.shop2Data do
		self.shop2Data[i].index = i

		if not self.shop2PartItems[i] then
			local tran = NGUITools.AddChild(self.itemGroup2.gameObject, self.PartItem2)
			local item = DressShowShop2PartItem.new(tran, self)

			item:setInfo(self.shop2Data[i])

			self.shop2PartItems[i] = item
		else
			self.shop2PartItems[i]:setInfo(self.shop2Data[i])
		end
	end

	self.itemGroup2:Reposition()

	if not keepPos then
		local sp = self.scroller2.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = self.initPos

		SpringPanel.Stop(self.scroller2.gameObject)
		SpringPanel.Begin(self.scroller2.gameObject, Vector3(0, -549, 0), 128)
	end
end

function DressShowShopWindow:initContentGroup3(keepPos)
	self.shop3Data = self.activityData:getShop3Data()

	if not self.shop3PartItems then
		self.shop3PartItems = {}
	end

	for i = 1, #self.shop3Data do
		self.shop3Data[i].index = i

		if not self.shop3PartItems[i] then
			local tran = NGUITools.AddChild(self.itemGroup3.gameObject, self.PartItem3)
			local item = DressShowShop3PartItem.new(tran, self)

			item:setInfo(self.shop3Data[i])

			self.shop3PartItems[i] = item
		else
			self.shop3PartItems[i]:setInfo(self.shop3Data[i])
		end
	end

	self.itemGroup3:Reposition()

	if not keepPos then
		local sp = self.scroller3.gameObject:GetComponent(typeof(SpringPanel))
		local initPos = self.initPos

		SpringPanel.Stop(self.scroller3.gameObject)
		SpringPanel.Begin(self.scroller3.gameObject, Vector3(0, -913, 0), 128)
	end
end

function DressShowShopWindow:updateResGroup()
	self.resData = {
		{
			314,
			315
		},
		{
			314,
			315
		},
		{
			314,
			315
		}
	}

	xyd.setUISpriteAsync(self.imgResource1, nil, xyd.tables.itemTable:getIcon(self.resData[self.tabIndex][1]))

	self.labelResource1.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.resData[self.tabIndex][1]))

	xyd.setUISpriteAsync(self.imgResource2, nil, xyd.tables.itemTable:getIcon(self.resData[self.tabIndex][2]))

	self.labelResource2.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(self.resData[self.tabIndex][2]))
end

function DressShowShop1Item:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowShop1Item.super.ctor(self, go)
	self:initUI()
end

function DressShowShop1Item:initUI()
	self:getUIComponent()
	self:register()
end

function DressShowShop1Item:getUIComponent()
	self.leftGroup = self.go:NodeByName("leftGroup").gameObject
	self.icon = self.leftGroup:ComponentByName("icon", typeof(UISprite))
	self.labelLimit = self.leftGroup:ComponentByName("labelLimit", typeof(UILabel))
	self.midGroup = self.go:NodeByName("midGroup").gameObject
	self.labelTitle = self.midGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.descScroller = self.midGroup:ComponentByName("descGroup", typeof(UIScrollView))
	self.labelDesc = self.midGroup:ComponentByName("descGroup/labelDesc", typeof(UILabel))
	self.rightGroup = self.go:NodeByName("rightGroup").gameObject
	self.labelTip = self.rightGroup:ComponentByName("labelTip", typeof(UILabel))
	self.awakeTimeGroup = self.midGroup:NodeByName("awakeTimeGroup").gameObject
	self.NoAwakeTimeGroup = self.awakeTimeGroup:NodeByName("NoAwakeTimeGroup").gameObject
	self.labelAwakeTime = self.awakeTimeGroup:ComponentByName("labelAwakeTime", typeof(UILabel))
	self.labelNoAwake = self.NoAwakeTimeGroup:ComponentByName("labelNoAwake", typeof(UILabel))
	self.btnBuy = self.rightGroup:NodeByName("btnBuy").gameObject
	self.labelBuyBtn = self.btnBuy:ComponentByName("labelBuyBtn", typeof(UILabel))
	self.costIcon = self.btnBuy:ComponentByName("icon", typeof(UISprite))
	self.btnDetail = self.rightGroup:NodeByName("btnDetail").gameObject
end

function DressShowShop1Item:register()
	UIEventListener.Get(self.btnBuy).onClick = function ()
		if not xyd.checkFunctionOpen(self.data.funID) then
			xyd.alertTips(__("SHOW_WINDOW_TEXT04", xyd.tables.functionTable:getName(self.data.funID)))

			return
		end

		if xyd.models.backpack:getItemNumByID(self.data.cost[1]) < self.data.cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.data.cost[1])))
		else
			local max_num = math.min(self.data.limitTime - self.data.buyTime, self.data.maxTime - self.data.awakeTime)

			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = true,
				item_no_click = true,
				cost = self.data.cost,
				max_num = max_num,
				itemParams = {
					itemID = self.data.item[1],
					num = self.data.item[2]
				},
				buyCallback = function (num)
					self.parent.activityData:buyShopItem(self.data.tableID, num)
				end,
				maxCallback = function ()
					if self.data.limitTime - self.data.buyTime == max_num then
						xyd.showToast(__("FULL_BUY_SLOT_TIME"))
					else
						xyd.showToast(__("SHOW_WINDOW_TEXT46"))
					end
				end
			})
		end
	end

	UIEventListener.Get(self.btnDetail).onClick = function ()
		xyd.openWindow("dress_show_buffs_detail_window", {
			buffTableID = self.data.tableID
		})
	end
end

function DressShowShop1Item:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local data = params
	self.data = data
	self.labelLimit.text = __("SHOW_WINDOW_TEXT34", data.limitTime - data.buyTime)

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.functionTable:getIcon(data.funID))

	if data.awakeTime > 0 then
		self.labelAwakeTime:SetActive(true)
		self.NoAwakeTimeGroup:SetActive(false)

		self.labelAwakeTime.text = __("SHOW_WINDOW_TEXT36", data.awakeTime)
	else
		self.labelAwakeTime:SetActive(false)
		self.NoAwakeTimeGroup:SetActive(true)

		self.labelNoAwake.text = __("SHOW_WINDOW_TEXT35")
	end

	self.labelBuyBtn.text = data.cost[2]
	self.labelTitle.text = xyd.tables.dressShowShopTextTable:getName(data.tableID)
	self.labelDesc.text = xyd.tables.dressShowShopTextTable:getDesc1(data.tableID)

	xyd.setUISpriteAsync(self.costIcon, nil, xyd.tables.itemTable:getIcon(data.cost[1]))

	local box = self.btnBuy:GetComponent(typeof(UnityEngine.BoxCollider))

	if data.limitTime - data.buyTime <= 0 or data.maxTime <= data.awakeTime then
		xyd.applyChildrenGrey(self.btnBuy.gameObject)

		box.enabled = false
	else
		xyd.applyChildrenOrigin(self.btnBuy.gameObject)

		box.enabled = true
	end

	self.descScroller:ResetPosition()
end

function DressShowShop2PartItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowShop2PartItem.super.ctor(self, go)
	self:initUI()
end

function DressShowShop2PartItem:initUI()
	self.itemHeight = 219
	self.itemGap = 12
	self.titleHeight = 42
	self.perRow = 4

	self:getUIComponent()
	self:register()
end

function DressShowShop2PartItem:getUIComponent()
	self.titleGroup = self.go:NodeByName("titleGroup").gameObject
	self.bg = self.titleGroup:ComponentByName("bg", typeof(UITexture))
	self.labelUnlockTitle = self.titleGroup:ComponentByName("labelUnlockTitle", typeof(UILabel))
	self.itemGroup = self.go:ComponentByName("itemGroup", typeof(UIGrid))
	self.goWidget = self.go:ComponentByName("", typeof(UIWidget))
end

function DressShowShop2PartItem:register()
end

function DressShowShop2PartItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local datas = params

	if not datas or #datas == 0 then
		self.titleGroup:SetActive(false)

		return
	end

	local curPoint = self.parent.activityData:getHistoryTotalScore()

	dump(curPoint)
	dump(datas[1].point)
	dump(datas)

	if curPoint < datas[1].point then
		self.labelUnlockTitle.text = __("SHOW_WINDOW_TEXT40", datas[1].point)

		xyd.setUITextureByNameAsync(self.bg, "collection_unlock_unit_bg")
	else
		self.labelUnlockTitle.text = xyd.split(__("SHOW_WINDOW_TEXT45"), "|")[datas.index]

		xyd.setUITextureByNameAsync(self.bg, "collection_shop_title_bg")
	end

	if not self.items then
		self.items = {}
	end

	local i = 1

	for _, data in pairs(datas) do
		if data and type(data) ~= "number" then
			if not self.items[i] then
				local tran = NGUITools.AddChild(self.itemGroup.gameObject, self.parent.item2)
				local item = DressShowShop2Item.new(tran, self)

				item:setInfo(data)
				table.insert(self.items, item)
			else
				self.items[i]:setInfo(data)
			end

			i = i + 1
		end
	end

	self:changeSelfHeight(true, math.ceil(#self.items / self.perRow))
	self.itemGroup:Reposition()
end

function DressShowShop2PartItem:changeSelfHeight(isActive, rowNum)
	if isActive == false then
		self.goWidget.height = 2

		return
	end

	self.goWidget.height = self.titleHeight + self.itemHeight * rowNum + self.itemGap * (rowNum - 1)
end

function DressShowShop2Item:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowShop2Item.super.ctor(self, go)
	self:initUI()
end

function DressShowShop2Item:initUI()
	self:getUIComponent()
	self:register()
end

function DressShowShop2Item:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.btnBuy = self.go:NodeByName("btnBuy").gameObject
	self.labelBuyBtn = self.btnBuy:ComponentByName("labelBuyBtn", typeof(UILabel))
	self.icon = self.btnBuy:ComponentByName("icon", typeof(UISprite))
	self.mask = self.go:NodeByName("mask").gameObject
	self.labelHaveBuy = self.mask:ComponentByName("labelHaveBuy", typeof(UILabel))
	self.shadow = self.go:NodeByName("shadow").gameObject
end

function DressShowShop2Item:register()
	UIEventListener.Get(self.btnBuy).onClick = function ()
		if self.parent.parent.activityData:getHistoryTotalScore() < self.data.point then
			xyd.alertTips("SHOW_WINDOW_TEXT41")

			return
		end

		if xyd.models.backpack:getItemNumByID(self.data.cost[1]) < self.data.cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.data.cost[1])))
		else
			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = true,
				item_no_click = true,
				cost = self.data.cost,
				max_num = self.data.leftTime,
				itemParams = {
					itemID = self.data.item[1],
					num = self.data.item[2]
				},
				buyCallback = function (num)
					self.parent.parent.activityData:reqShopAward(xyd.ShopType.DRESS_SHOW_SHOP2, self.data.tableID, num)

					local item = xyd.tables.dressShowWindowShop2Table:getItem(self.data.tableID)
					self.parent.parent.needAlertItems = {
						item_id = item[1],
						item_num = item[2] * num
					}
				end,
				maxCallback = function ()
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			})
		end
	end
end

function DressShowShop2Item:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local datas = params
	self.data = datas

	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			hideText = true,
			uiRoot = self.iconPos,
			itemID = datas.item[1],
			num = datas.item[2],
			dragScrollView = self.parent.parent.scroller2
		})
	else
		self.itemIcon:setInfo({
			hideText = true,
			uiRoot = self.iconPos,
			itemID = datas.item[1],
			num = datas.item[2],
			dragScrollView = self.parent.parent.scroller2
		})
	end

	self.labelLimit.text = __("SHOW_WINDOW_TEXT34", datas.leftTime .. "/" .. datas.limitTime)

	if xyd.Global.lang == "ko_kr" or xyd.Global.lang == "fr_fr" then
		self.labelLimit.fontSize = 18
	end

	self.mask:SetActive(datas.leftTime <= 0)
	self.shadow:SetActive(self.parent.parent.activityData:getHistoryTotalScore() < self.data.point)
	self.labelHaveBuy:SetActive(datas.leftTime <= 0)

	self.labelHaveBuy.text = __("SHOW_WINDOW_TEXT42")
	self.labelBuyBtn.text = datas.cost[2]

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.itemTable:getIcon(datas.cost[1]))
end

function DressShowShop3PartItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowShop3PartItem.super.ctor(self, go)
	self:initUI()
end

function DressShowShop3PartItem:initUI()
	self.itemHeight = 219
	self.itemGap = 12
	self.titleHeight = 42
	self.perRow = 4

	self:getUIComponent()
	self:register()
end

function DressShowShop3PartItem:getUIComponent()
	self.titleGroup = self.go:NodeByName("titleGroup").gameObject
	self.bg = self.titleGroup:ComponentByName("bg", typeof(UITexture))
	self.labelUnlockTitle = self.titleGroup:ComponentByName("labelUnlockTitle", typeof(UILabel))
	self.itemGroup = self.go:ComponentByName("itemGroup", typeof(UIGrid))
	self.goWidget = self.go:ComponentByName("", typeof(UIWidget))
end

function DressShowShop3PartItem:register()
end

function DressShowShop3PartItem:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local datas = params

	if not datas or #datas == 0 then
		self.titleGroup:SetActive(false)

		return
	end

	local curPoint = self.parent.activityData:getHistoryTotalScore()

	if curPoint < datas[1].point then
		self.labelUnlockTitle.text = __("SHOW_WINDOW_TEXT40", datas[1].point)

		xyd.setUITextureByNameAsync(self.bg, "collection_unlock_unit_bg")
	else
		self.labelUnlockTitle.text = xyd.split(__("SHOW_WINDOW_TEXT45"), "|")[datas.index]

		xyd.setUITextureByNameAsync(self.bg, "collection_shop_title_bg")
	end

	if not self.items then
		self.items = {}
	end

	local i = 1

	for _, data in pairs(datas) do
		if data and type(data) ~= "number" then
			if not self.items[i] then
				local tran = NGUITools.AddChild(self.itemGroup.gameObject, self.parent.item3)
				local item = DressShowShop3Item.new(tran, self)

				item:setInfo(data)
				table.insert(self.items, item)
			else
				self.items[i]:setInfo(data)
			end

			i = i + 1
		end
	end

	self:changeSelfHeight(true, math.ceil(#self.items / self.perRow))
	self.itemGroup:Reposition()
end

function DressShowShop3PartItem:changeSelfHeight(isActive, rowNum)
	if isActive == false then
		self.goWidget.height = 2

		return
	end

	self.goWidget.height = self.titleHeight + self.itemHeight * rowNum + self.itemGap * (rowNum - 1)
end

function DressShowShop3Item:ctor(go, parent)
	self.go = go
	self.parent = parent

	DressShowShop3Item.super.ctor(self, go)
	self:initUI()
end

function DressShowShop3Item:initUI()
	self:getUIComponent()
	self:register()
end

function DressShowShop3Item:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.btnBuy = self.go:NodeByName("btnBuy").gameObject
	self.labelBuyBtn = self.btnBuy:ComponentByName("labelBuyBtn", typeof(UILabel))
	self.icon = self.btnBuy:ComponentByName("icon", typeof(UISprite))
	self.mask = self.go:NodeByName("mask").gameObject
	self.shadow = self.go:NodeByName("shadow").gameObject
	self.labelHaveBuy = self.mask:ComponentByName("labelHaveBuy", typeof(UILabel))
end

function DressShowShop3Item:register()
	UIEventListener.Get(self.btnBuy).onClick = function ()
		if self.parent.parent.activityData:getHistoryTotalScore() < self.data.point then
			xyd.alertTips("SHOW_WINDOW_TEXT41")

			return
		end

		if xyd.models.backpack:getItemNumByID(self.data.cost[1]) < self.data.cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.data.cost[1])))
		else
			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = true,
				item_no_click = true,
				cost = self.data.cost,
				max_num = self.data.leftTime,
				itemParams = {
					itemID = self.data.item[1],
					num = self.data.item[2]
				},
				buyCallback = function (num)
					self.parent.parent.activityData:reqShopAward(xyd.ShopType.DRESS_SHOW_SHOP3, self.data.tableID, num)

					local item = xyd.tables.dressShowWindowShop3Table:getItem(self.data.tableID)
					self.parent.parent.needAlertItems = {
						item_id = item[1],
						item_num = item[2] * num
					}
				end,
				maxCallback = function ()
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			})
		end
	end
end

function DressShowShop3Item:setInfo(params)
	if not params then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	local datas = params
	self.data = datas

	if not self.itemIcon then
		self.itemIcon = xyd.getItemIcon({
			hideText = true,
			uiRoot = self.iconPos,
			itemID = datas.item[1],
			num = datas.item[2],
			dragScrollView = self.parent.parent.scroller3
		})
	else
		self.itemIcon:setInfo({
			hideText = true,
			uiRoot = self.iconPos,
			itemID = datas.item[1],
			num = datas.item[2],
			dragScrollView = self.parent.parent.scroller3
		})
	end

	self.labelLimit.text = __("SHOW_WINDOW_TEXT34", datas.leftTime .. "/" .. datas.limitTime)

	if xyd.Global.lang == "ko_kr" or xyd.Global.lang == "fr_fr" then
		self.labelLimit.fontSize = 18
	end

	self.mask:SetActive(datas.leftTime <= 0)
	self.shadow:SetActive(self.parent.parent.activityData:getHistoryTotalScore() < self.data.point)
	self.labelHaveBuy:SetActive(datas.leftTime <= 0)

	self.labelHaveBuy.text = __("SHOW_WINDOW_TEXT42")
	self.labelBuyBtn.text = datas.cost[2]

	xyd.setUISpriteAsync(self.icon, nil, xyd.tables.itemTable:getIcon(datas.cost[1]))
end

return DressShowShopWindow
