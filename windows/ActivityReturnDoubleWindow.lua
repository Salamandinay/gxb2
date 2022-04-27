local BaseWindow = import(".BaseWindow")
local ActivityReturnDoubleWindow = class("ActivityReturnDoubleWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = require("app.components.CountDown")

function ActivityReturnDoubleWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
end

function ActivityReturnDoubleWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:layout()
	self:registerEvent()
end

function ActivityReturnDoubleWindow:getUIComponent()
	local trans = self.window_.transform
	self.downBg = trans:ComponentByName("groupAll/downBg", typeof(UITexture))
	self.centerGroup = trans:NodeByName("groupAll/centerGroup").gameObject
	self.logoImg = self.centerGroup:ComponentByName("logoImg", typeof(UITexture))
	self.actTimeText = self.centerGroup:ComponentByName("timeGroup/actTimeText", typeof(UILabel))
	self.actTimeExplain = self.centerGroup:ComponentByName("timeGroup/actTimeExplain", typeof(UILabel))
	self.textLayout = self.centerGroup:ComponentByName("timeGroup", typeof(UILayout))
	self.btnCon = self.centerGroup:NodeByName("btnCon").gameObject
	self.numImg = self.btnCon:ComponentByName("numImg", typeof(UITexture))
	self.btnMain = self.btnCon:NodeByName("btnMain").gameObject
	self.btnMainText = self.btnCon:ComponentByName("btnMain/btnMainText", typeof(UILabel))
	self.btnTest = self.btnCon:NodeByName("btnTest").gameObject
	self.btnTestText = self.btnCon:ComponentByName("btnTest/btnTestText", typeof(UILabel))
	self.explainText = self.btnCon:ComponentByName("explainText", typeof(UILabel))
end

function ActivityReturnDoubleWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityReturnDoubleWindow:getWindowTop()
	return self.windowTop
end

function ActivityReturnDoubleWindow:layout()
	self.downBg:Y(-252 + -103 * self.scale_num_contrary)
	self.centerGroup:Y(308 + 75 * self.scale_num_contrary)

	self.btnMainText.text = __("ACTIVITY_PLAYER_RETURN_GOTOMAIN")
	self.btnTestText.text = __("GOTO_QUIZ")
	self.actTimeExplain.text = __("ACTIVITY_PLAYER_RETURN_TIMEEND")
	self.explainText.text = __("ACTIVITY_PLAYER_RETURN_EXPLAIN")

	self.textLayout:Reposition()
	xyd.setUITextureByNameAsync(self.logoImg, "activity_return_double_" .. xyd.Global.lang, true)
	xyd.setUITextureByNameAsync(self.numImg, "activity_double_drop_up_" .. xyd.Global.lang, true)

	local doubleTimeGet = tonumber(xyd.tables.miscTable:getVal("activity_return_drop_period"))
	local doubleTime_left = xyd.getServerTime() - self.activityData:startTime()

	if doubleTime_left > 0 then
		doubleTime_left = doubleTimeGet - doubleTime_left
	else
		doubleTime_left = -1
	end

	if doubleTime_left > 0 then
		self.countdown_return = CountDown.new(self.actTimeText, {
			duration = doubleTime_left,
			callback = handler(self, self.timeOver_all),
			secondStrType = xyd.SECOND2STR.HOURMINSEC
		})
	else
		self.timeOver_all()
	end
end

function ActivityReturnDoubleWindow:timeOver_all()
	self.actTimeText.text = "00:00:00"
end

function ActivityReturnDoubleWindow:registerEvent()
	UIEventListener.Get(self.btnMain.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("campaign_window")
	end)
	UIEventListener.Get(self.btnTest.gameObject).onClick = handler(self, function ()
		if not xyd.checkFunctionOpen(xyd.FunctionID.QUIZ) then
			return
		end

		if xyd.models.dailyQuiz:isAllMaxLev() then
			xyd.WindowManager.get():openWindow("daily_quiz2_window")
		else
			xyd.WindowManager.get():openWindow("daily_quiz_window")
		end
	end)
end

return ActivityReturnDoubleWindow
