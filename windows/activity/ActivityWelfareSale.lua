local ActivityContent = import(".ActivityContent")
local ActivityWelfareSale = class("ActivityWelfareSale", ActivityContent)
local ActivityWelfareSaleItem = class("ActivityWelfareSaleItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WelfareSaleTable = xyd.tables.welfareSaleTable
local json = require("cjson")
local BingActivityID = xyd.ActivityID.PROPHET_SUMMON_GIFTBAG

function ActivityWelfareSale:ctor(parentGO, params, parent)
	ActivityWelfareSale.super.ctor(self, parentGO, params, parent)

	local nowTime = xyd.db.misc:getValue("activity_welfare_sale_giftbag_redmark")

	if not nowTime or not xyd.isSameDay(tonumber(nowTime), xyd.getServerTime()) then
		xyd.db.misc:setValue({
			key = "activity_welfare_sale_giftbag_redmark",
			value = xyd.getServerTime()
		})
	end
end

function ActivityWelfareSale:getPrefabPath()
	return "Prefabs/Windows/activity/welfare_sale"
end

function ActivityWelfareSale:initUI()
	self:getUIComponent()
	ActivityWelfareSale.super.initUI(self)
	self:initUIComponent()
	self:initContentGroup()
end

function ActivityWelfareSale:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.labelText01 = go:ComponentByName("labelText01", typeof(UILabel))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.timeLable_ = self.timeGroup:ComponentByName("timeLable_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	local contentGroup = go:NodeByName("contentGroup").gameObject
	self.Bg2_ = contentGroup:ComponentByName("Bg2_", typeof(UISprite))
	self.scrollView = contentGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = contentGroup:NodeByName("scroller_/itemGroup").gameObject
	self.welfareItem = contentGroup:NodeByName("scroller_/welfare_sale_item").gameObject
end

function ActivityWelfareSale:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "welfare_sale_text01_" .. xyd.Global.lang, nil, , true)
	import("app.components.CountDown").new(self.timeLable_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	self.labelText01.text = __("WELFARE_TEXT01")
	self.endLabel_.text = __("TEXT_END")
end

function ActivityWelfareSale:initContentGroup()
	self:waitForFrame(1, function ()
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.welfareItem, ActivityWelfareSaleItem, self)
		local ids = WelfareSaleTable:getIds()
		self.items = {}
		local data = xyd.models.activity:getActivity(BingActivityID)
		local point = 0

		if data then
			local roundMaxNum = xyd.tables.activityTable:getRound(BingActivityID)[1]
			point = data.detail.point + data.detail.circle_times * roundMaxNum
		else
			xyd.alert(xyd.AlertType.TIPS, "绑定活动未开启: " .. BingActivityID)
		end

		for i = 1, #ids do
			local id = ids[i]
			local item = {
				id = id,
				buy_time = self.activityData.detail.buy_times[id] or 0,
				limit = WelfareSaleTable:getLimit(id),
				point = point
			}

			table.insert(self.items, item)
		end

		table.sort(self.items, function (a, b)
			local canBuy_a = a.limit - a.buy_time
			local canBuy_b = b.limit - b.buy_time

			if canBuy_a == canBuy_b then
				return a.id < b.id
			else
				return canBuy_b < canBuy_a
			end
		end)
		self.wrapContent:setInfos(self.items, {})
	end)
end

function ActivityWelfareSale:onRegister()
	ActivityWelfareSale.super.onRegister(self)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function ActivityWelfareSale:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.WELFARE_SALE then
		return
	end

	local awardID = self.activityData.buyID
	local awards = WelfareSaleTable:getAwards(awardID)
	local items = {}

	for i = 1, #awards do
		local item = {
			item_id = awards[i][1],
			item_num = awards[i][2]
		}

		table.insert(items, item)
	end

	xyd.itemFloat(items, nil, , 6000)

	local giftItems = self.wrapContent:getItems()
	local len = xyd.getLength(giftItems)

	for i = -1, -len, -1 do
		if awardID == giftItems[tostring(i)].id then
			giftItems[tostring(i)]:setBtnState(false)
			giftItems[tostring(i)]:updateTimeLabel()

			break
		end
	end
end

function ActivityWelfareSale:resizeToParent()
	ActivityWelfareSale.super.resizeToParent(self)
	self.go:Y(-440)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height
	self.Bg2_.height = 515 + p_height - 869

	if xyd.Global.lang == "en_en" then
		self.timeGroup:X(135)
	elseif xyd.Global.lang == "fr_fr" then
		self.timeGroup:X(115)
	elseif xyd.Global.lang == "ja_jp" then
		self.timeGroup:X(135)
	elseif xyd.Global.lang == "de_de" then
		self.timeGroup:X(100)

		self.timeLable_.fontSize = 20
		self.endLabel_.fontSize = 20

		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()

		self.labelText01.fontSize = 20
		self.labelText01.spacingY = 3
	end
end

function ActivityWelfareSaleItem:ctor(go, parent)
	ActivityWelfareSaleItem.super.ctor(self, go, parent)
end

function ActivityWelfareSaleItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.buyBtn_ = go:NodeByName("buyBtn_").gameObject
	self.buttonLabel = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.buttonIcon = self.buyBtn_:ComponentByName("icon_", typeof(UISprite))
	self.labelLimit = go:ComponentByName("labelLimit", typeof(UILabel))
end

function ActivityWelfareSaleItem:registerEvent()
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onBuy)
end

