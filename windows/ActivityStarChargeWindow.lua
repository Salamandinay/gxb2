local BaseShop = import(".BaseWindow")
local ActivityStarChargeWindow = class("ActivityStarChargeWindow", BaseShop)
local cjson = require("cjson")

function ActivityStarChargeWindow:ctor(name, params)
	ActivityStarChargeWindow.super.ctor(self, name, params)

	if params then
		self.wndType = params.type or 1
	else
		self.wndType = 1
	end

	self.activityDataLogin = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN)
	self.activityDataCharge = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_START_ALTAR_CHARGE)
	self.giftBagID = 1
	self.loginItemList_ = {}
	self.giftBagItem_ = {}
end

function ActivityStarChargeWindow:initWindow()
	ActivityStarChargeWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityStarChargeWindow:didClose()
	ActivityStarChargeWindow.super.didClose(self)

	if self.wndType == 1 then
		xyd.MainController.get().openPopWindowNum = xyd.MainController.get().openPopWindowNum - 1
	end
end

function ActivityStarChargeWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.logo_ = winTrans:ComponentByName("logo", typeof(UISprite))
	self.labelTips_ = winTrans:ComponentByName("tipsGroup/labelTips", typeof(UILabel))
	self.giftGroup_ = winTrans:NodeByName("giftGroup").gameObject
	self.buyBtn_ = self.giftGroup_:NodeByName("awardBtn").gameObject
	self.priceLabel_ = self.giftGroup_:ComponentByName("awardBtn/button_label", typeof(UILabel))
	self.vipLabel_ = self.giftGroup_:ComponentByName("vipLabel", typeof(UILabel))
	self.limitLabel_ = self.giftGroup_:ComponentByName("limitLabel", typeof(UILabel))

	for i = 1, 3 do
		self["giftRoot" .. i] = self.giftGroup_:NodeByName("awardRoot" .. i).gameObject
	end

	self.loginGroup_ = winTrans:NodeByName("loginGroup").gameObject
	self.awardBtn_ = self.loginGroup_:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = self.loginGroup_:ComponentByName("awardBtn/label", typeof(UILabel))
	self.labelNever_ = self.loginGroup_:ComponentByName("groupChoose/labelNever", typeof(UILabel))
	self.groupChoose_ = self.loginGroup_:ComponentByName("groupChoose", typeof(UILayout))
	self.imgChoose_ = self.loginGroup_:NodeByName("groupChoose/img").gameObject
	self.imgSelect_ = self.loginGroup_:NodeByName("groupChoose/img/imgSelect").gameObject

	for i = 1, 2 do
		self["loginRoot" .. i] = self.loginGroup_:NodeByName("awardRoot" .. i).gameObject
	end
end

function ActivityStarChargeWindow:willClose()
	if self.selectStage_ and self.selectStage_ == 1 then
		xyd.db.misc:setValue({
			key = "star_altar_login_open_time",
			value = xyd.getServerTime()
		})
	end
end

function ActivityStarChargeWindow:onClickChoose()
	if self.selectStage_ == 1 then
		self.selectStage_ = 0
	else
		self.selectStage_ = 1
	end

	xyd.db.misc:setValue({
		key = "star_altar_login_ignore",
		value = self.selectStage_
	})
	self.imgSelect_:SetActive(self.selectStage_ and self.selectStage_ == 1)
end

function ActivityStarChargeWindow:register()
	UIEventListener.Get(self.labelNever_.gameObject).onClick = function ()
		self:onClickChoose()
	end

	UIEventListener.Get(self.imgChoose_).onClick = function ()
		self:onClickChoose()
	end

	UIEventListener.Get(self.groupChoose_.gameObject).onClick = function ()
		self:onClickChoose()
	end

	xyd.setDarkenBtnBehavior(self.buyBtn_, self, function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end)

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		local nowDay = self.activityDataLogin:getNowDay()
		local params = cjson.encode({
			id = tonumber(nowDay)
		})
		local hasFinish = self.activityDataLogin:checkFinish(nowDay)

		if hasFinish then
			xyd.WindowManager.get():openWindow("activity_window", {
				activity_type = xyd.tables.activityTable:getType2(xyd.ActivityID.ACTIVITY_START_ALTAR_CHARGE),
				select = xyd.ActivityID.ACTIVITY_START_ALTAR_CHARGE
			})
			self:close()
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN, params)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onCharge))
end

