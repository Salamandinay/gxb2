local ActivityChristmasSignUp = class("ActivityChristmasSignUp", import(".ActivityContent"))
local ActivityChristmasSignUpItem = class("ActivityChristmasSignUpItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")

function ActivityChristmasSignUp:ctor(parentGO, params)
	ActivityChristmasSignUp.super.ctor(self, parentGO, params)
end

function ActivityChristmasSignUp:getPrefabPath()
	return "Prefabs/Windows/activity/activity_christmas_sign_in"
end

function ActivityChristmasSignUp:initUI()
	self.fg3_imgs = {
		[12.0] = "activity_christmas_sign_in_item_fg3_2",
		[6.0] = "activity_christmas_sign_in_item_fg3_1",
		[18.0] = "activity_christmas_sign_in_item_fg3_3",
		[24.0] = "activity_christmas_sign_in_item_fg3_4"
	}
	self.activityData.firstTime = false

	self:getUIComponent()
	ActivityChristmasSignUp.super.initUI(self)
	self:initUIComponent()
	self:register()
	self:initData()
end

function ActivityChristmasSignUp:getUIComponent()
	self.topGroup = self.go:NodeByName("topGroup").gameObject
	self.titleGroup = self.topGroup:NodeByName("titleGroup").gameObject
	self.titleImg = self.titleGroup:ComponentByName("titleImg", typeof(UISprite))
	self.GameObject = self.topGroup:NodeByName("GameObject").gameObject
	self.btnHelp = self.topGroup:NodeByName("btnHelp").gameObject
	self.btnHasGot = self.topGroup:NodeByName("btnHasGot").gameObject
	self.timeGroup = self.go:ComponentByName("timeGroup", typeof(UISprite))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.dateGroup = self.go:NodeByName("dateGroup").gameObject
	self.content1 = self.dateGroup:NodeByName("content1").gameObject
	self.content_grid1 = self.dateGroup:ComponentByName("content1", typeof(UIGrid))
	self.content2 = self.dateGroup:NodeByName("content2").gameObject
	self.content_grid2 = self.dateGroup:ComponentByName("content2", typeof(UIGrid))
	self.content3 = self.dateGroup:NodeByName("content3").gameObject
	self.content_grid3 = self.dateGroup:ComponentByName("content3", typeof(UIGrid))
	self.content4 = self.dateGroup:NodeByName("content4").gameObject
	self.content_grid4 = self.dateGroup:ComponentByName("content4", typeof(UIGrid))
	self.bg = self.dateGroup:NodeByName("bg").gameObject
	self.item = self.dateGroup:NodeByName("item").gameObject
	self.iconPos = self.item:NodeByName("iconPos").gameObject
	self.bottomGroup = self.go:NodeByName("bottomGroup").gameObject
	self.signInGroup = self.bottomGroup:NodeByName("signInGroup").gameObject
	self.labelSignIn = self.signInGroup:ComponentByName("labelSignIn", typeof(UILabel))
	self.curDateItem = self.signInGroup:NodeByName("curDateItem").gameObject
	self.curDateItemIconPos = self.curDateItem:NodeByName("iconPos").gameObject
	self.curDateItemClickMask = self.curDateItem:NodeByName("clickMask").gameObject
	self.curDateItemBg = self.curDateItem:ComponentByName("bg", typeof(UISprite))
	self.fanpaiEffectPos = self.curDateItem:ComponentByName("fanpaiEffectPos", typeof(UITexture))
	self.curDateItemFgGroup = self.curDateItem:ComponentByName("fgGroup", typeof(UIWidget))
	self.curDateItemFg1 = self.curDateItemFgGroup:ComponentByName("fg1", typeof(UISprite))
	self.curDateItemFg2 = self.curDateItemFgGroup:ComponentByName("fg2", typeof(UISprite))
	self.curDateItemFg3 = self.curDateItemFgGroup:ComponentByName("fg3", typeof(UISprite))
	self.curDateItemLabelID = self.curDateItemFgGroup:ComponentByName("labelID", typeof(UILabel))
	self.giftbagGroup = self.bottomGroup:NodeByName("giftbagGroup").gameObject
	self.labelGiftbag = self.giftbagGroup:ComponentByName("labelGiftbag", typeof(UILabel))
	self.itemsGroup = self.giftbagGroup:NodeByName("itemsGroup").gameObject
	self.itemsGroup_layout = self.giftbagGroup:ComponentByName("itemsGroup", typeof(UILayout))
	self.giftbagBuyBtn = self.giftbagGroup:NodeByName("giftbagBuyBtn").gameObject
	self.giftbagBuyBtnLabel = self.giftbagBuyBtn:ComponentByName("giftbagBuyBtnLabel", typeof(UILabel))
	self.labelGiftbagTip = self.giftbagGroup:ComponentByName("labelGiftbagTip", typeof(UILabel))
	self.labelGiftbagLimit = self.giftbagGroup:ComponentByName("labelGiftbagLimit", typeof(UILabel))
	self.tipGroup = self.bottomGroup:NodeByName("tipGroup").gameObject
	self.des_layout = self.tipGroup:ComponentByName("descGroup", typeof(UILayout))
	self.labelNotice = self.tipGroup:ComponentByName("descGroup/labelNotice", typeof(UILabel))
	self.tipGroupIconPos = self.tipGroup:NodeByName("descGroup/iconPos").gameObject
	self.labelSignIn2 = self.tipGroup:ComponentByName("labelSignIn", typeof(UILabel))
