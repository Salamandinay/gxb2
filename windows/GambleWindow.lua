local BaseWindow = import(".BaseWindow")
local GambleWindow = class("GambleWindow", BaseWindow)
local gambleModel = xyd.models.gamble
local GambleConfigTable = xyd.tables.gambleConfigTable
local OldSize = {
	w = 720,
	h = 1280
}
local windowType = {
	NORMAL = 1,
	SENIOR = 2
}
GambleWindow.windowType = windowType

function GambleWindow:ctor(name, params)
	GambleWindow.super.ctor(self, name, params)

	self.curWindowType_ = windowType.NORMAL

	if params then
		self.curWindowType_ = params.type or windowType.NORMAL
		self.lastWindow_ = params.lastWindow
	end

	self.curActionIndex_ = 1
	self.seqList_ = {}
	self.isNeedPlayAction_ = true

	gambleModel:clearGambleByType(windowType.NORMAL)
	gambleModel:clearGambleByType(windowType.SENIOR)

	self.itemsList_ = {}
	self.hasInit_ = false
	local activityId = xyd.ActivityID.WISHING_POOL_GIFTBAG
	self.ifShowBtnGo = xyd.models.activity:getActivity(activityId) ~= nil
	self.sideType = tonumber(xyd.db.misc:getValue("gamble_side_type")) or 1
	self.sideTypeTimes = {
		10,
		20,
		50
	}
	self.sideTypeIndex = {
		2,
		4,
		5
	}
	self.buyTimeText = {
		__("GAMBLE_BUY_TEN"),
		__("GAMBLE_BUY_TWENTY"),
		__("GAMBLE_BUY_FIFTY")
	}
end

function GambleWindow:initWindow()
	GambleWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:Find("content")
	self.panel_ = self.window_:GetComponent(typeof(UIPanel))
	self.Mask_ = winTrans:NodeByName("content/Mask_").gameObject
	self.navNormal_ = self.content_.transform:ComponentByName("navPart/nav1", typeof(UISprite))
	self.navNormalLabel_ = self.content_.transform:ComponentByName("navPart/nav1/lable", typeof(UILabel))
	self.navSenior_ = self.content_.transform:ComponentByName("navPart/nav2", typeof(UISprite))
	self.navSeniorLabel_ = self.content_.transform:ComponentByName("navPart/nav2/lable", typeof(UILabel))
	self.groupBottom_ = self.content_.transform:Find("groupBottom")
	self.modelPanel_ = winTrans:ComponentByName("modelPanel", typeof(UIPanel))
	self.groupModel = winTrans:Find("modelPanel/groupModel").gameObject
	self.groupNormal_ = winTrans:Find("modelPanel/groupModel/normal").gameObject
	self.groupSenior_ = winTrans:Find("modelPanel/groupModel/senior").gameObject
	self.imgBg_ = winTrans:ComponentByName("bgBorder/windowBg", typeof(UISprite))
	self.windowBg_ = winTrans:ComponentByName("windowBgTexture", typeof(UITexture))
	self.imgMidBg_ = self.content_.transform:ComponentByName("groupBottom/midBg", typeof(UISprite))
	self.skipBtn_ = self.content_.transform:NodeByName("groupBottom/btnSkip").gameObject
	self.skipSelectImg_ = self.content_.transform:ComponentByName("groupBottom/btnSkip/selectImg", typeof(UISprite))
	self.skipSelectLabel_ = self.content_.transform:ComponentByName("groupBottom/btnSkip/label", typeof(UILabel))
	self.groupBtns = self.content_.transform:Find("groupBottom/groupBtns")
	self.btnOne_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyOne", typeof(UIButton))
	self.oneIcon_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyOne/costIcon", typeof(UISprite))
	self.oneNum_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyOne/costNum", typeof(UILabel))
	self.oneLabel_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyOne/costDesc", typeof(UILabel))
	self.btnTen_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyTen", typeof(UIButton))
	self.tenIcon_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyTen/costIcon", typeof(UISprite))
	self.tenNum_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyTen/costNum", typeof(UILabel))
	self.tenLabel_ = self.content_.transform:ComponentByName("groupBottom/groupBtns/btnBuyTen/costDesc", typeof(UILabel))
	self.sideBtn = self.content_.transform:NodeByName("groupBottom/sideBtn").gameObject
	self.sideBtnLabel1 = self.sideBtn.transform:ComponentByName("sideBtnLabel1", typeof(UILabel))
	self.sideBtnLabel2 = self.sideBtn.transform:ComponentByName("sideBtnLabel2", typeof(UILabel))
	self.btnGoGroup = self.content_.transform:NodeByName("groupBottom/btnGoGroup").gameObject
	self.btnGo = self.btnGoGroup:NodeByName("btnGo").gameObject
	self.btnGoLabel = self.btnGo:ComponentByName("btnGoLabel", typeof(UILabel))
	self.btnRecords_ = self.content_.transform:ComponentByName("topBtnPart/btnRecord", typeof(UISprite))
	self.btnRecordsLabel_ = self.content_.transform:ComponentByName("topBtnPart/btnRecord/lable", typeof(UILabel))
	self.btnShop_ = self.content_.transform:ComponentByName("topBtnPart/btnShop", typeof(UISprite))
	self.helpBtn = self.content_.transform:ComponentByName("topBtnPart/helpBtn", typeof(UISprite)).gameObject
	self.probBtn = self.content_.transform:ComponentByName("topBtnPart/probBtn", typeof(UISprite)).gameObject
	self.groupMidItems = self.content_.transform:Find("groupBottom/groupMidItems")
	self.labelRefreshDesc_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/labelRefreshDesc", typeof(UILabel))
	self.labelTime_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/labelRefreshTime", typeof(UILabel))
	self.refreshBtn_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/refreshBtn", typeof(UISprite))
	self.refreshBtnCostIcon_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/refreshBtn/costIcon", typeof(UISprite))
	self.refreshBtnLabelNum_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/refreshBtn/costIcon/labelNum", typeof(UILabel))
	self.refreshBtnLabel_ = self.content_.transform:ComponentByName("groupBottom/groupMidItems/refresh/refreshBtn/labelRefresh", typeof(UILabel))
	self.imgMask_ = self.content_.transform:ComponentByName("imgMask", typeof(UISprite))

	self:register()

	if not gambleModel:reqGambleInfo(self.curWindowType_, false, true) then
		self:onGambleInfo()
	end

	self:layout()
	self:initNavState()
	self:initGirlsModel()
