local BaseWindow = import(".BaseWindow")
local BaseComponent = import("app.components.BaseComponent")
local ResItem = import("app.components.ResItem")
local TowerWindow = class("TowerWindow", BaseWindow)
local TowerItem = class("TowerItem", BaseComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local WindowTop = import("app.components.WindowTop")
local CountDown = import("app.components.CountDown")
local ItemRender = class("ItemRender")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.towerItem = TowerItem.new(go)

	self.towerItem:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, stage)
	if not stage then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.towerItem.data = stage

	self.towerItem:dataChanged()
end

function ItemRender:getGameObject()
	return self.go
end

function TowerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.nowAwardsId = -1
	self.isBattleWin_ = 0
	self.skinName = "TowerWindowSkin"

	if params then
		self.isBattleWin_ = params.isWin or 0
	end
end

function TowerWindow:addToUILayer(layer)
	BaseWindow.addToUILayer(self, layer)

	if self.params.not_show then
		self:hideWindow()
	end
end

function TowerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:register()

	local maxNum = xyd.tables.miscTable:getNumber("tower_water_max", "value")

	if maxNum <= xyd.models.towerMap:getTicket() then
		self.ticketResItem:setTimeLabel(false)
	else
		self.ticketResItem:setTimeLabel(true)
	end

	if xyd.models.towerMap.stage == 0 or xyd.models.towerMap:isRequireTowerInfo() then
		xyd.models.towerMap:reqMapInfo()
	else
		self:onTowerMapInfo()
	end

	if self:isNeedShowWin() and not xyd.models.towerMap:isSkipReport(xyd.BattleType.TOWER) then
		self:playWinAction()
	end

	self:setNowAwardsId()
end

function TowerWindow:getUIComponent()
	local trans = self.window_.transform
	self.topGroup = trans:NodeByName("topGroup").gameObject
	local ticketResItemContainer = trans:NodeByName("ticketResItem").gameObject
	self.ticketResItem = ResItem.new(ticketResItemContainer)
	local groupScroller_ = trans:NodeByName("groupScroller_").gameObject
	self.scrollView = groupScroller_:ComponentByName("scrollerStage", typeof(UIScrollView))
	self.scrollPanel = groupScroller_:ComponentByName("scrollerStage", typeof(UIPanel))
	local wrapContent = self.scrollView:ComponentByName("dataGroupStage", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("container").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)
	local btnGroup = trans:NodeByName("btnGroup").gameObject
	self.btnRank = btnGroup:NodeByName("btnRank").gameObject
	self.btnRecord = btnGroup:NodeByName("btnRecord").gameObject
	self.helpBtn = btnGroup:NodeByName("helpBtn").gameObject
	self.dressShowBtn = btnGroup:NodeByName("btnDressShow").gameObject
	self.actionMask_ = trans:NodeByName("actionMask_").gameObject
	self.leftBtnGroup = trans:NodeByName("leftBtnGroup").gameObject
	self.oldSchoolBtn = self.leftBtnGroup:NodeByName("oldSchoolBtn").gameObject
	self.oldSchoolBtn_UISprite = self.leftBtnGroup:ComponentByName("oldSchoolBtn", typeof(UISprite))
	self.oldSchoolBtn_redPoint = self.oldSchoolBtn:NodeByName("redPoint").gameObject
	self.oldSchoolBtnLabel = self.leftBtnGroup:ComponentByName("oldSchoolBtnLabel", typeof(UILabel))
	self.rightBtnGroup = trans:NodeByName("rightBtnGroup").gameObject
	self.towerFundBtn = self.rightBtnGroup:NodeByName("towerFundBtn").gameObject
	self.towerFundBtn_redPoint = self.towerFundBtn:NodeByName("redPoint").gameObject
	self.topAwardNode = trans:NodeByName("topAwardNode").gameObject
	self.awardsWords = self.topAwardNode:ComponentByName("container/awardsWords", typeof(UILabel))
	self.awardsContainer = self.topAwardNode:NodeByName("container/awardsContainer").gameObject

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.OLD_SCHOOL
	}, self.oldSchoolBtn_redPoint.gameObject)
	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.TOWER_FUND_GIFTBAG
	}, self.towerFundBtn_redPoint.gameObject)
