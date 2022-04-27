local BaseWindow = import(".BaseWindow")
local GuildDiningHall = class("GuildDiningHall", BaseWindow)
local GuildDiningHallItem = class("GuildDiningHallItem", require("app.components.CopyComponent"))
local GuildDiningHallRankItem = class("GuildDiningHallRankItem", require("app.components.CopyComponent"))
local GuildDiningHallBuildingItem = class("GuildDiningHallBuildingItem", require("app.components.CopyComponent"))

function GuildDiningHall:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.donateState = {
		[1.0] = false,
		[2.0] = false
	}
	self.currentIndex = 1
	self.Effects = {}
	self.diningHallItems = {}
	self.upgradeLevel = 0
end

function GuildDiningHall:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
	xyd.models.guild:reqDiningHallOrderList()
	self:updateUpIcon()
end

function GuildDiningHall:getUIComponent()
	local go = self.window_
	local main = go:NodeByName("main").gameObject
	self.labelWinTitle = main:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	self.helpBtn = main:NodeByName("helpBtn").gameObject
	self.nav = main:NodeByName("nav").gameObject
	self.view1 = main:NodeByName("view1").gameObject
	self.orderNum = self.view1:ComponentByName("orderNum", typeof(UILabel))
	local countDown = self.view1:ComponentByName("countDown", typeof(UILabel))
	self.countDown = require("app.components.CountDown").new(countDown)
	self.btnGetOrder = self.view1:NodeByName("btnGetOrder").gameObject
	self.btnGetOrder_label = self.btnGetOrder:ComponentByName("button_label", typeof(UILabel))
	self.btnGetOrder_mask = self.btnGetOrder:ComponentByName("mask", typeof(UISprite)).gameObject
	self.btnUpgradeOrder = self.view1:NodeByName("btnUpgradeOrder").gameObject
	self.btnUpgradeOrder_label = self.btnUpgradeOrder:ComponentByName("button_label", typeof(UILabel))
	self.btnUpgradeOrder_mask = self.btnUpgradeOrder:ComponentByName("mask", typeof(UISprite)).gameObject
	self.btnUpgradeOrder_lock = self.btnUpgradeOrder:ComponentByName("lock", typeof(UISprite)).gameObject
	self.btnUpgradeOrder_effect = self.btnUpgradeOrder:NodeByName("effect").gameObject
	self.btnStartOrder = self.view1:NodeByName("btnStartOrder").gameObject
	self.btnStartOrder_label = self.btnStartOrder:ComponentByName("button_label", typeof(UILabel))
	self.btnStartOrder_mask = self.btnStartOrder:ComponentByName("mask", typeof(UISprite)).gameObject
	self.btnStartOrder_lock = self.btnStartOrder:ComponentByName("lock", typeof(UISprite)).gameObject
	self.btnStartOrder_effect = self.btnStartOrder:NodeByName("effect").gameObject
	self.orderScroller_ = self.view1:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.orderGroup = self.view1:NodeByName("e:Scroller/orderGroup").gameObject
	self.orderNone = self.view1:NodeByName("orderNone").gameObject
	self.labelNone = self.orderNone:ComponentByName("labelNone", typeof(UILabel))
	self.view2 = main:NodeByName("view2").gameObject
	self.maxLev = self.view2:ComponentByName("maxLev", typeof(UISprite))
	local res = self.view2:NodeByName("res").gameObject
	self.res = require("app.components.ResItem").new(res)
	self.upProgressbar = self.view2:ComponentByName("upProgressbar", typeof(UIProgressBar))
	self.upProgressbar_label = self.upProgressbar:ComponentByName("label", typeof(UILabel))
	self.finalGroup = self.view2:NodeByName("finalGroup").gameObject
	self.changeGroup = self.view2:NodeByName("changeGroup").gameObject
	self.beforeBuilding = self.changeGroup:NodeByName("beforeBuilding").gameObject
	self.afterBuilding = self.changeGroup:NodeByName("afterBuilding").gameObject
	self.labelCostRes1 = self.view2:ComponentByName("cost1/labelCostRes1", typeof(UILabel))
	self.labelCostRes10 = self.view2:ComponentByName("cost10/labelCostRes10", typeof(UILabel))
	self.cost1 = self.view2:NodeByName("cost1").gameObject
	self.cost10 = self.view2:NodeByName("cost10").gameObject
	self.btnDonate1 = self.view2:NodeByName("btnDonate1").gameObject
	self.btnDonate10 = self.view2:NodeByName("btnDonate10").gameObject
	self.btnDonate1_label = self.btnDonate1:ComponentByName("button_label", typeof(UILabel))
	self.btnDonate10_label = self.btnDonate10:ComponentByName("button_label", typeof(UILabel))
	self.view3 = main:NodeByName("view3").gameObject
	self.groupRank = self.view3:NodeByName("e:Scroller/groupRank").gameObject
	self.guildMask_ = main:NodeByName("e:Group/e:Image").gameObject
	self.effectGroup = main:NodeByName("e:Group/effectGroup").gameObject
	self.upIcon = main:NodeByName("upIcon").gameObject
	self.guild_dininghall_rank_item = go:NodeByName("guild_dininghall_rank_item").gameObject
	self.guild_dininghall_item = go:NodeByName("guild_dininghall_item").gameObject
	self.guild_dininghall_building_item = go:NodeByName("guild_dininghall_building_item").gameObject

	self.guild_dininghall_rank_item:SetActive(false)
	self.guild_dininghall_item:SetActive(false)
	self.guild_dininghall_building_item:SetActive(false)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local params = {
			key = self:winName() .. "_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end
end

function GuildDiningHall:initUIComponent()
	if not self.timer_ then
		self.timer_ = Timer.New(handler(self, self.updateTime), 1, -1, false)
	end

	self.tab = require("app.common.ui.CommonTabBar").new(self.nav, 3, function (index)
		xyd.SoundManager:get():playSound(xyd.SoundID.TAB)
		self:setComponent(index)

		if index == 3 and not self.rankList then
			xyd.models.guild:reqDiningHallGoldRank()
		end
	end)

	self.tab:setTexts({
		__("ORDER"),
		__("LEV_UP"),
		__("RANK")
	})
	self:updateLev()
	self:updateGetNewOrder()
	self:updateUpgradeOrder()
	self:updateStartOrder()

	self.labelNone.text = __("NO_ORDERS")

	self.res:setInfo({
		tableId = xyd.ItemID.MANA
	})
	self.res:registerItemChange()
	self:updateProgressBar()
	self:updateBuilding()
	self:updateDonateRes()

	self.btnDonate1_label.text = __("DONATE_ONE")
	self.btnDonate10_label.text = __("DONATE_TEN")
end

function GuildDiningHall:setComponent(index)
	for i = 1, 3 do
		self["view" .. i]:SetActive(index == i)
	end
end

function GuildDiningHall:updateGetNewOrder()
	local gSelfInfo = xyd.models.guild.self_info
	self.btnGetOrder_label.text = __("GET_ORDER")
	gSelfInfo.order_time = gSelfInfo.order_time or 0
	local tmp = xyd.getServerTime()
	local tmp2 = tonumber(xyd.tables.miscTable:getVal("guild_order_cd"))

	if tmp >= gSelfInfo.order_time + tmp2 then
		self.btnGetOrder_mask:SetActive(false)
		self.countDown:SetActive(false)
	else
		self.countDown:SetActive(true)
		self.btnGetOrder_mask:SetActive(true)
		self.countDown:setInfo({
			duration = gSelfInfo.order_time + tmp2 - tmp,
			callback = handler(self, self.updateGetNewOrder)
		})
	end
end

function GuildDiningHall:updateUpgradeOrder()
	self.btnUpgradeOrder_label.text = __("GUILD_MEAL_TEXT1")
	self.orderList = xyd.models.guild:getDiningHallOrderList()
	local canUpgrade = false
	local maxLevel = #xyd.tables.guildOrderTable:getIDs() or 0

	if self.orderList then
		for _, order in pairs(self.orderList) do
			if order.order_lv < maxLevel and order.start_time == 0 and self.upgradeLevel < maxLevel then
				canUpgrade = true

				break
			end
		end
	end

	local gInfo = xyd.models.guild.base_info
	local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
	local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

	if funOpenLev <= millLev then
		self.btnUpgradeOrder_lock:SetActive(false)

		local timeStamp = xyd.db.misc:getValue("guild_dininghall_upgrade_btn_unlock_effect" .. xyd.Global.playerID)

		if not timeStamp then
			self:waitForTime(1, function ()
				self.btnUpgradeOrder_effect:SetActive(true)

				local effect = xyd.Spine.new(self.btnUpgradeOrder_effect)

				effect:setInfo("travel_other", function ()
					effect:play("travel_other_04", 1, 1, function ()
						self.btnUpgradeOrder_effect:SetActive(false)
					end)
				end, true)
				xyd.db.misc:setValue({
					value = 1,
					key = "guild_dininghall_upgrade_btn_unlock_effect" .. xyd.Global.playerID
				})
			end)
		end

		if canUpgrade then
			self.btnUpgradeOrder_mask:SetActive(false)
		else
			self.btnUpgradeOrder_mask:SetActive(true)
		end
	else
		self.btnUpgradeOrder_mask:SetActive(true)
		self.btnUpgradeOrder_lock:SetActive(true)
	end
end

function GuildDiningHall:updateStartOrder()
	self.btnStartOrder_label.text = __("GUILD_MEAL_TEXT2")
	self.orderList = xyd.models.guild:getDiningHallOrderList()
	local canStart = false

	if self.orderList then
		for _, order in pairs(self.orderList) do
			if order.start_time == 0 then
				canStart = true

				break
			end
		end
	end

	local gInfo = xyd.models.guild.base_info
	local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
	local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

	if funOpenLev <= millLev then
		self.btnStartOrder_lock:SetActive(false)

		local timeStamp = xyd.db.misc:getValue("guild_dininghall_start_btn_unlock_effect" .. xyd.Global.playerID)

		if not timeStamp then
			self:waitForTime(1, function ()
				self.btnStartOrder_effect:SetActive(true)

				local effect = xyd.Spine.new(self.btnStartOrder_effect)

				effect:setInfo("travel_other", function ()
					effect:play("travel_other_04", 1, 1, function ()
						self.btnStartOrder_effect:SetActive(false)
					end)
				end, true)
				xyd.db.misc:setValue({
					value = 1,
					key = "guild_dininghall_start_btn_unlock_effect" .. xyd.Global.playerID
				})
			end)
		end

		if canStart and (not self.disableItem or self:getDisableItemLength() == 0) then
			self.btnStartOrder_mask:SetActive(false)
		else
			self.btnStartOrder_mask:SetActive(true)
		end
	else
		self.btnStartOrder_mask:SetActive(true)
		self.btnStartOrder_lock:SetActive(true)
	end
end

function GuildDiningHall:updateLev()
	local gInfo = xyd.models.guild.base_info
	local lev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)

	if self.lev ~= lev then
		self.lev = lev

		return true
	else
		return false
	end
