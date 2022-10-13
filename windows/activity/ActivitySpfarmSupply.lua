local ActivityContent = import(".ActivityContent")
local ActivitySpfarmSupply = class("ActivitySpfarmSupply", ActivityContent)
local SupplyItem = class("SupplyItem", import("app.components.CopyComponent"))
local GiftBagTextTable = xyd.tables.giftBagTextTable

function ActivitySpfarmSupply:ctor(parentGO, params, parent)
	ActivitySpfarmSupply.super.ctor(self, parentGO, params, parent)
end

function ActivitySpfarmSupply:getPrefabPath()
	return "Prefabs/Windows/activity/activity_spfarm_giftbag"
end

function ActivitySpfarmSupply:initUI()
	self:getUIComponent()
	ActivitySpfarmSupply.super.initUI(self)
	self:initUIComponent()
	self:initGroup()
end

function ActivitySpfarmSupply:getUIComponent()
	local go = self.go
	self.textImg_ = go:ComponentByName("textImg_", typeof(UISprite))
	self.middleGroup = go:NodeByName("middleGroup").gameObject
	self.textLabel01_ = self.middleGroup:ComponentByName("textLabel01_", typeof(UILabel))
	self.itemNode1 = self.middleGroup:NodeByName("itemNode1").gameObject
	self.itemTips1 = self.middleGroup:ComponentByName("itemTips1", typeof(UILabel))
	self.itemNode2 = self.middleGroup:NodeByName("itemNode2").gameObject
	self.itemTips2 = self.middleGroup:ComponentByName("itemTips2", typeof(UILabel))
	self.itemNode3 = self.middleGroup:NodeByName("itemNode3").gameObject
	self.textLabel_ = self.middleGroup:ComponentByName("vipGroup/textLabel_", typeof(UILabel))
	self.vipLabel_ = self.middleGroup:ComponentByName("vipGroup/vipLabel_", typeof(UILabel))
	self.limitLabel_ = self.middleGroup:ComponentByName("limitLabel_", typeof(UILabel))
	self.buyBtn_ = self.middleGroup:NodeByName("buyBtn_").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.tipLabel_ = self.middleGroup:ComponentByName("tipGroup/tipLabel_", typeof(UILabel))
	self.bottomGroup = go:NodeByName("bottomGroup").gameObject
	self.timeGroup = self.bottomGroup:NodeByName("timeGroup").gameObject
	self.endLabel2_ = self.timeGroup:ComponentByName("endLabel2_", typeof(UILabel))
	self.timeLable_ = self.timeGroup:ComponentByName("timeLable_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.scroller_ = self.bottomGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = self.bottomGroup:NodeByName("scroller_/itemGroup").gameObject
	self.supply_item = self.bottomGroup:NodeByName("scroller_/supply_item").gameObject
	self.helpBtn_ = go:NodeByName("helpBtn_").gameObject
end

function ActivitySpfarmSupply:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "activity_spfarm_giftbag_text_" .. xyd.Global.lang)

	self.textLabel01_.text = __("ACTIVITY_SPFARM_TEXT99")
	self.tipLabel_.text = __("ACTIVITY_SPFARM_BATTLEPASS_TEXT07")

	if xyd.Global.lang == "fr_fr" then
		self.tipLabel_.width = 80
		self.tipLabel_.height = 80
	end

	self.itemTips1.text = __("ACTIVITY_SPFARM_TEXT90")

	if xyd.Global.lang == "en_en" then
		self.itemTips1.fontSize = 20
	end

	self.itemTips2.text = __("ACTIVITY_SPFARM_TEXT91")
	local endTime = self.activityData:getEndTime()
	self.countdown = import("app.components.CountDown").new(self.timeLable_)

	if endTime - xyd.getServerTime() > xyd.TimePeriod.DAY_TIME * 7 then
		self.endLabel_.text = __("REFRESH")
		self.endLabel2_.text = __("REFRESH")

		self.countdown:setInfo({
			duration = endTime - xyd.getServerTime() - xyd.TimePeriod.DAY_TIME * 7
		})
		xyd.db.misc:setValue({
			value = "1",
			key = "activity_space_explore_supply_redpoint_1"
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
		xyd.db.misc:setValue({
			value = "1",
			key = "activity_space_explore_supply_redpoint_2"
		})
	end
end

function ActivitySpfarmSupply:initGroup()
	self.items = {}
	local charges = self.activityData.detail.charges
	local special = 438

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

	local dailyAward = xyd.split(xyd.tables.miscTable:getVal("activity_spfarm_gift_daily"), "#")
	self.textLabel_.text = "VIP EXP"

	xyd.getItemIcon({
		show_has_num = true,
		scale = 0.7037037037037037,
		uiRoot = self.itemNode1,
		itemID = dailyAward[1],
		num = dailyAward[2]
	})

	for i = 1, #charges do
		local parentGO, flag = nil

		if charges[i].table_id == special then
			local table_id = charges[i].table_id
			self.buy_times = charges[i].buy_times
			self.limit_times = charges[i].limit_times
			local giftID = xyd.tables.giftBagTable:getGiftID(table_id)
			self.vipLabel_.text = "+" .. (xyd.tables.giftBagTable:getVipExp(table_id) or "0123")
			self.buyBtnLabel_.text = (GiftBagTextTable:getCurrency(table_id) or 0) .. " " .. (GiftBagTextTable:getCharge(table_id) or 0)
			local awards = xyd.tables.giftTable:getAwards(giftID) or {}

			for i = 1, #awards do
				local award = awards[i]
				local type = xyd.tables.itemTable:getType(award[1])
				local itemID = award[1]
				local iconType = nil
				local itemRoot = self.itemNode2

				if i >= 4 then
					itemRoot = self.itemNode3
				end

				if award[1] ~= xyd.ItemID.VIP_EXP then
					local item = xyd.getItemIcon({
						show_has_num = true,
						scale = 0.5555555555555556,
						uiRoot = itemRoot,
						itemID = itemID,
						num = award[2]
					}, iconType)
				end
			end

			local duringDay = math.modf((xyd.getServerTime() - self.activityData:startTime()) / xyd.DAY_TIME)

			if duringDay >= 1 and self.limit_times - self.buy_times > 0 then
				local spcailItem = xyd.getItemIcon({
					show_has_num = true,
					scale = 0.5555555555555556,
					uiRoot = self.itemNode3,
					itemID = dailyAward[1],
					num = dailyAward[2] * duringDay
				})

				spcailItem:setAddText(__("ACTIVITY_SPFARM_TEXT92"), 1.8)
			end

			if self.buy_times < self.limit_times then
				xyd.setEnabled(self.buyBtn_, true)
			else
				xyd.setEnabled(self.buyBtn_, false)
			end

			self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)
		else
			parentGO = self.itemGroup
			flag = true
			local tmpItem = NGUITools.AddChild(parentGO, self.supply_item)
			self.items[i] = SupplyItem.new(tmpItem, self.scroller_)

			self.items[i]:setInfos(charges[i], not flag)

			if flag then
				xyd.setDragScrollView(self.items[i].go, self.scroller_)
			end
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(special)
	end
end

function ActivitySpfarmSupply:onRegister()
	ActivitySpfarmSupply.super.onRegister(self)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_SPFARM_TEXT100"
		})
	end)
