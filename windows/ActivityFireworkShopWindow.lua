local ActivityFireworkShopWindow = class("ActivityFireworkShopWindow", import(".BaseWindow"))
local FireworkShopItem = class("FireworkShopItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")
local ResItem = import("app.components.ResItem")
local json = require("cjson")
local MAX_NUM = 4

function ActivityFireworkShopWindow:ctor(name, params)
	ActivityFireworkShopWindow.super.ctor(self, name, params)

	self.activityData = params.activityData
	self.localCilckNav = {}
	local clickNavEndTime = xyd.db.misc:getValue("activity_firework_shop_click_nav_EndTime")
	clickNavEndTime = clickNavEndTime or self.activityData:getEndTime()

	for i = 1, MAX_NUM do
		if i == 1 then
			table.insert(self.localCilckNav, 1)
		else
			local clickNav = xyd.db.misc:getValue("activity_firework_shop_click_nav" .. i)

			if clickNavEndTime and tonumber(clickNavEndTime) < self.activityData:getEndTime() then
				clickNav = 0

				xyd.db.misc:setValue({
					value = 0,
					key = "activity_firework_shop_click_nav" .. i
				})
			end

			if clickNav then
				table.insert(self.localCilckNav, tonumber(clickNav))
			else
				table.insert(self.localCilckNav, 0)
			end
		end
	end

	if tonumber(clickNavEndTime) < self.activityData:getEndTime() then
		xyd.db.misc:setValue({
			key = "activity_firework_shop_click_nav_EndTime",
			value = self.activityData:getEndTime()
		})
	end
end

function ActivityFireworkShopWindow:initWindow()
	self:getUIComponent()
	ActivityFireworkShopWindow.super.initWindow(self)
	self:registerEvent()
	self:layout()
end

function ActivityFireworkShopWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.titleGroup = self.groupAction:NodeByName("titleGroup").gameObject
	self.labelWinTitle = self.titleGroup:ComponentByName("labelWinTitle", typeof(UILabel))
	self.helpBtn = self.titleGroup:NodeByName("helpBtn").gameObject
	self.closeBtn = self.titleGroup:NodeByName("closeBtn").gameObject
	self.upCon = self.groupAction:NodeByName("upCon").gameObject
	self.yetCon = self.upCon:NodeByName("yetCon").gameObject
	self.yetConBg = self.yetCon:ComponentByName("yetConBg", typeof(UISprite))
	self.yetLabelText = self.yetCon:ComponentByName("yetLabelText", typeof(UILabel))
	self.yetLabelNum = self.yetCon:ComponentByName("yetLabelNum", typeof(UILabel))
	self.explainText = self.upCon:ComponentByName("explainText", typeof(UILabel))
	self.topItemsNode = self.groupAction:NodeByName("topItemsNode").gameObject
	self.effectNode = self.topItemsNode:ComponentByName("effectNode", typeof(UITexture))
	self.timeLabel = self.topItemsNode:ComponentByName("timeLabel", typeof(UILabel))
	self.resNode1 = self.topItemsNode:NodeByName("resNode1").gameObject
	self.resNode2 = self.topItemsNode:NodeByName("resNode2").gameObject
	self.navBtns = self.topItemsNode:NodeByName("navBtns").gameObject
	self.navBtnsUILayout = self.topItemsNode:ComponentByName("navBtns", typeof(UILayout))

	for i = 1, MAX_NUM do
		self["tab_" .. i] = self.navBtns:NodeByName("tab_" .. i).gameObject
		self["unchosen" .. i] = self["tab_" .. i]:ComponentByName("unchosen", typeof(UISprite))
		self["chosen" .. i] = self["tab_" .. i]:ComponentByName("chosen", typeof(UISprite))
		self["label" .. i] = self["tab_" .. i]:ComponentByName("label", typeof(UILabel))
		self["redPoint" .. i] = self["tab_" .. i]:ComponentByName("redPoint", typeof(UISprite))
		self["lockCon" .. i] = self["tab_" .. i]:NodeByName("lockCon").gameObject
		self["lockConUILayout" .. i] = self["tab_" .. i]:ComponentByName("lockCon", typeof(UILayout))
		self["lockImg" .. i] = self["lockCon" .. i]:ComponentByName("lockImg", typeof(UISprite))
		self["lockLabel" .. i] = self["lockCon" .. i]:ComponentByName("lockLabel", typeof(UILabel))
	end

	self.activity_firework_shop_item = self.groupAction:NodeByName("activity_firework_shop_item").gameObject
	self.scrollView = self.groupAction:NodeByName("scrollView").gameObject
	self.scrollViewUIScrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.content = self.scrollView:NodeByName("content").gameObject
	self.contentUIWrapContent = self.scrollView:ComponentByName("content", typeof(UIWrapContent))
	self.wrapContent_ = FixedMultiWrapContent.new(self.scrollViewUIScrollView, self.contentUIWrapContent, self.activity_firework_shop_item, FireworkShopItem, self)
