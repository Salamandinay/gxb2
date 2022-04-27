local BaseWindow = import(".BaseWindow")
local HeroChallengeDetailWindow = class("HeroChallengeDetailWindow", BaseWindow)
local ResItem = import("app.components.ResItem")
local WindowTop = import("app.components.WindowTop")
local BaseComponent = import("app.components.BaseComponent")
local HeroChallengeDetailItem = class("HeroChallengeDetailItem", BaseComponent)
local WarmUpHeroChallengeDetailItem = class("WarmUpHeroChallengeDetailItem", HeroChallengeDetailItem)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.data = nil
end

function ItemRender:update(index, info)
	self.data = info

	if not info then
		self.go:SetActive(false)

		return
	end

	if not self.heroChallengeItem then
		local itemClass = self.parent.itemClass
		self.heroChallengeItem = itemClass.new(self.go)

		self.heroChallengeItem:setDragScrollView(self.parent.scrollView)
	end

	self.heroChallengeItem.data = info

	self.go:SetActive(true)
	self.heroChallengeItem:update()
end

function ItemRender:refresh()
	if self.data then
		self.heroChallengeItem:update()
	end
end

function ItemRender:getGameObject()
	return self.go
end

function HeroChallengeDetailWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isShowRedPont_ = false
	self.skinName = "HeroChallengeDetailWindowSkin"
	self.fortId = params.fort_id
	self.isGuiding = params.isGuiding

	xyd.models.heroChallenge:setCurFort(self.fortId)

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		self.table_ = xyd.tables.partnerChallengeChessTable
	else
		self.table_ = xyd.tables.partnerChallengeTable
	end
end

function HeroChallengeDetailWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	local data = self.table_:getIdsByFort(self.fortId)
	self.labelTitle_.text = self.table_:fortName2(data[1])

	if xyd.Global.lang == "fr_fr" and self.fortId == 10 then
		self.labelTitle_.fontSize = 26
	end

	self.labelTime = self.ticketResItem:getTimeLabel()

	function self.labelTime.callback()
		self:updateTickets()
	end

	self:initResItem()
	self:initData()
	self:initBtn()
	self:register()
	self:openImgGuide()

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		return
	end

	if xyd.models.heroChallenge:getRewards(self.fortId) then
		xyd.WindowManager.get():openWindow("hero_challenge_fight_award_window", {
			fortId = self.fortId
		})
	end
end

function HeroChallengeDetailWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupMain_ = trans:NodeByName("groupMain_").gameObject
	local topGroup = self.groupMain_:NodeByName("topGroup").gameObject
	self.labelTitle_ = topGroup:ComponentByName("labelTitle_", typeof(UILabel))
	self.helpBtn = topGroup:NodeByName("helpBtn").gameObject
	self.btnReset = topGroup:NodeByName("btnReset").gameObject
	self.btnCheck = topGroup:NodeByName("btnCheck").gameObject
	self.btnCheckImgRedPoint = self.btnCheck:ComponentByName("imgRedPoint", typeof(UISprite))
	self.scrollView = self.groupMain_:ComponentByName("scroller_", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("itemGroup", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	local ticketResItemContainer = trans:NodeByName("ticketResItem").gameObject
	self.ticketResItemContainer_ = ticketResItemContainer
	self.ticketResItem = ResItem.new(ticketResItemContainer)
	local booklabelResItemContainer = trans:NodeByName("booklabelResItem").gameObject
	self.booklabelResItem = ResItem.new(booklabelResItemContainer)
end

function HeroChallengeDetailWindow:onHelpBtnOpen_()
	if self.fortId == 15 then
		xyd.WindowManager.get():openWindow("help_window", {
			key = "PARTNER_CHALLENGE_CHESS_TEXT07"
		})
	else
		self.super.onHelpBtnOpen_(self)
	end
end

function HeroChallengeDetailWindow:openImgGuide()
	local type = 0

	if self.fortId == 5 or self.fortId == 6 then
		type = 1
	elseif xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		type = 2
	end

	local hasOpen = xyd.db.misc:getValue("hero_challenge_img_guide_open" .. tostring(type))

	if not hasOpen and xyd.Global.lang ~= "fr_fr" and xyd.Global.lang ~= "ko_kr" and xyd.Global.lang ~= "de_de" and type ~= 2 then
		xyd.WindowManager.get():openWindow("img_guide_window", {
			wndname = "hero_challenge_detail_guide",
			start_type = type
		})
		xyd.db.misc:addOrUpdate({
			value = 1,
			key = "hero_challenge_img_guide_open" .. tostring(type)
		})
	end
end

function HeroChallengeDetailWindow:checkFirstIn15()
	if self.fortId ~= 15 or self.isGuiding then
		return
	end

	if not xyd.db.misc:getValue("challenge_fort_15_first") then
		xyd.db.misc:setValue({
			value = 1,
			key = "challenge_fort_15_first"
		})
		self:onHelpBtnOpen_()
	end
end

function HeroChallengeDetailWindow:playOpenAnimation(callback)
	callback()

	local localPosition = self.groupMain_.transform.localPosition

	self.groupMain_:SetLocalPosition(-1000, localPosition.y, 0)
	self:setTimeout(function ()
		local sequence = self:getSequence()

		sequence:Append(self.groupMain_.transform:DOLocalMoveX(50, 0.3))
		sequence:Append(self.groupMain_.transform:DOLocalMoveX(0, 0.27))
		sequence:AppendCallback(handler(self, function ()
			sequence:Kill(false)

			sequence = nil

			self:setWndComplete()
		end))
	end, self, 200)
	self:checkFirstIn15()
end

function HeroChallengeDetailWindow:register()
	HeroChallengeDetailWindow.super.register(self)

	UIEventListener.Get(self.btnCheck).onClick = function ()
		self:onCheckTouch()
	end

	self.eventProxy_:addEventListener(xyd.event.FIGHT_CHESS, handler(self, self.onChessFight))
	self.eventProxy_:addEventListener(xyd.event.RESET_FORT_CHESS, handler(self, self.onChessReset))
	self.eventProxy_:addEventListener(xyd.event.SELL_PARTNER, handler(self, self.onChessSellPartner))
	self.eventProxy_:addEventListener(xyd.event.BUY_PARTNER, handler(self, self.onChessBuy))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_CHESS_SHOP, handler(self, self.onChessRefreshShop))
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_FIGHT, handler(self, self.onFight))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.updateTickets))
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_RESET_FORT, handler(self, self.onReset))
	self.eventProxy_:addEventListener(xyd.event.UPDATE_CHALLENGE_TICKET, handler(self, self.updateTickets))
end

function HeroChallengeDetailWindow:onChessRefreshShop()
	self:updateBookLabel()
end

function HeroChallengeDetailWindow:onChessBuy()
	self:updateBookLabel()
end

function HeroChallengeDetailWindow:onChessReset()
	self:updateBookLabel()
	self:initData()
	xyd.alertTips(__("GUILD_RESET_SUCCESS"))
end

function HeroChallengeDetailWindow:onChessSellPartner()
	self:updateBookLabel()
end

function HeroChallengeDetailWindow:onChessFight(event)
	self:updateBookLabel()
	self.wrapContent:refresh()

	local cur = xyd.models.heroChallenge:getCurrentStage(self.fortId)

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS and cur == -1 then
		return
	end

	if event.data.is_win == 0 then
		self:setRedPoint(true)

		self.isShowRedChess_ = true
	end

	self:checkChessRedPoint()
end

function HeroChallengeDetailWindow:checkChessRedPoint()
	local hp = xyd.models.heroChallenge:getHp(self.fortId)

	if hp <= 0 then
		self.isShowRedChess_ = false

		self:setRedPoint(true)
	end
end

function HeroChallengeDetailWindow:initBtn()
	local ids = self.table_:getIdsByFort(self.fortId)
	local isPuzzle = self.table_:isPuzzle(ids[1])

	if isPuzzle then
		self.btnCheck:SetActive(false)
	else
		self.btnCheck:SetActive(true)
	end
end

function HeroChallengeDetailWindow:onCheckTouch()
	xyd.WindowManager.get():openWindow("hero_challenge_team_window", {
		fort_id = self.fortId,
		show_red_point = self.isShowRedPont_,
		show_red_chess = self.isShowRedChess_
	})
end

function HeroChallengeDetailWindow:onResetTouch()
	local cost = xyd.tables.miscTable:split2Cost("challenge_reset_cost", "value", "#")

	if xyd.models.heroChallenge:getTicket() < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("HERO_CHALLENGE_TIPS2", cost[2]))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("HERO_CHALLENGE_TIPS3"), function (yes)
		if yes then
			xyd.models.heroChallenge:reqResetFort(self.fortId)
		end
	end)
