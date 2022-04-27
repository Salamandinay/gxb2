local ActivityLafuliDriftGiftbag = class("ActivityLafuliDriftGiftbag", import(".ActivityContent"))
local CountDown = require("app.components.CountDown")

function ActivityLafuliDriftGiftbag:ctor(parentGo, params, parent)
	ActivityLafuliDriftGiftbag.super.ctor(self, parentGo, params, parent)
end

function ActivityLafuliDriftGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/lafuli_drift_giftbag"
end

function ActivityLafuliDriftGiftbag:initUI()
	self:getUIComponent()
	ActivityLafuliDriftGiftbag.super.initUI(self)
	xyd.setUITextureByNameAsync(self.imgText, "activity_lafuli_giftbag_logo_" .. xyd.Global.lang)
	self:initText()
	self:updateState()
	self:setIcon()
end

function ActivityLafuliDriftGiftbag:resizeToParent()
	ActivityLafuliDriftGiftbag.super.resizeToParent(self)

	local widget = self.go:GetComponent(typeof(UIWidget))

	self.textGroup:Y(386.8 - 0.66 * widget.height)
	self.mainGroup:Y(-0.6 * widget.height - 77.6)
end

function ActivityLafuliDriftGiftbag:getUIComponent()
	local go = self.go
	self.textGroup = go:NodeByName("textGroup").gameObject
	self.imgText = self.textGroup:ComponentByName("imgText", typeof(UITexture))
	self.timeGroup = self.textGroup:NodeByName("timeGroup").gameObject
	self.timeLabel = self.textGroup:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.endLabel = self.textGroup:ComponentByName("timeGroup/endLabel", typeof(UILabel))
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.buyBtn = self.mainGroup:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.iconGroup1 = self.mainGroup:NodeByName("iconGroup1").gameObject
	self.iconGroup2 = self.mainGroup:NodeByName("iconGroup2").gameObject
	self.dumpLabel = self.mainGroup:ComponentByName("dumpIcon/dumpLabel", typeof(UILabel))
	self.dumpLabelNum = self.mainGroup:ComponentByName("dumpIcon/dumpLabelNum", typeof(UILabel))
	self.expLabel = self.mainGroup:ComponentByName("expLabel", typeof(UILabel))
	self.limitLabel = self.mainGroup:ComponentByName("limitLabel", typeof(UILabel))
end

function ActivityLafuliDriftGiftbag:initText()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.expLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(giftbagID) .. " VIP EXP"
	self.buyBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbagID)
	self.dumpLabel.text = __("ACTIVITY_WARMUP_PACK_TEXT05")
	self.dumpLabelNum.text = "[size=20]+[size=28]" .. __("LAFULI_GIFTBAG_TEXT")
	self.endLabel.text = __("END")

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.timeGroup:X(-7)

		self.timeLabel.fontSize = 16
		self.endLabel.fontSize = 16
	elseif xyd.Global.lang == "ja_jp" then
		self.timeGroup:X(-10)
	end

	if xyd.Global.lang == "fr_fr" then
		self.endLabel.transform:SetSiblingIndex(0)
		self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
	end
end

function ActivityLafuliDriftGiftbag:updateState()
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

function ActivityLafuliDriftGiftbag:setIcon()
	local giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	local giftID = xyd.tables.giftBagTable:getGiftID(giftbagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)
	local countAward = 0

	for i = 1, #awards do
		local iconGroup = self.iconGroup1

		if countAward >= 2 then
			iconGroup = self.iconGroup2
		end

		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.8518518518518519

			xyd.getItemIcon({
				show_has_num = true,
				uiRoot = iconGroup,
				itemID = award[1],
				num = award[2],
				scale = scale
			})

			countAward = countAward + 1
		end
	end

	self.iconGroup1:GetComponent(typeof(UILayout)):Reposition()
	self.iconGroup2:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityLafuliDriftGiftbag:onRegister()
	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(xyd.tables.activityTable:getGiftBag(self.id)[1])
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityLafuliDriftGiftbag:onRecharge(evt)
	local giftBagID = evt.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	self:updateState()
end

return ActivityLafuliDriftGiftbag
