local ActivityStarPlanShopWindow = class("ActivityStarPlanShopWindow", import(".BaseWindow"))
local ShopItem = class("GoldfishShopItem", import("app.components.CopyComponent"))
local coinList = {
	455,
	456,
	457
}
local cjson = require("cjson")

function ActivityStarPlanShopWindow:ctor(name, params)
	ActivityStarPlanShopWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_STAR_PLAN)
	self.shopItemList_ = {}
end

function ActivityStarPlanShopWindow:initWindow()
	ActivityStarPlanShopWindow.super.initWindow(self)
	self:getUIComponent()
	self:updateResItem()
	self:updateShopItemList(true)
	self:register()
end

function ActivityStarPlanShopWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))

	for i = 1, 3 do
		self["resItemLabel" .. i] = winTrans:ComponentByName("resGroup/resItem" .. i .. "/label", typeof(UILabel))
	end

	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
	self.shopItemRoot_ = winTrans:NodeByName("shopItem").gameObject
	self.titleLabel_.text = __("FAIRY_TALE_SHOP_WINDOW")
end

function ActivityStarPlanShopWindow:updateResItem()
	for i = 1, 3 do
		self["resItemLabel" .. i].text = xyd.models.backpack:getItemNumByID(coinList[i])
	end
end

function ActivityStarPlanShopWindow:updateShopItemList(first)
	local ids = xyd.tables.activityStarPlanShopTable:getIDs()

	for index, id in ipairs(ids) do
		if not self.shopItemList_[index] then
			local newItemRoot = NGUITools.AddChild(self.grid_.gameObject, self.shopItemRoot_)

			newItemRoot:SetActive(true)

			self.shopItemList_[index] = ShopItem.new(newItemRoot, self)
		end

		local buyTime = self.activityData.detail.buy_times[id]

		self.shopItemList_[index]:setInfo(id, buyTime)
	end

	if first then
		self:waitForFrame(1, function ()
			self.grid_:Reposition()
			self.scrollView_:ResetPosition()
		end)
	end
end

function ActivityStarPlanShopWindow:register()
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateResItem))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
end

function ActivityStarPlanShopWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.activity_id == xyd.ActivityID.ACTIVITY_STAR_PLAN then
		dump(self.tempInfo)
		self:updateShopItemList()

		local awards = xyd.tables.activityStarPlanShopTable:getAwards(self.tempInfo.award_id)
		local itemInfo = {
			item_id = awards[1],
			item_num = awards[2] * self.tempInfo.num
		}
		self.tempInfo = nil

		xyd.itemFloat({
			itemInfo
		})
	end
end

function ActivityStarPlanShopWindow:setTempShopItem(itemInfo)
	self.tempInfo = xyd.cloneTable(itemInfo)

	self.activityData:setTempInfo(xyd.cloneTable(itemInfo))
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
	self.buyBtn_ = goTrans:NodeByName("buyBtn").gameObject
	self.buyBtnImg_ = goTrans:ComponentByName("buyBtn/costImg", typeof(UISprite))
	self.buyBtnLabel_ = goTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.limitLabel_ = goTrans:ComponentByName("limitLabel", typeof(UILabel))

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		self:onClickBuy()
	end
end

function ShopItem:setInfo(id, buy_time)
	self.id_ = id
	self.buyTime_ = buy_time
	local limit = xyd.tables.activityStarPlanShopTable:getLimit(self.id_)
	local cost = xyd.tables.activityStarPlanShopTable:getCost(self.id_)
	local award = xyd.tables.activityStarPlanShopTable:getAwards(self.id_)
	self.limitLabel_.text = __("ACTIVITY_RETURN_SHOP_LIMIT") .. " " .. limit - self.buyTime_
	local costImg = xyd.tables.itemTable:getIcon(cost[1])

	xyd.setUISpriteAsync(self.buyBtnImg_, nil, costImg)

	self.buyBtnLabel_.text = cost[2]

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon({
			notShowGetWayBtn = true,
			scale = 1,
			uiRoot = self.itemRoot_,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent_.scrollView_
		})
	end

	if limit - self.buyTime_ <= 0 then
		self.itemIcon_:setChoose(true)
		xyd.setEnabled(self.buyBtn_, false)
	else
		self.itemIcon_:setChoose(false)
		xyd.setEnabled(self.buyBtn_, true)
	end
end

function ShopItem:onClickBuy()
	local limit = xyd.tables.activityStarPlanShopTable:getLimit(self.id_)
	local cost = xyd.tables.activityStarPlanShopTable:getCost(self.id_)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	xyd.openWindow("activity_food_festival_exchange_window", {
		callback = function (num)
			xyd.WindowManager.get():closeWindow("activity_food_festival_exchange_window")
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_STAR_PLAN, cjson.encode({
				type = 2,
				num = num,
				award_id = self.id_
			}))
			self.parent_:setTempShopItem({
				num = num,
				award_id = self.id_
			})
		end,
		awards = {
			xyd.tables.activityStarPlanShopTable:getAwards(self.id_)
		},
		costs = {
			cost
		},
		limit = limit - self.buyTime_
	})
end

return ActivityStarPlanShopWindow
