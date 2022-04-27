local BaseShop = import(".BaseShop")
local MarketWindow = class("MarketWindow", BaseShop)
local MAXSLOT = 8
local CountDown = import("app.components.CountDown")
local backpackModel = xyd.models.backpack
local MarketItem = class("MarketItem")
local WindowTop = import("app.components.WindowTop")
local Destroy = UnityEngine.Object.Destroy
local OldSize = {
	w = 720,
	h = 1280
}

function MarketItem:ctor(go, parent)
	self.go_ = go
	self.parent_ = parent
	self.btnIcon_ = self.go_.transform:ComponentByName("buyBtn/costIcon", typeof(UISprite))
	self.uiBtn_ = self.go_.transform:ComponentByName("buyBtn", typeof(UISprite))
	self.icon_ = self.go_.transform:Find("item").gameObject
	self.itemMask_ = self.go_.transform:ComponentByName("item/mask", typeof(UISprite))
	self.btnMask_ = self.go_.transform:ComponentByName("buyBtn/mask", typeof(UISprite))
	self.labelHasBuy_ = self.go_.transform:ComponentByName("buyBtn/labelHasBuy", typeof(UILabel))
	self.buyLabel_ = self.go_.transform:ComponentByName("buyBtn/iconLabel", typeof(UILabel))

	if xyd.isIosTest() then
		local itembg = self.go_:ComponentByName("itembg", typeof(UISprite))

		itembg:SetActive(true)
		xyd.setUISprite(itembg, nil, "shop_icon_bg_ios_test")
	end
end

function MarketItem:setInfo(params, index)
	self.item_ = params.item
	self.cost_ = params.cost
	self.buyTimes_ = params.buy_times or 0
	self.index_ = index
	local noClick = false

	if not xyd.GuideController.get():isGuideComplete() then
		noClick = true
	end

	local itemType = xyd.tables.itemTable:getType(self.item_[1])
	local itemParams = {
		show_has_num = true,
		showSellLable = false,
		num = self.item_[2],
		itemID = self.item_[1],
		noClick = noClick,
		uiRoot = self.icon_,
		dragCallback = {
			startCallback = function ()
				self.parent_.hasMove_ = false
				self.parent_.delta_ = 0
			end,
			endCallback = function ()
				self.parent_.hasMove_ = false
				self.parent_.delta_ = 0
			end,
			dragCallback = function (go, delta)
				self.parent_:onDrag(go, delta)
			end
		}
	}

	if tonumber(self.item_[1]) == 100 then
		self.go_:SetActive(false)
	else
		self.go_:SetActive(true)
	end

	if self.itemIcon_ and self.itemType_ == itemType then
		self.itemIcon_:setInfo(itemParams)
	elseif self.itemIcon_ and self.itemType_ ~= itemType then
		NGUITools.Destroy(self.itemIcon_:getGameObject())

		self.itemIcon_ = xyd.getItemIcon(itemParams)
	else
		self.itemIcon_ = xyd.getItemIcon(itemParams)
	end

	self.itemType_ = itemType
	UIEventListener.Get(self.icon_.gameObject).onClick = handler(self, self.onClickIcon)
	local costIcon = xyd.tables.itemTable:getIcon(self.cost_[1])

	xyd.setUISpriteAsync(self.btnIcon_, nil, costIcon, nil, )

	self.labelHasBuy_.text = __("ALREADY_BUY")
	self.buyLabel_.text = tostring(xyd.getRoughDisplayNumber(self.cost_[2]))
	local left_times = 1

	if xyd.models.activity:isResidentReturnAddTime() then
		local return_multiple = xyd.tables.activityReturn2AddTable:getMultiple(xyd.ActivityResidentReturnAddType.WELFARE_SOCIETY)
		left_times = left_times * return_multiple
	end

	if left_times <= self.buyTimes_ then
		self.btnIcon_.gameObject:SetActive(false)
		self.itemMask_.gameObject:SetActive(true)
		self.btnMask_.gameObject:SetActive(true)
		self.labelHasBuy_.gameObject:SetActive(true)
		self.buyLabel_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.uiBtn_, nil, "white_btn_54_54")
	else
		self.btnIcon_.gameObject:SetActive(true)
		self.itemMask_.gameObject:SetActive(false)
		self.btnMask_.gameObject:SetActive(false)
		self.labelHasBuy_.gameObject:SetActive(false)
		self.buyLabel_.gameObject:SetActive(true)

		if xyd.isIosTest() then
			xyd.setUISpriteAsync(self.uiBtn_, nil, "blue_btn_54_54_ios_test")
		else
			xyd.setUISpriteAsync(self.uiBtn_, nil, "blue_btn_54_54")
		end
	end

	UIEventListener.Get(self.uiBtn_.gameObject).onClick = handler(self, self.onClickBtnBuy)
