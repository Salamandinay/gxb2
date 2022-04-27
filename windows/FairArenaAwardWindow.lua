local FairArenaAwardWindow = class("FairArenaAwardWindow", import(".BaseWindow"))
local SeasonAwardItem = class("SeasonAwardItem", import("app.common.ui.FixedWrapContentItem"))
local TreasureAwardItem = class("TreasureAwardItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = import("app.common.ui.CommonTabBar")
local CountDown = import("app.components.CountDown")
local rankTable = xyd.tables.activityFairArenaRankTable
local levelTable = xyd.tables.activityFairArenaLevelTable

function FairArenaAwardWindow:ctor(name, params)
	FairArenaAwardWindow.super.ctor(self, name, params)
end

function FairArenaAwardWindow:initWindow()
	FairArenaAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:updateContent(self.select)
	self:register()
end

function FairArenaAwardWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.nav = winTrans:NodeByName("nav").gameObject
	local mainGroup = winTrans:NodeByName("mainGroup")
	self.seasonAward = mainGroup:NodeByName("seasonAward").gameObject
	local upGroup = self.seasonAward:NodeByName("upGroup")
	self.nowRankLabel_ = upGroup:ComponentByName("nowRankLabel_", typeof(UILabel))
	self.nowAwardLabel_ = upGroup:ComponentByName("nowAwardLabel_", typeof(UILabel))
	self.everRankLabel_ = upGroup:ComponentByName("everRankLabel_", typeof(UILabel))
	self.everTopRankLabel_ = upGroup:ComponentByName("everTopRankLabel_", typeof(UILabel))
	self.desLabel_ = upGroup:ComponentByName("desLabel_", typeof(UILabel))
	self.timeLabel_ = upGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.nowAward = upGroup:NodeByName("nowAward").gameObject
	self.clockIcon_ = upGroup:NodeByName("clockIcon_").gameObject
	self.scrollView1 = self.seasonAward:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup1 = self.seasonAward:NodeByName("scrollView/itemGroup").gameObject
	self.awardItem1 = self.seasonAward:NodeByName("scrollView/seasonAwardItem").gameObject
	self.treasureAward = mainGroup:NodeByName("treasureAward").gameObject
	self.scrollView2 = self.treasureAward:ComponentByName("scrollView", typeof(UIScrollView))
	self.itemGroup2 = self.treasureAward:NodeByName("scrollView/itemGroup").gameObject
	self.awardItem2 = self.treasureAward:NodeByName("scrollView/treasureAwardItem").gameObject
end

function FairArenaAwardWindow:initUIComponent()
	self.data = xyd.models.fairArena:getArenaInfo()
	local activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FAIR_ARENA)
	self.titleLabel_.text = __("AWARD3")
	self.nowAwardLabel_.text = __("FAIR_ARENA_AWARDS_LEVEL_NOW")
	self.everRankLabel_.text = __("FAIR_ARENA_RANK_HISTORY_MAX")
	self.desLabel_.text = __("FAIR_ARENA_DESC_AWARDS")

	CountDown.new(self.timeLabel_, {
		duration = activityData:getEndTime() - xyd.getServerTime() - xyd.TimePeriod.DAY_TIME
	})

	local effect = xyd.Spine.new(self.clockIcon_)

	effect:setInfo("fx_ui_shizhong", function ()
		effect:SetLocalScale(1, 1, 1)
		effect:SetLocalPosition(0, 0, 0)
		effect:play("texiao1", 0)
	end)

	self.navGroup = CommonTabBar.new(self.nav, 2, function (index)
		if self.navFlag then
			self:updateContent(index)
		end

		self.navFlag = true
	end)

	self.navGroup:setTexts({
		__("FAIR_ARENA_AWARDS_RANK"),
		__("FAIR_ARENA_AWARDS_LEVEL")
	})

	self.select = tonumber(xyd.db.misc:getValue("fair_arena_award_last_select")) or 1

	self:waitForFrame(1, function ()
		self.navGroup:setTabActive(self.select, true)
	end)

	local self_rank = ""

	if self.data.self_rank then
		self_rank = self.data.self_rank + 1
	end

	self.nowRankLabel_.text = __("FAIR_ARENA_RANK_NOW") .. self_rank

	if self.data.history_rank and self.data.history_rank > 0 then
		self.everRankLabel_:SetActive(false)
		self.everTopRankLabel_:SetActive(false)

		self.everTopRankLabel_.text = self.data.history_rank
	else
		self.everRankLabel_:SetActive(false)
		self.everTopRankLabel_:SetActive(false)
	end

	if self_rank and self_rank ~= "" then
		local awards = rankTable:getAwardsByRank(self.data.self_rank)

		for i = 1, #awards do
			local item = xyd.getItemIcon({
				scale = 0.7037037037037037,
				uiRoot = self.nowAward,
				itemID = awards[i][1],
				num = awards[i][2]
			})
		end

		self.nowAward:GetComponent(typeof(UILayout)):Reposition()
	end