end

function GuildDiningHall:updateProgressBar()
	local lev = self.lev

	if self.lev == xyd.tables.guildMillTable:getMaxLev() then
		lev = lev - 1
	end

	local val = 0

	if lev > 1 then
		val = xyd.models.guild.base_info.gold - xyd.tables.guildMillTable:getAllGold(lev)
	else
		val = xyd.models.guild.base_info.gold
	end

	__TRACE(lev, xyd.tables.guildMillTable:getMaxLev(), xyd.tables.guildMillTable:getAllGold(lev), xyd.tables.guildMillTable:getGold(lev + 1))

	self.upProgressbar.value = val / xyd.tables.guildMillTable:getGold(lev + 1)
	self.upProgressbar_label.text = xyd.getRoughDisplayNumber(val) .. "/" .. xyd.getRoughDisplayNumber(xyd.tables.guildMillTable:getGold(lev + 1))
end

function GuildDiningHall:updateBuilding()
	if self.lev == xyd.tables.guildMillTable:getMaxLev() then
		self.finalGroup:SetActive(true)
		self.changeGroup:SetActive(false)
		NGUITools.DestroyChildren(self.finalGroup.transform)

		local go = NGUITools.AddChild(self.finalGroup, self.guild_dininghall_building_item)
		local item = GuildDiningHallBuildingItem.new(go)

		item:setInfo(self.lev)
		self.btnDonate1:SetActive(false)
		self.btnDonate10:SetActive(false)
		self.cost1:SetActive(false)
		self.cost10:SetActive(false)
		self.maxLev:SetActive(true)
		xyd.setUISprite(self.maxLev, nil, "guild_level_max_" .. xyd.Global.lang)
	else
		self.finalGroup:SetActive(false)
		self.changeGroup:SetActive(true)
		NGUITools.DestroyChildren(self.beforeBuilding.transform)
		NGUITools.DestroyChildren(self.afterBuilding.transform)

		local go1 = NGUITools.AddChild(self.beforeBuilding, self.guild_dininghall_building_item)
		local go2 = NGUITools.AddChild(self.afterBuilding, self.guild_dininghall_building_item)
		self.itemBefore = GuildDiningHallBuildingItem.new(go1)
		self.itemAfter = GuildDiningHallBuildingItem.new(go2)

		self.itemBefore:setInfo(self.lev)
		self.itemAfter:setInfo(self.lev + 1)
	end
