local SelectNum = import("app.components.SelectNum")
local BaseWindow = import(".BaseWindow")
local AcademyAssessmentBuyWindow = class("AcademyAssessmentBuyWindow", BaseWindow)

function AcademyAssessmentBuyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.purchaseNum = 1
	self.backpack = xyd.models.backpack
	self.itemParams = params.itemParams
end

function AcademyAssessmentBuyWindow:initWindow()
	AcademyAssessmentBuyWindow.super.initWindow(self)
	self:getUIComponents()
	self:setLayout()
	self:registerEvent()
end

function AcademyAssessmentBuyWindow:getUIComponents()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.groupItem = groupMain:NodeByName("groupItem").gameObject
	local selectNumPos = groupMain:NodeByName("selectNum").gameObject
	self.selectNum = SelectNum.new(selectNumPos, "minmax")
	self.btnSure = groupMain:ComponentByName("btnSure", typeof(UISprite))
	self.btnSureLabel = groupMain:ComponentByName("btnSure/btnSureLabel", typeof(UILabel))
	local group2 = groupMain:NodeByName("group2").gameObject
	self.labelTotal = group2:ComponentByName("labelTotal", typeof(UILabel))
	self.labelCost = group2:ComponentByName("labelCost", typeof(UILabel))
end

function AcademyAssessmentBuyWindow:setLayout()
	self.itemParams.uiRoot = self.groupItem
	self.btnSureLabel.text = __("CONFIRM")

	print(self.itemParams.itemID)
	xyd.getItemIcon(self.itemParams)

	self.labelTitle.text = __("ITEM_BUY_WINDOW", xyd.tables.itemTable:getName(self.itemParams.itemID))

	self:updateCostLabel()

	local maxNum = self:getMaxBuyNum()
	local params = {
		minNum = 0,
		curNum = 0,
		maxNum = math.max(maxNum, 10),
		callback = function (num)
			if maxNum <= num then
				xyd.showToast(__("FULL_BUY_SLOT_TIME"))

				num = maxNum
			end

			self.purchaseNum = num

			self.selectNum:setCurNum(num)
			self:updateCostLabel()
		end,
		maxCallback = function ()
			xyd.showToast(__("FULL_BUY_SLOT_TIME"))
		end
	}

	self.selectNum:setInfo(params)
	self.selectNum:setKeyboardPos(0, -360)
	self.selectNum:setPrompt("0")
end

function AcademyAssessmentBuyWindow:getMaxBuyNum()
	local crystal = self.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	local haveBought = xyd.models.academyAssessment:getBuySweepTimes()
	local canBuy = xyd.tables.academyAssessmentCostTable:getIDs() - haveBought

	return canBuy
end

function AcademyAssessmentBuyWindow:getCanBuyNum()
	local crystal = self.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	local haveBought = xyd.models.academyAssessment:getBuySweepTimes()
	local canBuy = xyd.tables.academyAssessmentCostTable:getIDs() - haveBought

	for i = 1, canBuy do
		if crystal < self:getCost(i) then
			return i - 1
		end
	end

	return canBuy
end

function AcademyAssessmentBuyWindow:updateCostLabel()
	local cost = tonumber(self:getCost(self.purchaseNum))
	local total = self.backpack:getItemNumByID(xyd.ItemID.CRYSTAL)
	self.labelCost.text = tostring(xyd.getRoughDisplayNumber(cost))
	self.labelTotal.text = xyd.getRoughDisplayNumber(total)

	if total < cost then
		self.labelTotal.color = Color.New2(3422556671.0)
	else
		self.labelTotal.color = Color.New2(1583978239)
	end
end

function AcademyAssessmentBuyWindow:getCost(num)
	local alreadyBuyTimes = xyd.models.academyAssessment:getBuySweepTimes()
	local cost = 0

	if alreadyBuyTimes == 0 then
		cost = xyd.tables.academyAssessmentCostTable:getCost(self.purchaseNum)
	elseif self.purchaseNum + alreadyBuyTimes <= xyd.tables.academyAssessmentCostTable:getIDs() then
		cost = xyd.tables.academyAssessmentCostTable:getCost(self.purchaseNum + alreadyBuyTimes) - xyd.tables.academyAssessmentCostTable:getCost(alreadyBuyTimes)
	end

	return cost or 0
end

function AcademyAssessmentBuyWindow:registerEvent()
	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.buyItems)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function AcademyAssessmentBuyWindow:buyItems()
	if self.purchaseNum <= 0 then
		return
	end

	local num = self.purchaseNum

	if self:getCanBuyNum() < self.purchaseNum then
		xyd.alert(xyd.AlertType.CONFIRM, __("CRYSTAL_NOT_ENOUGH"), function (yes)
			xyd.closeWindow("academy_assessment_buy_window")
			xyd.openWindow("vip_window")
		end, __("BUY"))

		return
	end

	xyd.models.academyAssessment:reqBuyTickets(xyd.SchoolTicketType.SWEEP, num)
	xyd.closeWindow("academy_assessment_buy_window")
end

return AcademyAssessmentBuyWindow