end

function HeroChallengeDetailWindow:onFight(event)
	self:updateTickets()
	self.wrapContent:refresh()
	self:checkRedPoint(event.data)
end

function HeroChallengeDetailWindow:onReset()
	self:updateTickets()
	self:initData()
	xyd.alert(xyd.AlertType.TIPS, __("GUILD_RESET_SUCCESS"))
end

function HeroChallengeDetailWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true)
	self.labelTime = self.ticketResItem:getTimeLabel()

	local function callbackFunc()
		local params = {
			show_has_num = true,
			itemID = xyd.ItemID.HERO_CHALLENGE_CHESS,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	self.ticketResItem:setInfo({
		tableId = xyd.ItemID.HERO_CHALLENGE
	})
	self.booklabelResItem:setInfo({
		tableId = xyd.ItemID.HERO_CHALLENGE_CHESS,
		callback = callbackFunc
	})
	self.booklabelResItem:hidePlus()

	local bookNum = xyd.models.heroChallenge:initBookLabel(self.fortId)

	self.booklabelResItem:setItemNum(bookNum)

	local ticket = xyd.models.heroChallenge:getTicket()

	self.ticketResItem:setItemNum(ticket)

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) ~= xyd.HeroChallengeFort.CHESS then
		self.booklabelResItem:canShow(false)
		self.ticketResItemContainer_.transform:X(0)
	else
		self.booklabelResItem:canShow(true)
	end

	self:updateTickets()
end

function HeroChallengeDetailWindow:updateTickets()
	local leftTime = xyd.models.heroChallenge:getLeftTime()

	if leftTime > 0 then
		self.ticketResItem:setTimeLabel(true)
		self.labelTime:setInfo({
			duration = leftTime
		})
	else
		self.ticketResItem:setTimeLabel(false)
	end

	local ticket = xyd.models.heroChallenge:getTicket()

	self.ticketResItem:setItemNum(ticket)
end

function HeroChallengeDetailWindow:initData()
	local ids = self.table_:getIdsByFort(self.fortId)
	local data = {}
	local activity_id = nil

	for i = 1, #ids do
		table.insert(data, {
			showFight = true,
			id = ids[i],
			index = i,
			fort_id = self.fortId
		})

		activity_id = self.table_:getIsActivity(ids[i])
	end

	if activity_id then
		local data = xyd.models.activity:getActivity(activity_id)

		if data then
			self.itemClass = WarmUpHeroChallengeDetailItem
		else
			self.itemClass = HeroChallengeDetailItem
		end
	else
		self.itemClass = HeroChallengeDetailItem
	end

	self.warpData_ = data

	self.wrapContent:setInfos(data, {})
end

function HeroChallengeDetailWindow:checkRedPoint(data)
	local isWin = data.is_win

	if isWin == 0 then
		local aliveNum = xyd.models.heroChallenge:getAliveNum(self.fortId)

		if aliveNum < 6 then
			self:setRedPoint(true)
		end
	end
end

function HeroChallengeDetailWindow:updateBookLabel()
	local bookNum = xyd.models.heroChallenge:getCoin(self.fortId)

	self.booklabelResItem:setItemNum(bookNum)
end

function HeroChallengeDetailWindow:setRedPoint(flag)
	self.btnCheckImgRedPoint:SetActive(flag)

	self.isShowRedPont_ = flag

	if not flag then
		self.isShowRedChess_ = false
	end
end

function HeroChallengeDetailWindow:getHeroChallengeDetailItem()
	return HeroChallengeDetailItem
end

function HeroChallengeDetailItem:ctor(parentGo)
	HeroChallengeDetailItem.super.ctor(self, parentGo)

	self.StageTable = xyd.tables.stageTable
	self.mapsModel = xyd.models.map
	self.skinName = "HeroChallengeDetailItemSkin"
end

function HeroChallengeDetailItem:getPrefabPath()
	return "Prefabs/Components/hero_challenge_detail_item"
end

