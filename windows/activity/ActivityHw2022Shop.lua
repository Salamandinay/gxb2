local ActivityHw2022Shop = class("ActivityHw2022Shop", import(".ActivityContent"))
local cjson = require("cjson")
local ShopItem = class("ShopItem", import("app.components.CopyComponent"))

function ActivityHw2022Shop:ctor(parentGO, params)
	self.shopItemList_ = {}

	ActivityHw2022Shop.super.ctor(self, parentGO, params)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_HW2022_SHOP, function ()
		xyd.db.misc:setValue({
			key = "activity_hw2022_shop_touch",
			value = xyd.getServerTime()
		})
	end)
	dump(self.activityData.detail)
end

function ActivityHw2022Shop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_hw2022_shop"
end

function ActivityHw2022Shop:initUI()
	ActivityHw2022Shop.super.initUI(self)
	self:getUIComponent()
	self:updateItemNum()
	self:layout()
end

function ActivityHw2022Shop:updateHeight()
end

function ActivityHw2022Shop:getUIComponent()
	local goTrans = self.go.transform
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.shopItem_ = goTrans:NodeByName("shopItem").gameObject
	self.scrollView_ = goTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollView/grid", typeof(UIGrid))

	for i = 1, 3 do
		self["resItem" .. i] = goTrans:NodeByName("resItemGroup/res_item" .. i).gameObject
		self["resItemLabel" .. i] = self["resItem" .. i]:ComponentByName("res_num_label", typeof(UILabel))

		UIEventListener.Get(self["resItem" .. i]).onClick = function ()
			xyd.WindowManager.get():closeWindow("activity_window", function ()
				local params = xyd.tables.activityTable:getWindowParams(xyd.ActivityID.ACTIVITY_HW2022)
				local testParams = nil

				if params ~= nil then
					testParams = params.activity_ids
				end

				xyd.openWindow("activity_window", {
					activity_type = xyd.tables.activityTable:getType(xyd.ActivityID.ACTIVITY_HW2022),
					onlyShowList = testParams,
					select = xyd.ActivityID.ACTIVITY_HW2022
				})
			end)
		end
	end
end

function ActivityHw2022Shop:updateItemNum()
	self.resItemLabel1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_AWARD_ITEM1)
	self.resItemLabel2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_AWARD_ITEM2)
	self.resItemLabel3.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ACTIVITY_HW2022_AWARD_ITEM3)
end

function ActivityHw2022Shop:layout()
	xyd.setUISpriteAsync(self.logoImg_, nil, "activity_hw2022_shop_logo_" .. xyd.Global.lang)
	self:updateItemList(true)
end

function ActivityHw2022Shop:updateItemList(resetposition)
	local buyTimes = self.activityData.detail.buy_times
	local ids = xyd.tables.activityHw2022ShopTable:getIDs()

	for index, id in ipairs(ids) do
		if not self.shopItemList_[index] then
			local newRoot = NGUITools.AddChild(self.grid_.gameObject, self.shopItem_)

			newRoot:SetActive(true)

			self.shopItemList_[index] = ShopItem.new(newRoot, self)
		end

		self.shopItemList_[index]:setInfo(id, buyTimes[index])
	end

	if resetposition then
		self.grid_:Reposition()
		self.scrollView_:ResetPosition()
	end
end

function ActivityHw2022Shop:onRegister()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_HALLOWEEN2022_SHOP_HELP"
		})
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateItemNum))
end

function ActivityHw2022Shop:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = cjson.decode(data.detail)
	local items = detail.items

	xyd.alertItems(items)
	self:updateItemList()
end

function ShopItem:ctor(go, parent)
	self.parent_ = parent

	ShopItem.super.ctor(self, go)
end

function ShopItem:initUI()
	ShopItem.super.initUI(self)
	self:getUIComponent()
end

function ShopItem:getUIComponent()
	local goTrans = self.go.transform
	self.itemRoot_ = goTrans:NodeByName("itemRoot").gameObject
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))
	self.costLayout_ = goTrans:ComponentByName("costLayout", typeof(UILayout))
	self.costItem1 = goTrans:ComponentByName("costLayout/costItem1", typeof(UISprite))
	self.costItem2 = goTrans:ComponentByName("costLayout/costItem2", typeof(UISprite))
	self.numLabel1 = goTrans:ComponentByName("costLayout/numLabel1", typeof(UILabel))
	self.numLabel2 = goTrans:ComponentByName("costLayout/numLabel2", typeof(UILabel))
	self.plusLabel = goTrans:NodeByName("costLayout/plusLabel").gameObject
	UIEventListener.Get(self.go.gameObject).onClick = handler(self, self.onClickBuy)
end

function ShopItem:setInfo(id, buy_time)
	if not id then
		self.go:SetActive(false)

		return
	end

	self.id_ = id
	self.buy_time = buy_time
	local award = xyd.tables.activityHw2022ShopTable:getAwards(self.id_)

	if not self.awardItem_ then
		self.awardItem_ = xyd.getItemIcon({
			showGetWays = false,
			scale = 0.9074074074074074,
			uiRoot = self.itemRoot_,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			itemID = award[1],
			num = award[2]
		})
	end

	local limit_times = xyd.tables.activityHw2022ShopTable:getLimit(self.id_)

	self.awardItem_:setChoose(limit_times <= self.buy_time)

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", limit_times - self.buy_time)
	local costs = xyd.tables.activityHw2022ShopTable:getCost(self.id_)

	self.plusLabel:SetActive(#costs >= 2)
	self.costItem2.gameObject:SetActive(#costs >= 2)
	self.numLabel2.gameObject:SetActive(#costs >= 2)

	for index, cost in ipairs(costs) do
		local img = xyd.tables.itemTable:getIcon(cost[1])
		self["numLabel" .. index].text = cost[2]

		xyd.setUISpriteAsync(self["costItem" .. index], nil, img)
	end

	self.costLayout_:Reposition()
end

function ShopItem:onClickBuy()
	local limit_times = xyd.tables.activityHw2022ShopTable:getLimit(self.id_)
	local costs = xyd.tables.activityHw2022ShopTable:getCost(self.id_)

	if limit_times <= self.buy_time then
		return
	end

	local flag = true

	for i = 1, #costs do
		local data = costs[i]

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			flag = false

			break
		end
	end

	if not flag then
		xyd.alertTips(__("NOT_ENOUGH_ACTIVITY_ITEMS"))

		return
	end

	xyd.openWindow("activity_food_festival_exchange_window", {
		callback = function (num)
			xyd.WindowManager.get():closeWindow("activity_food_festival_exchange_window")

			local params = cjson.encode({
				award_id = self.id_,
				num = num
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_HW2022_SHOP, params)
		end,
		awards = {
			xyd.tables.activityHw2022ShopTable:getAwards(self.id_)
		},
		costs = costs,
		limit = limit_times - self.buy_time
	})
end

return ActivityHw2022Shop
