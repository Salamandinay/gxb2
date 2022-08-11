local BaseWindow = import(".BaseWindow")
local GambleRewardsWindow = class("GambleRewardsWindow", BaseWindow)
local GambleConfigTable = xyd.tables.gambleConfigTable
local gambleModel = xyd.models.gamble

function GambleRewardsWindow:ctor(name, params)
	GambleRewardsWindow.super.ctor(self, name, params)

	self.data_ = params.data or {}
	self.type_ = params.type
	self.cost = params.cost
	self.cost2 = params.cost2
	self.btnSureText = params.btnSureText or "CONFIRM"
	self.btnLabelText = params.btnLabelText
	self.btnLabelText2 = params.btnLabelText2
	self.callback_ = params.callback
	self.buyCallback = params.buyCallback
	self.curWndType_ = params.wnd_type or self.WindowType.GAMBLE
	self.sureCallback_ = params.sureCallback
	self.afterAnimationCallback = params.afterAnimationCallback
	self.closeCallBackFun = params.closeCallBackFun
	self.layoutCenter = params.layoutCenter
	self.progressRoundText = params.progressRoundText
	self.progressText = params.progressText
	self.progressValue = params.progressValue
	self.progressLastValue = params.progressLastValue
	self.progressLastText = params.progressLastText
	self.showGolden = params.showGolden
	self.isNeedCostBtn = true

	if params.isNeedCostBtn ~= nil then
		self.isNeedCostBtn = params.isNeedCostBtn
	end

	self.isNeedOptionalBox = params.isNeedOptionalBox or false
	self.optionalBoxText = params.optionalBoxText
	self.optionalBoxCallBack = params.optionalBoxCallBack
	self.optionalBoxValue = params.optionalBoxValue or false
	self.optionalBoxTextSize = params.optionalBoxTextSize
	self.buyType = {
		TEN = 2,
		ONE = 1,
		FIFTY = 5,
		TWENTY = 4
	}
end

function GambleRewardsWindow:initWindow()
	GambleRewardsWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.content_ = winTrans:Find("content")
	self.scrollView_ = self.content_:GetComponent(typeof(UIScrollView))
	self.gridOfItems_ = winTrans:ComponentByName("content/itemsGrid", typeof(UIGrid))
	self.item_root_ = winTrans:NodeByName("content/item_root").gameObject
	self.itemRoot_ = winTrans:ComponentByName("content/itemRoot", typeof(UIGrid))
	self.groupBtns_ = winTrans:Find("bottonPos")
	self.btnSure_ = winTrans:ComponentByName("bottonPos/btnSure", typeof(UISprite))
	self.btnBuy_ = winTrans:ComponentByName("bottonPos/btnBuy", typeof(UISprite))
	self.btnSureLable_ = winTrans:ComponentByName("bottonPos/btnSure/costDesc", typeof(UILabel))
	self.btnBuyLable_ = winTrans:ComponentByName("bottonPos/btnBuy/costDesc", typeof(UILabel))
	self.btnBuyNumLable_ = winTrans:ComponentByName("bottonPos/btnBuy/costNum", typeof(UILabel))
	self.btnBuyIcon_ = winTrans:ComponentByName("bottonPos/btnBuy/costIcon", typeof(UISprite))
	self.btnBuy2_ = winTrans:ComponentByName("bottonPos/btnBuy2", typeof(UISprite))
	self.btnBuyLable2_ = winTrans:ComponentByName("bottonPos/btnBuy2/costDesc", typeof(UILabel))
	self.btnBuyNumLable2_ = winTrans:ComponentByName("bottonPos/btnBuy2/costNum", typeof(UILabel))
	self.btnBuyIcon2_ = winTrans:ComponentByName("bottonPos/btnBuy2/costIcon", typeof(UISprite))
	self.effectRoot_ = winTrans:ComponentByName("effect", typeof(UITexture))
	self.textImg = winTrans:ComponentByName("textImg", typeof(UITexture))
	self.progressGroup = winTrans:NodeByName("progressGroup").gameObject
	self.progressBar = self.progressGroup:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressDesc = self.progressBar:ComponentByName("progressLabel", typeof(UILabel))
	self.progressLabel = self.progressGroup:ComponentByName("label", typeof(UILabel))
	self.progressEffectNode = self.progressGroup:NodeByName("effect").gameObject
	self.optionalBox = self.groupBtns_:NodeByName("optionalBox").gameObject
	self.optionalBoxBtn = self.optionalBox:NodeByName("optionalBoxBtn").gameObject
	self.optionalBoxBtnChoose = self.optionalBoxBtn:ComponentByName("imgChoose", typeof(UISprite))
	self.optionalBoxLabel = self.optionalBox:ComponentByName("optionalBoxLabel", typeof(UILabel))
	self.itemsTopEffectUITexture = self.content_:ComponentByName("itemsTopEffect", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.textImg, "huodewupin_" .. xyd.Global.lang, true)
	self:layout()
	self:register()
