local BaseWindow = import(".BaseWindow")
local ItemUseWindow = class("ItemUseWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local SingleWayItem = import("app.components.SingleWayItem")

function ItemUseWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.data = params
	self.itemID = params.itemID or 0
	self.itemNum = params.itemNum or 0
	self.itemType = params.itemType
	self.chosenIndex = params.chosenIndex
	self.chosenId = params.chosenId
	self.showGetWay = params.showGetWay or false
	self.isShowWays = false
	self.curNum_ = math.min(self.itemNum, 1000)
	self.useMaxNum = 1000
	self.usedTotalNum = 0
	self.curUsedNum = 0
	self.allAwards = {}
end

function ItemUseWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function ItemUseWindow:getUIComponent()
	local go = self.window_
	self.groupMain_ = go:ComponentByName("groupMain_", typeof(UIWidget))
	self.groupIcon_ = self.groupMain_:NodeByName("groupIcon_").gameObject
	self.selectNumPos = self.groupMain_:NodeByName("selectNumPos").gameObject
	self.btnUse_ = self.groupMain_:NodeByName("btnUse_").gameObject
	self.btnUse_label = self.btnUse_:ComponentByName("button_label", typeof(UILabel))
	self.btnGetWay_ = self.groupMain_:NodeByName("btnGetWay_").gameObject
	self.labelName_ = self.groupMain_:ComponentByName("labelName_", typeof(UILabel))
	self.loadingComponent = self.groupMain_:NodeByName("loadingComponent").gameObject
	self.loadingEffect = self.loadingComponent:NodeByName("loadingEffect").gameObject
	self.loadingText = self.loadingComponent:ComponentByName("loadingText", typeof(UILabel))
	self.groupWays_ = go:ComponentByName("groupWays_", typeof(UIWidget))
	self.groupWaysTopLeft_ = self.groupWays_:NodeByName("top_left").gameObject
	self.groupWaysList_ = self.groupWaysTopLeft_:ComponentByName("groupWaysList_", typeof(UIWidget))
	self.labelWaysDesc_ = self.groupWaysTopLeft_:ComponentByName("labelWaysDesc_", typeof(UILabel))
end

function ItemUseWindow:initUIComponent()
	local name = xyd.tables.itemTable:getName(self.itemID)
	self.labelName_.text = name
	self.btnUse_label.text = __("USE")

	xyd.labelQulityColor(self.labelName_, self.itemID)

	self.selectNum_ = SelectNum.new(self.selectNumPos, "default")

	self:initIcon()
	self:initTextInput()
	self:setMultilingualText()

	if self.showGetWay then
		self:createWays()
		self.btnGetWay_:SetActive(true)

		self.labelName_.width = 360
	end
end

function ItemUseWindow:initIcon()
	local params = {
		noClick = true,
		uiRoot = self.groupIcon_,
		itemID = self.itemID
	}
	self.icon = xyd.getItemIcon(params)
end

function ItemUseWindow:initTextInput()
	local function callback(num)
		self.curNum_ = num
	end

	self.selectNum_:setInfo({
		maxNum = self.itemNum,
		curNum = math.min(self.itemNum, self.useMaxNum),
		callback = callback
	})
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -350)

	local value = math.min(self:getItemNum(), self.useMaxNum)

	self.selectNum_:setPrompt(value)
	self.selectNum_:setMaxNum(value)

	if self.itemID == xyd.ItemID.DATES_GIFTBAG then
		self.selectNum_:setMaxNum(math.min(self.itemNum, 1000))
		self.selectNum_:setCurNum(math.min(self.itemNum, 1000))

		self.curNum_ = math.min(self.itemNum, 1000)

		return
	end

	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
end

function ItemUseWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnUse_, self, self.useTouch)
	xyd.setDarkenBtnBehavior(self.btnGetWay_, self, self.getWayTouch)
	self.eventProxy_:addEventListener(xyd.event.USE_ITEM, handler(self, self.useCallback))
end