end

function GambleWindow:resizeToParent()
	local panelHeight = self.window_:GetComponent(typeof(UIPanel)).height

	if panelHeight < 1300 then
		self.content_:Y(-100)
		self.groupModel:Y(-210)
		self.imgMidBg_:Y(80)
		self.groupMidItems:Y(100)
		self.groupBtns:Y(-185)
	end
end

function GambleWindow:layout()
	self:updateLayout()
	self:initResItem()
end

function GambleWindow:checkShowSideBtn()
	if self.curWindowType_ == xyd.GambleWindowType.SENIOR then
		return false
	end

	local flag = self.ifShowBtnGo
	local needLevs = GambleConfigTable:needLevel(self.curWindowType_)
	local needVips = GambleConfigTable:needVip(self.curWindowType_)
	local selfLev = xyd.models.backpack:getLev()
	local selfVip = xyd.models.backpack:getVipLev()

	if selfVip < needLevs[4] and selfVip < needVips[4] or selfVip < needLevs[5] and selfVip < needVips[5] then
		flag = false
	end

	return flag
end

function GambleWindow:initBtnGo()
	if self.ifShowBtnGo and self.curWindowType_ == windowType.NORMAL then
		self.btnGo:SetActive(true)
		self.sideBtn:SetActive(true)
	else
		self.btnGo:SetActive(false)
		self.sideBtn:SetActive(false)
	end
end

function GambleWindow:updateLayout()
	local cost = GambleConfigTable:getCost(self.curWindowType_)
	local cost1 = xyd.split(cost[1], "#", true)
	local cost10 = xyd.split(cost[2], "#", true)
	self.navNormalLabel_.text = __("NORMAL_SLOT_MACHINE")
	self.navSeniorLabel_.text = __("HIGH_SLOT_MACHINE")

	if self.curWindowType_ == windowType.NORMAL then
		self.groupNormal_:SetActive(true)
		self.groupSenior_:SetActive(false)
		xyd.setUISpriteAsync(self.imgBg_, nil, "gb_normal_bg_2", nil, )
		xyd.setUITextureAsync(self.windowBg_, "Textures/scenes_web/gb_normal_bg", function ()
			self.imgBg_.gameObject:SetActive(false)
		end, false)

		self.btnRecords_.transform.localPosition = Vector3(205, -10, 0)

		xyd.setUISpriteAsync(self.imgMidBg_, nil, "gb_normal_mid_bg", nil, )
		xyd.setUISpriteAsync(self.tenIcon_, nil, "icon_35", nil, )
		xyd.setUISpriteAsync(self.oneIcon_, nil, "icon_35", nil, )
		xyd.setUISpriteAsync(self.btnRecords_, nil, "gb_normal_records", nil, )
		self.btnShop_.gameObject:SetActive(true)
		self.helpBtn.gameObject:SetActive(true)
		self.probBtn.gameObject:SetActive(true)
	else
		self.groupNormal_:SetActive(false)
		self.groupSenior_:SetActive(true)

		self.btnRecords_.transform.localPosition = Vector3(300, -10, 0)

		xyd.setUISpriteAsync(self.imgBg_, nil, "gb_senior_bg_2", nil, )
		xyd.setUITextureAsync(self.windowBg_, "Textures/scenes_web/gb_senior_bg", function ()
			self.imgBg_.gameObject:SetActive(false)
		end, false)
		xyd.setUISpriteAsync(self.imgMidBg_, nil, "gb_senior_mid_bg", nil, )
		xyd.setUISpriteAsync(self.tenIcon_, nil, "icon_29", nil, )
		xyd.setUISpriteAsync(self.oneIcon_, nil, "icon_29", nil, )
		xyd.setUISpriteAsync(self.btnRecords_, nil, "gb_senior_records", nil, )
		self.btnShop_.gameObject:SetActive(false)
		self.helpBtn.gameObject:SetActive(false)
		self.probBtn.gameObject:SetActive(true)
	end

	self.oneNum_.text = tostring(cost1[2])
	self.tenNum_.text = tostring(cost10[2])
	self.oneLabel_.text = __("GAMBLE_BUY_ONE")
	self.tenLabel_.text = __("GAMBLE_BUY_TEN")
	self.labelRefreshDesc_.text = __("GAMBLE_SYSTEM_REFRESH_TIME")
	self.btnRecordsLabel_.text = __("GAMBLE_RECORD_TITLE")
	self.skipSelectLabel_.text = __("SKIP_ANIMATION")
	self.skipBtn_:GetComponent(typeof(UISprite)).width = self.skipSelectLabel_.width + 63
	self.btnGoLabel.text = __("GAMBLE_BUY_POINTS_TEXT01")
	local tmpWidth = self.btnGoLabel.width + 40
	self.btnGo:GetComponent(typeof(UISprite)).width = tmpWidth
	self.btnGoGroup:GetComponent(typeof(UIWidget)).width = tmpWidth
	self.btnGo.transform.localPosition = Vector3(-tmpWidth / 2, 0, 0)
	self.sideBtnLabel2.text = __("GAMBLE_BUY_POINTS_TEXT04")

	if xyd.Global.lang == "zh_tw" then
		self.sideBtnLabel2.transform.localRotation = Vector3(0, 0, 0)
		self.sideBtnLabel2.transform.localPosition = Vector3(-12, -26, 0)
	end

	self:freshSkipBtnState()
	self:initBtnGo()
	self:updateSideLayout()
