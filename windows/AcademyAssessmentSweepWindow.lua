local BaseWindow = import(".BaseWindow")
local AcademyAssessmentSweepWindow = class("AcademyAssessmentSweepWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")

function AcademyAssessmentSweepWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curNum_ = 1
	self.id_ = params.id
	self.fortId_ = params.fort_id
end

function AcademyAssessmentSweepWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupMain = winTrans:NodeByName("groupMain").gameObject
	self.labelTitle = groupMain:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupMain:ComponentByName("closeBtn", typeof(UISprite)).gameObject
	self.labelTips_ = groupMain:ComponentByName("labelTips_", typeof(UILabel))
	local selectNum = groupMain:NodeByName("selectNum_").gameObject
	self.selectNum_ = SelectNum.new(selectNum, "default")
	self.btnSure_ = groupMain:ComponentByName("btnSure_", typeof(UISprite))
	self.btnSureLabel = self.btnSure_:ComponentByName("btnSureLabel", typeof(UILabel))
	local group1 = groupMain:NodeByName("group1").gameObject
	self.labelNum_ = group1:ComponentByName("labelNum_", typeof(UILabel))
end

function AcademyAssessmentSweepWindow:initWindow()
	AcademyAssessmentSweepWindow.super.initWindow(self)
	self:getUIComponent()
	self:layout()
	self:initSelectNum()
	self:registerEvent()
end

function AcademyAssessmentSweepWindow:layout()
	self.btnSureLabel.text = __("FRIEND_SWEEP")
	self.labelTitle.text = __("ACADEMY_ASSESSMENT_SWEEP_WINDOW")
	self.labelTips_.text = __("ACADEMY_ASSESSMENT_SWEEP_TIPS")
end

function AcademyAssessmentSweepWindow:initSelectNum()
	local function callback(num)
		self.curNum_ = num
		self.labelNum_.text = tostring(self.curNum_)
	end

	local num = xyd.models.academyAssessment:getSweepTimes()

	self.selectNum_:setInfo({
		minNum = 1,
		maxNum = num,
		callback = callback
	})
	self.selectNum_:setPrompt(num)
	self.selectNum_:setKeyboardPos(0, -370)
end

function AcademyAssessmentSweepWindow:registerEvent()
	AcademyAssessmentSweepWindow.super.register(self)

	UIEventListener.Get(self.btnSure_.gameObject).onClick = handler(self, self.onSure)
end

function AcademyAssessmentSweepWindow:onSure()
	local fightParams = {
		mapType = xyd.MapType.ACADEMY_ASSESSMENT,
		battleID = self.id_,
		fortID = self.fortId_,
		battleType = xyd.BattleType.ACADEMY_ASSESSMENT,
		num = self.curNum_
	}

	xyd.models.academyAssessment:reqSweep(self.id_, tonumber(self.selectNum_.curNum_))
	xyd.WindowManager:get():closeWindow("academy_assessment_sweep_window")
end

return AcademyAssessmentSweepWindow