end

function TowerWindow:register()
	TowerWindow.super.register(self)

	UIEventListener.Get(self.btnRank).onClick = function ()
		self:openRankWindow()
	end

	self.eventProxy_:addEventListener(xyd.event.TOWER_MAP_INFO, handler(self, self.onTowerMapInfo))
	self.eventProxy_:addEventListener(xyd.event.ITEM_CHANGE, handler(self, self.refresResItem))
	self.eventProxy_:addEventListener(xyd.event.TOWER_FIGHT, handler(self, self.updateGiftbagData))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.checkFundGiftbagBtn))

	UIEventListener.Get(self.oldSchoolBtn).onClick = function ()
		xyd.models.oldSchool:openOldSchoolMainWindow()
	end

	UIEventListener.Get(self.towerFundBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("tower_fund_giftbag_window")
	end

	self.scrollView.onDragMoving = handler(self, function ()
		self:setNowAwardsId()
	end)

	self:checkOldSchoolImg()
	self:checkFundGiftbagBtn()
end

function TowerWindow:updateGiftbagData()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.TOWER_FUND_GIFTBAG)

	if activityData then
		xyd.models.activity:reqActivityByID(xyd.ActivityID.TOWER_FUND_GIFTBAG)
	end
end

function TowerWindow:checkFundGiftbagBtn()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.TOWER_FUND_GIFTBAG)
	local isFinish = true

	if activityData then
		for _, v in pairs(activityData.detail.awards_info.awarded) do
			if v == 0 then
				isFinish = false
			end
		end

		for _, v in pairs(activityData.detail.charges) do
			if v.buy_times == 0 then
				isFinish = false
			end
		end
	end

	if xyd.models.towerMap.stage >= 20 and activityData and not isFinish then
		self.towerFundBtn:SetActive(true)
	else
		self.towerFundBtn:SetActive(false)
	end
end

function TowerWindow:checkOldSchoolImg()
	self.oldSchoolBtnLabel.text = ""

	if xyd.models.oldSchool:getAllInfo() then
		if xyd.models.oldSchool:isCanOpen() == true then
			xyd.setUISpriteAsync(self.oldSchoolBtn_UISprite, nil, "old_school_enter_active_" .. xyd.Global.lang, nil, )
			self:initTime()
		else
			xyd.setUISpriteAsync(self.oldSchoolBtn_UISprite, nil, "old_school_enter_grey_" .. xyd.Global.lang)

			self.oldSchoolBtnLabel.text = ""
		end
	else
		xyd.setUISpriteAsync(self.oldSchoolBtn_UISprite, nil, "old_school_enter_grey_" .. xyd.Global.lang)

		self.oldSchoolBtnLabel.text = ""
	end
end

function TowerWindow:initTime()
	local durationTime = xyd.models.oldSchool:getChallengeEndTime() - xyd.getServerTime()

	if durationTime <= 0 then
		durationTime = xyd.models.oldSchool:getShowEndTime() - xyd.getServerTime()
	end

	if durationTime > 0 then
		CountDown.new(self.oldSchoolBtnLabel, {
			duration = durationTime,
			callback = handler(self, self.oldSchoolTimeOver)
		})
	else
		self:oldSchoolTimeOver()
	end
end

