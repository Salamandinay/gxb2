local ActivityLostSpaceGiftBag = class("ActivityLostSpaceGiftBag", import(".ActivityContent"))
local CountDown = require("app.components.CountDown")

function ActivityLostSpaceGiftBag:ctor(parentGo, params, parent)
	ActivityLostSpaceGiftBag.super.ctor(self, parentGo, params, parent)
end

function ActivityLostSpaceGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_lost_space_giftbag"
end

function ActivityLostSpaceGiftBag:initUI()
	self:getUIComponent()
	ActivityLostSpaceGiftBag.super.initUI(self)
	xyd.setUISpriteAsync(self.imgText, nil, "activity_lost_space_giftbag_logo_" .. xyd.Global.lang)
	self:initText()
	self:updateState()
	self:setIcon()
end

function ActivityLostSpaceGiftBag:resizeToParent()
	ActivityLostSpaceGiftBag.super.resizeToParent(self)
end

function ActivityLostSpaceGiftBag:getUIComponent()
	local go = self.go
	self.imgText = go:ComponentByName("imgText_", typeof(UISprite))
	self.mainGroup = go:NodeByName("contentGroup").gameObject
	self.buyBtn = self.mainGroup:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.itemGroup2 = self.mainGroup:NodeByName("itemGroup2").gameObject
	self.expLabel = self.mainGroup:ComponentByName("expLabel", typeof(UILabel))
	self.limitLabel = self.mainGroup:ComponentByName("limitLabel", typeof(UILabel))
end

function ActivityLostSpaceGiftBag:initText()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.expLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(giftbagID) .. " VIP EXP"
	self.buyBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbagID)
end

function ActivityLostSpaceGiftBag:updateState()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	local buyTimes = self.activityData.detail.charges[1].buy_times
	local leftTimes = xyd.tables.giftBagTable:getBuyLimit(giftbagID) - buyTimes
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", leftTimes)

	if leftTimes > 0 then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end
end

function ActivityLostSpaceGiftBag:setIcon()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	local giftID = xyd.tables.giftBagTable:getGiftID(giftbagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)
	local countAward = 0

	for i = 1, #awards do
		local scale = 0.7962962962962963

		if countAward ~= 1 then
			scale = 0.6018518518518519
		end

		local itemRoot = self.itemGroup

		if countAward >= 3 then
			itemRoot = self.itemGroup2
		end

		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				uiRoot = itemRoot,
				itemID = award[1],
				num = award[2],
				scale = scale
			})

			countAward = countAward + 1
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityLostSpaceGiftBag:onRegister()
	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(xyd.tables.activityTable:getGiftBag(self.id)[1])
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityLostSpaceGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:updateState()
end

return ActivityLostSpaceGiftBag