end

function GambleWindow:initGirlsModel()
	if self.curWindowType_ == windowType.SENIOR then
		if not self.seniorModel_ then
			self.seniorModel_ = import("app.components.GirlsModel").new(self.groupSenior_)

			self.seniorModel_:setModelInfo({
				id = 4,
				bg = self.windowBg_,
				panel = self.modelPanel_
			}, function ()
				self.seniorModel_:setBubble()
			end)
			self.seniorModel_:SetActive(true)
		else
			self.seniorModel_:SetActive(true)
		end

		if self.normalModel_ then
			self.normalModel_:SetActive(false)
		end

		self.girlsModel_ = self.seniorModel_
	else
		if not self.normalModel_ then
			self.normalModel_ = import("app.components.GirlsModel").new(self.groupNormal_)

			self.normalModel_:setModelInfo({
				id = 3,
				bg = self.windowBg_,
				panel = self.modelPanel_
			}, function ()
				self.normalModel_:setBubble()
			end)
			self.normalModel_:SetActive(true)
		else
			self.normalModel_:SetActive(true)
		end

		if self.seniorModel_ then
			self.seniorModel_:SetActive(false)
		end

		self.girlsModel_ = self.normalModel_
	end
end

function GambleWindow:freshSkipBtnState()
	local state = xyd.db.misc:getValue("gamble_skip_" .. self.curWindowType_)

	if state and state == "1" then
		xyd.setUISpriteAsync(self.skipSelectImg_, nil, "setting_up_pick")
	else
		xyd.setUISpriteAsync(self.skipSelectImg_, nil, "setting_up_unpick")
	end

	self.state_ = state
end

function GambleWindow:onClickSkip()
	local state = xyd.db.misc:getValue("gamble_skip_" .. self.curWindowType_)

	if state and state == "1" then
		xyd.db.misc:setValue({
			value = "0",
			key = "gamble_skip_" .. self.curWindowType_
		})
	else
		xyd.db.misc:setValue({
			value = "1",
			key = "gamble_skip_" .. self.curWindowType_
		})
	end

	self:freshSkipBtnState()
end

function GambleWindow:initResItem()
	local cost = GambleConfigTable:getCost(windowType.NORMAL)
	local cost1 = xyd.split(cost[1], "#", true)
	local hidePlus = false

	local function closecallback()
		self:onClickCloseButton()
	end

	local function callback()
		xyd.WindowManager.get():openWindow("item_purchase_window", {
			exchange_id = 1
		})
	end

	self.windowTop1_ = import("app.components.WindowTop").new(self.window_, self.name_, nil, true, closecallback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = cost1[1],
			hidePlus = hidePlus,
			callback = callback
		}
	}

	self.windowTop1_:setItem(items)

	local cost_ = GambleConfigTable:getCost(windowType.SENIOR)
	local cost_1 = xyd.split(cost_[1], "#", true)
	hidePlus = true
	callback = nil
	self.windowTop2_ = import("app.components.WindowTop").new(self.window_, self.name_, nil, true, closecallback)
	local items_ = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = cost_1[1],
			hidePlus = hidePlus,
			callback = callback
		}
	}

	self.windowTop2_:setItem(items_)
	self:updateResItem()
end

function GambleWindow:updateResItem()
	if self.curWindowType_ == windowType.NORMAL then
		self.windowTop_ = self.WindowTop1_

		self.windowTop1_:getGameObject():SetActive(true)
		self.windowTop2_:getGameObject():SetActive(false)
	else
		self.windowTop_ = self.WindowTop2_

		self.windowTop1_:getGameObject():SetActive(false)
		self.windowTop2_:getGameObject():SetActive(true)
	end
end

function GambleWindow:initData()
	local items = gambleModel:getItems(self.curWindowType_)

	if not self.itemsGroup_ then
		self.itemsGoup_ = self.content_.transform:Find("groupBottom/groupMidItems")
	end

	local childCount = self.itemsGoup_.transform.childCount

	for i = 1, childCount do
		local go = self.itemsGoup_.transform:GetChild(i - 1)

		if go.name ~= "refresh" then
			local idx = tonumber(go.name)

			self:initIcon(go, idx, items[idx])
		end
	end
end

function GambleWindow:initIcon(go, idx, itemData)
	local itemIcon, itemSelect = nil
	local tmpProb = string.format("%.1f", tostring(itemData.weight / 100))
	tmpProb = tonumber(tmpProb) * 10 / 10
	local smalltips = __("GAMBLE_ITEM_RATE", tostring(tmpProb))

	if not self.itemsList_[idx] then
		itemSelect = go.transform:ComponentByName("iconSelectBg", typeof(UISprite))
		local uiRoot = go.transform:Find("iconRoot").gameObject
		local params = {
			uiRoot = uiRoot,
			itemID = itemData.item_id,
			num = itemData.item_num,
			smallTips = smalltips,
			wndType = xyd.ItemTipsWndType.GAMBLE
		}
		itemIcon = xyd.getItemIcon(params)

		table.insert(self.itemsList_, {
			itemIcon = itemIcon,
			itemSelect = itemSelect,
			iconRoot = uiRoot
		})
	else
		itemSelect = self.itemsList_[idx].itemSelect

		self:refreshIcon(idx)
	end

	if itemData.buy_limit ~= 0 and itemData.buy_limit <= itemData.buy_times then
		itemSelect.gameObject:SetActive(false)
		xyd.applyChildrenGrey(self.itemsList_[idx].itemIcon.go)
		self.itemsList_[idx].itemIcon:setChoose(true)
	else
		itemSelect.gameObject:SetActive(false)
	end
