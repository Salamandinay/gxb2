local ActivityContent = import(".ActivityContent")
local ActivityMonthly = class("ActivityMonthly", ActivityContent)
local CountDown = import("app.components.CountDown")
local ActivityMonthlyItem = class("ActivityMonthlyItem", import("app.components.CopyComponent"))

function ActivityMonthly:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.items_ = {}
	self.ui_complete_ = false
	self.data_complete_ = false

	self:getUIComponent()
	self:euiComplete()
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		if self.activityData.id ~= xyd.ActivityID.ACTIVITY_MONTHLY then
			return
		end

		self.data_complete_ = true

		self:update()
	end)

	local msg = messages_pb:get_activity_info_by_id_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_MONTHLY

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)
end

function ActivityMonthly:getPrefabPath()
	return "Prefabs/Windows/activity/activity_monthly"
end

function ActivityMonthly:getUIComponent()
	local go = self.go
	self.bgImg = go:ComponentByName("e:Image", typeof(UISprite))
	local itemBg = go:ComponentByName("itemBg", typeof(UISprite))
	self.e_Scroller = go:NodeByName("e:Scroller").gameObject
	self.e_Scroller_scrollerView = self.e_Scroller:GetComponent(typeof(UIDragScrollView))
	self.e_Scroller_uiPanel = self.e_Scroller:GetComponent(typeof(UIPanel))
	self.e_Scroller_uiPanel.depth = self.e_Scroller_uiPanel.depth + 1
	self.itemGroup = self.e_Scroller:NodeByName("itemGroup").gameObject
	self.itemGroup_uigrid = self.itemGroup:GetComponent(typeof(UIGrid))
	self.timeLabel = go:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = go:ComponentByName("endLabel", typeof(UILabel))
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.purchaseBtn = go:NodeByName("purchaseBtn").gameObject
	self.purchaseBtn_button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.purchaseBtn_uiSprite = self.purchaseBtn:GetComponent(typeof(UISprite))
	self.purchaseBtn_boxCollider = self.purchaseBtn:GetComponent(typeof(UnityEngine.BoxCollider))
	self.discountPart = self.purchaseBtn:NodeByName("discountPart").gameObject
	self.labelDiscount = self.discountPart:ComponentByName("labelDiscount", typeof(UILabel))
	self.labelOff = self.discountPart:ComponentByName("labelOff", typeof(UILabel))
	self.originPrice = self.purchaseBtn:ComponentByName("originPrice", typeof(UILabel))
	self.eRect = self.purchaseBtn:NodeByName("e:Rect").gameObject
	self.vipLabel = go:ComponentByName("vipLabel", typeof(UILabel))
	self.textLabel = go:ComponentByName("e:Group/textLabel", typeof(UILabel))
	self.activity_monthly_item = go:NodeByName("activity_monthly_item").gameObject
end

function ActivityMonthly:euiComplete()
	self.giftbagID = xyd.tables.activityTable:getGiftBag(self.id)[1]

	if xyd.models.activity:getActivity(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT) then
		self.giftbagID = xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)[2]
	end

	self.ui_complete_ = true

	xyd.setUISpriteAsync(self.bgImg, nil, "activity_monthly_bg01")
	xyd.setUISpriteAsync(self.textImg, nil, "activity_monthly_text01_" .. tostring(xyd.Global.lang), nil, , true)

	self.vipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftbagID) .. " VIP EXP"
	self.textLabel.text = __("ACTIVITY_MONTHLY_TEXT01")

	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
		self.endLabel.text = __("END_TEXT")
	else
		self.endLabel:SetActive(false)
		self.timeLabel:SetActive(false)
	end

	if xyd.Global.lang == "de_de" then
		self.endLabel:X(200)
		self.timeLabel:X(190)

		self.textLabel.width = 380
		self.textLabel.spacingY = 5
	elseif xyd.Global.lang == "fr_fr" or xyd.Global.lang == "en_en" then
		self.originPrice.fontSize = 16

		self.originPrice:X(3)
	end

	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		local params = {
			key = "ACTIVITY_MONTHLY_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end)
	UIEventListener.Get(self.purchaseBtn.gameObject).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftbagID)
	end)

	self.eventProxyInner_:addEventListener(xyd.event.RECHARGE, self.onRecharge, self)

	if self.giftbagID == xyd.tables.activityTable:getGiftBag(xyd.ActivityID.ACTIVIYT_RETURN_PRIVILEGE_DISCOUNT)[2] then
		self.purchaseBtn_button_label:Y(13)

		self.purchaseBtn_button_label.text = xyd.tables.giftBagTextTable:getCurrency(self.giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagID)

		self.discountPart:SetActive(true)
		self.originPrice:SetActive(true)
		self.eRect:SetActive(true)

		self.labelDiscount.text = "80%"
		self.labelOff.text = "OFF"
		self.originPrice.text = __("ACTIVITY_RETURN2_ADD_TEXT12")
	else
		self.discountPart:SetActive(false)
		self.originPrice:SetActive(false)
		self.eRect:SetActive(false)

		self.purchaseBtn_button_label.text = __("ACTIVITY_MONTHLY_TEXT03", xyd.tables.giftBagTextTable:getCurrency(self.giftbagID) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftbagID))
	end
end

function ActivityMonthly:onRecharge(event)
	local giftbagID = event.data.giftbag_id

	if giftbagID ~= self.giftbagID then
		return
	end

	self:updateExtra(true)
