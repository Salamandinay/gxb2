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
	self:resizePosY(self.imgText.gameObject, 80, -8)
	self:resizePosY(self.imgBg2, -488, -558)
	self:resizePosY(self.mainGroup, -725, -795)
	self:resizePosY(self.imgBg3_, -297, -368)
end

function ActivityLostSpaceGiftBag:getUIComponent()
	local go = self.go
	self.imgBg2 = go:NodeByName("imgBg2_").gameObject
	self.imgBg3_ = go:NodeByName("imgBg3_").gameObject
	self.imgText = go:ComponentByName("imgText_", typeof(UISprite))
	self.giftbagIcon = go:NodeByName("imgBg3_/giftbagIcon").gameObject
	self.effectRoot_ = self.giftbagIcon:NodeByName("effectRoot").gameObject
	self.tipsLabel_ = go:ComponentByName("imgBg3_/giftLabel", typeof(UILabel))
	self.labelTips_ = go:ComponentByName("imgBg3_/labelTips", typeof(UILabel))
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
	self.tipsLabel_.text = __("ACTIVITY_LOST_SPACE_TEXT07")
	self.labelTips_.text = __("ACTIVITY_LOST_SPACE_TEXT06")

	if leftTimes > 0 then
		xyd.setEnabled(self.buyBtn, true)
	else
		xyd.setEnabled(self.buyBtn, false)
	end

	self.effect = xyd.Spine.new(self.effectRoot_)

	self.effect:setInfo("fx_act_icon_2", function ()
		self.effect:play("texiao01", 0, 1)
	end)
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

	UIEventListener.Get(self.giftbagIcon).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_lost_space_award_new_window", {
			activityID = xyd.ActivityID.ACTIVITY_LOST_SPACE_GIFTBAG
		})
	end
end

function ActivityLostSpaceGiftBag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:updateState()
end

return ActivityLostSpaceGiftBag