end

function ActivityFireworkShopWindow:layout()
	self.labelWinTitle.text = __("FIREWORK_TEXT02")
	self.yetLabelText.text = __("FIREWORK_TEXT01")
	self.yetLabelNum.text = tostring(self.activityData.detail.sta_cost)
	self.explainText.text = __("FIREWORK_TEXT04")

	self:initNav()
	self:initTime()

	self.resItem2 = ResItem.new(self.resNode2)

	self.resItem2:setInfo({
		notSmall = false,
		hideBg = true,
		tableId = xyd.ItemID.FIRE_MOMENT
	})
end

function ActivityFireworkShopWindow:initTime()
	self.clockEffect_ = xyd.Spine.new(self.effectNode.gameObject)

	self.clockEffect_:setInfo("fx_ui_shizhong", function ()
		self.clockEffect_:play("texiao1", 0)
	end)

	self.timeLabelCount = import("app.components.CountDown").new(self.timeLabel)
	local leftTime = self.activityData:getEndTime() - xyd.getServerTime()

	if leftTime > 0 then
		self.timeLabelCount:setInfo({
			duration = leftTime,
			callback = function ()
				self.timeLabel.text = "00:00:00"
			end
		})
	else
		self.timeLabel.text = "00:00:00"
	end
end

function ActivityFireworkShopWindow:initNav()
	local index = MAX_NUM
	local labelText = {}
	self.tab = CommonTabBar.new(self.navBtns.gameObject, index, function (index)
		self:updateNav(index)
	end)

	self.tab:setTabActive(1, true, false)

	for i = 1, MAX_NUM do
		local num = xyd.tables.activityFireworkShopRankTable:getPoint(i)

		table.insert(labelText, __("FIREWORK_TEXT07", i))

		self["lockLabel" .. i].text = __("FIREWORK_TEXT05", num)
	end

	self.tab:setTexts(labelText)
	self.tab:setTabActive(1, true, false)
	self:updateNavShow()
end

function ActivityFireworkShopWindow:registerEvent()
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "FIREWORK_TEXT08"
		})
	end)

	for i = 1, MAX_NUM do
		UIEventListener.Get(self["lockCon" .. i].gameObject).onClick = handler(self, function ()
			xyd.alertTips(__("FIREWORK_TEXT06", xyd.tables.activityFireworkShopRankTable:getPoint(i)))
		end)
	end

	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		if self.resItem2 then
			self.resItem2:refresh()
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityFireworkShopWindow:updateNav(index)
	if self["redPoint" .. index].gameObject.activeSelf and self.localCilckNav[index] == 0 then
		self["redPoint" .. index].gameObject:SetActive(false)
		xyd.db.misc:setValue({
			value = 1,
			key = "activity_firework_shop_click_nav" .. index
		})

		self.localCilckNav[index] = 1
	end

	self:updateInfos(index)
end

function ActivityFireworkShopWindow:updateInfos(index)
	local award = xyd.tables.activityFireworkShopTable:getRanksAward()[index]

	self.wrapContent_:setInfos(award, {})
	self.scrollViewUIScrollView:ResetPosition()
end

function ActivityFireworkShopWindow:getShopInfo()
	return self.activityData.detail.buy_times
end

function ActivityFireworkShopWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_FIREWORK then
		return
	end

	local data = xyd.decodeProtoBuf(event.data)
	local info = json.decode(data.detail)

	if info.award_type == xyd.FireWorkAwardType.SHOP then
		for i, item in pairs(self.wrapContent_:getItems()) do
			if tonumber(item:getId()) == tonumber(info.award_id) then
				item:refresh()

				break
			end
		end

		self:updateNavShow()

		self.yetLabelNum.text = tostring(self.activityData.detail.sta_cost)
	end
end

function ActivityFireworkShopWindow:updateNavShow()
	local costNum = self.activityData.detail.sta_cost

	for i = 1, MAX_NUM do
		local num = xyd.tables.activityFireworkShopRankTable:getPoint(i)
		local unChosenImg = ""

		if costNum < num then
			self["lockCon" .. i].gameObject:SetActive(true)
			self["lockConUILayout" .. i]:Reposition()
			self["label" .. i].gameObject:SetActive(false)

			if i == 1 then
				unChosenImg = "nav_btn_grey_left"
			elseif i == MAX_NUM then
				unChosenImg = "nav_btn_grey_right"
			else
				unChosenImg = "nav_btn_grey_mid"
			end
		else
			if self.localCilckNav[i] == 0 then
				self["redPoint" .. i].gameObject:SetActive(true)
			end

			self["lockCon" .. i].gameObject:SetActive(false)
			self["label" .. i].gameObject:SetActive(true)

			if i == 1 then
				unChosenImg = "nav_btn_white_left"
			elseif i == MAX_NUM then
				unChosenImg = "nav_btn_white_right"
			else
				unChosenImg = "nav_btn_white_mid"
			end
		end

		xyd.setUISpriteAsync(self["unchosen" .. i], nil, unChosenImg)
	end
