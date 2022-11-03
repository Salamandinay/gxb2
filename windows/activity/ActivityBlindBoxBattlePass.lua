local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local ActivityBlindBoxBattlePass = class("ActivityBlindBoxBattlePass", ActivityContent)
local CountDown = import("app.components.CountDown")
local FundItemIcon = class("FundItemIcon")
local FundItem = class("FundItem", import("app.common.ui.FixedWrapContentItem"))

function FundItemIcon:ctor(go, parent)
	self.go = go
	self.parent = parent

	self:getUIComponent()
end

function FundItemIcon:getUIComponent()
	self.icon = self.go:NodeByName("icon").gameObject
	self.imgLock = self.go:NodeByName("imgLock").gameObject
	self.imgGet = self.go:NodeByName("imgGet").gameObject
	self.imgMask = self.go:NodeByName("imgMask").gameObject
	self.touchField = self.go:NodeByName("touchField").gameObject
	self.imgGetSprite = self.go:ComponentByName("imgGet", typeof(UISprite))
	self.imgLockSprite = self.go:ComponentByName("imgLock", typeof(UISprite))
	self.imgMaskSprite = self.go:ComponentByName("imgMask", typeof(UISprite))
end

function FundItemIcon:setInfo(params)
	if not params then
		dump("error")

		return
	end

	if params.award[1] == xyd.ItemID.VIP_EXP or params.award[1] == xyd.ItemID.EXP then
		return
	end

	NGUITools.DestroyChildren(self.icon.transform)

	self.itemIcon = xyd.getItemIcon({
		showGetWays = false,
		notShowGetWayBtn = true,
		show_has_num = true,
		scale = 0.6018518518518519,
		itemID = params.award[1],
		num = params.award[2],
		uiRoot = self.icon,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = params.scroller
	}, xyd.ItemIconType.ADVANCE_ICON)

	if params.baseFundItemState then
		self.imgLock:SetActive(false)
		xyd.setUISpriteAsync(self.imgGetSprite, "activity_blind_box_battlepass_web", "icon_dg_fl", nil, , true)
		xyd.setUISpriteAsync(self.imgMaskSprite, "activity_blind_box_battlepass_web", "mb_fl", nil, , true)

		if params.baseFundItemState == 1 then
			self.imgGet:SetActive(false)
			self.imgMask:SetActive(false)
			self:removeEffect()
		elseif params.baseFundItemState == 2 then
			self.imgGet:SetActive(false)
			self.imgMask:SetActive(false)
			self:addEffect()
		elseif params.baseFundItemState == 3 then
			self.imgGet:SetActive(true)
			self.imgMask:SetActive(true)
			self:removeEffect()
		end
	end

	if params.advFundItemState then
		xyd.setUISpriteAsync(self.imgGetSprite, "activity_blind_box_battlepass_web", "icon_dg_cz", nil, , true)
		xyd.setUISpriteAsync(self.imgMaskSprite, "activity_blind_box_battlepass_web", "mb_cz", nil, , true)
		xyd.setUISpriteAsync(self.imgLockSprite, "activity_blind_box_battlepass_web", "icon_s_cz", nil, , true)

		if params.advFundItemState == 1 or params.advFundItemState == 5 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(true)
			self.imgMask:SetActive(true)
			self:removeEffect()
		elseif params.advFundItemState == 2 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(false)
			self:addEffect()
		elseif params.advFundItemState == 3 then
			self.imgGet:SetActive(true)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(true)
			self:removeEffect()
		elseif params.advFundItemState == 4 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(false)
			self:removeEffect()
		end
	end

	if params.superFundItemState then
		xyd.setUISpriteAsync(self.imgGetSprite, "activity_blind_box_battlepass_web", "icon_dg_hh", nil, , true)
		xyd.setUISpriteAsync(self.imgMaskSprite, "activity_blind_box_battlepass_web", "mb_hh", nil, , true)
		xyd.setUISpriteAsync(self.imgLockSprite, "activity_blind_box_battlepass_web", "icon_s_hh", nil, , true)

		if params.superFundItemState == 1 or params.superFundItemState == 5 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(true)
			self.imgMask:SetActive(true)
			self:removeEffect()
		elseif params.superFundItemState == 2 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(false)
			self:addEffect()
		elseif params.superFundItemState == 3 then
			self.imgGet:SetActive(true)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(true)
			self:removeEffect()
		elseif params.superFundItemState == 4 then
			self.imgGet:SetActive(false)
			self.imgLock:SetActive(false)
			self.imgMask:SetActive(false)
			self:removeEffect()
		end
	end
