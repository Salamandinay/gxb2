local ActivityPopularityVoteHistoryWindow = class("ActivityPopularityVoteHistoryWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")
local PartnerCardItem = class("PartnerCardItem", import("app.common.ui.FixedMultiWrapContentItem"))
local ChampItem = class("ChampItem", import("app.common.ui.FixedMultiWrapContentItem"))
local cjson = require("cjson")

function ActivityPopularityVoteHistoryWindow:ctor(name, params)
	self.period = params.period
	self.hasData = params.hasData
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

	ActivityPopularityVoteHistoryWindow.super.ctor(self, name, params)
end

function ActivityPopularityVoteHistoryWindow:initWindow()
	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityPopularityVoteHistoryWindow:getUIComponent()
	local groupMain = self.window_:NodeByName("groupMain")
	self.helpBtn = groupMain:NodeByName("helpBtn").gameObject
	self.textLogo = groupMain:ComponentByName("textLogo", typeof(UISprite))
	self.periodLabel = groupMain:ComponentByName("periodLabel", typeof(UILabel))
	self.overLabel = groupMain:ComponentByName("overLabel", typeof(UILabel))
	self.parterCard = groupMain:NodeByName("parterCard").gameObject
	self.champItem = groupMain:NodeByName("champItem").gameObject
	self.scrollView = groupMain:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = self.scrollView:ComponentByName("groupContent", typeof(UIWrapContent))
end

function ActivityPopularityVoteHistoryWindow:layout()
	self:initTop()
	xyd.setUISpriteAsync(self.textLogo, nil, "activity_popularity_vote_" .. xyd.Global.lang)

	self.periodLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT" .. self.period + 17)
	self.overLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT12")

	if self.hasData then
		self:checkPeriod()
	end
end

function ActivityPopularityVoteHistoryWindow:initTop()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.POPULARITY_TICKET
		},
		{
			show_tips = true,
			hidePlus = false,
			id = xyd.ItemID.SUPPORT_TICKET
		}
	}

	self.windowTop:setItem(items)
end

function ActivityPopularityVoteHistoryWindow:checkPeriod()
	if self.period <= 4 then
		self.refreshContent = self.refreshContent1

		self:qualifiers(self.period)
	elseif self.period <= 9 then
		self.refreshContent = self.refreshContent2

		self:championships(self.period)
	end

	self:refreshContent()
end

function ActivityPopularityVoteHistoryWindow:qualifiers(period)
	self.wrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.groupContent, self.parterCard, PartnerCardItem, self)
end

function ActivityPopularityVoteHistoryWindow:championships(period)
	self.parterCard:SetActive(false)

	self.groupContent.rowNum = 1
	self.groupContent.rowWidth = 557
	self.groupContent.itemSize = 415

	self.groupContent:X(0)

	self.wrapContent = import("app.common.ui.FixedMultiWrapContent").new(self.scrollView, self.groupContent, self.champItem, ChampItem, self)

	if self.period == 9 then
		self:waitForFrame(1, function ()
			self.groupContent:Y(-690 + self.scale_num_ * 75)
		end)
	end
end

function ActivityPopularityVoteHistoryWindow:finals()
end

function ActivityPopularityVoteHistoryWindow:showPeriod()
end

function ActivityPopularityVoteHistoryWindow:refreshContent1()
	local partnerList = {}

	for _, item in ipairs(self.activityData.history[self.period][1]) do
		table.insert(partnerList, item)
	end

	if partnerList[1].score == 0 then
		self:shuffle(partnerList)
	else
		local rank = 1
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
	end

	self.wrapContent:setInfos(partnerList, {})
end

function ActivityPopularityVoteHistoryWindow:refreshContent2()
	local chamList = {}
	local tmpList = {}
	local startPos = xyd.Global.playerID % 4 + 1

	for _, list in ipairs(self.activityData.history[self.period]) do
		table.insert(tmpList, list)
	end

	for i = 1, #tmpList do
		if startPos > #tmpList then
			startPos = 1
		end

		table.insert(chamList, tmpList[startPos])

		startPos = startPos + 1
	end

	self.wrapContent:setInfos(chamList, {})
end

function ActivityPopularityVoteHistoryWindow:shuffle(list)
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

