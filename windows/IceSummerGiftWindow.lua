local BaseWindow = import("app.windows.BaseWindow")
local IceSummerGiftWindow = class("IceSummerGiftWindow", BaseWindow)

function IceSummerGiftWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.count = xyd.models.activity:getActivity(xyd.ActivityID.ICE_SUMMER).detail.charges[1].buy_times
end

function IceSummerGiftWindow:initWindow()
	IceSummerGiftWindow.super:initWindow()

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.limit = self.groupAction:ComponentByName("limitLabel", typeof(UILabel))
	self.vip = self.groupAction:ComponentByName("vipLabel", typeof(UILabel))
	self.itemGroup1 = self.groupAction:NodeByName("itemGroup1").gameObject
	self.itemGroup2 = self.groupAction:NodeByName("itemGroup2").gameObject
	self.layout1 = self.groupAction:ComponentByName("itemGroup1", typeof(UILayout))
	self.layout2 = self.groupAction:ComponentByName("itemGroup2", typeof(UILayout))
	self.purchase = self.groupAction:NodeByName("purchaseBtn").gameObject
	self.purchaseLabel = self.purchase:ComponentByName("button_label", typeof(UILabel))
	self.mask = self.groupAction:NodeByName("mask").gameObject

	self.mask:SetActive(false)

	self.table_id_ = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ICE_SUMMER)[1]

	self:layout()
	self:RegisterEvent()
end

function IceSummerGiftWindow:layout()
	self.vip.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.table_id_)) .. " VIP EXP"
	self.limit.text = __("BUY_GIFTBAG_LIMIT") .. tostring(xyd.tables.giftBagTable:getBuyLimit(self.table_id_) - self.count)
	self.purchaseLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.table_id_) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.table_id_))

	if tonumber(xyd.tables.giftBagTable:getBuyLimit(self.table_id_) - self.count) == 0 then
		xyd.applyChildrenGrey(self.purchase)
		xyd.setTouchEnable(self.purchase, false)
		self.mask:SetActive(true)
	end

	local awards = xyd.tables.giftTable:getAwards(xyd.tables.giftBagTable:getGiftID(self.table_id_))
	local scalexy = 0.6

	for i in ipairs(awards) do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local params = {}

			if xyd.tables.itemTable:getType(data[1]) == xyd.ItemType.AVATAR_FRAME or data[1] == xyd.ItemID.ICE_SUMMER_COIN then
				params = {
					show_has_num = true,
					itemID = data[1],
					num = data[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self.itemGroup1,
					scale = Vector3(0.8, 0.8, 1)
				}
			else
				params = {
					show_has_num = true,
					itemID = data[1],
					num = data[2],
					wndType = xyd.ItemTipsWndType.ACTIVITY,
					uiRoot = self.itemGroup2,
					scale = Vector3(scalexy, scalexy, 1)
				}
			end

			local icon = xyd.getItemIcon(params)
		end
	end

	XYDCo.WaitForFrame(1, function ()
		self.layout1:Reposition()
		self.layout2:Reposition()
	end, nil)
end

function IceSummerGiftWindow:RegisterEvent()
	UIEventListener.Get(self.purchase).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.table_id_)
	end)

	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, function ()
		self.count = xyd.models.activity:getActivity(xyd.ActivityID.ICE_SUMMER).detail.charges[1].buy_times

		self:layout()
	end))
end

return IceSummerGiftWindow
