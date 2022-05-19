local BaseShop = import(".BaseShop")
local GameAssistantMarketWindow = class("GameAssistantMarketWindow", BaseShop)
local MAXSLOT = 8
local CountDown = import("app.components.CountDown")
local backpackModel = xyd.models.backpack
local GameAssistantMarketItem = class("GameAssistantMarketItem")
local Destroy = UnityEngine.Object.Destroy
local AdvanceIcon = import("app.components.AdvanceIcon")

function GameAssistantMarketWindow:ctor(name, params)
	GameAssistantMarketWindow.super.ctor(self, name, params)

	self.isFree_ = false
	self.page_ = 1
	self.pageNum_ = 0
	self.itemList_ = {}
end

function GameAssistantMarketWindow:initWindow()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.content = self.groupAction:NodeByName("content").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.leftArr = self.content:NodeByName("leftArr").gameObject
	self.rightArr = self.content:NodeByName("rightArr").gameObject
	self.uiparent = self.content:NodeByName("gridOfItem").gameObject
	self.btnSure = self.groupAction:NodeByName("btnSure").gameObject
	self.btnReset = self.groupAction:NodeByName("btnReset").gameObject
	self.btnClose = self.groupAction:NodeByName("btnClose").gameObject
	self.ResGroup1 = self.groupAction:NodeByName("ResGroup1").gameObject
	self.labelRes1 = self.ResGroup1:ComponentByName("label", typeof(UILabel))
	self.ResGroup2 = self.groupAction:NodeByName("ResGroup2").gameObject
	self.labelRes2 = self.ResGroup2:ComponentByName("label", typeof(UILabel))

	self:registerEvent()
	GameAssistantMarketWindow.super.initWindow(self)
end

function GameAssistantMarketWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, handler(self, self.layOutUI))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_SHOP, handler(self, self.refreshItemList))

	UIEventListener.Get(self.btnClose.gameObject).onClick = function ()
		xyd.closeWindow(self.name_)
	end

	UIEventListener.Get(self.leftArr.gameObject).onClick = function ()
		self:goNextPage(-1)
	end

	UIEventListener.Get(self.rightArr.gameObject).onClick = function ()
		self:goNextPage(1)
	end

	UIEventListener.Get(self.btnSure.gameObject).onClick = function ()
		xyd.closeWindow(self.name_)
	end

	UIEventListener.Get(self.btnReset.gameObject).onClick = function ()
		xyd.models.gameAssistant.presetData.market = {}

		self:updateResGroup()
		self:refreshItemList(self.page_)
	end
end

