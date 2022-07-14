local ActivityCupidGift = class("ActivityCupidGift", import(".ActivityContent"))
local ActivityCupidGiftItem = class("ActivityCupidGiftItem", import("app.components.CopyComponent"))
local cjson = require("cjson")
local CountDown = import("app.components.CountDown")

function ActivityCupidGift:ctor(parentGO, params)
	ActivityCupidGift.super.ctor(self, parentGO, params)
end

function ActivityCupidGift:getPrefabPath()
	return "Prefabs/Windows/activity/activity_cupid_gift"
end

function ActivityCupidGift:resizeToParent()
	ActivityCupidGift.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height
	local heightDis = allHeight - 874
end

function ActivityCupidGift:initUI()
	xyd.db.misc:setValue({
		key = "activity_cupid_gift_openTime",
		value = xyd.getServerTime()
	})

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_CUPID_GIFT)
	self.items = {}

	self:getUIComponent()
	ActivityCupidGift.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityCupidGift:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UITexture))
	self.titleImg_ = self.groupAction:ComponentByName("titleImg_", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnPreview = self.groupAction:NodeByName("btnPreview").gameObject
	self.angleEffectPos = self.groupAction:ComponentByName("angleEffectPos", typeof(UITexture))
	self.dateGroup = self.groupAction:NodeByName("dateGroup").gameObject
	self.labelDate = self.dateGroup:ComponentByName("labelDate", typeof(UILabel))
	self.btnSingle = self.groupAction:NodeByName("btnSingle").gameObject
	self.labelSingle = self.btnSingle:ComponentByName("labelSingle", typeof(UILabel))
	self.redPointSingle = self.btnSingle:ComponentByName("redPoint", typeof(UISprite))
	self.btnMax = self.groupAction:NodeByName("btnMax").gameObject
	self.labelMax = self.btnMax:ComponentByName("labelMax", typeof(UILabel))
	self.redPointMax = self.btnMax:ComponentByName("redPoint", typeof(UISprite))
	self.timeGroup = self.groupAction:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.groupAction:ComponentByName("timeGroup", typeof(UILayout))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.TipsGroup = self.groupAction:NodeByName("TipsGroup").gameObject
	self.labelTips = self.TipsGroup:ComponentByName("labelTips", typeof(UILabel))
	self.giftGroup = self.groupAction:NodeByName("giftGroup").gameObject
	self.giftTimeGroup = self.giftGroup:NodeByName("giftTimeGroup").gameObject
	self.giftTimeGroupLayout = self.giftGroup:ComponentByName("giftTimeGroup", typeof(UILayout))
	self.giftTimeLabel_ = self.giftTimeGroup:ComponentByName("giftTimeLabel_", typeof(UILabel))
	self.giftEndLabel_ = self.giftTimeGroup:ComponentByName("giftEndLabel_", typeof(UILabel))
	self.labelTitle1 = self.giftGroup:ComponentByName("labelTitle1", typeof(UILabel))
	self.labelTitle2 = self.giftGroup:ComponentByName("labelTitle2", typeof(UILabel))
	self.labelDesc = self.giftGroup:ComponentByName("labelDesc", typeof(UILabel))
	self.labelExp = self.giftGroup:ComponentByName("labelExp", typeof(UILabel))
	self.itemGroup = self.giftGroup:NodeByName("itemGroup").gameObject
	self.itemGroupLayout = self.giftGroup:ComponentByName("itemGroup", typeof(UILayout))
	self.awardItem = self.giftGroup:NodeByName("awardItem").gameObject
	self.btnPlus = self.awardItem:NodeByName("btnPlus").gameObject
	self.giftbagBuyBtn = self.giftGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagBuyBtnLabel = self.giftbagBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
end

function ActivityCupidGift:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = nil

		if data.activity_id == xyd.ActivityID.ACTIVITY_CUPID_GIFT then
			if data and data.detail and data.detail ~= {} and data.detail ~= "" then
				detail = cjson.decode(data.detail)
			else
				detail = {}
			end

			local awards = {}

			if detail then
				for index, value in ipairs(detail) do
					table.insert(awards, {
						item_id = value[1],
						item_num = value[2]
					})
				end

				self.angleEffect:play("texiao_03", 1, 1, function ()
					xyd.openWindow("gamble_rewards_window", {
						wnd_type = 2,
						data = awards
					})
					self:initData()
					self:updateGiftGroup()
					self:updateGambleGroup()
					xyd.setTouchEnable(self.btnSingle, true)
					xyd.setTouchEnable(self.btnMax, true)
				end, true)
			end
		end
	end)
	self:registerEvent(xyd.event.STAY_SET_ATTACH_INDEX, function (event)
		xyd.SdkManager.get():showPayment(self.activityData:getCurGiftBagID())
	end)
	self:registerEvent(xyd.event.RECHARGE, function (event)
		self.needCheckUnlockEffect = true

		xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_CUPID_GIFT)
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_INFO_BY_ID, function (event)
		local activity_id = event.data.activity_id

		if activity_id ~= xyd.ActivityID.ACTIVITY_CUPID_GIFT then
			return
		end

		if self.needCheckUnlockEffect and self.activityData:getCurGiftIndex() == 2 then
			self.angleEffect:play("texiao_02", 1, 1, function ()
				self:initData()
				self:updateGiftGroup()
				self:updateGambleGroup()
			end, true)
		else
			self:initData()
			self:updateGiftGroup()
			self:updateGambleGroup()
		end

		self.needCheckUnlockEffect = false
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_CUPID_GIFT_HELP"
		})
	end

	UIEventListener.Get(self.btnSingle).onClick = function ()
		if self.activityData:getMaxHaveBuyGiftIndex() == 0 then
			xyd.alertTips(__("ACTIVITY_CUPID_GIFT_TEXT3"))

			return
		elseif self.activityData:getNowLeftTime() <= 0 then
			xyd.alertTips(__("ACTIVITY_CUPID_GIFT_TEXT11"))

			return
		end

		xyd.setTouchEnable(self.btnSingle, false)
		xyd.setTouchEnable(self.btnMax, false)
		self.activityData:reqSummon(1)
	end

	UIEventListener.Get(self.btnMax).onClick = function ()
		if self.activityData:getMaxHaveBuyGiftIndex() == 0 then
			xyd.alertTips(__("ACTIVITY_CUPID_GIFT_TEXT3"))

			return
		elseif self.activityData:getNowLeftTime() < 5 then
			xyd.alertTips(__("ACTIVITY_CUPID_GIFT_TEXT11"))

			return
		end

		xyd.setTouchEnable(self.btnSingle, false)
		xyd.setTouchEnable(self.btnMax, false)
		self.activityData:reqSummon(5)
	end

	UIEventListener.Get(self.giftbagBuyBtn).onClick = function ()
		if self.activityData:getChooseAwardIndex() > 0 then
			self.activityData:reqSelectSpecialAward()
		else
			xyd.alertTips(__("ACTIVITY_CUPID_GIFT_TEXT10"))
		end
	end

	UIEventListener.Get(self.btnPreview).onClick = function ()
		xyd.WindowManager:get():openWindow("common_preview_with_change_window", {
			box_id = 32019,
			title = __("ACTIVITY_AWARD_PREVIEW_TITLE")
		})
	end
