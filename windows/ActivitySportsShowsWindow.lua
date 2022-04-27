local ActivitySportsShowsWindow = class("ActivitySportsShowsWindow", import(".BaseWindow"))
local ResItem = import("app.components.ResItem")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local ActivitySportsGuessItem = class("ActivitySportsGuessItem", import("app.components.CopyComponent"))

function ActivitySportsShowsWindow:ctor(name, params)
	ActivitySportsShowsWindow.super.ctor(self, name, params)

	self.cur_select_ = 0
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)
end

function ActivitySportsShowsWindow:initWindow()
	ActivitySportsShowsWindow.super.initWindow(self)
	self:getComponent()
	self:registerEvent()
	self:layout()
	self:initTimeLabel()
end

function ActivitySportsShowsWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction").gameObject
	self.topBgImg_ = self.groupAction:ComponentByName("topBgImg", typeof(UISprite))
	self.winTitle_ = self.groupAction:ComponentByName("winTitle", typeof(UILabel))
	self.closeBtn_ = self.groupAction:NodeByName("closeBtn").gameObject
	self.helpBtn_ = self.groupAction:NodeByName("helpBtn").gameObject
	self.navGroup = self.groupAction:NodeByName("navGroup").gameObject
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
	self.guess1btn = self.guessNode:NodeByName("guess1btn").gameObject
	self.guess1btnLabel = self.guess1btn:ComponentByName("label", typeof(UILabel))
	self.guess2btn = self.guessNode:NodeByName("guess2btn").gameObject
	self.guess2btnLabel = self.guess2btn:ComponentByName("label", typeof(UILabel))
	self.player1topNode_ = self.guessNode:ComponentByName("player1topNode", typeof(UIGrid))
	self.player1bottomNode_ = self.guessNode:ComponentByName("player1bottomNode", typeof(UIGrid))
	self.player2topNode_ = self.guessNode:ComponentByName("player2topNode", typeof(UIGrid))
	self.player2bottomNode_ = self.guessNode:ComponentByName("player2bottomNode", typeof(UIGrid))
	self.recordsNone = self.groupAction:NodeByName("recordsNone").gameObject
	self.noneLabel = self.recordsNone:ComponentByName("noneLabel", typeof(UILabel))
end

function ActivitySportsShowsWindow:registerEvent()
	ActivitySportsShowsWindow.super.register(self)

	local dayIndex = self.activityData:getDayIndex()
	local monster1 = xyd.tables.activityDemoFightTable:getMonster1(dayIndex)
	local monster2 = xyd.tables.activityDemoFightTable:getMonster2(dayIndex)

	UIEventListener.Get(self.attrsBtn1).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sports_party_detail_window", {
			group = 1
		})
	end

	UIEventListener.Get(self.attrsBtn2).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sports_party_detail_window", {
			group = 2
		})
	end

	UIEventListener.Get(self.guess1btn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sports_shows_check_window", {
			color = 1,
			monster = monster1,
			dayIndex = dayIndex
		})
	end

	UIEventListener.Get(self.guess2btn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sports_shows_check_window", {
			color = 2,
			monster = monster2,
			dayIndex = dayIndex
		})
	end

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		local params = {
			key = self:winName() .. "_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	self.eventProxy_:addEventListener(xyd.event.SPORTS_BET, handler(self, self.onSportsBet))
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_DEMO_REPORT, handler(self, self.onReport))
end

function ActivitySportsShowsWindow:onReport(event)
	xyd.BattleController.get():sportShowsBattle(event.data.battle_result)
end

function ActivitySportsShowsWindow:onSportsBet(event)
	self:updateBtn()
	self.resCoin_:updateNum()
end

function ActivitySportsShowsWindow:initTimeLabel()
	local str = __("ENTRANCE_TEST_GUESS_COUNT_DOWN")
	local resTime = xyd.getTomorrowTime() - xyd.getServerTime()
	self.timeLabel_.text = str
	self.timeCount_.text = xyd.secondsToString(resTime)

	self.timeLayout_:Reposition()

	local function callback()
		resTime = resTime - 1
		self.timeCount_.text = xyd.secondsToString(resTime)

		if resTime <= 0 then
			xyd.alertTips(__("ACTIVITY_SPORTS_TIME_REFRESH"))
			xyd.models.activity:reqActivityByID(xyd.ActivityID.SPORTS)
			xyd.WindowManager.get():closeWindow(self.name_)
		end
	end

	self.labelTimer_ = self:getTimer(callback, 1, -1)

	self.labelTimer_:Start()
end

