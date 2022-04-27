local ActivityCrystalBall = class("ActivityCrystalBall", import(".ActivityContent"))
local CountDown = import("app.components.CountDown")

function ActivityCrystalBall:ctor(parentGO, params, parent)
	ActivityCrystalBall.super.ctor(self, parentGO, params, parent)
	dump(self.activityData.detail)
end

function ActivityCrystalBall:getPrefabPath()
	return "Prefabs/Windows/activity/activity_crystal_ball"
end

function ActivityCrystalBall:initUI()
	ActivityCrystalBall.super.initUI(self)
	self:getComponent()
	self:layoutUI()
	self:register()
	self:updateRedPoint()
end

function ActivityCrystalBall:getComponent()
	local goTrans = self.go:NodeByName("contentPart").gameObject
	self.logo_ = goTrans:ComponentByName("logo", typeof(UISprite))
	self.timeLabel_ = goTrans:ComponentByName("timePart/timeLabel", typeof(UILabel))
	self.endLabel_ = goTrans:ComponentByName("timePart/endLabel", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn").gameObject
	self.btnLost_ = goTrans:NodeByName("btnLost").gameObject
	self.btnLostRed_ = goTrans:NodeByName("btnLost/redPoint").gameObject
	self.btnStory_ = goTrans:NodeByName("btnStory").gameObject
	self.btnStoryRed_ = goTrans:NodeByName("btnStory/redPoint").gameObject
	self.labeLost_ = goTrans:ComponentByName("labeLost", typeof(UILabel))
	self.labelStory_ = goTrans:ComponentByName("labelStory", typeof(UILabel))
end

function ActivityCrystalBall:layoutUI()
	xyd.setUISpriteAsync(self.logo_, nil, "activity_crystall_ball_logo_" .. xyd.Global.lang)

	self.endLabel_.text = __("END")
	local params = {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	}

	if not self.refreshCount_ then
		self.refreshCount_ = CountDown.new(self.timeLabel_, params)
	else
		self.refreshCount_:setInfo(params)
	end

	self.labeLost_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT01")
	self.labelStory_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT02")
end

function ActivityCrystalBall:register()
	UIEventListener.Get(self.helpBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_CRYSTAL_BALL_HELP"
		})
	end

	UIEventListener.Get(self.btnStory_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_crystal_ball_story_window", {})
	end

	UIEventListener.Get(self.btnLost_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_crystal_ball_laf_window", {})
	end

	self:registerEvent(xyd.event.CRYSTAL_BALL_READ_PLOT, handler(self, self.updateRedPoint))
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.updateRedPoint))
end

function ActivityCrystalBall:updateRedPoint()
	self.btnLostRed_:SetActive(self.activityData:getQAFinishRed())
	self.btnStoryRed_:SetActive(self.activityData:getStoryAwardRed())
end

return ActivityCrystalBall
