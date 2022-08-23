local OldSchoolRankWindow = class("OldSchoolRankWindow", import(".BaseWindow"))
local RankItem = class("RankItem", require("app.components.CopyComponent"))
local AwardItem = class("GuildBossKillAwardItem")
local PlayerIcon = import("app.components.PlayerIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

function RankItem:ctor(go, parent, params)
	self.parent_ = parent

	RankItem.super.ctor(self, go)

	self.info = params

	self:getUIComponent()
	self:initUIComponent()
end

function RankItem:getUIComponent()
	self.bgImg = self.go:NodeByName("bgImg").gameObject
	self.labelGroup = self.go:NodeByName("labelGroup").gameObject
	self.imgRankIcon = self.labelGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.labelGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.go:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.go:NodeByName("avatarGroup/playerIcon").gameObject
	self.labelPlayerName = self.go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelDesText = self.go:ComponentByName("e:Group/labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.go:ComponentByName("e:Group/labelCurrentNum", typeof(UILabel))
	self.serverInfo = self.go:NodeByName("serverInfo").gameObject
	self.serverId = self.go:ComponentByName("serverInfo/serverId", typeof(UILabel))
	self.groupWords = self.go:ComponentByName("groupWords", typeof(UILabel))
	self.groupImg = self.go:ComponentByName("groupImg", typeof(UISprite))

	self.groupImg:SetActive(false)
	self.groupWords:SetActive(false)

	self.labelDesText.text = __("SCORE")
	self.pIcon = PlayerIcon.new(self.playerIcon)
end

function RankItem:initUIComponent()
	if not self.info then
		return
	end

	self.labelPlayerName.text = self.info.player_name

	if self.info.rank <= 3 and self.info.score > 0 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.info.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	elseif self.info.score > 0 then
		self.labelRank.text = tostring(self.info.rank)

		self.labelRank:SetActive(true)
		self.imgRankIcon:SetActive(false)
	else
		self.labelRank.text = " "

		self.labelRank:SetActive(true)
		self.imgRankIcon:SetActive(false)
	end

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.info.avatar_id,
		avatar_frame_id = self.info.avatar_frame_id,
		lev = self.info.lev
	})
	self.pIcon:AddUIDragScrollView(self.parent_.rankListScroller_scrollerView)

	self.serverId.text = xyd.getServerNumber(self.server_id_)

	if self.info.hide_bg then
		self.bgImg:SetActive(false)
	else
		self.bgImg:SetActive(true)
	end

	if self.point_ then
		self.labelCurrentNum.text = self.point_
	else
		self.labelCurrentNum.text = "0"
	end
end

function RankItem:update(_, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info
	local params = info

	self.go:SetActive(true)

	if params then
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.avatar_frame_id)
		self.level_ = tonumber(params.lev)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.score
		self.rank_ = params.rank
	end

	if self.point_ <= 0 then
		self.point_ = xyd.models.oldSchool:getSelfScore()
	end

	self:initUIComponent()
end

function OldSchoolRankWindow:ctor(name, params)
	OldSchoolRankWindow.super.ctor(self, name, params)
end

function OldSchoolRankWindow:initRankInfo()
	self.rank_data_ = xyd.models.oldSchool:getExtraRankList()
	self.self_data_ = {
		rank = -1,
		score = 0
	}
	local data = xyd.models.oldSchool:getRankData()

	if data and data.self_rank then
		self.self_data_.rank = data.self_rank + 1
		self.self_data_.score = data.self_score
	end

	for i = 1, 50 do
		local info = self.rank_data_[i]

		if info and info.player_id == xyd.Global.playerID then
			self.self_data_ = {
				rank = i,
				score = tonumber(info.score),
				avatar_id = info.avatar_id,
				avatar_frame_id = info.avatar_frame_id,
				server_id = info.server_id
			}
		end
	end

	dump(self.self_data_)
end

function OldSchoolRankWindow:initWindow()
	self:getComponent()
	OldSchoolRankWindow.super.initWindow(self)
	self:registerEvent()
	self.window_:SetActive(true)
	self.rankNode:SetActive(true)
	self:initRankInfo()
	self:initUI()
	self:initRankList()
end

function OldSchoolRankWindow:registerEvent()
	self.rankNode:SetActive(false)
	self.awardNode:SetActive(false)
	self.window_:SetActive(false)

	local msg = messages_pb:old_building_rank_list_req()

	xyd.Backend.get():request(xyd.mid.OLD_BUILDING_RANK_LIST, msg)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.upgroup_explainBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "OLD_SCHOOL_HELP2"
		})
	end)
end