end

function FundItemIcon:addEffect()
	local effect = "bp_available"

	self.itemIcon:setEffect(true, effect, {
		effectPos = Vector3(0, -2, 0),
		effectScale = Vector3(1.1, 1.1, 1.1),
		target = self.target_
	})
	self:setClick(true)
end

function FundItemIcon:removeEffect()
	self:setClick(false)
end

function FundItemIcon:setClick(flag)
	if flag == true then
		self.touchField:SetActive(true)

		UIEventListener.Get(self.touchField).onClick = function ()
			self.parent:getAward()
		end
	else
		self.touchField:SetActive(false)

		UIEventListener.Get(self.touchField).onClick = nil
	end
end

function ActivityBlindBoxBattlePass:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.giftBagID1 = self.activityData.detail.charges[1].table_id
	self.giftBagID2 = self.activityData.detail.charges[2].table_id
	self.dayNow = self.activityData:getPassedDayRound()

	self:getUIComponent()
	self:layout()
	self:register()
end

function ActivityBlindBoxBattlePass:getPrefabPath()
	return "Prefabs/Windows/activity/activity_blind_box_battlepass"
end

function ActivityBlindBoxBattlePass:getUIComponent()
	local go = self.go
	self.activityGroup = go:NodeByName("activityGroup").gameObject
	self.imgBg = self.activityGroup:ComponentByName("bg", typeof(UISprite))
	self.giftBagGroup1 = self.activityGroup:NodeByName("giftBagGroup1").gameObject
	self.giftBagGroup1Bg = self.giftBagGroup1:ComponentByName("bg", typeof(UISprite))
	self.giftBagGroup1Title = self.giftBagGroup1:ComponentByName("title", typeof(UISprite))
	self.giftBagGroup1AwardsGroup1 = self.giftBagGroup1:NodeByName("awardGroup1").gameObject
	self.giftBagGroup1AwardGroup1Title = self.giftBagGroup1AwardsGroup1:ComponentByName("title", typeof(UILabel))
	self.giftBagGroup1AwardGroup1Awards = self.giftBagGroup1AwardsGroup1:NodeByName("awards").gameObject
	self.giftBagGroup1AwardsGroup2 = self.giftBagGroup1:NodeByName("awardGroup2").gameObject
	self.giftBagGroup1AwardGroup2Title = self.giftBagGroup1AwardsGroup2:ComponentByName("title", typeof(UILabel))
	self.giftBagGroup1AwardGroup2Awards = self.giftBagGroup1AwardsGroup2:NodeByName("awards").gameObject
	self.giftBagGroup1VipLabel = self.giftBagGroup1:ComponentByName("vipLabel", typeof(UILabel))
	self.giftBag1BuyBtn = self.giftBagGroup1:NodeByName("buyButton1").gameObject
	self.giftBag1BuyLabel = self.giftBag1BuyBtn:ComponentByName("button_label", typeof(UILabel))
	self.giftBag1DiscountLabel1 = self.giftBag1BuyBtn:ComponentByName("discount/discountLabel1", typeof(UILabel))
	self.giftBag1DiscountLabel2 = self.giftBag1BuyBtn:ComponentByName("discount/discountLabel2", typeof(UILabel))
	self.giftBagGroup2 = self.activityGroup:NodeByName("giftBagGroup2").gameObject
	self.giftBagGroup2Bg = self.giftBagGroup2:ComponentByName("bg", typeof(UISprite))
	self.giftBagGroup2Title = self.giftBagGroup2:ComponentByName("title", typeof(UISprite))
	self.giftBagGroup2AwardsGroup1 = self.giftBagGroup2:NodeByName("awardGroup1").gameObject
	self.giftBagGroup2AwardGroup1Title = self.giftBagGroup2AwardsGroup1:ComponentByName("title", typeof(UILabel))
	self.giftBagGroup2AwardGroup1Awards = self.giftBagGroup2AwardsGroup1:NodeByName("awards").gameObject
	self.giftBagGroup2AwardsGroup1 = self.giftBagGroup2:NodeByName("awardGroup2").gameObject
	self.giftBagGroup2AwardGroup2Title = self.giftBagGroup2AwardsGroup1:ComponentByName("title", typeof(UILabel))
	self.giftBagGroup2AwardGroup2Awards = self.giftBagGroup2AwardsGroup1:NodeByName("awards").gameObject
	self.giftBagGroup2VipLabel = self.giftBagGroup2:ComponentByName("vipLabel", typeof(UILabel))
	self.giftBag2BuyBtn = self.giftBagGroup2:NodeByName("buyButton1").gameObject
	self.giftBag2BuyLabel = self.giftBag2BuyBtn:ComponentByName("button_label", typeof(UILabel))
	self.giftBag2DiscountLabel1 = self.giftBag2BuyBtn:ComponentByName("discount/discountLabel1", typeof(UILabel))
	self.giftBag2DiscountLabel2 = self.giftBag2BuyBtn:ComponentByName("discount/discountLabel2", typeof(UILabel))
	self.colName = self.go:NodeByName("colName").gameObject
	self.dayLabel = self.colName:ComponentByName("day", typeof(UILabel))
	self.baseAwardLabel = self.colName:ComponentByName("baseAward", typeof(UILabel))
	self.advanceAwardLabel = self.colName:ComponentByName("advanceAward", typeof(UILabel))
	self.superAwardLabel = self.colName:ComponentByName("superAward", typeof(UILabel))
	self.colNameLock1 = self.colName:NodeByName("lock1").gameObject
	self.colNameLock2 = self.colName:NodeByName("lock2").gameObject

	self.colNameLock1:SetActive(false)
	self.colNameLock2:SetActive(false)

	self.fundGroup = self.activityGroup:NodeByName("fundGroup").gameObject
	self.scrollerView = self.fundGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.wrapContent = self.scrollerView:ComponentByName("groupItem", typeof(UIWrapContent))
	self.scrollerViewPanel = self.fundGroup:ComponentByName("scroller", typeof(UIPanel))
	self.scrollerViewPanel.depth = self.scrollerViewPanel.depth + 1
	self.slidBar = self.activityGroup:NodeByName("slidBar/bar").gameObject
	self.fundItem = self.go:NodeByName("fundItem").gameObject
	self.fundItemIcon = self.go:NodeByName("fundItemIcon").gameObject