end

function GambleWindow:refreshIcon(idx)
	local iconRoot = self.itemsList_[idx].iconRoot
	local itemSelect = self.itemsList_[idx].itemSelect
	local itemData = gambleModel:getItem(self.curWindowType_, idx)

	if iconRoot and not tolua.isnull(iconRoot) then
		local childCount = iconRoot.transform.childCount

		for i = 1, childCount do
			local child = iconRoot.transform:GetChild(i - 1).gameObject

			UnityEngine.Object.Destroy(child)
		end

		local tmpProb = string.format("%.1f", tostring(itemData.weight / 100))
		tmpProb = tonumber(tmpProb) * 10 / 10
		local smalltips = __("GAMBLE_ITEM_RATE", tostring(tmpProb))
		local params = {
			uiRoot = iconRoot,
			itemID = itemData.item_id,
			num = itemData.item_num,
			smallTips = smalltips,
			wndType = xyd.ItemTipsWndType.GAMBLE
		}
		local itemIcon = xyd.getItemIcon(params)
		self.itemsList_[idx] = {
			itemIcon = itemIcon,
			itemSelect = itemSelect,
			iconRoot = iconRoot
		}
	end

	if itemSelect then
		if itemData.buy_limit ~= 0 and itemData.buy_limit <= itemData.buy_times then
			itemSelect.gameObject:SetActive(true)
		else
			itemSelect.gameObject:SetActive(false)
		end
	end
end

function GambleWindow:initTime()
	local systemTime = GambleConfigTable:getSystemTime(self.curWindowType_)
	local duration = systemTime - xyd.getServerTime() + gambleModel:getSystemTime(self.curWindowType_)

	if duration > 0 then
		if duration < 3600 then
			duration = duration + 5
		end

		local params = {
			callback = function ()
				self:checkUpdate()
			end,
			duration = duration
		}

		if not self.refreshTimeCount_ then
			self.refreshTimeCount_ = import("app.components.CountDown").new(self.labelTime_, params)
		else
			self.refreshTimeCount_:setInfo(params)
		end

		self.labelTime_.gameObject:SetActive(true)
	else
		self.labelTime_.gameObject:SetActive(true)
	end
end

function GambleWindow:initButton()
	local data = gambleModel:getData(self.curWindowType_)

	if not data then
		return
	end

	local isFree = gambleModel:isFreeRefresh(self.curWindowType_)
	local cost = {
		0,
		0
	}

	if not isFree then
		cost = GambleConfigTable:getRefresh(self.curWindowType_)

		xyd.setUISpriteAsync(self.refreshBtnCostIcon_, nil, "icon_" .. cost[1], nil, )

		self.refreshBtnLabelNum_.text = cost[2]

		self.refreshBtnCostIcon_.gameObject:SetActive(true)
		self.refreshBtnLabelNum_.gameObject:SetActive(true)

		self.refreshBtnLabel_.transform.localPosition = Vector3(15, 3, 0)

		if xyd.Global.lang == "en_en" then
			self.refreshBtnLabel_.fontSize = 23

			self.refreshBtnLabel_:X(20)
		elseif xyd.Global.lang == "fr_fr" then
			self.refreshBtnLabel_.fontSize = 18

			self.refreshBtnLabel_:X(18)
		end
	else
		self.refreshBtnCostIcon_.gameObject:SetActive(false)
		self.refreshBtnLabelNum_.gameObject:SetActive(false)

		self.refreshBtnLabel_.transform.localPosition = Vector3(0, 3, 0)
	end

	self.refreshBtnLabel_.text = __("REFRESH")
end

function GambleWindow:playStandbyAction()
	self:clearTimer()

	if not self.standbyTimer_ then
		self.standbyTimer_ = Timer.New(handler(self, self.standbyTimer), 1, -1, false)
	end

	self.standbyTimer_:Start()
end

function GambleWindow:standbyTimer()
	local index = self.curActionIndex_
	self.curActionIndex_ = self.curActionIndex_ + 1

	if self.curActionIndex_ > 8 then
		self.curActionIndex_ = 1
	end

	local selectIcon = self.itemsList_[index].itemSelect
	local sequene = DG.Tweening.DOTween.Sequence()

	local function getter()
		return selectIcon.color
	end

	local function setter(value)
		selectIcon.color = value
	end

	selectIcon.gameObject:SetActive(true)

	selectIcon.alpha = 1

	sequene:Insert(1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.2))
	sequene:SetAutoKill(false)
end

function GambleWindow:checkUpdate()
	local systemTime = GambleConfigTable:getSystemTime(self.curWindowType_)
	local duration = systemTime - xyd.getServerTime() + gambleModel:getSystemTime(self.curWindowType_)

	if duration <= 0 then
		gambleModel:clearGambleByType(self.curWindowType_)
		gambleModel:reqGambleInfo(self.curWindowType_, true)
	end
end

function GambleWindow:updateSideLayout()
	if self.curWindowType_ == xyd.GambleWindowType.NORMAL and self.ifShowBtnGo then
		local cost = GambleConfigTable:getCost(self.curWindowType_)[self.sideType + 2]
		self.tenNum_.text = xyd.split(cost, "#", true)[2]
		self.sideBtnLabel1.text = self.sideTypeTimes[self.sideType]
		self.tenLabel_.text = self.buyTimeText[self.sideType]
	end
end

