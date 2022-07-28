local OldSchoolHarmRankWindow = class("OldSchoolHarmRankWindow", import(".BaseWindow"))
local RankItem = class("RankItem", require("app.components.CopyComponent"))
local AwardItem = class("GuildBossKillAwardItem")
local AwardItem2 = class("GuildBossKillAwardItem2")
local PlayerIcon = import("app.components.PlayerIcon")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")

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

function AwardItem2:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function AwardItem2:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("labelRank", typeof(UILabel))
	self.rankImg = go:ComponentByName("imgRank", typeof(UISprite))
	self.awardLabel = go:ComponentByName("awardLabel", typeof(UILabel))
end

function AwardItem2:initUIComponent()
	self.rank = tonumber(self.rank)

	if self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = self.rank
	end

	local point = xyd.tables.oldBuildingHarmAwardPointTable:getPoint(self.rank)
	self.awardLabel.text = __("OLD_SCHOOL_FLOOR_11_TEXT06", point)
end

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

	self.labelDesText.text = __("FRIEND_HARM")
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

	if self.point_ and self.point_ > 0 then
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

	self:initUIComponent()
end

function OldSchoolHarmRankWindow:ctor(name, params)
	OldSchoolHarmRankWindow.super.ctor(self, name, params)
end

function OldSchoolHarmRankWindow:initWindow()
	self:getUIComponent()
	self:initNav()
	self:setCountDown()
	self:registerEvent()
	self.window_:SetActive(true)
	self.rankNode:SetActive(true)
	self:initRankInfo()

	self.winName.text = __("BOOK_RESEARCH_TEXT11")

	self:initRankList()
end

function OldSchoolHarmRankWindow:getUIComponent()
	local groupAction = self.window_:NodeByName("groupAction")
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
	self.harmRankNode = groupAction:NodeByName("harmRankNode").gameObject
	self.upgroup2 = self.harmRankNode:NodeByName("upgroup").gameObject
	self.arena_award_item2 = self.upgroup2:NodeByName("arena_award_item").gameObject
	self.labelRank2 = self.upgroup2:ComponentByName("labelRank", typeof(UILabel))
	self.labelNowAward2 = self.upgroup2:ComponentByName("labelNowAward", typeof(UILabel))
	self.labelDesc2 = self.harmRankNode:ComponentByName("labelDesc", typeof(UILabel))
	self.awardScroller2 = self.harmRankNode:NodeByName("awardScroller").gameObject
	self.awardScroller_scrollerView2 = self.harmRankNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_panel2 = self.harmRankNode:ComponentByName("awardScroller", typeof(UIPanel))
	self.awardContainer2 = self.harmRankNode:NodeByName("awardScroller/awardContainer").gameObject
end

function OldSchoolHarmRankWindow:registerEvent()
	self.rankNode:SetActive(false)
	self.awardNode:SetActive(false)
	self.window_:SetActive(false)

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function OldSchoolHarmRankWindow:initRankInfo()
	self.rankData_ = xyd.models.oldSchool:getHarmData()
	self.rank_data_ = self.rankData_.list or {}
	self.self_data_ = {
		rank = -1,
		score = 0
	}

	if self.rankData_ and self.rankData_.self_rank then
		self.self_data_.rank = self.rankData_.self_rank + 1
		self.self_data_.score = self.rankData_.self_score
	end

	for i = 1, #self.rank_data_ do
		local info = self.rank_data_[i]

		if info.player_id == xyd.Global.playerID then
			self.self_data_ = {
				rank = i,
				score = tonumber(info.score),
				avatar_id = info.avatar_id,
				avatar_frame_id = info.avatar_frame_id,
				server_id = info.server_id
			}
		end
	end
end

function OldSchoolHarmRankWindow:initRankList()
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

	for i = 1, #self.rank_data_ do
		local data = self.rank_data_[i]
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

	self.wrapContent:setInfos(self.rankListInfo_, {})
end

