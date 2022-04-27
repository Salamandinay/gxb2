local ArenaAllServerQuizWindow = class("ArenaAllServerQuizWindow", import(".BaseWindow"))
local CopyComponent = import("app.components.CopyComponent")
local ArenaAllServerQuizItem1 = class("ArenaAllServerQuizItem1", CopyComponent)
local ArenaAllServerQuizItem2 = class("ArenaAllServerQuizItem2", CopyComponent)
local ArenaAllServerQuizItem3 = class("ArenaAllServerQuizItem3", CopyComponent)
local ArenaAllServer = xyd.models.arenaAllServerNew
local CountDown = import("app.components.CountDown")
local AllServerPlayerIcon = import("app.components.AllServerPlayerIcon")
local PlayerIcon = import("app.components.PlayerIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ArenaAllServerQuizRecord = class("ArenaAllServerQuizRecord")
local ArenaAllServerQuizRecord2 = class("ArenaAllServerQuizRecord2")

function ArenaAllServerQuizWindow:ctor(name, params)
	ArenaAllServerQuizWindow.super.ctor(self, name, params)

	self.curIndex_ = 1
	self.contents_ = {}
end

function ArenaAllServerQuizWindow:initWindow()
	ArenaAllServerQuizWindow.super.initWindow()
	self:getUIComponent()
	self:initLayout()
	self:registerEvent()
end

function ArenaAllServerQuizWindow:getUIComponent()
	local winTrans = self.window_.transform
	local main = winTrans:NodeByName("main").gameObject
	self.helpBtn = main:NodeByName("helpBtn").gameObject
	self.closeBtn = main:NodeByName("closeBtn").gameObject
	self.labelWinTitle = main:ComponentByName("labelWinTitle", typeof(UILabel))

	for i = 1, 3 do
		self["nav" .. i] = main:NodeByName("nav/nav" .. i).gameObject
		self["item" .. i] = main:NodeByName("item" .. i).gameObject
	end

	self.groupNone_ = main:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
end

function ArenaAllServerQuizWindow:initLayout()
	self:changeTopTap()
	self:updateContent()

	self.nav1:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_5")
	self.nav2:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_6")
	self.nav3:ComponentByName("labelTips", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_7")
end

function ArenaAllServerQuizWindow:showNoneTips(flag, tips)
	if flag then
		self.labelNoneTips_.text = tips

		self.groupNone_:SetActive(true)
	else
		self.groupNone_:SetActive(false)
	end
end

function ArenaAllServerQuizWindow:registerEvent()
	self:register()

	for i = 1, 3 do
		UIEventListener.Get(self["nav" .. i]).onClick = function ()
			self:showNoneTips(false)

			self.curIndex_ = i

			self:changeTopTap()
			self:updateContent()
		end
	end

	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_BET, handler(self, self.onBet))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_BET_NEW, handler(self, self.onBet))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_CHANGE_BET, handler(self, self.onChangeBet))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_CHANGE_BET_NEW, handler(self, self.onChangeBet))
end

function ArenaAllServerQuizWindow:onBet()
	local item = self.contents_[1]

	if item then
		item:updateBtn()
		item:initPlayer()
	end
end

function ArenaAllServerQuizWindow:onChangeBet()
	xyd.showToast(__("ARENA_ALL_SERVER_QUIZ_SUCCESS"))
	self:onBet()
end

function ArenaAllServerQuizWindow:changeTopTap()
	local index = self.curIndex_

	for i = 1, 3 do
		local nav = self["nav" .. tostring(i)]
		local img = nav:NodeByName("selected").gameObject
		local flag = true

		if i == index then
			flag = false
		end

		img:SetActive(not flag)
		xyd.setTouchEnable(nav, flag)

		local label = nav:ComponentByName("labelTips", typeof(UILabel))

		if flag then
			label.color = Color.New2(960513791)
			label.effectColor = Color.New2(4294967295.0)
		else
			label.color = Color.New2(4294967295.0)
			label.effectColor = Color.New2(1012112383)
		end
	end