end

function ActivityChristmasSignUp:initUIComponent()
	xyd.setUISpriteAsync(self.titleImg, nil, "activity_christmas_sign_in_logo_" .. xyd.Global.lang, nil, , true)

	self.labelSignIn.text = __("ACTIVITY_COUNTDOWN_TEXT04")
	self.labelSignIn2.text = __("ACTIVITY_COUNTDOWN_TEXT04")
	self.labelGiftbag.text = __("ACTIVITY_COUNTDOWN_TEXT03")

	self.des_layout:Reposition()
	self:setTimeShow()

	if xyd.Global.lang == "de_de" then
		self.labelSignIn.width = 300
		self.labelSignIn2.width = 300
	end

	if xyd.Global.lang == "fr_fr" then
		self.labelSignIn.width = 350
		self.labelSignIn2.width = 350
	end
end

function ActivityChristmasSignUp:register()
	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
	end)
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		self:onGetMsg(event)
	end)

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_COUNTDOWN_HELP"
		})
	end

	UIEventListener.Get(self.btnHasGot).onClick = function ()
		local data = {}

		for key, value in pairs(self.activityData.detail.item_records) do
			data[value.item_id] = value.item_num
		end

		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = data,
			winTitle = __("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT01")
		})
	end
end

function ActivityChristmasSignUp:resizeToParent()
	ActivityChristmasSignUp.super.resizeToParent(self)
end

function ActivityChristmasSignUp:setTimeShow()
	CountDown.new(self.timeLabel_, {
		duration = self.activityData:getUpdateTime() - xyd.getServerTime()
	})

	self.endLabel_.text = __("END_TEXT")
end

function ActivityChristmasSignUp:initNoticeLabel()
	if self.activityData:getCurDateID() < 24 and self.activityData:getAward(self.activityData:getCurDateID()) ~= nil then
		if xyd.tables.activityChristmasSignUpCountDownAwardsTable:getGiftbagID(self.activityData:getCurDateID() + 1) ~= nil and xyd.tables.activityChristmasSignUpCountDownAwardsTable:getGiftbagID(self.activityData:getCurDateID() + 1) ~= 0 then
			self.labelNotice.text = __("ACTIVITY_COUNTDOWN_TEXT01")
		else
			self.labelNotice.text = __("ACTIVITY_COUNTDOWN_TEXT02")
		end
	end
end