end

function GambleRewardsWindow:layout()
	if self.curWndType_ == self.WindowType.GAMBLE and #self.data_ == 1 or self.curWndType_ == self.WindowType.PROPHET and #self.data_ <= 2 or self.curWndType_ == self.WindowType.NORMAL and #self.data_ <= 5 or self.curWndType_ == self.WindowType.ACTIVITY and #self.data_ <= 5 or self.curWndType_ == self.WindowType.DRESS and #self.data_ <= 2 or self.curWndType_ == self.WindowType.STARRY_ALTAR and #self.data_ < 10 then
		self.curBuyType_ = self.buyType.ONE

		self.gridOfItems_.gameObject:SetActive(false)
		self.itemRoot_.gameObject:SetActive(true)
	elseif self.curWndType_ == self.WindowType.GAMBLE and #self.data_ == 20 then
		self.curBuyType_ = self.buyType.TWENTY

		self.gridOfItems_.gameObject:SetActive(true)
		self.itemRoot_.gameObject:SetActive(false)
	elseif self.curWndType_ == self.WindowType.GAMBLE and #self.data_ == 50 then
		self.curBuyType_ = self.buyType.FIFTY

		self.gridOfItems_.gameObject:SetActive(true)
		self.itemRoot_.gameObject:SetActive(false)
	else
		self.curBuyType_ = self.buyType.TEN

		self.gridOfItems_.gameObject:SetActive(true)
		self.itemRoot_.gameObject:SetActive(false)
	end

	if self.layoutCenter then
		self.gridOfItems_.pivot = UIWidget.Pivot.Top

		self.gridOfItems_:X(0)
	end

	self.btnSureLable_.text = __(self.btnSureText)

	self.groupBtns_.gameObject:SetActive(false)

	if self.progressValue then
		self.progressGroup:SetActive(true)

		self.progressBar.value = self.progressLastValue
		self.progressDesc.text = self.progressLastText
		self.progressLabel.text = self.progressRoundText

		self.content_:Y(64)
		self.effectRoot_:Y(64)
		self.textImg:Y(71)
	else
		self.progressGroup:SetActive(false)
	end

	if self.isNeedOptionalBox then
		self.optionalBox:SetActive(true)

		self.optionalBoxLabel.text = self.optionalBoxText

		if self.optionalBoxTextSize then
			self.optionalBoxLabel.fontSize = self.optionalBoxTextSize
		end

		self.optionalBox:GetComponent(typeof(UILayout)):Reposition()
	else
		self.optionalBox:SetActive(false)
	end
end

function GambleRewardsWindow:loadEffects(flag)
	if not flag then
		self:ResetScrollPos()
	end

	if self.isNeedCostBtn then
		self:initCost()
	else
		self.btnBuy_.gameObject:SetActive(false)
		self.btnBuy2_.gameObject:SetActive(false)
		self.btnSure_.gameObject:X(0)
	end

	self:initData()
	self:playAnimation(function ()
		self:playChangeImgAni()
	end)
end

function GambleRewardsWindow:playOpenAnimation(callback)
	GambleRewardsWindow.super.playCloseAnimation(self, function ()
		if self.isNeedCostBtn then
			self:initCost()
		else
			self.btnBuy_.gameObject:SetActive(false)
			self.btnBuy2_.gameObject:SetActive(false)
			self.btnSure_.gameObject:X(0)
		end

		self:initData()
		self:playAnimation(function ()
			self:playChangeImgAni()
			callback()
		end)
	end)
end

function GambleRewardsWindow:ResetScrollPos()
	self.scrollView_:ResetPosition()

	self.content_:GetComponent(typeof(UIPanel)).transform.localPosition = Vector3(0, 0, 0)
	self.content_:GetComponent(typeof(UIPanel)).clipOffset = Vector2(0, 0)
	self.gridOfItems_.transform.localPosition = Vector3(-280, 40, 0)
end