function GambleWindow:register()
	GambleWindow.super.register(self)

	UIEventListener.Get(self.btnGo).onClick = function ()
		xyd.goWay(xyd.GoWayId.ACTIVITY_WISHING_POOL, nil, function ()
			xyd.closeWindow(self:getName())
		end)
	end

	UIEventListener.Get(self.sideBtn).onClick = function ()
		self.sideType = self.sideType + 1

		if self.sideType > 3 then
			self.sideType = 1
		end

		self:updateSideLayout()
		xyd.db.misc:setValue({
			key = "gamble_side_type",
			value = self.sideType
		})
	end

	UIEventListener.Get(self.refreshBtn_.gameObject).onClick = handler(self, self.refreshTouch)
	UIEventListener.Get(self.btnOne_.gameObject).onClick = handler(self, self.oneTouch)
	UIEventListener.Get(self.skipBtn_).onClick = handler(self, self.onClickSkip)

	UIEventListener.Get(self.btnOne_.gameObject).onPress = function (go, isPressed)
		if isPressed then
			self.oneIcon_.transform:SetLocalPosition(-30, 3, 0)
			self.oneNum_.transform:SetLocalPosition(-30, -12, 0)
			self.oneLabel_.transform:SetLocalPosition(35, 2, 0)
		else
			self.oneIcon_.transform:SetLocalPosition(-30, 5, 0)
			self.oneNum_.transform:SetLocalPosition(-30, -10, 0)
			self.oneLabel_.transform:SetLocalPosition(35, 4, 0)
		end
	end

	UIEventListener.Get(self.btnTen_.gameObject).onClick = handler(self, self.tenTouch)

	UIEventListener.Get(self.btnTen_.gameObject).onPress = function (go, isPressed)
		if isPressed then
			self.tenIcon_.transform:SetLocalPosition(-30, 3, 0)
			self.tenNum_.transform:SetLocalPosition(-30, -12, 0)
			self.tenLabel_.transform:SetLocalPosition(35, 2, 0)
		else
			self.tenIcon_.transform:SetLocalPosition(-30, 5, 0)
			self.tenNum_.transform:SetLocalPosition(-30, -10, 0)
			self.tenLabel_.transform:SetLocalPosition(35, 4, 0)
		end
	end

	UIEventListener.Get(self.btnShop_.gameObject).onClick = handler(self, self.shopTouch)
	UIEventListener.Get(self.btnRecords_.gameObject).onClick = handler(self, self.recordTouch)

	UIEventListener.Get(self.navNormal_.gameObject).onClick = function ()
		self:onNavTouch(windowType.NORMAL)
	end

	UIEventListener.Get(self.navSenior_.gameObject).onClick = function ()
		self:onNavTouch(windowType.SENIOR)
	end

	local ids = {
		xyd.tables.gambleTable:getDropBoxId(1),
		xyd.tables.gambleUpTable:getDropBoxId(1)
	}

	local function sortFunc(a, b)
		if b < a then
			return -1
		else
			return 1
		end
	end

	UIEventListener.Get(self.probBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("summon_drop_probability_window", {
			prefix = "GAMBLE_PRO_",
			box_id_ = ids,
			type = self.curWindowType_ - 1,
			title = __("GAMBLE_PRO_TITLE"),
			sort_func = sortFunc
		})
	end

	self.eventProxy_:addEventListener(xyd.event.GAMBLE_GET_INFO, handler(self, self.onGambleInfo))
	self.eventProxy_:addEventListener(xyd.event.GAMBLE_REFRESH, handler(self, self.onRefresh))
	self.eventProxy_:addEventListener(xyd.event.GAMBLE_GET_AWARD, handler(self, self.onGetAward))
	self.eventProxy_:addEventListener(xyd.event.GAMBLE_RECORDS, handler(self, self.onShowRecords))
end

function GambleWindow:oneTouch()
	local cost = GambleConfigTable:getCost(self.curWindowType_)
	local cost1 = xyd.split(cost[1], "#", true)

	if cost1[2] <= xyd.models.backpack:getItemNumByID(cost1[1]) then
		xyd.setTouchEnable(self.btnOne_, false)
		xyd.setTouchEnable(self.btnTen_, false)
		self.Mask_:SetActive(true)
		gambleModel:reqGetAward(self.curWindowType_, 1)

		local state = xyd.db.misc:getValue("gamble_skip_" .. self.curWindowType_)

		if not state or tonumber(state) ~= 1 then
			xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_1)
		end
	else
		self:showCoinTips(cost1[1])
	end
end

function GambleWindow:shopTouch(...)
	if self.girlsModel_ then
		self.girlsModel_:stopSound()
	end

	xyd.WindowManager.get():openWindow("shop_window", {
		shopType = xyd.ShopType.SHOP_LUCK
	})
end

function GambleWindow:recordTouch()
	gambleModel:reqGetRecords(self.curWindowType_)
end

function GambleWindow:onNavTouch(index)
	if self.girlsModel_ then
		self.girlsModel_:stopSound()
	end

	if self.curWindowType_ ~= index then
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

		if self.refreshTimer_ then
			self.refreshTimer_:Stop()

			self.refreshTimer_ = nil
		end

		if index == windowType.SENIOR and not self:checkSeniorEnable() then
			local vip = GambleConfigTable:needVip(windowType.SENIOR)
			local openValue = GambleConfigTable:needLevel(windowType.SENIOR)[1]

			xyd.alertTips(__("GAMBLE_DOOR_TIPS", openValue, vip[1]))

			return
		end

		self.curWindowType_ = index

		if not gambleModel:reqGambleInfo(self.curWindowType_) then
			self:onGambleInfo()
		end
	end

	self:freshSkipBtnState()
end