end

function ActivityCupidGift:initData()
	self.curGiftIndex = self.activityData:getCurGiftIndex()
	self.curGiftBagID = self.activityData:getCurGiftBagID()
	self.curGiftID = self.activityData:getCurGiftID()
end

function ActivityCupidGift:initUIComponent()
	self.labelSingle.text = __("ACTIVITY_CUPID_GIFT_TEXT1")
	self.labelMax.text = __("ACTIVITY_CUPID_GIFT_TEXT12")
	self.labelTips.text = __("ACTIVITY_CUPID_GIFT_TEXT3")
	self.labelTitle1.text = __("ACTIVITY_CUPID_GIFT_TEXT4")
	self.labelTitle2.text = __("ACTIVITY_CUPID_GIFT_TEXT5")
	self.endLabel_.text = __("END")
	self.giftEndLabel_.text = __("END")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "ja_jp" then
		self.labelTips.height = 20
		self.labelTips.width = 500
	elseif xyd.Global.lang == "en_en" then
		self.labelTips.height = 22
		self.labelTips.width = 650
		self.labelTips.fontSize = 22
	end

	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_cupid_gift_logo_" .. xyd.Global.lang)
	self:initData()
	self:updateGiftGroup()
	self:updateGambleGroup()
end

function ActivityCupidGift:updateGiftGroup()
	if self.curGiftIndex == 0 then
		self.giftGroup:SetActive(false)
	else
		self.giftGroup:SetActive(true)
	end

	if self.curGiftIndex > 0 and not self.giftCountDown then
		self.giftTimeGroup:SetActive(true)

		self.giftCountDown = CountDown.new(self.giftTimeLabel_, {
			duration = self.activityData:getNowGiftEndTime() - xyd.getServerTime()
		})

		if xyd.Global.lang == "fr_fr" then
			self.giftEndLabel_.transform:SetSiblingIndex(0)
		end

		self.giftTimeGroupLayout:Reposition()
	elseif self.curGiftIndex > 0 and self.giftCountDown then
		self.giftTimeGroup:SetActive(true)
		self.giftCountDown:setCountDownTime(self.activityData:getNowGiftEndTime() - xyd.getServerTime())
	else
		self.giftTimeGroup:SetActive(false)
	end

	self.labelDesc.text = __("ACTIVITY_CUPID_GIFT_TEXT6", xyd.tables.activityCupidGiftAwardTable:getDrawTimes(self.curGiftBagID))
	self.labelExp.text = __("MONTH_CARD_VIP", self.activityData:getExp(self.curGiftBagID))
	local leftWeek = math.floor((self.activityData:getEndTime() - xyd.getServerTime()) / 604800)

	if leftWeek > 0 then
		self.dateGroup:SetActive(true)
		self.timeGroup:SetActive(false)

		self.labelDate.text = __("ACTIVITY_CUPID_GIFT_TEXT9", leftWeek)

		if not self.activityData:haveBuyAnyGift() then
			self.labelTips.text = __("ACTIVITY_CUPID_GIFT_TEXT3")
		else
			self.labelTips.text = __("ACTIVITY_CUPID_GIFT_TEXT7", self.activityData:getNowLeftTime(), self.activityData:getTimesPerWeek()) .. "  " .. __("ACTIVITY_CUPID_GIFT_TEXT8")

			if xyd.Global.lang == "fr_fr" then
				self.labelTips.height = 40
				self.labelTips.width = 650
				self.labelTips.fontSize = 14
			end
		end
	else
		self.dateGroup:SetActive(false)
		self.timeGroup:SetActive(true)

		if not self.countDown then
			self.countDown = CountDown.new(self.timeLabel_, {
				duration = self.activityData:getEndTime() - xyd.getServerTime()
			})

			if xyd.Global.lang == "fr_fr" then
				self.endLabel_.transform:SetSiblingIndex(0)
			end

			self.timeGroupLayout:Reposition()
		else
			self.countDown:setCountDownTime(self.activityData:getEndTime() - xyd.getServerTime())
		end

		if not self.activityData:haveBuyAnyGift() then
			self.labelTips.text = __("ACTIVITY_CUPID_GIFT_TEXT3")
		else
			self.labelTips.text = __("ACTIVITY_CUPID_GIFT_TEXT7", self.activityData:getNowLeftTime(), self.activityData:getTimesPerWeek())

			if xyd.Global.lang == "fr_fr" then
				self.labelTips.height = 40
				self.labelTips.width = 650
				self.labelTips.fontSize = 14
			end
		end
	end

	if self.curGiftIndex == 0 then
		return
	end

	self.giftbagBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.curGiftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.curGiftBagID))
	local awards = xyd.tables.giftTable:getAwards(self.curGiftID)
	local count = 1
	local cost = xyd.tables.miscTable:split2Cost("activity_cupid_gift_draw", "value", "#")

	for i = 1, #awards do
		if awards[i][1] ~= 8 and xyd.tables.itemTable:getType(awards[i][1]) ~= 12 and awards[i][1] ~= cost[1] then
			if not self.items[count] then
				local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.awardItem.gameObject)
				local item = ActivityCupidGiftItem.new(tmp, self)
				self.items[count] = item
			end

			self.items[count]:setInfo({
				id = count,
				award = awards[i]
			})

			count = count + 1
		end
	end

	for i = 1, 1 do
		if not self.items[count] then
			local tmp = NGUITools.AddChild(self.itemGroup.gameObject, self.awardItem.gameObject)
			local item = ActivityCupidGiftItem.new(tmp, self)
			self.items[count] = item
		end

		self.items[count]:setInfo({
			id = count,
			canChooseAwards = xyd.tables.activityCupidGiftAwardTable:getAward(self.curGiftBagID),
			nowChooseAwardIndex = self.activityData:getChooseAwardIndex()
		})

		count = count + 1
	end

	self.itemGroupLayout:Reposition()
