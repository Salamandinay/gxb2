local BaseWindow = import(".BaseWindow")
local cjson = require("cjson")
local SoulLandBattlePass = class("SoulLandBattlePass", BaseWindow)
local FundItem = class("FundItem", import("app.common.ui.FixedWrapContentItem"))
local FundItemIcon = class("FundItemIcon")
local CountDown = import("app.components.CountDown")

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
end

function FundItemIcon:setInfo(params)
	if not params then
		dump("error")

		return
	end

	NGUITools.DestroyChildren(self.icon.transform)

	self.itemIcon = xyd.getItemIcon({
		showGetWays = false,
		notShowGetWayBtn = true,
		show_has_num = true,
		scale = 0.6203703703703703,
		itemID = params.award[1],
		num = params.award[2],
		uiRoot = self.icon,
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = params.scroller
	}, xyd.ItemIconType.ADVANCE_ICON)

	if params.baseFundItemState then
		self.imgLock:SetActive(false)

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

function SoulLandBattlePass:ctor(parentGO, params)
	BaseWindow.ctor(self, parentGO, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)

	if not self.activityData then
		dump("requir msg again")

		local msg = messages_pb:get_activity_info_by_id_req()
		msg.activity_id = xyd.ActivityID.SOUL_LAND_BATTLE_PASS

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

		self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SOUL_LAND_BATTLE_PASS)
	end

	if not self.activityData then
		return
	end

	self.params = params
	self.baseAwardIcons = {}
	self.advanceAwardIcons = {}
	self.scoreNow = self.activityData:getScoreNow()
	self.scoreMax = xyd.tables.soulLandBattlePassAwardsTable:getMaxScoreCanHold()
	self.giftBagID = self.activityData:getGiftBagID()
end

function SoulLandBattlePass:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:register()
end

function SoulLandBattlePass:getUIComponent()
	local winTrans = self.window_.transform
	self.logo = winTrans:ComponentByName("topGroup/logo", typeof(UISprite))
	self.timeText = winTrans:ComponentByName("topGroup/timeGroup/timeText", typeof(UILabel))
	self.timeEnd = winTrans:ComponentByName("topGroup/timeGroup/endText", typeof(UILabel))
	self.helpBtn = winTrans:NodeByName("topGroup/helpBtn").gameObject
	self.scrollerView = winTrans:ComponentByName("fundGroup/scroller", typeof(UIScrollView))
	self.wrapContent = self.scrollerView:ComponentByName("groupItem", typeof(UIWrapContent))
	self.passCardBuyBtn = winTrans:NodeByName("topGroup/buyButton2").gameObject
	self.passCardBuyBtnText = self.passCardBuyBtn:ComponentByName("button_lable", typeof(UILabel))
	self.scorBuyBtn = winTrans:NodeByName("topGroup/buyButton1").gameObject
	self.scorBuyBtnText = self.scorBuyBtn:ComponentByName("button_lable", typeof(UILabel))
	self.progressBar = winTrans:NodeByName("topGroup/progressBar").gameObject
	self.progressBarLable1 = self.progressBar:ComponentByName("progressLabel/progressLabel1", typeof(UILabel))
	self.progressBarLable2 = self.progressBar:ComponentByName("progressLabel/progressLabel2", typeof(UILabel))
	self.colName = winTrans:NodeByName("colName").gameObject
	self.scoreText = self.colName:ComponentByName("score", typeof(UILabel))
	self.baseAwardText = self.colName:ComponentByName("baseAward", typeof(UILabel))
	self.advanceAwardText = self.colName:ComponentByName("advanceAward", typeof(UILabel))
	self.fundItem = winTrans:NodeByName("fundItem").gameObject
	self.fundItemIcon = winTrans:NodeByName("fundItemIcon").gameObject
end

function SoulLandBattlePass:layout()
	self:setText()
	self:setTexture()
	self:setFundItems()
end

