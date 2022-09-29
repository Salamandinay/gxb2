local BaseWindow = import(".BaseWindow")
local ActivityPirateStoryWindow = class("ActivityPirateStoryWindow", BaseWindow)

function ActivityPirateStoryWindow:ctor(name, params)
	ActivityPirateStoryWindow.super.ctor(self, name, params)

	self.story_id = params.story_id
end

function ActivityPirateStoryWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivityPirateStoryWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.confirmBtn_ = winTrans:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel_ = winTrans:ComponentByName("confirmBtn/label", typeof(UILabel))
	self.scrollView_ = winTrans:ComponentByName("scrollView", typeof(UIScrollView))
	self.content_ = winTrans:ComponentByName("scrollView/content", typeof(UILabel))
end

function ActivityPirateStoryWindow:layout()
	self.titleLabel_.text = xyd.tables.activityPiratePlotListTextTable:getTitle(self.story_id)
	self.content_.text = xyd.tables.activityPiratePlotListTextTable:getDesc(self.story_id)

	self.scrollView_:ResetPosition()

	self.confirmBtnLabel_.text = __("SURE")

	UIEventListener.Get(self.confirmBtn_).onClick = function ()
		self:close()
	end
end

function ActivityPirateStoryWindow:willClose()
	self.willClose_ = true
	local cjson = require("cjson")
	local params = cjson.encode({
		type = 0,
		story_id = tonumber(self.story_id)
	})

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, params)
end

return ActivityPirateStoryWindow
