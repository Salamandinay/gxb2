local ActivityContent = import(".ActivityContent")
local ActActivityNewbeeFund3 = class("ActActivityNewbeeFund3", ActivityContent)
local ActivityNewbeeFoudItem = class("ActivityNewbeeFoudItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local fundTable = xyd.tables.activityNewbeeFundTable3

function ActActivityNewbeeFund3:ctor(name, params)
	ActivityContent.ctor(self, name, params)
end

function ActActivityNewbeeFund3:getPrefabPath()
	return "Prefabs/Windows/activity/activity_newbee_fund"
end

function ActActivityNewbeeFund3:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initData()
	self:initUIComponent()
	self:updateRedMark()
end

function ActActivityNewbeeFund3:initData()
	self.has_buy = self.activityData.detail.charges[1].buy_times == 1
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	self.awards = self.activityData.detail.info.awards or {}
	self.days = self.activityData:getDays()
end

function ActActivityNewbeeFund3:getUIComponent()
	local go = self.go
	self.bg_ = go:ComponentByName("Bg_", typeof(UITexture))
	self.imgText_ = go:ComponentByName("imgText_", typeof(UITexture))
	self.imgText2_ = go:ComponentByName("imgText2_", typeof(UISprite))
	self.scroller = go:NodeByName("scroller").gameObject
	self.scroller_UIScrollView = go:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scroller:NodeByName("groupContent").gameObject
	self.desLabel_ = self.groupContent:ComponentByName("desLabel_", typeof(UILabel))
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
	self.awardBg = go:ComponentByName("awardBg", typeof(UITexture))
	self.awardBgVlueCon_layout = self.awardBg:ComponentByName("awardBgVlueCon", typeof(UILayout))
	self.awardLabel = self.awardBg:ComponentByName("awardBgVlueCon/awardLabel", typeof(UILabel))
	self.awardIcon = self.awardBg:ComponentByName("awardBgVlueCon/awardIcon", typeof(UISprite))
	self.awardNumLabel = self.awardBg:ComponentByName("awardBgVlueCon/awardNumLabel", typeof(UILabel))
end

function ActActivityNewbeeFund3:initUIComponent()
	self.imgText_.gameObject:SetActive(false)
	xyd.setUISpriteAsync(self.imgText2_, nil, "activity_newbee_fund3_popup_logo_" .. xyd.Global.lang, nil, , true)

	self.desLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT01")
	self.awardNumLabel.text = "35000"
	self.titleLabel_.text = __("ACTIVITY_YEAR_FUND_INNER_TITLE")

	if self.desLabel_.height >= 109 then
		self.scroller_UIScrollView:ResetPosition()
	end

	xyd.setUITextureByNameAsync(self.awardBg, "activity_newbee_bg2")

	self.awardLabel.text = __("ACTIVITY_YEAR_FUND_TOTAL_CRYSTAL") .. " : "

	xyd.setUISpriteAsync(self.awardIcon, nil, "icon_" .. xyd.ItemID.CRYSTAL, nil, )
	self.awardBgVlueCon_layout:Reposition()

	local awardWidth = self.awardLabel.width + self.awardIcon.width + self.awardNumLabel.width

	if awardWidth > 260 then
		self.awardBg:GetComponent(typeof(UIWidget)).width = awardWidth + 40
	end

	local ids = fundTable:getIds()

	for i = 1, #ids do
		local id = ids[i]

		if fundTable:isPreview(id) == 1 then
			local tempGo = NGUITools.AddChild(self.itemGroup, self.tempItem)
			local item = ActivityNewbeeFoudItem.new(tempGo, id)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()

	if not self.has_buy then
		self:initBuyGroup()
	else
		self:initAwardGroup()
	end
end

function ActActivityNewbeeFund3:initBuyGroup()
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

function ActActivityNewbeeFund3:initAwardGroup()
	self.buyGroup:SetActive(false)
	self.awardGroup:SetActive(true)

	local start_time = self.activityData.start_time + self.activityData.detail.info.buy_day * 24 * 60 * 60
	local date1 = xyd.split(os.date("%y/%m/%d", start_time), "/")
	local endDay = 19
	local date2 = xyd.split(os.date("%y/%m/%d", start_time + endDay * 60 * 60 * 24), "/")
	self.signLabel_.text = __("ACTIVITY_YEAR_FUND_DAYS", self.days)
	self.getLabel_.text = __("ACTIVITY_YEAR_FUND_DATE", date1[2], date1[3], date2[2], date2[3])
	local awards = fundTable:getAwards(self.days)
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
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3, json.encode({
			table_id = self.days
		}))
	end

	self:updateAwardBtn()