function OldSchoolRankWindow:getComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.winName = groupAction:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("e:Group/closeBtn").gameObject
	self.nav = groupAction:NodeByName("e:Group/nav").gameObject
	self.awardNode = groupAction:NodeByName("awardNode").gameObject
	self.upgroup = self.awardNode:NodeByName("upgroup").gameObject
	self.arena_award_item = self.upgroup:NodeByName("arena_award_item").gameObject
	self.labelRank = self.upgroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = self.upgroup:ComponentByName("labelTopRank", typeof(UILabel))
	self.topRank = self.upgroup:ComponentByName("topRank", typeof(UILabel))
	self.labelNowAward = self.upgroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = self.upgroup:NodeByName("nowAward").gameObject
	self.awardItem1 = self.upgroup:NodeByName("nowAward/ns1:ItemIcon").gameObject
	self.awardItem2 = self.upgroup:NodeByName("nowAward/ns2:ItemIcon").gameObject
	self.awardItem3 = self.upgroup:NodeByName("nowAward/ns3:ItemIcon").gameObject
	self.labelDesc = self.awardNode:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = self.awardNode:NodeByName("clock").gameObject
	self.ddl2Text = self.awardNode:ComponentByName("ddl2Text", typeof(UILabel))
	self.awardScroller = self.awardNode:NodeByName("awardScroller").gameObject
	self.awardScroller_scrollerView = self.awardNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_panel = self.awardNode:ComponentByName("awardScroller", typeof(UIPanel))
	self.awardContainer = self.awardNode:NodeByName("awardScroller/awardContainer").gameObject
	self.rankNode = groupAction:NodeByName("rankNode").gameObject
	self.activity_sports_rank_item = self.rankNode:NodeByName("activity_sports_rank_item").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.rankListScroller_scrollerView = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListScroller_panel = self.rankNode:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListContainer = self.rankNode:NodeByName("rankListScroller/rankListContainer").gameObject
	self.playerRankGroup = self.rankNode:NodeByName("playerRankGroup").gameObject
	local rankListWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, RankItem, self)
	self.upgroup = self.rankNode:NodeByName("upgroup").gameObject
	self.upgroup_explainBtn = self.upgroup:NodeByName("explainBtn").gameObject
	self.upgroup_upBgImg = self.upgroup:ComponentByName("upBgImg", typeof(UITexture))
	self.upgroup_upExplainText = self.upgroup:ComponentByName("upExplainText", typeof(UILabel))
	self.upgroup_frameCon = self.upgroup:NodeByName("frameCon").gameObject
	self.playerIcon = PlayerIcon.new(self.upgroup_frameCon)

	self.playerIcon:setScale(0.8770491803278688)

	self.rankNone = self.rankNode:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
end

function OldSchoolRankWindow:initUI()
	self.winName.text = __("BOOK_RESEARCH_TEXT11")
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")

	self:initNav()
	self:setCountDown()
	self:initUpCon()
end

function OldSchoolRankWindow:initUpCon()
	self.upgroup:SetActive(true)

	local reseTinfo = {
		avatar_frame_id = xyd.models.oldSchool:getOldBuildingAward2Table():getFrameAwards(1)[1]
	}

	self.playerIcon:setInfo(reseTinfo)

	self.upgroup_upExplainText.text = __("OLD_SCHOOL_AWARD_EXPLAIN_TEXT")
end

function OldSchoolRankWindow:setCountDown()
	local tomorrowTime = xyd.getTomorrowTime()
	local tomorrowWeekDay = os.date("%w", tomorrowTime)

	if tomorrowWeekDay == 0 then
		tomorrowWeekDay = 7
	end

	local fridayTime = xyd.models.oldSchool:getChallengeEndTime() - xyd.getServerTime()
	local params = {
		duration = fridayTime
	}
	local effect = xyd.Spine.new(self.clock)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.labelRefreshTime_ = CountDown.new(self.ddl2Text, params)
end

function OldSchoolRankWindow:initNav()
	local index = 2
	local labelStates = {
		chosen = {
			color = Color.New2(4294967295.0),
			effectColor = Color.New2(1012112383)
		},
		unchosen = {
			color = Color.New2(960513791),
			effectColor = Color.New2(4294967295.0)
		}
	}
	self.tab = import("app.common.ui.CommonTabBar").new(self.nav.gameObject, index, function (index)
		self:updateLayout(index)
	end, nil, labelStates)

	self.tab:setTexts({
		__("RANK"),
		__("AWARD3")
	})
end

