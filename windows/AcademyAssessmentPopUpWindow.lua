local BaseWindow = import(".BaseWindow")
local AcademyAssessmentPopUpWindow = class("AcademyAssessmentPopUpWindow", BaseWindow)

function AcademyAssessmentPopUpWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.fort_id = params.fort_id

	if not self.fort_id then
		self.fort_id = 1
	end
end

function AcademyAssessmentPopUpWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
end

function AcademyAssessmentPopUpWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.imageBg = self.groupAction:ComponentByName("allCon/imageBg", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.imageBg, "academy_assessment_pop_up_bg", true)

	self.imagePerson = self.groupAction:ComponentByName("allCon/imagePerson", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.imagePerson, "academy_assessment_pop_up_girls_" .. self.fort_id, true)

	self.imageTextBg = self.groupAction:ComponentByName("allCon/imageTextBg", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.imageTextBg, "academy_assessment_pop_up_title_bg", true)

	self.imageTitle = self.groupAction:ComponentByName("allCon/imageTextBg/imageTitle", typeof(UITexture))

	xyd.setUITextureByNameAsync(self.imageTitle, "academy_assessment_pop_up_logo_" .. xyd.Global.lang, true)
end

function AcademyAssessmentPopUpWindow:closeSelf(callBack)
	self.sequence = DG.Tweening.DOTween.Sequence()

	self.sequence:Append(self.groupAction.transform:DOScale(Vector3(0, 0, 0), 0.2))
	self.sequence:AppendCallback(function ()
		self.sequence:Kill(true)
		xyd.WindowManager.get():closeWindow(self.name_, callBack)
	end)
end

return AcademyAssessmentPopUpWindow