function HeroChallengeDetailItem:initUI()
	HeroChallengeDetailItem.super.initUI(self)

	local go = self.go
	self.content = go:NodeByName("content").gameObject
	self.imgBg = self.content:ComponentByName("imgBg", typeof(UISprite))
	self.labelFortName = self.content:ComponentByName("labelFortName", typeof(UILabel))
	self.fGroup = self.content:NodeByName("fGroup").gameObject
	self.fortImg = self.fGroup:ComponentByName("fortImg", typeof(UISprite))
	self.labelFortDes = self.fGroup:ComponentByName("labelFortDes", typeof(UILabel))
	self.maskGroup = self.content:NodeByName("maskGroup").gameObject
	self.imgAsk = self.maskGroup:ComponentByName("imgAsk", typeof(UISprite))
	self.imgMask = self.maskGroup:ComponentByName("imgMask", typeof(UISprite))
	self.imgLock = self.maskGroup:ComponentByName("imgLock", typeof(UISprite))
	self.groupItem = self.content:NodeByName("groupItem").gameObject
	self.fortEffectGroup = self.content:ComponentByName("fortEffectGroup", typeof(UISprite))

	self:createChildren()
end

function HeroChallengeDetailItem:createChildren()
	self:setTouchListener(handler(self, self.onClickFortItem))
end

function HeroChallengeDetailItem:update()
	self.index = self.data.index
	self.id = self.data.id
	self.fortId = self.data.fort_id

	if xyd.tables.partnerChallengeChessTable:getFortType(self.fortId) == xyd.HeroChallengeFort.CHESS then
		self.FortTable = xyd.tables.partnerChallengeChessTable
	else
		self.FortTable = xyd.tables.partnerChallengeTable
	end

	self:initItem()
end

function HeroChallengeDetailItem:initItem()
	self.labelFortName.text = __("CHAPTER_COUNT", self.index)
	self.labelFortDes.text = self.FortTable:name(self.id)

	xyd.setUISpriteAsync(self.fortImg, nil, self.FortTable:chapterIcon(self.id))
	NGUITools.DestroyChildren(self.groupItem.transform)

	local currentStage = xyd.models.heroChallenge:getCurrentStage(self.fortId)

	self:checkLock()

	if self.id == currentStage and self.data.showFight then
		if not self.fortEffect then
			self.fortEffectGroup.gameObject:SetActive(true)

			self.fortEffect = xyd.Spine.new(self.fortEffectGroup.gameObject)

			self.fortEffect:setInfo("jianxg", function ()
				self.fortEffect:SetLocalPosition(0, 0, 0)
				self.fortEffect:SetLocalScale(1, 1, 1)
				self.fortEffect:setRenderTarget(self.fortEffectGroup, 2)
				self.fortEffect:play("texiao1", 0)
			end)
		end
	elseif self.fortEffect then
		self.fortEffect:destroy()

		self.fortEffect = nil
	end

	self:createItem()
end

function HeroChallengeDetailItem:createItem()
	local info = xyd.models.heroChallenge:getFortInfoByFortID(self.fortId)
	local rewards1 = self.FortTable:getReward1(self.id)
	local icon = xyd.getItemIcon({
		hideText = true,
		itemID = rewards1[1][1],
		num = rewards1[1][2],
		uiRoot = self.groupItem
	})

	if info and info.base_info and self.id <= info.base_info.fight_max_stage then
		icon:setChoose(true)
	end
end

function HeroChallengeDetailItem:checkLock()
	local currentStage = xyd.models.heroChallenge:getCurrentStage(self.fortId)

	if not xyd.checkFunctionOpen(xyd.FunctionID.HERO_CHALLENGE, true) then
		self:lock()

		return
	end

	if currentStage == -1 or self.id <= currentStage then
		self:unlock()
	else
		self:lock()
	end
end

function HeroChallengeDetailItem:onClickFortItem()
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if self.isLocked then
		xyd.showToast(__("LOCK_STORY_LIST"))

		return false
	else
		xyd.WindowManager.get():openWindow("hero_challenge_fight_window", {
			id = self.id,
			fortId = self.fortId
		})
	end
end

function HeroChallengeDetailItem:unlock()
	local info = xyd.models.heroChallenge:getFortInfoByFortID(self.fortId)
	self.isLocked = false

	self.maskGroup:SetActive(false)
	self.fGroup:SetActive(true)

	self.labelFortName.text = __("CHAPTER_COUNT", self.index)
end

