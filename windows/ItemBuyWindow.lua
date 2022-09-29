local BaseWindow = import(".BaseWindow")
local ItemBuyWindow = class("ItemBuyWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function ItemBuyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.backpack_ = xyd.models.backpack
	self.cost_ = params.cost
	self.maxNum_ = params.max_num
	self.itemParams_ = params.itemParams
	self.buyCallBack = params.buyCallback
	self.maxCallback = params.maxCallback
	self.data = params
	self.ifHideMinMax = params.hide_min_max or false
	self.ifShowItemNum = params.show_item_num or false
	self.curNum_ = 1
	self.purchaseNum_ = 1
	self.itemNoClick = xyd.checkCondition(params.item_no_click == nil, true, params.item_no_click)
	self.showGetWays = xyd.checkCondition(params.showGetWays == nil, nil, params.showGetWays)
	self.limitText = xyd.checkCondition(params.limitText == nil, nil, params.limitText)
	self.wndType = xyd.checkCondition(params.wndType == nil, nil, params.wndType)
end

function ItemBuyWindow:initWindow()
	ItemBuyWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:registerEvent()
end

function ItemBuyWindow:getUIComponent()
	local go = self.window_
	self.groupIcon_ = go:NodeByName("groupAction/groupIcon_").gameObject
	self.selectNumPos = go:NodeByName("groupAction/selectNumPos").gameObject
	self.btnBuy_ = go:NodeByName("groupAction/btnBuy_").gameObject
	self.btnBuy_label = go:ComponentByName("groupAction/btnBuy_/button_label", typeof(UILabel))
	self.labelName_ = go:ComponentByName("groupAction/labelName_", typeof(UILabel))
	self.bg06_ = go:NodeByName("groupAction/bg06")
	self.labelTotalVal_ = go:ComponentByName("groupAction/bg06/labelTotalVal_", typeof(UILabel))
	self.imgCost_ = go:ComponentByName("groupAction/bg06/imgCost", typeof(UISprite))
	self.closeBtn = go:ComponentByName("groupAction/closeBtn", typeof(UISprite)).gameObject
	self.limitLabel = go:ComponentByName("groupAction/limitLabel", typeof(UILabel))
end

function ItemBuyWindow:initUIComponent()
	if self.ifHideMinMax then
		self.textInput_ = SelectNum.new(self.selectNumPos, "default")
	else
		self.textInput_ = SelectNum.new(self.selectNumPos, "minmax")
	end

	local params = nil
	params = {
		uiRoot = self.groupIcon_,
		itemID = self.itemParams_.itemID,
		num = self.itemParams_.num,
		noClick = self.itemNoClick
	}

	if self.exchangeNum_ then
		params.num = self.exchangeNum_
	end

	if self.ifShowItemNum and self.itemParams_.num then
		params.num = self.itemParams_.num
	end

	if self.showGetWays ~= nil then
		params.showGetWays = self.showGetWays
	end

	if self.wndType ~= nil then
		params.wndType = self.wndType
	end

	self.icon = xyd.getItemIcon(params)
	local name = xyd.tables.itemTable:getName(self.itemParams_.itemID)
	self.btnBuy_label.text = __("CONFIRM")
	local costs = self.cost_
	local costItemID = tonumber(costs[1])
	local costNum = tonumber(costs[2])
	local itemName = xyd.tables.itemTable:getSmallIcon(costItemID)

	xyd.setUISpriteAsync(self.imgCost_, nil, itemName)

	self.labelName_.text = __("ITEM_BUY_WINDOW", name)
	local costNow = xyd.getRoughDisplayNumber(costNum * self.purchaseNum_)
	local total = xyd.getRoughDisplayNumber(self.backpack_:getItemNumByID(costItemID))
	self.labelTotalVal_.text = total .. "/" .. costNow
	local params = {
		minNum = 1,
		curNum = 1,
		callback = function (input)
			local totalCoin = self.backpack_:getItemNumByID(costItemID)
			local maxCanBuy = math.floor(totalCoin / costNum)

			if self.maxNum_ then
				maxCanBuy = math.min(self.maxNum_, maxCanBuy)
			end

			if maxCanBuy and maxCanBuy > 0 and maxCanBuy <= self.purchaseNum_ and self.purchaseNum_ <= input then
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))
			end

			self.purchaseNum_ = tonumber(input)

			self:updateLayout()
		end,
		addCallback = function ()
			local totalCoin = self.backpack_:getItemNumByID(costItemID)
			local maxCanBuy = math.floor(totalCoin / costNum)

			if self.maxNum_ then
				maxCanBuy = math.min(self.maxNum_, maxCanBuy)
			end

			if maxCanBuy and maxCanBuy > 0 and maxCanBuy < self.purchaseNum_ then
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))
			end
		end
	}
	local totalCoin = self.backpack_:getItemNumByID(costItemID)
	local maxCanBuy = math.floor(totalCoin / costNum)

	if self.maxNum_ and self.maxNum_ >= 0 then
		params.maxNum = self.maxNum_
	else
		params.maxNum = maxCanBuy
	end

	params.maxCanBuyNum = maxCanBuy

	if self.maxCallback then
		params.maxCallback = self.maxCallback
	end

	if self.maxNum_ and math.min(self.maxNum_, maxCanBuy) == 1 then
		params.notCallback = true
	elseif maxCanBuy == 1 then
		params.notCallback = true
	end

	self.textInput_:setPrompt(1)

	self.purchaseNum_ = 1

	self:updateLayout()
	self.textInput_:setInfo(params)
	self.textInput_:setFontSize(26, 26)
	self.textInput_:setKeyboardPos(0, -350)
	self.textInput_:setSelectBG2(true)
	self.bg06_:SetLocalPosition(0, -90, 0)

	if self.limitText then
		self.limitLabel.text = self.limitText

		self.groupIcon_:Y(97)
		self.selectNumPos:Y(-2.5)
		self.bg06_:Y(-68)
		self.limitLabel:Y(-105)
		self.limitLabel:SetActive(true)
	else
		self.limitLabel:SetActive(false)
	end
end

function ItemBuyWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnBuy_, self, self.exchangeItemRequest)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ItemBuyWindow:updateLayout()
	local costs = self.cost_
	local costItemID = tonumber(costs[1])
	local costNum = tonumber(costs[2])
	local costNow = costNum * self.purchaseNum_
	local total = self.backpack_:getItemNumByID(costItemID)
	self.labelTotalVal_.text = xyd.getRoughDisplayNumber(total) .. "/" .. xyd.getRoughDisplayNumber(costNow)

	if total < costNow then
		self.labelTotalVal_.color = Color.New2(3422556671.0)
	else
		self.labelTotalVal_.color = Color.New2(1583978239)
	end
end

function ItemBuyWindow:exchangeItemRequest()
	if not self.purchaseNum_ then
		return
	end

	local costs = self.cost_
	local costItemID = tonumber(costs[1])
	local costNum = tonumber(costs[2])

	if self.backpack_:getItemNumByID(costItemID) < costNum * self.purchaseNum_ then
		if costItemID == xyd.ItemID.CRYSTAL then
			xyd.alertConfirm(__("CRYSTAL_NOT_ENOUGH"), function (yes)
				xyd.WindowManager.get():closeWindow("item_buy_window")
				xyd.WindowManager.get():openWindow("vip_window")
			end, __("BUY"))

			return
		else
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(costItemID)))

			return
		end
	end

	if self.buyCallBack then
		self.buyCallBack(self.purchaseNum_)
	end

	self.purchaseNum_ = 0

	if self.skipClose then
		self.skipClose = nil

		return
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

return ItemBuyWindow