end

function FairArenaAwardWindow:updateContent(index)
	if index == 1 then
		self.seasonAward:SetActive(true)
		self.treasureAward:SetActive(false)

		if not self.seasonWrapContent then
			local wrapContent = self.itemGroup1:GetComponent(typeof(UIWrapContent))
			self.seasonWrapContent = FixedWrapContent.new(self.scrollView1, wrapContent, self.awardItem1, SeasonAwardItem, self)
		end

		local ids = rankTable:getIDs()

		self.seasonWrapContent:setInfos(ids, {})
	else
		self.seasonAward:SetActive(false)
		self.treasureAward:SetActive(true)

		if not self.treasureWrapContent then
			local wrapContent = self.itemGroup2:GetComponent(typeof(UIWrapContent))
			self.treasureWrapContent = FixedWrapContent.new(self.scrollView2, wrapContent, self.awardItem2, TreasureAwardItem, self)
		end

		local ids = levelTable:getIDs()

		table.sort(ids, function (a, b)
			return b < a
		end)
		self.treasureWrapContent:setInfos(ids, {})
	end
end

function FairArenaAwardWindow:register()
	FairArenaAwardWindow.super.register(self)
end

function SeasonAwardItem:ctor(go, parent)
	SeasonAwardItem.super.ctor(self, go, parent)
end

function SeasonAwardItem:initUI()
	local go = self.go
	self.rankLabel_ = go:ComponentByName("rankLabel_", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.layout = self.awardGroup:GetComponent(typeof(UILayout))
end

function SeasonAwardItem:updateInfo()
	self.id = self.data
	self.rankLabel_.text = rankTable:getRankShow(self.id)
	local awards = rankTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local item = xyd.getItemIcon({
			scale = 0.7037037037037037,
			uiRoot = self.awardGroup,
			itemID = awards[i][1],
			num = awards[i][2],
			dragScrollView = self.parent.scrollView1
		})
	end

	self.layout:Reposition()
end

function TreasureAwardItem:ctor(go, parent)
	TreasureAwardItem.super.ctor(self, go, parent)
end

function TreasureAwardItem:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.levelIcon_ = go:ComponentByName("levelIcon_", typeof(UISprite))
	self.levelLabel_ = go:ComponentByName("levelLabel_", typeof(UILabel))
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.scoreNumLabel_ = go:ComponentByName("scoreNumLabel_", typeof(UILabel))
	self.awardGroup = go:NodeByName("awardGroup").gameObject
	self.layout = self.awardGroup:GetComponent(typeof(UILayout))
	self.scoreLabel_.text = __("RANK_TEXT03")
end

function TreasureAwardItem:updateInfo()
	self.id = self.data

	self.bg_:SetActive(self.id % 2 == 1)

	self.levelLabel_.text = __("FAIR_ARENA_TITLE_GIFT", levelTable:getLevel(self.id))
	self.scoreNumLabel_.text = "+" .. levelTable:getScore(self.id)
	local style = levelTable:getStyle(self.id)

	xyd.setUISpriteAsync(self.levelIcon_, nil, "fair_arena_awardbox_icon" .. style)

	local awards = levelTable:getAwards(self.id)

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i = 1, #awards do
		local item = xyd.getItemIcon({
			scale = 0.5092592592592593,
			uiRoot = self.awardGroup,
			itemID = awards[i][1],
			num = awards[i][2],
			dragScrollView = self.parent.scrollView2
		})
	end

	self.layout:Reposition()
end

return FairArenaAwardWindow