function ActivityPopularityVoteHistoryWindow:onGetList(event)
	if not self.activityData.history then
		self.activityData.history = {}
	end

	self.activityData.history[self.period] = cjson.decode(event.data.rank_list)
	local vote_list = cjson.decode(event.data.vote_list)

	for _, list in ipairs(self.activityData.history[self.period]) do
		for _, item in ipairs(list) do
			for table_id, value in pairs(vote_list) do
				if item.table_id == tonumber(table_id) then
					item.myVote = value
				end
			end
		end
	end

	self:checkPeriod()
end

function ActivityPopularityVoteHistoryWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ACTIVITY_POPULARITY_VOTE_GET_VOTE_LIST, handler(self, self.onGetList))

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_POPULARITY_VOTE_HELPTEXT03"
		})
	end
end

function PartnerCardItem:ctor(go, parent)
	PartnerCardItem.super.ctor(self, go, parent)
end

function PartnerCardItem:initUI()
	self.partnerImg = self.go:ComponentByName("partnerImg", typeof(UISprite))
	self.mask = self.partnerImg:NodeByName("mask").gameObject
	self.cardBg = self.go:ComponentByName("cardBg", typeof(UISprite))
	self.winImg = self.go:NodeByName("winImg").gameObject
	self.winLabel = self.winImg:ComponentByName("winLabel", typeof(UILabel))
	self.rankImg = self.go:ComponentByName("rankImg", typeof(UISprite))
	self.rankLabel = self.rankImg:ComponentByName("rankLabel", typeof(UILabel))
	self.partnerNameLabel = self.go:ComponentByName("partnerNameLabel", typeof(UILabel))
	self.getVoteLabel = self.go:ComponentByName("getVoteLabel", typeof(UILabel))
	self.voetNumLabel = self.go:ComponentByName("voetNumLabel", typeof(UILabel))
	self.myVote = self.go:NodeByName("myVote").gameObject
	self.myVoteLabel = self.myVote:ComponentByName("myVoteLabel", typeof(UILabel))
	self.myVoteValueLabel = self.myVote:ComponentByName("myVoteValueLabel", typeof(UILabel))
	self.notVoteLabel = self.go:ComponentByName("notVoteLabel", typeof(UILabel))
	self.getVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT1")
	self.myVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT16")
	self.notVoteLabel.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT17")
	self.winLabel.text = "WIN !"

	if xyd.Global.lang == "de_de" then
		self.notVoteLabel.fontSize = 20
	elseif xyd.Global.lang == "en_en" then
		self.notVoteLabel.fontSize = 22
	end

	if self.parent.period <= 4 then
		self.go:SetLocalScale(0.833, 0.833, 0.833)
	elseif self.parent.period == 9 then
		self.go:SetLocalScale(1.1, 1.1, 1.1)
	end

	if UNITY_EDITOR or self.parent.period > 4 and (UNITY_ANDROID and XYDUtils.CompVersion(UnityEngine.Application.version, "1.4.80") >= 0 or UNITY_IOS and XYDUtils.CompVersion(UnityEngine.Application.version, "71.3.44") >= 0) then
		xyd.setUISpriteAsync(self.cardBg, nil, "activity_popularity_vote_card_4")
		ResCache.SetMaterial(self.partnerImg, "Materials/Common/stencil_mask_top")
		self.mask:SetActive(true)
	else
		xyd.setUISpriteAsync(self.cardBg, nil, "activity_popularity_vote_card_2")
		self.mask:SetActive(false)
	end
end

function PartnerCardItem:updateInfo()
	xyd.setUISpriteAsync(self.partnerImg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.data.table_id))

	if self.data.isWin then
		self.winImg:SetActive(true)
	else
		self.winImg:SetActive(false)
	end

	if self.data.rank then
		self.rankImg:SetActive(true)
		xyd.setUISpriteAsync(self.rankImg, nil, "activity_popularity_vote_rank_" .. self.data.rank)

		self.rankLabel.text = self.data.rank
	else
		self.rankImg:SetActive(false)
	end

	self.partnerNameLabel.text = xyd.tables.partnerTable:getName(self.data.table_id)
	self.voetNumLabel.text = self.data.score

	if self.data.myVote then
		self.myVote:SetActive(true)
		self.notVoteLabel:SetActive(false)

		self.myVoteValueLabel.text = self.data.myVote
	else
		self.myVote:SetActive(false)
		self.notVoteLabel:SetActive(true)
	end
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
	if self.data[2].score < self.data[1].score then
		self.data[1].isWin = true
	else
		self.data[2].isWin = true
	end

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

return ActivityPopularityVoteHistoryWindow
