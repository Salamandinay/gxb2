local ActivityEntranceTestShowsWindow = class("ActivityEntranceTestShowsWindow", import(".BaseWindow"))
local ResItem = import("app.components.ResItem")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ActivitySportsGuessItem = class("ActivitySportsGuessItem", import("app.components.CopyComponent"))

function ActivityEntranceTestShowsWindow:ctor(name, params)
	ActivityEntranceTestShowsWindow.super.ctor(self, name, params)

	self.cur_select_ = 0
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.todayIndex = self.activityData:getDayIndex()
end

function ActivityEntranceTestShowsWindow:initWindow()
	ActivityEntranceTestShowsWindow.super.initWindow(self)
	self:getComponent()
	self:registerEvent()
	self:layout()

	self.justGetInfo = true

	if not self.activityData:reqGambleInfo() then
		self.justGetInfo = false

		self:updateQuiz()
		self:updateRecord()
	end

	self:initTimeLabel()
end

function ActivityEntranceTestShowsWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.topBgImg_ = self.groupAction:ComponentByName("topBgImg", typeof(UISprite))
	self.winTitle_ = self.groupAction:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn_ = self.groupAction:NodeByName("helpBtn").gameObject
	self.navGroup = self.groupAction:NodeByName("navGroup").gameObject
	self.nav1None = self.navGroup:NodeByName("tab_1/none").gameObject
	self.scrollViewRecords_ = self.groupAction:ComponentByName("scrollViewRecords", typeof(UIScrollView))
	self.wrapcontent_ = self.groupAction:ComponentByName("scrollViewRecords/wrapcontent", typeof(MultiRowWrapContent))
	local itemRoot = self.window_:NodeByName("recordItemRoot").gameObject
	self.wrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollViewRecords_, self.wrapcontent_, itemRoot, ActivitySportsGuessItem, self)
	self.guessNode = self.groupAction:NodeByName("guessNode").gameObject
	self.attrsBtn1 = self.guessNode:NodeByName("attrsBtn1").gameObject
	self.attrsBtn2 = self.guessNode:NodeByName("attrsBtn2").gameObject
	self.timeLayout_ = self.guessNode:ComponentByName("timeLabelRoot", typeof(UILayout))
	self.timeLabel_ = self.guessNode:ComponentByName("timeLabelRoot/timeLabel", typeof(UILabel))
	self.timeCount_ = self.guessNode:ComponentByName("timeLabelRoot/timeCount", typeof(UILabel))
	self.groupResItem = self.guessNode:NodeByName("groupResItem").gameObject
	self.labelAwardTips_ = self.guessNode:ComponentByName("labelAwardTips", typeof(UILabel))

	for i = 1, 4 do
		self["guessbtn" .. i] = self.guessNode:NodeByName("guessbtn" .. i).gameObject
		self["guessbtnLabel" .. i] = self["guessbtn" .. i]:ComponentByName("label", typeof(UILabel))
		self["guessbtnIcon" .. i] = self["guessbtn" .. i]:ComponentByName("icon", typeof(UISprite))
		self["guessbtnIconLabel" .. i] = self["guessbtnIcon" .. i]:ComponentByName("labelIcon", typeof(UILabel))
	end

	self.player1topNode_ = self.guessNode:ComponentByName("player1topNode", typeof(UIGrid))
	self.player1bottomNode_ = self.guessNode:ComponentByName("player1bottomNode", typeof(UIGrid))
	self.player2topNode_ = self.guessNode:ComponentByName("player2topNode", typeof(UIGrid))
	self.player2bottomNode_ = self.guessNode:ComponentByName("player2bottomNode", typeof(UIGrid))
	self.bg1 = self.guessNode:ComponentByName("bg1", typeof(UISprite))
	self.bg2 = self.guessNode:ComponentByName("bg2", typeof(UISprite))
end

