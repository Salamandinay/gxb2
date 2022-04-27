local BaseWindow = import(".BaseWindow")
local DailyQuizGetWindow = class("DailyQuizGetWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function DailyQuizGetWindow:ctor(name, params)
	self.quiz_id = params.quiz_id
	self.leftTimes = params.leftTimes
	self.purchaseNum = 1

	BaseWindow.ctor(self, name, params)
end

function DailyQuizGetWindow:getUIComponent()
	local trans = self.window_.transform
	local groupMain = trans:NodeByName("groupAction").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelDesc_ = groupMain:ComponentByName("labelDesc_", typeof(UILabel))
	self.btnSure = groupMain:ComponentByName("btnSure", typeof(UISprite))
	self.btnSureLabel = self.btnSure:ComponentByName("btnSureLabel", typeof(UILabel))
	self.selectNumPos = groupMain:NodeByName("selectNum").gameObject
	self.selectNum = SelectNum.new(self.selectNumPos, "minmax")
	self.labelLeft = groupMain:ComponentByName("labelLeft", typeof(UILabel))
end

function DailyQuizGetWindow:initWindow()
	DailyQuizGetWindow.super.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:registerEvent()
end

function DailyQuizGetWindow:setLayout()
	self.labelDesc_.text = __("DAILY_QUIZ_TEXT02")
	self.btnSureLabel.text = __("SURE")
	self.labelTitle.text = __("GET2")
	local params = {
		minNum = 1,
		curNum = self.leftTimes,
		maxNum = self.leftTimes,
		callback = function (input)
			self.purchaseNum = input

			self:updateLayout()
		end
	}

	self.selectNum:setInfo(params)
	self.selectNum:setFontSize(26)
	self.selectNum:setBtnPos(112)
	self.selectNum:setMaxAndMinBtnPos(186)
	self.selectNum:setKeyboardPos(0, -370)
	self.selectNum:setSelectBGSize(140, 40)
end

function DailyQuizGetWindow:registerEvent()
	DailyQuizGetWindow.super.register(self)

	UIEventListener.Get(self.btnSure.gameObject).onClick = handler(self, self.buyTouch)
end

function DailyQuizGetWindow:updateLayout()
	self.labelLeft.text = __("DAILY_QUIZ_LEFT_COUNT") .. self.leftTimes .. "/" .. self.purchaseNum
end

function DailyQuizGetWindow:buyTouch()
	xyd.models.dailyQuiz:reqSweep(self.quiz_id, self.purchaseNum)
	self:close()
end

return DailyQuizGetWindow