function ActivityChristmasSignUp:initData()
	self.datas = {}
	local ids = xyd.tables.activityChristmasSignUpCountDownAwardsTable:getIDs()
	self.curDateID = self.activityData:getCurDateID()

	for i = 1, #ids do
		local id = i
		local data = {
			id = id,
			type = xyd.tables.activityChristmasSignUpCountDownAwardsTable:getType(id),
			giftbagID = xyd.tables.activityChristmasSignUpCountDownAwardsTable:getGiftbagID(id),
			curDateID = self.curDateID,
			award = self.activityData:getAward(id),
			parent = self
		}

		table.insert(self.datas, data)
	end

	if self.dateItems == nil then
		self.dateItems = {}

		for i = 1, #self.datas do
			local signInItem = NGUITools.AddChild(self["content" .. math.floor((i - 1) / 6) + 1], self.item)
			local item = ActivityChristmasSignUpItem.new(signInItem)

			item:setInfo(self.datas[i])
			table.insert(self.dateItems, item)
		end
	else
		for i = 1, #self.datas do
			self.dateItems[i]:setInfo(self.datas[i])
		end
	end

	self.content_grid1:Reposition()
	self.content_grid2:Reposition()
	self.content_grid3:Reposition()
	self.content_grid4:Reposition()

	self.curDateItemLabelID.text = self.curDateID

	if self.datas[self.curDateID].type >= 1 then
		xyd.setUISpriteAsync(self.curDateItemFg1, nil, "activity_christmas_sign_in_item_fg1_" .. self.datas[self.curDateID].id % 2, nil, , true)
	end

	if self.datas[self.curDateID].type >= 2 then
		xyd.setUISpriteAsync(self.curDateItemFg2, nil, "activity_christmas_sign_in_item_fg2_" .. self.datas[self.curDateID].id % 2, nil, , true)
	end

	if self.datas[self.curDateID].type >= 3 then
		xyd.setUISpriteAsync(self.curDateItemFg3, nil, self.fg3_imgs[self.curDateID], nil, , true)
	end

	if self.datas[self.curDateID].award == nil then
		self.curDateItemClickMask:GetComponent(typeof(UnityEngine.BoxCollider)).size = Vector3(2000, 2000, 0)

		UIEventListener.Get(self.curDateItemClickMask).onClick = function ()
			if self.activityData:getEndTime() <= xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			if self.curDateID < self.activityData:getCurDateID() then
				xyd.alertTips(__("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT02"))
				self:initData()

				return
			end

			self.curDateItemClickMask:SetActive(false)
			self.dateItems[self.curDateID].clickMask:SetActive(false)

			local data = require("cjson").encode({
				day = tonumber(self.curDateID)
			})
			local msg = messages_pb:get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		end
	else
		self.curDateItemFgGroup:SetActive(false)
		self:initNoticeLabel()

		if self.datas[self.curDateID].giftbagID ~= nil and self.datas[self.curDateID].giftbagID ~= 0 then
			self.signInGroup:SetActive(false)
			self.giftbagGroup:SetActive(true)
		else
			self.curIcon = xyd.getItemIcon({
				scale = 0.7592592592592593,
				uiRoot = self.curDateItemIconPos,
				itemID = self.datas[self.curDateID].award.item_id,
				num = self.datas[self.curDateID].award.item_num
			})

			self.curIcon:setChoose(true)

			self.curTipIcon = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.tipGroupIconPos,
				itemID = self.datas[self.curDateID].award.item_id,
				num = self.datas[self.curDateID].award.item_num
			})

			self.curTipIcon:setChoose(true)
			self.signInGroup:SetActive(false)
			self.tipGroup:SetActive(true)
		end
	end

	if self.datas[self.curDateID].giftbagID ~= nil and self.datas[self.curDateID].giftbagID ~= 0 then
		self:initGiftbag()
	end

	self.signInGroup:ComponentByName("", typeof(UIWidget)).alpha = 1
	self.tipGroup:ComponentByName("", typeof(UIWidget)).alpha = 1
end