end

function MarketItem:onClickIcon()
	xyd.WindowManager.get():openWindow("item_tips_window", {
		itemID = self.item_[1]
	})
end

function MarketItem:onClickBtnBuy()
	local hasNum = backpackModel:getItemNumByID(self.cost_[1])

	if self.cost_[2] <= hasNum then
		if xyd.GuideController.get():isPlayGuide() then
			local params = {
				message = __("CONFIRM_BUY"),
				alertType = xyd.AlertType.YES_NO,
				callback = function (confirmBuy)
					if confirmBuy then
						self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
					end
				end
			}

			xyd.WindowManager.get():openWindow("alert_window", params)
		elseif self.cost_[1] == xyd.ItemID.CRYSTAL then
			local timeStamp = xyd.db.misc:getValue("market_crystal_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.openWindow("gamble_tips_window", {
					type = "market_crystal",
					text = __("DAILY_QUIZ_BUY_TIPS_2", self.cost_[2]),
					callback = function ()
						self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
					end
				})
			else
				self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
			end
		else
			local timeStamp = xyd.db.misc:getValue("market_mana_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.openWindow("gamble_tips_window", {
					type = "market_mana",
					text = __("CONFIRM_BUY"),
					callback = function ()
						self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
					end
				})
			else
				self.parent_.shopModel_:buyShopItem(self.parent_.shopType_, self.index_)
			end
		end
	else
		local params = {
			alertType = xyd.AlertType.TIPS,
			message = __("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost_[1]))
		}

		xyd.WindowManager.get():openWindow("alert_window", params)
	end
end

function MarketItem:showItem(canShow)
	self.go_:SetActive(canShow)
end

function MarketWindow:ctor(name, params)
	MarketWindow.super.ctor(self, name, params)

	self.needCrystal_ = 20
	self.isFree_ = false
	self.pageIcons_ = {}
	self.page_ = 1
	self.pageNum_ = 0
	self.startX_ = 0
	self.itemList_ = {}
end

function MarketWindow:initWindow()
	local winTrans = self.window_.transform
	local marketBg = winTrans:ComponentByName("transPos/content", typeof(UITexture))
	local windowBg = winTrans:ComponentByName("bg", typeof(UITexture))
	self.windowBg = windowBg
	self.dragContentBg_ = winTrans:ComponentByName("scroll_drag", typeof(UIWidget)).gameObject

	xyd.setUITextureAsync(marketBg, "Textures/shop_web/market_bg")
	xyd.setUITextureAsync(windowBg, "Textures/scenes_web/market_scene")

	local contentTrans = marketBg.transform
	local leftArrIcon = contentTrans:ComponentByName("leftArr", typeof(UISprite))
	local rightArrIcon = contentTrans:ComponentByName("rightArr", typeof(UISprite))
	self.leftArr_ = contentTrans:Find("leftArr").gameObject
	self.rightArr_ = contentTrans:Find("rightArr").gameObject
	self.uiParent_ = contentTrans:Find("gridOfItem").gameObject
	self.pictureContainer_ = contentTrans:NodeByName("girlPos").gameObject

	self:initTopGroup()

	UIEventListener.Get(leftArrIcon.gameObject).onClick = function ()
		self:goNextPage(-1)
	end

	UIEventListener.Get(rightArrIcon.gameObject).onClick = function ()
		self:goNextPage(1)
	end

	UIEventListener.Get(self.dragContentBg_).onDragStart = function ()
		self.hasMove_ = false
		self.delta_ = 0
	end

	UIEventListener.Get(self.dragContentBg_).onDrag = function (go, delta)
		self:onDrag(go, delta)
	end

	UIEventListener.Get(self.dragContentBg_).onDragEnd = function ()
		self.delta_ = 0
		self.hasMove_ = false
	end

	self:registerEvent()
	MarketWindow.super.initWindow(self)
end

function MarketWindow:onDrag(go, delta)
	self.delta_ = self.delta_ + delta.x

	if self.delta_ > 50 and not self.hasMove_ then
		self.hasMove_ = true

		self:goNextPage(-1, true)
	end

	if self.delta_ < -50 and not self.hasMove_ then
		self.hasMove_ = true

		self:goNextPage(1, true)
	end
end

function MarketWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)

	if xyd.models.activity:isResidentReturnAddTime() then
		self.windowTop:addLeftTop("first_tips", "common_tips_1", 0.5, function ()
			xyd.alert(xyd.AlertType.TIPS, __("ACTIVITY_RETURN2_ADD_TEXT08"))
		end)
	end
