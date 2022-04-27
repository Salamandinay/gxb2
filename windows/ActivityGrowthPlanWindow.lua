local BaseWindow = import(".BaseWindow")
local ActivityGrowthPlanWindow = class("ActivityGrowthPlanWindow", BaseWindow)
local ActivityGrowthPlanItem = class("ActivityGrowthPlanItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local GiftBagTextTable = xyd.tables.giftBagTextTable
local activityGrowthPlanTable = xyd.tables.activityGrowthPlanTable

function ActivityGrowthPlanWindow:ctor(name, params)
	self.id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN
	self.giftBagID = xyd.tables.activityTable:getGiftBag(self.id)[1] or 334
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)

	BaseWindow.ctor(self, name, params)
end

function ActivityGrowthPlanWindow:playOpenAnimation(callback)
	ActivityGrowthPlanWindow.super.playOpenAnimation(self, function ()
		self:initContent()

		if callback then
			callback()
		end
	end)
end

function ActivityGrowthPlanWindow:initWindow()
	ActivityGrowthPlanWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	self:reqData()
	self:resizeToParent()
end

function ActivityGrowthPlanWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.textImg_ = groupAction:ComponentByName("textImg_", typeof(UITexture))
	self.partnerImg = groupAction:ComponentByName("partnerImgGroup/partnerImg", typeof(UITexture))
	self.partnerImgGroup = groupAction:NodeByName("partnerImgGroup").gameObject
	self.jianyingImg = groupAction:ComponentByName("jianyingImg", typeof(UITexture))
	self.desLabel_ = groupAction:ComponentByName("desGroup/desScroller/desLabel_", typeof(UILabel))
	self.timeLayout = groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = groupAction:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.endLabel_ = groupAction:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.expLabel_ = groupAction:ComponentByName("expLabel_", typeof(UILabel))
	self.scoreLabel_ = groupAction:ComponentByName("scoreLabel_", typeof(UILabel))
	self.tipLabel_ = groupAction:ComponentByName("tipLabel_", typeof(UILabel))
	self.addBtn_ = groupAction:NodeByName("addBtn_").gameObject
	self.addBtnSprite = self.addBtn_:GetComponent(typeof(UISprite))
	self.buyBtn_ = groupAction:NodeByName("buyBtn_").gameObject
	self.buyBtn_label = self.buyBtn_:ComponentByName("button_label", typeof(UILabel))
	self.progress = groupAction:ComponentByName("progressGroup", typeof(UISlider))
	self.progressBar = self.progress:ComponentByName("progressBar", typeof(UISprite))
	self.progress_label = groupAction:ComponentByName("progressGroup/progressLabel_", typeof(UILabel))
	self.helpBtn_ = groupAction:NodeByName("helpBtn_").gameObject
	self.awardBtn_ = groupAction:NodeByName("awardBtn_").gameObject
	self.choosePartnerBtn_ = groupAction:NodeByName("choosePartnerBtn_").gameObject
	self.labelChoosePartnerBtn_ = self.choosePartnerBtn_:ComponentByName("button_label", typeof(UILabel))
	self.changePartnerBtn_ = groupAction:NodeByName("changePartnerBtn_").gameObject
	self.labelChangePartnerBtn_ = self.changePartnerBtn_:ComponentByName("button_label", typeof(UILabel))
	self.getAllAwardBtn_ = groupAction:NodeByName("getAllAwardBtn_").gameObject
	self.labelGetAllAwardBtn_ = self.getAllAwardBtn_:ComponentByName("button_label", typeof(UILabel))
	self.gotoBtn_ = groupAction:NodeByName("gotoBtn_").gameObject
	self.labelGotoBtn_ = self.gotoBtn_:ComponentByName("button_label", typeof(UILabel))
	self.clickArea = groupAction:NodeByName("clickArea").gameObject
	self.bubble = groupAction:NodeByName("bubble").gameObject
	self.bubbleLabel_ = self.bubble:ComponentByName("label", typeof(UILabel))
	local contentGroup = groupAction:NodeByName("contentGroup").gameObject
	self.textLabel01_ = contentGroup:ComponentByName("textLabel01_", typeof(UILabel))
	self.textLabel02_ = contentGroup:ComponentByName("textLabel02_", typeof(UILabel))
	self.textLabel03_ = contentGroup:ComponentByName("textLabel03_", typeof(UILabel))
	self.scrollView = contentGroup:ComponentByName("scroller_", typeof(UIScrollView))
	self.scrollerPanel = contentGroup:ComponentByName("scroller_", typeof(UIPanel))
	self.itemGroup = contentGroup:NodeByName("scroller_/itemGroup").gameObject
	self.scrollerItem = contentGroup:NodeByName("scroller_/artifact_shop_warm_up_item").gameObject