function TowerWindow:setNowAwardsId()
	local topShowId = -1
	local itemHeight = 362

	if not self.scrollView then
		return
	end

	local scrollViewTopY = self.scrollView:Y() - self.scrollPanel.height / 2
	local scrollViewBottomY = self.scrollView:Y() + self.scrollPanel.height / 2
	local items = self.wrapContent:getItems()
	local topStage = 0
	local needTopAward = true

	for _, tmpItem in pairs(items) do
		if tmpItem.towerItem and tmpItem.towerItem.data then
			local itemTopY = -tmpItem.go:Y() - itemHeight / 2
			local itemBottomY = -tmpItem.go:Y() + itemHeight / 2

			if tmpItem.towerItem.data % 5 == 0 and scrollViewTopY - itemTopY <= 0.2 * itemHeight and itemBottomY - scrollViewBottomY <= 0.2 * itemHeight then
				topShowId = 0
				needTopAward = false
			end

			if itemTopY <= scrollViewTopY and scrollViewTopY < itemBottomY then
				topStage = tmpItem.towerItem.data
			end
		end
	end

	if topStage > 0 and topStage <= xyd.models.towerMap.stage then
		self:updateAwardsById(math.ceil(xyd.models.towerMap.stage / 5) * 5)

		return
	end

	if topStage == 0 and needTopAward then
		return
	end

	if needTopAward then
		topShowId = math.ceil(topStage / 5) * 5
	end

	self:updateAwardsById(topShowId)
end

function TowerWindow:updateAwardsById(id)
	if id == self.nowAwardsId then
		return
	end

	local stage = xyd.models.towerMap.stage

	if self:isNeedShowWin() then
		stage = stage - 1
	end

	self.awardsContainer:SetActive(true)

	local max = xyd.tables.miscTable:getNumber("tower_top", "value")

	if id <= 0 or max < xyd.models.towerMap.stage then
		self.topAwardNode:SetActive(false)
	elseif id > stage + 9 then
		self.awardsContainer:SetActive(false)
		self.topAwardNode:SetActive(true)
	else
		NGUITools.DestroyChildren(self.awardsContainer.transform)
		self.topAwardNode:SetActive(true)

		local rewards = xyd.tables.towerTable:getReward(id)

		for i = 1, #rewards do
			local data = rewards[i]
			local item = {
				show_has_num = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = self.awardsContainer
			}
			local icon = xyd.getItemIcon(item)

			icon:setScale(64 / xyd.DEFAULT_ITEM_SIZE)
			icon.go:X(-70 + (i - 1) * 70)
		end
	end

	self.awardsWords.text = __("TOWER_SHOW_TEXT01", id - stage + 1)

	if id - stage == 0 then
		self.awardsWords.text = __("TOWER_SHOW_TEXT02")
	end

	self.nowAwardsId = id
end

function TowerWindow:oldSchoolTimeOver()
	self.oldSchoolBtnLabel.text = ""
	local durationTime = xyd.models.oldSchool:getShowEndTime() - xyd.getServerTime()

	if durationTime > 0 then
		self:initTime()
	end
end

function TowerWindow:refresResItem(event)
	local ticket = xyd.models.towerMap:getTicket()

	self.ticketResItem:setItemNum(ticket)

	local leftTime = xyd.models.towerMap:getLeftTime()

	if leftTime > 0 then
		self.labelTime:setCountDownTime(leftTime)
		self.ticketResItem:setTimeLabel(true)
	else
		self.ticketResItem:setTimeLabel(false)
	end
end

function TowerWindow:openRankWindow()
	xyd.WindowManager.get():openWindow("rank_window", {
		mapType = xyd.MapType.TOWER
	})
end

function TowerWindow:setLayout()
	self:initTopGroup()
end

function TowerWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.topGroup, self.name_, 1, true)
	self.labelTime = self.ticketResItem:getTimeLabel()

	self.ticketResItem:setBtnCallback(handler(self, self.onPurchaseTicket))
	self.ticketResItem:setInfo({
		tableId = xyd.ItemID.TOWER_TICKET
	})

	local ticket = xyd.models.towerMap:getTicket()

	self.ticketResItem:setItemNum(ticket)
end