end

function ActivitySpfarmSupply:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	if giftbagID == 438 then
		self.buy_times = self.buy_times + 1

		if self.buy_times < self.limit_times then
			xyd.setEnabled(self.buyBtn_, true)
		else
			xyd.setEnabled(self.buyBtn_, false)
		end

		self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)
	end

	for i = 1, #self.items do
		if self.items[i].table_id == giftbagID then
			self.items[i]:setButtonState(self.items[i].buy_times + 1)

			break
		end
	end
end

function ActivitySpfarmSupply:resizeToParent()
	ActivitySpfarmSupply.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.textImg_:Y(-105 - (p_height - 874) * 0.25)
	self.middleGroup:Y(-300 - (p_height - 874) * 0.55)
	self.bottomGroup:Y(-640 - (p_height - 874) * 0.7)

	if xyd.Global.lang == "ja_jp" then
		self.tipLabel_:X(4)
	end
end

function SupplyItem:ctor(go, scroller)
	SupplyItem.super.ctor(self, go)

	self.scroller = scroller
end

function SupplyItem:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.textLabel_ = go:ComponentByName("textLabel_", typeof(UILabel))
	self.vipLabel_ = go:ComponentByName("vipLabel_", typeof(UILabel))
	self.limitLabel_ = go:ComponentByName("limitLabel_", typeof(UILabel))
	self.buyBtn_ = go:NodeByName("buyBtn_").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))

	self:initUIComponent()
end

function SupplyItem:initUIComponent()
	self.textLabel_.text = "VIP EXP"
	UIEventListener.Get(self.buyBtn_).onClick = handler(self, self.onBuy)
end

function SupplyItem:setInfos(params, isSpectial)
	self.table_id = params.table_id
	self.buy_times = params.buy_times
	self.limit_times = params.limit_times
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.table_id)
	self.vipLabel_.text = "+" .. (xyd.tables.giftBagTable:getVipExp(self.table_id) or "0123")
	self.buyBtnLabel_.text = (GiftBagTextTable:getCurrency(self.table_id) or 0) .. " " .. (GiftBagTextTable:getCharge(self.table_id) or 0)
	local awards = xyd.tables.giftTable:getAwards(self.giftID) or {}

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local award = awards[i]
		local type = xyd.tables.itemTable:getType(award[1])
		local itemID = award[1]
		local iconType = nil

		if type == xyd.ItemType.ACTIVITY_SPACE_EXPLORE then
			iconType = xyd.ItemIconType.ACTIVITY_SPACE_EXPLORE_ICON
			itemID = xyd.tables.miscTable:getNumber("adventure_giftbag_limit_partner", "value")
		end

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.7037037037037037,
				uiRoot = self.itemGroup,
				itemID = itemID,
				num = award[2],
				dragScrollView = self.scroller
			}, iconType)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
	self:setButtonState(self.buy_times)

	if isSpectial then
		self.bg_:SetActive(false)
	else
		self.bg_:SetActive(true)
	end
end

function SupplyItem:setButtonState(buy_times)
	self.buy_times = buy_times

	if self.buy_times < self.limit_times then
		xyd.setEnabled(self.buyBtn_, true)
	else
		xyd.setEnabled(self.buyBtn_, false)
	end

	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.limit_times - self.buy_times)
end

function SupplyItem:onBuy()
	xyd.SdkManager.get():showPayment(self.table_id)
end

return ActivitySpfarmSupply
