local ActivityChildhoodShop = class("ActivityChildhoodShop", import(".ActivityContent"))
local ActivityChildhoodShopItem = class("ActivityChildhoodShopItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityChildhoodShop:ctor(parentGO, params)
	ActivityChildhoodShop.super.ctor(self, parentGO, params)

	if self.activityData.detail.items and #self.activityData.detail.items > 0 then
		xyd.WindowManager:get():openWindow("activity_childhood_shop_select_award_window")
	end
end

function ActivityChildhoodShop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_childhood_shop"
end

function ActivityChildhoodShop:resizeToParent()
	ActivityChildhoodShop.super.resizeToParent(self)
	self:resizePosY(self.bg, 14, 0)
	self:resizePosY(self.topBg, 14, 0)
	self:resizePosY(self.logo, 0, -14)
	self:resizePosY(self.bottomBg, -877, -937)
	self:resizePosY(self.exchangeInterface, -372, -402)
	self:resizePosY(self.specialItem, -741, -791)
	self:resizePosY(self.gachaBtn, -742, -792)
	self:resizePosY(self.infExchangeBtn, -734, -784)

	for i = 1, 3 do
		self:resizePosY(self["infExchangeItem" .. i], -265, -285)
	end

	for i = 4, 6 do
		self:resizePosY(self["infExchangeItem" .. i], -490, -520)
	end

	if xyd.Global.lang == "de_de" then
		self.infExchangeBtnLabel.fontSize = 22
		self.gachaBtnLabel.fontSize = 22
	end
end

function ActivityChildhoodShop:initUI()
	self:getUIComponent()
	ActivityChildhoodShop.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityChildhoodShop:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UITexture))
	self.shopBg = self.go:NodeByName("shopBg").gameObject
	self.topBg = self.shopBg:NodeByName("top").gameObject
	self.bottomBg = self.shopBg:NodeByName("bottom").gameObject
	self.logo = self.shopBg:ComponentByName("logo", typeof(UISprite))
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.gachaBtn = self.go:NodeByName("gachaBtn").gameObject
	self.gachaBtnLabel = self.gachaBtn:ComponentByName("label", typeof(UILabel))
	self.gachaBtnRedMark = self.gachaBtn:NodeByName("redMark").gameObject
	self.infExchangeBtn = self.go:NodeByName("infExchangeBtn").gameObject
	self.infExchangeBtnSprite = self.infExchangeBtn:GetComponent(typeof(UISprite))
	self.infExchangeBtnLabel = self.infExchangeBtn:ComponentByName("label", typeof(UILabel))

	for i = 1, 2 do
		self["resItem" .. i] = self.go:NodeByName("resItem" .. i).gameObject
		self["resNum" .. i] = self["resItem" .. i]:ComponentByName("num", typeof(UILabel))
		self["resBtn" .. i] = self["resItem" .. i]:NodeByName("btn").gameObject
	end

	self.specialItem = self.go:NodeByName("specialItem").gameObject
	self.partnerModel = self.specialItem:ComponentByName("partnerModel", typeof(UITexture))
	self.specialItemLabel = self.specialItem:ComponentByName("label", typeof(UILabel))
	self.specialItemAwards = self.specialItem:NodeByName("awardGroup").gameObject
	self.specialItemBtn = self.specialItem:NodeByName("btn").gameObject
	self.specialItemBtnIcon = self.specialItemBtn:ComponentByName("icon", typeof(UISprite))
	self.specialItemBtnLabel = self.specialItemBtn:ComponentByName("label", typeof(UILabel))
	self.specialItemBtnRedMark = self.specialItem:NodeByName("redMark").gameObject
	self.exchangeInterface = self.go:NodeByName("exchangeInterface").gameObject

	for i = 1, 4 do
		self["exchangeItem" .. i] = self.exchangeInterface:NodeByName("item" .. i).gameObject
		self["exchangeItemNameLabel" .. i] = self["exchangeItem" .. i]:ComponentByName("label", typeof(UILabel))
		self["exchangeItemProgressBar" .. i] = self["exchangeItem" .. i]:ComponentByName("progressBar", typeof(UIProgressBar))
		self["exchangeItemProgressLabel" .. i] = self["exchangeItemProgressBar" .. i]:ComponentByName("progressLabel", typeof(UILabel))
		self["exchangeItemAward" .. i] = self["exchangeItem" .. i]:NodeByName("award").gameObject
		self["exchangeItemBtn" .. i] = self["exchangeItem" .. i]:NodeByName("btn").gameObject
		self["exchangeItemBtnRedMark" .. i] = self["exchangeItemBtn" .. i]:NodeByName("redMark").gameObject
	end

	self.infExchangeInterface = self.go:NodeByName("infExchangeInterface").gameObject

	for i = 1, 6 do
		self["infExchangeItem" .. i] = self.infExchangeInterface:NodeByName("item" .. i).gameObject
		self["infExchangeItemAward" .. i] = self["infExchangeItem" .. i]:NodeByName("award").gameObject
		self["infExchangeItemIcon" .. i] = self["infExchangeItem" .. i]:ComponentByName("icon", typeof(UISprite))
		self["infExchangeItemLimitLabel" .. i] = self["infExchangeItem" .. i]:ComponentByName("limitLabel", typeof(UILabel))
		self["infExchangeItemCostLabel" .. i] = self["infExchangeItem" .. i]:ComponentByName("costLabel", typeof(UILabel))
	end