end

function GuildDiningHall:updateDonateRes()
	local donate = xyd.tables.miscTable:split2Cost("guild_mill_donate", "value", "|#")
	self.labelCostRes1.text = xyd.getRoughDisplayNumber(donate[1][2])
	self.labelCostRes10.text = xyd.getRoughDisplayNumber(donate[2][2])

	if xyd.models.backpack:getMana() < donate[1][2] then
		self.labelCostRes1.color = Color.New2(3422556671.0)
		self.donateState[1] = false
	else
		self.labelCostRes1.color = Color.New2(1432789759)
		self.donateState[1] = true
	end

	if xyd.models.backpack:getMana() < donate[2][2] then
		self.labelCostRes10.color = Color.New2(3422556671.0)
		self.donateState[2] = false
	else
		self.labelCostRes10.color = Color.New2(1432789759)
		self.donateState[2] = true
	end
end

function GuildDiningHall:initOrders()
	NGUITools.DestroyChildren(self.orderGroup.transform)

	if #self.orderList == 0 then
		self.orderNone:SetActive(true)

		self.orderGroup:GetComponent(typeof(UIWidget)).alpha = 0
	else
		for i = 1, #self.orderList do
			local go = NGUITools.AddChild(self.orderGroup, self.guild_dininghall_item)
			local item = GuildDiningHallItem.new(go, self.orderList[i], self)

			table.insert(self.diningHallItems, item)
		end

		self.orderGroup:GetComponent(typeof(UIGrid)):Reposition()
	end

	self.timer_:Start()
