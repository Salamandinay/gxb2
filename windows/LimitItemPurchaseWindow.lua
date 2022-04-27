function __TS__FunctionBind(fn, thisArg, ...)
	local boundArgs = {
		...
	}

	return function (____, ...)
		local argArray = {
			...
		}
		local i = 0

		while i < #boundArgs do
			table.insert(argArray, i + 1, boundArgs[i + 1])

			i = i + 1
		end

		return fn(thisArg, unpack or table.unpack(argArray))
	end
end

local BaseWindow = import(".BaseWindow")
local LimitItemPurchaseWindow = class("LimitItemPurchaseWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function LimitItemPurchaseWindow:ctor(name, params)
	LimitItemPurchaseWindow.super.ctor(self, name, params)

	self.purchaseNum = 0
	self.skinName = "ItemPurchaseWindowSkin"
	self.backpack = xyd.models.backpack
	self.buyType = params.buyType
	self.buyNum = params.buyNum
	self.costType = params.costType
	self.costNum = params.costNum
	self.purchaseCallback = params.purchaseCallback
	self.titleKey = params.titleKey
	self.titleWords = params.titleWords
	self.limitNum = params.limitNum
	self.maxNum = params.maxNum
	self.notEnoughKey = params.notEnoughKey
	self.eventType = params.eventType or xyd.event.BOSS_BUY
	self.showWindowCallback = params.showWindowCallback
	self.limitKey = params.limitKey or ""
	self.needTips = params.needTips
	self.calPriceCallback = params.calPriceCallback
	self.maxCallback = params.maxCallback
	self.hasMaxMin = params.hasMaxMin
	self.onlyShowLimitTip = params.onlyShowLimitTip
	self.notShowNum = params.notShowNum
	self.maxCanBuy = params.maxCanBuy
	self.confirmText = params.confirmText or __("BUY")
	self.imgExchangeWidth = params.imgExchangeWidth
	self.imgExchangeHeight = params.imgExchangeHeight
	self.descLabel = params.descLabel

	if not self.calPriceCallback then
		function self.calPriceCallback(num)
			return tonumber(num) * self.costNum
		end
	end
end

function LimitItemPurchaseWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()
end

function LimitItemPurchaseWindow:getUIComponent()
	local winTrans = self.window_.transform
	local allGroup = winTrans:NodeByName("groupAction").gameObject
	self.bgImg = allGroup:NodeByName("e:Image").gameObject
	self.bgImg2 = allGroup:NodeByName("e:Image2").gameObject
	local upGroup = allGroup:NodeByName("upGroup").gameObject
	self.labelTitle = upGroup:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = upGroup:NodeByName("closeBtn").gameObject
	self.groupItem = allGroup:NodeByName("groupItem").gameObject
	self.textInputCon = allGroup:NodeByName("textInput").gameObject
	self.btnSure = allGroup:NodeByName("btnSure").gameObject
	self.btnSure_button_label = allGroup:ComponentByName("btnSure/button_label", typeof(UILabel))
	self.numGroup = allGroup:NodeByName("numGroup").gameObject
	self.ImgExchange = allGroup:ComponentByName("numGroup/ImgExchange", typeof(UISprite))
	self.labelTotal = allGroup:ComponentByName("numGroup/labelTotal", typeof(UILabel))
	self.labelSplit = allGroup:ComponentByName("numGroup/labelSplit", typeof(UILabel))
	self.labelCost = allGroup:ComponentByName("numGroup/labelCost", typeof(UILabel))
	self.labelDesc = allGroup:ComponentByName("labelDesc", typeof(UILabel))
end

function LimitItemPurchaseWindow:setLayout()
	if self.imgExchangeWidth then
		self.ImgExchange.width = self.imgExchangeWidth
	end

	if self.imgExchangeHeight then
		self.ImgExchange.height = self.imgExchangeHeight
	end

	local icon = xyd.getItemIcon({
		itemID = self.buyType,
		num = self.buyNum,
		uiRoot = self.groupItem.gameObject
	})

	if self.costType then
		xyd.setUISpriteAsync(self.ImgExchange, nil, tostring(xyd.tables.itemTable:getIcon(self.costType)), nil, )
	end

	self.btnSure_button_label.text = __("SURE")

	if self.titleWords == nil then
		self.labelTitle.text = __(self.titleKey)
	else
		self.labelTitle.text = self.titleWords
	end

	if self.notShowNum then
		self.numGroup:SetActive(false)
		self.bgImg:SetActive(false)
		self.bgImg2:SetActive(true)
		self.btnSure:Y(-107.5)
	else
		self.labelCost.text = tostring(xyd.getRoughDisplayNumber(self.calPriceCallback(self.purchaseNum)))

		if self.costType then
			self.labelTotal.text = tostring(xyd.getRoughDisplayNumber(self.backpack:getItemNumByID(self.costType)))
		end
	end

	if self.hasMaxMin then
		self.selectNum = SelectNum.new(self.textInputCon, "minmax", {})

		self.selectNum:setMaxAndMinBtnPos(234)
	else
		self.selectNum = SelectNum.new(self.textInputCon, "default", {})
	end

	self.selectNum:setKeyboardPos(0, -357)

	local curNum_ = 1

	if self.maxCanBuy and self.maxCanBuy == 0 or tostring(self.backpack:getItemNumByID(self.costType)) == 0 then
		self.purchaseNum = 0
	else
		self.purchaseNum = 1
	end

	local maxNum = nil

	if self.maxNum then
		maxNum = self.maxNum
	elseif self.costType and self.costNum then
		maxNum = math.min(math.floor(self.backpack:getItemNumByID(self.costType) / self.costNum), self.limitNum)
	end

	if self.notShowNum then
		maxNum = self.maxCanBuy
	end

	if self.costType and self.costType == 92 and self.buyType == 111 then
		curNum_ = self.backpack:getItemNumByID(self.costType)
	end

	print("maxNum", maxNum)

	local text1 = self.notEnoughKey

	if self.limitKey and self.onlyShowLimitTip then
		text1 = self.limitKey
	end

	self.selectNum:setInfo({
		minNum = 1,
		maxNum = maxNum,
		curNum = curNum_,
		maxCallback = function ()
			if self.showWindowCallback then
				xyd.WindowManager.get():openWindow("alert_window", {
					alertType = xyd.AlertType.CONFIRM,
					message = __(text1),
					callback = function (yes)
						if yes then
							self:showWindowCallback()
						end
					end,
					confirmText = self.confirmText
				})
				self:updateLayout()
			elseif self.maxCallback then
				self.maxCallback()
			end
		end,
		isTouchMaxCallback = function ()
			self.isTouchMax = true
		end,
		callback = function (num)
			self.purchaseNum = num

			self:updateLayout()
		end
	})
	self.selectNum:setCurNum(curNum_)

	if self.descLabel then
		self.labelDesc.text = self.descLabel

		self.labelDesc.gameObject:SetActive(true)
		self.btnSure:Y(-142.5)
	end
end

function LimitItemPurchaseWindow:registerEvent()
	LimitItemPurchaseWindow.super.register(self)

	self.btnSure_button_label.text = __("CONFIRM")
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.onTouch)

	self.eventProxy_:addEventListener(self.eventType, self.onBuy, self)