end

function ArenaAllServerQuizWindow:updateContent()
	if not self.contents_[self.curIndex_] then
		local item = nil

		if self.curIndex_ == 1 then
			item = ArenaAllServerQuizItem1.new(self.item1)
		elseif self.curIndex_ == 2 then
			item = ArenaAllServerQuizItem2.new(self.item2)
		elseif self.curIndex_ == 3 then
			item = ArenaAllServerQuizItem3.new(self.item3)
		end

		item:SetActive(true)
		item:setInfo()

		self.contents_[self.curIndex_] = item
	end

	for i = 1, 3 do
		if self.contents_[i] then
			self.contents_[i]:SetActive(false)
		end
	end

	self.contents_[self.curIndex_]:SetActive(true)
end

function ArenaAllServerQuizItem1:ctor(go)
	ArenaAllServerQuizItem1.super.ctor(self, go)

	self.cost_ = 0
end

function ArenaAllServerQuizItem1:initUI()
	ArenaAllServerQuizItem1.super.initUI(self)

	self.groupMain_ = self.go:NodeByName("groupMain_").gameObject
	self.labelTips_ = self.groupMain_:ComponentByName("labelTips_", typeof(UILabel))
	local labelCountDownNode_ = self.groupMain_:ComponentByName("groupTime_/labelCountDown_", typeof(UILabel))
	self.imgAwardTips_ = self.groupMain_:ComponentByName("imgAwardTips_", typeof(UISprite))
	self.labelMana_ = self.groupMain_:ComponentByName("groupMana/labelMana_", typeof(UILabel))
	self.player1 = self.groupMain_:NodeByName("player1").gameObject
	self.player2 = self.groupMain_:NodeByName("player2").gameObject
	self.groupLockTimer = self.groupMain_:NodeByName("groupLockTimer").gameObject
	self.labelTimeTips_ = self.groupLockTimer:ComponentByName("labelTimeTips_", typeof(UILabel))
	local labelLockTimeNode = self.groupLockTimer:ComponentByName("labelLockTime_", typeof(UILabel))
	self.labelLockTime_ = CountDown.new(labelLockTimeNode)

	for i = 1, 2 do
		self["player" .. i] = self.groupMain_:NodeByName("player" .. i).gameObject
		self["groupSupport" .. i] = self.groupMain_:NodeByName("groupSupport" .. i).gameObject
		self["labelSupport" .. i] = self["groupSupport" .. i]:ComponentByName("labelSupport" .. i, typeof(UILabel))
		self["labelSupportNum" .. i] = self["groupSupport" .. i]:ComponentByName("e:Group/labelSupportNum" .. i, typeof(UILabel))
		self["btn" .. i] = self.groupMain_:NodeByName("btn" .. i).gameObject
		self["btnChangeQuiz" .. i] = self.groupMain_:NodeByName("btnChangeQuiz" .. i).gameObject
	end

	self.labelCountDown_ = CountDown.new(labelCountDownNode_)

	self:registerEvent()
end

function ArenaAllServerQuizItem1:setInfo()
	self:layout()
end

function ArenaAllServerQuizItem1:showNoneTips()
	local wnd = xyd.WindowManager.get():getWindow("arena_all_server_quiz_window")

	if wnd then
		wnd:showNoneTips(true, __("ARENA_ALL_SERVER_TEXT_10"))
	end
end

