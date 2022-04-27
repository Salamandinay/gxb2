local BaseWindow = import(".BaseWindow")
local ArtifactShopWarmUpWindow = class("ArtifactShopWarmUpWindow", BaseWindow)
local ArtifactShopWarmUpItem = class("ArtifactShopWarmUpItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local GiftBagTextTable = xyd.tables.giftBagTextTable
local ActivityMissionPointTable = xyd.tables.activityMissionPointTable

function ArtifactShopWarmUpWindow:ctor(name, params)
	self.id = xyd.ActivityID.ARTIFACT_SHOP_WARM_UP
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)

	BaseWindow.ctor(self, name, params)
end

function ArtifactShopWarmUpWindow:playOpenAnimation(callback)
	ArtifactShopWarmUpWindow.super.playOpenAnimation(self, function ()
		self:initContent()

		if callback then
			callback()
		end
	end)
end

function ArtifactShopWarmUpWindow:initWindow()
	ArtifactShopWarmUpWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	self:reqData()
	self:resizeToParent()
end

function ArtifactShopWarmUpWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.textImg_ = groupAction:ComponentByName("textImg_", typeof(UITexture))
	self.desLabel_ = groupAction:ComponentByName("desGroup/desScroller/desLabel_", typeof(UILabel))
	self.timeLabel_ = groupAction:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = groupAction:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.expLabel_ = groupAction:ComponentByName("expLabel_", typeof(UILabel))
	self.scoreLabel_ = groupAction:ComponentByName("scoreLabel_", typeof(UILabel))
	self.addBtn_ = groupAction:NodeByName("addBtn_").gameObject
	self.addBtnSprite = self.addBtn_:GetComponent(typeof(UISprite))
	self.buyBtn_ = groupAction:NodeByName("buyBtn_").gameObject
	self.buyBtn_label = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.progress = groupAction:ComponentByName("progressGroup", typeof(UISlider))
	self.progress_label = groupAction:ComponentByName("progressGroup/progressLabel_", typeof(UILabel))
	self.helpBtn_ = groupAction:NodeByName("helpBtn_").gameObject
	self.awardBtn_ = groupAction:NodeByName("awardBtn_").gameObject
	self.clickArea = groupAction:NodeByName("clickArea").gameObject
	self.bubble = groupAction:NodeByName("bubble").gameObject
	self.bubbleLabel_ = self.bubble:ComponentByName("label", typeof(UILabel))
	local contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.textLabel01_ = contentGroup:ComponentByName("textLabel01_", typeof(UILabel))
	self.textLabel02_ = contentGroup:ComponentByName("textLabel02_", typeof(UILabel))
	self.textLabel03_ = contentGroup:ComponentByName("textLabel03_", typeof(UILabel))
	self.scrollView = contentGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = contentGroup:NodeByName("scroller_/itemGroup").gameObject
	self.scrollerItem = contentGroup:NodeByName("scroller_/artifact_shop_warm_up_item").gameObject
end

function ArtifactShopWarmUpWindow:initUIComponent()
	xyd.setUITextureByNameAsync(self.textImg_, "artifact_shop_warm_up_text01_" .. xyd.Global.lang, true)

	self.desLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT03")
	self.endLabel_.text = __("END")
	self.scoreLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT05")
	self.textLabel01_.text = __("ACTIVITY_MISSION_POINT_TEXT06")
	self.textLabel02_.text = __("ACTIVITY_MISSION_POINT_TEXT07")
	self.textLabel03_.text = __("ACTIVITY_MISSION_POINT_TEXT08")
	self.bubbleLabel_.text = __("ACTIVITY_MISSION_POINT_TEXT15")
	self.expLabel_.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.buyBtn_label.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)
end