end

function ActivityGrowthPlanWindow:initUIComponent()
	xyd.setUITextureByNameAsync(self.textImg_, "activity_growth_plan_logo_" .. xyd.Global.lang, true)

	self.desLabel_.text = __("ACTIVITY_GROWTH_PLAN_TEXT12")
	self.endLabel_.text = __("END")
	self.scoreLabel_.text = __("ACTIVITY_GROWTH_PLAN_TEXT04")
	self.textLabel01_.text = __("ACTIVITY_GROWTH_PLAN_TEXT08")
	self.textLabel02_.text = __("ACTIVITY_GROWTH_PLAN_TEXT09")
	self.textLabel03_.text = __("ACTIVITY_GROWTH_PLAN_TEXT10")
	self.tipLabel_.text = __("ACTIVITY_GROWTH_PLAN_TEXT11")
	self.labelGotoBtn_.text = __("ACTIVITY_GROWTH_PLAN_TEXT05")
	self.labelGetAllAwardBtn_.text = __("ACTIVITY_GROWTH_PLAN_TEXT07")
	self.labelChoosePartnerBtn_.text = __("ACTIVITY_GROWTH_PLAN_TEXT01")
	self.labelChangePartnerBtn_.text = __("ACTIVITY_GROWTH_PLAN_TEXT06")
	self.expLabel_.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.buyBtn_label.text = GiftBagTextTable:getCurrency(self.giftBagID) .. " " .. GiftBagTextTable:getCharge(self.giftBagID)

	if xyd.Global.lang == "en_en" then
		self.addBtn_:X(-126)
	end
end

function ActivityGrowthPlanWindow:register()
	ActivityGrowthPlanWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onGetData))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
	self.eventProxy_:addEventListener(xyd.event.BATTLE_PASS_SP_BUY_POINT, handler(self, self.onGetResitScoreMsg))
	self.eventProxy_:addEventListener(xyd.event.BATTLE_PASS_SP_SET_INDEX, handler(self, self.onConfirmPartner))

	UIEventListener.Get(self.buyBtn_).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID)
	end

	UIEventListener.Get(self.addBtn_).onClick = function ()
		if self.addFlag then
			xyd.openWindow("activity_growth_plan_score_window")
		else
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_GROWTH_PLAN_TEXT14"))
		end
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_GROWTH_PLAN_TEXT13"
		})
	end

	UIEventListener.Get(self.awardBtn_).onClick = function ()
		if self.activityData:getSelectedPartnerID() then
			xyd.openWindow("activity_growth_plan_award_window")
		else
			xyd.alertTips(__("ACTIVITY_GROWTH_PLAN_TEXT17"))
		end
	end

	UIEventListener.Get(self.clickArea).onClick = function ()
	end

	UIEventListener.Get(self.gotoBtn_).onClick = function ()
		xyd.db.misc:setValue({
			key = "growth_plan_goto_time_stamp",
			value = xyd.getServerTime()
		})

		local getwayID = xyd.tables.miscTable:split2Cost("activity_tea_getway", "value", "|")[1] or 14

		xyd.goWay(getwayID, nil, function ()
			xyd.closeWindow("activity_growth_plan_window")
		end)
	end

	UIEventListener.Get(self.changePartnerBtn_).onClick = function ()
		xyd.openWindow("activity_growth_plan_choose_partner_window", {
			closeCallBack = function ()
				self:initContent()
			end
		})
	end

	UIEventListener.Get(self.choosePartnerBtn_).onClick = function ()
		xyd.openWindow("activity_growth_plan_choose_partner_window", {
			closeCallBack = function ()
				self:initContent()
			end
		})
	end

	UIEventListener.Get(self.getAllAwardBtn_).onClick = function ()
		self:getAward()
	end
