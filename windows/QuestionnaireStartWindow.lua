local BaseWindow = import(".BaseWindow")
local QuestionnaireStartWindow = class("QuestionnaireStartWindow", BaseWindow)

function QuestionnaireStartWindow:ctor(name, params)
	QuestionnaireStartWindow.super.ctor(self, name, params)

	self.id_ = params.id
	local type = xyd.tables.questionnaireTable:getType(self.id_)

	if type == 2 then
		-- Nothing
	end
end

function QuestionnaireStartWindow:initWindow()
	QuestionnaireStartWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.logo_ = winTrans:ComponentByName("groupAction/logo", typeof(UISprite))
	self.titleLabel_ = winTrans:ComponentByName("groupAction/titleLabel", typeof(UILabel))
	self.startLabel_ = winTrans:ComponentByName("groupAction/startBtn/startLabel", typeof(UILabel))
	self.descLabel_ = winTrans:ComponentByName("groupAction/scroller1/itemList/descLabel", typeof(UILabel))
	self.textImg_ = winTrans:ComponentByName("groupAction/group1/textImg1", typeof(UISprite))
	self.startBtn_ = winTrans:ComponentByName("groupAction/startBtn", typeof(UISprite)).gameObject
	self.closeBtn = winTrans:ComponentByName("groupAction/closeBtn", typeof(UISprite)).gameObject
	self.itemGroup_ = winTrans:NodeByName("groupAction/itemGroup").gameObject

	self:layout()
end

function QuestionnaireStartWindow:layout()
	self:registerEvent()
	self:setLayout()
end

function QuestionnaireStartWindow:registerEvent()
	self:register()

	UIEventListener.Get(self.startBtn_).onClick = handler(self, self.onStartTouch)
end

function QuestionnaireStartWindow:onStartTouch()
	xyd.WindowManager.get():closeWindow("questionnaire_start_window")
	xyd.WindowManager.get():openWindow("questionnaire_window", {
		current_id = self.id_
	})
end

function QuestionnaireStartWindow:setLayout()
	self.titleLabel_.text = __("QUESTIONNAIRE_START_TITLE")
	self.startLabel_.text = __("QUESTIONNAIRE_START")
	self.descLabel_.text = __("QUESTIONNAIRE_TEXT1")
	local awards = nil
	local type = xyd.tables.questionnaireTable:getType(self.id_)

	if type == 1 then
		awards = xyd.tables.miscTable:split2Cost("questionnaire_award", "value", "|#")
	else
		awards = xyd.tables.miscTable:split2Cost("new_questionnaire_award", "value", "|#")
	end

	for i = 1, #awards do
		local icon = xyd.getItemIcon({
			hideText = true,
			itemID = awards[i][1],
			num = awards[i][2],
			uiRoot = self.itemGroup_
		})

		icon:setScale(0.6, 0.6, 0.6)
	end

	self.itemGroup_:GetComponent(typeof(UILayout)):Reposition()
	xyd.setUISpriteAsync(self.textImg_, "qustionnaire_web", "questionnaire_start_text01_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.logo_, "qustionnaire_web", "questionnaire_start_text02_" .. xyd.Global.lang, nil, , true)
end

return QuestionnaireStartWindow
