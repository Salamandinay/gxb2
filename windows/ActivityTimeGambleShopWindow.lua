local ActivityTimeGambleShopWindow = class("ActivityTimeGambleShopWindow", import(".BaseWindow"))
local ShopItem = class("ShopItem")
local cjson = require("cjson")
local myTable = xyd.tables.activityTimeShopTable

function ActivityTimeGambleShopWindow:ctor(name, params)
	ActivityTimeGambleShopWindow.super.ctor(self, name, params)
end

function ActivityTimeGambleShopWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityTimeGambleShopWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	local mainGroup = groupAction:NodeByName("mainGroup").gameObject
	self.navGroup = mainGroup:NodeByName("navGroup").gameObject
	self.itemGroup = mainGroup:NodeByName("itemGroup").gameObject
	self.tipsLabel = mainGroup:ComponentByName("tipsLabel", typeof(UILabel))
	self.costItemNumLabel = groupAction:ComponentByName("costItem/label", typeof(UILabel))
	self.shopItem = groupAction:NodeByName("shop_item").gameObject
end

function ActivityTimeGambleShopWindow:layout()
	self.costItemNumLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_DEBRIS)
	local unchosen = {
		color = Color.New2(496107519),
		effectColor = Color.New2(4294967295.0)
	}
	local chosen = {
		color = Color.New2(4294967295.0),
		effectColor = Color.New2(6933759)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab = require("app.common.ui.CommonTabBar").new(self.navGroup, 4, function (index)
		self:updateContent(index)
	end, nil, colorParams)
	local index = self:getOpenIndex()

	self.tab:setTexts({
		"1",
		"2",
		"3",
		"4"
	})

	self.tipsLabel.text = __("ACTIVITY_TIME_SHOP_UNLOCK")

	self.tab:setTabActive(index, true)

	self.shopItemList = {}

	for i = 1, 6 do
		local tmp = NGUITools.AddChild(self.itemGroup, self.shopItem)

		tmp:SetActive(true)

		local item = ShopItem.new(tmp, self)

		table.insert(self.shopItemList, item)
	end
end

function ActivityTimeGambleShopWindow:getOpenIndex()
	local index = 0
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TIME_GAMBLE)
	self.activityData = activityData
	local buy_times = activityData.detail_.buy_times

	for i = 1, 4 do
		local ids = myTable:getListByTab(i)
		local conditions = myTable:getConditions(ids[1])
		local flag = true

		for _, id in ipairs(conditions) do
			local limit = myTable:getLimit(id)

			if buy_times[id] < limit then
				flag = false

				break
			end
		end

		if flag then
			index = index + 1
		end
	end

	return index
end

function ActivityTimeGambleShopWindow:updateContent(index)
	self.index = index
	local ids = myTable:getListByTab(index)

	table.sort(ids)

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_TIME_GAMBLE)
	local buy_times = activityData.detail_.buy_times
	local conditions = myTable:getConditions(ids[1])
	local flag = true

	for _, id in ipairs(conditions) do
		local limit = myTable:getLimit(id)

		if buy_times[id] < limit then
			flag = false

			break
		end
	end

	self.tipsLabel:SetActive(not flag)

	for i, id in ipairs(ids) do
		self.shopItemList[i]:setInfo({
			id = id,
			buyTimes = buy_times[id],
			canBuy = flag
		})
	end

	for idx, item in ipairs(self.shopItemList) do
		if idx > #ids then
			item.go:SetActive(false)
		else
			item.go:SetActive(true)
		end
	end
end

function ActivityTimeGambleShopWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.onItemChange))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityTimeGambleShopWindow:onItemChange(event)
	local data = event.data.items

	for _, item in ipairs(data) do
		if item.item_id == xyd.ItemID.TIME_DEBRIS then
			self.costItemNumLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.TIME_DEBRIS)
			self.hasChangeItem_ = true

			if self.needUpdate_ and self.hasChangeItem_ then
				self:updateContent(self.index)
				self.activityData:getRedMarkState()

				self.hasChangeItem_ = false
				self.needUpdate_ = false
			end

			break
		end
	end
