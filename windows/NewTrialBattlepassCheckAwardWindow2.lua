local BaseWindow = import(".BaseWindow")
local NewTrialBattlepassCheckAwardWindow2 = class("NewTrialBattlepassCheckAwardWindow2", BaseWindow)

function NewTrialBattlepassCheckAwardWindow2:ctor(name, params)
	NewTrialBattlepassCheckAwardWindow2.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_NEWTRIAL_BATTLE_PASS)
	self.giftBagID = self.activityData.detail.charges[1].table_id
	self.expNow_ = self.activityData.detail.point or 0
	self.index_ = self.activityData:getIndexChoose()
end

function NewTrialBattlepassCheckAwardWindow2:initWindow()
	NewTrialBattlepassCheckAwardWindow2.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:layout()
end

function NewTrialBattlepassCheckAwardWindow2:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.vipLabel_ = winTrans:ComponentByName("vipLabel", typeof(UILabel))
	self.buyBtn_ = winTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("label", typeof(UILabel))
	self.title1_ = winTrans:ComponentByName("content1/title1", typeof(UILabel))
	self.itemList1_ = winTrans:ComponentByName("content1/itemList", typeof(UIGrid))
	self.itemIconRoot_ = winTrans:NodeByName("itemIcon").gameObject
end

function NewTrialBattlepassCheckAwardWindow2:register()
	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function NewTrialBattlepassCheckAwardWindow2:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= 420 then
		return
	end

	self:close()
end

function NewTrialBattlepassCheckAwardWindow2:layout()
	local simpleItems = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(1)
	local simpleItem = simpleItems[self.index_]

	xyd.getItemIcon({
		showNum = false,
		notShowGetWayBtn = true,
		uiRoot = self.itemIconRoot_,
		itemID = simpleItem[1],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	self.title1_.text = __("NEW_TRIAL_BATTLEPASS_TEXT15")
	self.labelTips_.text = __("NEW_TRIAL_BATTLEPASS_TEXT16")
	self.buyBtnLabel_.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID)
	self.vipLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID) .. " VIP EXP"
	local ids = xyd.tables.newTrialBattlePassAwardsTable:getIDs()
	local awardList1 = {}

	for index, id in ipairs(ids) do
		local is_awarded = self.activityData.detail.awarded[id]
		local is_exawarded = self.activityData.detail.ex_awarded[id]
		local need_exp = xyd.tables.newTrialBattlePassAwardsTable:getExp(id)
		local freeAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeAwards(id)
		local freeOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getFreeOptionalAwards(id)
		local freeOpAward = freeOpAwards[self.index_]
		local paidAwards = xyd.tables.newTrialBattlePassAwardsTable:getPaidAwards(id)
		local paidOpAwards = xyd.tables.newTrialBattlePassAwardsTable:getPaidOptionalAwards(id)
		local paidOpAward = paidOpAwards[self.index_]

		if freeAwards and freeAwards[1] and freeAwards[1] > 0 then
			table.insert(awardList1, {
				item_id = freeAwards[1],
				item_num = freeAwards[2]
			})
		end

		table.insert(awardList1, {
			item_id = freeOpAward[1],
			item_num = freeOpAward[2]
		})
		table.insert(awardList1, {
			item_id = paidOpAward[1],
			item_num = paidOpAward[2]
		})

		for _, data in ipairs(paidAwards) do
			table.insert(awardList1, {
				item_id = data[1],
				item_num = data[2]
			})
		end
	end

	local itemList1 = self:getItemList(awardList1)

	for index, itemData in ipairs(itemList1) do
		xyd.getItemIcon({
			notShowGetWayBtn = true,
			uiRoot = self.itemList1_.gameObject,
			itemID = itemData.item_id,
			num = itemData.item_num,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.itemList1_:Reposition()
end

function NewTrialBattlepassCheckAwardWindow2:getItemList(items)
	local tmpData = {}

	for _, item in ipairs(items) do
		local itemID = item.item_id

		if tmpData[itemID] == nil then
			tmpData[itemID] = 0
		end

		tmpData[itemID] = tmpData[item.item_id] + item.item_num
	end

	local datas = {}

	for k, v in pairs(tmpData) do
		table.insert(datas, {
			item_id = tonumber(k),
			item_num = v
		})
	end

	table.sort(datas, function (a, b)
		return b.item_id < a.item_id
	end)

	return datas
end

return NewTrialBattlepassCheckAwardWindow2
