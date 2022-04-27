local ActivityContent = import(".ActivityContent")
local ActivitySecretTreasureHuntGiftbag = class("ActivitySecretTreasureHuntGiftbag", ActivityContent)
local GiftbagItem = class("GiftbagItem", import("app.components.CopyComponent"))
local json = require("cjson")
local GiftBagTextTable = xyd.tables.giftBagTextTable

function ActivitySecretTreasureHuntGiftbag:ctor(parentGO, params, parent)
	ActivitySecretTreasureHuntGiftbag.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG, function ()
		xyd.db.misc:setValue({
			key = "secret_treasure_hunt_giftbag_view_time",
			value = xyd.getServerTime()
		})
	end)
end

function ActivitySecretTreasureHuntGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_secret_treasure_hunt_giftbag"
end

function ActivitySecretTreasureHuntGiftbag:initUI()
	self:getUIComponent()
	ActivitySecretTreasureHuntGiftbag.super.initUI(self)
	self:initUIComponent()
	self:initGroup()
end

function ActivitySecretTreasureHuntGiftbag:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.timeGroup = go:NodeByName("timeGroup").gameObject
	self.endLabel2_ = self.timeGroup:ComponentByName("endLabel2_", typeof(UILabel))
	self.timeLable_ = self.timeGroup:ComponentByName("timeLable_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.scroller_ = self.bottomGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = self.bottomGroup:NodeByName("scroller_/itemGroup").gameObject
	self.giftbag_item = go:NodeByName("giftbag_item").gameObject
	self.helpBtn_ = go:NodeByName("helpBtn_").gameObject
	self.resNum = go:ComponentByName("resItem/num", typeof(UILabel))
end

function ActivitySecretTreasureHuntGiftbag:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_secret_treasure_hunt_giftbag_text_" .. xyd.Global.lang)

	self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.COMPASS)
	local endTime = self.activityData:getEndTime()
	self.countdown = import("app.components.CountDown").new(self.timeLable_)

	if endTime - xyd.getServerTime() > xyd.TimePeriod.DAY_TIME * 7 then
		self.endLabel_.text = __("REFRESH")
		self.endLabel2_.text = __("REFRESH")

		self.countdown:setInfo({
			duration = endTime - xyd.getServerTime() - xyd.TimePeriod.DAY_TIME * 7
		})

		if xyd.Global.lang == "fr_fr" then
			self.endLabel_:SetActive(false)
			self.endLabel2_:SetActive(true)
			self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
		end
	else
		self.endLabel_.text = __("TEXT_END")

		self.countdown:setInfo({
			duration = endTime - xyd.getServerTime()
		})
	end
end

function ActivitySecretTreasureHuntGiftbag:initGroup()
	self.items = {}
	local passedTotalTime = xyd.getServerTime() - self.activityData:startTime()
	local round = math.ceil(passedTotalTime / xyd.TimePeriod.WEEK_TIME)
	local freeIDs = xyd.tables.activitySecretTreasureHuntGiftTable:getIds()

	for i = 1, #freeIDs do
		local tmpItem = NGUITools.AddChild(self.itemGroup.gameObject, self.giftbag_item)
		self.freeItem = GiftbagItem.new(tmpItem, self.scroller_, self)

		self.freeItem:setInfos({
			table_id = freeIDs[i],
			limit_times = round * 5,
			buy_times = self.activityData.detail.buy_times[1]
		}, true)
		xyd.setDragScrollView(self.freeItem.go, self.scroller_)
	end

	local charges = self.activityData.detail.charges

	table.sort(charges, function (a, b)
		local offsetA = a.limit_times - a.buy_times
		local offsetB = b.limit_times - b.buy_times

		if offsetA == 0 and offsetB == 0 then
			return b.table_id < a.table_id
		elseif offsetA == 0 or offsetB == 0 then
			return offsetB < offsetA
		else
			return b.table_id < a.table_id
		end
	end)

	for i = 1, #charges do
		local tmpItem = NGUITools.AddChild(self.itemGroup.gameObject, self.giftbag_item)
		self.items[i] = GiftbagItem.new(tmpItem, self.scroller_, self)

		self.items[i]:setInfos(charges[i], false)
		xyd.setDragScrollView(self.items[i].go, self.scroller_)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self:waitForTime(0.05, function ()
		self.scroller_:ResetPosition()
	end)
end