function GambleRewardsWindow:initCost()
	if self.curWndType_ == self.WindowType.GAMBLE then
		local cost = GambleConfigTable:getCost(self.type_)
		local cost1 = xyd.split(cost[1], "#", true)
		local cost10 = xyd.split(cost[2], "#", true)
		local btnLabel = ""

		if self.curBuyType_ == self.buyType.ONE then
			self.buyCost_ = cost1
			btnLabel = "GAMBLE_BUY_ONE"
		elseif self.curBuyType_ == self.buyType.TWENTY then
			self.buyCost_ = xyd.split(cost[4], "#", true)
			btnLabel = "GAMBLE_BUY_TWENTY"
		elseif self.curBuyType_ == self.buyType.FIFTY then
			self.buyCost_ = xyd.split(cost[5], "#", true)
			btnLabel = "GAMBLE_BUY_FIFTY"
		else
			self.buyCost_ = cost10
			btnLabel = "GAMBLE_BUY_TEN"
		end

		self.btnBuyNumLable_.text = self.buyCost_[2]

		xyd.setUISpriteAsync(self.btnBuyIcon_, nil, xyd.tables.itemTable:getIcon(self.buyCost_[1]), nil, )

		self.btnBuyLable_.text = __(btnLabel)
		self.btnSure_.transform.localPosition = Vector3(-150, 0, 0)

		self.btnBuy_.gameObject:SetActive(true)
	elseif self.curWndType_ == self.WindowType.PROPHET then
		local cost = xyd.tables.miscTable:split2Cost("prophet_cost", "value", "|#")
		local cost1 = cost[1]
		local cost10 = cost[2]
		local btnLabel = ""

		if self.curBuyType_ == self.buyType.ONE then
			self.buyCost_ = cost1
			btnLabel = "GAMBLE_BUY_ONE"
		else
			self.buyCost_ = cost10
			btnLabel = "GAMBLE_BUY_TEN"
		end

		self.btnBuyNumLable_.text = self.buyCost_[2]

		xyd.setUISpriteAsync(self.btnBuyIcon_, nil, xyd.tables.itemTable:getIcon(self.buyCost_[1]), nil, )

		self.btnBuyLable_.text = __(btnLabel)
		self.btnSure_.transform.localPosition = Vector3(-150, 0, 0)

		self.btnBuy_.gameObject:SetActive(true)
	elseif self.curWndType_ == self.WindowType.ACTIVITY then
		self.buyCost_ = self.cost
		self.buyCost2_ = self.cost2
		local btnLabel = "GAMBLE_BUY_ONE"

		if self.curBuyType_ ~= self.buyType.ONE then
			btnLabel = "GAMBLE_BUY_TEN"
		end

		xyd.setUISpriteAsync(self.btnBuyIcon_, nil, xyd.tables.itemTable:getIcon(self.buyCost_[1]))

		self.btnBuyNumLable_.text = self.buyCost_[2]
		self.btnBuyLable_.text = __(btnLabel)

		if self.btnLabelText then
			self.btnBuyLable_.text = __(self.btnLabelText)
		end

		self.btnBuy_:SetActive(true)

		if self.cost2 then
			xyd.setUISpriteAsync(self.btnBuyIcon2_, nil, xyd.tables.itemTable:getIcon(self.buyCost2_[1]))

			self.btnBuyNumLable2_.text = self.buyCost2_[2]

			if not self.btnLabelText2 then
				self.btnBuyLable_.text = __(self.btnLabelText, self.buyCost_[2])
				self.btnBuyLable2_.text = __(self.btnLabelText, self.buyCost2_[2])
			else
				self.btnBuyLable_.text = __(self.btnLabelText)
				self.btnBuyLable2_.text = __(self.btnLabelText2)
				self.btnBuyLable_.height = 45
				self.btnBuyLable2_.height = 45
			end

			self.btnSure_.width = 172
			self.btnBuy_.width = 172
			self.btnBuy2_.width = 172

			self.btnSure_:X(-220)
			self.btnBuy_:X(0)
			self.btnBuy2_:X(220)
			self.btnBuyLable_:X(25)
			self.btnBuyLable2_:X(25)

			self.btnBuyLable_.width = 100
			self.btnBuyLable2_.width = 100

			self.btnBuy2_:SetActive(true)
		else
			self.btnBuy2_:SetActive(false)
		end
	elseif self.curWndType_ == self.WindowType.DRESS then
		local cost, free_times, iconName = nil

		if self.type_ == 1 then
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_FREE)

			if activityData and activityData.detail.can_summon_times then
				free_times = activityData.detail.can_summon_times
			end
		else
			local activityData = xyd.models.activity:getActivity(xyd.ActivityID.DRESS_SUMMON_LIMIT_FREE)

			if activityData and activityData.detail.can_summon_times then
				free_times = activityData.detail.can_summon_times
			end
		end

		local btnLabel = ""

		if self.curBuyType_ == self.buyType.ONE then
			if free_times and free_times > 0 then
				self.btnBuyLable_.text = __("FREE2")

				self.btnBuyLable_.transform:X(0)
				self.btnBuyIcon_.gameObject:SetActive(false)
				self.btnBuyNumLable_.gameObject:SetActive(false)

				self.isFree_ = true
			else
				self.isFree_ = false

				if self.type_ == 1 then
					local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost1", "value", "#")

					xyd.setUISpriteAsync(self.btnBuyIcon_, nil, "icon_258", nil, )

					self.buyCost_ = cost
				else
					local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost2", "value", "|#")
					self.buyCost_ = cost[2]

					xyd.setUISpriteAsync(self.btnBuyIcon_, nil, "icon_259", nil, )
				end

				self.btnBuyLable_.transform:X(35)

				self.btnBuyLable_.text = __("GAMBLE_BUY_ONE")
				self.btnBuyNumLable_.text = 1

				self.btnBuyIcon_.gameObject:SetActive(true)
				self.btnBuyNumLable_.gameObject:SetActive(true)
			end
		elseif free_times and free_times >= 10 then
			self.btnBuyLable_.text = __("FREE2")

			self.btnBuyLable_.transform:X(0)
			self.btnBuyIcon_.gameObject:SetActive(false)
			self.btnBuyNumLable_.gameObject:SetActive(false)

			self.isFree_ = true
		else
			self.isFree_ = false

			if self.type_ == 1 then
				local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost1", "value", "#")
				self.buyCost_ = cost

				xyd.setUISpriteAsync(self.btnBuyIcon_, nil, "icon_258", nil, )
			else
				local cost = xyd.tables.miscTable:split2Cost("dress_gacha_cost2", "value", "|#")
				self.buyCost_ = cost[2]

				xyd.setUISpriteAsync(self.btnBuyIcon_, nil, "icon_259", nil, )
			end

			self.btnBuyLable_.transform:X(35)

			self.btnBuyLable_.text = __("GAMBLE_BUY_TEN")
			self.btnBuyNumLable_.text = 10

			self.btnBuyIcon_.gameObject:SetActive(true)
			self.btnBuyNumLable_.gameObject:SetActive(true)
		end

		self.btnSure_.transform.localPosition = Vector3(-150, 0, 0)

		self.btnBuy_.gameObject:SetActive(true)
	elseif self.curWndType_ == self.WindowType.STARRY_ALTAR then
		local cost = xyd.tables.starryAltarTable:getCost(self.type_)
		local btnLabel = ""

		if self.curBuyType_ == self.buyType.ONE then
			btnLabel = "GAMBLE_BUY_ONE"
		else
			cost[2] = cost[2] * 10
			btnLabel = "GAMBLE_BUY_TEN"
		end

		self.buyCost_ = cost
		self.btnBuyNumLable_.text = self.buyCost_[2]

		xyd.setUISpriteAsync(self.btnBuyIcon_, nil, xyd.tables.itemTable:getIcon(self.buyCost_[1]), nil, )

		self.btnBuyLable_.text = __(btnLabel)
		self.btnSure_.transform.localPosition = Vector3(-150, 0, 0)

		self.btnBuy_.gameObject:SetActive(true)
	else
		self.btnSure_:X(0)
		self.btnBuy_:SetActive(false)
	end