end

function ActivityBlindBoxBattlePass:layout()
	self:resize()
	self:setText()
	self:setTexture()
	self:setGiftBag1Icon()
	self:setGiftBag2Icon()
	self:setFundItems()
end

function ActivityBlindBoxBattlePass:resize()
	if xyd.Global.lang == "de_de" then
		self.giftBagGroup1AwardGroup2Title.width = 140
		self.giftBagGroup2AwardGroup2Title.width = 140
	end

	if xyd.Global.lang == "en_en" then
		self.giftBagGroup1AwardGroup2Title.width = 160
		self.giftBagGroup2AwardGroup2Title.width = 160
	end

	if xyd.Global.lang == "ja_jp" then
		self.dayLabel.width = 100
		self.giftBagGroup1AwardGroup2Title.width = 140
		self.giftBagGroup2AwardGroup2Title.width = 140
	end

	if xyd.Global.lang == "fr_fr" then
		self.giftBagGroup1AwardGroup1Title.fontSize = 15
		self.giftBagGroup2AwardGroup1Title.fontSize = 15
		self.giftBagGroup1AwardGroup2Title.fontSize = 15
		self.giftBagGroup2AwardGroup2Title.fontSize = 15

		self.giftBagGroup1AwardGroup1Title.gameObject:Y(37)
		self.giftBagGroup1AwardGroup2Title.gameObject:Y(37)
		self.giftBagGroup2AwardGroup1Title.gameObject:Y(37)
		self.giftBagGroup2AwardGroup2Title.gameObject:Y(37)
	end
end