function GameAssistantMarketWindow:layOutUI()
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)
	local timestamp = xyd.tables.miscTable:getNumber("starry_altar_open_time", "value")

	if xyd.getServerTime() < tonumber(timestamp) then
		local items = self.shopInfo_.items

		for i = 1, #items do
			if tonumber(items[i].item[1]) == 358 then
				self.donnotShowIndex = i
			end
		end
	else
		self.donnotShowIndex = nil
	end

	self.pageNum_ = math.ceil(#self.shopInfo_.items / MAXSLOT)

	if self.donnotShowIndex then
		self.pageNum_ = math.ceil((#self.shopInfo_.items - 1) / MAXSLOT)
	end

	self.pageNum_ = math.ceil(#self.shopInfo_.items / MAXSLOT)
	self.btnSure:ComponentByName("label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT32")
	self.btnReset:ComponentByName("label", typeof(UILabel)).text = __("GAME_ASSISTANT_TEXT31")
	self.labelTitle.text = __("GAME_ASSISTANT_TEXT29")

	self:initTimePart()
	self:initDotState()
	self:setArrowState()
	self:arrowMove()
	self:initItemsOnpage(1)
	self:updateResGroup()
end

function GameAssistantMarketWindow:startCountDown(leftTime)
	local reFreshTimeLabel = nil

	if self.shopType_ == xyd.ShopType.SHOP_BLACK_NEW then
		reFreshTimeLabel = self.window_.transform:ComponentByName("groupAction/timeRefresh/labelRefreshTime", typeof(UILabel))
	end

	local params = {
		callback = function ()
			self.shopModel_:refreshShop(self.shopType_)
		end,
		duration = leftTime
	}

	if not self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_ = CountDown.new(reFreshTimeLabel, params)
	else
		self.tlabelRefreshTime_:setInfo(params)
	end

	reFreshTimeLabel.gameObject:SetActive(true)
	self:initAlarmAni()
end

function GameAssistantMarketWindow:initTimePart()
	local winTrans = self.window_.transform
	local refreshTimer = winTrans:ComponentByName("groupAction/timeRefresh", typeof(UIWidget))

	if self.shopType_ == xyd.ShopType.SHOP_BLACK_NEW then
		refreshTimer.gameObject:SetActive(true)

		local labelNowFree = refreshTimer.transform:ComponentByName("labelNowFree", typeof(UILabel))
		local labelFreeTime = refreshTimer.transform:ComponentByName("labelFreeTime", typeof(UILabel))
		local reFreshTimeLabel = refreshTimer.transform:ComponentByName("labelRefreshTime", typeof(UILabel))
		labelNowFree.text = __("FREE_NOW")
		labelFreeTime.text = __("AFTER_FREE")
		local serverTime = xyd.getServerTime()
		local leftTime = 86400 - serverTime % 86400

		if leftTime <= 0 then
			labelNowFree.gameObject:SetActive(true)
			labelFreeTime.gameObject:SetActive(false)
			reFreshTimeLabel.gameObject:SetActive(false)

			if self.marketEffect1_ then
				self.marketEffect1_.gameObject:SetActive(false)
			end

			self.isFree_ = true
		else
			self.isFree_ = false

			labelNowFree.gameObject:SetActive(false)
			labelFreeTime.gameObject:SetActive(true)
			reFreshTimeLabel.gameObject:SetActive(true)
			self:startCountDown(leftTime)
		end
	end
end

function GameAssistantMarketWindow:initItemsOnpage(pageNum)
	local winTran = self.window_.transform
	local items = self.shopInfo_.items
	local itemPrefab = self.content:NodeByName("tempItem").gameObject

	self.uiparent.gameObject:SetActive(false)
	itemPrefab:SetActive(false)

	local tempItem = self.uiparent

	tempItem:SetActive(true)

	local tempGrid = tempItem.transform:ComponentByName("grid", typeof(UIGrid))

	for idx = 1, MAXSLOT do
		local realIndex = MAXSLOT * (pageNum - 1) + idx

		if self.donnotShowIndex and self.donnotShowIndex <= realIndex then
			realIndex = realIndex + 1
		end

		if not self.itemList_[idx] then
			local itemTemp = NGUITools.AddChild(tempGrid.gameObject, itemPrefab)

			itemTemp:SetActive(true)

			itemTemp.name = "itemTemp_" .. idx
			local GameAssistantMarketItem = GameAssistantMarketItem.new(itemTemp, self)

			if items[realIndex] then
				GameAssistantMarketItem:setInfo(items[realIndex], realIndex)

				GameAssistantMarketItem.name = "item" .. realIndex

				GameAssistantMarketItem:showItem(true)
			else
				GameAssistantMarketItem:showItem(false)
			end

			table.insert(self.itemList_, GameAssistantMarketItem)
		end
	end

	tempGrid:Reposition()
end

function GameAssistantMarketWindow:arrowMove()
	local positionLeft = self.leftArr.transform.localPosition.x
	local positionRight = self.rightArr.transform.localPosition.x
	local positionY = self.leftArr.transform.localPosition.y

	function self.playAni2_()
		self.sequence2_ = DG.Tweening.DOTween.Sequence()

		self.sequence2_:Insert(0, self.leftArr.transform:DOLocalMove(Vector3(positionLeft - 5, positionY, 0), 1, false))
		self.sequence2_:Insert(1, self.leftArr.transform:DOLocalMove(Vector3(positionLeft + 5, positionY, 0), 1, false))
		self.sequence2_:Insert(0, self.rightArr.transform:DOLocalMove(Vector3(positionRight + 5, positionY, 0), 1, false))
		self.sequence2_:Insert(1, self.rightArr.transform:DOLocalMove(Vector3(positionRight - 5, positionY, 0), 1, false))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = DG.Tweening.DOTween.Sequence()

		self.sequence1_:Insert(0, self.leftArr.transform:DOLocalMove(Vector3(positionLeft - 5, positionY, 0), 1, false))
		self.sequence1_:Insert(1, self.leftArr.transform:DOLocalMove(Vector3(positionLeft + 5, positionY, 0), 1, false))
		self.sequence1_:Insert(0, self.rightArr.transform:DOLocalMove(Vector3(positionRight + 5, positionY, 0), 1, false))
		self.sequence1_:Insert(1, self.rightArr.transform:DOLocalMove(Vector3(positionRight - 5, positionY, 0), 1, false))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function GameAssistantMarketWindow:initAlarmAni()
	local alarmPos = self.window_.transform:ComponentByName("groupAction/timeRefresh/alarmIcon", typeof(UIWidget))
	self.shizhongEffect_ = xyd.Spine.new(alarmPos.gameObject)

	self.shizhongEffect_:setInfo("fx_ui_shizhong", function ()
		self.shizhongEffect_:play("texiao1", -1, 1)
	end)
end

function GameAssistantMarketWindow:setArrowState()
	self.leftArr:SetActive(self.page_ ~= 1)
	self.rightArr:SetActive(self.page_ ~= self.pageNum_)
end

function GameAssistantMarketWindow:refreshItemList(pageNum)
	for idx = 1, MAXSLOT do
		local realIndex = ((pageNum or self.page_) - 1) * MAXSLOT + idx
		local itemInfo = self.shopInfo_.items[realIndex]
		local GameAssistantMarketItem = self.itemList_[idx]

		if not itemInfo and GameAssistantMarketItem then
			GameAssistantMarketItem:showItem(false)
		elseif GameAssistantMarketItem then
			GameAssistantMarketItem:showItem(true)
			GameAssistantMarketItem:setInfo(itemInfo, realIndex)
		end
	end
end

function GameAssistantMarketWindow:goNextPage(changePageNum)
	if changePageNum + self.page_ <= 0 or self.pageNum_ < self.page_ + changePageNum then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)

	self.page_ = self.page_ + changePageNum

	if self.page_ <= 0 then
		self.page_ = self.pageNum_
	elseif self.pageNum_ < self.page_ then
		self.page_ = 1
	end

	self:setArrowState()
	self:setPageIcon()
	self:refreshItemList(self.page_)
end

function GameAssistantMarketWindow:initDotState()
	self.dotIconList_ = {}
	local dotListTrans = self.window_.transform:Find("groupAction/content/dotIcon").transform

	for i = 0, dotListTrans.childCount - 1 do
		local dotItem = dotListTrans:GetChild(i)
		local dotIcon = dotItem.transform:GetComponent(typeof(UISprite))

		UIEventListener.Get(dotIcon.gameObject).onClick = function ()
			if self.page_ ~= i + 1 then
				self.page_ = i + 1

				if self.page_ <= 0 then
					self.page_ = self.pageNum_
				elseif self.pageNum_ < self.page_ then
					self.page_ = 1
				end

				self:setArrowState()
				self:setPageIcon()
				self:refreshItemList(self.page_)
			end
		end

		table.insert(self.dotIconList_, dotIcon)
	end

	self:setArrowState()
	self:setPageIcon()
end

function GameAssistantMarketWindow:setPageIcon()
	for idx, dotIcon in ipairs(self.dotIconList_) do
		if idx ~= self.page_ then
			xyd.setUISpriteAsync(dotIcon, nil, "market_dot_bg1", nil, )
		else
			xyd.setUISpriteAsync(dotIcon, nil, "market_dot_bg2", nil, )
		end

		dotIcon.width = 20
		dotIcon.height = 20
	end
end

function GameAssistantMarketWindow:updateResGroup()
	local resCost1 = 0
	local resCost2 = 0

	for realIndex, value in pairs(xyd.models.gameAssistant.presetData.market) do
		realIndex = tonumber(realIndex)
		value = tonumber(value)

		if type(value) == "number" and value > 0 then
			local info = self.shopInfo_.items[realIndex]

			if info.cost[1] == 1 then
				resCost1 = resCost1 + info.cost[2]
			elseif info.cost[1] == 2 then
				resCost2 = resCost2 + info.cost[2]
			end
		end
	end

	self.labelRes1.text = xyd.getRoughDisplayNumber(resCost1)
	self.labelRes2.text = xyd.getRoughDisplayNumber(resCost2)
end

function GameAssistantMarketWindow:willClose()
	GameAssistantMarketWindow.super.willClose(self)

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	if self.tlabelRefreshTime_ then
		self.tlabelRefreshTime_:stopTimeCount()

		self.tlabelRefreshTime_ = nil
	end

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end

	local wnd = xyd.getWindow("game_assistant_window")

	if wnd then
		wnd:updateMarketPart()
	end
end

function GameAssistantMarketItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.costIcon = self.go:ComponentByName("costIcon", typeof(UISprite))
	self.labelCost = self.go:ComponentByName("labelCost", typeof(UILabel))
	self.itemPos = self.go:NodeByName("itemPos").gameObject
	self.itemMask = self.itemPos:ComponentByName("mask", typeof(UISprite))
	self.chooseBtn = self.go:NodeByName("chooseBtn").gameObject
	self.chooseBtn_bg = self.go:ComponentByName("chooseBtn", typeof(UISprite))
	self.btnMask = self.chooseBtn:ComponentByName("mask", typeof(UISprite))
	self.labelHasBuy = self.chooseBtn:ComponentByName("labelHasBuy", typeof(UILabel))
	self.labelHasChoose = self.chooseBtn:ComponentByName("labelHasChoose", typeof(UILabel))
	self.labelChoose = self.chooseBtn:ComponentByName("labelChoose", typeof(UILabel))
end

function GameAssistantMarketItem:setInfo(params, index)
	self.item = params.item
	self.cost = params.cost
	self.buy_times = params.buy_times or 0
	self.index = index
	local itemType = xyd.tables.itemTable:getType(self.item[1])
	local itemParams = {
		show_has_num = true,
		showSellLable = false,
		scale = 0.7870370370370371,
		num = self.item[2],
		itemID = self.item[1],
		uiRoot = self.itemPos
	}

	if tonumber(self.item[1]) == 100 then
		self.go:SetActive(false)
	else
		self.go:SetActive(true)
	end

	if not self.icon then
		self.icon = AdvanceIcon.new(itemParams)
	else
		self.icon:setInfo(itemParams)
	end

	local iconName = xyd.tables.itemTable:getIcon(self.cost[1])

	xyd.setUISpriteAsync(self.costIcon, nil, iconName, nil, )

	self.labelHasBuy.text = __("ALREADY_BUY")
	self.labelHasChoose.text = __("GAME_ASSISTANT_TEXT68")
	self.labelChoose.text = __("GAME_ASSISTANT_TEXT92")
	self.labelCost.text = tostring(xyd.getRoughDisplayNumber(self.cost[2]))
	local left_times = 1

	if xyd.models.activity:isResidentReturnAddTime() then
		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WELFARE_SOCIETY)
		left_times = left_times * return_multiple
	end

	if xyd.models.gameAssistant.presetData.market[self.index] and type(xyd.models.gameAssistant.presetData.market[self.index]) == "number" and xyd.models.gameAssistant.presetData.market[self.index] > 0 then
		self.itemMask.gameObject:SetActive(false)
		self.btnMask.gameObject:SetActive(false)
		self.labelHasBuy.gameObject:SetActive(false)
		self.labelHasChoose.gameObject:SetActive(true)
		self.labelChoose.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.chooseBtn_bg, nil, "white_btn_54_54")
	else
		self.itemMask.gameObject:SetActive(false)
		self.btnMask.gameObject:SetActive(false)
		self.labelHasBuy.gameObject:SetActive(false)
		self.labelHasChoose.gameObject:SetActive(false)
		self.labelChoose.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.chooseBtn_bg, nil, "blue_btn_54_54")
	end

	UIEventListener.Get(self.chooseBtn.gameObject).onClick = handler(self, self.onClickBtnChoose)
