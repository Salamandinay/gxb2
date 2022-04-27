local BaseWindow = import(".BaseWindow")
local FairArenaEntryWindow = class("FairArenaEntryWindow", BaseWindow)
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")

function FairArenaEntryWindow:ctor(name, params)
	FairArenaEntryWindow.super.ctor(self, name, params)

	self.needReqData = params.needReqData
end

function FairArenaEntryWindow:initWindow()
	FairArenaEntryWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()

	if self.needReqData then
		xyd.models.fairArena:reqArenaInfo()
	else
		self:updateLayout()
	end
end

function FairArenaEntryWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.textImg01_ = winTrans:ComponentByName("textImg01_", typeof(UISprite))
	self.topGroup = winTrans:NodeByName("topGroup").gameObject
	self.timeLayout = winTrans:ComponentByName("timeGroup", typeof(UILayout))
	self.endLabel_ = winTrans:ComponentByName("timeGroup/endLabel_", typeof(UILabel))
	self.timeLabel_ = winTrans:ComponentByName("timeGroup/timeLabel_", typeof(UILabel))
	self.collectionBtn_ = winTrans:NodeByName("collectionBtn_").gameObject
	self.collectionRed = self.collectionBtn_:NodeByName("redPoint").gameObject
	self.scoreTextLabel_ = winTrans:ComponentByName("scoreGroup/scoreTextLabel_", typeof(UILabel))
	self.scoreLabel_ = winTrans:ComponentByName("scoreGroup/scoreLabel_", typeof(UILabel))
	self.rankBtn_ = winTrans:NodeByName("rankBtn_").gameObject
	self.recordBtn_ = winTrans:NodeByName("recordBtn_").gameObject
	self.awardBtn_ = winTrans:NodeByName("awardBtn_").gameObject
	local bottomGroup = winTrans:NodeByName("bottomGroup")
	self.tipsGroup = bottomGroup:NodeByName("tipsGroup").gameObject
	self.tipsLayout = bottomGroup:ComponentByName("tipsGroup", typeof(UILayout))
	self.tipsTimeLabel_ = bottomGroup:ComponentByName("tipsGroup/tipsTimeLabel_", typeof(UILabel))
	self.tipsLabel_ = bottomGroup:ComponentByName("tipsGroup/tipsLabel_", typeof(UILabel))
	self.challengeBtn_ = bottomGroup:NodeByName("challengeBtn_").gameObject
	self.leftLabel_ = self.challengeBtn_:ComponentByName("leftLabel_", typeof(UILabel))
	self.challengeIcon_ = self.challengeBtn_:NodeByName("icon_").gameObject
	self.challengeIcon_UISprite = self.challengeBtn_:ComponentByName("icon_", typeof(UISprite))
	self.costLabel_ = self.challengeBtn_:ComponentByName("icon_/costLabel_", typeof(UILabel))
	self.textImg02_ = self.challengeBtn_:ComponentByName("textImg02_", typeof(UISprite))
	self.testBtn_ = bottomGroup:NodeByName("testBtn_").gameObject
	self.testTimesLabel = self.testBtn_:ComponentByName("testTimesLabel", typeof(UILabel))
	self.textImg03_ = self.testBtn_:ComponentByName("textImg03_", typeof(UISprite))
	self.helpBtn_ = winTrans:NodeByName("helpBtn_").gameObject
end

