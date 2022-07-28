local ActivityContent = import(".ActivityContent")
local ActivitySandGiftbag = class("ActivitySandGiftbag", ActivityContent)
local ActivitySandGiftbagItem = class("ActivitySandGiftbagItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local AdvanceIcon = import("app.components.AdvanceIcon")
local json = require("cjson")

function ActivitySandGiftbag:ctor(parentGO, params, parent)
	ActivitySandGiftbag.super.ctor(self, parentGO, params, parent)
end

function ActivitySandGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/activity_sand_giftbag"
end

function ActivitySandGiftbag:initUI()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_SAND_GIFTBAG)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_GIFTBAG)
	self.specialGiftbagID = xyd.tables.miscTable:getNumber("activity_sand_gift", "value")
	self.specialIcons = {}

	self:getUIComponent()
	ActivitySandGiftbag.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivitySandGiftbag:resizeToParent()
	ActivitySandGiftbag.super.resizeToParent(self)
end

function ActivitySandGiftbag:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.Bg_ = self.groupAction:ComponentByName("Bg_", typeof(UISprite))
	self.textImg_ = self.groupAction:ComponentByName("textImg_", typeof(UISprite))
	self.helpBtn_ = self.groupAction:NodeByName("helpBtn_").gameObject
	self.specialGroup = self.groupAction:NodeByName("specialGroup").gameObject
	self.labelTitle = self.specialGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.bg = self.labelTitle:ComponentByName("bg", typeof(UISprite))
	self.itemTips1 = self.specialGroup:ComponentByName("itemTips1", typeof(UILabel))
	self.awardItemGroup = self.specialGroup:NodeByName("awardItemGroup").gameObject
	self.awardItemGroupGrid = self.specialGroup:ComponentByName("awardItemGroup", typeof(UIGrid))
	self.labelDesc = self.specialGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.labelVip = self.specialGroup:ComponentByName("labelVip", typeof(UILabel))
	self.giftbagBuyBtn = self.specialGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagBuyBtnLabel = self.giftbagBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.timeGroup = self.bottomGroup:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.bottomGroup:ComponentByName("timeGroup", typeof(UILayout))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.scroller = self.bottomGroup:NodeByName("scroller_").gameObject
	self.scrollView = self.bottomGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.itemGroup = self.scroller:NodeByName("itemGroup").gameObject
	self.item = self.scroller:NodeByName("item").gameObject
	self.drag = self.bottomGroup:NodeByName("drag").gameObject
end

function ActivitySandGiftbag:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ACTIVITY_SAND_GIFTBAG then
			return
		end

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_SAND_GIFTBAG)

		self:initData()
		self:initSpecialGroup()
	end)
	self:registerEvent(xyd.event.RECHARGE, function ()
		self:initData(true)
		self:initSpecialGroup()
	end)

	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_SAND_GIFTBAG_HELP"
		})
	end)
	UIEventListener.Get(self.giftbagBuyBtn).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.specialGiftbagID)
	end)
end

function ActivitySandGiftbag:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_SAND_GIFTBAG_TEXT01")
	self.labelDesc.text = __("ACTIVITY_SAND_GIFTBAG_TEXT05")
	self.itemTips1.text = __("ACTIVITY_SAND_GIFTBAG_TEXT04")

	if xyd.Global.lang == "fr_fr" then
		self.labelDesc.width = 340
		self.labelDesc.height = 48
	end

	xyd.setUISpriteAsync(self.textImg_, nil, "activity_sand_giftbag_logo_" .. xyd.Global.lang)

	self.countdown = import("app.components.CountDown").new(self.timeLabel_)

	if xyd.getServerTime() > self.activityData:getEndTime() - xyd.TimePeriod.DAY_TIME * 7 then
		self.countdown:setCountDownTime(self.activityData:getEndTime() - xyd.getServerTime())
		self.timeLabel_.transform:SetSiblingIndex(0)

		self.endLabel_.text = __("END")

		if xyd.Global.lang == "fr_fr" then
			self.endLabel_.transform:SetSiblingIndex(0)
		end
	else
		self.countdown:setCountDownTime(self.activityData:getEndTime() - xyd.TimePeriod.DAY_TIME * 7 - xyd.getServerTime())

		self.endLabel_.text = __("ACTIVITY_ICE_SECRET_AWARDS_CD")
	end

	self.timeGroupLayout:Reposition()
end

