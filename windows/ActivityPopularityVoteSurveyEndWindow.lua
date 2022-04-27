local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSurveyEndWindow = class("ActivityPopularityVoteSurveyEndWindow", BaseWindow)

function ActivityPopularityVoteSurveyEndWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityPopularityVoteSurveyEndWindow:initWindow()
	ActivityPopularityVoteSurveyEndWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.labelTip = self.groupAction:ComponentByName("labelTip", typeof(UILabel))
	self.labelDesc.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT11")
	self.labelTip.text = __("STAGE_ACHIEVEMENT_WINDOW_CLOSE")
end

return ActivityPopularityVoteSurveyEndWindow
