local ActivityPopularityVoteWindow = class("ActivityPopularityVoteWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local PartnerCardItem = class("PartnerCardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local ChampItem = class("ChampItem", import("app.common.ui.FixedMultiWrapContentItem"))
local cjson = require("cjson")
local showPosition = {
	[756006] = {
		scale = 0.85,
		x = 36,
		y = -589
	},
	[756008] = {
		scale = 0.85,
		x = 0,
		y = -750
	},
	[755006] = {
		scale = 0.85,
		x = 60,
		y = -650
	},
	[755007] = {
		scale = 0.85,
		x = 0,
		y = -720
	},
	[755008] = {
		scale = 0.8,
		x = 50,
		y = -740
	},
	[751013] = {
		scale = 0.85,
		x = -40,
		y = -790
	},
	[752016] = {
		scale = 0.85,
		x = 50,
		y = -750
	},
	[752014] = {
		scale = 0.85,
		x = 20,
		y = -600
	}
}

function ActivityPopularityVoteWindow:ctor(name, params)
	ActivityPopularityVoteWindow.super.ctor(self, name, params)

	self.showMission = true
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

	self.activityData:checkPeriodData()
end

function ActivityPopularityVoteWindow:initWindow()
	xyd.models.activity:reqActivityByID(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityPopularityVoteWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain").gameObject
	self.helpBtn = groupMain:NodeByName("helpBtn").gameObject
	self.awardBtn = groupMain:NodeByName("awardBtn").gameObject
	self.rankBtn = groupMain:NodeByName("rankBtn").gameObject
	self.textLogo = groupMain:ComponentByName("textLogo", typeof(UISprite))
	self.taskBtn = groupMain:NodeByName("taskBtn").gameObject
	self.taskLabel = self.taskBtn:ComponentByName("taskLabel", typeof(UILabel))
	self.taskRedPoint = self.taskBtn:NodeByName("red_point").gameObject
	self.scheduleBtn = groupMain:NodeByName("scheduleBtn").gameObject
	self.scheduleLabel = self.scheduleBtn:ComponentByName("scheduleLabel", typeof(UILabel))
	self.supportBtn = groupMain:NodeByName("supportBtn").gameObject
	self.supportLabel = self.supportBtn:ComponentByName("supportLabel", typeof(UILabel))
	self.periodLabel = groupMain:ComponentByName("periodLabel", typeof(UILabel))
	self.timeGroup = groupMain:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelEnd = self.timeGroup:ComponentByName("labelEnd", typeof(UILabel))
	self.parterCard = groupMain:NodeByName("parterCard").gameObject
	self.champItem = groupMain:NodeByName("champItem").gameObject
	self.scrollView = groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
	self.championGroup = groupMain:NodeByName("championGroup").gameObject
	self.championGirl = groupMain:ComponentByName("championGirl", typeof(UITexture))

	if UNITY_EDITOR then
		local testInput = groupMain:NodeByName("test_input_component").gameObject

		testInput:SetActive(true)

		local input = testInput:ComponentByName("main/input", typeof(UIInput))
		local btnSure = testInput:NodeByName("main/btnSure").gameObject

		UIEventListener.Get(btnSure).onClick = function ()
			self:testShow(input.value or 0)
		end
	end
end

function ActivityPopularityVoteWindow:testShow(partner_id)
	local name = xyd.tables.partnerTable:getName(partner_id)

	if not name then
		xyd.showToast("没这个战姬")

		return
	end

	self.parterCard:SetActive(false)
	self.champItem:SetActive(false)
	self.taskBtn:SetActive(false)
	self.scrollView:SetActive(false)
	self.championGroup:SetActive(true)
	self.championGirl:SetActive(true)
	self.rankBtn:SetActive(true)
	self.supportBtn:SetActive(false)
	self.scheduleBtn:Y(-56)
	self.championGroup:Y(-1068 + self.scale_num_ * 110)

	self.championGroup:ComponentByName("rankLabel", typeof(UILabel)).text = "1"
	self.championGroup:ComponentByName("partnerName", typeof(UILabel)).text = name
	self.championGroup:ComponentByName("voteNumLabel", typeof(UILabel)).text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1") .. " :\n1234"
	local res = xyd.tables.partnerPictureTable:getPartnerPic(partner_id)

	xyd.setUITextureByNameAsync(self.championGirl, res)

	local position = showPosition[tonumber(partner_id)]
	local scale = position and position.scale or xyd.tables.partnerPictureTable:getPartnerPicScale(partner_id)

	self.championGirl:SetLocalScale(scale, scale, scale)

	if position then
		self.championGirl:SetLocalPosition(position.x, position.y, 0)
	end
end

function ActivityPopularityVoteWindow:layout()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_popularity_vote_" .. xyd.Global.lang)

	self.taskLabel.text = __("MISSION")
	self.scheduleLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT5")
	self.supportLabel.text = __("ACTIVITY_POPULARITY_VOTE_TEXT04")

	if xyd.Global.lang == "ja_jp" then
		self.taskLabel.fontSize = 20

		self.taskLabel:X(10)

		self.scheduleLabel.fontSize = 20

		self.scheduleLabel:X(20)
	elseif xyd.Global.lang == "fr_fr" then
		self.scheduleLabel:X(10)

		self.supportLabel.width = 120

		self.supportBtn:X(290)
	elseif xyd.Global.lang == "de_de" then
		self.supportLabel.width = 120

		self.supportBtn:X(290)
	end

	xyd.models.redMark:setMarkImg(xyd.RedMarkType.ACTIVITY_POPULARITY_VOTE_AWARD, self.taskRedPoint)
	self.championGroup:SetActive(false)
	self:initTop(false)
end

function ActivityPopularityVoteWindow:initTop(hasData)
	if not self.windowTop then
		self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	end

	local hidePlus = false

	local function callback()
		self:openDailyTaskWindow()
	end

	if not hasData then
		callback = nil
		hidePlus = true
	end

	if self.showMission == false then
		hidePlus = true
		callback = nil
	end

	local items = {
		{
			id = xyd.ItemID.POPULARITY_TICKET,
			hidePlus = hidePlus,
			callback = callback
		},
		{
			id = xyd.ItemID.SUPPORT_TICKET,
			hidePlus = hidePlus,
			callback = callback
		}
	}

	self.windowTop:setItem(items)
end

function ActivityPopularityVoteWindow:checkPeriod()
	local curDay = (xyd.getServerTime() - self.activityData.start_time) / 86400
	local periodList = xyd.split(xyd.tables.miscTable:getVal("activity_popularity_vote_stagetime"), "|", true)
	self.curPeriod = 1

	for k, v in ipairs(periodList) do
		if curDay < v then
			self.curPeriod = k

			break
		end
	end

	self.periodLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT" .. self.curPeriod + 17)
	self.labelEnd.text = __("END")
	local duration = self.activityData.start_time + periodList[self.curPeriod] * 86400 - xyd.getServerTime()
	local timeCount = import("app.components.CountDown").new(self.labelTime)

	timeCount:setInfo({
		function ()
			xyd.WindowManager.get():closeWindow("activity_popularity_vote_window")
		end,
		duration = duration
	})

	if xyd.Global.lang == "fr_fr" then
		self.labelEnd.transform:SetSiblingIndex(0)
	end

	self.timeGroup:Reposition()

	if self.curPeriod <= 4 then
		self.championGroup:SetActive(false)
		self.championGirl:SetActive(false)
		self.rankBtn:SetActive(false)
		self.supportBtn:SetActive(true)

		self.refreshContent = self.refreshContent1

		self:qualifiers()

		if self.activityData.history[self.curPeriod] then
			self:refreshContent()
		end
	elseif self.curPeriod <= 9 then
		self.championGroup:SetActive(false)
		self.championGirl:SetActive(false)
		self.rankBtn:SetActive(false)
		self.supportBtn:SetActive(true)

		self.refreshContent = self.refreshContent2

		self:championships()
		dump(self.activityData.history[self.curPeriod])

		if self.activityData.history[self.curPeriod] then
			self:refreshContent()
		end
	else
		self.showMission = false

		self.championGroup:SetActive(true)
		self.championGirl:SetActive(true)
		self.rankBtn:SetActive(true)
		self.supportBtn:SetActive(false)

		if self.activityData.history[9] then
			self:showPeriod()
		end
	end
end

function ActivityPopularityVoteWindow:qualifiers()
	self.champItem:SetActive(false)

	self.wrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.groupContent, self.parterCard, PartnerCardItem, self)
end

function ActivityPopularityVoteWindow:championships()
	self.parterCard:SetActive(false)

	self.groupContent.rowNum = 1
	self.groupContent.rowWidth = 557
	self.groupContent.itemSize = 415

	self.groupContent:X(0)

	self.wrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.groupContent, self.champItem, ChampItem, self)

	if self.curPeriod == 9 then
		self:waitForFrame(1, function ()
			self.groupContent:Y(-690 + self.scale_num_ * 75)
		end)
	end
