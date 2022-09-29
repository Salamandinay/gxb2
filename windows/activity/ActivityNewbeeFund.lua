local ActivityContent = import(".ActivityContent")
local ActivityNewbeeFund = class("ActivityNewbeeFund", ActivityContent)
local ActivityNewbeeFoudItem = class("ActivityNewbeeFoudItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local fundTable = nil
local ActivityNewbeeFundAwardItem = class("ActivityNewbeeFundAwardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityNewbeeFundTable = xyd.tables.activityNewbeeFundTable2

function ActivityNewbeeFund:ctor(name, params)
	ActivityContent.ctor(self, name, params)
end

function ActivityNewbeeFund:getPrefabPath()
	return "Prefabs/Windows/activity/activity_new_newbee_fund"
end

function ActivityNewbeeFund:initUI()
	local startTime = self.activityData.detail.info.start_time
	self.isNew_ = true

	self:getUIComponent()
	ActivityContent.initUI(self)
	self:initData()
	self:initUIComponent()
	self:updateRedMark()
end

function ActivityNewbeeFund:initData()
	self.has_buy = self.activityData.detail.charges[1].buy_times == 1
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1]
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	self.awards = self.activityData.detail.info.awards or {}
	self.days = self.activityData:getDays()
end

function ActivityNewbeeFund:getUIComponent()
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
	self.contentGroup = go:NodeByName("contentGroup").gameObject
	self.titleLabel_ = self.contentGroup:ComponentByName("titleLabel_", typeof(UILabel))
	self.smallIcon = self.contentGroup:NodeByName("smallIcon").gameObject
	self.buyGroup = self.contentGroup:NodeByName("buyGroup").gameObject
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
	local mainGroup = self.contentGroup:NodeByName("mainGroup").gameObject
	self.scrollView = mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.itemGroup = mainGroup:NodeByName("scroller/itemGroup").gameObject
	self.mainAwardItem = mainGroup:NodeByName("scroller/activity_year_fund_award_item").gameObject
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.mainAwardItem, ActivityNewbeeFundAwardItem, self)
	self.awardIconGroup = self.buyGroup:NodeByName("awardIconGroup").gameObject
end

function ActivityNewbeeFund:initUIComponent()
	if self.isNew_ then
		self.imgText_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.imgText2_, nil, "activity_new_newbee_fund3_popup_logo_" .. xyd.Global.lang)

		self.desLabel_.text = __("ACTIVITY_NEWBEE_FUND_TEXT01")
		self.awardNumLabel.text = "45000"
		fundTable = xyd.tables.activityNewbeeFundTable2
	else
		self.imgText2_.gameObject:SetActive(false)
		xyd.setUITextureByNameAsync(self.imgText_, "activity_new_newbee_fund_logo_" .. xyd.Global.lang, true)

		self.desLabel_.text = __("ACTIVITY_NEWBEE_FUND_DES")
		self.awardNumLabel.text = xyd.tables.miscTable:getNumber("activity_newbee_total_value", "value")
		fundTable = xyd.tables.activityNewbeeFundTable2
	end

	self.titleLabel_.text = __("ACTIVITY_YEAR_FUND_INNER_TITLE2")

	if self.desLabel_.height >= 109 then
		self.scroller_UIScrollView:ResetPosition()
	end

	xyd.setUITextureByNameAsync(self.awardBg, "activity_new_newbee_bg2")

	self.awardLabel.text = __("ACTIVITY_YEAR_FUND_TOTAL_CRYSTAL") .. " : "

	xyd.setUISpriteAsync(self.awardIcon, nil, "icon_" .. xyd.ItemID.CRYSTAL, nil, )
	self.awardBgVlueCon_layout:Reposition()

	local awardWidth = self.awardLabel.width + self.awardIcon.width + self.awardNumLabel.width

	if awardWidth > 260 then
		self.awardBg:GetComponent(typeof(UIWidget)).width = awardWidth + 40
	end

	if not self.has_buy then
		self:initBuyGroup()
	else
		self:initAwardGroup()
	end

	self.days = self.activityData:getDays()
	self.awards = self.activityData.detail.info.awards or {}

	if not self.activityData then
		return
	end

	local ids = ActivityNewbeeFundTable:getIds()
	local collection = {}

	for i = 1, #ids do
		local id = ids[i]
		local state = 0

		if id <= self.days then
			if self.awards[id] == 1 then
				state = 1
			elseif self.awards[id] == 0 and id < self.days then
				state = 2
			end
		end

		table.insert(collection, {
			id = id,
			state = state
		})
	end

	dump(collection)
	dump(self.activityData)
	self.wrapContent:setInfos(collection, {
		scrollPos = Vector3(0, 180, 0)
	})
end

function ActivityNewbeeFund:initBuyGroup()
	self.buyGroup:SetActive(true)
	self.awardGroup:SetActive(false)

	self.expLabel_.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	local GiftBagTextTable = xyd.tables.giftBagTextTable
	self.buyBtnLabel_.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	local giftId = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftId)
	local iconScale = 1

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= xyd.ItemID.VIP_EXP then
			xyd.getItemIcon({
				show_has_num = true,
				showGetWays = false,
				notShowGetWayBtn = true,
				uiRoot = self.awardIconGroup,
				itemID = award[1],
				num = award[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = iconScale
			})

			iconScale = 0.8113207547169812
		end
	end

	self.awardIconGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityNewbeeFund:initAwardGroup()
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
		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, json.encode({
			table_id = self.days
		}))
	end

	self:updateAwardBtn()
end