function ActivityEntranceTestShowsWindow:registerEvent()
	ActivityEntranceTestShowsWindow.super.register(self)

	local dayIndex = self.activityData:getDayIndex()
	local monster1 = xyd.tables.activityEntranceTestGuessBattle:getMonster1(dayIndex)
	local monster2 = xyd.tables.activityEntranceTestGuessBattle:getMonster2(dayIndex)

	UIEventListener.Get(self.attrsBtn1).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_shows_detail_window", {
			group = 1
		})
	end

	UIEventListener.Get(self.attrsBtn2).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_entrance_shows_detail_window", {
			group = 2
		})
	end

	UIEventListener.Get(self.nav1None).onClick = function ()
		xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT37"))
	end

	UIEventListener.Get(self.guessbtn1).onClick = function ()
		local betID = self.activityData.detail.bet_records[dayIndex]

		if betID and betID ~= 0 then
			local betTeam = xyd.checkCondition(betID > 0, 1, 2)

			if betTeam == 2 and xyd.checkCondition(betID > 0, betID, -betID) == 1 then
				xyd.alertYesNo(__("ENTRANCE_TEST_GUESS_CHANGE_TIPS"), function (yes_no)
					if yes_no then
						local msg = messages_pb.warmup_bet_req()
						msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
						msg.index = dayIndex
						msg.is_win = 1
						msg.bet_num_id = 1

						xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
					end
				end)
			end
		else
			xyd.alertYesNo(__("ACTIVITY_NEW_WARMUP_TEXT38"), function (yes_no)
				if yes_no then
					local msg = messages_pb.warmup_bet_req()
					msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
					msg.index = dayIndex
					msg.is_win = 1
					msg.bet_num_id = 1

					xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
				end
			end)
		end
	end

	UIEventListener.Get(self.guessbtn2).onClick = function ()
		local betID = self.activityData.detail.bet_records[dayIndex]

		if betID and betID ~= 0 then
			local betTeam = xyd.checkCondition(betID > 0, 1, 2)

			if betTeam == 2 and xyd.checkCondition(betID > 0, betID, -betID) == 2 then
				xyd.alertYesNo(__("ENTRANCE_TEST_GUESS_CHANGE_TIPS"), function (yes_no)
					if yes_no then
						local msg = messages_pb.warmup_bet_req()
						msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
						msg.index = dayIndex
						msg.is_win = 1
						msg.bet_num_id = 2

						xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
					end
				end)
			end
		else
			xyd.alertYesNo(__("ACTIVITY_NEW_WARMUP_TEXT38"), function (yes_no)
				if yes_no then
					local msg = messages_pb.warmup_bet_req()
					msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
					msg.index = dayIndex
					msg.is_win = 1
					msg.bet_num_id = 2

					xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
				end
			end)
		end
	end

	UIEventListener.Get(self.guessbtn3).onClick = function ()
		local betID = self.activityData.detail.bet_records[dayIndex]

		if betID and betID ~= 0 then
			local betTeam = xyd.checkCondition(betID > 0, 1, 2)

			if betTeam == 1 and xyd.checkCondition(betID > 0, betID, -betID) == 1 then
				xyd.alertYesNo(__("ENTRANCE_TEST_GUESS_CHANGE_TIPS"), function (yes_no)
					if yes_no then
						local msg = messages_pb.warmup_bet_req()
						msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
						msg.index = dayIndex
						msg.is_win = 0
						msg.bet_num_id = 1

						xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
					end
				end)
			end
		else
			xyd.alertYesNo(__("ACTIVITY_NEW_WARMUP_TEXT38"), function (yes_no)
				if yes_no then
					local msg = messages_pb.warmup_bet_req()
					msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
					msg.index = dayIndex
					msg.is_win = 0
					msg.bet_num_id = 1

					xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
				end
			end)
		end
	end

	UIEventListener.Get(self.guessbtn4).onClick = function ()
		local betID = self.activityData.detail.bet_records[dayIndex]

		if betID and betID ~= 0 then
			local betTeam = xyd.checkCondition(betID > 0, 1, 2)

			if betTeam == 1 and xyd.checkCondition(betID > 0, betID, -betID) == 2 then
				xyd.alertYesNo(__("ENTRANCE_TEST_GUESS_CHANGE_TIPS"), function (yes_no)
					if yes_no then
						local msg = messages_pb.warmup_bet_req()
						msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
						msg.index = dayIndex
						msg.is_win = 0
						msg.bet_num_id = 2

						xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
					end
				end)
			end
		else
			xyd.alertYesNo(__("ACTIVITY_NEW_WARMUP_TEXT38"), function (yes_no)
				if yes_no then
					local msg = messages_pb.warmup_bet_req()
					msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
					msg.index = dayIndex
					msg.is_win = 0
					msg.bet_num_id = 2

					xyd.Backend.get():request(xyd.mid.WARMUP_BET, msg)
				end
			end)
		end
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		local params = {
			key = "ACTIVITY_NEW_WARMUP_HELP1"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	self.eventProxy_:addEventListener(xyd.event.WARMUP_BET, handler(self, self.onSportsBet))
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_REPORT, handler(self, self.onReport))
end

