local ActivityContent = import(".ActivityContent")
local ActivityDoubleDrop = class("ActivityDoubleDrop", ActivityContent)
local CountDown = require("app.components.CountDown")

function ActivityDoubleDrop:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)
end

function ActivityDoubleDrop:getPrefabPath()
	return "Prefabs/Windows/activity/activity_double_drop"
end

function ActivityDoubleDrop:initUI()
	self:getUIComponent()
	ActivityDoubleDrop.super.initUI(self)
	self:initUIComponet()
	self:onRegisterEvent()
end

function ActivityDoubleDrop:getUIComponent()
	local go = self.go
	self.group = go:NodeByName("group").gameObject
	self.bg = go:NodeByName("bg").gameObject
	self.imgTitle = self.group:ComponentByName("imgTitle", typeof(UISprite))
	self.timeGroup = self.group:NodeByName("timeGroup").gameObject
	self.timerGroup = self.timeGroup:NodeByName("timerGroup").gameObject
	self.timeLabel = self.timerGroup:ComponentByName("timeLabel", typeof(UILabel))
	self.endLabel = self.timerGroup:ComponentByName("endLabel", typeof(UILabel))
	self.buttomGroup = self.group:NodeByName("buttomGroup").gameObject
	self.buttomLabel = self.buttomGroup:ComponentByName("label", typeof(UILabel))
	self.imgLabel = self.buttomGroup:ComponentByName("imgLabel", typeof(UISprite))
	self.button = self.buttomGroup:NodeByName("button").gameObject
	self.btnLabel = self.button:ComponentByName("label", typeof(UILabel))
end

function ActivityDoubleDrop:resizeToParent()
	ActivityDoubleDrop.super.resizeToParent(self)

	local height = self.go:GetComponent(typeof(UIWidget)).height

	self.group:SetLocalPosition(self.group.transform.localPosition.x, -0.5 * height + 40, self.group.transform.localPosition.z)
	self:resizePosY(self.bg, -437, -526)
end

function ActivityDoubleDrop:initUIComponet()
	self:setText()
	self:setTexture()
end

function ActivityDoubleDrop:onRegisterEvent()
	UIEventListener.Get(self.button).onClick = function ()
		if not xyd.checkFunctionOpen(29) then
			return
		end

		if xyd.models.dailyQuiz:isAllMaxLev() then
			xyd.WindowManager.get():openWindow("daily_quiz2_window")
		else
			xyd.WindowManager.get():openWindow("daily_quiz_window")
		end
	end
end

function ActivityDoubleDrop:setText()
	self.buttomLabel.text = __("DOUBLE_DROP_QUIZ_DESC")
	self.btnLabel.text = __("GOTO_QUIZ")

	if self.activityData:getUpdateTime() - xyd.getServerTime() > 0 then
		local countdown = CountDown.new(self.timeLabel, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.timeLabel:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("TEXT_END")

	self.timerGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ActivityDoubleDrop:setTexture()
	xyd.setUISpriteAsync(self.imgTitle, nil, "activity_double_drop_logo_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.imgLabel, nil, "activity_double_drop_up_" .. xyd.Global.lang, nil, , true)
end

return ActivityDoubleDrop
