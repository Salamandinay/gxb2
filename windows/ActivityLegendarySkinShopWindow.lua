local BaseWindow = import(".BaseWindow")
local ActivityLegendarySkinShopWindow = class("ActivityLegendarySkinShopWindow", BaseWindow)
local ActivityEquipLevelUpAwardItem = class("ActivityEquipLevelUpAwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local cjson = require("cjson")

function ActivityLegendarySkinShopWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.buy_times = params.buy_times
	self.hasBuyId = nil
end

function ActivityLegendarySkinShopWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.plusBtn = groupAction:NodeByName("numGroup/btn").gameObject
	self.numLabel = groupAction:ComponentByName("numGroup/label", typeof(UILabel))
	self.scrollView = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.selectItem = groupAction:NodeByName("scroller/equip_level_up_award_item").gameObject
	self.itemGroup = groupAction:NodeByName("scroller/itemGroup").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.selectItem, ActivityEquipLevelUpAwardItem, self)

	self.selectItem:SetActive(false)
end

function ActivityLegendarySkinShopWindow:layout()
	self.labelTitle.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT09")
	self.numLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON2)
end

function ActivityLegendarySkinShopWindow:initItemGroup()
	local ids = xyd.tables.activityLengarySkinShopTable:getIDs()
	self.award = {}

	for i = 1, #ids do
		table.insert(self.award, {
			tonumber(ids[i]),
			self.buy_times[tonumber(ids[i])]
		})
	end

	self.wrapContent:setInfos(self.award, {})
end

function ActivityLegendarySkinShopWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresh))

	UIEventListener.Get(self.plusBtn).onClick = function ()
		local params = {
			showGetWays = false,
			show_has_num = true,
			itemID = xyd.ItemID.LEGENDARY_SKIN_ICON2,
			itemNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON2),
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end
end

function ActivityLegendarySkinShopWindow:refresh()
	self.numLabel.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON2)
end

function ActivityLegendarySkinShopWindow:onAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local detail = {}

	if data.activity_id == xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN then
		if data.detail and tostring(data.detail) ~= "" then
			detail = cjson.decode(data.detail)
		end

		local type = detail.type

		if not type or type ~= 1 then
			self.buy_times[self.hasBuyId] = self.buy_times[self.hasBuyId] + self.hasBuyNum

			xyd.models.itemFloatModel:pushNewItems({
				{
					item_id = xyd.tables.activityLengarySkinShopTable:getAwards(self.hasBuyId)[1],
					item_num = xyd.tables.activityLengarySkinShopTable:getAwards(self.hasBuyId)[2] * self.hasBuyNum
				}
			})
			self:initItemGroup()
		end
	end
end

function ActivityLegendarySkinShopWindow:buy(id, num)
	self.hasBuyId = id
	self.hasBuyNum = num
end

function ActivityLegendarySkinShopWindow:initWindow()
	ActivityLegendarySkinShopWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initItemGroup()
	self:register()
end

function ActivityEquipLevelUpAwardItem:ctor(go, parent)
	ActivityEquipLevelUpAwardItem.super.ctor(self, go, parent)

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

function ActivityEquipLevelUpAwardItem:registEvent()
	UIEventListener.Get(self.go).onClick = handler(self, self.buyTouch)
end

function ActivityEquipLevelUpAwardItem:updateInfo()
	self.label.text = __("BUY_GIFTBAG_LIMIT", self.data[2] .. "/" .. xyd.tables.activityLengarySkinShopTable:getLimit(self.data[1]))
	self.label2.text = tostring(xyd.tables.activityLengarySkinShopTable:getCost(self.data[1])[2])

	if self.itemIcon == nil then
		self.itemIcon = xyd.getItemIcon({
			show_has_num = true,
			uiRoot = self.icon,
			itemID = xyd.tables.activityLengarySkinShopTable:getAwards(self.data[1])[1],
			num = xyd.tables.activityLengarySkinShopTable:getAwards(self.data[1])[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		self.itemIcon:setDragScrollView()
	end

	if xyd.tables.activityLengarySkinShopTable:getLimit(self.data[1]) <= self.data[2] then
		self.bought:SetActive(true)
	end
end

function ActivityEquipLevelUpAwardItem:buyTouch()
	if xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON2) < xyd.tables.activityLengarySkinShopTable:getCost(self.data[1])[2] then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.LEGENDARY_SKIN_ICON2)))

		return
	end

	local leftTimes = xyd.tables.activityLengarySkinShopTable:getLimit(self.data[1]) - self.data[2]

	if leftTimes == 1 then
		xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (flag)
			if flag then
				local params = require("cjson").encode({
					num = 1,
					type = 2,
					award_id = tonumber(self.data[1])
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN, params)
				self.parent:buy(self.data[1], 1)
			end
		end)
	else
		local item = xyd.tables.activityLengarySkinShopTable:getAwards(self.data[1])
		local params = {
			hasMaxMin = true,
			buyType = item[1],
			buyNum = item[2],
			costType = xyd.tables.activityLengarySkinShopTable:getCost(self.data[1])[1],
			costNum = xyd.tables.activityLengarySkinShopTable:getCost(self.data[1])[2],
			purchaseCallback = function (_, num)
				local params = require("cjson").encode({
					type = 2,
					award_id = tonumber(self.data[1]),
					num = num
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN, params)
				self.parent:buy(self.data[1], num)
			end,
			titleWords = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(item[1])),
			limitNum = leftTimes,
			eventType = xyd.event.GET_ACTIVITY_AWARD
		}

		xyd.WindowManager.get():openWindow("limit_purchase_item_window", params)
	end
end

return ActivityLegendarySkinShopWindow