function ActivityEntranceTestShowsWindow:onReport(event)
	if self.justGetInfo then
		for i = 4, math.min(self.todayIndex, 6) do
			if not self.activityData.recordGamblePartners[i] then
				return true
			end
		end

		self.justGetInfo = false

		self:updateQuiz()
		self:updateRecord()
	else
		xyd.BattleController.get():entranceBattle(event)
	end
end

function ActivityEntranceTestShowsWindow:onSportsBet(event)
	self:updateBtn()
	self.resCoin_:updateNum()
end

function ActivityEntranceTestShowsWindow:initTimeLabel()
	local str = __("COUNT_DOWN")
	local resTime = xyd.getTomorrowTime() - xyd.getServerTime()
	self.timeLabel_.text = str
	self.timeCount_.text = xyd.secondsToString(resTime)

	self.timeLayout_:Reposition()

	local function callback()
		resTime = resTime - 1
		self.timeCount_.text = xyd.secondsToString(resTime)

		if resTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SPORTS_TIME_REFRESH"))
			xyd.models.activity:reqActivityByID(xyd.ActivityID.ENTRANCE_TEST)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end

	self.labelTimer_ = self:getTimer(callback, 1, -1)

	self.labelTimer_:Start()
end

function ActivityEntranceTestShowsWindow:layout()
	self.winTitle_.text = __("ACTIVITY_NEW_WARMUP_TEXT1")

	if not self.resCoin_ then
		self.resCoin_ = ResItem.new(self.groupResItem)
	end

	self.resCoin_:setInfo({
		tableId = xyd.ItemID.MANA
	})
	self.resCoin_:hidePlus()

	if not self.resSommonCoin_ then
		self.resSommonCoin_ = ResItem.new(self.groupResItem)
	end

	self.resSommonCoin_:setInfo({
		tableId = xyd.ItemID.SENIOR_SUMMON_SCROLL
	})
	self.resSommonCoin_:hidePlus()

	local str = __("ENTRANCE_TEST_SHOWS_TIPS")
	local str = string.gsub(str, "0x(%w+)", "%1")
	local str = string.gsub(str, " size=(%w+)", "][size=%1")
	self.labelAwardTips_.text = str

	if xyd.Global.lang ~= "zh_tw" then
		self.labelAwardTips_.fontSize = 24
	end

	if xyd.Global.lang == "de_de" then
		self.labelAwardTips_:Y(157)
	end

	local chosen = {
		color = Color.New2(1012112383),
		effectColor = Color.New2(4294967295.0)
	}
	local unchosen = {
		color = Color.New2(960513791),
		effectColor = Color.New2(4294967295.0)
	}
	local colorParams = {
		chosen = chosen,
		unchosen = unchosen
	}
	self.tab = CommonTabBar.new(self.navGroup, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if self.cur_select_ == index then
			return
		end

		if index == 1 and not self:checkCanShowQuiz() then
			xyd.alertTips(__("ACTIVITY_NEW_WARMUP_TEXT37"))

			return
		end

		self:onTouch(index)
	end, nil, colorParams)
	local tableLabels = xyd.split(__("ACTIVITY_SPORTS_SHOWS_LABELS"), "|")
	tableLabels[1] = __("ACTIVITY_NEW_WARMUP_TEXT1")

	self.tab:setTexts(tableLabels)

	local dayIndex = self.activityData:getDayIndex()

	if dayIndex >= 4 and dayIndex <= 6 then
		local bgArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_team", "value", "|#")

		xyd.setUISpriteAsync(self.bg1, nil, "activity_entrance_test_bg_jc_" .. bgArr[dayIndex - 3][1])
		xyd.setUISpriteAsync(self.bg2, nil, "activity_entrance_test_bg_jc_" .. bgArr[dayIndex - 3][2])
	end

	self:updateBtn()

	if self:checkCanShowQuiz() then
		self.tab:setTabActive(1, true)
	else
		self.tab:setTabActive(2, true)
		self.nav1None.gameObject:SetActive(true)
	end