function GambleWindow:tenTouch()
	local needVip = GambleConfigTable:needVip(self.curWindowType_)
	local selfVip = xyd.models.backpack:getVipLev()
	local selfLev = xyd.models.backpack:getLev()
	local cost = GambleConfigTable:getCost(self.curWindowType_)
	local needLev = GambleConfigTable:needLevel(self.curWindowType_)
	local cost10 = xyd.split(cost[2], "#", true)
	local state = xyd.db.misc:getValue("gamble_skip_" .. self.curWindowType_)
	local needLev_ = nil

	if self.curWindowType_ == 1 then
		needLev_ = needLev[3]
	elseif self.curWindowType_ == 2 then
		needLev_ = needLev[2]
	end

	if self.ifShowBtnGo and self.curWindowType_ == xyd.GambleWindowType.NORMAL and self.sideType > 1 then
		cost10 = xyd.split(cost[self.sideTypeIndex[self.sideType]], "#", true)
	end

	if selfVip < needVip[2] and selfLev < needLev_ then
		xyd.alertConfirm(__("GAMBLE_VIP_NOT_ENOUGH", needVip[2], needLev[3]), function (yes)
			if yes then
				xyd.WindowManager.get():openWindow("vip_window")
			end
		end, __("BUY"))
	else
		if cost10[2] <= xyd.models.backpack:getItemNumByID(cost10[1]) then
			local index = nil

			if needVip[2] <= selfVip then
				index = 2
			else
				index = 3
			end

			if self.ifShowBtnGo and self.curWindowType_ == xyd.GambleWindowType.NORMAL and self.sideType > 1 then
				local tmpIndex = self.sideTypeIndex[self.sideType]

				if needLev[tmpIndex] <= selfLev or needVip[tmpIndex] <= selfVip then
					index = tmpIndex
				end
			end

			if self.curWindowType_ == windowType.SENIOR and selfVip < needVip[2] then
				xyd.alertTips(__("GAMBLE_NEED_VIP", needVip[1]))

				return
			end

			local tips = ""
			local timekey = ""
			local timeStamp = nil

			if index == 4 then
				tips = __("GAMBLE_BUY_POINTS_TEXT02")
				timekey = "gamble_twenty_times"
				timeStamp = xyd.db.misc:getValue(timekey .. "_time_stamp")
			elseif index == 5 then
				tips = __("GAMBLE_BUY_POINTS_TEXT03")
				timekey = "gamble_fifty_times"
				timeStamp = xyd.db.misc:getValue(timekey .. "_time_stamp")
			end

			if tips ~= "" and (not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime())) then
				xyd.openWindow("gamble_tips_window", {
					text = tips,
					callback = function ()
						xyd.setTouchEnable(self.btnOne_, false)
						xyd.setTouchEnable(self.btnTen_, false)
						self.Mask_:SetActive(true)
						gambleModel:reqGetAward(self.curWindowType_, index)

						if not state or tonumber(state) ~= 1 then
							xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_10)
						end
					end,
					type = timekey
				})
			else
				xyd.setTouchEnable(self.btnOne_, false)
				xyd.setTouchEnable(self.btnTen_, false)
				self.Mask_:SetActive(true)
				gambleModel:reqGetAward(self.curWindowType_, index)

				if not state or tonumber(state) ~= 1 then
					xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_10)
				end
			end

			return
		end

		self:showCoinTips(cost10[1])
	end
end

function GambleWindow:showCoinTips(id)
	local tips = "GAMBLE_COIN_NOT_ENOUGH"

	if tonumber(id) == xyd.ItemID.GAMBLE_SUPER then
		tips = "GAMBLE_SUPER_COIN_NOT_ENOUGH"
	end

	xyd.alertTips(__(tips))
end

function GambleWindow:refreshTouch()
	local isFree = gambleModel:isFreeRefresh(self.curWindowType_)

	if not isFree then
		local cost = GambleConfigTable:getRefresh(self.curWindowType_)
		local selfNum = xyd.models.backpack:getItemNumByID(cost[1])

		if selfNum < cost[2] then
			xyd.alertConfirm(__("CRYSTAL_NOT_ENOUGH"), function (yes)
				if yes then
					xyd.WindowManager.get():openWindow("vip_window")
				end
			end, __("BUY"))
		else
			local timeStamp = xyd.db.misc:getValue("gamble_time_stamp")

			if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
				xyd.WindowManager.get():openWindow("gamble_tips_window", {
					type = "gamble",
					wndType = self.curWindowType_,
					callback = function ()
						gambleModel:reqRefreshInfo(self.curWindowType_)
					end
				})
			else
				gambleModel:reqRefreshInfo(self.curWindowType_)
			end
		end
	else
		gambleModel:reqRefreshInfo(self.curWindowType_)
	end
end

function GambleWindow:onGambleInfo()
	if not self.hasInit_ then
		self.hasInit_ = true

		self:initTime()
		self:initData()
		self:initButton()
		self:playStandbyAction()
		self:checkUpdate()
	else
		self:updatePanel()
	end
end

function GambleWindow:playOpenAnimation(callback)
	GambleWindow.super.playOpenAnimation(self, function ()
		self:playOpenAnimationsInInit()

		if callback then
			callback()
		end
	end)
end

function GambleWindow:updatePanel()
	self:updateLayout()
	self:updateResItem()
	self:initData()
	self:initTime()
	self:initButton()
	self:initGirlsModel()
	self:playStandbyAction()
	self:checkUpdate()
	self:initNavState()
end

