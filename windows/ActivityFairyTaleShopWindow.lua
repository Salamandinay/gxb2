local ActivityFairyTaleShopWindow = class("ActivityFairyTaleShopWindow", import(".BaseWindow"))
local FairyTaleShopItem = class("FairyTaleShopItem", import("app.components.BaseComponent"))
local FairyTaleShopGroup = class("FairyTaleShopGroup", import("app.components.BaseComponent"))
local cjson = require("cjson")
local labelStates = {
	chosen = {
		color = Color.New2(4294765567.0),
		effectColor = Color.New2(2606316799.0)
	},
	unchosen = {
		color = Color.New2(1985431807),
		effectColor = Color.New2(4294967295.0)
	}
}

function ActivityFairyTaleShopWindow:ctor(name, params)
	ActivityFairyTaleShopWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
	self.currentIndex = 0
	self.groupList_ = {}
	self.itemList_ = {}
end

function ActivityFairyTaleShopWindow:initWindow()
	ActivityFairyTaleShopWindow.super.initWindow(self)
	self:getComponent()
	self:refreshShopItem()
	self:regisetr()

	self.winTitle_.text = __("FAIRY_TALE_SHOP_WINDOW")

	self:refresResItems()
end

function ActivityFairyTaleShopWindow:getComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.winTitle_ = winTrans:ComponentByName("winTitle", typeof(UILabel))
	self.itemCostHasNum_ = winTrans:ComponentByName("costGroup/itemNum", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.grid_ = winTrans:ComponentByName("scrollView/grid", typeof(UIGrid))
end

function ActivityFairyTaleShopWindow:regisetr()
	ActivityFairyTaleShopWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresResItems))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ActivityFairyTaleShopWindow:onGetAward(event)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUY_ITEM)

	local realData = cjson.decode(event.data.detail)
	local tableId = realData.table_id
	local num = realData.num
	local item = xyd.tables.activityFairyTaleShopTable:getAward(tableId)
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)

	xyd.alertItems({
		{
			item_id = item[1],
			item_num = item[2] * num
		}
	})
	self:refreshShopItem()
end

function ActivityFairyTaleShopWindow:refresResItems()
	self.itemCostHasNum_.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.FAIRY_TALE_ICON))
end

function ActivityFairyTaleShopWindow:changeTextColor(label, selectStr)
	label.color = labelStates[selectStr].color
	label.effectColor = labelStates[selectStr].effectColor
end

function ActivityFairyTaleShopWindow:hasNavOpen(index)
	return true
end

function ActivityFairyTaleShopWindow:refreshShopItem()
	self.buyTimesList_ = self.activityData.detail.shop_infos
	local ids = xyd.tables.activityFairyTaleShopTable:getIds()
	local tempList = {}

	for i = 1, #ids do
		local shopGropItem = self.groupList_[i]

		if not self.groupList_[i] then
			shopGropItem = FairyTaleShopGroup.new(self.grid_.gameObject, self)
			self.groupList_[i] = shopGropItem
		end

		shopGropItem:setInfo({
			index = i,
			itemIds = ids[i]
		})
	end

	self.grid_:Reposition()
	self.scrollView_:ResetPosition()
end

function FairyTaleShopItem:ctor(parentGo, parent)
	self.parent_ = parent

	FairyTaleShopItem.super.ctor(self, parentGo)
end

function FairyTaleShopItem:initUI()
	FairyTaleShopItem.super.initUI(self)
	self:getComponent()
	self:registerEvent()
end

function FairyTaleShopItem:getComponent()
	local goTrans = self.go:NodeByName("mainNode")
	self.mainNode_ = goTrans.gameObject
	self.iconNode_ = goTrans:NodeByName("iconNode").gameObject
	self.res_text_ = goTrans:ComponentByName("res_text", typeof(UILabel))
	self.res_icon_ = goTrans:ComponentByName("res_icon", typeof(UISprite))
	self.limitText_ = goTrans:ComponentByName("limitText", typeof(UILabel))
	self.shadow_ = self.go:NodeByName("shadow").gameObject
	self.buyNode_ = self.go:NodeByName("buyNode").gameObject
	self.has_buy_words_ = self.go:ComponentByName("buyNode/has_buy_words", typeof(UILabel))
	self.drag = self.mainNode_:AddComponent(typeof(UIDragScrollView))
	self.has_buy_words_.text = __("ALREADY_BUY")
end

