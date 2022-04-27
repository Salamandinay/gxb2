local ActivityContent = import(".ActivityContent")
local ActivityYearFoud = class("NewSummonGiftBag", ActivityContent)
local ActivityYearFoudItem = class("ActivityYearFoudItem", import("app.components.CopyComponent"))
local ActivityYearFundTable = xyd.tables.activityYearFundTable
local CountDown = import("app.components.CountDown")
local json = require("cjson")

function ActivityYearFoud:ctor(name, params)
	ActivityContent.ctor(self, name, params)
end

function ActivityYearFoud:getPrefabPath()
	return "Prefabs/Windows/activity/activity_year_fund"
end

function ActivityYearFoud:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initData()
	self:initUIComponent()
	self:updateRedMark()
end

function ActivityYearFoud:initData()
	self.has_buy = self.activityData.detail.charges[1].buy_times == 1
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	self.awards = self.activityData.detail.info.awards or {}
	self.days = self.activityData:getDays()
end

function ActivityYearFoud:getUIComponent()
	local go = self.go
	self.imgText_ = go:ComponentByName("imgText_", typeof(UITexture))
	self.desLabel_ = go:ComponentByName("desLabel_", typeof(UILabel))
	self.modelNode = go:ComponentByName("modelNode", typeof(UITexture))
	self.helpBtn = go:NodeByName("helpBtn").gameObject
	self.checkBtn = go:NodeByName("checkBtn").gameObject
	self.checkRedMark_ = self.checkBtn:ComponentByName("redMark", typeof(UISprite))
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.titleLabel_ = self.contentGroup:ComponentByName("titleLabel_", typeof(UILabel))
	self.itemGroup = self.contentGroup:NodeByName("itemGroup").gameObject
	self.tempItem = self.itemGroup:NodeByName("activity_year_fund_item").gameObject
	self.buyGroup = self.contentGroup:NodeByName("buyGroup").gameObject
	self.awardLabel_ = self.buyGroup:ComponentByName("awardLabel_", typeof(UILabel))
	self.awardNumLabel_ = self.buyGroup:ComponentByName("awardNumLabel_", typeof(UILabel))
	self.expLabel_ = self.buyGroup:ComponentByName("expLabel_", typeof(UILabel))
	self.buyBtn = self.buyGroup:NodeByName("buyBtn").gameObject
	self.buyBtnLabel_ = self.buyBtn:ComponentByName("button_label", typeof(UILabel))
	self.awardGroup = self.contentGroup:NodeByName("awardGroup").gameObject
	self.awardItem = self.awardGroup:NodeByName("awardItem").gameObject
	self.signLabel_ = self.awardGroup:ComponentByName("signLabel_", typeof(UILabel))
	self.getLabel_ = self.awardGroup:ComponentByName("getLabel_", typeof(UILabel))
	self.awardBtn = self.awardGroup:NodeByName("awardBtn").gameObject
	self.awardBtnLabel_ = self.awardBtn:ComponentByName("button_label", typeof(UILabel))
	self.awardRedMark_ = self.awardBtn:ComponentByName("redMark", typeof(UISprite))
end

function ActivityYearFoud:initUIComponent()
	xyd.setUITextureByNameAsync(self.imgText_, "activity_year_fund_text01_" .. xyd.Global.lang, true)

	self.titleLabel_.text = __("ACTIVITY_YEAR_FUND_INNER_TITLE")
	self.desLabel_.text = __("ACTIVITY_YEAR_FUND_DES")

	NGUITools.DestroyChildren(self.modelNode.transform)

	self.modelGirl = xyd.Spine.new(self.modelNode.gameObject)

	self.modelGirl:setInfo("ganfuren_pifu03_lihui01", function ()
		self.modelGirl:setRenderTarget(self.modelNode, 1)
		self.modelGirl:SetLocalScale(0.65, 0.65, 0.65)
		self.modelGirl:SetLocalPosition(-65, 375, 0)
		self.modelGirl:play("animation", 0)
	end)

	local ids = ActivityYearFundTable:getIds()

	for i = 1, #ids do
		local id = ids[i]

		if ActivityYearFundTable:isPreview(id) == 1 then
			local tempGo = NGUITools.AddChild(self.itemGroup, self.tempItem)
			local item = ActivityYearFoudItem.new(tempGo, id)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if not self.has_buy then
		self:initBuyGroup()
	else
		self:initAwardGroup()
	end
end

function ActivityYearFoud:initBuyGroup()
	self.buyGroup:SetActive(true)
	self.awardGroup:SetActive(false)

	self.awardLabel_.text = __("ACTIVITY_YEAR_FUND_BUY")
	self.awardNumLabel_.text = xyd.tables.giftTable:getAwards(self.giftID)[1][2]
	self.expLabel_.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	local GiftBagTextTable = xyd.tables.giftBagTextTable
	self.buyBtnLabel_.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end
end