end

function ActivityCupidGift:initEffect()
	if not self.angleEffect then
		self.angleEffect = xyd.Spine.new(self.angleEffectPos.gameObject)

		self.angleEffect:setInfo("fx_cupid_gift", function ()
			if not self.activityData:haveBuyAnyGift() then
				self.angleEffect:play("texiao_01", 0, 1, function ()
				end, true)
			else
				self.angleEffect:play("texiao_04", 0, 1, function ()
				end, true)
			end
		end)
	elseif not self.activityData:haveBuyAnyGift() then
		self.angleEffect:play("texiao_01", 0, 1, function ()
		end, true)
	else
		self.angleEffect:play("texiao_04", 0, 1, function ()
		end, true)
	end
end

function ActivityCupidGift:updateGambleGroup()
	self:initEffect()

	self.labelMax.text = __("ACTIVITY_CUPID_GIFT_TEXT12")

	if self.curGiftIndex == 0 then
		xyd.setUITextureByNameAsync(self.bg, "activity_cupid_gift_bg_banner_2")
		self:resizePosY(self.timeGroup, -238, -242)
		self:resizePosY(self.titleImg_.gameObject, -150, -158)
		self:resizePosY(self.btnSingle, -670, -748)
		self:resizePosY(self.btnMax, -670, -748)
		self:resizePosY(self.angleEffectPos.gameObject, -573, -616)
		self:resizePosY(self.dateGroup, -309, -314)
	else
		xyd.setUITextureByNameAsync(self.bg, "activity_cupid_gift_bg_banner_1")
		self:resizePosY(self.timeGroup, -178, -178)
		self:resizePosY(self.titleImg_.gameObject, -81, -99)
		self:resizePosY(self.btnSingle, -396, -504)
		self:resizePosY(self.btnMax, -396, -504)
		self:resizePosY(self.angleEffectPos.gameObject, -380, -460)
		self:resizePosY(self.dateGroup, -168, -195)
	end

	if self.activityData:haveBuyAnyGift() then
		self.btnMax:SetActive(true)
		self.btnSingle:SetActive(true)

		if self.curGiftIndex == 0 then
			self:resizePosY(self.TipsGroup, -752, -830)
		else
			self:resizePosY(self.TipsGroup, -449, -566)
		end
	else
		self.btnMax:SetActive(false)
		self.btnSingle:SetActive(false)

		if self.curGiftIndex == 0 then
			self:resizePosY(self.TipsGroup, -719, -806)
		else
			self:resizePosY(self.TipsGroup, -415, -520)
		end
	end