function FairArenaEntryWindow:initUIComponent()
	xyd.setUISpriteAsync(self.textImg01_, nil, "fair_arena_text01_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.textImg02_, nil, "fair_arena_main_btn_text01_" .. xyd.Global.lang, nil, , true)
	xyd.setUISpriteAsync(self.textImg03_, nil, "fair_arena_main_btn_text02_" .. xyd.Global.lang, nil, , true)

	self.collectionBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_COLLECTION")
	self.rankBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_RANK")
	self.recordBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_HISTORY")
	self.awardBtn_:ComponentByName("button_label", typeof(UILabel)).text = __("FAIR_ARENA_AWARD_PREVIEW")
	self.scoreTextLabel_.text = __("FAIR_ARENA_POINT_NOW")
	self.windowTop = WindowTop.new(self.topGroup, self.name_, 10)
	local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
	local items = {
		{
			id = cost_id,
			callback = function ()
				if not self.activityData then
					self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
				end

				if self.activityData:getEndTime() - xyd.getServerTime() <= xyd.DAY_TIME then
					xyd.alertTips(__("FAIR_ARENA_GET_HOE_SHOW_TIME_NO"))
				else
					xyd.WindowManager.get():openWindow("fair_arena_get_hoe_window")
				end
			end
		},
		{
			id = xyd.ItemID.CRYSTAL
		}
	}

	self.leftLabel_.gameObject:SetActive(false)
	self.windowTop:setItem(items)
end

function FairArenaEntryWindow:register()
	FairArenaEntryWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.updateLayout))
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_EXPLORE, handler(self, self.onExplore))

	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "FAIR_ARENA_HELP1"
		})
	end)
	UIEventListener.Get(self.collectionBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_collection_window")
	end)
	UIEventListener.Get(self.rankBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_rank_window")
	end)
	UIEventListener.Get(self.recordBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_record_window")
	end)
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("fair_arena_award_window")
	end)
	UIEventListener.Get(self.challengeBtn_).onClick = handler(self, self.onChallenge)
	UIEventListener.Get(self.testBtn_).onClick = handler(self, self.onTest)
end

function FairArenaEntryWindow:updateLayout(event)
	if event and event.data.act_info.activity_id ~= xyd.ActivityID.ACTIVITY_FAIR_ARENA then
		return
	end

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	self.data = xyd.models.fairArena:getArenaInfo()

	if not self.timeCount1 then
		self.timeCount1 = CountDown.new(self.timeLabel_)
	end

	local leftTime = self.activityData:getEndTime() - xyd.getServerTime()

	if xyd.TimePeriod.DAY_TIME < leftTime then
		self.endLabel_.text = __("FAIR_ARENA_END_TIME_1")

		self.timeCount1:setInfo({
			duration = leftTime - xyd.TimePeriod.DAY_TIME
		})
		self:updateTime()
	else
		self.endLabel_.text = __("FAIR_ARENA_END_TIME_2")

		self.timeCount1:setInfo({
			duration = self.activityData:getEndTime() - xyd.getServerTime()
		})
		self.challengeBtn_:SetActive(false)
		self.testBtn_:SetActive(false)
		self.tipsTimeLabel_:SetActive(false)
		self.tipsGroup:SetActive(true)

		self.tipsLabel_.text = __("ACTIVITY_END_YET")
	end

	local cost_arr = xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")
	self.costLabel_.text = tostring(cost_arr[2])

	self.challengeIcon_:SetActive(true)
	xyd.setUISpriteAsync(self.challengeIcon_UISprite, nil, "icon_" .. cost_arr[1])

	self.scoreLabel_.text = self.data.score
	self.testTimesLabel.text = __("FAIR_ARENA_EXPLORE_LIMIT", self.data.test_times)

	self.timeLayout:Reposition()
	self.tipsLayout:Reposition()
	self:updateRedMark()
end

