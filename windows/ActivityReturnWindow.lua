local BaseWindow = import(".BaseWindow")
local ActivityReturnWindow = class("ActivityReturnWindow", BaseWindow)
local WindowTop = import("app.components.WindowTop")
local CountDown = require("app.components.CountDown")

function ActivityReturnWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isEnterRank = true
	self.tiliTimeIndex = 0
	self.currentState = xyd.Global.lang
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.RETURN)
end

function ActivityReturnWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self:layout()
	self:registerEvent()
end

function ActivityReturnWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAll = trans:NodeByName("groupAll").gameObject
	self.upGroup = self.groupAll:NodeByName("upGroup").gameObject
	self.logoImg = self.upGroup:ComponentByName("logoImg", typeof(UITexture))
	self.helpBtn = self.upGroup:NodeByName("helpBtn").gameObject
	self.actTimeExplain = self.upGroup:ComponentByName("timeGroup/actTimeExplain", typeof(UILabel))
	self.actTimeText = self.upGroup:ComponentByName("timeGroup/actTimeText", typeof(UILabel))
	self.returnTimeExplain = self.upGroup:ComponentByName("timeGroup/returnTimeExplain", typeof(UILabel))
	self.returnTimeText = self.upGroup:ComponentByName("timeGroup/returnTimeText", typeof(UILabel))
	self.downGroup = self.groupAll:NodeByName("downGroup").gameObject
	self.tipsBg = self.downGroup:NodeByName("tipsBg").gameObject
	self.tipsBgAnition = self.tipsBg:GetComponent(typeof(UnityEngine.Animation))
	self.tipsText = self.downGroup:ComponentByName("tipsBg/tipsText", typeof(UILabel))
	self.dailyDoubleCon = self.downGroup:NodeByName("dailyDoubleCon").gameObject
	self.dailyDoubleCon_name = self.downGroup:ComponentByName("dailyDoubleCon/name", typeof(UILabel))
	self.partnerBoxCon = self.downGroup:NodeByName("partnerBoxCon").gameObject
	self.partnerBoxCon_name = self.downGroup:ComponentByName("partnerBoxCon/name", typeof(UILabel))
	self.returnDreamCon = self.downGroup:NodeByName("returnDreamCon").gameObject
	self.returnDreamCon_name = self.downGroup:ComponentByName("returnDreamCon/name", typeof(UILabel))
	self.friendGuildCon = self.downGroup:NodeByName("friendGuildCon").gameObject
	self.friendGuildCon_name = self.downGroup:ComponentByName("friendGuildCon/name", typeof(UILabel))
	self.monthCardCon = self.downGroup:NodeByName("monthCardCon").gameObject
	self.monthCardCon_name = self.downGroup:ComponentByName("monthCardCon/name", typeof(UILabel))
end

function ActivityReturnWindow:initTopGroup()
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

function ActivityReturnWindow:getWindowTop()
	return self.windowTop
end

function ActivityReturnWindow:layout()
	self.upGroup:Y(509 + 46 * self.scale_num_contrary)
	self.returnDreamCon:Y(319 + 40 * self.scale_num_contrary)
	self.dailyDoubleCon:Y(333 + 26 * self.scale_num_contrary)
	self.friendGuildCon:Y(-75 + 23 * self.scale_num_contrary)

	self.dailyDoubleCon_name.text = __("ACT_RETURN_DOUBLE_BTN")
	self.partnerBoxCon_name.text = __("ACT_RETURN_GIFT_BTN")
	self.returnDreamCon_name.text = __("ACT_RETURN_MISSION_BTN")
	self.friendGuildCon_name.text = __("ACT_RETURN_COMMEND_BTN")
	self.monthCardCon_name.text = __("ACT_RETURN_CARD_BTN")
	self.actTimeExplain.text = __("ACTIVITY_PLAYER_RETURN_ALLTIME")
	self.returnTimeExplain.text = __("ACTIVITY_PLAYER_RETURN_RETURNTIME")

	xyd.setUITextureByNameAsync(self.logoImg, "activity_return_mission_logo_" .. xyd.Global.lang, true)

	self.actTimeText.text = "00:00:00"
	local returnTimeGet = tonumber(xyd.tables.miscTable:getVal("activity_return_player_time_range"))
	local countdown_returnTime = xyd.getServerTime() - self.activityData:startTime()

	if countdown_returnTime > 0 then
		countdown_returnTime = returnTimeGet - countdown_returnTime
	else
		countdown_returnTime = -1
	end

	if countdown_returnTime > 0 then
		self.countdown_return = CountDown.new(self.returnTimeText, {
			duration = countdown_returnTime,
			callback = handler(self, self.timeOver_return)
		})

		self.returnTimeExplain.gameObject:SetActive(true)
		self.returnTimeText.gameObject:SetActive(true)
	else
		self.returnTimeExplain.gameObject:SetActive(false)
		self.returnTimeText.gameObject:SetActive(false)
	end

	local countdown_allTime = self.activityData:getEndTime() - xyd.getServerTime()

	if countdown_allTime > 0 then
		self.countdown_all = CountDown.new(self.actTimeText, {
			duration = countdown_allTime,
			callback = handler(self, self.timeOver_all)
		})
	end

	local doubleTimeGet = tonumber(xyd.tables.miscTable:getVal("activity_return_drop_period"))
	local doubleTime_left = xyd.getServerTime() - self.activityData:startTime()

	if doubleTime_left > 0 then
		doubleTime_left = doubleTimeGet - doubleTime_left
	else
		doubleTime_left = -1
	end

	if doubleTime_left > 0 then
		self.tipsBg:SetActive(true)
		self.tipsBgAnition:Play()

		local daysNum = math.ceil(doubleTime_left / 86400)
		self.tipsText.text = __("ACTIVITY_PLAYER_RETURN_DOUBLEDAYS", daysNum)
	else
		self.tipsBg:SetActive(false)
	end
end

function ActivityReturnWindow:updateUpIcon()
	self.tipsBg:SetActive(xyd.getReturnBackIsDoubleTime())
end

function ActivityReturnWindow:timeOver_return()
	self.returnTimeExplain.gameObject:SetActive(false)
	self.returnTimeText.gameObject:SetActive(false)
end

function ActivityReturnWindow:timeOver_all()
	self.actTimeText.text = "00:00:00"
end

function ActivityReturnWindow:registerEvent()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_RETURN_WINDOW_HELP"
		})
	end)

	UIEventListener.Get(self.returnDreamCon).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_return_personal_window", {})
	end

	UIEventListener.Get(self.dailyDoubleCon.gameObject).onClick = handler(self, function ()
		if self.tipsBg.gameObject.activeSelf then
			xyd.WindowManager.get():openWindow("activity_return_double_window")
		else
			xyd.alertTips(__("ACTIVITY_END_YET"))
		end
	end)
	UIEventListener.Get(self.friendGuildCon.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_return_commend_window")
	end)
	UIEventListener.Get(self.partnerBoxCon.gameObject).onClick = handler(self, function ()
		local params = {
			select = xyd.ActivityID.HOT_POINT_PARTNER,
			activity_type2 = xyd.tables.activityTable:getType2(xyd.ActivityID.HOT_POINT_PARTNER)
		}

		xyd.WindowManager.get():openWindow("activity_window", params)
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.monthCardCon.gameObject).onClick = handler(self, function ()
		local params = {
			select = xyd.ActivityID.MONTH_CARD,
			activity_type2 = xyd.tables.activityTable:getType2(xyd.ActivityID.MONTH_CARD)
		}

		xyd.WindowManager.get():openWindow("activity_window", params)
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

return ActivityReturnWindow