end

function GuildDiningHall:willClose()
	BaseWindow.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

function GuildDiningHall:onClickGetOrder()
	xyd.models.guild:reqDiningHallNewOrders()
end

function GuildDiningHall:onClickStartOrder()
	local gInfo = xyd.models.guild.base_info
	local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
	local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

	if millLev < funOpenLev then
		xyd.alert(xyd.AlertType.TIPS, __("GUILD_MEAL_TEXT6"))

		return
	end

	for _, order in pairs(self.orderList) do
		if order.start_time == 0 then
			xyd.models.guild:reqDiningHallStartOrder(order.order_id)
		end
	end
end

function GuildDiningHall:onClickUpgradeOrder()
	local gInfo = xyd.models.guild.base_info
	local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
	local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

	if millLev < funOpenLev then
		xyd.alert(xyd.AlertType.TIPS, __("GUILD_MEAL_TEXT6"))

		return
	end

	xyd.WindowManager.get():openWindow("guild_dininghall_upgrade_window")
end

function GuildDiningHall:showAward(items)
	if not self.effect then
		self.effect = xyd.Spine.new(self.effectGroup)
	end

	local itemData = {}

	for _, item in ipairs(items) do
		local params = {
			item_id = tonumber(item.item_id) or tonumber(item.itemID),
			item_num = tonumber(item.item_num) or tonumber(item.num)
		}

		table.insert(itemData, params)
	end

	if xyd.GuideController.get():isGuideComplete() then
		self.guildMask_:SetActive(true)
		self.effect:setInfo("dingdan", function ()
			self.effect:SetLocalScale(1.04, 1.04, 1)
			self.effect:play("texiao01", 1, 1, function ()
				if tolua.isnull(self.guildMask_) then
					return
				end

				self.guildMask_:SetActive(false)
				self.effect:SetActive(false)
				xyd.WindowManager.get():openWindow("gamble_rewards_window", {
					wnd_type = 2,
					data = itemData
				})
			end)
		end)
	end
end