end

function ActivityPopularityVoteWindow:showPeriod()
	local nowdata = self.activityData.history[9]
	local partner_id = nowdata[1][1].table_id

	self.activityData:reqRankListByParner(partner_id)
	self.parterCard:SetActive(false)
	self.champItem:SetActive(false)
	self.taskBtn:SetActive(false)
	self.scheduleBtn:Y(-56)
	self.championGroup:Y(-1068 + self.scale_num_ * 110)

	self.championGroup:ComponentByName("rankLabel", typeof(UILabel)).text = "1"
	self.championGroup:ComponentByName("partnerName", typeof(UILabel)).text = xyd.tables.partnerTable:getName(partner_id)
	self.championGroup:ComponentByName("voteNumLabel", typeof(UILabel)).text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1") .. " :\n" .. nowdata[1][1].score
	local res = xyd.tables.partnerPictureTable:getPartnerPic(partner_id)

	xyd.setUITextureByNameAsync(self.championGirl, res)

	local position = showPosition[tonumber(partner_id)]
	local scale = position and position.scale or xyd.tables.partnerPictureTable:getPartnerPicScale(partner_id)

	self.championGirl:SetLocalScale(scale, scale, scale)

	if position then
		self.championGirl:SetLocalPosition(position.x, position.y, 0)
	end