function ActivityYearFoud:initAwardGroup()
	self.buyGroup:SetActive(false)
	self.awardGroup:SetActive(true)

	local start_time = self.activityData.start_time + self.activityData.detail.info.buy_day * 24 * 60 * 60
	local date1 = xyd.split(os.date("%y/%m/%d", start_time), "/")
	local date2 = xyd.split(os.date("%y/%m/%d", start_time + 2505600), "/")
	self.signLabel_.text = __("ACTIVITY_YEAR_FUND_DAYS", self.days)
	self.getLabel_.text = __("ACTIVITY_YEAR_FUND_DATE", date1[2], date1[3], date2[2], date2[3])
	local awards = ActivityYearFundTable:getAwards(self.days)
	self.awardShowItem = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.7685185185185185,
		uiRoot = self.awardItem,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	self.awardShowItem:setBackEffect(true, "fx_ui_beijingguang", "texiao", {
		effectPos = Vector3(0, 0, 0),
		scale = Vector3(1.1, 1.1, 1.1)
	})

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_YEAR_FUND, json.encode({
			table_id = self.days
		}))
	end

	self:updateAwardBtn()
end

function ActivityYearFoud:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_YEAR_FUND_HELP"
		})
	end

	UIEventListener.Get(self.checkBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_year_fund_award_window")
		self.checkRedMark_:SetActive(false)
	end
end

function ActivityYearFoud:onRecharge()
	self.activityData.detail.charges[1].buy_times = 1
	self.activityData.detail.info.days = 1
	self.has_buy = true
	self.days = 1
	local win = xyd.getWindow("activity_window")

	if win then
		win:setTitleTimeLabel(xyd.ActivityID.ACTIVITY_YEAR_FUND, self.activityData:getEndTime() - xyd.getServerTime(), 1)
	end

	self:initAwardGroup()
	self:updateRedMark()
end

function ActivityYearFoud:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_YEAR_FUND then
		return
	end

	local detail = json.decode(data.detail)
	local items = {}
	local awards = detail.items

	for i = 1, #awards do
		table.insert(items, {
			item_id = awards[i].item_id,
			item_num = awards[i].item_num
		})
	end

	xyd.itemFloat(items, nil, , 6000)

	self.awards = self.activityData.detail.info.awards

	self:updateAwardBtn()
	self:updateRedMark()
end

function ActivityYearFoud:updateAwardBtn()
	if self.awards[self.days] == 1 then
		xyd.setEnabled(self.awardBtn, false)

		self.awardBtnLabel_.text = __("ALREADY_GET_PRIZE")

		self.awardShowItem:setBackEffect(false)
	else
		xyd.setEnabled(self.awardBtn, true)

		self.awardBtnLabel_.text = __("GET2")
	end
end

function ActivityYearFoud:updateRedMark()
	if self.has_buy then
		if self.awards[self.days] == 1 then
			self.awardRedMark_:SetActive(false)
		else
			self.awardRedMark_:SetActive(true)
		end

		self.checkRedMark_:SetActive(self.activityData:getRedMarkState2())
	else
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_YEAR_FUND, function ()
			xyd.db.misc:setValue({
				key = "activity_year_fund_red_mark_1",
				value = xyd.getServerTime()
			})
		end)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_YEAR_FUND, self.activityData:getRedMarkState())
end

function ActivityYearFoud:resizeToParent()
	ActivityYearFoud.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.go:Y(-320)
	self.contentGroup:Y(-295 - (p_height - 869))
	self.imgText_:Y(200 - (p_height - 869) * 0.25)
	self.desLabel_:Y(35 - (p_height - 869) * 0.7)

	if xyd.Global.lang == "en_en" then
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 19
	elseif xyd.Global.lang == "fr_fr" then
		self.awardLabel_.width = 300
		self.awardLabel_.fontSize = 24

		self.awardLabel_:X(-65)
		self.buyGroup:NodeByName("awardIcon_").gameObject:X(-38)
		self.awardNumLabel_:X(-40)
	elseif xyd.Global.lang == "ja_jp" then
		self.awardLabel_.fontSize = 24
	elseif xyd.Global.lang == "de_de" then
		self.desLabel_.width = 290
		self.awardLabel_.fontSize = 24
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 20
	end
end

function ActivityYearFoudItem:ctor(go, id)
	self.id = id

	ActivityYearFoudItem.super.ctor(self, go)
end

function ActivityYearFoudItem:initUI()
	self.itemNode = self.go:NodeByName("itemNode").gameObject
	self.go:ComponentByName("label_", typeof(UILabel)).text = __("ACTIVITY_WEEK_DATE", self.id)
	local awards = ActivityYearFundTable:getAwards(self.id)
	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.9537037037037037,
		uiRoot = self.itemNode,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		isNew = ActivityYearFundTable:isNew(self.id)
	})

	if ActivityYearFundTable:hasEffect(self.id) then
		item:setEffect(true, "fx_ui_bp_available", {
			effectPos = Vector3(0, 5, 0)
		})
	end
end

return ActivityYearFoud
