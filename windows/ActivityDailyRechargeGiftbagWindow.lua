local BaseWindow = import(".BaseWindow")
local ActivityDailyRechargeGiftbagWindow = class("ActivityDailyRechargeGiftbagWindow", BaseWindow)
local GiftbagItem = class("GiftbagItem", import("app.components.CopyComponent"))
local json = require("cjson")
local dabaoBuytimes = 0
local smallBuytimes = 0

function ActivityDailyRechargeGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_DAILY_RECHARGE)
	self.items = {}
end

function ActivityDailyRechargeGiftbagWindow:initWindow()
	self:getUIComponent()
	ActivityDailyRechargeGiftbagWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityDailyRechargeGiftbagWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.normalGroup = self.groupMain:NodeByName("normalGroup").gameObject
	self.normalScoller = self.normalGroup:ComponentByName("scoller", typeof(UIScrollView))
	self.normalAwards = self.normalScoller:NodeByName("awardGroup").gameObject
	self.giftbag_item = winTrans:NodeByName("giftbag_item").gameObject
	self.bottom = self.groupAction:NodeByName("bottom").gameObject
	self.vipLabel = self.bottom:ComponentByName("vipLabel", typeof(UILabel))
	self.buyBtn = self.bottom:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.giftbagLabel = self.buyBtn:ComponentByName("giftbagLabel", typeof(UILabel))
	self.dumpIcon = self.bottom:ComponentByName("dumpIcon", typeof(UISprite))
	self.labelText = self.dumpIcon:ComponentByName("labelText", typeof(UILabel))
	self.labelNum = self.dumpIcon:ComponentByName("labelNum", typeof(UILabel))
end

function ActivityDailyRechargeGiftbagWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_PAY_DAY_TEXT09")
	self.labelText.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT09")
	self.labelNum.text = __("ACTIVITY_PAY_DAY_TEXT08")
	self.table_id = self.activityData.detail.charges[#self.activityData.detail.charges].table_id
	self.buy_times = self.activityData.detail.charges[#self.activityData.detail.charges].buy_times
	self.limit_times = self.activityData.detail.charges[#self.activityData.detail.charges].limit_times
	self.vipLabel.text = "VIP EXP +" .. (xyd.tables.giftBagTable:getVipExp(self.table_id) or "0123")
	self.buyBtnLabel.text = (xyd.tables.giftBagTextTable:getCurrency(self.table_id) or 0) .. " " .. (xyd.tables.giftBagTextTable:getCharge(self.table_id) or 0)
	self.giftbagLabel.text = __("ACTIVITY_PAY_DAY_TEXT06")
	dabaoBuytimes = self.buy_times

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn, true)

		for i = 1, #self.activityData.detail.charges - 1 do
			if self.activityData.detail.charges[i].limit_times <= self.activityData.detail.charges[i].buy_times then
				xyd.setEnabled(self.buyBtn, false)

				break
			end
		end
	else
		xyd.setEnabled(self.buyBtn, false)
	end

	local privilegeCardGiftID = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVITY_DAILY_RECHARGE)
	local normalInfos = {}

	table.insert(normalInfos, {
		is_special = false,
		limit_times = 1,
		index = 1,
		is_free = true,
		table_id = 0,
		buy_times = self.activityData.detail.free_times
	})

	for i = 1, #self.activityData.detail.charges - 1 do
		local buyTimes = self.activityData.detail.charges[i].buy_times

		if self.activityData.detail.charges[#self.activityData.detail.charges].buy_times ~= 0 then
			buyTimes = self.activityData.detail.charges[i].limit_times
		end

		smallBuytimes = smallBuytimes + buyTimes

		if privilegeCardGiftID ~= self.activityData.detail.charges[i].table_id then
			table.insert(normalInfos, {
				is_special = false,
				is_free = false,
				table_id = self.activityData.detail.charges[i].table_id,
				limit_times = self.activityData.detail.charges[i].limit_times,
				buy_times = buyTimes,
				index = i
			})
		end
	end

	for i = 1, #normalInfos do
		local normalItemGo = NGUITools.AddChild(self.normalAwards.gameObject, self.giftbag_item)
		local normalItem = GiftbagItem.new(normalItemGo, self, self.normalScoller)

		normalItem:setInfo(normalInfos[i])
		xyd.setDragScrollView(normalItemGo, self.normalScoller)
		table.insert(self.items, normalItem)
	end

	self.normalAwards:GetComponent(typeof(UILayout)):Reposition()
	self.normalScoller:ResetPosition()
end

function ActivityDailyRechargeGiftbagWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function ()
		smallBuytimes = smallBuytimes + 1

		self:updateItems()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateItems()
	end)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

function ActivityDailyRechargeGiftbagWindow:updateItems()
	self.buy_times = self.activityData.detail.charges[#self.activityData.detail.charges].buy_times
	self.limit_times = self.activityData.detail.charges[#self.activityData.detail.charges].limit_times
	dabaoBuytimes = self.buy_times

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn, true)

		for i = 1, #self.activityData.detail.charges - 1 do
			if self.activityData.detail.charges[i].limit_times <= self.activityData.detail.charges[i].buy_times then
				xyd.setEnabled(self.buyBtn, false)

				break
			end
		end
	else
		xyd.setEnabled(self.buyBtn, false)
	end

	for i = 1, #self.items do
		local item = self.items[i]

		if item.is_free == false then
			item:updateState(self.activityData.detail.charges[item.index].buy_times)
		else
			item:updateState(self.activityData.detail.free_times)
		end
	end
end

function GiftbagItem:ctor(go, parent, scroller)
	GiftbagItem.super.ctor(self, go)

	self.parent = parent
	self.scroller = scroller
end

function GiftbagItem:initUI()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.textLabel = self.go:ComponentByName("textLabel", typeof(UILabel))
	self.vipLabel = self.go:ComponentByName("vipLabel", typeof(UILabel))
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
	self.buyBtn = self.go:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.buyBtnIcon = self.buyBtn:NodeByName("icon").gameObject
	self.redPoint = self.buyBtn:NodeByName("redPoint").gameObject
	UIEventListener.Get(self.buyBtn).onClick = handler(self, self.onBuy)
end

function GiftbagItem:setInfo(params)
	self.table_id = params.table_id
	self.buy_times = params.buy_times
	self.limit_times = params.limit_times
	self.is_free = params.is_free
	self.is_special = params.is_special
	self.index = params.index

	if self.is_free then
		self.vipLabel:SetActive(false)
		self.textLabel:SetActive(false)
		self.limitLabel:SetActive(false)
		self.buyBtnIcon:SetActive(false)

		self.buyBtnLabel.text = __("ACTIVITY_PAY_DAY_TEXT04")

		self.buyBtn:Y(-8)
	else
		self.buyBtnIcon:SetActive(false)
		self.buyBtnLabel:X(0)
	end

	if self.is_free then
		local awards = xyd.tables.miscTable:split2Cost("activity_pay_day_free_awards", "value", "|#")

		NGUITools.DestroyChildren(self.itemGroup.transform)

		for i = 1, #awards do
			local award = awards[i]

			xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = award[1],
				num = award[2],
				dragScrollView = self.scroller
			})
		end

		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

		if self.buy_times == 0 then
			self.redPoint:SetActive(true)
		end
	else
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.table_id)
		self.vipLabel.text = "+" .. (xyd.tables.giftBagTable:getVipExp(self.table_id) or "0123")
		self.buyBtnLabel.text = (xyd.tables.giftBagTextTable:getCurrency(self.table_id) or 0) .. " " .. (xyd.tables.giftBagTextTable:getCharge(self.table_id) or 0)
		local awards = xyd.tables.giftTable:getAwards(self.giftID) or {}

		NGUITools.DestroyChildren(self.itemGroup.transform)

		for i = 1, #awards do
			local award = awards[i]

			if award[1] ~= xyd.ItemID.VIP_EXP then
				local icon = xyd.getItemIcon({
					show_has_num = true,
					scale = 0.7037037037037037,
					uiRoot = self.itemGroup,
					itemID = award[1],
					num = award[2],
					dragScrollView = self.scroller
				})
			end
		end

		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	end

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)
end

function GiftbagItem:updateState(buy_times)
	self.buy_times = buy_times

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)

	if self.is_free then
		if self.buy_times ~= 0 then
			self.redPoint:SetActive(false)
		end
	elseif dabaoBuytimes ~= 0 then
		xyd.setEnabled(self.buyBtn, false)
	end
end

function GiftbagItem:onBuy()
	if self.is_free then
		local data = require("cjson").encode({
			type = 2
		})
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_DAILY_RECHARGE
		msg.params = data

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	elseif smallBuytimes == 0 then
		xyd.alert(xyd.AlertType.YES_NO, __("ACTIVITY_PAY_DAY_TEXT07"), function (flag)
			if flag then
				xyd.SdkManager.get():showPayment(self.table_id)
			end
		end)
	else
		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

return ActivityDailyRechargeGiftbagWindow