function TowerWindow:onTowerMapInfo()
	local stage = xyd.models.towerMap.stage

	if self:isNeedShowWin() and not xyd.models.towerMap:isSkipReport(xyd.BattleType.TOWER) then
		stage = stage - 1
	end

	local max = math.min(stage + 11, xyd.tables.miscTable:getNumber("tower_top", "value"))
	local list = {}

	for i = max, stage - 7, -1 do
		if i < 1 then
			break
		end

		table.insert(list, i)
	end

	self.wrapContent:setInfos(list, {})
	self.wrapContent:jumpToInfo(math.min(stage + 1, max))

	local leftTime = xyd.models.towerMap:getLeftTime()

	if leftTime > 0 then
		self.labelTime:setCountDownTime(leftTime)
		self.ticketResItem:setTimeLabel(true)
	else
		self.ticketResItem:setTimeLabel(false)
	end

	local ticket = xyd.models.towerMap:getTicket()

	self.ticketResItem:setItemNum(ticket)

	UIEventListener.Get(self.btnRecord).onClick = function ()
		xyd.WindowManager:get():openWindow("tower_record_window")
	end

	UIEventListener.Get(self.dressShowBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("dress_show_buffs_detail_window", {
			function_id = xyd.FunctionID.TOWER
		})
	end

	self:setNowAwardsId()
end

function TowerWindow:onTowerBattle(event)
	if xyd.models.towerMap:isSkipReport(xyd.BattleType.TOWER) then
		return
	end

	local ticket = xyd.models.towerMap:getTicket()

	self.ticketResItem:setItemNum(ticket)

	if event.data.is_win == 0 then
		local leftTime = xyd.models.towerMap:getLeftTime()

		if leftTime > 0 then
			self.labelTime:setCountDownTime(leftTime)
			self.ticketResItem:setTimeLabel(true)
		else
			self.ticketResItem:setTimeLabel(false)
		end

		return
	end

	local stage = event.data.stage_id + 1
	local list = {}
	local max = math.min(stage + 11, xyd.tables.miscTable:getNumber("tower_top", "value"))
	stage = math.min(stage, max)

	for i = max, stage - 7, -1 do
		if i < 1 then
			break
		end

		table.insert(list, i)
	end

	self.wrapContent:setInfos(list, {})
end

function TowerWindow:onTowerUpdate(data)
	local ticket = xyd.models.towerMap:getTicket()

	self.ticketResItem:setItemNum(ticket)

	if data.event_data.battle_report.isWin == 0 then
		local leftTime = xyd.models.towerMap:getLeftTime()

		if leftTime > 0 then
			self.labelTime:setCountDownTime(leftTime)
			self.ticketResItem:setTimeLabel(true)
		else
			self.ticketResItem:setTimeLabel(false)
		end

		return
	end

	local stage = data.event_data.stage_id + 1
	local list = {}
	local max = math.min(stage + 11, xyd.tables.miscTable:getNumber("tower_top", "value"))
	stage = math.min(stage, max)

	for i = max, stage - 7, -1 do
		if i < 1 then
			break
		end

		table.insert(list, i)
	end

	self.wrapContent:setInfos(list, {})
	self.wrapContent:jumpToInfo(math.min(stage + 1, max))
end

function TowerWindow:onPurchaseTicket()
	xyd.WindowManager.get():openWindow("item_purchase_window", {
		exchange_id = xyd.ExchangeItem._2TO13
	})
end

function TowerWindow:isNeedShowWin()
	if xyd.models.towerMap:isSkipReport(xyd.BattleType.TOWER) then
		return false
	end

	return self.isBattleWin_ ~= 0
end

function TowerWindow:playWinAction()
	self.scrollView.enabled = false

	self:setTimeout(function ()
		if self and self.scrollView then
			self.scrollView.enabled = true
		end
	end, self, 3000)
	self:setTimeout(function ()
		local item1, item2 = nil
		local stage = xyd.models.towerMap.stage
		local items = self.wrapContent:getItems()

		for _, tmpItem in pairs(items) do
			if tmpItem.towerItem then
				if tmpItem.towerItem.data == stage - 1 then
					item1 = tmpItem.towerItem
				elseif tmpItem.towerItem.data == stage then
					item2 = tmpItem.towerItem
				end
			end
		end

		if item1 then
			item1:playCompleteAction(function ()
				if not self then
					return
				end

				local maxStage = xyd.tables.miscTable:getNumber("tower_top", "value")

				if item1.data >= maxStage - 2 then
					self.isBattleWin_ = 0
					self.scrollView.enabled = true

					item1:update()

					if item2 then
						item2:update()
					end

					return
				end

				local posY = math.max(self.scrollView:Y() - 362, self:getMinY())
				local sp = SpringPanel.Begin(self.scrollView.gameObject, Vector3(0, posY, 0), 8)

				function sp.onFinished()
					self.scrollView.enabled = true
				end

				self:setTimeout(function ()
					if not self then
						return
					end

					self.isBattleWin_ = 0

					if item2 then
						item2:update()
					end

					item1:update()
				end, self, 200)
			end)
		end
	end, self, 200)
end

function TowerWindow:getMinY()
	return self.scrollPanel.height / 2 - 181 - 8
end

TowerWindow.ITEM_HEIGHT = 362
TowerWindow.MAX_TICKET = 10

function TowerItem:ctor(parentGo)
	TowerItem.super.ctor(self, parentGo)

	self.heroModel_ = nil
	self.effectCloseDoor = nil
end

function TowerItem:getPrefabPath()
	return "Prefabs/Components/tower_item"
end

function TowerItem:initUI()
	TowerItem.super.initUI(self)

	local content = self.go:NodeByName("content").gameObject
	self.imgBg1 = content:ComponentByName("imgBg1", typeof(UISprite))
	self.imgBg1Texture = content:ComponentByName("imgBg1Texture", typeof(UITexture))
	self.imgBg2 = content:ComponentByName("imgBg2", typeof(UISprite))
	self.imgBg2Texture = content:ComponentByName("imgBg2Texture", typeof(UITexture))
	self.imgBg3 = content:ComponentByName("imgBg3", typeof(UISprite))
	self.imgBg3Texture = content:ComponentByName("imgBg3Texture", typeof(UITexture))
	self.door = content:NodeByName("door").gameObject
	self.imgDoor = self.door:ComponentByName("imgDoor", typeof(UISprite))
	self.imgBlock = self.door:ComponentByName("imgBlock", typeof(UISprite))
	self.groupDoor = self.door:NodeByName("groupDoor").gameObject
	self.groupModel = content:NodeByName("groupModel").gameObject
	self.touchLayer = content:NodeByName("touchLayer").gameObject
	self.groupBox = content:NodeByName("groupBox").gameObject
	self.groupMist = content:NodeByName("groupMist").gameObject
	self.towerBox_close = self.groupBox:NodeByName("towerBox_close").gameObject
	self.towerBox_open = self.groupBox:NodeByName("towerBox_open").gameObject
	self.boardGroup = self.door:NodeByName("boardGroup").gameObject
	self.awardsNode = content:NodeByName("awardsNode").gameObject
	self.awardsContainer = self.awardsNode:NodeByName("awardsContainer").gameObject
	self.label = self.boardGroup:ComponentByName("label", typeof(UILabel))
	self.awardsWords = self.awardsNode:ComponentByName("awardsWords", typeof(UILabel))
	self.towerBox_open_uiSprite = self.groupBox:ComponentByName("towerBox_open", typeof(UISprite))

	xyd.setUISpriteAsync(self.towerBox_open_uiSprite, nil, "towerBox_open")

	self.towerBox_close_uiSprite = self.groupBox:ComponentByName("towerBox_close", typeof(UISprite))

	xyd.setUISpriteAsync(self.towerBox_close_uiSprite, nil, "towerBox_close")

	self.boardGroup_image = self.door:ComponentByName("boardGroup/e:Image", typeof(UISprite))

	xyd.setUISpriteAsync(self.boardGroup_image, nil, "tower_icon04")
	xyd.setUISpriteAsync(self.imgBlock, nil, "tower_icon02")
	xyd.setUISpriteAsync(self.imgDoor, nil, "tower_icon03")
	xyd.setUISpriteAsync(self.imgBg1, nil, "tower_smallbg00")
	xyd.setUISpriteAsync(self.imgBg2, nil, "tower_smallbg01")
	xyd.setUISpriteAsync(self.imgBg3, nil, "tower_smallbg00")
	self:setChildren()
end

function TowerItem:setChildren()
	UIEventListener.Get(self.go).onClick = function ()
		if xyd.tables.miscTable:getNumber("tower_top", "value") < self.data then
			return
		end

		if self.data ~= xyd.models.towerMap.stage then
			return
		end

		xyd.WindowManager.get():openWindow("tower_campaign_detail_window", {
			id = self.data,
			type = xyd.BattleType.TOWER
		})
	end

	UIEventListener.Get(self.towerBox_close).onClick = function ()
		if xyd.tables.miscTable:getNumber("tower_top", "value") < self.data then
			return
		end

		local rewards = xyd.tables.towerTable:getReward(self.data)

		xyd.WindowManager.get():openWindow("activity_award_preview_window", {
			awards = rewards
		})
	end
end

function TowerItem:getCurStage()
	local wnd = xyd.WindowManager.get():getWindow("tower_window")
	local stage = xyd.models.towerMap.stage

	if wnd and wnd:isNeedShowWin() then
		stage = stage - 1
	end

	return stage
end

function TowerItem:setCurrentState(state)
	for i = 1, 3 do
		self["imgBg" .. i]:SetActive(false)
		self["imgBg" .. i .. "Texture"]:SetActive(false)
	end

	self["imgBg" .. state]:SetActive(true)
	self["imgBg" .. state .. "Texture"]:SetActive(true)

	if state == 1 then
		self.door.transform.localPosition = Vector3(-94, 31, 0)
	elseif state == 3 then
		self.door.transform.localPosition = Vector3(-16, 31, 0)
	else
		self.door.transform.localPosition = Vector3(-26, 31, 0)
	end

	xyd.setUITextureAsync(self["imgBg" .. state .. "Texture"], "Textures/scenes_web/tower_bg0" .. state - 1)
end

function TowerItem:dataChanged()
	if self.data % 5 == 0 then
		self:setCurrentState(3)
	elseif self.data % 2 == 0 then
		self:setCurrentState(2)
	else
		self:setCurrentState(1)
	end

	self.label.text = self.data

	self:update()
end

function TowerItem:update()
	local curStage = self:getCurStage()

	if self.data == curStage then
		self.imgBlock:SetActive(false)
		self.imgDoor:SetActive(true)
	elseif self.data < curStage then
		self.imgBlock:SetActive(true)
		self.imgDoor:SetActive(false)
	else
		self.imgBlock:SetActive(false)
		self.imgDoor:SetActive(false)
	end

	self.groupBox:SetActive(false)
	self:updateAwards()

	local battleID = xyd.tables.towerTable:getBattleID(self.data)
	local monsters = xyd.tables.battleTable:getMonsters(battleID)
	local tableID = monsters[1]

	if curStage <= self.data and self.data <= curStage + 9 then
		self.groupModel:SetActive(true)

		local heroTableID = xyd.tables.monsterTable:getPartnerLink(monsters[1])
		local modelID = xyd.tables.partnerTable:getModelID(heroTableID)
		local name = xyd.tables.modelTable:getModelName(modelID)

		if xyd.tables.monsterTable:getSkin(tableID) and xyd.tables.monsterTable:getSkin(tableID) ~= 0 then
			heroTableID = xyd.tables.monsterTable:getSkin(tableID)
			modelID = xyd.tables.equipTable:getSkinModel(heroTableID)
			name = xyd.tables.modelTable:getModelName(modelID)
		end

		if not self.heroModel_ or self.heroModel_:getName() ~= name then
			if self.heroModel_ then
				self.heroModel_:destroy()

				self.heroModel_ = nil
			end

			local widget = self.groupModel:GetComponent(typeof(UIWidget))
			widget.alpha = 1
			local scale = xyd.tables.modelTable:getScale(modelID)
			local node = xyd.Spine.new(self.groupModel)

			node:setInfo(name, function ()
				node:SetLocalScale(-scale, scale, scale)
				node:SetLocalPosition(0, 0, -self.data)
				node:setRenderTarget(self.groupModel:GetComponent(typeof(UIWidget)), 1)
				node:play("idle", 0)
			end)

			self.heroModel_ = node
		end
	else
		self.groupModel:SetActive(false)
	end

	if self.data == curStage then
		if self.effectDoor and self.effectDoor:isValid() then
			self.effectDoor:SetActive(true)
			self.effectDoor:play("texiao1", 0)
		elseif not self.effectDoor then
			self.effectDoor = xyd.Spine.new(self.groupDoor)

			self.effectDoor:setInfo("fx_mentexiao", function ()
				self.effectDoor:SetLocalScale(1, 1, 1)

				if self.data ~= curStage then
					self.effectDoor:SetActive(false)

					return
				end

				self.effectDoor:play("texiao1", 0)
			end)
		end
	elseif self.effectDoor and self.effectDoor:isValid() then
		self.effectDoor:stop()
		self.effectDoor:SetActive(false)
	end

	if self.data > curStage + 9 then
		if self.effectMist and self.effectMist:isValid() then
			self.effectMist:SetActive(true)
			self.effectMist:play("texiao1", 0)
		elseif not self.effectMist then
			self.effectMist = xyd.Spine.new(self.groupMist)

			self.effectMist:setInfo("fx_changjingyanwu", function ()
				if self.data <= curStage + 9 then
					self.effectMist:SetActive(false)

					return
				end

				self.effectMist:play("texiao1", 0)
			end)
		end
	elseif self.effectMist and self.effectMist:isValid() then
		self.effectMist:stop()
		self.effectMist:SetActive(false)
	end

	if self.effectCloseDoor then
		self.effectCloseDoor:destroy()

		self.effectCloseDoor = nil
	end
end

function TowerItem:updateAwards()
	local curStage = self:getCurStage()
	self.awardsWords.text = ""

	self.awardsNode:SetActive(false)

	if self.data > curStage + 9 then
		return
	end

	if self.data % 5 ~= 0 or self.data < curStage then
		return
	end

	NGUITools.DestroyChildren(self.awardsContainer.transform)
	self.awardsNode:SetActive(true)

	self.awardsWords.text = __("TOWER_SHOW_TEXT02")
	local rewards = xyd.tables.towerTable:getReward(self.data)

	for i = 1, #rewards do
		local data = rewards[i]
		local item = {
			show_has_num = true,
			isShowSelected = false,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY,
			uiRoot = self.awardsContainer
		}
		local icon = xyd.getItemIcon(item)

		icon:setScale(64 / xyd.DEFAULT_ITEM_SIZE)
		icon.go:X((i - 2) * 70)
	end
end

function TowerItem:playCompleteAction(callback)
	self.heroModel_:play("dead", 1, 1, function ()
		local action = self:getSequence()
		local w = self.groupModel:GetComponent(typeof(UIWidget))
		local getter, setter = xyd.getTweenAlphaGeterSeter(w)

		action:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.5))
		action:AppendCallback(function ()
			action:Kill(false)

			action = nil

			if self.heroModel_ then
				self.heroModel_:destroy()

				self.heroModel_ = nil
			end

			if callback then
				callback()
			end
		end)
	end)
	self.imgDoor:SetActive(false)

	if self.effectDoor then
		self.effectDoor:SetActive(false)
	end

	self.effectCloseDoor = xyd.Spine.new(self.groupDoor)

	self.effectCloseDoor:setInfo("fx_fengban", function ()
		self.effectCloseDoor:SetLocalScale(1, 1, 1)
		self.effectCloseDoor:SetLocalPosition(0, 40, 0)
		self.effectCloseDoor:play("texiao_01", 1)
	end)
end

return TowerWindow