end

function GambleRewardsWindow:initData()
	self.items_ = {}

	if self.curBuyType_ == self.buyType.ONE then
		self.item_root_.gameObject:SetActive(false)
		self.itemRoot_.gameObject:SetActive(true)
		self.gridOfItems_.gameObject:SetActive(false)

		local childCount = self.itemRoot_.transform.childCount

		for i = 1, childCount do
			local go = self.itemRoot_.transform:GetChild(i - 1)

			if go.name ~= "item2Root" then
				UnityEngine.Object.Destroy(go.gameObject)
			end
		end

		self.itemRoot_:GetComponent(typeof(UIWidget)).alpha = 0

		for _, itemData in ipairs(self.data_) do
			local itemIcon = xyd.getItemIcon({
				show_has_num = true,
				hideText = true,
				uiRoot = self.itemRoot_.gameObject,
				itemID = itemData.item_id,
				num = itemData.item_num,
				dragScrollView = self.scrollView_,
				showLev = itemData.showLev
			}, itemData.iconType)

			if itemData.belowText then
				if itemData.belowTextColor then
					itemIcon:setBelowLabel(true, itemData.belowText, itemData.belowTextColor)
				else
					itemIcon:setBelowLabel(true, itemData.belowText)
				end
			end

			local changeWidget = nil

			if itemData.changeItem and tonumber(itemData.changeItem) > 0 then
				local changeRoot = itemIcon.go
				local icon2 = xyd.getItemIcon({
					hideText = true,
					uiRoot = changeRoot,
					itemID = itemData.changeItem,
					dragScrollView = self.scrollView_
				}, itemData.iconType)

				icon2:setDepth(40)

				changeWidget = icon2.go:GetComponent(typeof(UIWidget))
			end

			table.insert(self.items_, {
				obj = itemIcon:getGameObject(),
				item = itemIcon,
				itemData = itemData,
				changeWidget = changeWidget
			})
		end

		self:waitForFrame(1, function ()
			self.itemRoot_:Reposition()
		end)
	else
		self.itemRoot_.gameObject:SetActive(false)
		self.gridOfItems_.gameObject:SetActive(true)

		local childCount = self.gridOfItems_.transform.childCount

		for i = 1, childCount do
			local go = self.gridOfItems_.transform:GetChild(i - 1)

			go.gameObject:SetActive(false)
		end

		self.gridOfItems_:Reposition()

		for i = 1, childCount do
			local go = self.gridOfItems_.transform:GetChild(i - 1)

			UnityEngine.Object.Destroy(go.gameObject)
		end

		for _, itemData in ipairs(self.data_) do
			local uiRoot = NGUITools.AddChild(self.gridOfItems_.gameObject, self.item_root_.gameObject)
			local itemIcon = xyd.getItemIcon({
				show_has_num = true,
				hideText = true,
				uiRoot = uiRoot.gameObject,
				itemID = itemData.item_id,
				num = itemData.item_num,
				dragScrollView = self.scrollView_,
				showLev = itemData.showLev
			}, itemData.iconType)

			if itemData.belowText then
				if itemData.belowTextColor then
					itemIcon:setBelowLabel(true, itemData.belowText, itemData.belowTextColor)
				else
					itemIcon:setBelowLabel(true, itemData.belowText)
				end

				self.gridOfItems_.cellHeight = 144

				self.gridOfItems_:Y(46)
			end

			local changeWidget = nil

			if itemData.changeItem and tonumber(itemData.changeItem) > 0 then
				local changeRoot = uiRoot:NodeByName("item2Root").gameObject
				changeWidget = changeRoot:GetComponent(typeof(UIWidget))

				xyd.getItemIcon({
					hideText = true,
					uiRoot = changeRoot,
					itemID = itemData.changeItem,
					dragScrollView = self.scrollView_
				}, itemData.iconType)
			end

			table.insert(self.items_, {
				obj = uiRoot.gameObject,
				item = itemIcon,
				itemData = itemData,
				changeWidget = changeWidget
			})
		end

		self.gridOfItems_:Reposition()

		for _, itemData in ipairs(self.items_) do
			itemData.obj:SetActive(false)
		end

		self.item_root_.gameObject:SetActive(false)
	end