end

function ActivityPopularityVoteWindow:shuffle(list)
	local playerId = xyd.models.selfPlayer.playerID_
	local len = #list

	for i = 1, len do
		local seed = tonumber(playerId) + i * 107
		seed = tonumber(string.reverse(tostring(seed)))

		math.randomseed(seed)

		local index = math.ceil(math.random() * len)
		local temp = list[index]
		list[index] = list[i]
		list[i] = temp
	end
end

function ActivityPopularityVoteWindow:refreshContent1()
	local partnerList = {}

	for _, item in ipairs(self.activityData.history[self.curPeriod][1]) do
		table.insert(partnerList, item)
	end

	if partnerList[1].score == 0 then
		table.sort(partnerList, function (a, b)
			return b.table_id < a.table_id
		end)
		self:shuffle(partnerList)
	else
		partnerList[1].rank = 1

		for i = 2, 4 do
			if partnerList[i].score == 0 then
				break
			end

			if partnerList[i].score < partnerList[i - 1].score then
				partnerList[i].rank = i
			else
				partnerList[i].rank = partnerList[i - 1].rank
			end
		end

		for i = 5, #partnerList do
			if partnerList[i].score > 0 and partnerList[i].score == partnerList[4].score then
				partnerList[i].rank = partnerList[4].rank
			else
				break
			end
		end

		table.sort(partnerList, function (a, b)
			return b.table_id < a.table_id
		end)
		self:shuffle(partnerList)
	end

	self.wrapContent:setInfos(partnerList, {})