function ArenaAllServerQuizItem1:layout()
	self.labelSupport1.text = __("ARENA_ALL_SERVER_TEXT_32")
	self.labelSupport2.text = __("ARENA_ALL_SERVER_TEXT_32")
	self.labelTimeTips_.text = __("LOCK_COUNT_DOWN")
	local pickPlayers = ArenaAllServer:getPickPlayers()
	local round = ArenaAllServer:getCurRound()

	if round > 6 or not pickPlayers or not pickPlayers[1] then
		self:showNoneTips()
		self.groupMain_:SetActive(false)
	else
		self.labelTips_.text = __("ARENA_ALL_SERVER_TEXT_9") .. __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(ArenaAllServer:getCurRound()))
		local source = "arena_as_quiz_" .. xyd.Global.lang

		xyd.setUISpriteAsync(self.imgAwardTips_, nil, source, nil, , true)
		self:initCost()
		self:initPlayer()
		self:updateBtn()

		local time = ArenaAllServer:getNextFightTime()

		self.labelCountDown_:setInfo({
			duration = time
		})

		if time - 7200 > 0 then
			self.labelLockTime_:setInfo({
				duration = time - 7200
			})
		else
			self.labelLockTime_.labelComp.text = __("ARENA_ALL_SERVER_GROUP_LOCK")
		end
	end
end

function ArenaAllServerQuizItem1:initCost()
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local currentStage = mapInfo.current_stage
	local maxStage = mapInfo.max_stage > 0 and mapInfo.max_stage or 1
	local goldData = xyd.split(xyd.tables.stageTable:getGold(maxStage), "#", true)
	self.cost_ = goldData[2] * xyd.tables.miscTable:getNumber("arena_all_server_bet_times", "value")
end

function ArenaAllServerQuizItem1:registerEvent()
	UIEventListener.Get(self.btn1).onClick = function ()
		self:onBtnTouch(1)
	end

	UIEventListener.Get(self.btn2).onClick = function ()
		self:onBtnTouch(2)
	end

	for i = 1, 2 do
		self["btnChangeQuiz" .. i]:ComponentByName("button_label", typeof(UILabel)).text = __("ARENA_ALL_SERVER_QUIZ_CHANGE")

		UIEventListener.Get(self["btnChangeQuiz" .. i]).onClick = function ()
			self:onChangeQuizTouch(i)
		end
	end
end

function ArenaAllServerQuizItem1:onBtnTouch(index)
	if xyd.isItemAbsence(xyd.ItemID.MANA, self.cost_, true) then
		return
	end

	local pickPlayers = ArenaAllServer:getPickPlayers()

	if not pickPlayers[index] then
		return
	end

	local playerID = pickPlayers[index].player_id
	local round = ArenaAllServer:getCurRound()

	if round > 3 and ArenaAllServer:checkAlive(xyd.Global.playerID) and playerID ~= xyd.Global.playerID then
		xyd.alert(xyd.AlertType.TIPS, __("ARENA_ALL_SERVER_TEXT_30"))

		return
	end

	xyd.alert(xyd.AlertType.YES_NO, __("ARENA_ALL_SERVER_TEXT_29", xyd.getRoughDisplayNumber(self.cost_)), function (yes)
		if yes then
			ArenaAllServer:reqQuiz(playerID)
		end
	end)
end

function ArenaAllServerQuizItem1:onChangeQuizTouch(index)
	local pickPlayers = ArenaAllServer:getPickPlayers()

	if not pickPlayers[index] then
		return
	end

	local playerID = pickPlayers[index].player_id
	local round = ArenaAllServer:getCurRound()

	if round > 3 and ArenaAllServer:checkAlive(xyd.Global.playerID) and playerID ~= xyd.Global.playerID then
		xyd.alert(xyd.AlertType.TIPS, __("ARENA_ALL_SERVER_TEXT_30"))

		return
	end

	if not ArenaAllServer:checkChangeTime() then
		return
	end

	ArenaAllServer:reqChangeQuiz(playerID)
end

function ArenaAllServerQuizItem1:initPlayer()
	local pickPlayers = ArenaAllServer:getPickPlayers()

	for i = 1, #pickPlayers do
		local playerInfo = pickPlayers[i]
		local parent = self["player" .. i]

		NGUITools.DestroyChildren(parent.transform)

		local item = AllServerPlayerIcon.new(parent)
		local isShowQuiz = false
		local curRound = ArenaAllServer:getCurRound()
		local betInfo = ArenaAllServer:getBetInfoByRound(curRound)

		if betInfo and betInfo.win_player_id and betInfo.win_player_id == playerInfo.player_id then
			isShowQuiz = true
		end

		item:setInfo(playerInfo, {
			type = "s_106_2",
			is_quiz = true,
			show_effect = true,
			show_quiz = isShowQuiz
		})
	end