end

function GambleRewardsWindow:playChangeImgAni()
	for _, item in ipairs(self.items_) do
		if item.changeWidget then
			item.changeWidget.alpha = 1
		end
	end

	local function setter(val)
		for _, item in ipairs(self.items_) do
			if item.changeWidget then
				item.changeWidget.alpha = val
			end
		end
	end

	self.seq = self:getSequence()

	self.seq:SetLoops(-1)
	self.seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0, 1.5))
	self.seq:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 0, 1, 1.5))
end

function GambleRewardsWindow:register()
	GambleRewardsWindow.super.register(self)

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, self.sureTouch)
	UIEventListener.Get(self.btnBuy_.gameObject).onClick = handler(self, function ()
		self:buyTouch(false)
	end)
	UIEventListener.Get(self.btnBuy2_.gameObject).onClick = handler(self, function ()
		self:buyTouch(true)
	end)

	self:waitForFrame(1, function ()
		self.eventProxy_:addEventListener(xyd.event.GAMBLE_GET_AWARD, handler(self, self.onGetAward))
	end)

	UIEventListener.Get(self.optionalBoxBtn).onClick = function ()
		self.optionalBoxValue = not self.optionalBoxValue

		self.optionalBoxBtnChoose:SetActive(self.optionalBoxValue)
	end