end

function ActivityGrowthPlanWindow:reqData()
	self.activityData = xyd.models.activity:getActivity(self.id)

	if self.activityData then
		xyd.models.activity:reqActivityByID(self.id)
	end
end

function ActivityGrowthPlanWindow:initContent()
	if self.getData and self:isWndComplete() then
		CountDown.new(self.timeLabel_, {
			duration = self.activityData:getEndTime() - xyd.getServerTime()
		})

		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))

		if not self.wrapContent then
			self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.scrollerItem, ActivityGrowthPlanItem, self)
		end

		if xyd.Global.lang == "fr_fr" then
			self.endLabel_.transform:SetSiblingIndex(0)
		end

		self.timeLayout:Reposition()
		self:initData()
		self:updatePartnerGroup()
		self:updateContentGroup()
		self:updateBtnBuyGiftbag()
		self:updateBtn2()
		self:updateProgress()
		self:updateRedMark()
		self:updateBtn3()
	end
end

function ActivityGrowthPlanWindow:onGetData(event)
	self.activityData = xyd.models.activity:getActivity(self.id)
	self.getData = true

	self:initContent()
end

function ActivityGrowthPlanWindow:initData()
	self.has_buy = self.activityData:getHasBuyGiftbag()
	self.point = self.activityData:getNowPoint()
	self.selectedPartnerID = self.activityData:getSelectedPartnerID()
	self.confirmedPartnerID = self.activityData:getConfirmedPartnerID()
end