function SoulLandBattlePass:setText()
	local updateTime = self.activityData.update_time
	local leftTime = updateTime - xyd.getServerTime()

	if leftTime > 0 then
		local countdown = CountDown.new(self.timeText, {
			duration = leftTime
		})
		self.timeEnd.text = __("TEXT_END")
	else
		self.timeText:SetActive(false)
		self.timeEnd:SetActive(false)
	end

	self.passCardBuyBtnText.text = __("SOUL_LAND_BATTLEPASS_TEXT07")
	self.scorBuyBtnText.text = __("SOUL_LAND_BATTLEPASS_TEXT03")
	self.progressBarLable1.text = __("SOUL_LAND_BATTLEPASS_TEXT02")
	self.scoreText.text = __("SOUL_LAND_BATTLEPASS_TEXT04")
	self.baseAwardText.text = __("SOUL_LAND_BATTLEPASS_TEXT05")
	self.advanceAwardText.text = __("SOUL_LAND_BATTLEPASS_TEXT06")

	self:updateProgressBar()

	if self.activityData:checkBuy() then
		xyd.setEnabled(self.passCardBuyBtn, false)
	end
end

function SoulLandBattlePass:setTexture()
	xyd.setUISpriteAsync(self.logo, nil, "soul_land_passcard_logo_" .. xyd.Global.lang)
end

function SoulLandBattlePass:updateProgressBar()
	self.scoreNow = self.activityData:getScoreNow()
	self.progressBarLable2.text = tostring(self.scoreNow) .. "/" .. tostring(self.scoreMax)
	self.progressBar:GetComponent(typeof(UIProgressBar)).value = self.scoreNow / self.scoreMax
end

function SoulLandBattlePass:setFundItems()
	local ids = xyd.tables.soulLandBattlePassAwardsTable:getIDs()
	local fundItemList = {}

	for _, id in ipairs(ids) do
		local params = {
			id = id,
			scoreNow = self.scoreNow,
			scoreNeed = xyd.tables.soulLandBattlePassAwardsTable:getExp(id),
			exBuy = self.activityData:checkBuy(),
			isBaseAwarded = self.activityData:isBassAwardedById(id),
			isAdvanceAwarded = self.activityData:isExAwardedById(id),
			baseAwards = xyd.tables.soulLandBattlePassAwardsTable:getFreeAwards(id),
			advanceAwards = xyd.tables.soulLandBattlePassAwardsTable:getPaidAwards(id)
		}

		table.insert(fundItemList, params)
	end

	self.fundItemList = fundItemList
	self.wrapContentClass = require("app.common.ui.FixedWrapContent").new(self.scrollerView, self.wrapContent, self.fundItem, FundItem, self)
	local fundItemList1 = {}
	local fundItemList2 = {}

	for i, info in ipairs(self.fundItemList) do
		if info.isBaseAwarded == true and info.isAdvanceAwarded == true then
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

function SoulLandBattlePass:updateList()
	for _, info in ipairs(self.fundItemList) do
		local id = info.id
		info.exBuy = self.activityData:checkBuy()
		info.scoreNow = self.activityData.detail.point
		info.isBaseAwarded = self.activityData:isBassAwardedById(id)
		info.isAdvanceAwarded = self.activityData:isExAwardedById(id)
	end

	local fundItemList1 = {}
	local fundItemList2 = {}

	for i, info in ipairs(self.fundItemList) do
		if info.isBaseAwarded == true and info.isAdvanceAwarded == true then
			table.insert(fundItemList2, info)
		else
			table.insert(fundItemList1, info)
		end
	end

	for i, info in ipairs(fundItemList2) do
		table.insert(fundItemList1, info)
	end

	self.wrapContentClass:setInfos(fundItemList1)
	self.activityData:setRedMark()
end