function GuildDiningHall:onGetOrderList(event)
	self.orderList = xyd.models.guild:getDiningHallOrderList()
	local awards = event.data.awards

	if awards and #awards > 0 then
		self:showAward(awards)
	end

	self.orderNum.text = __("ORDER_NUM", #self.orderList)

	self:initOrders()
	self:updateUpgradeOrder()
	self:updateStartOrder()
end

function GuildDiningHall:onGetNewOrders()
	self.upgradeLevel = 0
	self.orderList = xyd.models.guild:getDiningHallOrderList()
	self.orderNum.text = __("ORDER_NUM", #self.orderList)

	for i = #self.diningHallItems, 1, -1 do
		local item = self.diningHallItems[i]

		if not item.isStart then
			table.remove(self.diningHallItems, i)
			NGUITools.Destroy(item:getGameObject().transform)
		end
	end

	self.orderGroup:SetActive(true)

	local layout = self.orderGroup:GetComponent(typeof(UIGrid))

	for i = 1, #self.orderList do
		if self.orderList[i].start_time == 0 then
			local go = NGUITools.AddChild(self.orderGroup, self.guild_dininghall_item)
			local item = GuildDiningHallItem.new(go, self.orderList[i], self)

			table.insert(self.diningHallItems, item)
			item:tweening()
		end
	end

	layout:Reposition()

	self.orderGroup:GetComponent(typeof(UIWidget)).alpha = 1

	self.orderNone:SetActive(false)
	self:updateGetNewOrder()
	self:updateUpgradeOrder()
	self:updateStartOrder()
end

function GuildDiningHall:updateTime()
	for i = 1, #self.diningHallItems do
		local item = self.diningHallItems[i]

		item:updateTime()
	end
end

function GuildDiningHall:onUpdateOrder(event)
	local order_info = event.data.order_info

	dump(order_info)

	if self.disableItem and self.disableItem[order_info.order_id] and order_info.start_time == 0 then
		if order_info.order_lv == self.upgradeLevel then
			self.disableItem[order_info.order_id] = nil
		end

		if self:getDisableItemLength() == 0 then
			for i = 1, #self.diningHallItems do
				local item = self.diningHallItems[i]

				item:setBtnState(true)
			end
		end
	else
		for i = 1, #self.diningHallItems do
			local item = self.diningHallItems[i]

			dump(item.data.order_id)

			if order_info.order_id == item.data.order_id then
				item:setInfo(order_info)

				if order_info.start_time == 0 then
					item:playUpgradeEffect()
				end

				break
			end
		end
	end

	self:updateUpgradeOrder()
	self:updateStartOrder()
end

function GuildDiningHall:onCompleteOrder(event)
	local data = event.data

	for i = #self.diningHallItems, 1, -1 do
		local item = self.diningHallItems[i]

		if item.data.order_id == data.order_id then
			table.remove(self.diningHallItems, i)
			NGUITools.Destroy(item:getGameObject())
			self:showAward(data.awards)

			break
		end
	end
end

function GuildDiningHall:onGetGoldRank(event)
	local data = event.data
	local player_rank = {
		score = 1,
		player_name = 2,
		time = 7,
		avatar_id = 3,
		player_id = 6,
		lev = 5,
		avatar_frame_id = 4,
		job = 8
	}
	self.rankList = {}

	NGUITools.DestroyChildren(self.groupRank.transform)

	for i = 1, #data.list do
		local rank = {
			rank = i
		}

		for k, _ in pairs(player_rank) do
			rank[k] = data.list[i][k]
		end

		self.rankList[i] = rank
		local go = NGUITools.AddChild(self.groupRank, self.guild_dininghall_rank_item)
		local item = GuildDiningHallRankItem.new(go, self.rankList[i])
	end

	self.groupRank:GetComponent(typeof(UILayout)):Reposition()
end

function GuildDiningHall:registerEvent()
	self:setCloseBtn(self.closeBtn)
	xyd.setDarkenBtnBehavior(self.btnDonate1, self, function ()
		if not self.donateState[1] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

			return
		end

		xyd.models.guild:reqDiningHallDonateGold(1)
	end)
	xyd.setDarkenBtnBehavior(self.btnDonate10, self, function ()
		if not self.donateState[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.MANA)))

			return
		end

		xyd.models.guild:reqDiningHallDonateGold(2)
	end)
	xyd.setDarkenBtnBehavior(self.btnGetOrder, self, self.onClickGetOrder)
	xyd.setDarkenBtnBehavior(self.btnStartOrder, self, self.onClickStartOrder)
	xyd.setDarkenBtnBehavior(self.btnUpgradeOrder, self, self.onClickUpgradeOrder)

	UIEventListener.Get(self.btnStartOrder_mask).onClick = function ()
		local gInfo = xyd.models.guild.base_info
		local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
		local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

		if millLev < funOpenLev then
			xyd.alert(xyd.AlertType.TIPS, __("GUILD_MEAL_TEXT6"))
		end
	end

	UIEventListener.Get(self.btnUpgradeOrder_mask).onClick = function ()
		local gInfo = xyd.models.guild.base_info
		local millLev = xyd.tables.guildMillTable:getIdByGold(gInfo.gold)
		local funOpenLev = tonumber(xyd.tables.miscTable:getVal("guild_quick_order_open"))

		if millLev < funOpenLev then
			xyd.alert(xyd.AlertType.TIPS, __("GUILD_MEAL_TEXT6"))
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_ORDER_LIST, self.onGetOrderList, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_UPGRADE_ORDER, self.onUpdateOrder, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_START_ORDER, self.onUpdateOrder, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_COMPLETE_ORDER, self.onCompleteOrder, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_NEW_ORDERS, self.onGetNewOrders, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_DONATE_GOLD, self.onDonateGold, self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_DININGHALL_GOLD_RANK, self.onGetGoldRank, self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, self.updateDonateRes, self)
end