function ActivitySportsShowsWindow:layout()
	self.winTitle_.text = __("ACTIVITY_SPORTS_SHOWS_WINDOW")
	self.noneLabel.text = __("ACTIVITY_SPORTS_PLAYERRANK_TEXT4")
	self.resCoin_ = ResItem.new(self.groupResItem)

	self.resCoin_:setInfo({
		tableId = xyd.ItemID.SPORTS_TICKET
	})
	self.resCoin_:hidePlus()

	local str = __("ACTIVITY_SPORTS_SHOWS_WORD")
	local str = string.gsub(str, "0x(%w+)", "%1")
	local str = string.gsub(str, " size=(%w+)", "][size=%1")
	self.labelAwardTips_.text = str

	if xyd.Global.lang ~= "zh_tw" then
		self.labelAwardTips_.fontSize = 24
	end

	local colorParams = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = CommonTabBar.new(self.navGroup, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		if self.cur_select_ == index then
			return
		end

		if index == 1 and not self:checkCanShowQuiz() then
			return
		end

		self:onTouch(index)
	end, nil, colorParams)
	local tableLabels = xyd.split(__("ACTIVITY_SPORTS_SHOWS_LABELS"), "|")

	self.tab:setTexts(tableLabels)
	self:updateBtn()

	if self:checkCanShowQuiz() then
		self.tab:setTabActive(1, true)
		self:initQuiz()
	else
		self.tab:setTabActive(2, true)

		self.tab.tabs[1].tab.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
	end
end

function ActivitySportsShowsWindow:initQuiz()
	local dayIndex = self.activityData:getDayIndex()
	local monster1 = xyd.tables.activityDemoFightTable:getMonster1(dayIndex)
	local monster2 = xyd.tables.activityDemoFightTable:getMonster2(dayIndex)
	local MonsterTable = xyd.tables.monsterTable

	for i = 1, 6 do
		if monster1[i] then
			local tableID = monster1[i]
			local id = MonsterTable:getPartnerLink(tableID)
			local itemID = MonsterTable:getSkin(tableID)
			local lev = MonsterTable:getShowLev(tableID)
			local parent_ = self.player1bottomNode_

			if i <= 2 then
				parent_ = self.player1topNode_
			end

			xyd.getHeroIcon({
				scale = 0.49074074074074076,
				isMonster = true,
				noClick = true,
				uiRoot = parent_.gameObject,
				tableID = tableID,
				skin_id = itemID,
				lev = lev
			})
			parent_:Reposition()
		end

		if monster2[i] then
			local tableID = monster2[i]
			local id = MonsterTable:getPartnerLink(tableID)
			local itemID = MonsterTable:getSkin(tableID)
			local lev = MonsterTable:getShowLev(tableID)
			local parent_ = self.player2bottomNode_

			if i <= 2 then
				parent_ = self.player2topNode_
			end

			xyd.getHeroIcon({
				scale = 0.49074074074074076,
				isMonster = true,
				noClick = true,
				uiRoot = parent_.gameObject,
				tableID = tableID,
				skin_id = itemID,
				lev = lev
			})
			parent_:Reposition()
		end
	end
end

function ActivitySportsShowsWindow:onTouch(index)
	self.cur_select_ = index

	if index == 1 then
		self.scrollViewRecords_.gameObject:SetActive(false)
		self.guessNode:SetActive(true)
		self.recordsNone:SetActive(false)
	else
		self.scrollViewRecords_.gameObject:SetActive(true)
		self.guessNode:SetActive(false)

		if self.isShowNone then
			self.recordsNone:SetActive(true)
		else
			self.recordsNone:SetActive(false)
		end

		if not self.isInitRecord_ then
			self.isInitRecord_ = true

			self:waitForFrame(1, function ()
				self:updateRecord()
			end)
		end
	end
end

function ActivitySportsShowsWindow:updateRecord()
	local list = {}
	local dayIndex = self.activityData:getDayIndex()

	if dayIndex >= 2 then
		for i = dayIndex - 1, 1, -1 do
			local daySec = os.date("*t", self.activityData.start_time + (i - 1) * 24 * 60 * 60)
			local dateStr = __("DATE_2", daySec.month, daySec.day)
			local itemData = {
				selfBet = self.activityData.detail.bet_records[i],
				isWin = self.activityData.detail.demo_records[i],
				id = i,
				dateStr = dateStr
			}

			table.insert(list, itemData)
		end
	end

	self.wrap_:setInfos(list, {})

	if #list == 0 then
		self.isShowNone = true

		self.recordsNone:SetActive(true)
	else
		self.isShowNone = false

		self.recordsNone:SetActive(false)
	end
end

function ActivitySportsShowsWindow:updateBtn()
	local dayIndex = self.activityData:getDayIndex()
	local betID = self.activityData.detail.bet_records[dayIndex]

	if betID and betID ~= 0 then
		local betTeam = xyd.checkCondition(betID > 0, 1, 2)
		self["guess" .. tostring(betTeam) .. "btnLabel"].text = __("ACTIVITY_SPORTS_TEXT01")
		self["guess" .. tostring(betTeam) .. "btn"]:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false
		local hideID = xyd.checkCondition(betID > 0, 2, 1)

		self["guess" .. tostring(hideID) .. "btn"]:SetActive(false)
		self["attrsBtn" .. tostring(hideID)]:SetActive(false)
	else
		for i = 1, 2 do
			self["guess" .. tostring(i) .. "btnLabel"].text = __("ARENA_ALL_SERVER_TEXT_26")
		end
	end
end

