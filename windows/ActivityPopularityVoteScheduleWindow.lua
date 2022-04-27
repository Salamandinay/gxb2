local ActivityPopularityVoteScheduleWindow = class("ActivityPopularityVoteScheduleWindow", import(".BaseWindow"))
local ScheduleItem = class("ScheduleItem", import("app.components.CopyComponent"))
local PeriodState = {
	NOT_START = 1,
	IS_ENDED = 3,
	ON_GOING = 2
}

function ActivityPopularityVoteScheduleWindow:ctor(name, params)
	ActivityPopularityVoteScheduleWindow.super.ctor(self, name, params)
end

function ActivityPopularityVoteScheduleWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityPopularityVoteScheduleWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction")
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.labelTitle = groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollerPanel = groupAction:ComponentByName("scroller", typeof(UIPanel))
	self.chileScheduleItem = groupAction:NodeByName("chileScheduleItem").gameObject
	self.schedule_1 = self.scroller:NodeByName("schedule_1").gameObject
	self.schedule_2 = self.scroller:NodeByName("schedule_2").gameObject

	self.chileScheduleItem:SetActive(false)
end

function ActivityPopularityVoteScheduleWindow:layout()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT5")
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)
	local curDay = (xyd.getServerTime() - activityData.start_time) / 86400
	local periodList = xyd.split(xyd.tables.miscTable:getVal("activity_popularity_vote_stagetime"), "|", true)
	self.curPeriod = 1

	for k, v in ipairs(periodList) do
		if curDay < v then
			self.curPeriod = k

			break
		end
	end

	self.scheduleItem_1 = ScheduleItem.new(self.schedule_1, self, 1)
	self.scheduleItem_2 = ScheduleItem.new(self.schedule_2, self, 2)
	self.originY = self.schedule_1.transform:InverseTransformPoint(self.labelTitle.transform.position).y
end

function ActivityPopularityVoteScheduleWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)
end

function ScheduleItem:ctor(go, parent, period)
	self.parent = parent
	self.period = period
	self.curPeriod = self.parent.curPeriod
	self.bg1 = go:NodeByName("bg1").gameObject
	self.onGoingImg = go:NodeByName("onGoingImg").gameObject
	self.onGoingLabel = self.onGoingImg:ComponentByName("onGoingLabel", typeof(UILabel))
	self.timeLabel = go:ComponentByName("timeLabel", typeof(UILabel))
	self.periodLabel = go:ComponentByName("periodLabel", typeof(UILabel))
	self.childSchedule = go:NodeByName("childSchedule").gameObject
	self.grid = self.childSchedule:NodeByName("grid").gameObject
	self.pullGroup = go:NodeByName("pullGroup").gameObject
	self.pullDown = self.pullGroup:NodeByName("pullDown").gameObject
	self.pullUp = self.pullGroup:NodeByName("pullUp").gameObject
	self.isPull = false

	ScheduleItem.super.ctor(self, go)
	self:registerEvent()
end

function ScheduleItem:initUI()
	self.pullDown:SetActive(not self.isPull)
	self.pullUp:SetActive(self.isPull)

	self.onGoingLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT13")
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)
	local periodList = xyd.split(xyd.tables.miscTable:getVal("activity_popularity_vote_stagetime"), "|", true)
	local startTime, endTime, childPeriodsList = nil

	if self.period == 1 then
		childPeriodsList = {
			1,
			2,
			3,
			4
		}

		if self.curPeriod <= 4 then
			self.periodState = PeriodState.ON_GOING
		else
			self.periodState = PeriodState.IS_ENDED
		end

		self.periodLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT6")
		startTime = self.activityData.start_time
		endTime = self.activityData.start_time + periodList[4] * 86400 - 86400
	else
		childPeriodsList = {
			5,
			6,
			7,
			8,
			9
		}

		if self.curPeriod <= 4 then
			self.periodState = PeriodState.NOT_START
		elseif self.curPeriod > 9 then
			self.periodState = PeriodState.IS_ENDED
		else
			self.periodState = PeriodState.ON_GOING
		end

		self.periodLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT7")
		startTime = self.activityData.start_time + periodList[4] * 86400
		endTime = self.activityData.start_time + periodList[9] * 86400 - 86400
	end

	self.onGoingImg:SetActive(self.periodState == PeriodState.ON_GOING)

	local timeStr = nil
	local t1 = os.date("*t", startTime)
	timeStr = __("DATE_2", t1.month, t1.day) .. "~"
	local t2 = os.date("*t", endTime)
	timeStr = timeStr .. __("DATE_2", t2.month, t2.day)
	self.timeLabel.text = timeStr

	self:addChileScheduleItem(childPeriodsList, periodList)
	self.childSchedule:SetActive(self.isPull)