function FairyTaleShopItem:setInfo(info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.info_ = info
	self.limit_ = info.limit
	self.buyTime_ = info.buy_times or 0
	self.id_ = info.id
	self.is_completed = info.is_completed
	self.info_.item = xyd.tables.activityFairyTaleShopTable:getAward(self.id_)
	self.info_.cost = xyd.tables.activityFairyTaleShopTable:getCost(self.id_)

	xyd.setUISpriteAsync(self.res_icon_, nil, xyd.tables.itemTable:getName(self.info_.cost[1]))

	self.res_text_.text = self.info_.cost[2]
	self.limitText_.text = __("BUY_GIFTBAG_LIMIT", self.buyTime_ .. "/" .. self.limit_)
	local params = {
		uiRoot = self.iconNode_,
		itemID = self.info_.item[1],
		num = self.info_.item[2],
		dragScrollView = self.parent_.scrollView_
	}

	if not self.itemIcon_ then
		self.itemIcon_ = xyd.getItemIcon(params)
	elseif self.itemIcon_ then
		NGUITools.Destroy(self.itemIcon_:getGameObject())

		self.itemIcon_ = xyd.getItemIcon(params)
	end

	self:updateShaddow()
end

function FairyTaleShopItem:updateShaddow()
	self.shadow_:SetActive(self.limit_ <= self.buyTime_ or self.is_completed == 0)
	self.buyNode_:SetActive(self.limit_ <= self.buyTime_)
end

function FairyTaleShopItem:registerEvent()
	UIEventListener.Get(self.mainNode_).onClick = function ()
		if self.is_completed == 0 then
			return
		end

		if self.limit_ and self.limit_ <= self.buyTime_ then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))

			return
		end

		local get_data = self.info_.item
		local data = self.info_.cost

		if xyd.models.backpack:getItemNumByID(data[1]) < data[2] then
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

			return
		end

		local params = {
			needTips = true,
			limitKey = "ACTIVITY_WORLD_BOSS_LIMIT",
			buyType = get_data[1],
			buyNum = get_data[2],
			costType = data[1],
			costNum = data[2]
		}

		function params.purchaseCallback(_, num)
			if xyd.models.backpack:getItemNumByID(data[1]) < data[2] * num then
				xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))

				return
			end

			local msg = messages_pb.get_activity_award_req()
			msg.activity_id = xyd.ActivityID.FAIRY_TALE
			msg.params = cjson.encode({
				table_id = self.id_,
				num = num
			})

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			xyd.WindowManager.get():closeWindow("limit_purchase_item_window")
		end

		params.titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(get_data[1]))
		params.limitNum = self.limit_ - self.buyTime_
		params.notEnoughWords = __("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1]))
		params.eventType = xyd.event.BOSS_BUY

		function params.tipsCallback()
			xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(data[1])))
		end

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

function FairyTaleShopItem:getPrefabPath()
	return "Prefabs/Components/fairy_tale_shop_item"
end

function FairyTaleShopGroup:ctor(parentGo, parent)
	self.parent_ = parent

	FairyTaleShopGroup.super.ctor(self, parentGo)
end

function FairyTaleShopGroup:getPrefabPath()
	return "Prefabs/Components/fairy_tale_shop_group"
end

function FairyTaleShopGroup:initUI()
	FairyTaleShopGroup.super.initUI(self)
	self:getComponent()
end

function FairyTaleShopGroup:getComponent()
	local goTrans = self.go.transform
	self.okImg_ = goTrans:NodeByName("okImg").gameObject
	self.lockImg_ = goTrans:NodeByName("lockImg").gameObject
	self.textLabel_ = goTrans:ComponentByName("textLabel", typeof(UILabel))
	self.groupItem_ = goTrans:ComponentByName("groupItem", typeof(UIGrid))
	self.drag = self.go:AddComponent(typeof(UIDragScrollView))
end

function FairyTaleShopGroup:setInfo(params)
	self.index = params.index
	self.drag.scrollView = self.parent_.scrollView_

	self:refreshItem(params.itemIds)
end

function FairyTaleShopGroup:refreshItem(idList)
	local itemList = self.parent_.itemList_
	local is_completed, completeValue = nil

	for _, id in ipairs(idList) do
		local idx = tonumber(id)
		local shopItem = nil

		if not itemList[idx] then
			shopItem = FairyTaleShopItem.new(self.groupItem_.gameObject, self.parent_)
			itemList[idx] = shopItem
		else
			shopItem = itemList[idx]
		end

		is_completed = self.parent_.activityData.detail.shop_infos[id].is_completed
		completeValue = xyd.tables.activityFairyTaleShopTable:getCompleteValue(id)

		shopItem:setInfo({
			id = id,
			buy_times = self.parent_.activityData.detail.shop_infos[id].buy_times,
			limit = xyd.tables.activityFairyTaleShopTable:getLimit(id),
			is_completed = is_completed
		})
	end

	self:updateLock(is_completed, completeValue)
	self.groupItem_:Reposition()
end

function FairyTaleShopGroup:updateLock(is_completed, completeValue)
	local isLock = is_completed ~= 1

	self.lockImg_:SetActive(isLock)
	self.okImg_:SetActive(not isLock)

	if isLock then
		self.textLabel_.text = __("FAIRY_TALE_SHOP_LEVEL_NOT_ENOUGH_" .. self.index)
	else
		self.textLabel_.text = __("FAIRY_TALE_SHOP_LEVEL", self.index)
	end
end

return ActivityFairyTaleShopWindow
