local FoudGiftbagPushWindow = class("FoudGiftbagPushWindow", import(".BaseWindow"))

function FoudGiftbagPushWindow:ctor(name, params)
	FoudGiftbagPushWindow.super.ctor(self, name, params)

	self.push_list_ = params or {}
end

function FoudGiftbagPushWindow:initWindow()
	FoudGiftbagPushWindow.super.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self:updateLayout()
end

function FoudGiftbagPushWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.touchGroup = self.window_:NodeByName("groupAction/touchGroup").gameObject
	local conTrans = self.window_:NodeByName("groupAction/groupContent")
	self.Bg1_ = conTrans:ComponentByName("Bg1_", typeof(UITexture))
	self.Bg2_ = conTrans:ComponentByName("Bg2_", typeof(UITexture))
	self.imgTitle_ = conTrans:ComponentByName("imgTitle_", typeof(UISprite))
	self.imgPageNum_ = conTrans:ComponentByName("imgPageNum_", typeof(UISprite))
	self.label1_ = conTrans:ComponentByName("label1_", typeof(UILabel))
	self.label2_ = conTrans:ComponentByName("label2_", typeof(UILabel))
	self.icon1_ = conTrans:ComponentByName("icon1_", typeof(UITexture))
	self.icon2_ = conTrans:ComponentByName("icon2_", typeof(UISprite))
	self.itemScroll = conTrans:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = conTrans:NodeByName("scroller/itemGroup").gameObject
	self.buyBtn = conTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = conTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.groupCrystal = conTrans:NodeByName("groupCrystal").gameObject
	local groupGain = self.groupCrystal:NodeByName("groupGain").gameObject
	self.gainText_ = groupGain:ComponentByName("imgText", typeof(UISprite))
	self.gainNum_ = groupGain:NodeByName("groupNum").gameObject
	local groupTotal = self.groupCrystal:NodeByName("groupTotal").gameObject
	self.totalText_ = groupTotal:ComponentByName("imgText", typeof(UISprite))
	self.totalNum_ = groupTotal:NodeByName("groupNum").gameObject
	self.numCell = self.groupCrystal:ComponentByName("numCell", typeof(UISprite))
end

function FoudGiftbagPushWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:updateLayout()
	end)

	UIEventListener.Get(self.touchGroup).onClick = function ()
		self:checkClose()
	end
end

function FoudGiftbagPushWindow:updateLayout()
	if not self.push_list_[1] then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	local data = xyd.models.activity:getActivity(self.push_list_[1].activity_id)

	if not data then
		xyd.models.activity:reqActivityByID(self.push_list_[1].activity_id)
	else
		self.cur_push_ = self.push_list_[1]

		table.remove(self.push_list_, 1)

		local activity_id = self.cur_push_.activity_id
		local giftbag_id = self.cur_push_.giftbag_id

		if activity_id == xyd.ActivityID.LEVEL_FUND then
			self.type_ = xyd.POPUP_STATE.LEVEL_FOUND

			self:setLevelFoudUIComponent()
		elseif activity_id == xyd.ActivityID.TOWER_FUND_GIFTBAG then
			self.type_ = xyd.POPUP_STATE.TOWER_FOUND

			self:setTowerFoudUIComponent(giftbag_id)
		end
	end
end

function FoudGiftbagPushWindow:setLevelFoudUIComponent()
	xyd.setUITextureByNameAsync(self.Bg1_, "level_foud_giftbag_bg1", true)
	xyd.setUITextureByNameAsync(self.Bg2_, "level_foud_giftbag_bg2", true)
	xyd.setUISpriteAsync(self.icon2_, nil, "level_fund_bg2")
	xyd.setUISpriteAsync(self.imgTitle_, nil, "level_fund_text_" .. xyd.Global.lang, nil, , true)

	self.buyBtnLabel.text = __("NEW_RECHARGE_TEXT08")
	self.label1_.text = __("NEW_RECHARGE_TEXT07")
	self.label1_.fontSize = 22
	self.label1_.color = Color.New2(4294967295.0)
	self.label2_.text = __("NEW_RECHARGE_PUSH_TEXT01", xyd.tables.activityLevelUpTable:getTotalAwardNum())
	self.label2_.fontSize = 24
	self.label2_.color = Color.New2(4294093567.0)
	self.label2_.effectStyle = UILabel.Effect.Outline8
	self.label2_.effectColor = Color.New2(1529358591)

	self.Bg1_:Y(300)
	self.Bg2_:SetLocalPosition(-5, -160, 0)
	self.imgTitle_:Y(45)

	self.label1_.width = 520

	self.label1_:Y(-30)
	self.label2_:Y(-290)
	self.buyBtn:Y(-395)
	self.itemGroup:SetActive(false)
	self.imgPageNum_:SetActive(false)
	self.label2_:SetActive(false)
	self.groupCrystal:SetActive(true)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		local select = xyd.ActivityID.LEVEL_FUND
		local data = xyd.models.activity:getActivity(select)

		if not data then
			xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

			return
		end

		xyd.WindowManager.get():closeWindow(self.name_, function ()
			xyd.openWindow("activity_window", {
				activity_type2 = 3,
				select = select
			})
		end)
	end

	if xyd.Global.lang == "en_en" then
		self.label1_:Y(-35)
	elseif xyd.Global.lang == "fr_fr" then
		self.label1_:Y(-30)
		self.imgPageNum_:SetLocalPosition(180, 30, 0)
	end

	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.LEVEL_FUND)

	if activityData.detail.charges[1].limit_times <= activityData.detail.charges[1].buy_times then
		xyd.setUISpriteAsync(self.gainText_, nil, "level_fund_gain_" .. xyd.Global.lang, nil, , true)
	else
		xyd.setUISpriteAsync(self.gainText_, nil, "level_fund_addup_" .. xyd.Global.lang, nil, , true)
	end

	xyd.setUISpriteAsync(self.totalText_, nil, "level_fund_total_" .. xyd.Global.lang, nil, , true)

	local gainNum = 0
	local totalNum = 0
	local selfLevel = xyd.models.backpack:getLev()
	local ids = xyd.tables.activityLevelUpTable:getIds()

	for i, id in ipairs(ids) do
		local level = xyd.tables.activityLevelUpTable:getLevel(id)
		local award = xyd.tables.activityLevelUpTable:getRewards(id)

		if level <= selfLevel then
			gainNum = gainNum + award[2]
		end

		totalNum = totalNum + award[2]
	end

	gainNum = tostring(gainNum)
	totalNum = tostring(totalNum)

	for i = 1, string.len(gainNum) do
		local num = string.sub(gainNum, i, i)
		local go = NGUITools.AddChild(self.gainNum_.gameObject, self.numCell.gameObject)

		xyd.setUISpriteAsync(go:GetComponent(typeof(UISprite)), nil, "level_fund_num" .. num, nil, , true)
	end

	for i = 1, string.len(totalNum) do
		local num = string.sub(totalNum, i, i)
		local go = NGUITools.AddChild(self.totalNum_.gameObject, self.numCell.gameObject)

		xyd.setUISpriteAsync(go:GetComponent(typeof(UISprite)), nil, "level_fund_num" .. num, nil, , true)
	end

	self.gainNum_:GetComponent(typeof(UILayout)):Reposition()
	self.totalNum_:GetComponent(typeof(UILayout)):Reposition()