end

function GambleRewardsWindow:sureTouch()
	if self.sureCallback_ then
		self.sureCallback_()
	end

	xyd.closeWindow(self.name_)
end

function GambleRewardsWindow:buyTouch(isCost2)
	if self.curWndType_ == self.WindowType.GAMBLE then
		if self.buyCost_[2] <= xyd.models.backpack:getItemNumByID(self.buyCost_[1]) then
			local index = self.curBuyType_

			if self.curBuyType_ == self.buyType.ONE then
				-- Nothing
			elseif self.curBuyType_ == self.buyType.TWENTY then
				index = 4
			elseif self.curBuyType_ == self.buyType.FIFTY then
				index = 5
			else
				local needVip = GambleConfigTable:needVip(self.type_)
				local selfVip = xyd.models.backpack:getVipLev()
				index = needVip[2] <= selfVip and 2 or 3
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
						gambleModel:reqGetAward(self.type_, index)
					end,
					type = timekey
				})
			else
				gambleModel:reqGetAward(self.type_, index)
			end

			return
		end

		self:showCoinTips(self.buyCost_[1])
	elseif self.curWndType_ == self.WindowType.PROPHET then
		local cost = self.buyCost_

		if xyd.isItemAbsence(cost[1], cost[2]) then
			return
		end

		local proWnd = xyd.WindowManager.get():getWindow("prophet_window")

		if proWnd then
			proWnd:requestSummon()
		end

		xyd.closeWindow("gamble_rewards_window")
	elseif self.curWndType_ == self.WindowType.ACTIVITY then
		if self.buyCallback then
			self.buyCallback(self.buyCost_, self.buyCost2_, isCost2)
			xyd.closeWindow("gamble_rewards_window")
		else
			xyd.alertTips("没有回调函数")
		end
	elseif self.curWndType_ == self.WindowType.DRESS then
		local cost = self.buyCost_

		if not self.isFree_ and xyd.isItemAbsence(cost[1], cost[2]) then
			xyd.alertTips(__("SWEETY_HOUSE_NEED_MORE", xyd.tables.itemTable:getName(cost[1])))

			return
		end

		local win = xyd.WindowManager.get():getWindow("dress_summon_window")
		local times = xyd.checkCondition(self.curBuyType_ == self.buyType.ONE, 1, 10)

		if win then
			win:cleardebrisSeq()

			if self.type_ == 1 then
				win:reqSummonDress(times)
			else
				win:reqSummonLimitDress(times)
			end
		end

		xyd.closeWindow("gamble_rewards_window")
	elseif self.curWndType_ == self.WindowType.STARRY_ALTAR then
		if self.buyCallback then
			self.buyCallback()
		end

		xyd.closeWindow("gamble_rewards_window")
	end
end

function GambleRewardsWindow:showCoinTips(id)
	local tips = "GAMBLE_COIN_NOT_ENOUGH"

	if tonumber(id) == xyd.ItemID.GAMBLE_SUPER then
		tips = "GAMBLE_SUPER_COIN_NOT_ENOUGH"
	end

	xyd.alertTips(__(tips))
end

function GambleRewardsWindow:onGetAward(event)
	if self.curWndType_ == self.WindowType.GAMBLE then
		local awards = event.data.awards
		local type_ = event.data.gamble_type
		local items = gambleModel:getAwards(type_, awards)
		self.data_ = items
		self.type_ = type_

		self:layout()
		self:loadEffects()
	end
end