function GambleWindow:initNavState()
	if not self.spriteLock_ then
		self.spriteLock_ = self.navSenior_.transform:ComponentByName("img", typeof(UISprite))
	end

	if self:checkSeniorEnable() then
		self.spriteLock_.gameObject:SetActive(false)
	else
		self.spriteLock_.gameObject:SetActive(true)
	end

	if self.curWindowType_ == windowType.NORMAL then
		xyd.setUISpriteAsync(self.navNormal_, nil, "nav_btn_blue_left", nil, )

		self.navNormalLabel_.color = Color.New2(4294967295.0)
		self.navSeniorLabel_.color = Color.New2(960513791)
		self.navNormalLabel_.effectStyle = UILabel.Effect.Outline
		self.navNormalLabel_.effectColor = Color.New2(473916927)

		if self:checkSeniorEnable() then
			xyd.setUISpriteAsync(self.navSenior_, nil, "nav_btn_white_right", nil, )
			self.navSeniorLabel_:X(0)

			self.navSeniorLabel_.effectStyle = UILabel.Effect.None
		else
			xyd.setUISpriteAsync(self.navSenior_, nil, "nav_btn_grey_right", nil, )

			self.navSeniorLabel_.effectStyle = UILabel.Effect.Outline
			self.navSeniorLabel_.effectColor = Color.New2(4294967295.0)

			if xyd.Global.lang == "en_en" then
				self.navSeniorLabel_.fontSize = 21
			elseif xyd.Global.lang == "de_de" then
				self.navSeniorLabel_.fontSize = 24
			end
		end
	else
		self.navSeniorLabel_.color = Color.New2(4294967295.0)
		self.navNormalLabel_.color = Color.New2(960513791)
		self.navNormalLabel_.effectStyle = UILabel.Effect.None
		self.navSeniorLabel_.effectStyle = UILabel.Effect.Outline
		self.navSeniorLabel_.effectColor = Color.New2(473916927)

		xyd.setUISpriteAsync(self.navNormal_, nil, "nav_btn_white_left", nil, )
		xyd.setUISpriteAsync(self.navSenior_, nil, "nav_btn_blue_right", nil, )
	end
end

function GambleWindow:checkSeniorEnable()
	local vip = GambleConfigTable:needVip(windowType.SENIOR)
	local openValue = GambleConfigTable:needLevel(windowType.SENIOR)[1]
	local selfVip = xyd.models.backpack:getVipLev()
	local selfLev = xyd.models.backpack:getLev()

	if vip[1] <= selfVip or openValue <= selfLev then
		return true
	else
		return false
	end
end

function GambleWindow:onShowRecords(event)
	local strList = {}
	local records = event.data.records

	for _, record in ipairs(records) do
		local quality = xyd.tables.itemTable:getQuality(record.item_id)
		local str = __("GAMBLE_RECORD_ITEM", record.player_name, xyd.getQualityColor2(quality), xyd.tables.itemTable:getName(record.item_id), record.item_num)

		table.insert(strList, str)
	end

	if #strList <= 0 then
		xyd.alertTips(__("GAMBLE_NO_RECORDS"))
	else
		local params = {
			isYahei = true,
			isFlow = true,
			title = __("GAMBLE_RECORD_TITLE"),
			str_list = strList
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end
end

function GambleWindow:onRefresh(event)
	self.imgMask_.gameObject:SetActive(true)

	local freshIndex = 1

	local function callback()
		self:clearTimer()

		local indexOut = self.curActionIndex_

		self.itemsList_[indexOut].itemSelect.gameObject:SetActive(false)

		local function timerRefreshFunc()
			local index = self.curActionIndex_

			self:refreshIcon(index)

			if not self.itemsList_[index].refreshEffect then
				local effect = xyd.Spine.new(self.itemsList_[index].iconRoot)

				effect:setInfo("shuaxin", function ()
					effect:SetLocalPosition(0, 0, 0)
					effect:SetLocalScale(1, 1, 1)
					effect:setRenderTarget(self.itemsList_[index].itemIcon:getIconSprite(), 100)
					effect:play("texiao01", 1, 1, function ()
						effect:SetActive(false)
					end)
				end)

				self.itemsList_[index].refreshEffect = effect
			else
				local refreshEffect = self.itemsList_[index].refreshEffect

				refreshEffect:SetActive(true)
				refreshEffect:play("texiao01", 1, 1, function ()
					refreshEffect:SetActive(false)
				end)
			end

			self.curActionIndex_ = self.curActionIndex_ + 1

			if self.curActionIndex_ > 8 then
				self.curActionIndex_ = 1
			end

			freshIndex = freshIndex + 1

			if freshIndex >= 9 then
				freshIndex = 1

				self.refreshTimer_:Stop()
				self.imgMask_.gameObject:SetActive(false)
				self:initTime()
				self:initButton()
				self:playStandbyAction()
			end
		end

		if not self.refreshTimer_ then
			self.refreshTimer_ = Timer.New(timerRefreshFunc, 0.06, -1, false)

			self.refreshTimer_:Start()
		else
			self.refreshTimer_:Stop()
			self.refreshTimer_:Start()
		end
	end

	callback()
	self:initButton()
end

function GambleWindow:onGetAward(event)
	if not self.isNeedPlayAction_ then
		self:onGambleInfo()

		return
	end

	if self.girlsModel_ then
		self.girlsModel_:playChooseAction()
	end

	local awards = event.data.awards
	local type_ = event.data.gamble_type
	local items = gambleModel:getAwards(type_, awards)
	local call1, call2 = nil

	local function call()
		if self.timer2_ then
			self.timer2_:Stop()

			self.timer2_ = nil
		end

		self.imgMask_.gameObject:SetActive(false)

		self.isNeedPlayAction_ = false

		self:onGambleInfo()
		self:playStandbyAction()
		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			data = items,
			type = type_,
			callback = function ()
				self:onGambleInfo()
				self:playStandbyAction()

				self.isNeedPlayAction_ = true

				xyd.setTouchEnable(self.btnOne_, true)
				xyd.setTouchEnable(self.btnTen_, true)
				self.Mask_:SetActive(false)
			end
		})
	end

	if #items > 1 then
		call1 = call
	else
		call2 = call
	end

	local isCool = items[1] and items[1].cool and items[1].cool == 1

	local function callback()
		if not self.window_ then
			return
		end
	end

	if self.state_ and self.state_ == "1" then
		call()
	else
		self:playAwardAction(awards[1], call1, call2, isCool)
	end
end