end

function ActActivityNewbeeFund3:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local key = "ACTIVITY_NEWBEE_FUND_HELP"

		xyd.WindowManager.get():openWindow("help_window", {
			key = key
		})
	end

	UIEventListener.Get(self.checkBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_newbee_fund3_award_window", {
			isNew = self.isNew_
		})
		self.checkRedMark_:SetActive(false)
	end
end

function ActActivityNewbeeFund3:onRecharge(event)
	local giftBagIDNow = event.data.giftbag_id

	if self.giftBagID ~= giftBagIDNow then
		return
	end

	self.activityData.detail.charges[1].buy_times = 1
	self.activityData.detail.info.days = 1
	self.has_buy = true
	self.days = 1
	local win = xyd.getWindow("activity_window")

	if win then
		win:setTitleTimeLabel(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3, self.activityData:getEndTime() - xyd.getServerTime(), 1)
	end

	self:initAwardGroup()
	self:updateRedMark()
end

function ActActivityNewbeeFund3:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_NEWBEE_FUND3 then
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

function ActActivityNewbeeFund3:updateAwardBtn()
	if self.awards[self.days] == 1 then
		xyd.setEnabled(self.awardBtn, false)

		self.awardBtnLabel_.text = __("ALREADY_GET_PRIZE")

		self.awardShowItem:setBackEffect(false)
	else
		xyd.setEnabled(self.awardBtn, true)

		self.awardBtnLabel_.text = __("GET2")
	end
end

function ActActivityNewbeeFund3:updateRedMark()
	if self.has_buy then
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3, function ()
			if self.awards[self.days] == 1 then
				self.awardRedMark_:SetActive(false)
			else
				self.awardRedMark_:SetActive(true)
			end

			self.checkRedMark_:SetActive(self.activityData:getRedMarkState2())
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_NEWBEE_FUND3, self.activityData:getRedMarkState())
		end)
	else
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND3, function ()
			xyd.db.misc:setValue({
				key = "activity_newbee_fund3_red_mark_1",
				value = xyd.getServerTime()
			})
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_NEWBEE_FUND3, self.activityData:getRedMarkState())
		end)
	end
end

function ActActivityNewbeeFund3:resizeToParent()
	ActActivityNewbeeFund3.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.go:Y(-320)
	self.contentGroup:Y(-295 - (p_height - 869))

	if xyd.Global.lang == "de_de" then
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 20
		self.awardLabel_.pivot = UIWidget.Pivot.Left
	elseif xyd.Global.lang == "en_en" then
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 19
	end

	self.scroller:Y(12 + -129 * self.scale_num_contrary)
	self.imgText_:Y(219 + -45 * self.scale_num_contrary)
	self.awardBg:Y(106 + -73 * self.scale_num_contrary)
	self.imgText2_:Y(219 + -45 * self.scale_num_contrary)
end

function ActivityNewbeeFoudItem:ctor(go, id)
	self.id = id

	ActivityNewbeeFoudItem.super.ctor(self, go)
end

function ActivityNewbeeFoudItem:initUI()
	self.itemNode = self.go:NodeByName("itemNode").gameObject
	self.go:ComponentByName("label_", typeof(UILabel)).text = __("ACTIVITY_WEEK_DATE", self.id)
	local awards = fundTable:getAwards(self.id)
	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.9537037037037037,
		uiRoot = self.itemNode,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		isNew = fundTable:isNew(self.id)
	})

	if fundTable:hasEffect(self.id) then
		item:setEffect(true, "fx_ui_bp_available", {
			effectPos = Vector3(0, 5, 0),
			effectScale = Vector3(1.1, 1.1, 1.1)
		})
	end
end

return ActActivityNewbeeFund3