function ActivityBlindBoxBattlePass:setText()
	self.giftBagGroup1AwardGroup1Title.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT01")
	self.giftBagGroup2AwardGroup1Title.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT01")
	self.giftBagGroup1AwardGroup2Title.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT02")
	self.giftBagGroup2AwardGroup2Title.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT02")
	self.giftBag1DiscountLabel1.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT09")
	self.giftBag1DiscountLabel2.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT07")
	self.giftBag2DiscountLabel1.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT09")
	self.giftBag2DiscountLabel2.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT08")
	self.dayLabel.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT03")
	self.baseAwardLabel.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT04")
	self.advanceAwardLabel.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT05")
	self.superAwardLabel.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT06")
	self.giftBag1BuyLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID1) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID1)
	self.giftBagGroup1VipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID1) .. "\n VIP EXP"
	self.giftBag2BuyLabel.text = xyd.tables.giftBagTextTable:getCurrency(self.giftBagID2) .. " " .. xyd.tables.giftBagTextTable:getCharge(self.giftBagID2)
	self.giftBagGroup2VipLabel.text = "+" .. xyd.tables.giftBagTable:getVipExp(self.giftBagID2) .. "\n VIP EXP"

	if self.activityData:checkGiftBag1Buy() then
		xyd.setEnabled(self.giftBag1BuyBtn, false)
		self.colNameLock1:SetActive(false)
	end

	if self.activityData:checkGiftBag2Buy() then
		xyd.setEnabled(self.giftBag2BuyBtn, false)
		self.colNameLock2:SetActive(false)
	end
end

function ActivityBlindBoxBattlePass:setTexture()
	xyd.setUISpriteAsync(self.giftBagGroup1Title, nil, "activity_blind_box_battlepass_logo_czlb_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.giftBagGroup2Title, nil, "activity_blind_box_battlepass_logo_hhlb_" .. xyd.Global.lang, nil, , true)
end

function ActivityBlindBoxBattlePass:setFundItems()
	local ids = xyd.tables.activityBlindBoxBattlePassTable:getIDs()
	local fundItemList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			dayNeed = id,
			baseAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards1(id),
			advanceAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards2(id),
			superAwards = xyd.tables.activityBlindBoxBattlePassTable:getAwards3(id),
			giftBag1Buy = self.activityData:checkGiftBag1Buy(),
			giftBag2Buy = self.activityData:checkGiftBag2Buy(),
			isBaseAwarded = self.activityData:isBaseAwardedById(id),
			isAdvanceAwarded = self.activityData:isAdvAwardedById(id),
			isSuperAwarded = self.activityData:isSuperAwardedById(id)
		}

		table.insert(fundItemList, params)
	end

	self.fundItemList = fundItemList
	self.wrapContentClass = require("app.common.ui.FixedWrapContent").new(self.scrollerView, self.wrapContent, self.fundItem, FundItem, self)
	local fundItemList1 = {}
	local fundItemList2 = {}

	for i, info in ipairs(self.fundItemList) do
		if info.isBaseAwarded == true and info.isAdvanceAwarded == true and info.isSuperAwarded == true then
			table.insert(fundItemList2, info)
		else
			table.insert(fundItemList1, info)
		end
	end

	for i, info in ipairs(fundItemList2) do
		table.insert(fundItemList1, info)
	end

	self.wrapContentClass:setInfos(fundItemList1, {})
end

function ActivityBlindBoxBattlePass:setGiftBag1Icon()
	local awards1 = xyd.tables.activityBlindBoxBattlePassTable:getGiftBag1Award1()

	for i, award in pairs(awards1) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				itemID = award[1],
				num = award[2],
				uiRoot = self.giftBagGroup1AwardGroup1Awards,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollerView
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end

	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID1)
	local awards2 = xyd.tables.giftTable:getAwards(giftID)

	for i, award in pairs(awards2) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				itemID = award[1],
				num = award[2],
				uiRoot = self.giftBagGroup1AwardGroup2Awards,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollerView
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end
end

function ActivityBlindBoxBattlePass:setGiftBag2Icon()
	local awards1 = xyd.tables.activityBlindBoxBattlePassTable:getGiftBag2Award1()

	for i, award in pairs(awards1) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				itemID = award[1],
				num = award[2],
				uiRoot = self.giftBagGroup2AwardGroup1Awards,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollerView
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end

	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID2)
	local awards2 = xyd.tables.giftTable:getAwards(giftID)

	for i, award in pairs(awards2) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			xyd.getItemIcon({
				showGetWays = false,
				notShowGetWayBtn = true,
				show_has_num = true,
				scale = 0.6018518518518519,
				itemID = award[1],
				num = award[2],
				uiRoot = self.giftBagGroup2AwardGroup2Awards,
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				dragScrollView = self.scrollerView
			}, xyd.ItemIconType.ADVANCE_ICON)
		end
	end
