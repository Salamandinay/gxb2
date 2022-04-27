local ActivityContent = import(".ActivityContent")
local TestFeedback = class("TestFeedback", ActivityContent)

function TestFeedback:ctor(params)
	ActivityContent.ctor(self, params)

	self.currentStar1 = 0
	self.currentStar2 = 0
	self.skinName = "TestFeedbackSkin"
	self.currentState = xyd.Global.lang
end

function TestFeedback:euiComplete()
	ActivityContent.euiComplete(self)
	self:layout()
	self:registerEvent()
	self:setCountDown()

	self.currentStar1 = self.activityData.detail.story_star
	self.currentStar2 = self.activityData.detail.ui_star

	self:update()
end

function TestFeedback:layout()
	local htmlParser = egret.HtmlTextParser.new(true)
	self.labelText01_.textFlow = htmlParser:parser(__(_G, "TEST_FEEDBACK_TEXT_01"))
	self.labelText02_.text = __(_G, "TEST_FEEDBACK_TEXT_02")
	self.labelText03_.text = __(_G, "TEST_FEEDBACK_TEXT_03")
	self.btnSend_.label = __(_G, "TEST_FEEDBACK_TEXT_10")
	self.endLabel.text = __(_G, "END_TEXT")
end

function TestFeedback:setCountDown()
	if xyd:getServerTime() < self.activityData:getUpdateTime() then
		self.timeLabel:setCountDownTime(self.activityData:getUpdateTime() - xyd:getServerTime())
	else
		self.endLabel.visible = false
		self.timeLabel.visible = false
	end
end

function TestFeedback:registerEvent()
	self.btnSend_:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
		self:sendMsg()
	end, self)

	local i = 1

	while i <= 5 do
		self["group1_" .. tostring(i)]:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
			if self.activityData.detail.daily_comment then
				return
			end

			self.currentStar1 = i

			self:update()
		end, self)
		self["group2_" .. tostring(i)]:addEventListener(egret.TouchEvent.TOUCH_TAP, function ()
			if self.activityData.detail.daily_comment then
				return
			end

			self.currentStar2 = i

			self:update()
		end, self)

		i = i + 1
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (____, event)
		if event.data.activity_id ~= xyd.ActivityID.TEST_FEEDBACK then
			return
		end

		xyd:showToast(__(_G, "TEST_FEEDBACK_TEXT_13"))

		local data = JSON:parse(event.data.detail)
		self.currentStar1 = data.story_star
		self.currentStar2 = data.ui_star

		self:update()
	end, self)
end

function TestFeedback:sendMsg()
	if not self.currentStar1 or not self.currentStar2 then
		xyd:showToast(__(_G, "TEST_FEEDBACK_TEXT_12"))

		return
	end

	local data = JSON:stringify({
		story_star = self.currentStar1,
		ui_star = self.currentStar2
	})
	local param = {
		activity_id = xyd.ActivityID.TEST_FEEDBACK,
		params = data
	}

	xyd.Backend:get():request(xyd.mid.GET_ACTIVITY_AWARD, param)
end

function TestFeedback:update()
	self:updateStar()
	self:updateLabel()
	self:updateButton()
end

function TestFeedback:updateStar()
	local i = 1

	while i <= 5 do
		if i <= self.currentStar1 then
			self["star1_" .. tostring(i)].visible = true
		else
			self["star1_" .. tostring(i)].visible = false
		end

		i = i + 1
	end

	local i = 1

	while i <= 5 do
		if i <= self.currentStar2 then
			self["star2_" .. tostring(i)].visible = true
		else
			self["star2_" .. tostring(i)].visible = false
		end

		i = i + 1
	end
end

function TestFeedback:updateLabel()
	if self.currentStar1 then
		self.labelScore_.text = __(_G, "TEST_FEEDBACK_TEXT_04", self.currentStar1)
	end

	if self.currentStar2 then
		self.labelDesc_.text = __(_G, "TEST_FEEDBACK_TEXT_0" .. tostring(String(_G, self.currentStar2 + 4)))
	end

	self.btnSend_.label = __(_G, "TEST_FEEDBACK_TEXT_10")
end

function TestFeedback:updateButton()
	if self.activityData.detail.daily_comment then
		self.btnSend_.imgMask_.visible = true
		self.btnSend_.touchEnabled = false
		self.btnSend_.label = __(_G, "TEST_FEEDBACK_TEXT_10")
	else
		self.btnSend_.imgMask_.visible = false
		self.btnSend_.touchEnabled = true
		self.btnSend_.label = __(_G, "TEST_FEEDBACK_TEXT_11")
	end
end

return TestFeedback