function ActivityWelfareSaleItem:onBuy()
	if self.point < self.reqPoint then
		xyd.showToast(__("WELFARE_TEXT02", self.reqPoint))
	else
		local cost = WelfareSaleTable:getCost(self.id)

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alert(xyd.AlertType.YES_NO, __("CRYSTAL_NOT_ENOUGH"), function (yes)
				if yes then
					xyd.WindowManager.get():openWindow("vip_window")
				end
			end)
		else
			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					self.parent.activityData:setBuyID(self.id)
					xyd.models.activity:reqAwardWithParams(xyd.ActivityID.WELFARE_SALE, json.encode({
						award_id = self.id
					}))
				end
			end)
		end
	end
end

function ActivityWelfareSaleItem:updateTimeLabel()
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", 0)
end

function ActivityWelfareSaleItem:updateInfo()
	if self.id == self.data.id then
		return
	end

	self.id = self.data.id
	self.limit = self.data.limit
	self.point = self.data.point
	self.buy_time = self.parent.activityData.detail.buy_times[self.id]
	self.reqPoint = WelfareSaleTable:getRequirement(self.id)
	self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", self.limit - self.buy_time)
	local awards = WelfareSaleTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if self.point < self.reqPoint then
		xyd.setUISpriteAsync(self.buttonIcon, nil, "awake_lock")

		self.buttonIcon.width = 26
		self.buttonIcon.height = 30
		self.buttonLabel.text = __("WELFARE_LIMIT_NUM", self.point, self.reqPoint)
	else
		local cost = WelfareSaleTable:getCost(self.id)

		xyd.setUISpriteAsync(self.buttonIcon, nil, xyd.tables.itemTable:getSmallIcon(cost[1]))

		self.buttonIcon.width = 40
		self.buttonIcon.height = 40
		self.buttonLabel.text = cost[2]
	end

	if self.limit - self.buy_time <= 0 then
		self:setBtnState(false)
	else
		self:setBtnState(true)
	end
end

function ActivityWelfareSaleItem:setBtnState(flag)
	if flag then
		xyd.setEnabled(self.buyBtn_, true)
		xyd.applyOrigin(self.buttonIcon)
	else
		xyd.setEnabled(self.buyBtn_, false)
		xyd.applyGrey(self.buttonIcon)
	end
end

return ActivityWelfareSale