function GuildDiningHall:onDonateGold()
	if tolua.isnull(self.window_) then
		return
	end

	local isLevUp = self:updateLev()

	self:updateProgressBar()
	self:updateBuilding()
	self:updateDonateRes()

	self.rankList = nil

	if self.lev == xyd.tables.guildMillTable:getMaxLev() then
		return
	elseif isLevUp then
		self.itemBefore:playEffect()
		self.itemAfter:playEffect()
	else
		self.itemBefore:playEffect()
	end

	self:updateUpgradeOrder()
	self:updateStartOrder()
end

function GuildDiningHall:updateUpIcon()
	if xyd.models.activity:isResidentReturnAddTime() then
		self.upIcon:SetActive(xyd.models.activity:isResidentReturnAddTime())

		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.GUILD)

		xyd.setUISpriteAsync(self.upIcon.gameObject:GetComponent(typeof(UISprite)), nil, "common_tips_up_" .. return_multiple, nil, , )
	else
		self.upIcon:SetActive(false)
	end
end

function GuildDiningHall:upgradeAllOrder(upgradeLevel)
	self.disableItem = {}
	self.upgradeLevel = upgradeLevel

	for i = 1, #self.diningHallItems do
		local item = self.diningHallItems[i]

		if item.data.order_lv < upgradeLevel and item.data.start_time == 0 then
			local order_info = item.data
			order_info.order_lv = upgradeLevel

			item:setInfo(order_info)
			item:playUpgradeEffect()
			item:setBtnState(false)

			self.disableItem[order_info.order_id] = true
		end
	end

	self:updateUpgradeOrder()
	self:updateStartOrder()
end

function GuildDiningHall:getDisableItemLength()
	if not self.disableItem then
		return 0
	end

	local count = 0

	for _, __ in pairs(self.disableItem) do
		count = count + 1
	end

	return count
end

function GuildDiningHallItem:ctor(go, data, parent)
	self.parent_ = parent

	GuildDiningHallItem.super.ctor(self, go)

	self.data = data
	self.startsItem_ = {}

	self:getUIComponent()
	self:initUIComponent()
	self:onRegisterEvent()
end

function GuildDiningHallItem:tweening()
	self.go:GetComponent(typeof(UIWidget)).alpha = 0.5

	self.go:GetComponent(typeof(UIWidget)):SetLocalScale(0.5, 0.5, 0.5)

	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(self.go.transform:DOScale(1.1, 0.13))
	sequence:Join(xyd.getTweenAlpha(self.go:GetComponent(typeof(UIWidget)), 1, 0.13))
	sequence:Append(self.go.transform:DOScale(0.97, 0.13))
	sequence:Append(self.go.transform:DOScale(1, 0.16))
	sequence:AppendCallback(function ()
		sequence:Kill(false)
	end)
end

function GuildDiningHallItem:getUIComponent()
	local go = self.go
	self.timeInterval = go:ComponentByName("time/timeInterval", typeof(UILabel))
	self.timeLabel = go:ComponentByName("time/timeLabel", typeof(UILabel))
	self.clockEffect = go:NodeByName("clockEffect").gameObject
	self.imgFood = go:ComponentByName("imgFood", typeof(UISprite))
	self.btnUpgrade = go:NodeByName("btnUpgrade").gameObject
	self.starGroup = go:NodeByName("starGroup").gameObject
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.btn = go:NodeByName("btn").gameObject
	self.btn_mask = self.btn:ComponentByName("mask", typeof(UISprite)).gameObject
	self.progress = go:ComponentByName("progress", typeof(UIProgressBar))
	self.progress_label = self.progress:ComponentByName("label", typeof(UILabel))
