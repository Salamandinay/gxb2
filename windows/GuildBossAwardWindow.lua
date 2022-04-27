local BaseWindow = import(".BaseWindow")
local GuildBossAwardWindow = class("GuildBossAwardWindow", BaseWindow)
local GuildBossKillAwardItem = class("GuildBossKillAwardItem")

function GuildBossAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.bossId_ = params.bossId or 0
end

function GuildBossAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function GuildBossAwardWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.scroller = go:ComponentByName("bGroup/e:Scroller", typeof(UIScrollView))
	self.awardContainer = go:NodeByName("bGroup/e:Scroller/awardContainer").gameObject
	self.labelAward1 = go:ComponentByName("bGroup/labelAward1", typeof(UILabel))
	self.labelAward2 = go:ComponentByName("bGroup/labelAward2", typeof(UILabel))
	self.item = go:NodeByName("bGroup/item").gameObject
	self.itemTitle = self.item:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = self.item:NodeByName("itemGroup").gameObject
	self.rankImg = self.item:ComponentByName("rankImg", typeof(UISprite))
end

function GuildBossAwardWindow:initUIComponent()
	self.labelAward1.text = tostring(__("GUILD_BOSS_AWARD_1")) .. " :"
	self.labelAward2.text = tostring(__("GUILD_BOSS_AWARD_2")) .. " :"

	if xyd.Global.lang == "fr_fr" then
		self.labelAward1:X(-180)
		self.labelAward2:X(-155)
	end

	self.labelTitle.text = __("GUILD_BOSS_AWARD_2")

	self:initKillAward()
	self:initBattleAward()
end

function GuildBossAwardWindow:initBattleAward()
	self.itemTitle.text = __("GUILD_BOSS_AWARD_3") .. " :"

	if xyd.Global.lang == "fr_fr" then
		self.itemTitle:X(-165)
	end

	local awardsDataList = xyd.tables.guildBossTable:getBattleAwards(self.bossId_)

	for i = 1, #awardsDataList do
		local itemData = awardsDataList[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end
end

function GuildBossAwardWindow:initKillAward()
	local rankMaxId = xyd.tables.guildBossRankTable:getMaxID()

	for i = 1, rankMaxId do
		local rank = xyd.tables.guildBossRankTable:getRank(i)
		local awardName = xyd.tables.guildBossRankTable:getName(i)
		local awardsData = xyd.tables.guildBossTable:getKillAwards(self.bossId_, awardName)
		local go = NGUITools.AddChild(self.awardContainer, self.item)
		local awardItem = GuildBossKillAwardItem.new(go, {
			awardsData = awardsData,
			rank = rank,
			id = i
		}, self)
	end

	self.awardContainer:GetComponent(typeof(UILayout)):Reposition()
end

function GuildBossKillAwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function GuildBossKillAwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.rankImg = go:ComponentByName("rankImg", typeof(UISprite))
end

function GuildBossKillAwardItem:initUIComponent()
	if self.rank <= 3 then
		xyd.setUISprite(self.rankImg, nil, "rank_icon0" .. self.rank)
		self.rankImg:SetActive(true)
		self.itemTitle:SetActive(false)
	else
		self.rankImg:SetActive(false)
		self.itemTitle:SetActive(true)

		self.itemTitle.text = xyd.tables.guildBossRankTable:getShow(self.id)
	end

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.scroller,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return GuildBossAwardWindow