function ActivityGrowthPlanWindow:updateContentGroup()
	local ids = activityGrowthPlanTable:getIDs()
	local data = {}

	for i = 1, #ids do
		local score = activityGrowthPlanTable:getPoint(i)
		local baseIsAwarded = self.activityData:getBaseIsAwarded(i)
		local extraIsAwarded = self.activityData:getExtraIsAwarded(i)
		local canGetAward = score <= self.point and baseIsAwarded == false or self.has_buy == true and score <= self.point and extraIsAwarded == false

		table.insert(data, {
			id = i,
			score = score,
			isComplete = score <= self.point,
			hasBuy = self.has_buy,
			baseIsAwarded = baseIsAwarded,
			extraIsAwarded = extraIsAwarded,
			canGetAward = canGetAward,
			panel = self.scrollerPanel
		})
	end

	table.sort(data, function (a, b)
		if a.canGetAward ~= b.canGetAward then
			return xyd.bool2Num(b.canGetAward) < xyd.bool2Num(a.canGetAward)
		elseif a.isComplete ~= b.isComplete then
			return xyd.bool2Num(a.isComplete) < xyd.bool2Num(b.isComplete)
		else
			return a.id < b.id
		end
	end)

	self.lastID = data[#ids].id

	self.wrapContent:setInfos(data, {})
end

function ActivityGrowthPlanWindow:updatePartnerGroup()
	if self.selectedPartnerID == nil and self.confirmedPartnerID == nil then
		self.choosePartnerBtn_:SetActive(true)
		self.changePartnerBtn_:SetActive(false)
	elseif self.confirmedPartnerID == nil then
		self.choosePartnerBtn_:SetActive(false)
		self.changePartnerBtn_:SetActive(true)
	else
		self.choosePartnerBtn_:SetActive(false)
		self.changePartnerBtn_:SetActive(false)
	end

	if self.selectedPartnerID == nil then
		self.jianyingImg:SetActive(true)
		self.partnerImg:SetActive(false)
	else
		self.jianyingImg:SetActive(false)

		local xy = xyd.tables.partnerPictureTable:getPartnerPicXY(self.selectedPartnerID)
		local scale = xyd.tables.partnerPictureTable:getPartnerPicScale(self.selectedPartnerID)

		xyd.setUITextureByNameAsync(self.partnerImg, "partner_picture_" .. self.selectedPartnerID, false, function ()
			local pic_params = xyd.tables.miscTable:split2Cost("activity_growth_plan_picture", "value", "|#")[self.activityData:getCurPartnerIndex()]
			local cut_params = xyd.tables.miscTable:split2Cost("activity_growth_plan_cut", "value", "|#")[self.activityData:getCurPartnerIndex()]

			if xy and scale then
				self.partnerImg.gameObject.transform:SetLocalPosition(pic_params[1], pic_params[2], 0)
				self.partnerImg.gameObject.transform:SetLocalScale(pic_params[3], pic_params[4], 1)

				self.partnerImg.border = Vector4(0, 0, 0, 0)
			end

			self.partnerImg:SetActive(true)

			self.partnerImg.width = xyd.getTextureRealSize("partner_picture_" .. self.selectedPartnerID).width
			self.partnerImg.height = xyd.getTextureRealSize("partner_picture_" .. self.selectedPartnerID).height

			if cut_params[1] then
				self.partnerImg.border = Vector4(cut_params[3], cut_params[1], cut_params[4], cut_params[2])
			else
				self.partnerImg.border = Vector4(400, 1010, 410, 100)
			end
		end)
	end
end

function ActivityGrowthPlanWindow:updateBtnBuyGiftbag()
	if self.has_buy then
		xyd.setEnabled(self.buyBtn_, false)
	else
		xyd.setEnabled(self.buyBtn_, true)
	end
end

function ActivityGrowthPlanWindow:updateBtn2()
	local canResitScore = self.activityData:getCanResitScore()

	if canResitScore > 0 then
		self.addFlag = true
	else
		self.addFlag = false
	end
end

function ActivityGrowthPlanWindow:updateBtn3()
	if self.activityData:checkRedPointOfCanGetAward() == true then
		xyd.applyChildrenOrigin(self.getAllAwardBtn_.gameObject)
	else
		xyd.applyChildrenGrey(self.getAllAwardBtn_.gameObject)
	end

	xyd.setEnabled(self.getAllAwardBtn_, self.activityData:checkRedPointOfCanGetAward())
end

function ActivityGrowthPlanWindow:updateProgress()
	local nextLayerPoint = 0
	local ids = activityGrowthPlanTable:getIDs()

	for i = 1, #ids do
		local point = activityGrowthPlanTable:getPoint(i)

		if i == #ids or self.point < point then
			nextLayerPoint = point

			break
		end
	end

	self.progress_label.text = self.point .. "/" .. nextLayerPoint
	self.progressBar.fillAmount = math.min(self.point / nextLayerPoint, 1)
end

function ActivityGrowthPlanWindow:onRecharge()
	self.has_buy = true

	self:updateBtnBuyGiftbag()
	self:updateContentGroup()
end

function ActivityGrowthPlanWindow:onGetResitScoreMsg(event)
	self.point = self.activityData.detail.point

	self:initContent()
end

function ActivityGrowthPlanWindow:onConfirmPartner(event)
	self:getAward()
end

function ActivityGrowthPlanWindow:updateRedMark()
	self.gotoBtn_:NodeByName("red_point").gameObject:SetActive(self.activityData:checkRedPointOfGoto())
	self.choosePartnerBtn_:NodeByName("red_point").gameObject:SetActive(self.activityData:checkRedPointOfChoosePartner())
	self.getAllAwardBtn_:NodeByName("red_point").gameObject:SetActive(self.activityData:checkRedPointOfCanGetAward())
	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_GROWTH_PLAN, self.activityData:getRedMarkState())
end

function ActivityGrowthPlanWindow:resizeToParent()
end