end

function ActivityEntranceTestShowsWindow:updateQuiz()
	self.todayIndex = self.activityData:getDayIndex()
	local partners = self.activityData:getGambleInfo(self.todayIndex)

	for i = 1, 6 do
		if partners[1] and partners[1][i] then
			local partnerInfo = partners[1][i]
			local parent_ = self.player1bottomNode_

			if i <= 2 then
				parent_ = self.player1topNode_
			end

			partnerInfo.noClick = true
			partnerInfo.scale = 0.49074074074074076
			partnerInfo.uiRoot = parent_.gameObject

			xyd.getHeroIcon(partnerInfo)
			parent_:Reposition()
		end

		if partners[2] and partners[2][i] then
			local partnerInfo = partners[2][i]
			local parent_ = self.player2bottomNode_

			if i <= 2 then
				parent_ = self.player2topNode_
			end

			partnerInfo.noClick = true
			partnerInfo.scale = 0.49074074074074076
			partnerInfo.uiRoot = parent_.gameObject

			xyd.getHeroIcon(partnerInfo)
			parent_:Reposition()
		end
	end
end

function ActivityEntranceTestShowsWindow:onTouch(index)
	self.cur_select_ = index

	if index == 1 then
		self.scrollViewRecords_.gameObject:SetActive(false)
		self.guessNode:SetActive(true)
	else
		self.scrollViewRecords_.gameObject:SetActive(true)
		self.guessNode:SetActive(false)

		if not self.isInitRecord_ then
			self.isInitRecord_ = true

			self:waitForFrame(1, function ()
				self:updateRecord()
			end)
		end
	end
end

function ActivityEntranceTestShowsWindow:updateRecord()
	local list = {}
	local dayIndex = self.activityData:getDayIndex()

	if dayIndex >= 5 then
		for i = dayIndex - 1, 4, -1 do
			local daySec = os.date("*t", self.activityData.start_time + (i - 1) * 24 * 60 * 60)
			local dateStr = __("DATE_2", daySec.month, daySec.day)
			local itemData = {
				selfBet = self.activityData.detail.bet_records[i] or 0,
				isWin = self.activityData.detail.demo_records[i],
				id = i,
				dateStr = dateStr
			}

			if i < 7 then
				table.insert(list, itemData)
			end
		end
	end

	self.wrap_:setInfos(list, {})
end