end

function GuildDiningHallItem:initUIComponent()
	self:updateTime()

	if xyd.Global.lang == "fr_fr" then
		self.go:NodeByName("time"):X(-20)
	end

	self.timeInterval.text = tostring(xyd.tables.guildOrderTable:getTime(self.data.order_lv) / 3600)
	self.timeLabel.text = __("HOUR")

	xyd.setUISprite(self.imgFood, nil, xyd.tables.guildOrderTable:getPic(self.data.order_lv))

	for i = 1, self.data.order_lv do
		if not self.startsItem_[i] then
			local star = NGUITools.AddChild(self.starGroup, "star_" .. i)
			local sp = star:AddComponent(typeof(UISprite))

			xyd.setUISprite(sp, xyd.Atlas.COMMON_UI, "partner_star_yellow")
			sp:MakePixelPerfect()

			sp.depth = self.starGroup:GetComponent(typeof(UIWidget)).depth + 2
			self.startsItem_[i] = star
		else
			self.startsItem_[i]:SetActive(true)
		end
	end

	if self.data.order_lv < #self.startsItem_ then
		for j = self.data.order_lv, #self.startsItem_ do
			self.startsItem_[j]:SetActive(false)
		end
	end

	self.starGroup:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.awardGroup.transform)

	local awards = xyd.tables.guildOrderTable:getAwards(self.data.order_lv)

	for i = 1, #awards do
		local factor = math.floor((self.data.factor or 10000) / 10000 * 10) / 10
		awards[i].num = math.floor(awards[i].num * factor)

		if awards[i].num > 10000 then
			awards[i].num = awards[i].num + 1
		end
	end

	for i = 1, #awards do
		local item = xyd.getItemIcon({
			noClickSelected = true,
			scale = 0.64,
			uiRoot = self.awardGroup,
			itemID = awards[i].itemID,
			num = awards[i].num,
			labelNumScale = Vector3(1.6, 1.6, 1),
			dragScrollView = self.parent_.orderScroller_
		})
	end

	self.awardGroup:GetComponent(typeof(UILayout)):Reposition()

	local orderTableIds = xyd.tables.guildOrderTable:getIDs()

	if self.data.order_lv ~= orderTableIds[#orderTableIds] and self.data.start_time == 0 then
		self.btnUpgrade:SetActive(true)
	else
		self.btnUpgrade:SetActive(false)
	end

	if self.data.start_time == 0 then
		self.isStart = false
	else
		self.isStart = true
	end
end

function GuildDiningHallItem:setBtnState(flag)
	self.btn_mask:SetActive(not flag)
end

function GuildDiningHallItem:setInfo(data)
	self.data = data

	self:initUIComponent()
end

function GuildDiningHallItem:updateTime()
	local serverTime = xyd.getServerTime()
	local endTime = self.data.start_time + xyd.tables.guildOrderTable:getTime(self.data.order_lv)

	self.btn:SetActive(false)
	self.progress:SetActive(false)

	if self.data.start_time == 0 then
		self.currentState = "start"

		xyd.setUISprite(self.btn:GetComponent(typeof(UISprite)), nil, "white_btn_54_54")
		xyd.setBtnLabel(self.btn, {
			strokeColor = 4294967295.0,
			color = 1012112383,
			stroke = 1,
			text = __("START")
		})
		self.btn:SetActive(true)
	elseif endTime < serverTime then
		self.currentState = "done"

		xyd.setUISprite(self.btn:GetComponent(typeof(UISprite)), nil, "blue_btn_54_54")
		self.btn:SetActive(true)
		xyd.setBtnLabel(self.btn, {
			strokeColor = 1012112383,
			color = 4294967295.0,
			stroke = 1,
			text = __("PUB_MISSION_COMPLETE")
		})
	else
		local max = xyd.tables.guildOrderTable:getTime(self.data.order_lv)

		self.progress:SetActive(true)

		self.progress.value = (serverTime - self.data.start_time) / max
		self.progress_label.text = xyd.secondsToString(endTime - serverTime)
	end
end

function GuildDiningHallItem:onRegisterEvent()
	xyd.setDarkenBtnBehavior(self.btnUpgrade, self, self.onClickUpgrade)
	xyd.setDarkenBtnBehavior(self.btn, self, self.onClickBtn)
end

function GuildDiningHallItem:onClickUpgrade()
	local cost = xyd.tables.guildOrderTable:getUpCost(self.data.order_lv)

	if not cost or xyd.isItemAbsence(cost.itemID, cost.num) then
		return
	end

	local timeStamp = xyd.db.misc:getValue("guild_dining_hall_upgrade_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			type = "guild_dining_hall_upgrade",
			text = __("UPGRADE_ORDER_TIPS", cost.num),
			callback = function (yes)
				xyd.models.guild:reqDiningHallUpgradeOrder(self.data.order_id)
			end
		})
	else
		xyd.models.guild:reqDiningHallUpgradeOrder(self.data.order_id)
	end