end

function MarketWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_SHOP_INFO, handler(self, self.layOutUI))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_SHOP, handler(self, self.refreshItemList))
	self.eventProxy_:addEventListener(xyd.event.BUY_SHOP_ITEM, handler(self, self.buyItemRes))
end

function MarketWindow:layOutUI()
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)
	self.pageNum_ = math.ceil(#self.shopInfo_.items / MAXSLOT)

	self:initTimePart()
	self:initDotState()
	self:setArrowState()
	self:arrowMove()
	self:initItemsOnpage(1)
	self:setGirlsModel()
end

function MarketWindow:startCountDown(leftTime)
	local reFreshTimeLabel = nil

	if self.shopType_ == xyd.ShopType.SHOP_BLACK_NEW then
		reFreshTimeLabel = self.window_.transform:ComponentByName("transPos/content/timeRefresh/labelRefreshTime", typeof(UILabel))
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

function MarketWindow:initTimePart()
	local winTrans = self.window_.transform
	local refreshTimer = winTrans:ComponentByName("transPos/content/timeRefresh", typeof(UIWidget))

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

function MarketWindow:initItemsOnpage(pageNum)
	local winTran = self.window_.transform
	local items = self.shopInfo_.items
	local itemPrefab = winTran:Find("transPos/content/tempItem").gameObject

	self.uiParent_.gameObject:SetActive(false)
	itemPrefab:SetActive(false)

	local tempItem = self.uiParent_

	tempItem:SetActive(true)

	local tempGrid = tempItem.transform:ComponentByName("grid", typeof(UIGrid))

	for idx = 1, MAXSLOT do
		local realIndex = MAXSLOT * (pageNum - 1) + idx

		if not self.itemList_[idx] then
			local itemTemp = NGUITools.AddChild(tempGrid.gameObject, itemPrefab)

			itemTemp:SetActive(true)

			itemTemp.name = "itemTemp_" .. idx
			local marketItem = MarketItem.new(itemTemp, self)

			if items[realIndex] then
				marketItem:setInfo(items[realIndex], realIndex)

				marketItem.name = "item" .. realIndex

				marketItem:showItem(true)
			else
				marketItem:showItem(false)
			end

			table.insert(self.itemList_, marketItem)
		end
	end

	tempGrid:Reposition()
end

function MarketWindow:arrowMove()
	local positionLeft = self.leftArr_.transform.localPosition.x
	local positionRight = self.rightArr_.transform.localPosition.x

	function self.playAni2_()
		self.sequence2_ = DG.Tweening.DOTween.Sequence()

		self.sequence2_:Insert(0, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft - 5, -48, 0), 1, false))
		self.sequence2_:Insert(1, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft + 5, -48, 0), 1, false))
		self.sequence2_:Insert(0, self.rightArr_.transform:DOLocalMove(Vector3(positionRight + 5, -48, 0), 1, false))
		self.sequence2_:Insert(1, self.rightArr_.transform:DOLocalMove(Vector3(positionRight - 5, -48, 0), 1, false))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = DG.Tweening.DOTween.Sequence()

		self.sequence1_:Insert(0, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft - 5, -48, 0), 1, false))
		self.sequence1_:Insert(1, self.leftArr_.transform:DOLocalMove(Vector3(positionLeft + 5, -48, 0), 1, false))
		self.sequence1_:Insert(0, self.rightArr_.transform:DOLocalMove(Vector3(positionRight + 5, -48, 0), 1, false))
		self.sequence1_:Insert(1, self.rightArr_.transform:DOLocalMove(Vector3(positionRight - 5, -48, 0), 1, false))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function MarketWindow:initAlarmAni()
	local alarmPos = self.window_.transform:ComponentByName("transPos/content/timeRefresh/alarmIcon", typeof(UIWidget))
	self.shizhongEffect_ = xyd.Spine.new(alarmPos.gameObject)

	self.shizhongEffect_:setInfo("fx_ui_shizhong", function ()
		self.shizhongEffect_:play("texiao1", -1, 1)
	end)