function GambleWindow:playAwardAction(awardIndex, call1, call2, isCool)
	self:clearTimer()
	self.imgMask_.gameObject:SetActive(false)

	local finalIndex = nil

	if awardIndex - 5 < 0 then
		finalIndex = 8 + awardIndex - 5 + 1
	else
		finalIndex = awardIndex - 5 + 1
	end

	local num = 24 + finalIndex - self.curActionIndex_ + 1
	local count = 0

	local function onAwardTime()
		count = count + 1

		if count < num then
			local sequene = DG.Tweening.DOTween.Sequence()
			local index = self.curActionIndex_
			local selectIcon = self.itemsList_[index].itemSelect

			local function getter()
				return selectIcon.color
			end

			local function setter(value)
				selectIcon.color = value
			end

			selectIcon.gameObject:SetActive(true)

			selectIcon.alpha = 1

			sequene:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 0, 0.5))
			sequene:AppendCallback(function ()
				selectIcon.gameObject:SetActive(false)
			end)
			sequene:SetAutoKill(false)
			table.insert(self.seqList_, sequene)

			self.curActionIndex_ = self.curActionIndex_ + 1

			if self.curActionIndex_ > 8 then
				self.curActionIndex_ = 1
			end

			return
		end

		if not self.timer2_ then
			if call1 then
				call1()

				return
			end

			local index = self.curActionIndex_
			local objs = {}
			local finalIndex = index

			for i = 0, 4 do
				local curIndex = index + i > 8 and index + i - 8 or index + i
				local selectIcon = self.itemsList_[curIndex].itemSelect

				selectIcon.gameObject:SetActive(true)

				selectIcon.alpha = 0

				table.insert(objs, selectIcon)

				finalIndex = curIndex

				if awardIndex == finalIndex then
					break
				end
			end

			objs[1].alpha = 1

			local function showEffect()
				if isCool then
					if not self.itemsList_[awardIndex].dajiangEffect then
						local effect = xyd.Spine.new(self.itemsList_[awardIndex].iconRoot)

						effect:setInfo("fx_dajiangtexiao", function ()
							effect:SetLocalPosition(0, 0, 0)
							effect:SetLocalScale(1, 1, 1)
							effect:setRenderTarget(self.itemsList_[awardIndex].itemIcon:getIconSprite(), 1)
							effect:play("texiao", 1, 1, function ()
								effect:SetActive(false)
							end)
						end)

						self.itemsList_[awardIndex].dajiangEffect = effect

						return
					end

					local dajiangEffect = self.itemsList_[awardIndex].dajiangEffect

					dajiangEffect:SetActive(true)
					dajiangEffect:play("texiao", 1, 1, function ()
						dajiangEffect:SetActive(false)
					end)
				end
			end

			local actions = {}
			local length = #objs

			for i = 1, #objs do
				table.insert(actions, {
					alpha = 0,
					obj = objs[i],
					delay = 0.2 + i * 0.1,
					miss = 0.2 + i * 0.1
				})
			end

			table.insert(actions, {
				delay = 0.6,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				call = showEffect
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 1,
				obj = objs[length]
			})
			table.insert(actions, {
				delay = 0.2,
				alpha = 0,
				obj = objs[length]
			})

			if call1 then
				call1()
			end

			local function timer2Func()
				local action = actions[1]

				if action then
					if action.call then
						action.call()
						table.remove(actions, 1)

						if actions[1] and actions[1].obj then
							actions[1].obj.alpha = 1
						end
					else
						action.delay = action.delay - 0.1

						if action.delay <= 0 then
							action.obj.alpha = action.alpha == 1 and 0 or 1
							local sequene2 = DG.Tweening.DOTween.Sequence()

							table.insert(self.seqList_, sequene2)

							local miss = action.miss or 0.2

							local function getter()
								return action.obj.color
							end

							local function setter(value)
								action.obj.color = value
							end

							action.obj.gameObject:SetActive(true)

							action.obj.alpha = 1

							sequene2:Insert(0, DG.Tweening.DOTween.ToAlpha(getter, setter, action.alpha, miss))
							sequene2:SetAutoKill(false)
							table.remove(actions, 1)

							if actions[1] and actions[1].obj then
								actions[1].obj.alpha = 1
							end
						end
					end
				end

				if #actions <= 0 and call2 then
					call2()
				end
			end

			self.timer2_ = Timer.New(timer2Func, 0.1, -1, false)

			self.timer2_:Start()
		end

		self.curActionIndex_ = self.curActionIndex_ + 4

		if self.curActionIndex_ > 8 then
			self.curActionIndex_ = self.curActionIndex_ - 8
		end
	end

	self.rewardTimer_ = Timer.New(onAwardTime, 0.1, -1, false)

	self.rewardTimer_:Start()
end

function GambleWindow:playOpenAnimationsInInit()
	local seq = self:getSequence()
	local y_ = self.groupBottom_.localPosition.y

	seq:Insert(0, self.groupBottom_:DOLocalMove(Vector3(20, y_, 0), 0.2))
	seq:Insert(0.2, self.groupBottom_:DOLocalMove(Vector3(0, y_, 0), 0.2))
	seq:Insert(0, self.groupModel.transform:DOLocalMove(Vector3(-20, -210, 0), 0.2))
	seq:Insert(0.2, self.groupModel.transform:DOLocalMove(Vector3(0, -210, 0), 0.3))
end

function GambleWindow:clearTimer()
	if self.standbyTimer_ then
		self.standbyTimer_:Stop()

		self.standbyTimer_ = nil
	end

	if self.rewardTimer_ then
		self.rewardTimer_:Stop()

		self.rewardTimer_ = nil
	end

	if self.refreshTimer_ then
		self.refreshTimer_:Stop()

		self.refreshTimer_ = nil
	end
end

function GambleWindow:willClose()
	GambleWindow.super.willClose(self)
	self:clearTimer()

	if self.refreshTimeCount_ then
		self.refreshTimeCount_:stopTimeCount()

		self.refreshTimeCount_ = nil
	end

	for _, seq in pairs(self.seqList_) do
		if seq then
			seq:Kill()
		end
	end
end

return GambleWindow
