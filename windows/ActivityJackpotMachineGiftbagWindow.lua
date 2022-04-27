local BaseWindow = import(".BaseWindow")
local ActivityJackpotMachineGiftbagWindow = class("ActivityJackpotMachineGiftbagWindow", BaseWindow)
local GiftbagItem = class("GiftbagItem", import("app.components.CopyComponent"))
local json = require("cjson")

function ActivityJackpotMachineGiftbagWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.JACKPOT_MACHINE)
	self.items = {}
end

function ActivityJackpotMachineGiftbagWindow:initWindow()
	self:getUIComponent()
	ActivityJackpotMachineGiftbagWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityJackpotMachineGiftbagWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.groupMain = self.groupAction:NodeByName("groupMain").gameObject
	self.specialGroup = self.groupMain:NodeByName("specialGroup").gameObject
	self.labelSpecial = self.specialGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.specialScoller = self.specialGroup:ComponentByName("scoller", typeof(UIScrollView))
	self.specialAwards = self.specialScoller:NodeByName("awardGroup").gameObject
	self.normalGroup = self.groupMain:NodeByName("normalGroup").gameObject
	self.labelNormal = self.normalGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.normalScoller = self.normalGroup:ComponentByName("scoller", typeof(UIScrollView))
	self.normalAwards = self.normalScoller:NodeByName("awardGroup").gameObject
	self.giftbag_item = winTrans:NodeByName("giftbag_item").gameObject
end

function ActivityJackpotMachineGiftbagWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_JACKPOT_GIFTBAG_TITLE")
	self.labelSpecial.text = __("ACTIVITY_JACKPOT_GIFTBAG_TEXT01")
	self.labelNormal.text = __("ACTIVITY_JACKPOT_GIFTBAG_TEXT02")
	local privilegeCardGiftID = xyd.tables.miscTable:getNumber("activity_jackpot_gift", "value")
	self.privilegeCardGiftIndex = 1

	for i = 1, #self.activityData.detail.charges do
		if self.activityData.detail.charges[i].table_id == privilegeCardGiftID then
			self.privilegeCardGiftIndex = i

			break
		end
	end

	local specialItemGo = NGUITools.AddChild(self.specialAwards.gameObject, self.giftbag_item)
	local specialItem = GiftbagItem.new(specialItemGo, self, self.specialScoller)

	specialItem:setInfo({
		is_special = true,
		is_free = false,
		table_id = self.activityData.detail.charges[self.privilegeCardGiftIndex].table_id,
		limit_times = self.activityData.detail.charges[self.privilegeCardGiftIndex].limit_times,
		buy_times = self.activityData.detail.charges[self.privilegeCardGiftIndex].buy_times,
		index = self.privilegeCardGiftIndex
	})
	xyd.setDragScrollView(specialItemGo, self.specialScoller)
	table.insert(self.items, specialItem)

	local normalInfos = {}
	local freeIDs = xyd.tables.activityJackpotExchangeTable:getIDs()

	for i = 1, #freeIDs do
		table.insert(normalInfos, {
			is_special = false,
			is_free = true,
			table_id = freeIDs[i],
			limit_times = xyd.tables.activityJackpotExchangeTable:getLimit(freeIDs[i]),
			buy_times = self.activityData.detail.buy_times[freeIDs[i]],
			index = i
		})
	end

	dump(self.activityData.detail.charges)

	for i = 1, #self.activityData.detail.charges do
		if privilegeCardGiftID ~= self.activityData.detail.charges[i].table_id then
			table.insert(normalInfos, {
				is_special = false,
				is_free = false,
				table_id = self.activityData.detail.charges[i].table_id,
				limit_times = self.activityData.detail.charges[i].limit_times,
				buy_times = self.activityData.detail.charges[i].buy_times,
				index = i
			})
		end
	end

	table.sort(normalInfos, function (a, b)
		local offsetA = a.limit_times - a.buy_times
		local offsetB = b.limit_times - b.buy_times

		if offsetA == 0 and offsetB ~= 0 or offsetA ~= 0 and offsetB == 0 then
			return offsetB < offsetA
		elseif a.is_free ~= b.is_free then
			return a.is_free
		else
			return b.table_id < a.table_id
		end
	end)

	for i = 1, #normalInfos do
		local normalItemGo = NGUITools.AddChild(self.normalAwards.gameObject, self.giftbag_item)
		local normalItem = GiftbagItem.new(normalItemGo, self, self.normalScoller)

		normalItem:setInfo(normalInfos[i])
		xyd.setDragScrollView(normalItemGo, self.normalScoller)
		table.insert(self.items, normalItem)
	end

	self.specialAwards:GetComponent(typeof(UILayout)):Reposition()
	self.normalAwards:GetComponent(typeof(UILayout)):Reposition()
	self.specialScoller:ResetPosition()
	self.normalScoller:ResetPosition()
end

function ActivityJackpotMachineGiftbagWindow:register()
	BaseWindow.register(self)

	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function ()
		self:updateItems()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		self:updateItems()
	end)
end

function ActivityJackpotMachineGiftbagWindow:updateItems()
	for i = 1, #self.items do
		local item = self.items[i]

		item:updateState(item.is_free and self.activityData.detail.buy_times[item.index] or self.activityData.detail.charges[item.index].buy_times)
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

		local cost = xyd.tables.activityJackpotExchangeTable:getCost(self.table_id)
		self.buyBtnLabel.text = tostring(cost[2])
	else
		self.buyBtnIcon:SetActive(false)
		self.buyBtnLabel:X(0)
	end

	if self.is_free then
		local awards = xyd.tables.activityJackpotExchangeTable:getAwards(self.table_id)

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

				if award[1] == xyd.ItemID.JACKPOT_PRIVILEGE_CARD then
					icon:setEffect(true, "fx_ui_bp_available")
				end
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
end

function GiftbagItem:onBuy()
	if self.is_free then
		local cost = xyd.tables.activityJackpotExchangeTable:getCost(self.table_id)

		if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = math.min(self.limit_times - self.buy_times, math.floor(xyd.models.backpack:getItemNumByID(cost[1]) / cost[2])),
			show_max_num = xyd.models.backpack:getItemNumByID(cost[1]),
			select_multiple = cost[2],
			icon_info = {
				height = 34,
				width = 34,
				name = "icon_" .. cost[1]
			},
			title_text = __("ACTIVITY_JACKPOT_MACHINE_GIFTBAG_BUY_TITLE"),
			explain_text = __("ACTIVITY_JACKPOT_MACHINE_GIFTBAG_BUY_TEXT"),
			sure_callback = function (num)
				xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
					if yes then
						local msg = messages_pb.get_activity_award_req()
						msg.activity_id = xyd.ActivityID.JACKPOT_MACHINE
						msg.params = json.encode({
							award_type = 2,
							award_id = self.table_id,
							num = num
						})

						xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)

						local common_use_cost_window = xyd.WindowManager.get():getWindow("common_use_cost_window")

						if common_use_cost_window then
							xyd.WindowManager.get():closeWindow("common_use_cost_window")
						end
					end
				end)
			end
		})
	else
		xyd.SdkManager.get():showPayment(self.table_id)
	end
end

return ActivityJackpotMachineGiftbagWindow