function FairArenaEntryWindow:onChallenge()
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = 0

	if mapInfo then
		maxStage = mapInfo.max_stage
	end

	local openValue = xyd.tables.miscTable:getNumber("fair_arena_explore_stage", "value")
	local fortId = xyd.tables.stageTable:getFortID(openValue)
	local text = tostring(fortId) .. "-" .. tostring(xyd.tables.stageTable:getName(openValue))

	if maxStage < openValue then
		xyd.showToast(__("FUNC_OPEN_STAGE", text))

		return
	end

	local cost_id = tonumber(xyd.tables.miscTable:split2num("fair_arena_ticket_item", "value", "#")[1])
	local cost_num = xyd.models.backpack:getItemNumByID(cost_id)

	if cost_num <= 0 then
		xyd.alert(xyd.AlertType.YES_NO, __("FAIR_ARENA_GET_HOE_NONE_TIPS"), function (yes_no)
			if yes_no then
				xyd.WindowManager.get():openWindow("fair_arena_get_hoe_window")
			end
		end)

		return
	end

	local notFirst = xyd.db.misc:getValue("fair_arena_first_challenge")

	if not notFirst then
		xyd.openWindow("fair_arena_alert_window", {
			alertType = xyd.AlertType.YES_NO,
			message = __("FAIR_ARENA_TIPS_EXPLORE_FIRST"),
			closeText = __("FAIR_ARENA_GOTO_DEMO"),
			confirmText = __("FAIR_ARENA_GOTO_EXPLORE"),
			callback = function (yes)
				if yes then
					xyd.models.fairArena:reqExplore(xyd.FairArenaType.NORMAL)
				else
					xyd.models.fairArena:reqExplore(xyd.FairArenaType.TEST)
				end
			end
		})
	else
		xyd.models.fairArena:reqExplore(xyd.FairArenaType.NORMAL)
	end
end

function FairArenaEntryWindow:onTest()
	if self.data.test_times > 0 then
		xyd.alertYesNo(__("FAIR_ARENA_TIPS_DEMO", self.data.test_times), function (yes)
			if yes then
				xyd.models.fairArena:reqExplore(xyd.FairArenaType.TEST)
			end
		end)
	else
		xyd.alertTips(__("FAIR_ARENA_TIPS_DEMO_LIMIT"))
	end
end

function FairArenaEntryWindow:onExplore(event)
	local data = event.data

	if data.operate ~= xyd.FairArenaType.BUY_HOE then
		xyd.WindowManager.get():openWindow("fair_arena_explore_window", {}, function ()
			xyd.WindowManager.get():closeWindow("fair_arena_entry_window")
		end)
	end
end

function FairArenaEntryWindow:updateRedMark()
	local flag = xyd.db.misc:getValue("fair_arena_collection_redpoint")

	if flag then
		self.collectionRed:SetActive(false)
	else
		self.collectionRed:SetActive(true)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.FAIR_ARENA, self.activityData:getRedMarkState())
end

function FairArenaEntryWindow:updateTime()
	local free_get_arr = xyd.tables.miscTable:split2Cost("fair_arena_free", "value", "|#", true)
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	local start_time = activityData:startTime()
	local count_time = activityData:getEndTime() - xyd.DAY_TIME
	local can_get = false

	for i, data in pairs(free_get_arr) do
		if start_time <= xyd.getServerTime() and xyd.getServerTime() < start_time + (data[1] - 1) * xyd.DAY_TIME then
			count_time = start_time + (data[1] - 1) * xyd.DAY_TIME
			can_get = true
			self.tipsLabel_.text = __("FAIR_ARENA_GET_HOE_TIME_EXPLAIN", data[2])

			break
		end
	end

	local duration = count_time - xyd.getServerTime()

	if duration > 0 then
		if self.timeCount then
			self.timeCount:dispose()
		end

		self.timeCount = CountDown.new(self.tipsTimeLabel_)

		self.timeCount:setInfo({
			duration = duration,
			callback = function ()
				self:waitForTime(2, handler(self, self.updateTime))
			end
		})
	else
		self:timeOver()
	end

	if not can_get then
		self.tipsLabel_.text = __("FAIR_ARENA_GET_HOE_TIME_END")
	end

	self.tipsLayout:Reposition()
end

function FairArenaEntryWindow:timeOver()
	self.tipsTimeLabel_:SetActive(false)
	self.tipsGroup:SetActive(true)

	self.tipsLabel_.text = __("ACTIVITY_END_YET")
end

return FairArenaEntryWindow