function ArtifactShopWarmUpWindow:register()
	ArtifactShopWarmUpWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetData))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetData))
	self.eventProxy_:addEventListener(xyd.event.GET_MISSION_LIST, handler(self, self.updateBtn2))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self.eventProxy_:addEventListener(xyd.event.ARTIFACT_SCORE_RESIT, handler(self, self.onUpdate))

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	UIEventListener.Get(self.addBtn_).onClick = function ()
		if self.addFlag then
			xyd.openWindow("artifact_shop_warm_up_score_window")
		else
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_MISSION_POINT_TEXT12"))
		end
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_MISSION_POINT_TEXT04"
		})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		xyd.openWindow("artifact_shop_warm_up_award_window")
	end

	UIEventListener.Get(self.clickArea).onClick = function ()
		xyd.openWindow("shop_window", {
			shopType = xyd.ShopType.ARTIFACT
		}, function ()
			xyd.closeWindow("artifact_shop_warm_up_window")
		end)
	end
end

function ArtifactShopWarmUpWindow:reqData()
	self.activityData = xyd.models.activity:getActivity(self.id)

	if self.activityData then
		if self.activityData.detail.active_time == 0 then
			xyd.models.activity:reqAward(self.id)
		else
			xyd.models.activity:reqActivityByID(self.id)
		end

		xyd.models.mission:getData()
	end
end

function ArtifactShopWarmUpWindow:initContent()
	if self.getData and self:isWndComplete() then
		self.getData = nil

		CountDown.new(self.timeLabel_, {
			duration = self.activityData:getEndTime() - xyd.getServerTime()
		})

		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, ArtifactShopWarmUpItem, self)

		self:initData()
		self:updateContentGroup()
		self:updateBtn1()
		self:updateProgress()
		self:updateRedMark()
	end

	if not self.timer then
		self.time = 0
		self.timer = self:getTimer(function ()
			self.time = self.time + 1

			if self.time == 6 then
				self.bubble:SetActive(true)
			end

			if self.time == 10 then
				self.time = 0

				self.bubble:SetActive(false)
			end
		end, 1, -1)

		self.timer:Start()
	end

	local nowTime = xyd.db.misc:getValue("artifact_shop_warm_up_dadian")

	if not nowTime or not xyd.isToday(tonumber(nowTime)) then
		local msg = messages_pb.record_activity_req()
		msg.activity_id = xyd.ActivityID.ARTIFACT_SHOP_WARM_UP

		xyd.Backend.get():request(xyd.mid.RECORD_ACTIVITY, msg)
		xyd.db.misc:setValue({
			key = "new_seven_giftbag_dadian",
			value = xyd.getServerTime()
		})
	end
end

function ArtifactShopWarmUpWindow:onGetData(event)
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.getData = true

	self:initContent()
end

function ArtifactShopWarmUpWindow:initData()
	self.has_buy = self.activityData.detail.charges[1].buy_times == 1
	self.point = self.activityData.detail.point or 0
	self.awarded = self.activityData.detail.awarded
	self.days = self.activityData:getDayNum()
end

function ArtifactShopWarmUpWindow:updateContentGroup()
	local ids = ActivityMissionPointTable:getIds()
	local collection = {}

	for i = 1, #ids do
		local score = ActivityMissionPointTable:getPoint(i)

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

function ArtifactShopWarmUpWindow:updateBtn1()
	if self.has_buy then
		xyd.setEnabled(self.buyBtn_, false)
	else
		xyd.setEnabled(self.buyBtn_, true)
	end
end

function ArtifactShopWarmUpWindow:updateBtn2()
	local canResitScore = self.activityData:getCanResitScore()

	if canResitScore > 0 then
		xyd.setUISpriteAsync(self.addBtnSprite, nil, "artifact_shop_warm_up_btn1")

		self.addFlag = true
	else
		xyd.setUISpriteAsync(self.addBtnSprite, nil, "artifact_shop_warm_up_btn2")

		self.addFlag = false
	end
end

function ArtifactShopWarmUpWindow:updateProgress()
	self.progress_label.text = self.point .. "/" .. ActivityMissionPointTable:getTotalPoint()
	self.progress.value = self.point / ActivityMissionPointTable:getTotalPoint()
