local BaseWindow = import(".BaseWindow")
local NewFirstRechargePopUpWindow = class("NewFirstRechargePopUpWindow", BaseWindow)
local NewFirstRechargeTable = xyd.tables.newFirstRechargeTable
local json = require("cjson")

function NewFirstRechargePopUpWindow:ctor(name, params)
	NewFirstRechargePopUpWindow.super.ctor(self, name, params)
end

function NewFirstRechargePopUpWindow:initWindow()
	self:getUIComponent()
	NewFirstRechargePopUpWindow.super.initWindow(self)
	xyd.setUITextureByNameAsync(self.imgText, "new_first_recharge_logo_" .. xyd.Global.lang)
	xyd.setUISpriteAsync(self.img_, nil, "ft_" .. xyd.Global.lang)

	self.descLabel.text = __("NEW_RECHARGE_TEXT01")
	self.previewLabel.text = __("NEW_RECHARGE_TEXT03")

	for i = 1, 3 do
		self.dayLabelList[i].text = __("ACTIVITY_WEEK_DATE", i)
	end

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)
	self.originCanAward = activityData.detail.can_award

	self:updateRed()
	self:updateStatus()
	self:setIcon()
	self:register()
end

function NewFirstRechargePopUpWindow:updateRed()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)
	local lastLoginDay = tonumber(xyd.db.misc:getValue("new_first_recharge_last_day")) or 0
	local nowDay = activityData:getLoginDay()

	if nowDay - lastLoginDay >= 1 then
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.NEW_FIRST_RECHARGE, function ()
			xyd.db.misc:setValue({
				key = "new_first_recharge_last_day",
				value = nowDay
			})
		end)
	end
end

function NewFirstRechargePopUpWindow:canGetAwards()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)
	local isAwards = activityData.detail.is_awarded
	local nowDay = math.min(activityData:getAwardDay(), 3)

	return isAwards[nowDay] == 0
end

function NewFirstRechargePopUpWindow:getUIComponent()
	local mainGroup = self.window_:NodeByName("groupAction/mainGroup").gameObject
	self.descLabel = mainGroup:ComponentByName("descLabel", typeof(UILabel))
	self.buyBtn = mainGroup:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.redPoint = self.buyBtn:NodeByName("redPoint").gameObject
	self.imgText = mainGroup:ComponentByName("imgText", typeof(UITexture))
	self.img_ = mainGroup:ComponentByName("img_", typeof(UISprite))
	self.partnerPreview = mainGroup:NodeByName("partnerPreview").gameObject
	self.previewLabel = self.partnerPreview:ComponentByName("previewLabel", typeof(UILabel))
	self.partnerPreviewBtn = self.partnerPreview:NodeByName("partnerPreviewBtn").gameObject
	self.closeBtn = mainGroup:NodeByName("closeBtn").gameObject
	local itemGroup = mainGroup:NodeByName("itemGroup").gameObject
	self.dayLabelList = {}
	self.iconGroupList = {}

	for i = 1, 3 do
		local item = itemGroup:NodeByName("item" .. i).gameObject
		local dayLabel = item:ComponentByName("dayLabel", typeof(UILabel))
		local iconGroup = item:NodeByName("iconGroup").gameObject

		table.insert(self.dayLabelList, dayLabel)
		table.insert(self.iconGroupList, iconGroup)
	end
end

function NewFirstRechargePopUpWindow:updateStatus()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)

	if activityData.detail.can_award == 0 then
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY
	elseif activityData.detail.is_awarded[3] == 0 then
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD
	else
		self.cur_status = xyd.FIRST_RECHARGE_BUTTON_STATUS.ALREADY_AWARD
	end

	self:setBtn()
end

function NewFirstRechargePopUpWindow:setBtn()
	if self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY then
		self.buyBtnLabel.text = __("BUY")

		xyd.setUISpriteAsync(self.buyBtn:GetComponent(typeof(UISprite)), nil, "mana_week_card_btn01")
	elseif self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD then
		self.buyBtnLabel.text = __("GET2")

		xyd.setUISpriteAsync(self.buyBtn:GetComponent(typeof(UISprite)), nil, "mana_week_card_btn01")

		if not self:canGetAwards() then
			xyd.applyGrey(self.buyBtn:GetComponent(typeof(UISprite)))
			self.buyBtnLabel:ApplyGrey()
		end
	else
		self.buyBtnLabel.text = __("ALREADY_GET_PRIZE")

		xyd.setUISpriteAsync(self.buyBtn:GetComponent(typeof(UISprite)), nil, "mana_week_card_btn01")
		xyd.applyGrey(self.buyBtn:GetComponent(typeof(UISprite)))
		self.buyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.buyBtn, false)
	end

	self.redPoint:SetActive(self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.CAN_AWARD and self:canGetAwards())