end

function ActivityPopularityVoteWindow:refreshContent2(keepPosition)
	local chamList = {}
	local tmpList = {}
	local startPos = xyd.Global.playerID % 4 + 1

	dump(self.activityData.history[self.curPeriod])

	for _, list in ipairs(self.activityData.history[self.curPeriod]) do
		table.insert(tmpList, list)
	end

	for i = 1, #tmpList do
		if startPos > #tmpList then
			startPos = 1
		end

		table.insert(chamList, tmpList[startPos])

		startPos = startPos + 1
	end

	self.wrapContent:setInfos(chamList, {
		keepPosition = keepPosition
	})
end

function ActivityPopularityVoteWindow:onVote(event)
end

function ActivityPopularityVoteWindow:onAward(event)
	if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_POPULARITY_VOTE then
		return
	end

	local detail = cjson.decode(event.data.detail)

	if detail.type ~= 1 then
		return
	end

	local mission_id = detail.mission_id
	self.activityData.detail_.mission_awarded[mission_id] = 1

	self.activityData:getRedMarkState()
end

function ActivityPopularityVoteWindow:onMissionInfo(event)
	local missionCount = event.data.mission_count
	local missionAwarded = event.data.mission_awarded
	local voteAwarded = event.data.vote_awarded

	for i = 1, #missionCount do
		self.activityData.detail_.mission_count[i] = missionCount[i]
	end

	for i = 1, #missionAwarded do
		self.activityData.detail_.mission_awarded[i] = missionAwarded[i]
	end

	for i = 1, #voteAwarded do
		self.activityData.detail_.vote_awarded[i] = voteAwarded[i]
	end

	self.activityData.detail_.vote_num = event.data.vote_num
end

function ActivityPopularityVoteWindow:onActivityInfo()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

	if self.needOpenTaskWindow then
		self.needOpenTaskWindow = false

		xyd.WindowManager.get():openWindow("activity_task_get_award_window", {
			hasNav = false,
			titleText = __("MISSION"),
			tipsText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT9"),
			taskList = self:getDailyTaskList(),
			activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
		})

		return
	end

	self:checkPeriod()
	self.activityData:reqVoteRankList(math.min(9, self.curPeriod))
	self:initTop(true)
end

function ActivityPopularityVoteWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_POPULARITY_VOTE_SUPPORT, handler(self, self.onVote))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_POPULARITY_VOTE_VOTE_MISSION_INFO, handler(self, self.onMissionInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, handler(self, self.onActivityInfo))
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_POPULARITY_VOTE_GET_VOTE_LIST, handler(self, function ()
		if not self.curPeriod then
			return
		end

		if self.curPeriod <= 9 then
			if self.refreshContent and self.activityData.history[self.curPeriod] then
				self:refreshContent()
			end
		elseif self.activityData.history[9] then
			self:showPeriod()
		end
	end))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_POPULARITY_VOTE_HELPTEXT01"
		})
	end

	UIEventListener.Get(self.rankBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_popularity_vote_rank_window")
	end

	UIEventListener.Get(self.awardBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_task_mail_award_window", {
			titleText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT4"),
			tipsText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT10"),
			taskList = self:getAccumulateTaskList()
		})
	end

	UIEventListener.Get(self.taskBtn).onClick = function ()
		self:openDailyTaskWindow()
	end

	UIEventListener.Get(self.scheduleBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_popularity_vote_schedule_window")
	end

	UIEventListener.Get(self.supportBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_popularity_vote_support_window")
	end
end

function ActivityPopularityVoteWindow:openDailyTaskWindow()
	xyd.WindowManager.get():openWindow("activity_task_get_award_window", {
		hasNav = false,
		titleText = __("MISSION"),
		tipsText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT9"),
		taskList = self:getDailyTaskList(),
		activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
	})
	xyd.db.misc:setValue({
		key = "activity_popularity_vote_award",
		value = xyd.getServerTime()
	})
	self.activityData:getRedMarkState()
end

function ActivityPopularityVoteWindow:getDailyTaskList()
	local t = xyd.tables.activityPopularityVoteTaskTable
	local ids = t:getIDs()
	local missionCount = self.activityData.detail_.mission_count
	local missionAwarded = self.activityData.detail_.mission_awarded
	local taskList = {}

	for i = 1, #ids do
		table.insert(taskList, {
			id = t:getId(i),
			des = t:getDesc(i),
			awards = t:getAward(i),
			complete = t:getCompleteNum(i),
			count = missionCount[i],
			isAwarded = missionAwarded[i],
			activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE,
			goWayList = t:getGoWay(i),
			closeCallback = function ()
				local msg = messages_pb:get_activity_info_by_id_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_INFO_BY_ID, msg)

				self.needOpenTaskWindow = true
			end
		})
	end

	table.sort(taskList, function (a, b)
		local canAwardA = a.complete <= a.count and a.isAwarded == 0 and 100 or 0
		local canAwardB = b.complete <= b.count and b.isAwarded == 0 and 100 or 0
		local notCompleteA = a.count < a.complete and 10 or 0
		local notCompleteB = b.count < b.complete and 10 or 0
		local weightA = notCompleteA + canAwardA + a.isAwarded
		local weightB = notCompleteB + canAwardB + b.isAwarded

		if weightA == weightB then
			return a.id < b.id
		else
			return weightB < weightA
		end
	end)

	return taskList
end

function ActivityPopularityVoteWindow:getAccumulateTaskList()
	local t = xyd.tables.activityPopularityVoteAwaradTable
	local ids = t:getIDs()
	local voteAwarded = self.activityData.detail_.vote_awarded
	local taskList = {}

	for i = 1, #ids do
		table.insert(taskList, {
			id = t:getId(i),
			des = __("ACTIVITY_POPULARITY_VOTE_AWARDTEXT11", t:getCompleteNum(i)),
			awards = t:getAward(i),
			complete = t:getCompleteNum(i),
			count = self.activityData.detail_.vote_num,
			isAwarded = voteAwarded[i]
		})
	end

	table.sort(taskList, function (a, b)
		if a.isAwarded == b.isAwarded then
			return a.id < b.id
		else
			return a.isAwarded == 0
		end
	end)

	return taskList
end

function PartnerCardItem:initUI()
	self.partnerImg = self.go:ComponentByName("partnerImg", typeof(UISprite))
	self.mask = self.partnerImg:NodeByName("mask").gameObject
	self.cardBg = self.go:ComponentByName("cardBg", typeof(UISprite))
	self.winImg = self.go:NodeByName("winImg").gameObject
	self.rankImg = self.go:ComponentByName("rankImg", typeof(UISprite))
	self.rankLabel = self.rankImg:ComponentByName("rankLabel", typeof(UILabel))
	self.partnerNameLabel = self.go:ComponentByName("partnerNameLabel", typeof(UILabel))
	self.getVoteLabel = self.go:ComponentByName("getVoteLabel", typeof(UILabel))
	self.voetNumLabel = self.go:ComponentByName("voetNumLabel", typeof(UILabel))
	self.btnVote = self.go:NodeByName("btnVote").gameObject
	self.voteLabel = self.btnVote:ComponentByName("voteLabel", typeof(UILabel))
	self.getVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1")
	self.voteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT2")

	if self.parent.curPeriod <= 4 then
		self.go:SetLocalScale(0.833, 0.833, 0.833)
	elseif self.parent.curPeriod == 9 then
		self.go:SetLocalScale(1.1, 1.1, 1.1)
	end

	if UNITY_EDITOR or self.parent.curPeriod > 4 and (UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.4.80") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.3.44") >= 0) then
		xyd.setUISpriteAsync(self.cardBg, nil, "activity_popularity_vote_card_3")
		ResCache.SetMaterial(self.partnerImg, "Materials/Common/stencil_mask_top")
		self.mask:SetActive(true)
	else
		xyd.setUISpriteAsync(self.cardBg, nil, "activity_popularity_vote_card_1")
		self.mask:SetActive(false)
	end