end

function GameAssistantMarketItem:onClickIcon()
	xyd.WindowManager.get():openWindow("item_tips_window", {
		itemID = self.item_[1]
	})
end

function GameAssistantMarketItem:onClickBtnChoose()
	local hasNum = backpackModel:getItemNumByID(self.cost[1])

	if xyd.models.gameAssistant.presetData.market[self.index] and type(xyd.models.gameAssistant.presetData.market[self.index]) ~= "number" then
		xyd.models.gameAssistant.presetData.market[self.index] = 0
	end

	if xyd.models.gameAssistant.presetData.market[self.index] and tonumber(xyd.models.gameAssistant.presetData.market[self.index]) > 0 then
		xyd.models.gameAssistant.presetData.market[self.index] = 0

		self.itemMask.gameObject:SetActive(false)
		self.btnMask.gameObject:SetActive(false)
		self.labelHasBuy.gameObject:SetActive(false)
		self.labelHasChoose.gameObject:SetActive(false)
		self.labelChoose.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.chooseBtn_bg, nil, "blue_btn_54_54")
	elseif self.cost[2] <= hasNum then
		xyd.models.gameAssistant.presetData.market[self.index] = 1

		self.itemMask.gameObject:SetActive(false)
		self.btnMask.gameObject:SetActive(false)
		self.labelHasBuy.gameObject:SetActive(false)
		self.labelHasChoose.gameObject:SetActive(true)
		self.labelChoose.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.chooseBtn_bg, nil, "white_btn_54_54")
	else
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost[1])))
	end

	self.parent:updateResGroup()
end

function GameAssistantMarketItem:showItem(canShow)
	self.go:SetActive(canShow)
end

return GameAssistantMarketWindow