end

function LimitItemPurchaseWindow:onTouch(evt)
	if not self.purchaseCallback then
		return
	end

	self.purchaseCallback(evt, self.purchaseNum)
end

function LimitItemPurchaseWindow:updateLayout()
	if self.limitNum < self.purchaseNum then
		self.selectNum:setCurNum(self.limitNum)

		self.purchaseNum = self.limitNum

		if xyd.WindowManager.get():isOpen("alert_window") == true then
			xyd.WindowManager.get():closeWindow("alert_window")
		end

		if not self.isTouchMax then
			xyd.showToast(__("ACTIVITY_WORLD_BOSS_LIMIT"))
		else
			self.isTouchMax = nil
		end
	elseif self.costType and self.backpack:getItemNumByID(self.costType) < self.calPriceCallback(self.purchaseNum) then
		local real_num = self:getRealNum()

		if self.showWindowCallback then
			self.labelTotal.color = Color.New2(3422556671.0)
		else
			self.selectNum:setCurNum(real_num)

			self.purchaseNum = real_num
		end
	elseif self.purchaseNum <= 0 then
		self.selectNum:setCurNum(0)

		self.purchaseNum = 0
		self.labelTotal.color = Color.New2(1583978239)
	else
		self.labelTotal.color = Color.New2(1583978239)
	end

	if not self.notShowNum then
		self.labelCost.text = tostring(xyd.getRoughDisplayNumber(self.calPriceCallback(self.purchaseNum)))
	end
end

function LimitItemPurchaseWindow:onBuy(event)
	xyd.WindowManager.get():closeWindow(self.name_)

	if self.needTips then
		xyd.WindowManager.get():openWindow("alert_window", {
			alertType = xyd.AlertType.TIPS,
			message = __("PURCHASE_SUCCESS")
		})
	end
end

function LimitItemPurchaseWindow:getRealNum()
	local num = 0
	local l = 0
	local r = self.limitNum
	local sum = self.backpack:getItemNumByID(self.costType)

	while l <= r do
		local mid = math.floor((l + r) / 2)

		if self.calPriceCallback(mid) <= sum then
			l = mid + 1
			num = math.max(num, mid)
		else
			r = mid - 1
		end
	end

	return num
end

local ActivityJigsawPurchaseWindow = class("ActivityJigsawPurchaseWindow", LimitItemPurchaseWindow)

function ActivityJigsawPurchaseWindow:ctor(name, params)
	LimitItemPurchaseWindow.ctor(self, name, params)

	self.textArray = {}
	self.textArray = params.textArray
	self.skinName = "ActivityJigsawPurchaseWindowSkin"
end

function ActivityJigsawPurchaseWindow:createChildren()
	LimitItemPurchaseWindow.createChildren(self)
	self:setLabelText()
end

function ActivityJigsawPurchaseWindow:setLabelText()
	local i = 0

	while i < #self.textArray do
		self["textLabel" .. tostring(i)].text = self.textArray[i + 1]
		i = i + 1
	end
end

return LimitItemPurchaseWindow