end

function ArenaAllServerQuizItem1:updateBtn()
	local info = ArenaAllServer:getCurRoundBetInfo()

	if info and info.win_player_id then
		self.btn1:SetActive(false)
		self.btn2:SetActive(false)

		local pickPlayers = ArenaAllServer:getPickPlayers()
		local curRound = ArenaAllServer:getCurRound()
		local betInfo = ArenaAllServer:getBetInfoByRound(curRound)

		for i = 1, #pickPlayers do
			local playerInfo = pickPlayers[i]

			if betInfo and betInfo.win_player_id and betInfo.win_player_id == playerInfo.player_id then
				self["btnChangeQuiz" .. i]:SetActive(false)
			else
				self["btnChangeQuiz" .. i]:SetActive(true)
			end
		end
	else
		self.btn1:SetActive(true)
		self.btn2:SetActive(true)

		self.btn1:ComponentByName("button_label", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_26")
		self.btn1:ComponentByName("labelCost", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.cost_)
		self.btn2:ComponentByName("button_label", typeof(UILabel)).text = __("ARENA_ALL_SERVER_TEXT_26")
		self.btn2:ComponentByName("labelCost", typeof(UILabel)).text = xyd.getRoughDisplayNumber(self.cost_)
	end

	local rate = ArenaAllServer:getPickSupportRate()
	self.labelSupportNum1.text = tostring(math.ceil(rate[1] * 100)) .. "%"
	self.labelSupportNum2.text = tostring(math.floor(rate[2] * 100)) .. "%"
	self.labelMana_.text = xyd.getRoughDisplayNumber(xyd.models.backpack:getMana())
end

function ArenaAllServerQuizItem2:ctor(go)
	ArenaAllServerQuizItem2.super.ctor(self, go)
end

function ArenaAllServerQuizItem2:initUI()
	ArenaAllServerQuizItem2.super.initUI(self)

	self.groupMain_ = self.go:NodeByName("groupMain_").gameObject
	local scrollView = self.groupMain_:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList", typeof(UIWrapContent))
	local item = scrollView:NodeByName("recordItem").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, item, ArenaAllServerQuizRecord, self)

	self:registerEvent()
end

function ArenaAllServerQuizItem2:setInfo()
	self:layout()
end

function ArenaAllServerQuizItem2:layout()
	self:initList()
end

function ArenaAllServerQuizItem2:showNoneTips()
	local wnd = xyd.WindowManager.get():getWindow("arena_all_server_quiz_window")

	if wnd then
		wnd:showNoneTips(true, __("ARENA_ALL_SERVER_TEXT_10"))
	end
end

function ArenaAllServerQuizItem2:initList()
	local data = {}
	local betInfo = ArenaAllServer:getBetInfo()

	for i = 6, 1, -1 do
		if betInfo[i] and betInfo[i].is_win ~= -1 then
			table.insert(data, {
				round = i,
				info = betInfo[i]
			})
		end
	end

	if #data == 0 then
		self.groupMain_:SetActive(false)
		self:showNoneTips()

		return
	end

	self.wrapContent_:setInfos(data, {})
end

function ArenaAllServerQuizItem2:registerEvent()
end

function ArenaAllServerQuizRecord:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.reportIDs_ = {}

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
	self:registerEvent()
end

function ArenaAllServerQuizRecord:getGameObject()
	return self.go
end