function ActivityGrowthPlanWindow:getAward()
	if self.activityData:getSelectedPartnerID() == nil then
		xyd.alertTips(__("ACTIVITY_GROWTH_PLAN_TEXT17"))

		return
	end

	local awards = self.activityData.detail.awarded
	local ex_awards = self.activityData.detail.paid_awarded
	local nowPoint = self.activityData.detail.point
	local ids = activityGrowthPlanTable:getIDs()
	local data = {}

	for i = 1, #ids do
		local id = tonumber(ids[i])

		if activityGrowthPlanTable:getPoint(id) <= nowPoint then
			if ex_awards[id] == 0 and self.activityData:getHasBuyGiftbag() == true then
				table.insert(data, {
					index = 2,
					id = id
				})
			end

			if awards[id] == 0 then
				table.insert(data, {
					index = 1,
					id = id
				})
			end
		end
	end

	if data[1] == nil then
		return
	end

	if self.activityData:getConfirmedPartnerID() == nil then
		local function callback(flag)
			if flag == true then
				local msg = messages_pb:battle_pass_sp_set_index_req()
				msg.index = self.activityData:getCurPartnerIndex()
				msg.activity_id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN

				xyd.Backend.get():request(xyd.mid.BATTLE_PASS_SP_SET_INDEX, msg)
			end
		end

		xyd.alertYesNo(__("ACTIVITY_GROWTH_PLAN_TEXT18"), callback, __("YES"), false, nil, __("ACTIVITY_GROWTH_PLAN_TEXT01"), nil, , , )

		return
	end

	local params = require("cjson").encode({
		batches = data
	})
	local msg = messages_pb:get_activity_award_req()
	msg.params = params
	msg.activity_id = xyd.ActivityID.ACTIVITY_GROWTH_PLAN

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityGrowthPlanWindow:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)
	local allItem = {}

	if data then
		local json = require("cjson")
		local detail = json.decode(data.detail)
		local realData = {}

		for i = 1, #detail.batch_result do
			local items = detail.batch_result[i].items

			for j = 1, #items do
			end

			xyd.models.itemFloatModel:pushNewItems(items)
		end

		self:initContent()
	end
end

function ActivityGrowthPlanItem:ctor(go, parent)
	ActivityGrowthPlanItem.super.ctor(self, go, parent)

	self.baseItems = {}
	self.extraItems = {}
end

