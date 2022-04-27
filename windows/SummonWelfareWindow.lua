local BaseWindow = import(".BaseWindow")
local SummonWelfareWindow = class("SummonWelfareWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local GiftBagTable = xyd.tables.giftBagTable
local json = require("cjson")

function SummonWelfareWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.items = {}
	self.currentState = xyd.Global.lang
	self.pushParmas = params
	self.giftbagID = tonumber(params.giftbag_id)
	self.activityID = tonumber(params.activity_id)
end

function SummonWelfareWindow:initWindow()
	SummonWelfareWindow.super.initWindow(self)
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_INFO_BY_ID, handler(self, self.listen))

	local data = xyd.models.activity:getActivity(xyd.ActivityID.SUMMON_WELFARE)

	if data == nil then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.SUMMON_WELFARE)

		return
	end

	self.data = data

	self:getDetail()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function SummonWelfareWindow:listen(event)
	self.data = xyd.models.activity:getActivity(xyd.ActivityID.SUMMON_WELFARE)

	self:getDetail()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function SummonWelfareWindow:getDetail()
	local giftbagId = self.pushParmas.giftbag_id

	if #self.data.detail > 1 then
		for i = 1, #self.data.detail do
			if self.data.detail[i].table_id == giftbagId then
				self.detail = self.data.detail[i]

				break
			end
		end
	else
		self.detail = self.data.detail
	end
end

function SummonWelfareWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.titleImg = self.groupAction:ComponentByName("titleImg", typeof(UISprite))
	self.timerLabel = self.groupAction:ComponentByName("timerLabel", typeof(UILabel))
	self.infoLabel = self.groupAction:ComponentByName("infoLabel", typeof(UILabel))
	self.purchaseGroup = self.groupAction:NodeByName("purchaseGroup").gameObject
	self.purchaseBtn = self.purchaseGroup:ComponentByName("btn", typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseGroup:ComponentByName("btn", typeof(UnityEngine.BoxCollider))
	self.purchaseBtn_button_label = self.purchaseGroup:ComponentByName("btn/label", typeof(UILabel))
	self.limitLabel = self.purchaseGroup:ComponentByName("limitLabel", typeof(UILabel))
	self.vipLabel = self.purchaseGroup:ComponentByName("vipLabel", typeof(UILabel))
	self.coinNum = self.purchaseGroup:ComponentByName("coinNum", typeof(UILabel))
	self.touchField = self.groupAction:NodeByName("touchField").gameObject
end

function SummonWelfareWindow:layout()
	if xyd:getServerTime() < self:getUpdateTime() then
		local countdown = CountDown.new(self.timerLabel, {
			duration = self:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timerLabel:SetActive(false)
	end

	xyd.setUISpriteAsync(self.titleImg, nil, "summon_welfare_text01_" .. tostring(xyd.Global.lang), nil, , true)

	self.infoLabel.text = __("ACTIVITY_PROPEL_GACHA")
	self.vipLabel.text = "+" .. tostring(GiftBagTable:getVipExp(self.giftbagID)) .. " VIP EXP"
	self.coinNum.text = "x" .. tostring(xyd.tables.giftTable:getAwards(self.giftbagID)[2][2])
	self.purchaseBtn_button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagID))
	local limit = GiftBagTable:getBuyLimit(self.giftbagID)
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - self.detail.buy_times))

	if limit <= self.detail.buy_times then
		self:btnSetGrey()
	end
end

function SummonWelfareWindow:getUpdateTime()
	local updateTime = nil

	return self.detail.update_time + GiftBagTable:getLastTime(self.giftbagID)
end

function SummonWelfareWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))

	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftbagID)
	end)
	UIEventListener.Get(self.touchField).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function SummonWelfareWindow:onRecharge(event)
	local giftbagId = event.data.giftbag_id
	local limit = GiftBagTable:getBuyLimit(giftbagId)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.SUMMON_WELFARE)

	if limit <= activityData.detail.buy_times then
		self:btnSetGrey()
	end

	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", tostring(limit - activityData.detail.buy_times))
end

function SummonWelfareWindow:btnSetGrey()
	xyd.applyGrey(self.purchaseBtn)
	xyd.setTouchEnable(self.purchaseBtn.gameObject, false)
end

return SummonWelfareWindow
