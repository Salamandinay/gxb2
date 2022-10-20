local BaseWindow = import(".BaseWindow")
local SoulLandShopWindow = class("SoulLandShopWindow", BaseWindow)
local SoulLandShopItem = class("SoulLandShopItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local cjson = require("cjson")

function SoulLandShopWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.buy_times = params.buy_times
	self.hasBuyId = nil
end

function SoulLandShopWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.plusBtn = groupAction:NodeByName("numGroup/btn").gameObject
	self.numLabel = groupAction:ComponentByName("numGroup/label", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.selectItem = groupAction:NodeByName("equip_level_up_award_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.selectItem, SoulLandShopItem, self)

	self.selectItem:SetActive(false)
end

function SoulLandShopWindow:layout()
	self.labelTitle.text = __("SOUL_LAND_TEXT21")

	self:refresh()
end

function SoulLandShopWindow:initItemGroup()
	local ids = xyd.tables.soulLandShopTable:getIDs()
	self.award = {}

	for i = 1, #ids do
		table.insert(self.award, {
			tonumber(ids[i]),
			self.buy_times[tonumber(ids[i])]
		})
	end

	self.wrapContent:setInfos(self.award, {})
end

function SoulLandShopWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.SOUL_LAND_SHOP_BUY, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresh))

	UIEventListener.Get(self.plusBtn).onClick = function ()
		local params = {
			showGetWays = false,
			show_has_num = true,
			itemID = xyd.ItemID.SOUL_LAND_BRANCH,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.SOUL_LAND_BRANCH),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function SoulLandShopWindow:refresh()
	self.numLabel.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getItemNumByID(xyd.ItemID.SOUL_LAND_BRANCH))
end

function SoulLandShopWindow:onAward(event)
	self.buy_times = event.data.buy_times

	self:initItemGroup()
end

function SoulLandShopWindow:buy(id, num)
	self.hasBuyId = id
	self.hasBuyNum = num
end

function SoulLandShopWindow:initWindow()
	SoulLandShopWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItemGroup()
	self:register()
end

function SoulLandShopItem:ctor(go, parent)
	SoulLandShopItem.super.ctor(self, go, parent)

	self.icon = self.go:NodeByName("icon").gameObject
	self.label = self.go:ComponentByName("label", typeof(UILabel))
	self.label2 = self.go:ComponentByName("label2", typeof(UILabel))
	self.bought = self.go:NodeByName("bought").gameObject

	self.bought:SetActive(false)

	self.label3 = self.go:ComponentByName("bought/buyNode/has_buy_words", typeof(UILabel))
	self.label3.text = __("ALREADY_BUY")
	self.itemIcon = nil
	self.parent = parent

	self:registEvent()
end

function SoulLandShopItem:registEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.buyTouch)
end

function SoulLandShopItem:updateInfo()
	self.label.text = __("BUY_GIFTBAG_LIMIT", self.data[2] .. "/" .. xyd.tables.soulLandShopTable:getLimit(self.data[1]))
	self.label2.text = tostring(xyd.tables.soulLandShopTable:getCost(self.data[1])[2])

	if self.itemIcon == nil then
		self.itemIcon = xyd.getItemIcon({
			show_has_num = true,
			uiRoot = self.icon,
			itemID = xyd.tables.soulLandShopTable:getItem(self.data[1])[1],
			num = xyd.tables.soulLandShopTable:getItem(self.data[1])[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		self.itemIcon:setDragScrollView()
	end

	if xyd.tables.soulLandShopTable:getLimit(self.data[1]) <= self.data[2] then
		self.bought:SetActive(true)
	end
end

function SoulLandShopItem:buyTouch()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.SOUL_LAND_BRANCH) < xyd.tables.soulLandShopTable:getCost(self.data[1])[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.SOUL_LAND_BRANCH)))

		return
	end

	local leftTimes = xyd.tables.soulLandShopTable:getLimit(self.data[1]) - self.data[2]

	if leftTimes == 1 then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (flag)
			if flag then
				xyd.models.soulLand:reqBuyShop(tonumber(self.data[1]), 1)
				self.parent:buy(self.data[1], 1)
			end
		end)
	else
		local item = xyd.tables.soulLandShopTable:getItem(self.data[1])
		local params = {
			hasMaxMin = true,
			buyType = item[1],
			buyNum = item[2],
			costType = xyd.tables.soulLandShopTable:getCost(self.data[1])[1],
			costNum = xyd.tables.soulLandShopTable:getCost(self.data[1])[2],
			purchaseCallback = function (_, num)
				xyd.models.soulLand:reqBuyShop(tonumber(self.data[1]), num)
				self.parent:buy(self.data[1], num)
			end,
			titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(item[1])),
			limitNum = leftTimes,
			eventType = xyd.event.GET_ACTIVITY_AWARD
		}

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

return SoulLandShopWindow
