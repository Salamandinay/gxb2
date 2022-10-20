local BaseWindow = import(".BaseWindow")
local SoulLandBattlePassBuyWindow = class("SoulLandBattlePassBuyWindow", BaseWindow)

function SoulLandBattlePassBuyWindow:ctor(name, params)
	SoulLandBattlePassBuyWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

	dump(self.activityData.detail, "self.activityData.detail")

	self.giftBagID = self.activityData.detail.charges[1].table_id
end

function SoulLandBattlePassBuyWindow:initWindow()
	SoulLandBattlePassBuyWindow.super.initWindow(self)
	self:getUIComponent()
	self:register()
	self:layout()
end

function SoulLandBattlePassBuyWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.vipLabel_ = winTrans:ComponentByName("vipLabel", typeof(UILabel))
	self.buyBtn_ = winTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = self.buyBtn_:ComponentByName("label", typeof(UILabel))
	self.title1_ = winTrans:ComponentByName("content1/title1", typeof(UILabel))
	self.itemList1_ = winTrans:ComponentByName("content1/itemList", typeof(UIGrid))
	self.itemIconRoot_ = winTrans:NodeByName("itemIcon").gameObject
end

function SoulLandBattlePassBuyWindow:register()
	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function SoulLandBattlePassBuyWindow:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= self.giftBagID then
		return
	end

	self:close()
end

function SoulLandBattlePassBuyWindow:layout()
	self.title1_.text = __("SOUL_LAND_BATTLEPASS_TEXT08")
	self.labelTips_.text = __("SOUL_LAND_BATTLEPASS_TEXT07")
	self.buyBtnLabel_.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID)
	self.vipLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID) .. " VIP EXP"
	local itemList = xyd.tables.soulLandBattlePassAwardsTable:getMergePaidAwards()

	for index, itemData in ipairs(itemList) do
		xyd.getItemIcon({
			notShowGetWayBtn = true,
			uiRoot = self.itemList1_.gameObject,
			itemID = itemData[1],
			num = itemData[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.itemList1_:Reposition()
end

return SoulLandBattlePassBuyWindow