function ItemUseWindow:useTouch()
	if self.itemNum == 0 then
		xyd.showToast(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.itemID)))

		return
	end

	if self.itemType == xyd.ItemType.OPTIONAL_TREASURE_CHEST then
		self:useTouchOptionalTreasureChest()

		return
	end

	if self.itemID == xyd.ItemID.DATES_GIFTBAG then
		if self.useMaxNum < self.curNum_ then
			self.loadingText.text = __("ITEM_GIFTBAG_OPEN_TIPS")
			local effect = xyd.Spine.new(self.loadingEffect)

			effect:setInfo("loading", function ()
				effect:SetLocalScale(0.95, 0.95, 0.95)
				effect:play("idle", 0, 1)
			end)

			self.effect = effect

			self.loadingComponent:SetActive(true)
		end

		self.curUsedNum = math.min(self.useMaxNum, self.curNum_ - self.usedTotalNum)
		self.usedTotalNum = self.usedTotalNum + self.curUsedNum

		xyd.models.backpack:useItem(tonumber(self.itemID), self.curUsedNum)

		return
	end

	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		xyd.models.backpack:useItem(tonumber(self.itemID), self.curNum_)
	end
end

function ItemUseWindow:getWayTouch()
	if self.isShowWays then
		self:hideWays()
	else
		self:showWays()
	end

	self.isShowWays = not self.isShowWays
end

function ItemUseWindow:useTouchOptionalTreasureChest()
	if self.curNum_ > 0 and self.curNum_ <= self.itemNum then
		xyd.models.backpack:useOptionalGiftBox(self.itemID, self.curNum_, self.chosenIndex, self.chosenId)
		self:close()

		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end

		if xyd.WindowManager.get():isOpen("award_select_window") then
			xyd.WindowManager.get():closeWindow("award_select_window")
		end
	end
end

function ItemUseWindow:onUseOptionalGiftBox(event)
	if not self.allAwards[event.data.item_id] then
		self.allAwards[event.data.item_id] = 0
	end

	self.allAwards[event.data.item_id] = self.allAwards[event.data.item_id] + event.data.item_num

	self:hideEffect(function ()
		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end

		if xyd.WindowManager.get():isOpen("award_item_tips_window") then
			xyd.WindowManager.get():closeWindow("award_item_tips_window")
		end

		xyd.closeWindow("item_use_window")
	end)
end

function ItemUseWindow:useCallback(event)
	if tonumber(event.data.used_item_id) == xyd.ItemID.DATES_GIFTBAG then
		for _, data in ipairs(event.data.items) do
			if not self.allAwards[data.item_id] then
				self.allAwards[data.item_id] = 0
			end

			self.allAwards[data.item_id] = self.allAwards[data.item_id] + data.item_num
		end

		if self.usedTotalNum < self.curNum_ then
			self.curUsedNum = math.min(self.useMaxNum, self.curNum_ - self.usedTotalNum)
			self.usedTotalNum = self.usedTotalNum + self.curUsedNum

			xyd.models.backpack:useItem(tonumber(self.itemID), self.curUsedNum)
		else
			self:hideEffect(function ()
				if xyd.WindowManager.get():isOpen("item_tips_window") then
					xyd.WindowManager.get():closeWindow("item_tips_window")
				end

				if xyd.WindowManager.get():isOpen("award_item_tips_window") then
					xyd.WindowManager.get():closeWindow("award_item_tips_window")
				end

				xyd.closeWindow("item_use_window")
			end)
		end
	else
		if xyd.WindowManager.get():isOpen("item_tips_window") then
			xyd.WindowManager.get():closeWindow("item_tips_window")
		end

		if xyd.WindowManager.get():isOpen("award_item_tips_window") then
			xyd.WindowManager.get():closeWindow("award_item_tips_window")
		end

		self:close(function ()
			local items = event.data.items

			if #items > 0 then
				xyd.alertItems(items)
			end
		end)
	end
end

function ItemUseWindow:hideEffect(callback)
	if self.loadingComponent.activeSelf then
		local action = self:getSequence()

		local function setter(value)
			self.loadingComponent:GetComponent(typeof(UIWidget)).alpha = value

			if self.effect and self.effect.spAnim then
				self.effect.spAnim:setAlpha(value)
			end
		end

		action:Append(DG.Tweening.DOTween.To(DG.Tweening.Core.DOSetter_float(setter), 1, 0.01, 1))
		action:AppendCallback(callback)
	else
		callback()
	end
end