end

function FoudGiftbagPushWindow:setTowerFoudUIComponent(giftbag_id)
	local level_ = xyd.tables.activityTowerFundGiftBagTable:getLevelByGiftbagID(giftbag_id)

	xyd.setUITextureByNameAsync(self.Bg1_, "tower_foud_giftbag_bg1", true)
	xyd.setUITextureByNameAsync(self.Bg2_, "tower_foud_giftbag_bg2", true)
	xyd.setUITextureByNameAsync(self.icon1_, "tower_foud_giftbag_divide", true)

	if level_ == 1 then
		self.imgPageNum_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.imgTitle_, nil, "tower_fund_giftbag_logo_" .. xyd.Global.lang, nil, , true)
	else
		self.imgPageNum_.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.imgTitle_, nil, "tower_fund_giftbag_logo_" .. xyd.Global.lang .. "2", nil, , true)
		xyd.setUISpriteAsync(self.imgPageNum_, nil, "activity_sports_num_" .. level_)
	end

	self.buyBtnLabel.text = __("NEW_RECHARGE_TEXT08")
	self.label1_.text = __("NEW_RECHARGE_TEXT09")
	self.label1_.fontSize = 24
	self.label1_.color = Color.New2(2234264831.0)
	self.label2_.text = __("NEW_RECHARGE_TEXT10")
	self.label2_.fontSize = 22
	self.label2_.color = Color.New2(2739775743.0)
	self.label2_.effectStyle = UILabel.Effect.None

	self.Bg1_:Y(160)
	self.Bg2_:SetLocalPosition(-15, -140, 0)
	self.imgTitle_:Y(40)

	self.label1_.width = 480

	self.label1_:Y(-50)
	self.label2_:Y(-120)
	self.icon1_:Y(-120)
	self.buyBtn:Y(-365)
	NGUITools.DestroyChildren(self.itemGroup.transform)
	self.itemGroup:SetActive(true)

	local totalAwards = xyd.tables.activityTowerFundGiftBagTable:getTotalAwards(level_)
	local scale = 1
	local layout = self.itemGroup:GetComponent(typeof(UILayout))

	if level_ >= 5 then
		scale = 0.8
		layout.gap = Vector2(20, 0)
	end

	for k, v in pairs(totalAwards) do
		local item = xyd.getItemIcon({
			show_has_num = true,
			uiRoot = self.itemGroup,
			itemID = tonumber(k),
			num = v,
			scale = scale
		})

		xyd.setDragScrollView(item.go, self.itemScroll)
	end

	layout:Reposition()
	self.itemScroll:ResetPosition()

	UIEventListener.Get(self.buyBtn).onClick = function ()
		local select = xyd.ActivityID.TOWER_FUND_GIFTBAG
		local data = xyd.models.activity:getActivity(select)

		if not data then
			xyd.showToast(__("ACTIVITY_OPEN_TEXT"))

			return
		end

		xyd.WindowManager.get():closeWindow(self.name_, function ()
			xyd.openWindow("activity_window", {
				activity_type2 = 3,
				select = select
			})
		end)
	end

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.imgTitle_:Y(55)
	elseif xyd.Global.lang == "ja_jp" then
		self.label1_:Y(-30)

		self.label1_.width = 380
	elseif xyd.Global.lang == "de_de" then
		self.label1_:Y(-22)

		self.label1_.spacingY = 2
		self.label1_.width = 420
		self.icon1_.width = 520
	end
end

function FoudGiftbagPushWindow:checkClose()
	if #self.push_list_ > 0 then
		self:updateLayout()
	else
		xyd.GiftbagPushController.get():checkIndependentPopUpWindow(self.type_)
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

return FoudGiftbagPushWindow
