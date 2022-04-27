local BaseWindow = import(".BaseWindow")
local ActivityHalloweenShopWindow = class("ActivityHalloweenShopWindow", BaseWindow)
local ActivityHalloweenShopWindowItem = class("ActivityHalloweenShopWindowItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityHalloweenShopWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.items = {}
	self.buyNum = nil
end

function ActivityHalloweenShopWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityHalloweenShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.resItem1 = self.groupAction:ComponentByName("resItem1", typeof(UISprite))
	self.resItemNum1 = self.resItem1:ComponentByName("num", typeof(UILabel))
	self.resItem2 = self.groupAction:ComponentByName("resItem2", typeof(UISprite))
	self.resItemNum2 = self.resItem2:ComponentByName("num", typeof(UILabel))
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup = self.scrollView:NodeByName("items").gameObject
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
end

function ActivityHalloweenShopWindow:layout()
	self.resItemNum1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_SUGAR)
	self.resItemNum2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CANDY_LAMP)
	local ids = xyd.tables.activityHalloweenShopTable:getIDs()
	local params = {}
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_HALLOWEEN)

	for _, id in ipairs(ids) do
		table.insert(params, {
			id = id,
			award = xyd.tables.activityHalloweenShopTable:getAward(id),
			limit = xyd.tables.activityHalloweenShopTable:getLimit(id),
			cost = xyd.tables.activityHalloweenShopTable:getCost(id),
			times = activityData.detail.buy_times[id]
		})
	end

	table.sort(params, function (a, b)
		local limitA = a.limit - a.times == 0
		local limitB = b.limit - b.times == 0

		if limitA ~= limitB then
			return not limitA
		else
			return a.id < b.id
		end
	end)

	for i = 1, #params do
		local awardItem = NGUITools.AddChild(self.itemGroup, self.itemCell)
		local item = ActivityHalloweenShopWindowItem.new(awardItem, self)

		item:setInfo(params[i])
		table.insert(self.items, item)
	end

	self.itemGroup:GetComponent(typeof(UIGrid)):Reposition()
	self.scrollView:ResetPosition()
	self.itemCell:SetActive(false)
end

function ActivityHalloweenShopWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local award = xyd.tables.activityHalloweenShopTable:getAward(self.buyID)

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = award[1],
				item_num = award[2] * self.buyNum
			}
		})

		xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_HALLOWEEN).detail.buy_times[self.buyID] = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_HALLOWEEN).detail.buy_times[self.buyID] + self.buyNum

		for i = 1, #self.items do
			if self.items[i].id == self.buyID then
				self.items[i]:setInfo({
					id = self.buyID,
					award = xyd.tables.activityHalloweenShopTable:getAward(self.buyID),
					limit = xyd.tables.activityHalloweenShopTable:getLimit(self.buyID),
					cost = xyd.tables.activityHalloweenShopTable:getCost(self.buyID),
					times = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_HALLOWEEN).detail.buy_times[self.buyID]
				})
			end
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, function (event)
		self.resItemNum1.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.PUMPKIN_SUGAR)
		self.resItemNum2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CANDY_LAMP)
	end))
end

function ActivityHalloweenShopWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:register()
end

function ActivityHalloweenShopWindowItem:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.btn = self.go:NodeByName("btn").gameObject
	self.costImg = self.btn:ComponentByName("costImg", typeof(UISprite))
	self.btnLabel = self.btn:ComponentByName("labelTips", typeof(UILabel))
end

function ActivityHalloweenShopWindowItem:setInfo(params)
	self.params = params
	self.id = params.id
	self.label.text = __("BUY_GIFTBAG_LIMIT", params.limit - params.times)

	if params.limit - params.times <= 0 then
		xyd.setEnabled(self.btn, false)
	end

	xyd.setUISpriteAsync(self.costImg, nil, xyd.tables.itemTable:getIcon(params.cost[1]))

	self.btnLabel.text = params.cost[2]
	local icon = xyd.getItemIcon({
		show_has_num = true,
		showGetWays = false,
		itemID = params.award[1],
		num = params.award[2],
		uiRoot = self.icon.gameObject,
		dragScrollView = self.parent.scrollView,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function ActivityHalloweenShopWindowItem:register()
	UIEventListener.Get(self.btn).onClick = function ()
		if xyd.models.backpack:getItemNumByID(self.params.cost[1]) < self.params.cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.params.cost[1])))
		else
			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = true,
				item_no_click = true,
				cost = self.params.cost,
				max_num = self.params.limit - self.params.times,
				itemParams = {
					itemID = self.params.award[1],
					num = self.params.award[2]
				},
				buyCallback = function (num)
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_HALLOWEEN, cjson.encode({
						award_id = self.id,
						num = num
					}))

					self.parent.buyID = self.id
					self.parent.buyNum = num
				end,
				maxCallback = function ()
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			})
		end
	end
end

return ActivityHalloweenShopWindow
