local ActivityEnconterStoryExplainWindow = class("ActivityEnconterStoryExplainWindow", import(".BaseWindow"))

function ActivityEnconterStoryExplainWindow:ctor(name, params)
	ActivityEnconterStoryExplainWindow.super.ctor(self, name, params)

	self.text_id = params.text_id
end

function ActivityEnconterStoryExplainWindow:initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function ActivityEnconterStoryExplainWindow:getUIComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.title = self.groupAction:ComponentByName("title", typeof(UILabel))
	self.backBtn = self.groupAction:NodeByName("backBtn").gameObject
	self.bg2 = self.groupAction:ComponentByName("bg2", typeof(UISprite))
	self.explainText = self.groupAction:ComponentByName("explainText", typeof(UILabel))
end

function ActivityEnconterStoryExplainWindow:layout()
	self.title.text = xyd.tables.activityEncounterStoryTextTable:getTitle(self.text_id)
	self.explainText.text = xyd.tables.activityEncounterStoryTextTable:getText(self.text_id)

	self:waitForFrame(2, function ()
		self.groupAction:Y(-self.bg.gameObject.transform.localPosition.y)
	end)
end

function ActivityEnconterStoryExplainWindow:registerEvent()
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		self:close()
	end)
end

return ActivityEnconterStoryExplainWindow