function ArenaAllServerQuizRecord:initUI()
	self.labelTips_ = self.go:ComponentByName("labelTips_", typeof(UILabel))
	self.labelMana_ = self.go:ComponentByName("groupMana/labelMana_", typeof(UILabel))
	self.imgIsHit_ = self.go:ComponentByName("imgIsHit_", typeof(UISprite))
	self.btnVideo_ = self.go:NodeByName("btnVideo_").gameObject

	for i = 1, 2 do
		self["player" .. i] = self.go:NodeByName("player" .. i).gameObject
		self["labelGuildName" .. i] = self["player" .. i]:ComponentByName("labelGuildName" .. i, typeof(UILabel))
		self["labelPlayerName" .. i] = self["player" .. i]:ComponentByName("labelPlayerName" .. i, typeof(UILabel))
		self["imgResult" .. i] = self["player" .. i]:ComponentByName("imgResult" .. i, typeof(UISprite))
		self["imgQuiz" .. i] = self["player" .. i]:ComponentByName("imgQuiz" .. i, typeof(UISprite))
		self["avatarGroup" .. i] = self["player" .. i]:NodeByName("avatarGroup" .. i).gameObject
	end
end

function ArenaAllServerQuizRecord:registerEvent()
	UIEventListener.Get(self.btnVideo_).onClick = handler(self, self.onVideoTouch)
end

function ArenaAllServerQuizRecord:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function ArenaAllServerQuizRecord:onVideoTouch()
	if not self.reportIDs_ or not self.reportIDs_[1] then
		return
	end

	xyd.WindowManager:get():openWindow("arena_3v3_record_detail_window", {
		report_ids = self.reportIDs_,
		model = ArenaAllServer
	})
end

function ArenaAllServerQuizRecord:updateInfo()
	self.labelTips_.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(self.data.round))
	local info = self.data.info
	local isWin = info.is_win == 1

	self:initPlayer(1, info.win_player_show_info or {}, isWin)
	self:initPlayer(2, info.lose_player_show_info or {}, not isWin)

	local hitSrc = xyd.checkCondition(isWin, "arena_as_win_" .. xyd.lang, "arena_as_lose_" .. xyd.lang)

	xyd.setUISpriteAsync(self.imgIsHit_, nil, hitSrc)

	local manaStr = isWin and "+" or "-"

	if isWin then
		manaStr = tostring(manaStr) .. tostring(xyd.getRoughDisplayNumber(info.items[2]))
	else
		manaStr = tostring(manaStr) .. tostring(xyd.getRoughDisplayNumber(info.items[2]))
	end

	self.labelMana_.text = manaStr
	self.labelMana_.color = isWin and Color.New2(227172351) or Color.New2(3865139711.0)
	local winPlayerID = xyd.checkCondition(isWin, info.win_player_id, info.lose_player_id)
	self.reportIDs_ = ArenaAllServer:getReportIds(self.data.round, winPlayerID)
end

function ArenaAllServerQuizRecord:initPlayer(index, playerInfo, isWin)
	local guildName = playerInfo.guild_name

	if not guildName or guildName == "" then
		guildName = __("ARENA_ALL_SERVER_TEXT_14")
	end

	self["labelGuildName" .. tostring(index)].text = guildName
	self["labelPlayerName" .. tostring(index)].text = playerInfo.player_name or ""
	local source = isWin and "arena_as_win" or "arena_as_lose"

	xyd.setUISpriteAsync(self["imgResult" .. tostring(index)], nil, source)

	local playerIcon = PlayerIcon.new(self["avatarGroup" .. tostring(index)])

	playerIcon:setInfo(playerInfo)
end

function ArenaAllServerQuizItem3:ctor(go)
	ArenaAllServerQuizItem3.super.ctor(self, go)

	self.showIndex_ = 0
end

function ArenaAllServerQuizItem3:initUI()
	ArenaAllServerQuizItem3.super.initUI(self)

	self.groupMain_ = self.go:NodeByName("groupMain_").gameObject
	self.labelTips_ = self.groupMain_:ComponentByName("top/labelTips_", typeof(UILabel))
	self.labelMana_ = self.groupMain_:ComponentByName("top/groupMana/labelMana_", typeof(UILabel))
	local bottom = self.groupMain_:NodeByName("bottom").gameObject
	self.labelTips2_ = bottom:ComponentByName("labelTips2_", typeof(UILabel))
	self.labelTips3_ = bottom:ComponentByName("labelTips3_", typeof(UILabel))
	local scrollView = bottom:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = scrollView:ComponentByName("itemList_", typeof(UIWrapContent))
	local item = scrollView:NodeByName("recordItem").gameObject
	self.wrapContent_ = FixedWrapContent.new(scrollView, wrapContent, item, ArenaAllServerQuizRecord2, self)