function ActivitySandGiftbag:initData(keepPosition)
	self.data = {}
	self.specialData = {
		left_time = 1,
		awarded = 0,
		giftBagID = self.specialGiftbagID
	}
	local charges = self.activityData.detail.charges

	for i = 1, #charges do
		local giftBagID = tonumber(charges[i].table_id)
		local awarded = 0

		if charges[i].limit_times <= charges[i].buy_times then
			awarded = 1
		end

		if giftBagID ~= self.specialGiftbagID then
			table.insert(self.data, {
				giftBagID = giftBagID,
				left_time = charges[i].limit_times - charges[i].buy_times,
				awarded = awarded
			})
		else
			self.specialData = {
				giftBagID = giftBagID,
				left_time = charges[i].limit_times - charges[i].buy_times,
				awarded = awarded
			}
		end
	end

	local function sort_func(a, b)
		if a.awarded ~= b.awarded then
			return a.awarded < b.awarded
		else
			return a.giftBagID < b.giftBagID
		end
	end

	table.sort(self.data, sort_func)

	if self.wrapContent == nil then
		local wrapContent = self.scroller:ComponentByName("itemGroup", typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.item, ActivitySandGiftbagItem, self)
	end

	self.wrapContent:setInfos(self.data, {
		keepPosition = keepPosition
	})

	if not keepPosition then
		self.scrollView:ResetPosition()
	end
end

function ActivitySandGiftbag:initSpecialGroup()
	self.labelVip.text = __("VIP EXP") .. "+" .. xyd.tables.giftBagTable:getVipExp(self.specialGiftbagID)
	self.giftbagBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.specialGiftbagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.specialGiftbagID))
	self.specialGiftID = xyd.tables.giftBagTable:getGiftID(self.specialGiftbagID)
	local awards = xyd.tables.giftTable:getAwards(self.specialGiftID)
	local doubleNum = self.activityData:getDoubleAwardNum()

	if self.activityData:haveBuySpecialGiftbag() then
		doubleNum = 0
	end

	if doubleNum > 0 then
		table.insert(awards, {
			390,
			doubleNum
		})
	end

	for index, icon in ipairs(self.specialIcons) do
		icon:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				notShowGetWayBtn = true,
				show_has_num = false,
				scale = 0.5555555555555556,
				uiRoot = self.awardItemGroup.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}

			if self.specialIcons[self.count] == nil then
				self.specialIcons[self.count] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.specialIcons[self.count]:setInfo(params)
			end

			self.specialIcons[self.count]:SetActive(true)
			self.specialIcons[self.count]:setChoose(self.specialData.left_time <= 0)

			if award[1] == 390 and i == #awards then
				self.specialIcons[self.count]:getCurIcon():setAddText(__("ACTIVITY_SPFARM_TEXT92"), 1.7)
			end

			self.count = self.count + 1
		end
	end

	if self.specialData.left_time <= 0 then
		xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagBuyBtn, false)
	else
		xyd.applyOrigin(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagBuyBtnLabel:ApplyOrigin()
		xyd.setTouchEnable(self.giftbagBuyBtn, true)
	end

	self.awardItemGroupGrid:Reposition()
end

function ActivitySandGiftbagItem:ctor(go, parent)
	ActivitySandGiftbagItem.super.ctor(self, go, parent)
end

function ActivitySandGiftbagItem:initUI()
	local go = self.go
	self.awardGroup_ = self.go:NodeByName("awardGroup_").gameObject
	self.awardGroupLayout = self.go:ComponentByName("awardGroup_", typeof(UILayout))
	self.vipLabel_ = self.go:ComponentByName("vipLabel_", typeof(UILabel))
	self.expLabel_ = self.go:ComponentByName("expLabel_", typeof(UILabel))
	self.limitLabel_ = self.go:ComponentByName("limitLabel_", typeof(UILabel))
	self.btnPurchase = self.go:NodeByName("chargeBtn_").gameObject
	self.labelBtnPurchase = self.btnPurchase:ComponentByName("button_label", typeof(UILabel))
	self.icons = {}
	UIEventListener.Get(self.btnPurchase).onClick = handler(self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end)
end

function ActivitySandGiftbagItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)

	self.giftBagID = self.data.giftBagID
	self.left_time = self.data.left_time
	local awards = nil
	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", self.left_time)
	self.vipLabel_.text = __("VIP EXP")
	self.expLabel_.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID)
	self.labelBtnPurchase.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	awards = xyd.tables.giftTable:getAwards(self.giftID)

	for i = 1, #self.icons do
		self.icons[i]:SetActive(false)
	end

	self.count = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[i] ~= 8 and xyd.tables.itemTable:getType(award[i]) ~= 12 then
			local params = {
				show_has_num = false,
				scale = 0.7037037037037037,
				notShowGetWayBtn = true,
				uiRoot = self.awardGroup_.gameObject,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.parent.scrollView
			}

			if self.icons[self.count] == nil then
				self.icons[self.count] = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
			else
				self.icons[self.count]:setInfo(params)
			end

			self.icons[self.count]:SetActive(true)
			self.icons[self.count]:setChoose(self.left_time <= 0)

			self.count = self.count + 1
		end
	end

	if self.left_time <= 0 then
		xyd.applyGrey(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelBtnPurchase:ApplyGrey()
		xyd.setTouchEnable(self.btnPurchase, false)
	else
		xyd.applyOrigin(self.btnPurchase:GetComponent(typeof(UISprite)))
		self.labelBtnPurchase:ApplyOrigin()
		xyd.setTouchEnable(self.btnPurchase, true)
	end

	self.awardGroupLayout:Reposition()
end

return ActivitySandGiftbag