function ActivityStarChargeWindow:layout()
	if self.wndType == 1 then
		xyd.setUISpriteAsync(self.logo_, nil, "activity_star_altar_login_logo_" .. xyd.Global.lang, nil, , true)
		self:initLogin()
	elseif self.wndType == 2 and self.activityDataCharge then
		xyd.setUISpriteAsync(self.logo_, nil, "activity_star_altar_charge_logo2_" .. xyd.Global.lang, nil, , true)
		self:initGiftBag()
	end
end

function ActivityStarChargeWindow:initLogin()
	self.selectStage_ = xyd.db.misc:getValue("star_altar_login_ignore") or 0

	self.imgSelect_:SetActive(self.selectStage_ and self.selectStage_ == 1)
	self.loginGroup_:SetActive(true)
	self.giftGroup_:SetActive(false)

	self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_BUTTON03")
	self.labelNever_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT05")

	self:waitForFrame(1, function ()
		self.groupChoose_:Reposition()
	end)

	self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT04")
	local nowDay = self.activityDataLogin:getNowDay()
	local awards = xyd.tables.activityStarAltarLoginTable:getAward(tonumber(nowDay))
	local hasFinish = self.activityDataLogin:checkFinish(nowDay)

	if hasFinish then
		self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT03")
		self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_BUTTON04")
		local nowStage = self.activityDataCharge:getNowStage()
		awards = xyd.tables.activityStarAltarCostTable:getAwards(nowStage)
	end

	for i = 1, 2 do
		if not self.loginItemList_[i] then
			self.loginItemList_[i] = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self["loginRoot" .. i],
				itemID = awards[i][1],
				num = awards[i][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end
end

function ActivityStarChargeWindow:initGiftBag()
	self.loginGroup_:SetActive(false)
	self.giftGroup_:SetActive(true)

	self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT03")
	self.info = self.activityDataCharge.detail.charges[1]
	self.giftBagID = self.info.table_id
	self.priceLabel_.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
	self.vipLabel_.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagID)) .. " VIP EXP"
	self.limitLabel_.text = __("BUY_GIFTBAG_LIMIT", tonumber(self.info.limit_times) - tonumber(self.info.buy_times))
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)
	local hasBuy = tonumber(self.info.limit_times) - tonumber(self.info.buy_times) <= 0
	local awardsData = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardsData, data)
		end
	end

	for i = 1, 3 do
		if not self.giftBagItem_[i] then
			self.giftBagItem_[i] = xyd.getItemIcon({
				scale = 0.7962962962962963,
				uiRoot = self["giftRoot" .. i],
				itemID = awardsData[i][1],
				num = awardsData[i][2],
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})
		end

		self.giftBagItem_[i]:setChoose(hasBuy)
	end

	if hasBuy then
		xyd.setEnabled(self.buyBtn_, false)
	end
end

function ActivityStarChargeWindow:onAward(event)
	local id = event.data.activity_id

	if id ~= xyd.ActivityID.ACTIVITY_START_ALTAR_LOGIN then
		return
	end

	local details = require("cjson").decode(event.data.detail)
	local items = details.items

	xyd.itemFloat(items)

	local nowStage = self.activityDataCharge:getNowStage()
	local awards = xyd.tables.activityStarAltarCostTable:getAwards(nowStage)

	for i = 1, 2 do
		self.loginItemList_[i]:setInfo({
			scale = 0.7962962962962963,
			itemID = awards[i][1],
			num = awards[i][2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.labelTips_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_TEXT03")
	self.awardBtnLabel_.text = __("ACTIVITY_STAR_ALTAR_GAMBLE_BUTTON04")
end

function ActivityStarChargeWindow:onCharge(event)
	self:initGiftBag()
end

return ActivityStarChargeWindow