end

function ArtifactShopWarmUpWindow:onRecharge()
	self.has_buy = true

	self:updateBtn1()
	self:updateContentGroup()
end

function ArtifactShopWarmUpWindow:onUpdate(event)
	self.activityData.detail.point = event.data.point
	self.point = event.data.point
	self.awarded = event.data.awarded

	self:updateContentGroup()
	self:updateBtn2()
	self:updateProgress()
end

function ArtifactShopWarmUpWindow:updateRedMark()
	xyd.db.misc:setValue({
		key = "artifact_shop_warm_up_redmark",
		value = xyd.getServerTime()
	})
	xyd.models.redMark:setMark(xyd.RedMarkType.ARTIFACT_SHOP_WARM_UP, false)

	local win = xyd.getWindow("main_window")

	if win then
		win:CheckExtraActBtn(xyd.MAIN_LEFT_TOP_BTN_TYPE.ARTIFACT_SHOP_WARM_UP)
	end
end

function ArtifactShopWarmUpWindow:resizeToParent()
	if xyd.Global.lang == "en_en" then
		self.desLabel_:Y(-10)
	elseif xyd.Global.lang == "fr_fr" then
		self.desLabel_:Y(-45)
	elseif xyd.Global.lang == "ja_jp" then
		self.desLabel_:Y(-10)
	elseif xyd.Global.lang == "de_de" then
		self.window_.transform:NodeByName("groupAction/timeGroup"):X(165)
		self.desLabel_:Y(-45)
	end
end

function ArtifactShopWarmUpItem:ctor(go, parent)
	ArtifactShopWarmUpItem.super.ctor(self, go, parent)

	self.baseItems = {}
	self.extraItems = {}
end

function ArtifactShopWarmUpItem:initUI()
	local go = self.go
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.baseAwardGroup = go:NodeByName("baseAwardGroup").gameObject
	self.extraAwardGroup = go:NodeByName("extraAwardGroup").gameObject
	self.layout1 = self.baseAwardGroup:GetComponent(typeof(UILayout))
	self.layout2 = self.extraAwardGroup:GetComponent(typeof(UILayout))
	self.fgx = go:NodeByName("fgx")
end

function ArtifactShopWarmUpItem:updateInfo()
	self.id = self.data.id
	self.score = self.data.score
	self.isComplete = self.data.isComplete
	self.hasBuy = self.data.hasBuy
	self.scoreLabel_.text = self.score

	if self.parent.lastID and self.id == self.parent.lastID then
		self.fgx:SetActive(false)
	else
		self.fgx:SetActive(true)
	end

	local baseAwards = ActivityMissionPointTable:getBaseAwards(self.id)
	local effects1 = ActivityMissionPointTable:hasEffect1(self.id)

	for i = 1, #baseAwards do
		local award = baseAwards[i]
		local hasEffect = effects1[i]

		if not self.baseItems[i] then
			self.baseItems[i] = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.5555555555555556,
				uiRoot = self.baseAwardGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		else
			self.baseItems[i]:SetActive(true)
			self.baseItems[i]:setInfo({
				show_has_num = true,
				scale = 0.5555555555555556,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end

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

	local extraAwards = ActivityMissionPointTable:getExtraAwards(self.id)
	local effects2 = ActivityMissionPointTable:hasEffect2(self.id)

	for i = 1, #extraAwards do
		local award = extraAwards[i]
		local hasEffect = effects2[i]

		if not self.extraItems[i] then
			self.extraItems[i] = xyd.getItemIcon({
				show_has_num = true,
				scale = 0.5555555555555556,
				uiRoot = self.extraAwardGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		else
			self.extraItems[i]:SetActive(true)
			self.extraItems[i]:setInfo({
				show_has_num = true,
				scale = 0.5555555555555556,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			})
		end

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

return ArtifactShopWarmUpWindow
