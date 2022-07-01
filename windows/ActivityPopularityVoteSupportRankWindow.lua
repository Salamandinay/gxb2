local BaseWindow = import(".BaseWindow")
local ActivityPopularityVoteSupportRankWindow = class("ActivityPopularityVoteSupportRankWindow", BaseWindow)
local RankItem = class("RankItem", import("app.common.ui.FixedWrapContentItem"))
local PlayerIcon = import("app.components.PlayerIcon")
local cjson = require("cjson")

function ActivityPopularityVoteSupportRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.params = params
	self.tableID = params.tableID
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

	self.activityData:reqRankListByParner(self.tableID)

	self.voteSum = self.params.score
	self.maxPeriod = self.params.maxPeriod
end

function ActivityPopularityVoteSupportRankWindow:initWindow()
	self:getUIComponent()
	ActivityPopularityVoteSupportRankWindow.super.initWindow(self)
	self:initUIComponent()
	self:register()
end

function ActivityPopularityVoteSupportRankWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle = self.groupAction:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = self.groupAction:NodeByName("closeBtn").gameObject
	self.scrollView = self.groupAction:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("wrapContent", typeof(UIWrapContent))
	self.rank_item = self.scrollView:NodeByName("rank_item").gameObject
	self.wrapContent = require("app.common.ui.FixedWrapContent").new(self.scrollView, wrapContent, self.rank_item, RankItem, self)

	self.wrapContent:hideItems()

	self.leftGroup = self.groupAction:NodeByName("leftGroup").gameObject
	self.partnerInfoPart = self.leftGroup:NodeByName("partnerInfoPart").gameObject
	self.partnerImg = self.partnerInfoPart:ComponentByName("partnerImg", typeof(UISprite))
	self.labelName = self.partnerInfoPart:ComponentByName("labelName", typeof(UILabel))
	self.labelVote = self.partnerInfoPart:ComponentByName("labelVote", typeof(UILabel))
	self.labelVoteNum = self.partnerInfoPart:ComponentByName("labelVoteNum", typeof(UILabel))
	self.CurRankWords = self.leftGroup:ComponentByName("CurRankWords", typeof(UILabel))
	self.labelRank = self.leftGroup:ComponentByName("labelRank", typeof(UILabel))
end

function ActivityPopularityVoteSupportRankWindow:initUIComponent()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_TEXT05")
	self.labelName.text = xyd.tables.partnerTable:getName(self.tableID)
	self.labelVote.text = __("ACTIVITY_POPULARITY_VOTE_TEXT08")
	self.labelVoteNum.text = self.voteSum
	self.CurRankWords.text = __("ACTIVITY_POPULARITY_VOTE_TEXT02")
	self.labelRank.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT" .. self.maxPeriod + 17)

	xyd.setUISpriteAsync(self.partnerImg, nil, xyd.tables.partnerPictureTable:getPartnerCard(self.tableID))

	if not self.infos then
		-- Nothing
	end
end

function ActivityPopularityVoteSupportRankWindow:updateData()
	self.infos = self.activityData:getRankListByParner(self.tableID)

	dump(self.infos)

	for key, value in ipairs(self.infos) do
		value.rank = tonumber(key)
	end

	self.wrapContent:setInfos(self.infos, {})
	self.wrapContent:resetPosition()
	self.scrollView:ResetPosition()
end

function ActivityPopularityVoteSupportRankWindow:register()
	UIEventListener.Get(self.closeBtn).onClick = function ()
		self:close()
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data
		local detail = cjson.decode(data.detail)

		if event.data.activity_id == xyd.ActivityID.ACTIVITY_POPULARITY_VOTE and detail.type == 3 then
			self:updateData()
		end
	end)
end

function RankItem:ctor(go, parent)
	RankItem.super.ctor(self, go, parent)

	self.go = go
	self.parent = parent

	self:getUIComponent()
end

function RankItem:getUIComponent()
	self.rankGroup = self.go:NodeByName("rankGroup").gameObject
	self.imgRankIcon = self.rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.avatarGroup:NodeByName("playerIcon").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.serverInfo = self.go:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.pointWords = self.go:ComponentByName("pointWords", typeof(UILabel))
	self.labelPoint = self.go:ComponentByName("labelPoint", typeof(UILabel))
	self.pIcon = PlayerIcon.new(self.playerIcon)

	self.pIcon:AddUIDragScrollView()
end

function RankItem:updateInfo()
	self.avatar_id = tonumber(self.data.avatar_id)
	self.frame_id = tonumber(self.data.frame_id)
	self.level = tonumber(self.data.lev)
	self.player_name = self.data.player_name
	self.server_id = tonumber(self.data.server_id)
	self.rank = self.data.rank
	self.point = self.data.score

	self.go:SetActive(true)

	if tonumber(self.rank) ~= nil and tonumber(self.rank) <= 3 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.rank)
	end

	self.pIcon:setInfo({
		scale = 0.4824561403508772,
		avatarID = self.avatar_id,
		avatar_frame_id = self.frame_id,
		lev = self.level
	})

	self.labelPlayerName.text = self.player_name
	self.serverId.text = xyd.getServerNumber(self.server_id)
	self.pointWords.text = __("ACTIVITY_POPULARITY_VOTE_TEXT09")
	self.labelPoint.text = self.point
end

function RankItem:getGameObject()
	return self.go
end

return ActivityPopularityVoteSupportRankWindow