function ActivityEntranceTestShowsWindow:updateBtn()
	local dayIndex = self.activityData:getDayIndex()
	local awardArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_cost", "value", "|#")
	local cost = {
		awardArr[1],
		awardArr[2],
		awardArr[1],
		awardArr[2]
	}

	for i = 1, 4 do
		xyd.setUISpriteAsync(self["guessbtnIcon" .. i], nil, xyd.tables.itemTable:getIcon(cost[i][1]))

		self["guessbtnIconLabel" .. i].text = xyd.getRoughDisplayNumber(cost[i][2])
	end

	local betID = self.activityData.detail.bet_records[dayIndex]

	if betID and betID ~= 0 then
		local betTeam = xyd.checkCondition(betID > 0, 1, 2)

		for i = 1, 2 do
			self["guessbtn" .. tostring((betTeam - 1) * 2 + i)]:SetActive(false)

			self["guessbtnLabel" .. tostring((betTeam - 1) * 2 + i)].text = __("ARENA_ALL_SERVER_TEXT_26")
		end

		local hideID = xyd.checkCondition(betID > 0, 2, 1)

		for i = 1, 2 do
			self["guessbtn" .. tostring((hideID - 1) * 2 + i)]:SetActive(math.abs(betID) == i)

			self["guessbtnLabel" .. tostring((hideID - 1) * 2 + i)].text = __("ENTRANCE_TEST_GUESS_CHANGE")
		end
	else
		for i = 1, 4 do
			self["guessbtnLabel" .. tostring(i)].text = __("ARENA_ALL_SERVER_TEXT_26")
		end
	end
end

function ActivityEntranceTestShowsWindow:checkCanShowQuiz()
	local ids = xyd.tables.activityEntranceTestGuessBattle:getIds()
	local dayIndex = self.activityData:getDayIndex()

	if dayIndex > 6 then
		return false
	end

	return true
end

function ActivitySportsGuessItem:ctor(go, parent)
	self.parent_ = parent

	ActivitySportsGuessItem.super.ctor(self, go)

	self.monster1List_ = {}
	self.monster2List_ = {}
end

function ActivitySportsGuessItem:initUI()
	ActivitySportsGuessItem.super.initUI(self)
	self:getUIComponent()
	self:registerEvent()
end

function ActivitySportsGuessItem:getUIComponent()
	self.labelMana_ = self.go:ComponentByName("groupCard/labelMana_", typeof(UILabel))
	self.icon = self.go:ComponentByName("groupCard/icon", typeof(UISprite))
	self.loseImg = self.go:NodeByName("loseImg").gameObject
	self.labelTips_ = self.go:ComponentByName("labelTips_", typeof(UILabel))
	self.imgIsHit_ = self.go:ComponentByName("imgIsHit_", typeof(UISprite))
	self.btnVideo_ = self.go:NodeByName("btnVideo_").gameObject
	self.imgResult1 = self.go:ComponentByName("imgResult1", typeof(UISprite))
	self.imgResult2 = self.go:ComponentByName("imgResult2", typeof(UISprite))
	self.topPlayer1 = self.go:ComponentByName("topPlayer1", typeof(UIGrid))
	self.topPlayer2 = self.go:ComponentByName("topPlayer2", typeof(UIGrid))
	self.bottomPlayer1 = self.go:ComponentByName("bottomPlayer1", typeof(UIGrid))
	self.bottomPlayer2 = self.go:ComponentByName("bottomPlayer2", typeof(UIGrid))
	self.bg1 = self.go:ComponentByName("bg1", typeof(UISprite))
	self.bg2 = self.go:ComponentByName("bg2", typeof(UISprite))
end

function ActivitySportsGuessItem:registerEvent()
	UIEventListener.Get(self.btnVideo_).onClick = handler(self, self.onVideoTouch)
end

function ActivitySportsGuessItem:onVideoTouch()
	if self.dayIndex then
		local msg = messages_pb.warmup_get_report_req()
		msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
		msg.id = self.dayIndex

		xyd.Backend.get():request(xyd.mid.WARMUP_GET_REPORT, msg)
	end
end

