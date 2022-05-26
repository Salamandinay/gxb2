local BaseWindow = import(".BaseWindow")
local ActivityChildhoodShopExchangeWindow = class("ActivityChildhoodShopExchangeWindow", BaseWindow)
local ActivityChildhoodShopExchangeWindowItem = class("ActivityChildhoodShopExchangeWindowItem", import("app.components.CopyComponent"))
local cjson = require("cjson")

function ActivityChildhoodShopExchangeWindow:ctor(name, params)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CHILDHOOD_SHOP)
	self.params = params
	self.items = {}

	xyd.db.misc:setValue({
		key = "activity_childhood_shop_exchange_line_view_time" .. self.params.line,
		value = xyd.getServerTime()
	})
	BaseWindow.ctor(self, name, params)
end

function ActivityChildhoodShopExchangeWindow:initWindow()
	self:getUIComponent()
	ActivityChildhoodShopExchangeWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityChildhoodShopExchangeWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.partner = self.groupAction:ComponentByName("partner", typeof(UITexture))
	self.resItem = self.groupAction:ComponentByName("resItem", typeof(UISprite))
	self.resNum = self.resItem:ComponentByName("num", typeof(UILabel))
	self.scroller = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.itemCell = self.groupAction:NodeByName("itemCell").gameObject
end

function ActivityChildhoodShopExchangeWindow:initUIComponent()
	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_CANDY)
	self.line = self.params.line
	local ids = xyd.tables.activityChildrenShopTable:getIDs()

	for i = 1, #ids do
		local type = xyd.tables.activityChildrenShopTable:getType(ids[i])

		if type == 1 then
			local line = xyd.tables.activityChildrenShopTable:getLine(ids[i])

			if line == self.line then
				local condition = tonumber(xyd.tables.activityChildrenShopTable:getCondition(ids[i]))
				local go = NGUITools.AddChild(self.itemGroup.gameObject, self.itemCell.gameObject)
				local item = ActivityChildhoodShopExchangeWindowItem.new(go, self)
				local info = {
					id = ids[i],
					limitTime = xyd.tables.activityChildrenShopTable:getLimit(ids[i]),
					buyTime = self.activityData.detail.buy_times[ids[i]],
					isLock = condition ~= 0 and self.activityData.detail.buy_times[condition] == 0 and true or false
				}

				item:setInfo(info)
				xyd.setDragScrollView(item.go, self.scroller)
				table.insert(self.items, item)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self.scroller:ResetPosition()

	self.partnerEffect = xyd.Spine.new(self.partner.gameObject)

	self.partnerEffect:setInfo("yinyue_pifu05", function ()
		self.partnerEffect:play("idle", 0)
	end)
end

function ActivityChildhoodShopExchangeWindow:register()
	ActivityChildhoodShopExchangeWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.CHILDHOOD_SHOP_CANDY)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		for i = 1, #self.items do
			local item = self.items[i]
			local id = item.id
			local condition = tonumber(xyd.tables.activityChildrenShopTable:getCondition(id))

			item:update({
				buyTime = self.activityData.detail.buy_times[id],
				isLock = condition ~= 0 and self.activityData.detail.buy_times[condition] == 0 and true or false
			})
		end
	end)
end

function ActivityChildhoodShopExchangeWindowItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.groupAward = self.go:NodeByName("groupAward").gameObject
	self.labelLimit = self.go:ComponentByName("labelLimit", typeof(UILabel))
	self.labelNum = self.go:ComponentByName("labelNum", typeof(UILabel))
	self.btnBuy = self.go:NodeByName("btnBuy").gameObject
	self.btnBuyIcon = self.btnBuy:ComponentByName("icon", typeof(UISprite))
	self.btnBuyNum = self.btnBuy:ComponentByName("num", typeof(UILabel))
end

function ActivityChildhoodShopExchangeWindowItem:setInfo(params)
	self.id = params.id
	self.limitTime = params.limitTime
	self.buyTime = params.buyTime
	self.isLock = params.isLock
	self.icons = {}
	local awards = xyd.tables.activityChildrenShopTable:getAward(self.id)

	for i, award in ipairs(awards) do
		self.icons[i] = xyd.getItemIcon({
			notShowGetWayBtn = true,
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.groupAward,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scroller,
			isNew = award[1] == 6761 and true or false
		})
	end

	self.labelLimit.text = __("ACTIVITY_RETURN_SHOP_LIMIT")
	self.labelNum.text = self.buyTime .. "/" .. self.limitTime

	if self.limitTime <= self.buyTime then
		self.btnBuy:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		for _, icon in ipairs(self.icons) do
			icon:setChoose(true)
		end
	end

	if self.limitTime <= self.buyTime or self.isLock then
		xyd.applyChildrenGrey(self.btnBuy.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnBuy.gameObject)
	end

	local cost = xyd.tables.activityChildrenShopTable:getCost(self.id)

	xyd.setUISpriteAsync(self.btnBuyIcon, nil, "icon_" .. cost[1])

	self.btnBuyNum.text = cost[2]

	UIEventListener.Get(self.btnBuy).onClick = function ()
		if self.isLock then
			xyd.alertTips(__("ACTIVITY_CHILDREN_SHOP_TIPS04"))

			return
		end

		if self.limitTime <= self.buyTime then
			xyd.alertTips(__("ACTIVITY_CHILDREN_SHOP_TIPS03"))

			return
		end

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.alertYesNo(__("CONFIRM_CHANGE"), function (yes)
			if yes then
				self.parent.activityData:sendReq({
					num = 1,
					type = 1,
					award_id = self.id
				})
			end
		end)
	end
end

function ActivityChildhoodShopExchangeWindowItem:update(params)
	self.buyTime = params.buyTime
	self.isLock = params.isLock
	self.labelNum.text = self.buyTime .. "/" .. self.limitTime

	if self.limitTime <= self.buyTime then
		for _, icon in ipairs(self.icons) do
			icon:setChoose(true)
		end
	end

	if self.limitTime <= self.buyTime or self.isLock then
		xyd.applyChildrenGrey(self.btnBuy.gameObject)
	else
		xyd.applyChildrenOrigin(self.btnBuy.gameObject)
	end
end

return ActivityChildhoodShopExchangeWindow