function GambleRewardsWindow:playAnimation(callback)
	local function playNormal(obj, callback, delay)
		if not obj or tolua.isnull(obj) then
			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_NORMAL)
		obj:SetActive(true)

		obj.transform.localScale = Vector3(0.36, 0.36, 0.36)
		local sequeneNormal = self:getSequence()

		sequeneNormal:Append(obj.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.13 / delay))
		sequeneNormal:Append(obj.transform:DOScale(Vector3(0.9, 0.9, 0.9), 0.16 / delay))
		sequeneNormal:Append(obj.transform:DOScale(Vector3(1, 1, 1), 0.16 / delay))
		sequeneNormal:AppendCallback(function ()
			if callback then
				callback()
			end
		end)
		sequeneNormal:SetAutoKill(true)
	end

	local function playBig(obj, itemIcon, callback, itemID, delay)
		if not obj or tolua.isnull(obj) then
			return
		end

		xyd.SoundManager.get():playSound(xyd.SoundID.GAMEBLE_VALUABLE)

		local targetSprite_1 = itemIcon:getIconSprite()
		local targetSprite_2 = itemIcon:getBorder()
		local effect = xyd.Spine.new(obj)

		effect:setInfo("fx_dajiangchuchang", function ()
			effect:setRenderPanel(self.scrollView_.gameObject:GetComponent(typeof(UIPanel)))
			effect:SetLocalPosition(0, 0, 0)
			effect:SetLocalScale(1.1, 1.1, 1.1)
			effect:setRenderTarget(self.itemsTopEffectUITexture, 0)

			obj.transform.localScale = Vector3(0.36, 0.36, 0.36)
			local icon = itemIcon:getGameObject()

			if not obj or tolua.isnull(obj) then
				return
			end

			obj:SetActive(true)

			local sequeneBig = self:getSequence()

			sequeneBig:Insert(0, obj.transform:DOScale(Vector3(1.2, 1.2, 1.2), 0.13 / delay))
			sequeneBig:Insert(0.13, obj.transform:DOScale(Vector3(1, 1, 1), 0.16 / delay))
			sequeneBig:AppendCallback(function ()
				if callback then
					callback(true)
				end
			end)
			effect:play("texiao", 1, 1, function ()
				effect:SetActive(false)

				local newEffect = xyd.Spine.new(obj)

				newEffect:setInfo("fx_ui_beijingguang", function ()
					newEffect:setRenderPanel(self.scrollView_.gameObject:GetComponent(typeof(UIPanel)))
					newEffect:setRenderTarget(targetSprite_1, -20)
					newEffect:SetLocalPosition(0, 0, 0)
					newEffect:SetLocalScale(1.1, 1.1, 1.1)
					newEffect:play("texiao", 0, 1)
				end)
			end)
		end)
	end

	local function playScroll(delta)
		local pos = self.gridOfItems_.transform.localPosition
		local seq = self:getSequence()

		seq:Append(self.gridOfItems_.transform:DOLocalMove(Vector3(pos.x, pos.y + delta, pos.z), 0.2))
	end

	local function play(actions)
		local delay = 1

		if self.curWndType_ == self.WindowType.GAMBLE then
			if #actions == 20 then
				delay = 2
			elseif #actions == 50 then
				delay = 5
			end
		end

		for i, data in ipairs(actions) do
			local itemData = data.itemData
			local item = data.item
			local obj = data.obj

			if obj then
				if not tolua.isnull(obj) then
					obj:SetActive(false)
				end
			end

			local isCool = itemData.cool == 1

			if i < #actions - 1 then
				self:setTimeout(function ()
					if isCool then
						playBig(obj, item, nil, itemData.item_id, delay)
					else
						playNormal(obj, nil, delay)
					end

					if self.curWndType_ == self.WindowType.GAMBLE and i > 5 and i <= #actions - 6 and i % 10 == 1 then
						self:setTimeout(function ()
							playScroll(264)
						end, obj, 100)
					end

					if self.curWndType_ == self.WindowType.DRAGONBOAT2022 and i > 10 and i % 10 == 1 then
						self:setTimeout(function ()
							playScroll(264)
						end, obj, 100)
					end
				end, obj, (100 * i + 300) / delay)
			else
				local function callback()
					if self.curWndType_ == self.WindowType.GAMBLE then
						xyd.models.selfPlayer:openNewPlayerTipsWindow(xyd.NewPlayerTipsId.GAMBLE)
					elseif self.curWndType_ == self.WindowType.PROPHET then
						xyd.models.selfPlayer:openNewPlayerTipsWindow(xyd.NewPlayerTipsId.PROPHET)
					end

					self.groupBtns_.gameObject:SetActive(true)

					if self.afterAnimationCallback then
						self:afterAnimationCallback()
					end
				end

				self:setTimeout(function ()
					if isCool then
						playBig(obj, item, callback, itemData.item_id, delay)
					else
						playNormal(obj, callback, delay)
					end

					if self.curWndType_ == self.WindowType.GAMBLE and i > 10 and i % 10 == 1 then
						self:setTimeout(function ()
							playScroll(264)
						end, obj, 100)
					end

					if self.curWndType_ == self.WindowType.DRAGONBOAT2022 and i > 10 and i % 10 == 1 then
						self:setTimeout(function ()
							playScroll(264)
						end, obj, 100)
					end
				end, obj, (100 * i + 300) / delay)
			end
		end
	end

	local actions = self.items_

	xyd.SoundManager.get():playSound(xyd.SoundID.GAMBLE_REWARDS)

	if not self.huodeWuPinEffect_ then
		local effect = xyd.Spine.new(self.effectRoot_.gameObject)

		effect:setNoStopResumeSetupPose(true)
		effect:setInfo("huodewupin", function ()
			effect:changeAttachment("zi1", self.textImg)
			effect:SetLocalPosition(0, 0, 0)
			effect:SetLocalScale(1, 1, 1)
			effect:setRenderTarget(self.effectRoot_, 1)
			effect:play("texiao01", 1, 1, function ()
				self.huodeWuPinEffect_:stop()
				effect:play("texiao02", 0)
			end)
		end)

		self.huodeWuPinEffect_ = effect
	else
		self.huodeWuPinEffect_:play("texiao01", 1, 1, function ()
			self.huodeWuPinEffect_:stop()
			self.huodeWuPinEffect_:play("texiao02", 0)
		end)
	end

	self:setTimeout(play, actions, 300)
	self:waitForTime(0.31, function ()
		self.itemRoot_:GetComponent(typeof(UIWidget)).alpha = 1
	end)
	self:waitForTime(0.1 * #actions + 1, function ()
		if self.progressValue then
			self:playProgressEffect()
		end
	end)
	self:waitForTime(1, function ()
		if callback then
			callback()
		end
	end)