end

function ActivityCupidGift:updateRedPoint()
end

function ActivityCupidGift:dispose()
	ActivityCupidGift.super.dispose(self)
end

function ActivityCupidGiftItem:ctor(go, parent)
	ActivityCupidGiftItem.super.ctor(self, go, parent)

	self.parent = parent

	self:initUI()
end

function ActivityCupidGiftItem:initUI()
	self.btnPlus = self.go:NodeByName("btnPlus").gameObject
	self.btnExchange = self.go:NodeByName("btnExchange").gameObject

	UIEventListener.Get(self.btnPlus).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
			items = self.canChooseAwards,
			sureCallback = function (index)
				self.parent.activityData:selectSpecialAward(index)

				self.data.nowChooseAwardIndex = index

				self:setInfo(self.data)
			end,
			buttomTitleText = __("SELECT_AWARD_PLEASE"),
			titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
			sureBtnText = __("SURE"),
			cancelBtnText = __("CANCEL"),
			tipsText = __(""),
			selectedIndex = self.data.nowChooseAwardIndex
		})
	end

	UIEventListener.Get(self.btnExchange).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_common_select_award_window", {
			items = self.canChooseAwards,
			sureCallback = function (index)
				self.parent.activityData:selectSpecialAward(index)

				self.data.nowChooseAwardIndex = index

				self:setInfo(self.data)
			end,
			buttomTitleText = __("ACTIVITY_CLOCK_CHOOSE"),
			titleText = __("ACTIVITY_CLOCKGIFTBAG_TEXT02"),
			sureBtnText = __("SURE"),
			cancelBtnText = __("CANCEL"),
			tipsText = __(""),
			selectedIndex = self.data.nowChooseAwardIndex
		})
	end
end

function ActivityCupidGiftItem:setInfo(data)
	self.data = data
	self.id = self.data.id
	self.award = self.data.award
	self.canChooseAwards = self.data.canChooseAwards
	self.nowChooseAwardIndex = self.data.nowChooseAwardIndex or 0

	if self.canChooseAwards and self.nowChooseAwardIndex <= 0 then
		if self.icon then
			self.icon:SetActive(false)
		end

		self.btnExchange:SetActive(false)
	elseif self.canChooseAwards and self.nowChooseAwardIndex > 0 then
		if self.icon then
			self.icon:SetActive(true)
		end

		self.award = self.canChooseAwards[self.nowChooseAwardIndex]

		self.btnExchange:SetActive(true)
	end

	if self.award then
		local params = {
			scale = 0.6018518518518519,
			uiRoot = self.go.gameObject,
			itemID = self.award[1],
			num = self.award[2]
		}

		if not self.icon then
			self.icon = xyd.getItemIcon(params, xyd.ItemIconType.ADVANCE_ICON)
		end

		self.icon:setInfo(params)
	end
end

function ActivityCupidGiftItem:getGameObject()
	return self.go
end

return ActivityCupidGift