end

function ActivityBlindBoxBattlePass:updateDayNow()
	self.dayNow = self.activityData:getPassedDayRound()
end

function ActivityBlindBoxBattlePass:updateList()
	for _, info in ipairs(self.fundItemList) do
		local id = info.id
		info.giftBag1Buy = self.activityData:checkGiftBag1Buy()
		info.giftBag2Buy = self.activityData:checkGiftBag2Buy()
		info.isBaseAwarded = self.activityData:isBaseAwardedById(id)
		info.isAdvanceAwarded = self.activityData:isAdvAwardedById(id)
		info.isSuperAwarded = self.activityData:isSuperAwardedById(id)
	end

	local fundItemList1 = {}
	local fundItemList2 = {}

	for i, info in ipairs(self.fundItemList) do
		if info.isBaseAwarded == true and info.isAdvanceAwarded == true and info.isSuperAwarded == true then
			table.insert(fundItemList2, info)
		else
			table.insert(fundItemList1, info)
		end
	end

	for i, info in ipairs(fundItemList2) do
		table.insert(fundItemList1, info)
	end

	self.wrapContentClass:setInfos(fundItemList1)
end

function ActivityBlindBoxBattlePass:register()
	UIEventListener.Get(self.giftBag1BuyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID1)
	end

	UIEventListener.Get(self.giftBag2BuyBtn).onClick = function ()
		xyd.SdkManager.get():showPayment(self.giftBagID2)
	end

	self.scrollerView.onDragMoving = handler(self, self.onDarg)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityBlindBoxBattlePass:onDarg()
	local start = -554
	local endPos = -756 + -178 * self.scale_num_contrary
	local len1 = start - endPos
	local start2 = -163
	local endPos2 = 568 + -178 * self.scale_num_contrary
	local len2 = endPos2 - start2
	local rate = len2 / len1
	local posNow = self.scrollerView.transform.localPosition.y
	local move2 = posNow - start2
	local move1 = move2 / rate
	local position = start - move1

	if start <= position then
		position = start
	end

	if position <= endPos then
		position = endPos
	end

	self.slidBar:Y(position)
end

function ActivityBlindBoxBattlePass:onAward(event)
	if event.data.activity_id == xyd.ActivityID.ACTIVITY_BLIND_BOX_BATTLE_PASS then
		local info = cjson.decode(event.data.detail)

		self:updateList()

		local items = info.items

		xyd.itemFloat(items)
	end
end

function ActivityBlindBoxBattlePass:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID == self.giftBagID1 then
		xyd.setEnabled(self.giftBag1BuyBtn, false)
		self.colNameLock1:SetActive(false)
	elseif giftBagID == self.giftBagID2 then
		xyd.setEnabled(self.giftBag2BuyBtn, false)
		self.colNameLock2:SetActive(false)
	else
		return
	end

	self:updateList()
end

function ActivityBlindBoxBattlePass:getAward()
	local awardList = {}

	for _, info in ipairs(self.fundItemList) do
		local id = info.id

		if info.dayNeed <= self.dayNow and (info.isBaseAwarded == false or info.giftBag1Buy == true and info.isAdvanceAwarded == false or info.giftBag2Buy == true and info.isSuperAwarded == false) then
			table.insert(awardList, id)
		end
	end

	self.activityData:reqAward(awardList)
end

function FundItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.baseFundItemState = 0
	self.advFundItemState = 0
	self.superFundItemState = 0

	self:getUIComponent()
end

function FundItem:getUIComponent()
	self.labelDay = self.go:ComponentByName("box1/labelDay", typeof(UILabel))
	self.labelDayBg = self.go:ComponentByName("box1/bg", typeof(UISprite))
	self.baseAwardsGo = self.go:NodeByName("box2/award").gameObject
	self.advanceAwardsGo = self.go:NodeByName("box3/award").gameObject
	self.superAwardsGo = self.go:NodeByName("box4/award").gameObject