end

function ActivityChildhoodShop:initUIComponent()
	if self:checkAllExchangeLineComplete() then
		self.curInterface = "infExchange"
		self.finishExchange = true
	else
		self.curInterface = "exchange"
		self.finishExchange = false
	end

	xyd.setUISpriteAsync(self.logo, nil, "childhood_shop_logo_" .. xyd.Global.lang, nil, , true)

	self.gachaBtnLabel.text = __("ACTIVITY_CHILDREN_SHOP_BUTTON01")

	self:updateResItem()
	self:updateSpecialItem(true)
	self:updateInterface(true)
	self:updateInfExchangeBtn()
	self:updateRed()
end

function ActivityChildhoodShop:checkAllExchangeLineComplete()
	local ids = xyd.tables.activityChildrenShopTable:getIDs()

	for i = 1, #ids do
		local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

		if type == 1 and self.activityData.detail.buy_times[ids[i]] == 0 then
			return false
		end
	end

	return true
end

function ActivityChildhoodShop:updateResItem()
	self.resNum1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_CANDY)
	self.resNum2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_BALLOON)
end

function ActivityChildhoodShop:updateSpecialItem(isInit)
	if isInit then
		self.specialExchangeIcons = {}
		self.specialItemLabel.text = __("ACTIVITY_CHILDREN_SHOP_TEXT01")
		local ids = xyd.tables.activityChildrenShopTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

			if type == 2 then
				self.specialExchangeID = ids[i]
				self.specialExchangeCost = xyd.tables.activityChildrenShopTable:getCost(ids[i])
				local awards = xyd.tables.activityChildrenShopTable:getAward(ids[i])

				for _, award in ipairs(awards) do
					local icon = xyd.getItemIcon({
						show_has_num = true,
						notShowGetWayBtn = true,
						scale = 0.5925925925925926,
						uiRoot = self.specialItemAwards,
						itemID = award[1],
						num = award[2],
						wndType = xyd.ItemTipsWndType.ACTIVITY
					})

					table.insert(self.specialExchangeIcons, icon)
				end

				xyd.setUISpriteAsync(self.specialItemBtnIcon, nil, "icon_" .. self.specialExchangeCost[1])

				self.specialItemBtnLabel.text = self.specialExchangeCost[2]
			end
		end
	end

	local limitTime = xyd.tables.activityChildrenShopTable:getLimit(self.specialExchangeID)

	if self:checkAllExchangeLineComplete() and self.activityData.detail.buy_times[self.specialExchangeID] < limitTime then
		xyd.applyChildrenOrigin(self.specialItemBtn.gameObject)

		for _, icon in ipairs(self.specialExchangeIcons) do
			icon:setEffect(true, "fx_ui_bp_available")
		end
	else
		xyd.applyChildrenGrey(self.specialItemBtn.gameObject)

		for _, icon in ipairs(self.specialExchangeIcons) do
			icon:setEffect(false)
		end
	end

	if limitTime <= self.activityData.detail.buy_times[self.specialExchangeID] then
		self.specialItemBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		for _, icon in ipairs(self.specialExchangeIcons) do
			icon:setChoose(true)
		end
	end