function ActivityGrowthPlanItem:initUI()
	local go = self.go
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.baseAwardGroup = go:NodeByName("baseAwardGroup").gameObject
	self.extraAwardGroup = go:NodeByName("extraAwardGroup").gameObject
	self.layout1 = self.baseAwardGroup:GetComponent(typeof(UILayout))
	self.layout2 = self.extraAwardGroup:GetComponent(typeof(UILayout))
	self.clickMask = go:NodeByName("clickMask").gameObject
	self.fgx = go:NodeByName("fgx")
	self.imgUnknow = go:NodeByName("imgUnknow").gameObject

	if not self.baseItemIcons or not self.baseHeroIcon then
		self.baseItemIcons = {}
		self.baseHeroIcons = {}

		for i = 1, 3 do
			local baseItemIcon = xyd.getItemIcon({
				scale = 0.5555555555555556,
				uiRoot = self.baseAwardGroup,
				dragScrollView = self.parent.scrollView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			table.insert(self.baseItemIcons, baseItemIcon)

			local baseHeroIcon = xyd.getItemIcon({
				scale = 0.5555555555555556,
				uiRoot = self.baseAwardGroup,
				dragScrollView = self.parent.scrollView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.HERO_ICON)

			table.insert(self.baseHeroIcons, baseHeroIcon)
		end
	end

	if not self.extraItemIcons or not self.extraHeroIcons then
		self.extraItemIcons = {}
		self.extraHeroIcons = {}

		for i = 1, 3 do
			local extraItemIcon = xyd.getItemIcon({
				scale = 0.5555555555555556,
				uiRoot = self.extraAwardGroup,
				dragScrollView = self.parent.scrollView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			table.insert(self.extraItemIcons, extraItemIcon)

			local extraHeroIcon = xyd.getItemIcon({
				scale = 0.5555555555555556,
				uiRoot = self.extraAwardGroup,
				dragScrollView = self.parent.scrollView,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			}, xyd.ItemIconType.HERO_ICON)

			table.insert(self.extraHeroIcons, extraHeroIcon)
		end
	end
end

function ActivityGrowthPlanItem:updateInfo()
	self.id = self.data.id
	self.score = self.data.score
	self.isComplete = self.data.isComplete
	self.hasBuy = self.data.hasBuy
	self.baseIsAwarded = self.data.baseIsAwarded
	self.extraIsAwarded = self.data.extraIsAwarded
	self.scoreLabel_.text = self.score
	self.panel = self.data.panel
	local partnerNum = #xyd.tables.miscTable:split2Cost("activity_growth_plan_partner", "value", "|")

	if self.imgUnknow_base then
		self.imgUnknow_base:SetActive(false)
	end

	if self.imgUnknow_extra then
		self.imgUnknow_extra:SetActive(false)
	end

	if self.parent.lastID and self.id == self.parent.lastID then
		self.fgx:SetActive(false)
	else
		self.fgx:SetActive(true)
	end

	if self.isComplete and not self.baseIsAwarded or self.isComplete and not self.extraIsAwarded and self.hasBuy then
		self.clickMask:SetActive(true)

		UIEventListener.Get(self.clickMask).onClick = function ()
			if self.isComplete and not self.baseIsAwarded or self.isComplete and not self.extraIsAwarded and self.hasBuy then
				self:onTouchAward()
			end
		end
	else
		self.clickMask:SetActive(false)
	end

	local baseAwardData = {}
	local baseAwardData = activityGrowthPlanTable:getStableFreeAward(self.id)
	local baseUnknowAward = activityGrowthPlanTable:getUnknownFreeAward(self.id)

	if baseUnknowAward and baseUnknowAward[1] then
		if self.parent.selectedPartnerID == nil then
			for i = 1, #baseUnknowAward[1] do
				table.insert(baseAwardData, {
					baseUnknowAward[1][1][1],
					baseUnknowAward[1][1][2],
					[3.0] = 1
				})
			end
		else
			local index = self.parent.activityData:getCurPartnerIndex()

			for i = 1, #baseUnknowAward[index] do
				table.insert(baseAwardData, {
					baseUnknowAward[index][i][1],
					baseUnknowAward[index][i][2],
					[3.0] = 0
				})
			end
		end
	end

	for i = 1, 3 do
		self.baseItemIcons[i]:SetActive(false)
		self.baseHeroIcons[i]:SetActive(false)
	end

	self.baseIcons = {}

	for i = 1, #baseAwardData do
		local award = baseAwardData[i]
		local type = xyd.tables.itemTable:getType(award[1])

		if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
			self.baseIcons[i] = self.baseHeroIcons[i]
		else
			self.baseIcons[i] = self.baseItemIcons[i]
		end

		if award[3] == 1 then
			if not self.imgUnknow_base then
				self.imgUnknow_base = NGUITools.AddChild(self.baseAwardGroup.gameObject, self.imgUnknow.gameObject)
			end

			self.imgUnknow_base:SetActive(true)
			self.baseIcons[i]:getIconRoot():SetActive(false)
		else
			if self.imgUnknow_base then
				self.imgUnknow_base:SetActive(false)
			end

			self.baseIcons[i]:getIconRoot():SetActive(true)
		end

		local params = {
			show_has_num = true,
			scale = 0.5555555555555556,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView,
			panel = self.panel,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		if self.isComplete and not self.baseIsAwarded then
			params.effect = "bp_available"
		end

		self.baseIcons[i]:setEffectState(false)
		self.baseIcons[i]:setInfo(params)

		if params.effect then
			self.baseIcons[i]:setPartExampleVisible("gEffect", true)
		end

		if not self.isComplete then
			self.baseIcons[i]:setMask(true)
			self.baseIcons[i]:setChoose(false)
		elseif self.baseIsAwarded then
			self.baseIcons[i]:setMask(false)
			self.baseIcons[i]:setChoose(true)
		else
			self.baseIcons[i]:setChoose(false)
			self.baseIcons[i]:setMask(false)
		end
	end

	self.layout1:Reposition()

	local extraAwardData = {}
	local extraAwardData = activityGrowthPlanTable:getStablePaidAward(self.id)
	local extraUnknowAward = activityGrowthPlanTable:getUnknownPaidAward(self.id)

	if extraUnknowAward and extraUnknowAward[1] then
		if self.parent.selectedPartnerID == nil then
			for i = 1, #extraUnknowAward[1] do
				table.insert(extraAwardData, {
					extraUnknowAward[1][1][1],
					extraUnknowAward[1][1][2],
					[3.0] = 1
				})
			end
		else
			local index = self.parent.activityData:getCurPartnerIndex()

			for i = 1, #extraUnknowAward[index] do
				table.insert(extraAwardData, {
					extraUnknowAward[index][i][1],
					extraUnknowAward[index][i][2],
					[3.0] = 0
				})
			end
		end
	end

	local lightShow = activityGrowthPlanTable:getLightShow(self.id)
	local j = 1

	for i = 1, #extraAwardData do
		if lightShow and j <= #lightShow then
			if lightShow[j] == i then
				extraAwardData[i][4] = true
				j = j + 1
			else
				extraAwardData[i][4] = false
			end
		end
	end

	for i = 1, 3 do
		self.extraItemIcons[i]:SetActive(false)
		self.extraHeroIcons[i]:SetActive(false)
	end

	self.extraIcons = {}

	for i = 1, #extraAwardData do
		local award = extraAwardData[i]
		local type = xyd.tables.itemTable:getType(award[1])

		if type == xyd.ItemType.HERO or type == xyd.ItemType.HERO_DEBRIS or type == xyd.ItemType.HERO_RANDOM_DEBRIS then
			self.extraIcons[i] = self.extraHeroIcons[i]
		else
			self.extraIcons[i] = self.extraItemIcons[i]
		end

		if award[3] == 1 then
			if not self.imgUnknow_extra then
				self.imgUnknow_extra = NGUITools.AddChild(self.extraAwardGroup.gameObject, self.imgUnknow.gameObject)
			end

			self.imgUnknow_extra:SetActive(true)
			self.extraIcons[i]:getIconRoot():SetActive(false)
		else
			if self.imgUnknow_extra then
				self.imgUnknow_extra:SetActive(false)
			end

			self.extraIcons[i]:getIconRoot():SetActive(true)
		end

		local params = {
			show_has_num = true,
			scale = 0.5555555555555556,
			itemID = award[1],
			num = award[2],
			dragScrollView = self.parent.scrollView,
			panel = self.panel,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}
		local effect = nil

		if self.hasBuy and self.isComplete and not self.extraIsAwarded then
			params.effect = "bp_available"
		elseif award[4] == true then
			effect = "bp_item"
		end

		self.extraIcons[i]:setEffectState(false)
		self.extraIcons[i]:setBackEffect(false)
		self.extraIcons[i]:setInfo(params)

		if effect == "bp_item" then
			self.extraIcons[i]:setBackEffect(true, effect, "texiao01", {
				effectPos = Vector3(9, -3, 0),
				scale = Vector3(1.1, 1.1, 1.1),
				panel_ = self.panel
			})
		end

		if not self.hasBuy then
			self.extraIcons[i]:setLock(true)
		elseif not self.isComplete then
			self.extraIcons[i]:setLock(false)
			self.extraIcons[i]:setChoose(false)
			self.extraIcons[i]:setMask(false)
		elseif self.extraIsAwarded then
			self.extraIcons[i]:setLock(false)
			self.extraIcons[i]:setChoose(true)
		else
			self.extraIcons[i]:setLock(false)
			self.extraIcons[i]:setChoose(false)
			self.extraIcons[i]:setMask(false)
		end
	end

	self.layout2:Reposition()
end

function ActivityGrowthPlanItem:onTouchAward()
	self.parent:getAward()
end

return ActivityGrowthPlanWindow