end

function FundItem:update(_, info)
	if not info then
		return
	end

	self.info = info

	self.parent:updateDayNow()

	if self.info.dayNeed <= self.parent.dayNow and self.info.isBaseAwarded == false then
		self.baseFundItemState = 2
	elseif self.info.isBaseAwarded == true then
		self.baseFundItemState = 3
	elseif self.parent.dayNow < self.info.dayNeed then
		self.baseFundItemState = 1
	end

	if self.info.giftBag1Buy == false and self.parent.dayNow < self.info.dayNeed then
		self.advFundItemState = 1
	elseif self.info.giftBag1Buy == true and self.info.dayNeed <= self.parent.dayNow and self.info.isAdvanceAwarded == false then
		self.advFundItemState = 2
	elseif self.info.isAdvanceAwarded == true then
		self.advFundItemState = 3
	elseif self.info.giftBag1Buy == true and self.parent.dayNow < self.info.dayNeed then
		self.advFundItemState = 4
	elseif self.info.giftBag1Buy == false and self.info.dayNeed <= self.parent.dayNow then
		self.advFundItemState = 5
	end

	if self.info.giftBag2Buy == false and self.parent.dayNow < self.info.dayNeed then
		self.superFundItemState = 1
	elseif self.info.giftBag2Buy == true and self.info.dayNeed <= self.parent.dayNow and self.info.isSuperAwarded == false then
		self.superFundItemState = 2
	elseif self.info.isSuperAwarded == true then
		self.superFundItemState = 3
	elseif self.info.giftBag2Buy == true and self.parent.dayNow < self.info.dayNeed then
		self.superFundItemState = 4
	elseif self.info.giftBag2Buy == false and self.info.dayNeed <= self.parent.dayNow then
		self.superFundItemState = 5
	end

	self:setFundListInfo()
end

function FundItem:setFundListInfo()
	self.labelDay.text = __("ACTIVITY_BLIND_BOX_GIFTBAG_TEXT10", self.info.dayNeed)

	if self.parent.dayNow < self.info.dayNeed then
		xyd.setUISpriteAsync(self.labelDayBg, "activity_blind_box_battlepass_web", "bg_dl_2", nil, , true)
	else
		xyd.setUISpriteAsync(self.labelDayBg, "activity_blind_box_battlepass_web", "bg_dl_1", nil, , true)
	end

	NGUITools.DestroyChildren(self.baseAwardsGo.transform)

	for i, baseAward in pairs(self.info.baseAwards) do
		if baseAward[1] ~= xyd.ItemID.VIP_EXP and baseAward[1] ~= xyd.ItemID.EXP then
			local tempGo = NGUITools.AddChild(self.baseAwardsGo, self.parent.fundItemIcon)
			local fundItemIcon = FundItemIcon.new(tempGo, self.parent)
			local params = {
				baseFundItemState = self.baseFundItemState,
				award = baseAward,
				scroller = self.parent.scrollerView
			}

			fundItemIcon:setInfo(params)
		end
	end

	self.baseAwardsGo:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.advanceAwardsGo.transform)

	for i, award in pairs(self.info.advanceAwards) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			local tempGo = NGUITools.AddChild(self.advanceAwardsGo, self.parent.fundItemIcon)
			local fundItemIcon = FundItemIcon.new(tempGo, self.parent)
			local params = {
				advFundItemState = self.advFundItemState,
				award = award,
				scroller = self.parent.scrollerView
			}

			fundItemIcon:setInfo(params)
		end
	end

	self.advanceAwardsGo:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.superAwardsGo.transform)

	for i, award in pairs(self.info.superAwards) do
		if award[1] ~= xyd.ItemID.VIP_EXP and award[1] ~= xyd.ItemID.EXP then
			local tempGo = NGUITools.AddChild(self.superAwardsGo, self.parent.fundItemIcon)
			local fundItemIcon = FundItemIcon.new(tempGo, self.parent)
			local params = {
				superFundItemState = self.superFundItemState,
				award = award,
				scroller = self.parent.scrollerView
			}

			fundItemIcon:setInfo(params)
		end
	end

	self.superAwardsGo:GetComponent(typeof(UILayout)):Reposition()
end

return ActivityBlindBoxBattlePass