function SoulLandBattlePass:register()
	UIEventListener.Get(self.passCardBuyBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("soul_land_battlepass_buy_window")
	end

	UIEventListener.Get(self.scorBuyBtn).onClick = function ()
		if self.activityData:checkFullScore() then
			xyd.alertTips(__("SOUL_LAND_BATTLEPASS_TEXT12"))
		elseif not self.activityData:checkFullScore() and self.activityData:getRestCanBuy() <= 0 then
			xyd.alertTips(__("SOUL_LAND_BATTLEPASS_TEXT13"))
		else
			xyd.WindowManager.get():openWindow("soul_land_battlepass_buy_point_window")
		end
	end

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "SOUL_LAND_BATTLEPASS_HELP"
		})
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function SoulLandBattlePass:onAward(event)
	local data = xyd.decodeProtoBufData(event.data)

	if event.data.activity_id == xyd.ActivityID.SOUL_LAND_BATTLE_PASS then
		local info = cjson.decode(event.data.detail)

		self:updateList()

		if info.type == 1 then
			local items = info.items

			xyd.itemFloat(items)
		elseif info.type == 2 then
			self:updateProgressBar()
		end
	end
end

function SoulLandBattlePass:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if giftBagID ~= self.giftBagID then
		return
	end

	xyd.setEnabled(self.passCardBuyBtn, false)
	self:updateList()
end

function SoulLandBattlePass:getAward()
	local awardList = {}

	for _, info in ipairs(self.fundItemList) do
		local id = info.id

		if info.scoreNeed <= self.activityData.detail.point and (self.activityData.detail.awarded[id] == 0 or self.activityData.detail.ex_awarded[id] == 0 and self.activityData:checkBuy()) then
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

	self:getUIComponent()
end

function FundItem:getUIComponent()
	self.labelScore = self.go:ComponentByName("box1/labelScore", typeof(UILabel))
	self.baseAwardsGo = self.go:NodeByName("box2/award").gameObject
	self.advanceAwardsGo = self.go:NodeByName("box3/award").gameObject
end

function FundItem:update(_, info)
	if not info then
		return
	end

	self.info = info

	if self.info.scoreNeed <= self.info.scoreNow and self.info.isBaseAwarded == false then
		self.baseFundItemState = 2
	elseif self.info.isBaseAwarded == true then
		self.baseFundItemState = 3
	elseif self.info.scoreNow < self.info.scoreNeed then
		self.baseFundItemState = 1
	end

	if self.info.exBuy == false and self.info.scoreNow < self.info.scoreNeed then
		self.advFundItemState = 1
	elseif self.info.exBuy == true and self.info.scoreNeed <= self.info.scoreNow and self.info.isAdvanceAwarded == false then
		self.advFundItemState = 2
	elseif self.info.isAdvanceAwarded == true then
		self.advFundItemState = 3
	elseif self.info.exBuy == true and self.info.scoreNow < self.info.scoreNeed then
		self.advFundItemState = 4
	elseif self.info.exBuy == false and self.info.scoreNeed <= self.info.scoreNow then
		self.advFundItemState = 5
	end

	self:setFundListInfo()
end

function FundItem:setFundListInfo()
	self.labelScore.text = self.info.scoreNeed

	NGUITools.DestroyChildren(self.baseAwardsGo.transform)

	for i, baseAward in pairs(self.info.baseAwards) do
		local tempGo = NGUITools.AddChild(self.baseAwardsGo, self.parent.fundItemIcon)
		local fundItemIcon = FundItemIcon.new(tempGo, self.parent)
		local params = {
			baseFundItemState = self.baseFundItemState,
			award = baseAward,
			scroller = self.parent.scrollerView
		}

		fundItemIcon:setInfo(params)
	end

	self.baseAwardsGo:GetComponent(typeof(UILayout)):Reposition()
	NGUITools.DestroyChildren(self.advanceAwardsGo.transform)

	for i, award in pairs(self.info.advanceAwards) do
		local tempGo = NGUITools.AddChild(self.advanceAwardsGo, self.parent.fundItemIcon)
		local fundItemIcon = FundItemIcon.new(tempGo, self.parent)
		local params = {
			advFundItemState = self.advFundItemState,
			award = award,
			scroller = self.parent.scrollerView
		}

		fundItemIcon:setInfo(params)
	end

	self.advanceAwardsGo:GetComponent(typeof(UILayout)):Reposition()
end

return SoulLandBattlePass
