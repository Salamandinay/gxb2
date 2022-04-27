local BaseWindow = import(".BaseWindow")
local GuildCompetitionRankWindow = class("GuildCompetitionRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local RankItemAllItem = class("RankItemAllItem", import("app.components.CopyComponent"))
local RankItemAllInItem = class("RankItemAllInItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local NAV_TYPE = {
	RANK_ALL = 1,
	RANK_IN = 2
}

function GuildCompetitionRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.curClickType = NAV_TYPE.RANK_ALL
	self.guildRankData = params.guildRankData
end

function GuildCompetitionRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:onTouch(self.curClickType)
end

function GuildCompetitionRankWindow:getDataInfo()
	local msg = messages_pb:get_school_rank_list_req()

	xyd.Backend:get():request(xyd.mid.GET_SCHOOL_RANK_LIST, msg)
end

function GuildCompetitionRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_COMPETITION_BOSS_RANK, handler(self, function (__, event)
		local data = xyd.decodeProtoBuf(event.data)
		self.inRankData = data

		if self.curClickType == NAV_TYPE.RANK_IN then
			self:layout()
		end
	end))
end

function GuildCompetitionRankWindow:getUIComponent()
	local trans = self.window_.transform
	self.groupAction = trans:NodeByName("groupAction").gameObject
	self.e_Group = self.groupAction:NodeByName("e:Group").gameObject
	self.labelWinTitle = self.e_Group:ComponentByName("labelWinTitle", typeof(UILabel))
	self.closeBtn = self.e_Group:NodeByName("closeBtn").gameObject
	self.nav = self.e_Group:NodeByName("nav").gameObject
	self.rankNode = self.groupAction:NodeByName("rankNode").gameObject
	self.rank_item_all = self.rankNode:NodeByName("rank_item_all").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.rankListScroller_UIScrollView = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.rankListScroller:NodeByName("rankListContainer").gameObject
	self.rankListContainer_UIWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.playerRankGroup = self.rankNode:NodeByName("playerRankGroup").gameObject
	self.playerRankGroup_UILayout = self.rankNode:ComponentByName("playerRankGroup", typeof(UILayout))
	self.rankNone = self.rankNode:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_UIScrollView, self.rankListContainer_UIWrapContent, self.rank_item_all, RankItemAllItem, self)
	self.rankNodeIn = self.groupAction:NodeByName("rankNodeIn").gameObject
	self.rank_item_in = self.rankNodeIn:NodeByName("rank_item_in").gameObject
	self.rankListScroller_In = self.rankNodeIn:NodeByName("rankListScroller").gameObject
	self.rankListScroller_In_panel = self.rankNodeIn:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListScroller_In_UIScrollView = self.rankNodeIn:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer_In = self.rankListScroller_In_UIScrollView:NodeByName("rankListContainer").gameObject
	self.rankListContainer_In_UIWrapContent = self.rankListScroller_In_UIScrollView:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.playerRankGroup_In = self.rankNodeIn:NodeByName("playerRankGroup").gameObject
	self.playerRankGroup_In_UILayout = self.rankNodeIn:ComponentByName("playerRankGroup", typeof(UILayout))
	self.rankNone_In = self.rankNodeIn:NodeByName("rankNone").gameObject
	self.labelNoneTips_In = self.rankNone_In:ComponentByName("labelNoneTips", typeof(UILabel))
	self.wrapContent_In = FixedWrapContent.new(self.rankListScroller_In_UIScrollView, self.rankListContainer_In_UIWrapContent, self.rank_item_in, RankItemAllInItem, self)
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
	self.labelNoneTips_In.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
end

function GuildCompetitionRankWindow:addTitle()
	if self.labelWinTitle then
		self.labelWinTitle.text = __("GUILD_COMPETITION_RANK_NAME")
	end
end