end

function NewFirstRechargePopUpWindow:setIcon()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)
	local nowDay = math.min(activityData:getAwardDay(), 3)
	local ids = NewFirstRechargeTable:getIDs()
	local isAwards = activityData.detail.is_awarded
	self.iconList = {}

	for i = 1, 3 do
		local id = ids[i]
		local awards = NewFirstRechargeTable:getAwards(id)
		local flag = isAwards[i] == 1
		local list = {}

		for j = 1, #awards do
			local item = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.9,
				uiRoot = self.iconGroupList[i],
				itemID = awards[j][1],
				num = awards[j][2]
			})

			item:setChoose(flag)
			table.insert(list, item)

			if activityData.detail.can_award == 1 and i <= nowDay and isAwards[i] == 0 then
				item:setEffect(true, "fx_ui_bp_available", {
					effectPos = Vector3(2, 7, 0)
				})
			else
				item:setEffect(false)
			end
		end

		table.insert(self.iconList, list)
	end
end

function NewFirstRechargePopUpWindow:register()
	NewFirstRechargePopUpWindow.super.register(self)

	UIEventListener.Get(self.partnerPreviewBtn).onClick = function ()
		xyd.openWindow("partner_info", {
			grade = 6,
			lev = 100,
			table_id = 56006
		})
	end

	UIEventListener.Get(self.buyBtn).onClick = handler(self, self.onClickBuyBtn)

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function NewFirstRechargePopUpWindow:onClickBuyBtn()
	if self.cur_status == xyd.FIRST_RECHARGE_BUTTON_STATUS.NEED_BUY then
		xyd.GiftbagPushController.get().isJumping = true

		xyd.WindowManager.get():closeWindow("new_first_recharge_pop_up_window")

		if xyd.models.activity:getActivity(xyd.ActivityID.NEW_LIMIT_FIVE_STAR_GIFTBAG) then
			xyd.WindowManager.get():clearStackWindow()
			xyd.WindowManager.get():openWindow("activity_window", {
				activity_type = xyd.EventType.COOL,
				select = xyd.ActivityID.NEW_LIMIT_FIVE_STAR_GIFTBAG
			}, function ()
				xyd.GiftbagPushController.get().isJumping = false
			end)
		else
			xyd.WindowManager.get():clearStackWindow()
			xyd.WindowManager.get():openWindow("activity_window", {
				activity_type = xyd.EventType.COOL
			}, function ()
				xyd.GiftbagPushController.get().isJumping = false
			end)
		end
	elseif self:canGetAwards() then
		xyd.models.activity:reqAward(xyd.ActivityID.NEW_FIRST_RECHARGE)
	else
		xyd.showToast(__("NEW_RECHARGE_TEXT12"))
	end
end

function NewFirstRechargePopUpWindow:onAward(event)
	if event.data.activity_id == xyd.ActivityID.NEW_FIRST_RECHARGE then
		local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)
		local awardsList = activityData.awardList
		local ids = NewFirstRechargeTable:getIDs()

		for i = 1, #awardsList do
			local awards = NewFirstRechargeTable:getAwards(ids[awardsList[i]])
			local items = {}

			for j = 1, #awards do
				table.insert(items, {
					item_id = awards[j][1],
					item_num = tonumber(awards[j][2])
				})
			end

			xyd.models.itemFloatModel:pushNewItems(items)

			for _, item in ipairs(self.iconList[awardsList[i]]) do
				item:setChoose(true)
				item:setEffect(false)
			end
		end

		if awardsList[3] == 1 and activityData:getLoginDay() <= 7 then
			local wnd = xyd.WindowManager.get():getWindow("main_window")

			wnd:CheckExtraActBtn(xyd.MAIN_LEFT_TOP_BTN_TYPE.NEWFIRSTRECHARGE)
		end

		self:updateStatus()
	end
end

function NewFirstRechargePopUpWindow:onRecharge()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.NEW_FIRST_RECHARGE)

	if activityData.detail.can_award == self.originCanAward then
		return
	end

	self:updateStatus()
end

function NewFirstRechargePopUpWindow:willOpen()
	NewFirstRechargePopUpWindow.super.willOpen(self)
end

function NewFirstRechargePopUpWindow:didClose()
	NewFirstRechargePopUpWindow.super.didClose(self)

	xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
end

return NewFirstRechargePopUpWindow
