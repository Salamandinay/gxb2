local BaseWindow = import(".BaseWindow")
local ActivityResidentReturnSupportWindow = class("ActivityResidentReturnSupportWindow", BaseWindow)
local ActivityResidentReturnSupportItem = class("ActivityResidentReturnSupportItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local WindowTop = require("app.components.WindowTop")
local GiftBagTextTable = xyd.tables.giftBagTextTable
local ActivityResidentReturnRewardTable = xyd.tables.activityResidentReturnRewardTable

function ActivityResidentReturnSupportWindow:ctor(name, params)
	self.id = xyd.ActivityID.ACTIVITY_RESIDENT_RETURN
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	self.activityData = xyd.models.activity:getActivity(self.id)
	local localSupportTime = xyd.db.misc:getValue("activity_resident_return_support_red_time")

	if not localSupportTime or localSupportTime and not xyd.isSameDay(tonumber(localSupportTime), xyd.getServerTime()) then
		xyd.db.misc:setValue({
			key = "activity_resident_return_support_red_time",
			value = xyd.getServerTime()
		})
	end

	BaseWindow.ctor(self, name, params)
end

function ActivityResidentReturnSupportWindow:playOpenAnimation(callback)
	ActivityResidentReturnSupportWindow.super.playOpenAnimation(self, function ()
		self:reqData()

		if callback then
			callback()
		end
	end)
end

function ActivityResidentReturnSupportWindow:initTopGroup()
	local function callback()
		xyd.WindowManager.get():openWindow("activity_resident_return_main_window")
		xyd.WindowManager:get():closeWindow(self.name_)
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, nil, , callback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityResidentReturnSupportWindow:getWindowTop()
	return self.windowTop
end

function ActivityResidentReturnSupportWindow:initWindow()
	ActivityResidentReturnSupportWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:initTopGroup()
	self:register()
	self:updateContent()
	self:resizeToParent()
end

function ActivityResidentReturnSupportWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.textImg_ = groupAction:ComponentByName("textImg_", typeof(UISprite))
	self.desScroller = groupAction:ComponentByName("desGroup/desScroller", typeof(UIScrollView))
	self.desLabel_ = groupAction:ComponentByName("desGroup/desScroller/desLabel_", typeof(UILabel))
	self.timeLabel_ = groupAction:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = groupAction:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.expLabel_ = groupAction:ComponentByName("expLabel_", typeof(UILabel))
	self.buyBtn_ = groupAction:NodeByName("buyBtn_").gameObject
	self.buyBtn_label = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.helpBtn_ = groupAction:NodeByName("helpBtn_").gameObject
	self.awardBtn_ = groupAction:NodeByName("awardBtn_").gameObject
	local contentGroup = groupAction:NodeByName("contentGroup").gameObject
	local bgGroup = contentGroup:NodeByName("bgGroup").gameObject
	self.contentBg3_ = bgGroup:ComponentByName("contentBg3_", typeof(UISprite))
	self.contentBg4_ = bgGroup:ComponentByName("contentBg4_", typeof(UISprite))
	local scoreGroup = contentGroup:NodeByName("scoreGroup").gameObject
	self.progress = scoreGroup:ComponentByName("progressGroup", typeof(UISlider))
	self.progress_label = scoreGroup:ComponentByName("progressGroup/progressLabel_", typeof(UILabel))
	self.scoreLabel_ = scoreGroup:ComponentByName("scoreLabel_", typeof(UILabel))
	self.addBtn_ = scoreGroup:NodeByName("addBtn_").gameObject
	self.addBtnSprite = self.addBtn_:GetComponent(typeof(UISprite))
	self.effect_ = scoreGroup:NodeByName("effect_").gameObject
	local titleGroup = contentGroup:NodeByName("titleGroup").gameObject
	self.scoreTitleLabel_ = titleGroup:ComponentByName("scoreTitleLabel_", typeof(UILabel))
	self.baseAwardTitleLabel_ = titleGroup:ComponentByName("baseAwardTitleGroup/baseAwardTitleLabel_", typeof(UILabel))
	self.extraAwardTitileLabel_ = titleGroup:ComponentByName("extraAwardTitleGroup/extraAwardTitileLabel_", typeof(UILabel))
	local scrollerGroup = contentGroup:NodeByName("scrollerGroup").gameObject
	self.scrollView = scrollerGroup:ComponentByName("itemScroller", typeof(UIScrollView))
	self.itemGroup = scrollerGroup:NodeByName("itemScroller/itemGroup").gameObject
	self.scrollerItem = scrollerGroup:NodeByName("itemScroller/activity_resident_return_support_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, ActivityResidentReturnSupportItem, self)
end

function ActivityResidentReturnSupportWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg_, nil, "resident_return_support_logo_" .. xyd.Global.lang, nil, , true)
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getReturnEndTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END")
	self.desLabel_.text = __("ACTIVITY_RETURN2_SUPPORT_TEXT01")
	self.scoreLabel_.text = __("ACTIVITY_RETURN2_SUPPORT_TEXT05")
	self.scoreTitleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT06")
	self.baseAwardTitleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT07")
	self.extraAwardTitileLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT08")

	self.desScroller:ResetPosition()

	self.expLabel_.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.buyBtn_label.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)
	local effect = xyd.Spine.new(self.effect_)

	effect:setInfo("return2_score", function ()
		effect:play("texiao01", 0)
	end)
	self.effect_:SetActive(false)