function ActivityChristmasSignUp:initGiftbag()
	self.giftBagID = self.datas[self.curDateID].giftbagID
	self.labelGiftbagTip.text = __("MONTH_CARD_VIP", xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	self.giftbagBuyBtnLabel.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))
	local limitTime = self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].limit_times
	local buyTime = self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].buy_times
	self.labelGiftbagLimit.text = __("BUY_GIFTBAG_LIMIT", limitTime - buyTime)
	self.giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(self.giftID)
	self.giftBagIcons = {}

	for i = 1, #awards do
		local award = awards[i]

		if award[1] ~= 8 and xyd.tables.itemTable:getType(award[1]) ~= 12 then
			local icon = xyd.getItemIcon({
				show_has_num = true,
				hideText = false,
				scale = 0.7037037037037037,
				uiRoot = self.itemsGroup,
				itemID = award[1],
				num = award[2]
			})

			table.insert(self.giftBagIcons, icon)
		end
	end

	self.itemsGroup_layout:Reposition()

	if self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].limit_times <= self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].buy_times then
		xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagBuyBtn, false)

		for i = 1, #self.giftBagIcons do
			self.giftBagIcons[i]:setChoose(true)
		end
	end

	UIEventListener.Get(self.giftbagBuyBtn).onClick = handler(self, function ()
		if self.activityData:getEndTime() <= xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_END_YET"))

			return
		end

		if self.curDateID < self.activityData:getCurDateID() then
			xyd.alertTips(__("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT02"))
			self:initData()

			return
		end

		xyd.SdkManager.get():showPayment(self.giftBagID)
	end)

	self:registerEvent(xyd.event.RECHARGE, function (event)
		self:onGetGiftbagMsg(event)
	end)
end

function ActivityChristmasSignUp:playOpenAnimation(callback)
	self.curDateItemClickMask:SetActive(false)
	self.curDateItemBg:SetActive(true)

	self.fanpaiSequence = self:getSequence(callback)
	local time = 0.3

	self.curDateItemFgGroup:SetLocalScale(1, 1, 0)
	self.curDateItemIconPos:SetLocalScale(0, 1, 0)
	self.curDateItemBg:SetLocalScale(0, 1, 0)

	self.fanpaiEffect = xyd.Spine.new(self.fanpaiEffectPos.gameObject)

	self.fanpaiEffect:setInfo("fx_countdown_card", function ()
		self.fanpaiEffect:play("texiao01", 1, 1, function ()
			self.fanpaiEffectPos:SetActive(false)
		end, true)
	end)
	self.dateItems[self.curDateID]:playOpenAnimation()
	self.fanpaiSequence:Append(self.curDateItemFgGroup.transform:DOScaleX(0, time)):Insert(time, self.curDateItemBg.gameObject.transform:DOScaleX(1, time)):Insert(time, self.curDateItemIconPos.transform:DOScaleX(1, time))
end

function ActivityChristmasSignUp:onGetMsg(event)
	local detail = cjson.decode(event.data.detail)

	local function callback()
		local awards = {
			detail.item_records[#detail.item_records]
		}

		xyd.models.itemFloatModel:pushNewItems(awards)
		self.curIcon:setChoose(true)
		self.curTipIcon:setChoose(true)
		self.dateItems[self.curDateID]:setChoose(true)

		if self.datas[self.curDateID].giftbagID ~= nil and self.datas[self.curDateID].giftbagID ~= 0 then
			self:changeToGiftbag()
		else
			self:changeToTip()
		end
	end

	local award = detail.item_records[#detail.item_records]
	self.curIcon = xyd.getItemIcon({
		scale = 0.9259259259259259,
		uiRoot = self.curDateItemIconPos,
		itemID = award.item_id,
		num = award.item_num
	})
	self.curTipIcon = xyd.getItemIcon({
		scale = 0.7037037037037037,
		uiRoot = self.tipGroupIconPos,
		itemID = award.item_id,
		num = award.item_num
	})

	self.dateItems[self.curDateID]:genarateIcon(award)
	self:playOpenAnimation(callback)
	self:initNoticeLabel()
end

function ActivityChristmasSignUp:onGetGiftbagMsg(event)
	local limitTime = self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].limit_times
	local buyTime = self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].buy_times
	self.labelGiftbagLimit.text = __("BUY_GIFTBAG_LIMIT", limitTime - buyTime)

	if self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].limit_times <= self.activityData.detail.charges[self.activityData:getGiftBagIndex(self.giftBagID)].buy_times then
		xyd.applyGrey(self.giftbagBuyBtn:GetComponent(typeof(UISprite)))
		self.giftbagBuyBtnLabel:ApplyGrey()
		xyd.setTouchEnable(self.giftbagBuyBtn, false)

		for i = 1, #self.giftBagIcons do
			self.giftBagIcons[i]:setChoose(true)
		end
	end
end