function ItemUseWindow:showAwards()
	local items = {}

	for itemId, itemNum in pairs(self.allAwards) do
		table.insert(items, {
			item_id = itemId,
			item_num = itemNum
		})
	end

	if #items > 0 then
		xyd.alertItems(items, nil, , , function (a, b)
			return tonumber(a.item_id) < tonumber(b.item_id)
		end)
	end
end

function ItemUseWindow:didClose()
	if self and self.showAwards then
		self:showAwards()
	end
end

function ItemUseWindow:getItemId()
	return self.itemID
end

function ItemUseWindow:getItemNum()
	return self.itemNum
end

function ItemUseWindow:getCurNum()
	return self.curNum_
end

function ItemUseWindow:createWays()
	self.labelWaysDesc_.text = __("GET_WAYS")
	local ways = xyd.tables.itemTable:getWays(self.itemID)
	local lev = xyd.models.backpack:getLev()
	local params = {}

	for i = 1, #ways do
		local way = ways[i]
		local hideLev = xyd.tables.getWayTable:getHideLv(way)

		if not hideLev or hideLev == 0 or lev <= hideLev then
			table.insert(params, {
				id = way,
				item_id = self.itemID
			})
		end
	end

	self.groupWaysList_.height = #params * 69 + (#params - 1) * 10
	self.groupWays_.height = self.groupWaysList_.height + 108

	for i = 1, #params do
		local wayItem = SingleWayItem.new(self.groupWaysList_.gameObject, params[i])
	end
end

function ItemUseWindow:showWays()
	local mainHeight = self.groupMain_.height
	local mainPos = self.groupMain_.transform.localPosition
	local curY = mainPos.y
	local waysHeight = self.groupWays_.height
	local newY = waysHeight / 2
	local waysPos = self.groupWays_.transform.localPosition
	local go = self.groupMain_.gameObject
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(go.transform:DOLocalMoveY(curY + 10, 0.1))
	sequence:Append(go.transform:DOLocalMoveY(newY - 10, 0.13))
	sequence:Append(go.transform:DOLocalMoveY(newY, 0.13))
	self.groupWays_:SetLocalPosition(waysPos.x, newY - mainHeight / 2, 0)

	self.groupWays_.alpha = 0.5

	self.groupWays_:SetLocalScale(0.5, 0.5, 1)
	self.groupWays_:SetActive(true)

	local sequence2 = DG.Tweening.DOTween.Sequence()
	local waysGO = self.groupWays_.gameObject

	sequence2:Insert(0.1, waysGO.transform:DOScale(1.05, 0.13))

	local function setter(value)
		self.groupWays_.color = value
	end

	local function getter()
		return self.groupWays_.color
	end

	sequence2:Insert(0.1, DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.13))
	sequence:Insert(0.23, waysGO.transform:DOScale(1, 0.2))
end

function ItemUseWindow:hideWays()
	local mainPos = self.groupMain_.transform.localPosition
	local curY = mainPos.y
	local go = self.groupMain_.gameObject
	local waysGO = self.groupWays_.gameObject
	local sequence = DG.Tweening.DOTween.Sequence()

	sequence:Append(waysGO.transform:DOScale(1.05, 0.13))
	sequence:Insert(0.13, waysGO.transform:DOScale(0.5, 0.1))

	local function setter(value)
		self.groupWays_.color = value
	end

	local function getter()
		return self.groupWays_.color
	end

	sequence:Insert(0.13, DG.Tweening.DOTween.ToAlpha(getter, setter, 0.5, 0.1))
	sequence:InsertCallback(0.23, function ()
		self.groupWays_:SetActive(false)
	end)

	local groupMainCurY = 0
	local sequence2 = DG.Tweening.DOTween.Sequence()

	sequence2:AppendInterval(0.1)
	sequence2:Append(go.transform:DOLocalMoveY(curY - 10, 0.13))
	sequence2:Append(go.transform:DOLocalMoveY(groupMainCurY + 10, 0.13))
	sequence2:Append(go.transform:DOLocalMoveY(groupMainCurY, 0.1))
end

function ItemUseWindow:setMultilingualText()
	if (self.itemID == xyd.ItemID.NEWYEAR_WELFARE_GIFTBAG2022 or xyd.ItemID.NEWYEAR_SUPER_GIFTBAG2022) and xyd.Global.lang == "fr_fr" then
		self.labelName_.fontSize = 20
	end
end

return ItemUseWindow
