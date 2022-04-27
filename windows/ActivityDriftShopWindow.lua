local BaseWindow = import(".BaseWindow")
local ActivityDriftShopWindow = class("ActivityDriftShopWindow", BaseWindow)
local ActivityDriftShopWindowItem = class("ActivityDriftShopWindowItem", import("app.components.CopyComponent"))

function ActivityDriftShopWindow:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.items = {}
	self.buyNum = nil
end

function ActivityDriftShopWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityDriftShopWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.numLabel = self.groupAction:ComponentByName("numLabel", typeof(UILabel))
	self.scrollView = self.groupAction:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup = self.scrollView:NodeByName("items").gameObject
	self.itemCell = winTrans:NodeByName("itemCell").gameObject
end

function ActivityDriftShopWindow:layout()
	self.numLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DRIFT_SHOP_COIN)
	local ids = xyd.tables.activityLafuliShopTable:getIDs()
	local params = {}
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.LAFULI_DRIFT)

	for _, id in ipairs(ids) do
		table.insert(params, {
			id = id,
			award = xyd.tables.activityLafuliShopTable:getAward(id),
			limit = xyd.tables.activityLafuliShopTable:getLimit(id),
			cost = xyd.tables.activityLafuliShopTable:getCost(id),
			times = activityData.detail.shop_times[id]
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
		local item = ActivityDriftShopWindowItem.new(awardItem, self)

		item:setInfo(params[i])
		table.insert(self.items, item)
	end

	self.itemCell:SetActive(false)
end

function ActivityDriftShopWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.LAFULI_DRIFT_SHOP, function (event)
		xyd.models.itemFloatModel:pushNewItems(event.data.items)

		xyd.models.activity:getActivity(xyd.ActivityID.LAFULI_DRIFT).detail.shop_times[event.data.table_id] = xyd.models.activity:getActivity(xyd.ActivityID.LAFULI_DRIFT).detail.shop_times[event.data.table_id] + self.buyNum

		for i = 1, #self.items do
			if self.items[i].id == event.data.table_id then
				self.items[i]:setInfo({
					id = event.data.table_id,
					award = xyd.tables.activityLafuliShopTable:getAward(event.data.table_id),
					limit = xyd.tables.activityLafuliShopTable:getLimit(event.data.table_id),
					cost = xyd.tables.activityLafuliShopTable:getCost(event.data.table_id),
					times = xyd.models.activity:getActivity(xyd.ActivityID.LAFULI_DRIFT).detail.shop_times[event.data.table_id]
				})
			end
		end
	end)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, function (event)
		self.numLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.DRIFT_SHOP_COIN)
	end))
end

function ActivityDriftShopWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
	self:register()
end

function ActivityDriftShopWindowItem:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.btn = self.go:NodeByName("btn").gameObject
	self.btnLabel = self.btn:ComponentByName("labelTips", typeof(UILabel))
end

function ActivityDriftShopWindowItem:setInfo(params)
	self.params = params
	self.id = params.id
	self.label.text = __("BUY_GIFTBAG_LIMIT", params.limit - params.times)

	if params.limit - params.times <= 0 then
		xyd.setEnabled(self.btn, false)
	end

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

function ActivityDriftShopWindowItem:register()
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
					local msg = messages_pb.lafuli_drift_shop_req()
					msg.activity_id = xyd.ActivityID.LAFULI_DRIFT
					msg.table_id = self.id
					msg.num = num

					xyd.Backend.get():request(xyd.mid.LAFULI_DRIFT_SHOP, msg)

					self.parent.buyNum = num
				end,
				maxCallback = function ()
					xyd.showToast(__("FULL_BUY_SLOT_TIME"))
				end
			})
		end
	end
end

return ActivityDriftShopWindow