function ActivitySecretTreasureHuntGiftbag:onRegister()
	ActivitySecretTreasureHuntGiftbag.super.onRegister(self)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_SECTRETTREASURE_TEXT27"
		})
	end)

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self.resNum.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.COMPASS)
	end)
end

function ActivitySecretTreasureHuntGiftbag:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	for i = 1, #self.items do
		if self.items[i].table_id == giftbagID then
			self.items[i]:setButtonState(self.items[i].buy_times + 1)

			break
		end
	end
end

function ActivitySecretTreasureHuntGiftbag:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG then
		return
	end

	self.freeItem:setButtonState(self.freeItem.buy_times + self.freeBuyTimes)

	self.activityData.detail.buy_times[1] = self.activityData.detail.buy_times[1] + self.freeBuyTimes
	local awards = xyd.tables.activitySecretTreasureHuntGiftTable:getAward(1)
	local itemInfo = {}

	for i = 1, #awards do
		local award = awards[i]

		table.insert(itemInfo, {
			item_id = award[1],
			item_num = award[2] * self.freeBuyTimes
		})
	end

	xyd.itemFloat(itemInfo)
end

function ActivitySecretTreasureHuntGiftbag:resizeToParent()
	ActivitySecretTreasureHuntGiftbag.super.resizeToParent(self)
end

function GiftbagItem:ctor(go, scroller, parent)
	GiftbagItem.super.ctor(self, go)

	self.scroller = scroller
	self.parent = parent
end

function GiftbagItem:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.textLabel_ = go:ComponentByName("textLabel_", typeof(UILabel))
	self.vipLabel_ = go:ComponentByName("vipLabel_", typeof(UILabel))
	self.limitLabel_ = go:ComponentByName("limitLabel_", typeof(UILabel))
	self.buyBtn_ = go:NodeByName("buyBtn_").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.buyBtnIcon_ = self.buyBtn_:NodeByName("icon").gameObject

	self:initUIComponent()
end

function GiftbagItem:initUIComponent()
	self.textLabel_.text = "VIP EXP"
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onBuy)
end

function GiftbagItem:setInfos(params, isfree)
	self.isfree = isfree
	self.table_id = params.table_id
	self.buy_times = params.buy_times
	self.limit_times = params.limit_times

	if self.isfree then
		self.vipLabel_:SetActive(false)
		self.textLabel_:SetActive(false)

		local awards = xyd.tables.activitySecretTreasureHuntGiftTable:getAward(self.table_id)

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
					dragScrollView = self.scroller
				})
			end
		end

		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
		self:setButtonState(self.buy_times)

		local cost = xyd.tables.activitySecretTreasureHuntGiftTable:getCost(self.table_id)
		self.buyBtnLabel_.text = tostring(cost[2])

		self.buyBtnLabel_:X(10)
	else
		self.giftID = xyd.tables.giftBagTable:getGiftID(self.table_id)
		self.vipLabel_.text = "+" .. (xyd.tables.giftBagTable:getVipExp(self.table_id) or "0123")
		self.buyBtnLabel_.text = (GiftBagTextTable:getCurrency(self.table_id) or 0) .. " " .. (GiftBagTextTable:getCharge(self.table_id) or 0)
		local awards = xyd.tables.giftTable:getAwards(self.giftID) or {}

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
					dragScrollView = self.scroller
				})
			end
		end

		self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
		self:setButtonState(self.buy_times)
		self.buyBtnIcon_:SetActive(false)
	end
end

function GiftbagItem:setButtonState(buy_times)
	self.buy_times = buy_times

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn_, true)
	else
		xyd.setEnabled(self.buyBtn_, false)
	end

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)
end

function GiftbagItem:onBuy()
	if self.isfree then
		local cost = xyd.tables.activitySecretTreasureHuntGiftTable:getCost(self.table_id)

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.min(math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2]), self.limit_times - self.buy_times),
			show_max_num = math.floor(xyd.models.backpack:getItemNumByID(cost[1])),
			select_multiple = cost[2],
			icon_info = {
				height = 34,
				name = "icon_2",
				width = 34
			},
			title_text = __("BUY2"),
			explain_text = __("DAILY_QUIZ_BUY_DETAILS"),
			sure_callback = function (num)
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_SECRET_TREASURE_HUNT_GIFTBAG
				msg.params = json.encode({
					award_id = self.table_id,
					num = num
				})

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

				self.parent.freeBuyTimes = num
				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	else
		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

return ActivitySecretTreasureHuntGiftbag
