local BaseWindow = import(".BaseWindow")
local GuildWarRankWindow = class("GuildWarRankWindow", BaseWindow)
local RankItem = class("RankItem", import("app.components.BaseComponent"))
local GuildWarRankItem = class("GuildWarRankItem", import("app.components.BaseComponent"))

function RankItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.rankItem = GuildWarRankItem.new(go, self.parent)

	self.rankItem:setDragScrollView(parent.scrollView)
end

function RankItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.rankItem.params = data

	self.rankItem:setInfo(data.rank, data.info)
end

function RankItem:getGameObject()
	return self.go
end

function GuildWarRankWindow:ctor(name, params)
	GuildWarRankWindow.super.ctor(self, name, params)
end

function GuildWarRankWindow:initWindow()
	GuildWarRankWindow.super.initWindow(self)
	self:registerEvent()

	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelWinTitle = content:ComponentByName("labelWinTitle", typeof(UILabel))
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.scrollView:NodeByName("rankListContainer").gameObject
	local wrapContent = self.scrollView:ComponentByName("rankListContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("container").gameObject
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView, wrapContent, iconContainer, RankItem, self)
	self.playerRankGroup = middleGroup:NodeByName("playerRankGroup").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject

	UIEventListener.Get(self.closeBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	xyd.models.guildWar:reqRankList()
	self:initSelfRank()
end

function GuildWarRankWindow:initSelfRank()
	local selfItem = GuildWarRankItem.new(self.playerRankGroup:ComponentByName("bgImg3", typeof(UIWidget)).gameObject)
	local selfParams = {
		flag = xyd.models.guild.base_info.flag,
		name = xyd.models.guild.base_info.name,
		score = xyd.models.guildWar:getScore(),
		server_id = xyd.models.guild:getSelfServer()
	}
	local params = {
		rank = xyd.models.guildWar:getRank(),
		info = selfParams
	}

	selfItem:setInfo(params.rank, params.info)
	selfItem:setBgVisible(false)
end

function GuildWarRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_GET_RANK_LIST, self.layout, self)
end

function GuildWarRankWindow:layout(event)
	local rankList = event.data.list
	local dataList = {}

	for idx, info in ipairs(rankList) do
		table.insert(dataList, {
			rank = idx,
			info = info
		})
	end

	self.wrapContent:setInfos(dataList, {})
end

function GuildWarRankItem:ctor(go, parent)
	self.parent_ = parent

	GuildWarRankItem.super.ctor(self, go)
end

function GuildWarRankItem:getPrefabPath()
	return "Prefabs/Components/guild_war_rank_item"
end

function GuildWarRankItem:initUI()
	GuildWarRankItem.super.initUI(self)

	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite)).gameObject
	self.imgRankIcon_ = go:ComponentByName("rankGroup/imgRankIcon", typeof(UISprite))
	self.labelRank_ = go:ComponentByName("rankGroup/labelRank", typeof(UILabel))
	self.guildIcon_ = go:ComponentByName("guildIcon", typeof(UISprite))
	self.guildName_ = go:ComponentByName("guildName", typeof(UILabel))
	self.labelPointTitle_ = go:ComponentByName("labelPointTitle", typeof(UILabel))
	self.labelPoint_ = go:ComponentByName("labelPoint", typeof(UILabel))
	self.serverID_ = go:ComponentByName("serverGroup/label", typeof(UILabel))
end

function GuildWarRankItem:setInfo(rank, info)
	if not info then
		return
	else
		if not self.info_ or self.info_.flag ~= info.flag then
			local flag = xyd.tables.guildIconTable:getIcon(info.flag)

			xyd.setUISpriteAsync(self.guildIcon_, nil, flag)
		end

		if not self.rank_ or self.rank_ ~= rank then
			if rank > 3 then
				self.imgRankIcon_.gameObject:SetActive(false)
				self.labelRank_.gameObject:SetActive(true)

				self.labelRank_.text = rank
			else
				self.imgRankIcon_.gameObject:SetActive(true)
				self.labelRank_.gameObject:SetActive(false)
				xyd.setUISpriteAsync(self.imgRankIcon_, nil, "rank_icon0" .. rank)
			end
		end

		self.guildName_.text = info.name
		self.labelPointTitle_.text = __("SCORE")
		self.labelPoint_.text = info.score
		self.serverID_.text = xyd.getServerNumber(info.server_id)
		self.info_ = info
		self.rank_ = rank
	end
end

function GuildWarRankItem:setDragScrollView(scrollView)
	local drag = self.bgImg:AddComponent(typeof(UIDragScrollView))
	drag.scrollView = scrollView
end

function GuildWarRankItem:setBgVisible(state)
	self.bgImg.gameObject:SetActive(state)
end

return GuildWarRankWindow
