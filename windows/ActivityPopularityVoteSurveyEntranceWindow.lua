local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSurveyEntranceWindow = class("ActivityPopularityVoteSurveyEntranceWindow", BaseWindow)

function ActivityPopularityVoteSurveyEntranceWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ActivityPopularityVoteSurveyEntranceWindow:initWindow()
	ActivityPopularityVoteSurveyEntranceWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityPopularityVoteSurveyEntranceWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.imgText = self.groupAction:ComponentByName("imgText", typeof(UISprite))
	self.imgLogo = self.groupAction:ComponentByName("imgLogo", typeof(UISprite))
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.labelDesc = self.groupAction:ComponentByName("labelDesc", typeof(UILabel))
	self.labelName = self.groupAction:ComponentByName("labelName", typeof(UILabel))
	self.labelTicket = self.groupAction:ComponentByName("labelTicket", typeof(UILabel))
	self.btnEntrance = self.groupAction:NodeByName("btnEntrance").gameObject
	self.btnEntranceLabel = self.btnEntrance:ComponentByName("button_label", typeof(UILabel))
end

function ActivityPopularityVoteSurveyEntranceWindow:initUIComponent()
	xyd.setUISpriteAsync(self.imgText, nil, "activity_popularity_vote_survey_text_" .. xyd.Global.lang, nil, , true)

	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT01")
	self.labelDesc.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT04")
	self.labelName.text = xyd.tables.partnerTable:getName(51017)
	self.labelTicket.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1")
	self.btnEntranceLabel.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT02")
end

function ActivityPopularityVoteSurveyEntranceWindow:register()
	UIEventListener.Get(self.btnEntrance).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_popularity_vote_survey_main_window")
		self:close()
	end
end

return ActivityPopularityVoteSurveyEntranceWindow