function ActivitySportsShowsWindow:checkCanShowQuiz()
	local ids = xyd.tables.activityDemoFightTable:getIds()
	local dayIndex = self.activityData:getDayIndex()

	if dayIndex > #ids then
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
	self.loseImg = self.go:NodeByName("loseImg").gameObject
	self.winImg = self.go:NodeByName("winImg").gameObject
	self.labelTips_ = self.go:ComponentByName("labelTips_", typeof(UILabel))
	self.imgIsHit_ = self.go:ComponentByName("imgIsHit_", typeof(UISprite))
	self.btnVideo_ = self.go:NodeByName("btnVideo_").gameObject
	self.imgResult1 = self.go:ComponentByName("imgResult1", typeof(UISprite))
	self.imgResult2 = self.go:ComponentByName("imgResult2", typeof(UISprite))
	self.topPlayer1 = self.go:ComponentByName("topPlayer1", typeof(UIGrid))
	self.topPlayer2 = self.go:ComponentByName("topPlayer2", typeof(UIGrid))
	self.bottomPlayer1 = self.go:ComponentByName("bottomPlayer1", typeof(UIGrid))
	self.bottomPlayer2 = self.go:ComponentByName("bottomPlayer2", typeof(UIGrid))
end

function ActivitySportsGuessItem:registerEvent()
	UIEventListener.Get(self.btnVideo_).onClick = handler(self, self.onVideoTouch)
end

function ActivitySportsGuessItem:onVideoTouch()
	if self.dayIndex then
		local msg = messages_pb.sports_get_demo_report_req()
		msg.activity_id = xyd.ActivityID.SPORTS
		msg.id = self.dayIndex

		xyd.Backend.get():request(xyd.mid.SPORTS_GET_DEMO_REPORT, msg)
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
	local guessOk = false

	if self.data.selfBet < 0 and self.data.isWin == 0 then
		guessOk = true
	elseif self.data.selfBet > 0 and self.data.isWin == 1 then
		guessOk = true
	end

	self.labelTips_.text = self.data.dateStr
	local awardArr = xyd.tables.miscTable:split2Cost("activity_sports_guess_award", "value", "|#")

	if guessOk then
		xyd.setUISpriteAsync(self.imgIsHit_, nil, "arena_as_win_" .. xyd.Global.lang)
	else
		xyd.setUISpriteAsync(self.imgIsHit_, nil, "arena_as_lose_" .. xyd.Global.lang)
	end

	local manaStr = nil

	if guessOk then
		print("self.data.selfBet", self.data.selfBet)

		manaStr = "+" .. tostring(xyd.getRoughDisplayNumber(awardArr[math.abs(self.data.selfBet)][2]))
		self.labelMana_.color = Color.New2(227172351)
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

	self.loseImg:SetActive(self.data.isWin ~= 1)
	self.winImg:SetActive(self.data.isWin == 1)
	self:updatePartnerList()
end

function ActivitySportsGuessItem:updatePartnerList()
	local monster1 = xyd.tables.activityDemoFightTable:getMonster1(self.data.id)
	local monster2 = xyd.tables.activityDemoFightTable:getMonster2(self.data.id)
	local MonsterTable = xyd.tables.monsterTable

	for i = 1, 6 do
		if monster1[i] then
			local tableID = monster1[i]
			local id = MonsterTable:getPartnerLink(tableID)
			local itemID = MonsterTable:getSkin(tableID)
			local lev = MonsterTable:getShowLev(tableID)
			local parent_ = self.bottomPlayer1

			if i <= 2 then
				parent_ = self.topPlayer1
			end

			local params = {
				scale = 0.49074074074074076,
				isMonster = true,
				noClick = true,
				uiRoot = parent_.gameObject,
				tableID = tableID,
				skin_id = itemID,
				lev = lev
			}

			if self.monster1List_[i] then
				self.monster1List_[i]:SetActive(true)
				self.monster1List_[i]:setInfo(params)
			else
				self.monster1List_[i] = xyd.getHeroIcon(params)
			end
		elseif self.monster1List_[i] then
			self.monster1List_[i]:SetActive(false)
		end

		if monster2[i] then
			local tableID = monster2[i]
			local id = MonsterTable:getPartnerLink(tableID)
			local itemID = MonsterTable:getSkin(tableID)
			local lev = MonsterTable:getShowLev(tableID)
			local parent_ = self.bottomPlayer2

			if i <= 2 then
				parent_ = self.topPlayer2
			end

			local params = {
				scale = 0.49074074074074076,
				isMonster = true,
				noClick = true,
				uiRoot = parent_.gameObject,
				tableID = tableID,
				skin_id = itemID,
				lev = lev
			}

			if self.monster2List_[i] then
				self.monster2List_[i]:SetActive(true)
				self.monster2List_[i]:setInfo(params)
			else
				self.monster2List_[i] = xyd.getHeroIcon(params)
			end
		elseif self.monster2List_[i] then
			self.monster2List_[i]:SetActive(false)
		end
	end

	self.topPlayer1:Reposition()
	self.topPlayer2:Reposition()
	self.bottomPlayer1:Reposition()
	self.bottomPlayer2:Reposition()
end

return ActivitySportsShowsWindow