end

function FireworkShopItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	FireworkShopItem.super.ctor(self, go)
end

function FireworkShopItem:initUI()
	self:getUIComponent()
	self:register()

	self.has_buy_words.text = __("ALREADY_BUY")
end

function FireworkShopItem:getUIComponent()
	self.mainNode = self.go:NodeByName("mainNode").gameObject
	self.iconNode = self.mainNode:NodeByName("iconNode").gameObject
	self.name_text = self.mainNode:ComponentByName("name_text", typeof(UILabel))
	self.res_text = self.mainNode:ComponentByName("res_text", typeof(UILabel))
	self.res_icon = self.mainNode:ComponentByName("res_icon", typeof(UISprite))
	self.shadow = self.go:ComponentByName("shadow", typeof(UISprite))
	self.shadowUIWidget = self.go:ComponentByName("shadow", typeof(UIWidget))
	self.buyNode = self.go:ComponentByName("buyNode", typeof(UISprite))
	self.has_buy_words = self.buyNode:ComponentByName("has_buy_words", typeof(UILabel))
end

function FireworkShopItem:update(index, realIndex, info)
	if not info then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	self.id = info
	local award = xyd.tables.activityFireworkShopTable:getAward(self.id)
	local params = {
		isAddUIDragScrollView = true,
		isShowSelected = false,
		uiRoot = self.iconNode,
		itemID = award[1],
		avatar_frame_id = award[1],
		num = award[2]
	}

	if not self.icon then
		self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
	else
		self.icon:setInfo(params)
	end

	self.shadowUIWidget.depth = 50
	local cost = xyd.tables.activityFireworkShopTable:getCost(self.id)
	self.res_text.text = tostring(cost[2])

	xyd.setUISpriteAsync(self.res_icon, nil, xyd.tables.itemTable:getIcon(cost[1]))
	self:refresh()

	local shopRank = xyd.tables.activityFireworkShopTable:getShopRank(self.id)

	if self.parent["lockCon" .. shopRank].gameObject.activeSelf then
		self.shadow.gameObject:SetActive(true)
		self.buyNode.gameObject:SetActive(false)

		self.shadowUIWidget.depth = 20
	end
end

function FireworkShopItem:getId()
	return self.id
end

function FireworkShopItem:refresh()
	local hasNum = self.parent:getShopInfo()[self.id]
	local allNum = xyd.tables.activityFireworkShopTable:getLimit(self.id)
	local limitText = hasNum .. "/" .. allNum
	self.name_text.text = __("BUY_GIFTBAG_LIMIT", limitText)

	if allNum <= hasNum then
		self.buyNode.gameObject:SetActive(true)
		self.shadow.gameObject:SetActive(true)
	else
		self.buyNode.gameObject:SetActive(false)
		self.shadow.gameObject:SetActive(false)
	end
end

function FireworkShopItem:register()
	UIEventListener.Get(self.mainNode.gameObject).onClick = function ()
		local cost = xyd.tables.activityFireworkShopTable:getCost(self.id)

		if self.parent.activityData:getEndTime() <= xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		else
			local hasNum = self.parent:getShopInfo()[self.id]
			local allNum = xyd.tables.activityFireworkShopTable:getLimit(self.id)
			local max_num = math.min(allNum - hasNum, math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]))
			local award = xyd.tables.activityFireworkShopTable:getAward(self.id)

			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = false,
				item_no_click = false,
				cost = cost,
				max_num = max_num,
				itemParams = {
					itemID = award[1],
					num = award[2]
				},
				buyCallback = function (num)
					if self.parent.activityData:getEndTime() <= xyd.getServerTime() then
						xyd.alertTips(__("ACTIVITY_END_YET"))

						return
					end

					local params = json.encode({
						award_type = xyd.FireWorkAwardType.SHOP,
						award_id = self.id,
						num = num
					})

					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_FIREWORK, params)
				end,
				maxCallback = function ()
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			})
		end
	end

	UIEventListener.Get(self.shadow.gameObject).onClick = function ()
		local shopRank = xyd.tables.activityFireworkShopTable:getShopRank(self.id)

		if self.parent["lockCon" .. shopRank].gameObject.activeSelf then
			xyd.alertTips(__("FIREWORK_TEXT06", xyd.tables.activityFireworkShopRankTable:getPoint(shopRank)))
		end
	end
end

return ActivityFireworkShopWindow