function ActivitySportsGuessItem:update(_, _, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.data = info
	self.dayIndex = info.id

	if self.dayIndex >= 4 and self.dayIndex <= 6 then
		local bgArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_team", "value", "|#")

		xyd.setUISpriteAsync(self.bg1, nil, "activity_entrance_test_bg_jl_" .. bgArr[self.dayIndex - 3][1])
		xyd.setUISpriteAsync(self.bg2, nil, "activity_entrance_test_bg_jl_" .. bgArr[self.dayIndex - 3][2])
	end

	local guessOk = false

	if self.data.selfBet < 0 and self.data.isWin == 0 then
		guessOk = true
	elseif self.data.selfBet > 0 and self.data.isWin == 1 then
		guessOk = true
	end

	self.labelTips_.text = self.data.dateStr
	local awardArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_award", "value", "|#")
	local costArr = xyd.tables.miscTable:split2Cost("activity_warmup_arena_guess_cost", "value", "|#")

	if not self.data.selfBet or self.data.selfBet == 0 then
		xyd.setUISpriteAsync(self.imgIsHit_, nil, "arena_as_bg_wcy_" .. xyd.Global.lang)
	elseif guessOk then
		xyd.setUISpriteAsync(self.imgIsHit_, nil, "arena_as_win_" .. xyd.Global.lang)
	else
		xyd.setUISpriteAsync(self.imgIsHit_, nil, "arena_as_lose_" .. xyd.Global.lang)
	end

	if awardArr[math.abs(self.data.selfBet)] and awardArr[math.abs(self.data.selfBet)][1] then
		xyd.setUISpriteAsync(self.icon, nil, xyd.tables.itemTable:getIcon(awardArr[math.abs(self.data.selfBet)][1]))
	end

	local manaStr = nil

	if guessOk then
		manaStr = "+" .. tostring(xyd.getRoughDisplayNumber(awardArr[math.abs(self.data.selfBet)][2]))
		self.labelMana_.color = Color.New2(227172351)
	elseif costArr[math.abs(self.data.selfBet)] and costArr[math.abs(self.data.selfBet)][2] then
		manaStr = "-" .. tostring(xyd.getRoughDisplayNumber(costArr[math.abs(self.data.selfBet)][2]))
	else
		manaStr = "0"
		self.labelMana_.color = Color.New2(3865139711.0)
	end

	self.labelMana_.text = manaStr

	if self.data.isWin == 1 then
		xyd.setUISpriteAsync(self.imgResult1, nil, "arena_as_win")
		xyd.setUISpriteAsync(self.imgResult2, nil, "arena_as_lose")
	else
		xyd.setUISpriteAsync(self.imgResult2, nil, "arena_as_win")
		xyd.setUISpriteAsync(self.imgResult1, nil, "arena_as_lose")
	end

	self:updatePartnerList()
end

function ActivitySportsGuessItem:updatePartnerList()
	local partners = self.parent_.activityData:getGambleInfo(self.data.id)

	for i = 1, 6 do
		if partners and partners[1] and partners[1][i] then
			local partnerInfo = partners[1][i]
			local parent_ = self.bottomPlayer1

			if i <= 2 then
				parent_ = self.topPlayer1
			end

			partnerInfo.noClick = true
			partnerInfo.scale = 0.49074074074074076
			partnerInfo.uiRoot = parent_.gameObject

			if self.monster1List_[i] then
				self.monster1List_[i]:SetActive(true)
				self.monster1List_[i]:setInfo(partnerInfo)
			else
				self.monster1List_[i] = xyd.getHeroIcon(partnerInfo)
			end
		elseif self.monster1List_[i] then
			self.monster1List_[i]:SetActive(false)
		end

		if partners and partners[2] and partners[2][i] then
			local partnerInfo = partners[2][i]
			local parent_ = self.bottomPlayer2

			if i <= 2 then
				parent_ = self.topPlayer2
			end

			partnerInfo.noClick = true
			partnerInfo.scale = 0.49074074074074076
			partnerInfo.uiRoot = parent_.gameObject

			if self.monster2List_[i] then
				self.monster2List_[i]:SetActive(true)
				self.monster2List_[i]:setInfo(partnerInfo)
			else
				self.monster2List_[i] = xyd.getHeroIcon(partnerInfo)
			end
		elseif self.monster2List_[i] then
			self.monster2List_[i]:SetActive(false)
		end
	end

	self.topPlayer1:Reposition()
	self.bottomPlayer1:Reposition()
	self.topPlayer2:Reposition()
	self.bottomPlayer2:Reposition()
end

return ActivityEntranceTestShowsWindow
