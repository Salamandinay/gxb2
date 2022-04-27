local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSurveyMainWindow = class("ActivityPopularityVoteSurveyMainWindow", BaseWindow)
local skinName = {
	"ACTIVITY_POPULARITY_VOTE_SURVEYTEXT05",
	"ACTIVITY_POPULARITY_VOTE_SURVEYTEXT06",
	"ACTIVITY_POPULARITY_VOTE_SURVEYTEXT07",
	"ACTIVITY_POPULARITY_VOTE_SURVEYTEXT08"
}
local skinURL = {
	"activity_popularity_vote_survey_skin43_4",
	"activity_popularity_vote_survey_skin43_2",
	"activity_popularity_vote_survey_skin43_3",
	"activity_popularity_vote_survey_skin43_1"
}
local skinURL_Big = {
	"activity_popularity_vote_survey_skin4",
	"activity_popularity_vote_survey_skin2",
	"activity_popularity_vote_survey_skin3",
	"activity_popularity_vote_survey_skin1"
}

function ActivityPopularityVoteSurveyMainWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.chooseIndex = 0
end

function ActivityPopularityVoteSurveyMainWindow:initWindow()
	ActivityPopularityVoteSurveyMainWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function ActivityPopularityVoteSurveyMainWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	local groupMain = groupAction:NodeByName("groupMain").gameObject

	for i = 1, 4 do
		local groupOption = groupMain:NodeByName("groupOption" .. i).gameObject
		self["imgSkin" .. i] = groupOption:ComponentByName("imgSkin", typeof(UISprite))
		self["imgUnSelect" .. i] = groupOption:NodeByName("imgUnSelect").gameObject
		self["imgSelect" .. i] = self["imgUnSelect" .. i]:NodeByName("imgSelect").gameObject
		self["labelOption" .. i] = groupOption:ComponentByName("labelOption", typeof(UILabel))
		self["clickArea" .. i] = groupOption:NodeByName("clickArea").gameObject
	end

	self.btnVote = groupAction:NodeByName("btnVote").gameObject
	self.btnVoteLabel = self.btnVote:ComponentByName("button_label", typeof(UILabel))
end

function ActivityPopularityVoteSurveyMainWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT13")
	self.btnVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT09")

	for i = 1, 4 do
		xyd.setUISpriteAsync(self["imgSkin" .. i], nil, skinURL[i], nil, , true)

		self["labelOption" .. i].text = __(skinName[i])
	end

	self:updateSelect()
end

function ActivityPopularityVoteSurveyMainWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	UIEventListener.Get(self.btnVote).onClick = function ()
		if self.chooseIndex == 0 then
			xyd.alertTips(__("ACTIVITY_POPULARITY_VOTE_SURVEYTEXT12"))

			return
		end

		local params = {
			select_id = self.chooseIndex
		}
		local msg = messages_pb.get_activity_award_req()
		msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE_SURVEY
		msg.params = require("cjson").encode(params)

		xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
	end

	for i = 1, 4 do
		UIEventListener.Get(self["clickArea" .. i]).onClick = function ()
			self.chooseIndex = i

			self:updateSelect()
		end

		UIEventListener.Get(self["imgSkin" .. i].gameObject).onClick = function ()
			xyd.WindowManager.get():openWindow("activity_popularity_vote_survey_skin_window", {
				skinName = skinName[i],
				skinURL = skinURL_Big[i]
			})
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function ()
		local mainWindow = xyd.WindowManager.get():getWindow("main_window")

		mainWindow:CheckExtraActBtn()
		xyd.WindowManager.get():openWindow("activity_popularity_vote_survey_end_window")
		self:close()
	end)
end

function ActivityPopularityVoteSurveyMainWindow:updateSelect()
	for i = 1, 4 do
		self["imgSelect" .. i]:SetActive(i == self.chooseIndex)
	end
end

return ActivityPopularityVoteSurveyMainWindow
