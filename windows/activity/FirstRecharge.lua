local ActivityContent = import(".ActivityContent")
local FirstRecharge = class("FirstRecharge", ActivityContent)
local CountDown = require("app.components.CountDown")

function FirstRecharge:ctor(parentGO, params, parent)
	self.skinName = "FirstRechargeSkin"

	ActivityContent.ctor(self, parentGO, params, parent)
end

function FirstRecharge:getPrefabPath()
	return "Prefabs/Windows/activity/first_recharge"
end

function FirstRecharge:getUIComponent()
	local go = self.go
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	local timeLabelNode = self.mainGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.timeLabel = CountDown.new(timeLabelNode)
	self.firstRechargeLabel = self.mainGroup:ComponentByName("firstRechargeLabel", typeof(UILabel))
	self.buyBtn = self.mainGroup:NodeByName("buyBtn").gameObject
	self.btnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = self.mainGroup:NodeByName("itemGroup").gameObject
	self.imgText01 = self.mainGroup:ComponentByName("imgText01", typeof(UISprite))
end

function FirstRecharge:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)

	self.activityID = self.activityData.id
	self.currentState = xyd.Global.lang

	self:layout()
end

function FirstRecharge:layout()
	xyd.setUISpriteAsync(self.imgText01, nil, "first_recharge_text01_" .. xyd.Global.lang, nil, , true)
	self:setIcon()

	if self:retTime() > 0 then
		self.timeLabel:setCountDownTime(self:retTime())
	end

	self:updateStatus()
end

function FirstRecharge:onRegister()
	ActivityContent.onRegister(self)
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))

	UIEventListener.Get(self.buyBtn).onClick = handler(self, self.onTouchBuyBtn)
end

function FirstRecharge:resizeToParent()
	ActivityContent.resizeToParent(self)

	if xyd.Global.getRealHeight() < xyd.Global.getMaxHeight() then
		self.mainGroup:Y(-374)
	end

	if xyd.lang == "en_en" then
		self.imgText01:Y(90)
	elseif xyd.lang == "fr_fr" then
		self.imgText01:Y(70)
	elseif xyd.lang == "de_de" then
		self.imgText01:Y(82)
	end
end

function FirstRecharge:updateStatus()
	if self.activityData.detail.is_awarded == 0 and self.activityData.detail.can_award == 0 then
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY
	elseif self.activityData.detail.can_award == 1 and self.activityData.detail.is_awarded == 0 then
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD
	else
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.ALREADY_AWARD
	end

	self:setBtn()
	self:setText()
end

function FirstRecharge:setBtn()
	local ret_time = self:retTime()

	if self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY then
		self.btnLabel.text = __("BUY")
	elseif self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD then
		self.btnLabel.text = __("GET_PRIZE")
	elseif self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.ALREADY_AWARD then
		self.btnLabel.text = __("ALREADY_GET_PRIZE")
	end

	if ret_time < 0 or self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.ALREADY_AWARD then
		xyd.applyChildrenGrey(self.buyBtn)
		xyd.setTouchEnable(self.buyBtn, false)
	end
end

function FirstRecharge:setText()
	self.firstRechargeLabel.text = __("FIRST_RECHARGE_TEXT01")

	if xyd.Global.lang == "de_de" then
		self.firstRechargeLabel.fontSize = 18
		self.firstRechargeLabel.width = 298
	elseif xyd.Global.lang == "fr_fr" then
		self.firstRechargeLabel.fontSize = 17
		self.firstRechargeLabel.width = 310
	end

	if self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.ALREADY_AWARD then
		self.timeLabel:setCountDownTime(1)

		local win = xyd.WindowManager.get():getWindow("activity_window")

		if win then
			win:setTitleTimeLabel(self.id, 0, 1)
		end
	end
end

function FirstRecharge:setIcon()
	local awards = xyd.tables.miscTable:split2Cost("first_charge_awards", "value", "|#")
	local cur_cnt = 0

	for i = 1, #awards do
		local cur_data = awards[i]

		if cur_data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.8981481481481481

			if cur_cnt ~= 0 then
				scale = 0.7037037037037037
			end

			local item = {
				show_has_num = true,
				itemID = cur_data[1],
				num = cur_data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.itemGroup,
				scale = scale
			}
			local icon = xyd.getItemIcon(item)
			cur_cnt = cur_cnt + 1
		end
	end
end

function FirstRecharge:onRecharge(evt)
	if self.activityData.detail.is_awarded == 1 then
		return
	end

	self:updateStatus()
end

function FirstRecharge:onTouchBuyBtn(evt)
	if self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY then
		xyd.WindowManager.get():openWindow("vip_window")
	elseif self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD then
		xyd.models.activity:reqAward(xyd.ActivityID.FIRST_RECHARGE)
	end
end

function FirstRecharge:onActivityAward(evt)
	self:updateStatus()

	local items = {}
	local awards = xyd.tables.miscTable:split2Cost("first_charge_awards", "value", "|#")

	for i = 1, #awards do
		table.insert(items, {
			item_id = awards[i][1],
			item_num = awards[i][2]
		})
	end

	self:itemFloat(items)
end

function FirstRecharge:retTime()
	local cur_time = xyd.getServerTime()

	return self.activityData:getUpdateTime() - cur_time
end

return FirstRecharge