end

function GambleRewardsWindow:playProgressEffect()
	local frameCount = 1

	if #self.items_ > 5 then
		frameCount = 2
	end

	for i = 1, 5 + frameCount * 5 do
		self:waitForTime(i / 60, function ()
			self.progressBar.value = self.progressLastValue + (self.progressValue - self.progressLastValue) / (5 + frameCount * 5) * i
			self.progressDesc.text = string.format("%0.1f", (self.progressLastValue + (self.progressValue - self.progressLastValue) / (5 + frameCount * 5) * i) * 100) .. "%"
		end)
	end

	local effect = xyd.Spine.new(self.progressEffectNode)

	effect:setInfo("jindutiao_newbee_activity", function ()
		effect:SetLocalPosition(0, 0, 0)
		effect:SetLocalScale(1, 1, 1)

		if not self.showGolden then
			effect:play("texiao01", 1, 1, function ()
				effect:play("texiao02", frameCount, 1, function ()
					effect:play("texiao03", 1)
				end)
			end)
		else
			effect:play("texiao04", 1, 1, function ()
				effect:play("texiao05", frameCount, 1, function ()
					effect:play("texiao06", 1)
				end)
			end)
		end
	end)

	local sequence = self:getSequence()

	sequence:Append(self.progressDesc.transform:DOScale(Vector3(1.3, 1.3, 1.3), 0.08333333333333333))
	sequence:AppendCallback(function ()
		self.progressDesc.text = self.progressText
	end)
	sequence:AppendInterval(frameCount * 5 / 60)
	sequence:Append(self.progressDesc.transform:DOScale(Vector3(1.33, 1.33, 1.33), 0.16666666666666666))
	sequence:Append(self.progressDesc.transform:DOScale(Vector3(1, 1, 1), 0.08333333333333333))
end

function GambleRewardsWindow:willClose()
	GambleRewardsWindow.super.willClose(self)

	if self.huodeWuPinEffect_ then
		self.huodeWuPinEffect_:destroy()

		self.huodeWuPinEffect_ = nil
	end

	if self.curWndType_ == self.WindowType.DRESS then
		local win = xyd.WindowManager.get():getWindow("dress_summon_window")

		if win then
			win:cleardebrisSeq()
		end
	end

	if self.optionalBoxCallBack then
		self.optionalBoxCallBack(self.optionalBoxValue)
	end

	if self.closeCallBackFun then
		self.closeCallBackFun()
	end
end

function GambleRewardsWindow:excuteCallBack(isCloseAll)
	GambleRewardsWindow.super.excuteCallBack(self, isCloseAll)

	if isCloseAll then
		return
	end

	if self.callback_ then
		self.callback_()
	end
end

GambleRewardsWindow.WindowType = {
	GAMBLE = 1,
	ACTIVITY = 4,
	PROPHET = 3,
	DRESS = 5,
	DRAGONBOAT2022 = 7,
	STARRY_ALTAR = 6,
	NORMAL = 2
}

return GambleRewardsWindow