function ActivityNewbeeFund:onRegister()
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		local key = nil

		if self.isNew_ then
			key = "ACTIVITY_NEWBEE_FUND_HELP"
		else
			key = "ACTIVITY_YEAR_FUND_HELP"
		end

		xyd.WindowManager.get():openWindow("help_window", {
			key = key
		})
	end
end

function ActivityNewbeeFund:onRecharge(event)
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
		win:setTitleTimeLabel(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, self.activityData:getEndTime() - xyd.getServerTime(), 1)
	end

	self:initAwardGroup()
	self:updateRedMark()
end

function ActivityNewbeeFund:onAward(event)
	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_NEWBEE_FUND then
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

	local data = event.data

	if data.activity_id ~= xyd.ActivityID.ACTIVITY_NEWBEE_FUND then
		return
	end

	self:initUIComponent()
end

function ActivityNewbeeFund:updateAwardBtn()
	if self.awards[self.days] == 1 then
		xyd.setEnabled(self.awardBtn, false)

		self.awardBtnLabel_.text = __("ALREADY_GET_PRIZE")

		self.awardShowItem:setBackEffect(false)
	else
		xyd.setEnabled(self.awardBtn, true)

		self.awardBtnLabel_.text = __("GET2")
	end
end

function ActivityNewbeeFund:updateRedMark()
	if self.has_buy then
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, function ()
			if self.awards[self.days] == 1 then
				self.awardRedMark_:SetActive(false)
			else
				self.awardRedMark_:SetActive(true)
			end

			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_NEWBEE_FUND, self.activityData:getRedMarkState())
		end)
	else
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, function ()
			xyd.db.misc:setValue({
				key = "activity_newbee_fund_red_mark_1",
				value = xyd.getServerTime()
			})
			xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_NEWBEE_FUND, self.activityData:getRedMarkState())
		end)
	end
end

function ActivityNewbeeFund:resizeToParent()
	ActivityNewbeeFund.super.resizeToParent(self)

	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	self.go:Y(-320)
	self.contentGroup:Y(-295 - (p_height - 869))

	if xyd.Global.lang == "de_de" then
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 20

		self.smallIcon:X(-175)
	elseif xyd.Global.lang == "en_en" then
		self.signLabel_.fontSize = 20
		self.getLabel_.fontSize = 19
	elseif xyd.Global.lang == "fr_fr" then
		self.smallIcon:X(-210)
	elseif xyd.Global.lang == "ja_jp" then
		self.smallIcon:X(-110)
	elseif xyd.Global.lang == "ko_kr" then
		self.smallIcon:X(-105)
	end

	self.scroller:Y(12 + -129 * self.scale_num_contrary)
	self.imgText_:Y(219 + -45 * self.scale_num_contrary)
	self.awardBg:Y(106 + -73 * self.scale_num_contrary)
	self.imgText2_:Y(219 + -54 * self.scale_num_contrary)
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

function ActivityNewbeeFundAwardItem:ctor(go, parent)
	ActivityNewbeeFundAwardItem.super.ctor(self, go, parent)
end

function ActivityNewbeeFundAwardItem:initUI()
	local go = self.go
	self.itemNode = go:NodeByName("itemNode").gameObject
	self.reqBtn = go:ComponentByName("reqBtn", typeof(UITexture))
	self.label_ = go:ComponentByName("label_", typeof(UILabel))

	xyd.setUITextureByNameAsync(self.reqBtn, "activity_year_fund_icon_" .. xyd.Global.lang, true)
	self.reqBtn:AddComponent(typeof(UIDragScrollView))

	UIEventListener.Get(self.reqBtn.gameObject).onClick = function ()
		local cost = ActivityNewbeeFundTable:getCost(self.id)[2]
		local timeStamp = xyd.db.misc:getValue("activity_year_fund_time_stamp")

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_year_fund",
				wndType = self.curWindowType_,
				callback = function ()
					local crystal = xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)

					if cost <= crystal then
						xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, json.encode({
							table_id = self.id
						}))
					else
						xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH_CRYSTAL"))
					end
				end,
				text = __("ACTIVITY_YEAR_FUND_LATE_AWARD_TIP", cost)
			})
		else
			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_NEWBEE_FUND, json.encode({
				table_id = self.id
			}))
		end
	end
end

function ActivityNewbeeFundAwardItem:updateInfo()
	self.id = self.data.id
	self.state = self.data.state
	local isNew = ActivityNewbeeFundTable:isNew(self.id)

	if self.state == 1 then
		isNew = false
	end

	local awards = ActivityNewbeeFundTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.itemNode.transform)

	local item = xyd.getItemIcon({
		show_has_num = true,
		scale = 0.9537037037037037,
		isShowSelected = false,
		uiRoot = self.itemNode,
		itemID = awards[1],
		num = awards[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.parent.scrollView,
		isNew = isNew
	})

	if ActivityNewbeeFundTable:hasEffect(self.id) then
		item:setEffect(true, "fx_ui_bp_available", {
			effectPos = Vector3(0, 5, 0)
		})
	end

	self.reqBtn:SetActive(false)

	if self.state == 1 then
		item:setChoose(true)
	elseif self.state == 2 then
		self.reqBtn:SetActive(true)

		local flag = xyd.db.misc:getValue("activity_newbee_fund_red_mark_2") or 0

		if tonumber(flag) < self.id then
			xyd.db.misc:setValue({
				key = "activity_newbee_fund_red_mark_2",
				value = self.id
			})
		end
	end

	self.label_.text = __("ACTIVITY_WEEK_DATE", self.id)
end

return ActivityNewbeeFund