function OldSchoolRankWindow:updateLayout(index)
	self.rankNode:SetActive(index == 1)
	self.awardNode:SetActive(index == 2)

	if index == 2 and not self.hasInitAward_ then
		self:initAward()
	end
end

function OldSchoolRankWindow:initRankList()
	self.rankListInfo_ = {}
	local params = {
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		lev = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		score = tonumber(self.self_data_.score),
		rank = tonumber(self.self_data_.rank),
		server_id = xyd.models.selfPlayer:getServerID()
	}
	local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
	local selfRankItem = RankItem.new(tmp, self)

	selfRankItem:update(nil, params)
	selfRankItem:setDepth(15)

	for i = 1, 50 do
		local data = self.rank_data_[i]

		if data and data.player_id and data.player_id > 0 then
			local params = {
				avatar_id = data.avatar_id,
				avatar_frame_id = data.avatar_frame_id,
				player_id = data.player_id,
				lev = data.lev,
				player_name = data.player_name,
				score = tonumber(data.score),
				server_id = data.server_id,
				rank = tonumber(i)
			}

			table.insert(self.rankListInfo_, params)
		end
	end

	self.wrapContent:setInfos(self.rankListInfo_, {})
end

function OldSchoolRankWindow:initAward()
	self.hasInitAward_ = true
	self.labelTopRank.text = tostring(__("GUILD_BOSS_AWARD_2")) .. ":"
	self.labelNowAward.text = tostring(__("GUILD_BOSS_TEXT03"))

	self:initKillAward()
	self:initBattleAward()
end

function OldSchoolRankWindow:initKillAward()
	self.arena_award_item.gameObject:SetActive(false)

	local rankIds = xyd.models.oldSchool:getOldBuildingAward2Table():getIds()

	for i = 1, #rankIds do
		local rank = rankIds[i]
		local awardsData = xyd.models.oldSchool:getOldBuildingAward2Table():getAwards(rank)
		local frameData = xyd.models.oldSchool:getOldBuildingAward2Table():getFrameAwards(rank)

		if #frameData > 0 then
			table.insert(awardsData, frameData)
		end

		local rankFront = xyd.models.oldSchool:getOldBuildingAward2Table():getRankFront(rank)
		local go = NGUITools.AddChild(self.awardContainer, self.arena_award_item.gameObject)

		go:SetActive(true)

		local awardItem = AwardItem.new(go, {
			awardsData = awardsData,
			rank = rank,
			rankFront = rankFront,
			id = i
		}, self)
	end

	self.awardContainer:GetComponent(typeof(UILayout)):Reposition()
	self.awardScroller_scrollerView:ResetPosition()
end

function OldSchoolRankWindow:initBattleAward()
	self.labelNowAward.text = __("NOW_AWARD")
	local score = self.self_data_.score
	local rank = self.self_data_.rank

	if score == 0 or rank == -1 then
		self.labelRank.text = __("NOW_RANK") .. " "
		self.labelNowAward.text = __("NOW_AWARD") .. " "
	elseif rank and tonumber(rank) > 0 then
		self.labelRank.text = __("NOW_RANK") .. ": " .. rank
		local rankID = xyd.models.oldSchool:getOldBuildingAward2Table():getRankIdByRank(rank)
		local awardData = xyd.models.oldSchool:getOldBuildingAward2Table():getAwards(rankID)
		local frameData = xyd.models.oldSchool:getOldBuildingAward2Table():getFrameAwards(rankID)

		if #frameData > 0 then
			table.insert(awardData, frameData)
		end

		for idx, info in ipairs(awardData) do
			self["awardItem" .. idx]:SetActive(true)

			local params = {
				labelNumScale = 1.6,
				hideText = true,
				itemID = info[1],
				num = info[2],
				uiRoot = self["awardItem" .. idx]
			}
			local itemIcon = xyd.getItemIcon(params)

			itemIcon:SetLocalScale(0.72, 0.72, 1)
		end

		self.nowAward:GetComponent(typeof(UILayout)):Reposition()
	else
		self.labelRank.text = __("NOW_RANK") .. " "
		self.labelNowAward.text = __("NOW_AWARD") .. " "
	end

	self.labelDesc.text = __("COUNT_DOWN_BY_MAIL")
end

function AwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rankFront = params.rankFront
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function AwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("labelRank", typeof(UILabel))
	self.itemGroup = go:NodeByName("awardGroup").gameObject
	self.rankImg = go:ComponentByName("imgRank", typeof(UISprite))
end

function AwardItem:initUIComponent()
	self.rank = tonumber(self.rank)

	if self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = self.rankFront
	end

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.awardScroller_scrollerView,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return OldSchoolRankWindow