function OldSchoolHarmRankWindow:initNav()
	local index = 3
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
		__("OLD_SCHOOL_FLOOR_11_TEXT03"),
		__("OLD_SCHOOL_FLOOR_11_TEXT04"),
		__("OLD_SCHOOL_FLOOR_11_TEXT05")
	})
	self.tab:setTabActive(1, true)
end

function OldSchoolHarmRankWindow:updateLayout(index)
	self.rankNode:SetActive(index == 1)
	self.awardNode:SetActive(index == 3)
	self.harmRankNode:SetActive(index == 2)

	if index == 3 and not self.hasInitAward_ then
		self:initAward()
	end

	if index == 2 and not self.hasInitAward2_ then
		self:initAward2()
	end
end

function OldSchoolHarmRankWindow:setCountDown()
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

function OldSchoolHarmRankWindow:initAward()
	self.hasInitAward_ = true
	self.labelTopRank.text = tostring(__("GUILD_BOSS_AWARD_2")) .. ":"
	self.labelNowAward.text = tostring(__("GUILD_BOSS_TEXT03"))

	self:initKillAward()
	self:initBattleAward()
end

function OldSchoolHarmRankWindow:initKillAward()
	self.arena_award_item.gameObject:SetActive(false)

	local rankIds = xyd.tables.oldBuildingHarmAwardTable:getIds()

	for i = 1, #rankIds do
		local rank = rankIds[i]
		local awardsData = xyd.tables.oldBuildingHarmAwardTable:getAwards(rank)
		local frameData = xyd.tables.oldBuildingHarmAwardTable:getFrameAwards(rank)

		if #frameData > 0 then
			table.insert(awardsData, frameData)
		end

		local rankFront = xyd.tables.oldBuildingHarmAwardTable:getRankFront(rank)
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

function OldSchoolHarmRankWindow:initBattleAward()
	self.labelNowAward.text = __("NOW_AWARD")
	local score = self.self_data_.score
	local rank = self.self_data_.rank

	if score == 0 or rank == -1 then
		self.labelRank.text = __("NOW_RANK") .. " "
		self.labelNowAward.text = __("NOW_AWARD") .. " "
	elseif rank and tonumber(rank) > 0 then
		self.labelRank.text = __("NOW_RANK") .. ": " .. rank
		local rankID = xyd.tables.oldBuildingHarmAwardTable:getRankIdByRank(rank)
		local awardData = xyd.tables.oldBuildingHarmAwardTable:getAwards(rankID)
		local frameData = xyd.tables.oldBuildingHarmAwardTable:getFrameAwards(rankID)

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

function OldSchoolHarmRankWindow:initAward2()
	self.hasInitAward2_ = true

	self:initKillAward2()
	self:initBattleAward2()
end

function OldSchoolHarmRankWindow:initKillAward2()
	self.arena_award_item2.gameObject:SetActive(false)

	local rankIds = xyd.tables.oldBuildingHarmAwardPointTable:getIds()

	for i = 1, #rankIds do
		local rank = tonumber(rankIds[i])
		local go = NGUITools.AddChild(self.awardContainer2, self.arena_award_item2.gameObject)

		go:SetActive(true)

		local awardItem = AwardItem2.new(go, {
			rank = rank,
			id = i
		}, self)
	end

	self.awardContainer2:GetComponent(typeof(UILayout)):Reposition()
	self.awardScroller_scrollerView2:ResetPosition()
end

function OldSchoolHarmRankWindow:initBattleAward2()
	local score = self.self_data_.score
	local rank = self.self_data_.rank

	if rank <= 0 then
		rank = " "
	end

	self.labelDesc2.text = __("OLD_SCHOOL_FLOOR_11_TEXT07")
	self.labelRank2.text = __("NOW_RANK") .. ": " .. rank
	local point = xyd.tables.oldBuildingHarmAwardPointTable:getPoint(rank) or 0
	self.labelNowAward2.text = __("NOW_AWARD") .. " " .. __("OLD_SCHOOL_FLOOR_11_TEXT06", point)
end

return OldSchoolHarmRankWindow
