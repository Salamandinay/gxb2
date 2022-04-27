local BaseWindow = import(".BaseWindow")
local AcademyAssessmentBattleSetWindow = class("AcademyAssessmentBattleSetWindow", BaseWindow)

function AcademyAssessmentBattleSetWindow:ctor(name, params)
	AcademyAssessmentBattleSetWindow.super.ctor(self, name, params)

	self.failEnd = false
	self.ticketEnd = false
	local abbr1 = xyd.db.misc:getValue("academy_assessment_battle_set_fail_end")

	if abbr1 and tonumber(abbr1) ~= 0 then
		self.failEnd = true
	end

	local abbr2 = xyd.db.misc:getValue("academy_assessment_battle_set_ticket_end")

	if abbr2 and tonumber(abbr2) ~= 0 then
		self.ticketEnd = true
	end
end

function AcademyAssessmentBattleSetWindow:initWindow()
	self:getUIComponent()
	AcademyAssessmentBattleSetWindow.super.initWindow(self)
	self:initLayout()
	self:registerEvent()
end

function AcademyAssessmentBattleSetWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.groupAcademyAssessment = groupAction:NodeByName("groupAcademyAssessment").gameObject
	self.labelTitle = self.groupAcademyAssessment:ComponentByName("labelTitle", typeof(UILabel))
	self.btnHelp = self.groupAcademyAssessment:NodeByName("btnHelp").gameObject
	self.option1 = self.groupAcademyAssessment:ComponentByName("option1", typeof(UISprite)).gameObject
	self.imgSelect1 = self.option1:ComponentByName("imgSelect", typeof(UISprite))
	self.labelDesc1 = self.groupAcademyAssessment:ComponentByName("labelDesc1", typeof(UILabel))
	self.option2 = self.groupAcademyAssessment:ComponentByName("option2", typeof(UISprite)).gameObject
	self.imgSelect2 = self.option2:ComponentByName("imgSelect", typeof(UISprite))
	self.labelDesc2 = self.groupAcademyAssessment:ComponentByName("labelDesc2", typeof(UILabel))
end

function AcademyAssessmentBattleSetWindow:initLayout()
	self.labelTitle.text = __("ACADEMY_EXAM_TEXT1")
	self.labelDesc1.text = __("ACADEMY_EXAM_TEXT2")
	self.labelDesc2.text = __("ACADEMY_EXAM_TEXT3")

	if xyd.Global.lang == "fr_fr" then
		self.labelDesc1.width = 390
		self.labelDesc2.width = 390
	end

	if xyd.Global.lang == "de_de" then
		self.labelDesc1.width = 400
		self.labelDesc1.height = 80
		self.labelDesc2.width = 400
	end

	self:updateSelect()
end

function AcademyAssessmentBattleSetWindow:registerEvent()
	AcademyAssessmentBattleSetWindow.super.register(self)

	UIEventListener.Get(self.option1).onClick = function ()
		self.failEnd = not self.failEnd

		if self.failEnd then
			self.ticketEnd = false

			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_ticket_end"
			})
			xyd.db.misc:setValue({
				value = 1,
				key = "academy_assessment_battle_set_fail_end"
			})
		else
			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_fail_end"
			})
		end

		self:updateSelect()
	end

	UIEventListener.Get(self.option2).onClick = function ()
		self.ticketEnd = not self.ticketEnd

		if self.ticketEnd then
			self.failEnd = false

			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_fail_end"
			})
			xyd.db.misc:setValue({
				value = 1,
				key = "academy_assessment_battle_set_ticket_end"
			})
		else
			xyd.db.misc:setValue({
				value = 0,
				key = "academy_assessment_battle_set_ticket_end"
			})
		end

		self:updateSelect()
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "OLD_SCHOOL_HELP1"
		})
	end
end

function AcademyAssessmentBattleSetWindow:updateSelect()
	if self.failEnd then
		self.imgSelect1:SetActive(true)
	else
		self.imgSelect1:SetActive(false)
	end

	if self.ticketEnd then
		self.imgSelect2:SetActive(true)
	else
		self.imgSelect2:SetActive(false)
	end
end

return AcademyAssessmentBattleSetWindow