end

function ActivityTimeGambleShopWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_TIME_GAMBLE then
		return
	end

	local detail = cjson.decode(event.data.detail)

	if tonumber(detail.type) == 1 and self.buyId_ and self.buyId_ > 0 then
		local award = myTable:getAward(self.buyId_)
		local num = 1

		if self.buyNum then
			num = self.buyNum
		end

		local items = {
			{
				item_id = award[1],
				item_num = award[2] * num
			}
		}

		xyd.alertItems(items)

		self.buyId_ = nil
		self.buyNum = nil
	end

	self.needUpdate_ = true

	if self.needUpdate_ and self.hasChangeItem_ then
		self:updateContent(self.index)
		self.activityData:getRedMarkState()

		self.hasChangeItem_ = false
		self.needUpdate_ = false
	end
end

function ShopItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.iconRoot = go:NodeByName("iconRoot").gameObject
	self.labelLimit = go:ComponentByName("labelLimit", typeof(UILabel))
	self.buyBtn = go:NodeByName("buyBtn").gameObject
	self.redPoint = go:NodeByName("buyBtn/redMark").gameObject
	self.iconImg = self.buyBtn:ComponentByName("icon", typeof(UISprite))
	self.labelNum = self.buyBtn:ComponentByName("labelNum", typeof(UILabel))
	self.maskImg = go:NodeByName("maskImg").gameObject
	UIEventListener.Get(self.go).onClick = handler(self, self.buyItem)
end

function ShopItem:setInfo(params)
	self.id = params.id
	self.buyTimes = params.buyTimes
	self.canBuy = params.canBuy
	local award = myTable:getAward(params.id)

	if self.itemIcon then
		NGUITools.Destroy(self.itemIcon:getGameObject())
	end

	self.itemIcon = xyd.getItemIcon({
		show_has_num = true,
		uiRoot = self.iconRoot,
		itemID = award[1],
		num = award[2]
	})
	local limit = myTable:getLimit(self.id)
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", limit - self.buyTimes)
	local cost = myTable:getCost(params.id)

	xyd.setUISpriteAsync(self.iconImg, nil, "icon_" .. cost[1])

	self.labelNum.text = cost[2]

	if limit <= self.buyTimes then
		self.itemIcon:setChoose(true)
		xyd.setTouchEnable(self.buyBtn, false)
		self.maskImg:SetActive(true)
		self.redPoint:SetActive(false)
	else
		self.maskImg:SetActive(false)
		self.itemIcon:setChoose(false)
		xyd.setTouchEnable(self.buyBtn, true)

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) and self.canBuy then
			self.redPoint:SetActive(true)
		else
			self.redPoint:SetActive(false)
		end
	end
end

function ShopItem:buyItem()
	if not self.canBuy then
		xyd.alertTips(__("GACHA_LIMIT_EXCHANGE_UNLOCK"))
	else
		local cost = myTable:getCost(self.id)

		if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
			local award = myTable:getAward(self.id)
			local limit = myTable:getLimit(self.id)
			local cost = myTable:getCost(self.id)

			if limit and limit >= 99 then
				xyd.WindowManager.get():openWindow("limit_purchase_item_window", {
					limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
					needTips = true,
					titleKey = "ACTIVITY_PRAY_BUY",
					buyType = tonumber(award[1]),
					buyNum = tonumber(award[2]),
					costType = tonumber(cost[1]),
					costNum = tonumber(cost[2]),
					purchaseCallback = function (evt, num)
						local params = cjson.encode({
							type = 1,
							table_id = self.id,
							num = num
						})

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_GAMBLE, params)

						self.parent.buyId_ = self.id
						self.parent.buyNum = num

						xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
					end,
					limitNum = limit - self.buyTimes,
					eventType = xyd.event.BOSS_BUY
				})
			else
				xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
					if yes then
						local params = cjson.encode({
							type = 1,
							table_id = self.id
						})

						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_TIME_GAMBLE, params)

						self.parent.buyId_ = self.id
					end
				end)
			end
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
		end
	end
end

return ActivityTimeGambleShopWindow
