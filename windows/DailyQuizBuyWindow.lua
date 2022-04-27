local BaseWindow = import(".BaseWindow")
local DailyQuizBuyWindow = class("DailyQuizBuyWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function DailyQuizBuyWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.purchaseNum = 1
	self.quizType = 1
	self.buyTimes = 0
	self.backpack = xyd.models.backpack
	self.quizType = params.quiz_type
	self.buyTimes = params.buy_times
end

function DailyQuizBuyWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelDesc_ = groupMain:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnSure = groupMain:ComponentByName("btnSure", typeof(UISprite))
	self.btnSureLabel = self.btnSure:ComponentByName("btnSureLabel", typeof(UILabel))
	self.selectNumPos = groupMain:NodeByName("selectNum").gameObject
	self.selectNum = SelectNum.new(self.selectNumPos, "minmax")
	local groupCost = groupMain:NodeByName("groupCost").gameObject
	self.labelTotal = groupCost:ComponentByName("labelTotal", typeof(UILabel))
	self.labelSplit = groupCost:ComponentByName("labelSplit", typeof(UILabel))
	self.labelCost = groupCost:ComponentByName("labelCost", typeof(UILabel))
end

function DailyQuizBuyWindow:initWindow()
	DailyQuizBuyWindow.super.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()
end

function DailyQuizBuyWindow:setLayout()
	self.btnSureLabel.text = __("CONFIRM")
	self.labelDesc_.text = __("DAILY_QUIZ_BUY_DETAILS")
	self.btnSureLabel.text = __("SURE")
	local cost = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = cost[1]
	local costNum = cost[2]
	self.labelTitle.text = __("DAILY_QUIZ_BUY_WINDOW")
	self.labelCost.text = xyd.getRoughDisplayNumber(costNum * self.purchaseNum)
	self.labelTotal.text = xyd.getRoughDisplayNumber(self.backpack:getItemNumByID(costItemID))
	local vip = self.backpack:getVipLev()
	local buyTimes = self.buyTimes
	local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)
	local maxCanBuy = maxBuyTimes - buyTimes
	local params = {
		curNum = 1,
		maxNum = self:getMaxCanBuy(),
		callback = function (input)
			self.purchaseNum = input
			local maxCanBuy = self:getMaxCanBuy()

			if maxCanBuy < self.purchaseNum then
				self.purchaseNum = maxCanBuy

				self.textInput:setCurNum(maxCanBuy)
				xyd.alert(xyd.AlertType.TIPS, __("DAILY_QUIZ_BUY_TIPS_1", vip, maxBuyTimes))
			end

			self:updateLayout()
		end
	}

	self.selectNum:setInfo(params)
	self.selectNum:setPrompt(1)
	self.selectNum:setKeyboardPos(0, -370)
end

function DailyQuizBuyWindow:getMaxCanBuy()
	local vip = self.backpack:getVipLev()
	local buyTimes = self.buyTimes
	local maxBuyTimes = xyd.tables.vipTable:getQuizBuyTimes(vip)
	local maxCanBuy = maxBuyTimes - buyTimes

	return maxCanBuy
end

function DailyQuizBuyWindow:registerEvent()
	DailyQuizBuyWindow.super.register(self)

	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.buyTouch)
end

function DailyQuizBuyWindow:updateLayout()
	local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = costs[1]
	local costNum = costs[2]
	self.labelCost.text = xyd.getRoughDisplayNumber(costNum * self.purchaseNum)
	local total = self.backpack:getItemNumByID(costItemID)

	if total < costNum * self.purchaseNum then
		self.labelTotal.color = Color.New2(3422556671.0)
	else
		self.labelTotal.color = Color.New2(1583978239)
	end
end

function DailyQuizBuyWindow:buyTouch()
	if not self.purchaseNum then
		return
	end

	local costs = xyd.split(xyd.tables.miscTable:getVal("quiz_buy_cost"), "#", true)
	local costItemID = costs[1]
	local costNum = costs[2]

	if xyd.isItemAbsence(costItemID, costNum * self.purchaseNum) then
		return
	end

	xyd.models.dailyQuiz:reqBuy(self.quizType, self.purchaseNum)

	self.purchaseNum = 0

	xyd.WindowManager:get():closeWindow("daily_quiz_buy_window")
end

return DailyQuizBuyWindow