end

function GuildDiningHallItem:onClickBtn()
	if self.currentState == "start" then
		xyd.models.guild:reqDiningHallStartOrder(self.data.order_id)
	elseif self.currentState == "done" then
		xyd.models.guild:reqDiningHallCompleteOrder(self.data.order_id)
	end
end

function GuildDiningHallItem:playUpgradeEffect()
	xyd.SoundManager.get():playSound(xyd.SoundID.REFRESH)

	if not self.effect then
		self.effect = xyd.Spine.new(self.imgFood.gameObject)

		self.effect:setInfo("fx_ui_dingdansj", function ()
			self.effect:setRenderTarget(self.imgFood, 1)
			self.effect:play("texiao01", 1, 1, nil, true)
		end)
	else
		self.effect:play("texiao01", 1, 1, nil, true)
	end
end

function GuildDiningHallBuildingItem:ctor(go)
	GuildDiningHallBuildingItem.super.ctor(self, go)
	self:getUIComponent()
	self:initUIComponent()
end

function GuildDiningHallBuildingItem:getUIComponent()
	local go = self.go
	self.lv = go:ComponentByName("lv", typeof(UILabel))
	self.bg01 = go:NodeByName("bg01").gameObject
	self.bg02 = go:NodeByName("bg02").gameObject
	self.buildingPic = go:ComponentByName("buildingPic", typeof(UISprite))
	self.desc1 = go:ComponentByName("desc1", typeof(UILabel))
	self.desc2 = go:ComponentByName("desc2", typeof(UILabel))
	self.effectGroup = go:NodeByName("effectGroup").gameObject
end

function GuildDiningHallBuildingItem:initUIComponent()
end

function GuildDiningHallBuildingItem:setInfo(lev)
	self.lv.text = "Lv." .. tostring(lev)

	xyd.setUISprite(self.buildingPic, nil, xyd.tables.guildMillTable:getPic(lev))

	local factor = math.floor((xyd.tables.guildMillTable:getFactor(lev) - 10000) / 100)
	self.desc1.text = __("MILL_FACTOR", factor)
	self.desc2.text = __("ORDER_NUMS", xyd.tables.guildMillTable:getOrderNum(lev))
end

function GuildDiningHallBuildingItem:playEffect()
	if not self.effect then
		self.effect = xyd.Spine.new(self.effectGroup)

		self.effect:setInfo("fx_ui_stsj", function ()
			self.effect:SetLocalScale(1.2, 1.2, 1)
			self.effect:setRenderTarget(self.buildingPic, 1)
			self.effect:play("texiao01", 1, 1, nil, true)
		end, true)
	else
		self.effect:play("texiao01", 1, 1, nil, true)
	end
end

function GuildDiningHallRankItem:ctor(go, data)
	GuildDiningHallRankItem.super.ctor(self, go)

	self.data = data

	self:getUIComponent()
	self:initUIComponent()
end

function GuildDiningHallRankItem:getUIComponent()
	local go = self.go
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIcon = go:NodeByName("pIcon").gameObject
	self.pIcon = require("app.components.PlayerIcon").new(pIcon)
	self.lv = go:ComponentByName("lv", typeof(UILabel))
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.title = go:ComponentByName("title", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
end

function GuildDiningHallRankItem:initUIComponent()
	local params = self.data

	self.pIcon:setInfo({
		avatarID = params.avatar_id
	})
	self.pIcon:SetLocalScale(0.64, 0.64, 1)

	self.playerName.text = params.player_name

	if params.rank > 3 then
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = params.rank
	else
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
		xyd.setUISprite(self.imgRank, nil, "rank_icon0" .. tostring(params.rank))
	end

	self.lv.text = params.lev
	self.labelPoint.text = __("DONATE")
	self.point.text = xyd.getRoughDisplayNumber(tonumber(params.score))
	self.title.text = __("GUILD_JOB" .. tostring(params.job))
end

return GuildDiningHall