end

function MarketWindow:buyItemRes(event)
	self.shopInfo_ = self.shopModel_:getShopInfo(self.shopType_)

	self:refreshItemList()

	local params = event.data
	local index = params.index
	local items = params.items
	local buyItem = items[index]
	local itemData = {
		{
			item_id = buyItem.item[1],
			item_num = buyItem.item[2]
		}
	}

	xyd.alertItems(itemData)

	if self.girlsModel and xyd.GuideController.get():isGuideComplete() then
		self.girlsModel:playChooseAction()
	end
end

function MarketWindow:setGirlsModel()
	local id = xyd.tables.shopConfigTable:getGirlsModel(self.shopType_)

	if not self.girlsModel then
		self.girlsModel = import("app.components.GirlsModel").new(self.pictureContainer_)

		self.girlsModel:SetActive(true)

		self.pictureContainer_.transform.localPosition = Vector3(-90, 100, 0)

		self.girlsModel:setModelInfo({
			id = id,
			bg = self.windowBg
		}, function ()
			self.girlsModel:setBubble()
		end)
	end
end

function MarketWindow:setArrowState()
	self.leftArr_:SetActive(self.page_ ~= 1)
	self.rightArr_:SetActive(self.page_ ~= self.pageNum_)
end

function MarketWindow:refreshItemList(pageNum)
	for idx = 1, MAXSLOT do
		local realIndex = ((pageNum or self.page_) - 1) * MAXSLOT + idx
		local itemInfo = self.shopInfo_.items[realIndex]
		local marketItem = self.itemList_[idx]

		if not itemInfo and marketItem then
			marketItem:showItem(false)
		elseif marketItem then
			marketItem:showItem(true)
			marketItem:setInfo(itemInfo, realIndex)
		end
	end
end

function MarketWindow:goNextPage(changePageNum, buyDrag)
	if buyDrag and (changePageNum + self.page_ <= 0 or self.pageNum_ < self.page_ + changePageNum) then
		return
	end

	xyd.SoundManager.get():playSound(xyd.SoundID.SWITCH_PAGE)

	if not xyd.GuideController.get():isGuideComplete() then
		return
	end

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

function MarketWindow:initDotState()
	self.dotIconList_ = {}
	local dotListTrans = self.window_.transform:Find("transPos/content/dotIcon").transform

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

function MarketWindow:setPageIcon()
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

function MarketWindow:willClose()
	MarketWindow.super.willClose(self)

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
end

function MarketWindow:iosTestChangeUI()
	self.girlsModel:SetActive(false)
	xyd.setUITextureAsync(self.windowBg, "Textures/texture_ios/market_scene_ios_test")
	xyd.setUITextureAsync(self.window_:ComponentByName("transPos/content", typeof(UITexture)), "Textures/texture_ios/market_bg_ios_test")
	xyd.setUISprite(self.window_:ComponentByName("transPos/content/timeRefresh/icon", typeof(UISprite)), nil, "shop_icon_3_ios_test")
end

return MarketWindow