function HeroChallengeDetailItem:lock()
	self.imgLock:SetActive(true)
	self.fortEffectGroup.gameObject:SetActive(false)

	self.isLocked = true

	self.maskGroup:SetActive(true)
	self.fGroup:SetActive(true)

	self.labelFortName.text = __("CHAPTER_COUNT", self.index)
end

function WarmUpHeroChallengeDetailItem:ctor(parentGo)
	HeroChallengeDetailItem.ctor(self, parentGo)

	self.skinName = "WarmUpHeroChallengeDetailItemSkin"
end

function WarmUpHeroChallengeDetailItem:getPrefabPath()
	return "Prefabs/Components/warm_up_hero_challenge_detail_item"
end

function WarmUpHeroChallengeDetailItem:initUI()
	WarmUpHeroChallengeDetailItem.super.initUI(self)

	self.missionLabel = self.content:ComponentByName("missionLabel", typeof(UILabel))
	self.progress = self.content:ComponentByName("progress", typeof(UIProgressBar))
	self.labelDisplay = self.progress:ComponentByName("labelDisplay", typeof(UILabel))
	self.progress_fore = self.progress:ComponentByName("fore", typeof(UISprite))

	xyd.setUISpriteAsync(self.progress_fore, nil, "activity_bar_thumb")
end

function WarmUpHeroChallengeDetailItem:createChildren()
	HeroChallengeDetailItem.createChildren(self)
end

function WarmUpHeroChallengeDetailItem:createItem()
	if self:checkComplete() then
		HeroChallengeDetailItem.createItem(self)
	else
		local data = xyd.tables.newPartnerWarmUpMissionTable:getAwardsByChallengeId(self.id)
		local item = xyd.getItemIcon({
			hideText = true,
			itemID = data[1],
			num = data[2],
			uiRoot = self.groupItem
		})
	end
end

function WarmUpHeroChallengeDetailItem:checkComplete()
	local data = xyd.models.activity:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		local detail = data.detail

		if detail then
			local list = detail.missions
			local mission_id = xyd.tables.newPartnerWarmUpMissionTable:getMissionIdByChallengeId(self.id)
			local mission_data = list[mission_id]

			if mission_data then
				return mission_data.is_completed ~= 0
			end
		end
	end

	return false
end

function WarmUpHeroChallengeDetailItem:uncomplete()
	self.progress:SetActive(true)

	local maximum = xyd.tables.newPartnerWarmUpMissionTable:getCompleteValueByChallengeId(self.id)
	local data = xyd.models.activity:getActivity(xyd.ActivityID.NEW_PARTNER_WARMUP)

	if data then
		local detail = data.detail

		if detail then
			local list = detail.missions
			local mission_id = xyd.tables.newPartnerWarmUpMissionTable:getMissionIdByChallengeId(self.id)
			local mission_data = list[mission_id]

			if mission_data then
				self.progress.value = mission_data.value / maximum
				self.labelDisplay.text = mission_data.value .. "/" .. maximum
			end
		end
	end

	self.maskGroup:SetActive(true)
	self.imgCompleteMask:SetActive(true)
	self.imgAsk:SetActive(true)
	self.imgLock:SetActive(false)
	self.imgMask:SetActive(false)

	self.missionLabel.text = xyd.tables.newPartnerWarmingUpMissionTextTable:getDesc(self.index)

	self.missionLabel:SetActive(true)

	self.is_complete_ = false

	self.labelFortDes:SetActive(false)
	self.labelFortName:SetActive(false)
end

function WarmUpHeroChallengeDetailItem:complete()
	self.progress:SetActive(false)
	self.missionLabel:SetActive(false)

	self.is_complete_ = true

	self.labelFortDes:SetActive(true)
	self.labelFortName:SetActive(true)
end

function WarmUpHeroChallengeDetailItem:checkLock()
	if self:checkComplete() then
		HeroChallengeDetailItem.checkLock(self)
	else
		self:uncomplete()
	end
end

function WarmUpHeroChallengeDetailItem:unlock()
	self:complete()
	HeroChallengeDetailItem.unlock(self)
	self.imgAsk:SetActive(false)
end

function WarmUpHeroChallengeDetailItem:lock()
	self:complete()
	HeroChallengeDetailItem.lock(self)
	self.imgAsk:SetActive(true)
end

function WarmUpHeroChallengeDetailItem:onClickFortItem()
	return HeroChallengeDetailItem.onClickFortItem(self)
end

return HeroChallengeDetailWindow