end

function ArenaAllServerQuizItem3:setInfo()
	self:layout()
end

function ArenaAllServerQuizItem3:layout()
	self.labelTips_.text = __("ARENA_ALL_SERVER_TEXT_11")
	self.labelTips2_.text = __("ARENA_ALL_SERVER_TEXT_12")
	self.labelTips3_.text = __("ARENA_ALL_SERVER_TEXT_13")

	self:initList()
end

function ArenaAllServerQuizItem3:initList()
	local data = {}
	local totalNum = 0
	local betInfo = ArenaAllServer:getBetInfo()

	for i = 1, 6 do
		if betInfo[i] and betInfo[i].is_win ~= -1 then
			table.insert(data, {
				round = i,
				info = betInfo[i]
			})

			local curNum = betInfo[i].items[2]
			local isWin = betInfo[i].is_win
			totalNum = totalNum + xyd.checkCondition(isWin and isWin == 1, curNum, -curNum)
		else
			table.insert(data, {
				round = i
			})
		end
	end

	if totalNum == 0 then
		self.labelMana_.text = "0"
		self.labelMana_.color = Color.New2(227172351)
	elseif totalNum > 0 then
		self.labelMana_.text = "+" .. tostring(xyd.getRoughDisplayNumber(totalNum))
		self.labelMana_.color = Color.New2(227172351)
	else
		self.labelMana_.text = xyd.getRoughDisplayNumber(totalNum)
		self.labelMana_.color = Color.New2(3865139711.0)
	end

	self.wrapContent_:setInfos(data, {})
end

function ArenaAllServerQuizRecord2:ctor(go, parent)
	self.go = go
	self.parent = parent

	xyd.setDragScrollView(go, parent.scrollView)
	self:initUI()
end

function ArenaAllServerQuizRecord2:getGameObject()
	return self.go
end

function ArenaAllServerQuizRecord2:initUI()
	self.imgDot_ = self.go:NodeByName("imgDot_").gameObject
	self.labelMana_ = self.go:ComponentByName("groupMana/labelMana_", typeof(UILabel))
	self.labelTips_ = self.go:ComponentByName("labelTips_", typeof(UILabel))
	self.imgIsHit_ = self.go:ComponentByName("imgIsHit_", typeof(UISprite))
end

function ArenaAllServerQuizRecord2:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.data = info

	self.go:SetActive(true)
	self:updateInfo()
end

function ArenaAllServerQuizRecord2:updateInfo()
	local info = self.data.info
	self.labelTips_.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(self.data.round))

	if info then
		local isWin = info.is_win

		self.imgIsHit_:SetActive(true)

		local source = xyd.checkCondition(isWin and isWin == 1, "arena_as_win_" .. xyd.lang, "arena_as_lose_" .. xyd.lang)

		xyd.setUISpriteAsync(self.imgIsHit_, nil, source)

		local manaStr = xyd.checkCondition(isWin and isWin == 1, "+", "-")

		if isWin and isWin == 1 then
			manaStr = tostring(manaStr) .. tostring(xyd.getRoughDisplayNumber(info.items[2]))
		else
			manaStr = tostring(manaStr) .. tostring(xyd.getRoughDisplayNumber(info.items[2]))
		end

		self.labelMana_.text = manaStr
		self.labelMana_.color = xyd.checkCondition(isWin and isWin == 1, Color.New2(227172351), Color.New2(3865139711.0))
	else
		self.imgIsHit_:SetActive(false)

		self.labelMana_.text = "0"
		self.labelMana_.color = Color.New2(227172351)
	end

	if self.data.round == 6 then
		self.imgDot_:SetActive(false)
	else
		self.imgDot_:SetActive(true)
	end
end

return ArenaAllServerQuizWindow