end

function ActivityChildhoodShop:updateInterface(isInit)
	if isInit then
		local ids = xyd.tables.activityChildrenShopTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

			if type == 1 then
				if not self.lastIDofEachLine then
					self.lastIDofEachLine = {}
				end

				local line = xyd.tables.activityChildrenShopTable:getLine(ids[i])
				self.lastIDofEachLine[line] = ids[i]
			end

			if type == 3 then
				if not self.infExchangeInfos then
					self.infExchangeInfos = {}
				end

				table.insert(self.infExchangeInfos, {
					id = ids[i],
					awards = xyd.tables.activityChildrenShopTable:getAward(ids[i]),
					cost = xyd.tables.activityChildrenShopTable:getCost(ids[i]),
					limit = xyd.tables.activityChildrenShopTable:getLimit(ids[i])
				})
			end
		end

		for i = 1, 4 do
			local awards = xyd.tables.activityChildrenShopTable:getAward(self.lastIDofEachLine[i])
			local award = awards[1]
			local icon = xyd.getItemIcon({
				show_has_num = true,
				notShowGetWayBtn = true,
				scale = 0.6944444444444444,
				uiRoot = self["exchangeItemAward" .. i],
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			if not self.exchangeItemIcons then
				self.exchangeItemIcons = {}
			end

			table.insert(self.exchangeItemIcons, icon)
		end

		self.infExchangeIcons = {}

		for i, info in ipairs(self.infExchangeInfos) do
			self.infExchangeIcons[i] = {}

			for _, award in ipairs(info.awards) do
				self.infExchangeIcons[i][_] = xyd.getItemIcon({
					show_has_num = true,
					notShowGetWayBtn = true,
					scale = 0.9074074074074074,
					uiRoot = self["infExchangeItemAward" .. i],
					itemID = award[1],
					num = award[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY
				})
			end

			xyd.setUISpriteAsync(self["infExchangeItemIcon" .. i], nil, "icon_" .. info.cost[1])

			self["infExchangeItemCostLabel" .. i].text = info.cost[2]
		end

		self.partnerEffect = xyd.Spine.new(self.partnerModel.gameObject)

		self.partnerEffect:setInfo("yinyue_pifu05", function ()
			self.partnerEffect:play("idle", 0)
		end)
	end

	if self.curInterface == "exchange" then
		self.exchangeInterface:SetActive(true)
		self.infExchangeInterface:SetActive(false)
		self.partnerModel:SetActive(true)

		self.totalNumofEachLine = {}
		self.completeNumofEachLine = {}
		local ids = xyd.tables.activityChildrenShopTable:getIDs()

		for i = 1, #ids do
			local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

			if type == 1 then
				local line = xyd.tables.activityChildrenShopTable:getLine(ids[i])

				if not self.totalNumofEachLine[line] then
					self.totalNumofEachLine[line] = 0
				end

				self.totalNumofEachLine[line] = self.totalNumofEachLine[line] + 1

				if not self.completeNumofEachLine[line] then
					self.completeNumofEachLine[line] = 0
				end

				if self.activityData.detail.buy_times[ids[i]] > 0 then
					self.completeNumofEachLine[line] = self.completeNumofEachLine[line] + 1
				end
			end
		end

		for i = 1, 4 do
			self["exchangeItemNameLabel" .. i].text = __("ACTIVITY_CHILDREN_SHOP_TEXT02", __("ACTIVITY_CHILDREN_SHOP_TEXT0" .. i + 2))
			self["exchangeItemProgressBar" .. i].value = self.completeNumofEachLine[i] / self.totalNumofEachLine[i]
			self["exchangeItemProgressLabel" .. i].text = self.completeNumofEachLine[i] .. "/" .. self.totalNumofEachLine[i]

			if self.completeNumofEachLine[i] == self.totalNumofEachLine[i] then
				self.exchangeItemIcons[i]:setChoose(true)
			end
		end
	else
		self.exchangeInterface:SetActive(false)
		self.infExchangeInterface:SetActive(true)
		self.partnerModel:SetActive(false)

		for i, info in ipairs(self.infExchangeInfos) do
			self["infExchangeItemLimitLabel" .. i].text = __("LIMIT_BUY", info.limit - self.activityData.detail.buy_times[info.id])

			if info.limit <= self.activityData.detail.buy_times[info.id] then
				for _, icon in ipairs(self.infExchangeIcons[i]) do
					icon:setChoose(true)
				end
			end
		end
	end
end

function ActivityChildhoodShop:updateInfExchangeBtn()
	if self:checkAllExchangeLineComplete() then
		self.infExchangeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

		self.infExchangeBtnLabel:SetActive(true)

		if self.curInterface == "infExchange" then
			xyd.setUISpriteAsync(self.infExchangeBtnSprite, nil, "childhood_shop_back_btn")

			self.infExchangeBtnLabel.text = __("ACTIVITY_CHILDREN_SHOP_BUTTON02")
		else
			xyd.setUISpriteAsync(self.infExchangeBtnSprite, nil, "childhood_shop_inf_exchange_btn")

			self.infExchangeBtnLabel.text = __("ACTIVITY_CHILDREN_SHOP_BUTTON03")
		end
	else
		self.infExchangeBtn:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		self.infExchangeBtnLabel:SetActive(false)
		xyd.setUISpriteAsync(self.infExchangeBtnSprite, nil, "childhood_shop_inactive_btn")
	end
end

function ActivityChildhoodShop:updateRed()
	self.activityData:updateRedMark()

	if self:checkAllExchangeLineComplete() and self.activityData.detail.buy_times[self.specialExchangeID] == 0 and self.specialExchangeCost[2] <= xyd.models.backpack:getItemNumByID(self.specialExchangeCost[1]) then
		self.specialItemBtnRedMark:SetActive(true)
	else
		self.specialItemBtnRedMark:SetActive(false)
	end

	local gachaCost = xyd.tables.miscTable:split2Cost("activity_children_gamble_cost", "value", "#")

	if gachaCost[2] <= xyd.models.backpack:getItemNumByID(gachaCost[1]) then
		self.gachaBtnRedMark:SetActive(true)
	else
		self.gachaBtnRedMark:SetActive(false)
	end

	local ids = xyd.tables.activityChildrenShopTable:getIDs()

	for i = 1, 4 do
		self["exchangeItemBtnRedMark" .. i]:SetActive(false)

		local condition = xyd.tables.activityChildrenShopTable:getCondition(self.lastIDofEachLine[i])
		local cost = xyd.tables.activityChildrenShopTable:getCost(self.lastIDofEachLine[i])

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.activityData.detail.buy_times[self.lastIDofEachLine[i]] == 0 and self.activityData.detail.buy_times[condition] ~= 0 then
			self["exchangeItemBtnRedMark" .. i]:SetActive(true)
		else
			local timeStamp = xyd.db.misc:getValue("activity_childhood_shop_exchange_line_view_time" .. i)

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
				for _, id in ipairs(ids) do
					local line = xyd.tables.activityChildrenShopTable:getLine(id)

					if line == i then
						local condition = tonumber(xyd.tables.activityChildrenShopTable:getCondition(id))
						local cost = xyd.tables.activityChildrenShopTable:getCost(id)

						if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.activityData.detail.buy_times[id] == 0 and (condition ~= 0 and self.activityData.detail.buy_times[condition] ~= 0 or condition == 0) then
							self["exchangeItemBtnRedMark" .. i]:SetActive(true)
						end
					end
				end
			end
		end
	end
end

function ActivityChildhoodShop:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateResItem()
		self:updateRed()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function ()
		if not self.finishExchange and self:checkAllExchangeLineComplete() then
			self.finishExchange = true

			xyd.alertConfirm(__("ACTIVITY_CHILDREN_SHOP_TIPS05"), nil, __("ACTIVITY_CHILDREN_SHOP_BUTTON04"))

			local win = xyd.WindowManager:get():getWindow("activity_childhood_shop_exchange_window")

			if win then
				win:close()
			end

			self.curInterface = "infExchange"
		end

		self:updateInfExchangeBtn()
		self:updateInterface()
		self:updateSpecialItem()
		self:updateRed()
	end)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_CHILDREN_SHOP_HELP"
		})
	end

	UIEventListener.Get(self.gachaBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_childhood_shop_gacha_window")
	end

	UIEventListener.Get(self.infExchangeBtn).onClick = function ()
		self.curInterface = self.curInterface == "infExchange" and "exchange" or "infExchange"

		self:updateInterface()
		self:updateInfExchangeBtn()
	end

	UIEventListener.Get(self.specialItemBtn).onClick = function ()
		if not self:checkAllExchangeLineComplete() then
			xyd.alertTips(__("ACTIVITY_CHILDREN_SHOP_TIPS01"))

			return
		end

		if xyd.models.backpack:getItemNumByID(self.specialExchangeCost[1]) < self.specialExchangeCost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.specialExchangeCost[1])))

			return
		end

		xyd.alertYesNo(__("CONFIRM_CHANGE"), function (yes)
			if yes then
				self.activityData:sendReq({
					num = 1,
					type = 1,
					award_id = self.specialExchangeID
				})
			end
		end)
	end

	UIEventListener.Get(self.resBtn1).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.CHILDHOOD_SHOP_CANDY
		})
	end

	UIEventListener.Get(self.resBtn2).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_item_getway_window", {
			itemID = xyd.ItemID.CHILDHOOD_SHOP_BALLOON,
			activityData = self.activityData,
			openItemBuyWnd = function ()
				local limitTime = xyd.tables.miscTable:getNumber("activity_children_buy_limit", "value")
				local maxNumCanBuy = limitTime - self.activityData.detail.buy

				xyd.WindowManager.get():openWindow("item_buy_window", {
					item_no_click = false,
					cost = xyd.tables.miscTable:split2Cost("activity_children_buy_cost", "value", "#"),
					max_num = maxNumCanBuy,
					itemParams = {
						num = 1,
						itemID = xyd.ItemID.CHILDHOOD_SHOP_BALLOON
					},
					buyCallback = function (num)
						if maxNumCanBuy <= 0 then
							xyd.showToast(__("FULL_BUY_SLOT_TIME"))

							return
						end

						self.activityData:sendReq({
							type = 3,
							num = num
						})
					end,
					limitText = __("BUY_GIFTBAG_LIMIT", self.activityData.detail.buy .. "/" .. limitTime)
				})
			end
		})
	end

	for i = 1, 4 do
		UIEventListener.Get(self["exchangeItemBtn" .. i]).onClick = function ()
			xyd.WindowManager:get():openWindow("activity_childhood_shop_exchange_window", {
				line = i
			})
			self:updateRed()
		end
	end

	for i = 1, 6 do
		UIEventListener.Get(self["infExchangeItem" .. i]).onClick = function ()
			local id = self.infExchangeInfos[i].id
			local cost = self.infExchangeInfos[i].cost
			local limit = self.infExchangeInfos[i].limit
			local award = xyd.tables.activityChildrenShopTable:getAward(id)[1]

			if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

				return
			end

			if limit <= self.activityData.detail.buy_times[id] then
				xyd.alertTips(__("ACTIVITY_CHILDREN_SHOP_TIPS03"))

				return
			end

			local params = {
				notEnoughKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_NOT_ENOUGH",
				hasMaxMin = true,
				titleKey = "MID_AUTUMN_ACTIVITY_EXCHANGE_TITLE",
				buyType = award[1],
				buyNum = award[2],
				costType = cost[1],
				costNum = cost[2],
				purchaseCallback = function (_, num)
					self.activityData:sendReq({
						type = 1,
						award_id = id,
						num = num
					})
				end,
				limitNum = limit - self.activityData.detail.buy_times[id],
				eventType = xyd.event.GET_ACTIVITY_AWARD
			}

			xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
		end
	end
end

return ActivityChildhoodShop
