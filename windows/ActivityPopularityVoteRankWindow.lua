local ActivityPopularityVoteRankWindow = class("ActivityPopularityVoteRankWindow", import(".BaseWindow"))
local RankItem = class("RankItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")

function ActivityPopularityVoteRankWindow:ctor(name, params)
	ActivityPopularityVoteRankWindow.super.ctor(self, name, params)
end

function ActivityPopularityVoteRankWindow:initWindow()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_POPULARITY_VOTE)

	self:getUIComponent()
	self:layout()
	self:registerEvent()
end

function ActivityPopularityVoteRankWindow:getUIComponent()
	local content = self.window_:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = content:NodeByName("closeBtn").gameObject
	self.helpBtn = content:NodeByName("helpBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("rankListContainer", typeof(UIWrapContent))
	local rankItem = ResCache.AddGameObject(content, "Prefabs/Components/rank_item")
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, rankItem, RankItem, self)
end

function ActivityPopularityVoteRankWindow:layout()
	self.labelTitle.text = __("ACTIVITY_POPULARITY_VOTE_TITLETEXT8")
	local player_list = self.activityData:getRankListByParner(self.activityData.history[9][1][1].table_id)

	for i = 1, #player_list do
		player_list[i].rank = i
	end

	self.wrapContent:setInfos(player_list)
	self:waitForFrame(1, function ()
		self.scrollView:ResetPosition()
	end)
end

function ActivityPopularityVoteRankWindow:registerEvent()
	UIEventListener.Get(self.closeBtn).onClick = handler(self, function ()
		self:close()
	end)

	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_POPULARITY_VOTE_HELPTEXT02"
		})
	end
end

function RankItem:initUI()
	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	local rankGroup = go:NodeByName("rankGroup").gameObject
	self.imgRankIcon = rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = go:NodeByName("avatarGroup").gameObject
	self.levelGroup = go:NodeByName("levelGroup").gameObject
	self.labelLevel = self.levelGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.labelPlayerName = go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.groupLevel_ = go:NodeByName("groupLevel_").gameObject
	self.labelDesText = self.groupLevel_:ComponentByName("labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.groupLevel_:ComponentByName("labelCurrentNum", typeof(UILabel))
	self.serverInfo = go:NodeByName("serverInfo").gameObject

	self.levelGroup:SetActive(false)
	self.serverInfo:SetActive(true)

	self.labelDesText.text = __("WEDDING_VOTE_TEXT_17")
	self.labelDesText.color = Color.New2(1549556991)

	self.labelDesText:Y(10)

	self.labelCurrentNum.color = Color.New2(6933759)
	self.labelCurrentNum.fontSize = 30

	self.labelCurrentNum:Y(-26)
end

function RankItem:updateInfo()
	if self.data.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.data.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.data.rank

		self.labelRank:SetActive(true)
	end

	self.labelPlayerName.text = self.data.player_name
	self.labelCurrentNum.text = self.data.score
	self.serverInfo:ComponentByName("serverId", typeof(UILabel)).text = xyd.getServerNumber(self.data.server_id)

	self.labelPlayerName:SetLocalPosition(-125, 20, 0)

	if not self.playerIcon then
		local scroller_panel = nil

		if self.parent and self.parent.parent and self.parent.parent.scrollView then
			scroller_panel = self.parent.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
		end

		self.playerIcon = import("app.components.PlayerIcon").new(self.avatarGroup, scroller_panel)
	end

	self.playerIcon:setInfo({
		noClick = false,
		avatarID = self.data.avatar_id,
		avatar_frame_id = self.data.avatar_frame_id,
		callback = function ()
			if self.data.player_id ~= xyd.Global.playerID then
				xyd.WindowManager.get():openWindow("arena_formation_window", {
					is_robot = false,
					player_id = self.data.player_id
				})
			end
		end,
		lev = self.data.lev
	})
	self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)
end

return ActivityPopularityVoteRankWindow