end

function ScheduleItem:addChileScheduleItem(childPeriodsList, periodList)
	for i = 1, #childPeriodsList do
		local childPeriod = childPeriodsList[i]
		local childItem = NGUITools.AddChild(self.grid, self.parent.chileScheduleItem)
		local periodLabel = childItem:ComponentByName("periodLabel", typeof(UILabel))
		periodLabel.text = __("ACTIVITY_POPULARITY_VOTE_TIMETEXT0" .. childPeriod)
		local startTime = childPeriod > 1 and self.activityData.start_time + periodList[childPeriod - 1] * 86400 or self.activityData.start_time
		local endTime = self.activityData.start_time + periodList[childPeriod] * 86400 - 86400
		local timeStr = nil
		local t1 = os.date("*t", startTime)
		local t2 = os.date("*t", endTime)

		if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
			timeStr = __("DATE_2", t1.month, t1.day) .. "-" .. __("DATE_2", t2.month, t2.day)
		else
			timeStr = t1.month .. "." .. t1.day .. "-" .. t2.month .. "." .. t2.day
		end

		childItem:ComponentByName("timeLabel", typeof(UILabel)).text = timeStr
		local stateLabel = childItem:ComponentByName("stateLabel", typeof(UILabel))

		if self.curPeriod == childPeriod then
			stateLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT13")
			stateLabel.color = Color.New2(4071227647.0)
		elseif childPeriod < self.curPeriod then
			stateLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT12")
			stateLabel.color = Color.New2(2155905279.0)
		else
			stateLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT14")
			stateLabel.color = Color.New2(1583978239)
		end

		xyd.setDragScrollView(childItem, self.parent.scroller)

		UIEventListener.Get(childItem).onClick = function ()
			if childPeriod < self.curPeriod then
				local hasData = false
				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

				if activityData.history and activityData.history[childPeriod] then
					hasData = true
				else
					local msg = messages_pb.activity_popularity_vote_get_vote_list_req()
					msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
					msg.period = childPeriod

					xyd.Backend.get():request(xyd.mid.ACTIVITY_POPULARITY_VOTE_GET_VOTE_LIST, msg)
				end

				xyd.WindowManager.get():closeWindow("activity_popularity_vote_schedule_window")
				xyd.WindowManager.get():openWindow("activity_popularity_vote_history_window", {
					hasData = hasData,
					period = childPeriod
				})
			elseif childPeriod == self.curPeriod then
				xyd.showToast(__("ACTIVITY_POPULARITY_VOTE_TITLETEXT13"))
			else
				xyd.showToast(__("ACTIVITY_POPULARITY_VOTE_TITLETEXT14"))
			end
		end

		if xyd.Global.lang == "de_de" then
			periodLabel.width = 181
			periodLabel.fontSize = 18
		end
	end
end

function ScheduleItem:registerEvent()
	UIEventListener.Get(self.bg1).onClick = function ()
		if self.isPlayAnimation then
			return
		end

		self.isPull = not self.isPull

		self.pullDown:SetActive(not self.isPull)
		self.pullUp:SetActive(self.isPull)
		self:playPullAnimation()
	end

	xyd.setDragScrollView(self.bg1, self.parent.scroller)
end

function ScheduleItem:playPullAnimation()
	self.isPlayAnimation = true
	local sequence = self:getSequence()

	self.childSchedule:SetActive(self.isPull)

	local startAlpht, endAlpha = nil

	if self.isPull then
		startAlpht = 0
		endAlpha = 1
	else
		startAlpht = 1
		endAlpha = 0
	end

	self.childSchedule:SetLocalScale(1, startAlpht, 1)
	sequence:Append(self.childSchedule.transform:DOScale(endAlpha, 0.1))

	if self.period == 1 then
		local y = self.isPull and -337 or -116

		sequence:Join(self.parent.schedule_2.transform:DOLocalMoveY(y, 0.1))
	end

	sequence:AppendCallback(function ()
		sequence:Kill(false)

		sequence = nil
		self.isPlayAnimation = false
		local posY = nil

		if self.period == 2 and self.isPull then
			posY = self.go.transform:InverseTransformPoint(self.parent.labelTitle.transform.position).y
		else
			posY = self.parent.schedule_1.transform:InverseTransformPoint(self.parent.labelTitle.transform.position).y
		end

		local delta = posY - self.parent.originY

		self.parent.scroller:MoveRelative(Vector3(0, delta, 0))
	end)
end

return ActivityPopularityVoteScheduleWindow