function ActivityChristmasSignUp:changeToGiftbag()
	self.giftbagGroup:SetActive(true)

	self.giftbagGroup:ComponentByName("", typeof(UIWidget)).alpha = 0.01
	self.changeSequence = self:getSequence()

	self.changeSequence:Join(xyd.getTweenAlpha(self.signInGroup:ComponentByName("", typeof(UIWidget)), 0.02, 1.5)):Append(xyd.getTweenAlpha(self.giftbagGroup:ComponentByName("", typeof(UIWidget)), 1, 1.5)):AppendCallback(function ()
		self.signInGroup:SetActive(false)
	end)
end

function ActivityChristmasSignUp:changeToTip()
	self.tipGroup:SetActive(true)

	self.tipGroup:ComponentByName("", typeof(UIWidget)).alpha = 0.01
	self.changeSequence2 = self:getSequence()

	self.changeSequence2:Join(xyd.getTweenAlpha(self.signInGroup:ComponentByName("", typeof(UIWidget)), 0.02, 1.5)):Append(xyd.getTweenAlpha(self.tipGroup:ComponentByName("", typeof(UIWidget)), 1, 1.5)):AppendCallback(function ()
		self.signInGroup:SetActive(false)
	end)
end

function ActivityChristmasSignUpItem:ctor(go)
	ActivityChristmasSignUpItem.super:ctor(go)

	self.go = go

	self:getUIComponent()

	self.fg3_imgs = {
		[12.0] = "activity_christmas_sign_in_item_fg3_2",
		[6.0] = "activity_christmas_sign_in_item_fg3_1",
		[18.0] = "activity_christmas_sign_in_item_fg3_3",
		[24.0] = "activity_christmas_sign_in_item_fg3_4"
	}
end

function ActivityChristmasSignUpItem:getUIComponent()
	self.iconPos = self.go:NodeByName("iconPos").gameObject
	self.clickMask = self.go:NodeByName("clickMask").gameObject
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.fanpaiEffectPos = self.go:ComponentByName("fanpaiEffectPos", typeof(UITexture))
	self.fgGroup = self.go:ComponentByName("fgGroup", typeof(UIWidget))
	self.fg1 = self.fgGroup:ComponentByName("fg1", typeof(UISprite))
	self.fg2 = self.fgGroup:ComponentByName("fg2", typeof(UISprite))
	self.fg3 = self.fgGroup:ComponentByName("fg3", typeof(UISprite))
	self.fgGiftbag = self.fgGroup:ComponentByName("fgGiftbag", typeof(UISprite))
	self.labelID = self.fgGroup:ComponentByName("labelID", typeof(UILabel))
	self.curDayEffectPos = self.fgGroup:ComponentByName("curDayEffectPos", typeof(UITexture))
end