end

function ActivityResidentReturnSupportWindow:register()
	ActivityResidentReturnSupportWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateContent))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateContent))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.updateContent))

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	UIEventListener.Get(self.addBtn_).onClick = function ()
		local canResitScore = self.activityData:getReturnSupportCanResitScore()

		if canResitScore > 0 then
			xyd.openWindow("activity_resident_return_support_score_window")
		else
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RETURN2_SUPPORT_TEXT02"))
		end
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_RETURN2_SUPPORT_TEXT04"
		})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.openWindow("activity_resident_return_support_award_window")
	end
end

function ActivityResidentReturnSupportWindow:updateContent()
	self:updateData()
	self:updateBtnBuy()
	self:updateBtnAdd()
	self:updateProgress()
	self:updateContentGroup()
	self:updateRed()
end

function ActivityResidentReturnSupportWindow:updateData()
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.has_buy = self.activityData.detail.charges[1].buy_times == 1
	self.point = self.activityData.detail.point or 0
end

function ActivityResidentReturnSupportWindow:updateContentGroup()
	local ids = ActivityResidentReturnRewardTable:getIds()
	local collection = {}

	for i = 1, #ids do
		local score = ActivityResidentReturnRewardTable:getPoint(i)

		table.insert(collection, {
			id = i,
			score = score,
			isComplete = score <= self.point,
			hasBuy = self.has_buy
		})
	end

	table.sort(collection, function (a, b)
		if a.isComplete ~= b.isComplete then
			return xyd.bool2Num(a.isComplete) < xyd.bool2Num(b.isComplete)
		else
			return a.id < b.id
		end
	end)

	self.lastID = collection[#ids].id

	self.wrapContent:setInfos(collection, {})
end

function ActivityResidentReturnSupportWindow:updateBtnBuy()
	if self.has_buy then
		xyd.setEnabled(self.buyBtn_, false)
	else
		xyd.setEnabled(self.buyBtn_, true)
	end
end

function ActivityResidentReturnSupportWindow:updateBtnAdd()
	local canResitScore = self.activityData:getReturnSupportCanResitScore()

	if canResitScore > 0 then
		xyd.applyOrigin(self.addBtnSprite)
		self.effect_:SetActive(true)
	else
		xyd.applyDark(self.addBtnSprite)
		self.effect_:SetActive(false)
	end
end

function ActivityResidentReturnSupportWindow:updateProgress()
	self.progress_label.text = self.point .. "/" .. ActivityResidentReturnRewardTable:getTotalPoint()
	self.progress.value = self.point / ActivityResidentReturnRewardTable:getTotalPoint()
end

function ActivityResidentReturnSupportWindow:reqData()
	xyd.models.activity:reqActivityByID(self.id)
end

function ActivityResidentReturnSupportWindow:updateRed()
	self.activityData:setRedMarkState(xyd.RedMarkType.ACTIVITY_RESIDENT_RETURN_RED_2)
end

function ActivityResidentReturnSupportWindow:resizeToParent()
	local width = self.window_:GetComponent(typeof(UIPanel)).width
	local height = self.window_:GetComponent(typeof(UIPanel)).height

	self.contentBg3_:X(-width / 2 + 5)
	self.contentBg4_:X(width / 2 - 5)
	self.contentBg3_:Y((1280 - height) / 2)
	self.contentBg4_:Y((1280 - height) / 2)

	self.contentBg3_.width = height - 532
	self.contentBg4_.width = height - 532
end

function ActivityResidentReturnSupportItem:ctor(go, parent)
	ActivityResidentReturnSupportItem.super.ctor(self, go, parent)

	self.baseItems = {}
	self.extraItems = {}
end

function ActivityResidentReturnSupportItem:initUI()
	local go = self.go
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.baseAwardGroup = go:NodeByName("baseAwardGroup").gameObject
	self.extraAwardGroup = go:NodeByName("extraAwardGroup").gameObject
	self.layout1 = self.baseAwardGroup:GetComponent(typeof(UILayout))
	self.layout2 = self.extraAwardGroup:GetComponent(typeof(UILayout))
	self.divideLine_ = go:NodeByName("divideLine_")
end

function ActivityResidentReturnSupportItem:updateInfo()
	if not self.go then
		return
	end

	self.id = self.data.id
	self.score = self.data.score
	self.isComplete = self.data.isComplete
	self.hasBuy = self.data.hasBuy
	self.scoreLabel_.text = self.score

	if self.parent.lastID and self.id == self.parent.lastID then
		self.divideLine_:SetActive(false)
	else
		self.divideLine_:SetActive(true)
	end

	local baseAwards = ActivityResidentReturnRewardTable:getBaseAwards(self.id)
	local effects1 = ActivityResidentReturnRewardTable:hasEffect1(self.id)

	NGUITools.DestroyChildren(self.baseAwardGroup.transform)

	for i = 1, #baseAwards do
		local award = baseAwards[i]
		local hasEffect = effects1[i]
		self.baseItems[i] = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.baseAwardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scrollView
		})

		if hasEffect == 1 then
			self.baseItems[i]:setEffect(true, "fx_ui_bp_available", {
				effectPos = Vector3(2, 5, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				panel_ = self.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
			})
		else
			self.baseItems[i]:setEffect(false)
		end

		if self.isComplete then
			self.baseItems[i]:setChoose(true)
		else
			self.baseItems[i]:setChoose(false)
		end
	end

	for i = #baseAwards + 1, #self.baseItems do
		self.baseItems[i]:SetActive(false)
	end

	if #baseAwards >= 3 then
		self.layout1.gap = Vector2(11, 0)
	else
		self.layout1.gap = Vector2(22, 0)
	end

	self.layout1:Reposition()

	local extraAwards = ActivityResidentReturnRewardTable:getExtraAwards(self.id)
	local effects2 = ActivityResidentReturnRewardTable:hasEffect2(self.id)

	NGUITools.DestroyChildren(self.extraAwardGroup.transform)

	for i = 1, #extraAwards do
		local award = extraAwards[i]
		local hasEffect = effects2[i]
		self.extraItems[i] = xyd.getItemIcon({
			show_has_num = true,
			scale = 0.7037037037037037,
			uiRoot = self.extraAwardGroup,
			itemID = award[1],
			num = award[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			dragScrollView = self.parent.scrollView
		})

		if hasEffect == 1 then
			self.extraItems[i]:setEffect(true, "fx_ui_bp_available", {
				effectPos = Vector3(2, 5, 0),
				effectScale = Vector3(1.1, 1.1, 1.1),
				panel_ = self.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
			})
		else
			self.extraItems[i]:setEffect(false)
		end

		if not self.hasBuy then
			self.extraItems[i]:setLockSource("lock")
			self.extraItems[i]:setLockScale(0.7)
			self.extraItems[i]:setLock(true)
		elseif self.isComplete then
			self.extraItems[i]:setLock(false)
			self.extraItems[i]:setChoose(true)
		else
			self.extraItems[i]:setLock(false)
			self.extraItems[i]:setChoose(false)
		end
	end

	for i = #extraAwards + 1, #self.extraItems do
		self.extraItems[i]:SetActive(false)
	end

	if #extraAwards >= 3 then
		self.layout2.gap = Vector2(11, 0)
	else
		self.layout2.gap = Vector2(22, 0)
	end

	self.layout2:Reposition()
end

return ActivityResidentReturnSupportWindow
