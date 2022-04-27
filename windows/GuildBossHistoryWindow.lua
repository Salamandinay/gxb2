local BaseWindow = import(".BaseWindow")
local GuildBossHistoryWindow = class("GuildBossHistoryWindow", BaseWindow)
local GuildBossHistoryItem = class("GuildBossHistoryItem", require("app.components.CopyComponent"))

function GuildBossHistoryWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.bossId_ = params.bossId
end

function GuildBossHistoryWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.bGroup = go:NodeByName("bGroup").gameObject
	self.scrollView_ = self.bGroup:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.historyContainer = self.bGroup:NodeByName("e:Scroller/historyContainer").gameObject
	self.item = self.window_:NodeByName("item").gameObject

	self.item:SetActive(false)
end

function GuildBossHistoryWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()

	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)

	if self.bossData_ then
		self:refresh()
	else
		xyd.models.guild:reqBossInfo(self.bossId_)
	end
end

function GuildBossHistoryWindow:initUIComponent()
	self.labelTitle.text = __("GUILD_HISTORY_WINDOW_NAME")
end

function GuildBossHistoryWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.GUILD_BOSS_INFO, self.refreshData, self)
end

function GuildBossHistoryWindow:refreshData()
	self.bossData_ = xyd.models.guild:getBossInfo(self.bossId_)

	self:refresh()
end

function GuildBossHistoryWindow:refresh()
	self.bossInfo_ = self.bossData_.bossInfo
	self.bossRank_ = self.bossData_.bossRank
	local renderPanel = self.bGroup:ComponentByName("e:Scroller", typeof(UIPanel))
	local topHarm = 0
	local rank_info = {
		"score",
		"player_name",
		"avatar_id",
		"avatar_frame_id",
		"lev",
		"player_id",
		"power",
		"server_id"
	}

	NGUITools.DestroyChildren(self.historyContainer.transform)

	for i = 1, #self.bossRank_ do
		local rankData = {}

		if i == 1 then
			topHarm = self.bossRank_[i].score
		end

		for _, k in ipairs(rank_info) do
			rankData[k] = self.bossRank_[i][k]
		end

		rankData.rank = i
		rankData.bossId = self.bossId_
		rankData.topHarm = topHarm
		local go = NGUITools.AddChild(self.historyContainer, self.item)
		local rankItem = GuildBossHistoryItem.new(go, rankData, renderPanel)
	end

	self.historyContainer:GetComponent(typeof(UILayout)):Reposition()
	self.scrollView_:ResetPosition()
end

function GuildBossHistoryItem:ctor(go, params, renderPanel)
	GuildBossHistoryItem.super.ctor(self, go)

	self.rankData = params
	self.renderPanel_ = renderPanel

	self:getUIComponent()
	self:initUIComponent()
end

function GuildBossHistoryItem:getUIComponent()
	local go = self.go
	self.labelName = go:ComponentByName("labelName", typeof(UILabel))
	self.harmProgressBar = go:ComponentByName("harmProgressBar", typeof(UIProgressBar))
	self.harmProgressBar_label = self.harmProgressBar:ComponentByName("label", typeof(UILabel))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIcon = go:NodeByName("pIcon").gameObject
	self.pIcon = require("app.components.PlayerIcon").new(pIcon, self.renderPanel_)
	self.itemGroup = go:NodeByName("itemGroup").gameObject
end

function GuildBossHistoryItem:initUIComponent()
	self.labelName.text = self.rankData.player_name

	if self.rankData.rank <= 3 then
		xyd.setUISprite(self.imgRank, nil, "rank_icon0" .. self.rankData.rank)
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.labelRank.text = tostring(self.rankData.rank)

		self.labelRank:SetActive(true)
		self.imgRank:SetActive(false)
	end

	self.pIcon:setInfo({
		noClick = true,
		avatarID = self.rankData.avatar_id,
		avatar_frame_id = self.rankData.avatar_frame_id
	})
	self.pIcon:SetLocalScale(0.65, 0.65, 1)

	self.harmProgressBar_label.text = self.rankData.score
	self.harmProgressBar.value = self.rankData.score / self.rankData.topHarm
	local awardName = xyd.tables.guildBossRankTable:getNameByRank(self.rankData.rank)
	local awardsData = xyd.tables.guildBossTable:getKillAwards(self.rankData.bossId, awardName)

	for i = 1, #awardsData do
		local itemData = awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.67, 0.67, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return GuildBossHistoryWindow