function ActivityChristmasSignUpItem:setInfo(params)
	if not params then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	self.parent = params.parent
	self.id = params.id
	self.type = params.type
	self.giftbagID = params.giftbagID
	self.curDateID = params.curDateID
	self.award = params.award
	self.labelID.text = self.id

	if self.award ~= nil then
		self.awarded = true
	else
		self.awarded = false
	end

	if self.awarded == true then
		self.fgGroup:SetActive(false)
		self:genarateIcon(self.award)
	elseif self.id == self.curDateID then
		self.curDayEffectPos:SetActive(true)

		self.clickEffect = xyd.Spine.new(self.curDayEffectPos.gameObject)

		self.clickEffect:setInfo("bp_available", function ()
			self.clickEffect:SetLocalScale(1, 1, 1)
			self.clickEffect:play("texiao01", 0, 1, function ()
			end, true)
		end)
	end

	if self.curDateID == self.id and self.award == nil then
		self.clickMask:SetActive(true)
	else
		self.clickMask:SetActive(false)
	end

	if self.type >= 1 then
		xyd.setUISpriteAsync(self.fg1, nil, "activity_christmas_sign_in_item_fg1_" .. self.id % 2, nil, , true)
	end

	if self.type >= 2 then
		xyd.setUISpriteAsync(self.fg2, nil, "activity_christmas_sign_in_item_fg2_" .. self.id % 2, nil, , true)
	end

	if self.type >= 3 then
		xyd.setUISpriteAsync(self.fg3, nil, self.fg3_imgs[self.id], nil, , true)
	end

	if self.giftbagID ~= nil and self.giftbagID ~= 0 then
		self.fgGiftbag:SetActive(true)
	end

	if self.id == self.curDateID then
		UIEventListener.Get(self.clickMask).onClick = function ()
			if self.parent.activityData:getEndTime() <= xyd.getServerTime() then
				xyd.alertTips(__("ACTIVITY_END_YET"))

				return
			end

			if self.curDateID < self.parent.activityData:getCurDateID() then
				xyd.alertTips(__("ACTIVITY_CHRISTMAS_SIGN_UP_TEXT02"))
				self:initData()

				return
			end

			self.parent.curDateItemClickMask:SetActive(false)
			self.clickMask:SetActive(false)

			local data = require("cjson").encode({
				day = tonumber(self.id)
			})
			local msg = messages_pb:get_activity_award_req()
			msg.activity_id = xyd.ActivityID.ACTIVITY_CHRISTMAS_SIGN_UP
			msg.params = data

			xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
		end
	end

	if self.curDateID < self.id then
		self.clickMask:SetActive(true)

		UIEventListener.Get(self.clickMask).onClick = function ()
			if self.giftbagID ~= nil and self.giftbagID ~= 0 then
				xyd.alertTips(__("ACTIVITY_COUNTDOWN_TIPS"))
			end

			self.clickMask:SetActive(false)

			if self.clickSequence then
				self.clickSequence:Kill(false)

				self.clickSequence = nil
				self.go.transform.localPosition.x = 0
			end

			local basePosition = self.go.transform.localPosition
			self.clickSequence = self:getSequence()

			self.clickSequence:Insert(0, self.go.transform:DOLocalMove(Vector3(basePosition.x - 5, basePosition.y, 0), 0.05, false))
			self.clickSequence:Insert(0.05, self.go.transform:DOLocalMove(Vector3(basePosition.x + 5, basePosition.y, 0), 0.1, false))
			self.clickSequence:Insert(0.15, self.go.transform:DOLocalMove(Vector3(basePosition.x - 5, basePosition.y, 0), 0.1, false))
			self.clickSequence:Insert(0.25, self.go.transform:DOLocalMove(Vector3(basePosition.x, basePosition.y, 0), 0.05, false))
			self.clickSequence:AppendCallback(function ()
				self.clickMask:SetActive(true)
			end)
		end
	end
end

function ActivityChristmasSignUpItem:genarateIcon(item)
	self.curDayEffectPos:SetActive(false)

	if not self.icon then
		self.icon = xyd.getItemIcon({
			show_has_num = true,
			hideText = true,
			scale = 0.9166666666666666,
			uiRoot = self.iconPos,
			itemID = item.item_id,
			num = item.item_num
		})

		self.icon:setChoose(true)
	else
		self.icon:setInfo({
			show_has_num = true,
			hideText = true,
			scale = 0.9166666666666666,
			itemID = item.item_id,
			num = item.item_num
		})
		self.icon:setChoose(false)
	end
end

function ActivityChristmasSignUpItem:setChoose(flag)
	if self.icon then
		self.icon:setChoose(flag)
	end
end

function ActivityChristmasSignUpItem:playOpenAnimation()
	self.clickMask:SetActive(false)
	self.bg:SetActive(true)

	self.fanpaiSequence = self:getSequence()
	local time = 0.3

	self.fgGroup:SetLocalScale(1, 1, 0)
	self.iconPos:SetLocalScale(0, 1, 0)
	self.bg:SetLocalScale(0, 1, 0)

	self.fanpaiEffect = xyd.Spine.new(self.fanpaiEffectPos.gameObject)

	self.fanpaiEffect:setInfo("fx_countdown_card", function ()
		self.fanpaiEffect:play("texiao01", 1, 1, function ()
			self.fanpaiEffectPos:SetActive(false)
		end, true)
	end)
	self.fanpaiSequence:Append(self.fgGroup.transform:DOScaleX(0, time)):Insert(time, self.bg.gameObject.transform:DOScaleX(1, time)):Insert(time, self.iconPos.transform:DOScaleX(1, time))
end

return ActivityChristmasSignUp