function GuildCompetitionRankWindow:initNav()
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
	self.tab = CommonTabBar.new(self.nav.gameObject, index, function (index)
		self:updateNav(index)
	end, nil, labelStates)

	self.tab:setTexts({
		__("GUILD_COMPETITION_ALL"),
		__("GUILD_COMPETITION_SINGLE")
	})
end

function GuildCompetitionRankWindow:updateNav(i)
	if self.curClickType == i then
		return
	end

	self.curClickType = i

	self:onTouch(i)
end

function GuildCompetitionRankWindow:layout()
	if self.curClickType == NAV_TYPE.RANK_ALL then
		self:initRankList()
	elseif self.curClickType == NAV_TYPE.RANK_IN then
		self:initRankListLast()
	end
end

function GuildCompetitionRankWindow:initRankList(groupId)
	if self.isInitRankList then
		self.rankListScroller_UIScrollView:ResetPosition()

		return
	end

	if self.selfRankItem == nil then
		self:refreshSelfRank()
	else
		self:refreshSelfRank(true)
	end

	if self.guildRankData == nil or self.guildRankData.list == nil or #self.guildRankData.list == 0 then
		self.rankListScroller:SetActive(false)
		self.rankNone:SetActive(true)

		return
	end

	self.rankListScroller:SetActive(true)
	self.rankNone:SetActive(false)

	local rankDataList = {}

	for i in pairs(self.guildRankData.list) do
		local data = self.guildRankData.list[i]
		local params = {
			rank = i,
			score = tonumber(data.score),
			server_id = data.server_id,
			guild_id = data.guild_id,
			flag = data.flag,
			name = data.name,
			num = data.num,
			lv = data.lv
		}

		table.insert(rankDataList, params)
	end

	self.wrapContent:setInfos(rankDataList, {})

	self.isInitRankList = true
end

function GuildCompetitionRankWindow:initRankListLast()
	if self.isInitRankListLast then
		self.rankListScroller_In:SetActive(true)
		self.rankListScroller_In_UIScrollView:ResetPosition()

		return
	end

	if self.selfRankItem_In == nil then
		self:refreshSelfRankLast()
	else
		self:refreshSelfRankLast(true)
	end

	if self.inRankData == nil or self.inRankData.list == nil or #self.inRankData.list == 0 then
		self.rankListScroller_In:SetActive(false)
		self.rankNone_In:SetActive(true)

		return
	end

	self.rankListScroller_In:SetActive(true)
	self.rankNone_In:SetActive(false)

	local rankDataList = {}

	for i in pairs(self.inRankData.list) do
		local data = self.inRankData.list[i]
		local params = {
			server_id = data.server_id,
			player_name = data.player_name,
			avatar_frame_id = data.avatar_frame_id,
			signature = data.signature,
			score = tonumber(data.score),
			lev = data.lev,
			is_online = data.is_online,
			player_id = data.player_id,
			avatar_id = data.avatar_id,
			rank = i
		}

		table.insert(rankDataList, params)
	end

	self.wrapContent_In:setInfos(rankDataList, {})

	self.isInitRankListLast = true
end

function GuildCompetitionRankWindow:refreshSelfRank(isRefresh)
	if self.guildRankData.self_rank == nil then
		self.guildRankData.self_rank = -1
	end

	if self.guildRankData.self_score == nil then
		self.guildRankData.self_score = 0
	end

	local guild_data = xyd.models.guild.base_info
	local self_item = {
		is_self = true,
		rank = self.guildRankData.self_rank + 1,
		score = tonumber(self.guildRankData.self_score),
		server_id = xyd.models.selfPlayer:getServerID(),
		guild_id = guild_data.guild_id,
		flag = guild_data.flag,
		name = guild_data.name,
		num = #xyd.models.guild.members,
		lv = xyd.models.guild.level
	}

	if isRefresh == nil or isRefresh == false then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.rank_item_all.gameObject)
		local item = RankItemAllItem.new(tmp)
		self.selfRankItem = item

		self.selfRankItem:update(nil, self_item)
	elseif isRefresh and isRefresh == true then
		self.selfRankItem:update(nil, self_item)
	end