end

function PartnerCardItem:updateInfo()
	dump(self.data.table_id)
	dump(xyd.tables.partnerPictureTable:getPartnerCard(self.data.table_id))
	xyd.setUISpriteAsync(self.partnerImg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.data.table_id))
	self.winImg:SetActive(false)

	if self.data.rank then
		self.rankImg:SetActive(true)
		xyd.setUISpriteAsync(self.rankImg, nil, "activity_popularity_vote_rank_" .. self.data.rank)

		self.rankLabel.text = self.data.rank
	else
		self.rankImg:SetActive(false)
	end

	self.partnerNameLabel.text = xyd.tables.partnerTable:getName(self.data.table_id)
	self.voetNumLabel.text = self.data.score
end

function PartnerCardItem:registerEvent()
	UIEventListener.Get(self.btnVote).onClick = function ()
		local itemList = xyd.split2(xyd.tables.miscTable:getVal("activity_popularity_vote_cost"), {
			"|",
			"#"
		}, true)

		xyd.WindowManager.get():openWindow("activity_use_item_window", {
			onceUseMax = 10000000,
			titleText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT2"),
			tipsText = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT11"),
			useText = __("USE"),
			useTips = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT15"),
			itemList = itemList,
			useFunction = function (itemID, num)
				local msg = messages_pb.activity_popularity_vote_support_req()
				msg.activity_id = xyd.ActivityID.ACTIVITY_POPULARITY_VOTE
				msg.table_id = self.data.table_id
				msg.num = num
				msg.type = itemID == itemList[1][1] and 1 or 2

				xyd.Backend.get():request(xyd.mid.ACTIVITY_POPULARITY_VOTE_SUPPORT, msg)

				local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

				activityData:setVote(itemID, num, self.data.table_id)
			end,
			eventID = xyd.event.ACTIVITY_POPULARITY_VOTE_SUPPORT,
			closeCallBack = function ()
				self.parent:refreshContent(true)
			end,
			languageList = {
				de_de = {
					fontSize = 18,
					width = 470
				}
			}
		})
	end

	UIEventListener.Get(self.go).onClick = function ()
		dump(self.data)
		dump(self.data.table_id)
		xyd.openWindow("activity_popularity_vote_support_message_window", {
			tableID = self.data.table_id,
			curPeriod = self.parent.curPeriod
		})
	end

	xyd.setDragScrollView(self.btnVote, self.parent.scrollView)
end

function ChampItem:initUI()
	self.leftRoot = self.go:NodeByName("leftRoot").gameObject
	self.rightRoot = self.go:NodeByName("rightRoot").gameObject
	local left = NGUITools.AddChild(self.leftRoot, self.parent.parterCard)
	self.leftPartner = PartnerCardItem.new(left, self.parent)
	local right = NGUITools.AddChild(self.rightRoot, self.parent.parterCard)
	self.rightPartner = PartnerCardItem.new(right, self.parent)
end

function ChampItem:updateInfo()
	if xyd.Global.playerID % 2 == 0 then
		if self.data[1].table_id < self.data[2].table_id then
			self.leftPartner.data = self.data[1]
			self.rightPartner.data = self.data[2]
		else
			self.leftPartner.data = self.data[2]
			self.rightPartner.data = self.data[1]
		end
	elseif self.data[1].table_id < self.data[2].table_id then
		self.rightPartner.data = self.data[1]
		self.leftPartner.data = self.data[2]
	else
		self.rightPartner.data = self.data[2]
		self.leftPartner.data = self.data[1]
	end

	self.leftPartner:updateInfo()
	self.rightPartner:updateInfo()
end

return ActivityPopularityVoteWindow