end

function ActivityMonthly:update()
	if not self.ui_complete_ or not self.data_complete_ then
		return
	end

	self:initItem()
	self:updateBtn(self:getHasExtra())
end

function ActivityMonthly:initItem()
	local ids = xyd.tables.activityMonthlyTable:getIDs()
	local list = {}
	local allItem = {}
	local specialTime = xyd.tables.miscTable:getVal("new_trial_restart_open_time")

	for i, v in pairs(ids) do
		local id = ids[i]

		if self:getIsAward(id) and self:getIsAward(id) >= 0 then
			local params = {
				id = id,
				value = self:getValue(id),
				is_award = self:getIsAward(id),
				has_extra = self:getHasExtra()
			}

			if id ~= 7 or xyd.getServerTime() >= tonumber(specialTime) then
				if id == 5 then
					-- Nothing
				elseif self:getIsAward(id) then
					table.insert(list, params)
				else
					table.insert(allItem, params)
				end
			end
		end
	end

	for i, v in pairs(list) do
		table.insert(allItem, v)
	end

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i in ipairs(allItem) do
		local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.activity_monthly_item.gameObject)
		local item = ActivityMonthlyItem.new(tmp, allItem[i])

		table.insert(self.items_, item)
	end

	self.activity_monthly_item:SetActive(false)
	self.itemGroup_uigrid:Reposition()
end

function ActivityMonthly:getValue(id)
	return self.activityData.detail.points[id]
end

function ActivityMonthly:getIsAward(id)
	return self.activityData.detail.awarded[id]
end

function ActivityMonthly:getHasExtra()
	return self.activityData.detail.ex_buy
end

function ActivityMonthly:updateExtra(flag)
	if flag ~= true and flag ~= false then
		flag = xyd.checkCondition(flag == 0, false, true)
	end

	for i, v in pairs(self.items_) do
		self.items_[i]:updateExtra(flag)
	end

	self:updateBtn(flag)
end

function ActivityMonthly:updateBtn(flag)
	if flag ~= true and flag ~= false then
		flag = xyd.checkCondition(flag == 0, false, true)
	end

	self.purchaseBtn_boxCollider.enabled = not flag

	if flag then
		xyd.applyChildrenGrey(self.purchaseBtn)
	end
end

function ActivityMonthly:dispose()
	ActivityMonthly.super.dispose(self)
end

function ActivityMonthlyItem:ctor(goItem, params)
	self.goItem_ = goItem
	self.transGo = goItem.transform
	self.items_ = {}
	self.extra_items_ = {}
	self.id_ = params.id
	self.is_award_ = xyd.checkCondition(params.is_award == 0, false, true)
	self.value_ = params.value
	self.has_extra_ = xyd.checkCondition(params.has_extra == 0, false, true)

	self:getUIComponent()
	self:createChildren()
end

function ActivityMonthlyItem:getUIComponent()
	self.bgImg = self.transGo:ComponentByName("bgImg", typeof(UITexture))

	xyd.setUITextureAsync(self.bgImg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01")

	self.line = self.transGo:ComponentByName("e:Image", typeof(UISprite))
	self.textLabel = self.transGo:ComponentByName("textLabel", typeof(UILabel))
	self.itemGroup = self.transGo:NodeByName("itemGroup").gameObject
	self.itemGroup_uiLayout = self.itemGroup:GetComponent(typeof(UILayout))
	self.descLabel = self.transGo:ComponentByName("descLabel", typeof(UILabel))
	self.countLabel = self.transGo:ComponentByName("countLabel", typeof(UILabel))
end

function ActivityMonthlyItem:createChildren()
	self.textLabel.text = xyd.tables.activityMonthlyTextTable:getText(self.id_)
	self.descLabel.text = __("ACTIVITY_MONTHLY_TEXT007")
	local limitValue = xyd.tables.activityMonthlyTable:getValue(self.id_)

	if self.is_award_ then
		self.value_ = limitValue
	end

	self.countLabel.text = "" .. tostring(self.value_) .. "/" .. tostring(xyd.tables.activityMonthlyTable:getValue(self.id_))

	self:initItem()

	self.itemGroup_uiLayout.enabled = true
end

function ActivityMonthlyItem:initItem()
	local items = xyd.tables.activityMonthlyTable:getAwards(self.id_)
	local extra_items = xyd.tables.activityMonthlyTable:getExtraAwards(self.id_)

	for i, v in pairs(items) do
		local data = items[i]
		local item = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			itemID = data[1],
			num = data[2],
			uiRoot = self.itemGroup.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.75, 0.75, 1)
		})

		item:setChoose(self.is_award_)
		table.insert(self.items_, item)
	end

	for i, v in pairs(extra_items) do
		local data = extra_items[i]
		local item = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			uiRoot = self.itemGroup.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			scale = Vector3(0.75, 0.75, 1)
		})

		dump(self.has_extra_)
		item:setChoose(self.is_award_ and self.has_extra_)
		item:setLock(not self.has_extra_)
		item:setMask(not self.has_extra_ or self.is_award_ and self.has_extra_)
		table.insert(self.extra_items_, item)
	end
end

function ActivityMonthlyItem:updateExtra(flag)
	if flag ~= true and flag ~= false then
		flag = xyd.checkCondition(flag == 0, false, true)
	end

	for i in pairs(self.extra_items_) do
		local item = self.extra_items_[i]

		item:setLock(not flag)
	end
end

return ActivityMonthly