end

function GuildCompetitionRankWindow:refreshSelfRankLast(isRefresh)
	if self.inRankData.self_rank == nil then
		self.inRankData.self_rank = -1
	end

	if self.inRankData.self_score == nil then
		self.inRankData.self_score = 0
	end

	local self_item = {
		is_online = 1,
		is_self = true,
		server_id = xyd.models.selfPlayer:getServerID(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		signature = xyd.models.selfPlayer:getSignature(),
		score = tonumber(self.inRankData.self_score),
		lev = xyd.models.backpack:getLev(),
		player_id = xyd.models.selfPlayer:getPlayerID(),
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		rank = self.inRankData.self_rank + 1
	}

	if isRefresh == nil or isRefresh == false then
		local tmp = NGUITools.AddChild(self.playerRankGroup_In.gameObject, self.rank_item_in.gameObject)
		local item = RankItemAllInItem.new(tmp, self)
		self.selfRankItem_In = item

		self.selfRankItem_In:update(nil, self_item)
	elseif isRefresh and isRefresh == true then
		self.selfRankItem_In:update(nil, self_item)
	end
end

function GuildCompetitionRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK_ALL then
		self.rankNode:SetActive(true)
		self.rankNodeIn:SetActive(false)
		self:layout()
	elseif index == NAV_TYPE.RANK_IN then
		self.rankNode:SetActive(false)
		self.rankNodeIn:SetActive(true)
		self.rankListScroller_In:SetActive(false)

		if not self.firstInitInData then
			self.firstInitInData = true
			local msg = messages_pb:guild_competition_boss_rank_req()
			msg.boss_id = 0
			msg.activity_id = xyd.ActivityID.GUILD_COMPETITION

			xyd.Backend.get():request(xyd.mid.GUILD_COMPETITION_BOSS_RANK, msg)
		else
			self:layout()
		end
	end
end

function RankItemAllItem:ctor(go, parent)
	self.go = go

	self:getUIComponent()

	self.parent = parent
end

function RankItemAllItem:SetActive(visible)
	self.go:SetActive(visible)
end

function RankItemAllItem:getUIComponent()
	self.rank_item_all = self.go
	self.bgImg = self.rank_item_all:ComponentByName("bgImg", typeof(UISprite))
	self.labelGroup = self.rank_item_all:NodeByName("labelGroup").gameObject
	self.imgRankIcon = self.labelGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.labelGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.rank_item_all:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.avatarGroup:NodeByName("playerIcon").gameObject
	self.guildFlagImg = self.avatarGroup:ComponentByName("guildFlagImg", typeof(UISprite))
	self.labelPlayerName = self.rank_item_all:ComponentByName("labelPlayerName", typeof(UILabel))
	self.numberInfo = self.rank_item_all:NodeByName("numberInfo").gameObject
	self.number = self.numberInfo:ComponentByName("number", typeof(UILabel))
	self.serverInfo = self.rank_item_all:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.levelGroup = self.rank_item_all:NodeByName("levelGroup").gameObject
	self.levelText = self.levelGroup:ComponentByName("levelText", typeof(UILabel))
	self.levelNumText = self.levelGroup:ComponentByName("levelNumText", typeof(UILabel))
	self.scoreGroup = self.rank_item_all:NodeByName("scoreGroup").gameObject
	self.scoreText = self.scoreGroup:ComponentByName("scoreText", typeof(UILabel))
	self.scoreNumText = self.scoreGroup:ComponentByName("scoreNumText", typeof(UILabel))
	self.levelText.text = __("LEV")
	self.scoreText.text = __("SCORE")
end

function RankItemAllItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info

	self.go:SetActive(true)

	if self.info then
		self.rank_ = self.info.rank

		if self.info.is_self then
			self.bgImg:SetActive(false)
		end

		local deal_score = self.info.score

		if deal_score > 0 and deal_score < 1 then
			deal_score = 1
		elseif deal_score > 1 then
			deal_score = math.floor(deal_score)
		end

		if tonumber(deal_score) >= 100000000 then
			self.scoreNumText.text = tostring(tonumber(deal_score) / 1000) .. "K"
		else
			self.scoreNumText.text = tostring(deal_score)
		end

		self.levelNumText.text = tostring(self.info.lv)
		self.labelPlayerName.text = self.info.name
		self.number.text = self.info.num .. "/" .. xyd.tables.guildExpTable:getMember(self.info.lv)
		self.serverId.text = xyd.getServerNumber(self.info.server_id)

		xyd.setUISprite(self.guildFlagImg, nil, xyd.tables.guildIconTable:getIcon(self.info.flag))
		self:layout()
	end
end

function RankItemAllItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and tonumber(self.rank_) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		if self.rank_ == 0 then
			self.labelRank.text = __("NO_GET_RANK")
		else
			self.labelRank.text = tostring(self.rank_)
		end
	end
end

function RankItemAllInItem:ctor(go, parent, params)
	self.go = go

	self:getUIComponent()

	self.parent = parent
end

function RankItemAllInItem:SetActive(visible)
	self.go:SetActive(visible)
end

function RankItemAllInItem:getUIComponent()
	self.rank_item_in = self.go
	self.bgImg = self.rank_item_in:ComponentByName("bgImg", typeof(UISprite))
	self.labelGroup = self.rank_item_in:NodeByName("labelGroup").gameObject
	self.imgRankIcon = self.labelGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = self.labelGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = self.rank_item_in:NodeByName("avatarGroup").gameObject
	self.playerIcon = self.avatarGroup:NodeByName("playerIcon").gameObject
	self.e_Group = self.rank_item_in:NodeByName("e:Group").gameObject
	self.labelLevel = self.e_Group:ComponentByName("labelLevel", typeof(UILabel))
	self.labelPlayerName = self.rank_item_in:ComponentByName("labelPlayerName", typeof(UILabel))
	self.scoreGroup = self.rank_item_in:NodeByName("scoreGroup").gameObject
	self.scoreText = self.scoreGroup:ComponentByName("scoreText", typeof(UILabel))
	self.scoreNumText = self.scoreGroup:ComponentByName("scoreNumText", typeof(UILabel))
	self.scoreText.text = __("WORLD_BOSS_DESC_TEXT")
end

function RankItemAllInItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info

	self.go:SetActive(true)

	if self.info then
		self.rank_ = self.info.rank
		local deal_score = self.info.score

		if deal_score > 0 and deal_score < 1 then
			deal_score = 1
		elseif deal_score > 1 then
			deal_score = math.floor(deal_score)
		end

		self.scoreNumText.text = xyd.getRoughDisplayNumber3(tonumber(deal_score))
		self.labelPlayerName.text = self.info.player_name
		self.labelLevel.text = self.info.lev

		if self.info.is_self then
			self.bgImg:SetActive(false)
		end

		self:layout()

		if not self.pIcon then
			if not self.info.is_self then
				self.pIcon = PlayerIcon.new(self.playerIcon, self.parent.rankListScroller_In_panel)
			else
				self.pIcon = PlayerIcon.new(self.playerIcon)
			end
		end

		self.pIcon:setInfo({
			avatarID = self.info.avatar_id,
			avatar_frame_id = self.info.avatar_frame_id
		})
	end
end

function RankItemAllInItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and tonumber(self.rank_) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		if self.rank_ == 0 then
			self.labelRank.text = __("NO_GET_RANK")
		else
			self.labelRank.text = tostring(self.rank_)
		end
	end
end

return GuildCompetitionRankWindow
