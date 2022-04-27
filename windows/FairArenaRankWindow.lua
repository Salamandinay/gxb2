local BaseWindow = import(".BaseWindow")
local FairArenaRankWindow = class("FairArenaRankWindow", BaseWindow)
local RankItem1 = class("RankItem1", import("app.common.ui.FixedWrapContentItem"))
local RankItem2 = class("RankItem2", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local CommonTabBar = import("app.common.ui.CommonTabBar")

function FairArenaRankWindow:ctor(name, params)
	FairArenaRankWindow.super.ctor(self, name, params)
end

function FairArenaRankWindow:initWindow()
	FairArenaRankWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
	xyd.models.fairArena:reqRank()
end

function FairArenaRankWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction").gameObject
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.nav = winTrans:NodeByName("nav").gameObject
	self.mainGroup = winTrans:NodeByName("mainGroup").gameObject
	self.group1 = self.mainGroup:NodeByName("group1").gameObject
	self.scrollView1 = self.group1:ComponentByName("scrollView", typeof(UIScrollView))
	self.rankListRect1 = self.group1:ComponentByName("scrollView", typeof(UIRect))
	self.itemGroup1 = self.group1:NodeByName("scrollView/itemGroup").gameObject
	self.rankItem1 = self.group1:NodeByName("scrollView/rank_item").gameObject
	self.group2 = self.mainGroup:NodeByName("group2").gameObject
	self.scrollView2 = self.group2:ComponentByName("scrollView", typeof(UIScrollView))
	self.rankListRect2 = self.group2:ComponentByName("scrollView", typeof(UIRect))
	self.itemGroup2 = self.group2:NodeByName("scrollView/itemGroup").gameObject
	self.rankItem2 = self.group2:NodeByName("scrollView/rank_item").gameObject
	self.selfRankGroup = self.mainGroup:NodeByName("selfRankGroup").gameObject
	self.upGroup = self.group1:NodeByName("upGroup").gameObject
	self.upGroupBg = self.upGroup:ComponentByName("upGroupBg", typeof(UITexture))
	self.upGroupPanel = self.upGroup:NodeByName("upGroupPanel").gameObject

	for i = 1, 3 do
		self["personCon" .. i] = self.upGroupPanel:NodeByName("personCon" .. i).gameObject
		self["defaultCon" .. i] = self["personCon" .. i]:NodeByName("defaultCon" .. i).gameObject
		self["showCon" .. i] = self["personCon" .. i]:NodeByName("showCon" .. i).gameObject
		self["nameCon" .. i] = self["showCon" .. i]:NodeByName("nameCon" .. i).gameObject
		self["nameCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("nameCon" .. i, typeof(UILayout))
		self["upLevelGroup" .. i] = self["nameCon" .. i]:NodeByName("upLevelGroup" .. i).gameObject
		self["upLabelLevel" .. i] = self["upLevelGroup" .. i]:ComponentByName("upLabelLevel" .. i, typeof(UILabel))
		self["labelPlayerName" .. i] = self["nameCon" .. i]:ComponentByName("labelPlayerName" .. i, typeof(UILabel))
		self["serverInfo" .. i] = self["showCon" .. i]:NodeByName("serverInfo" .. i).gameObject
		self["serverId" .. i] = self["serverInfo" .. i]:ComponentByName("serverId" .. i, typeof(UILabel))
		self["groupIcon" .. i] = self["serverInfo" .. i]:ComponentByName("groupIcon" .. i, typeof(UISprite))
		self["downLevelCon" .. i] = self["showCon" .. i]:NodeByName("downLevelCon" .. i).gameObject
		self["downLevelCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("downLevelCon" .. i, typeof(UILayout))
		self["labelDesText" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesText" .. i, typeof(UILabel))
		self["labelDesIcon" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesIcon" .. i, typeof(UISprite))
		self["labelCurrentNum" .. i] = self["downLevelCon" .. i]:ComponentByName("labelCurrentNum" .. i, typeof(UILabel))
		self["personEffectCon" .. i] = self["showCon" .. i]:NodeByName("personEffectCon" .. i).gameObject
	end
end

function FairArenaRankWindow:initUIComponent()
	self.titleLabel_.text = __("FAIR_ARENA_RANK_WINDOW")
	self.navGroup = CommonTabBar.new(self.nav, 2, function (index)
		if self.navFlag then
			self:updateRankList(index)
		end

		self.navFlag = true
	end)

	self.navGroup:setTexts({
		__("FAIR_ARENA_RANK_TOP"),
		__("FAIR_ARENA_RANK_TOTAL")
	})
end

function FairArenaRankWindow:register()
	FairArenaRankWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.FAIR_ARENA_RANK, handler(self, self.initRankList))
end

function FairArenaRankWindow:initRankList(event)
	self.rankInfo_ = xyd.decodeProtoBuf(event.data)

	if self:checkHideSelfRank() then
		self.selfRankGroup:SetActive(false)
		self.rankListRect1:SetBottomAnchor(self.mainGroup, 0, 2)
		self.rankListRect2:SetBottomAnchor(self.mainGroup, 0, 2)
	else
		self:initSelfRank()
	end

	self:updateRankList(1)
end

function FairArenaRankWindow:updateRankList(index)
	if not self.rankInfo_ then
		return
	end

	local collection = {}

	if index == 1 then
		self.group1:SetActive(true)
		self.group2:SetActive(false)

		if not self.wrapContent1 then
			local wrapContent = self.itemGroup1:GetComponent(typeof(UIWrapContent))
			self.wrapContent1 = FixedWrapContent.new(self.scrollView1, wrapContent, self.rankItem1, RankItem1, self)
		end

		if self.rankInfo_.list and #self.rankInfo_.list > 3 then
			for i = 4, #self.rankInfo_.list do
				table.insert(collection, {
					rank = i,
					info = self.rankInfo_.list[i]
				})
			end
		end

		self.wrapContent1:setInfos(collection, {})
		self:updateThree(self.rankInfo_)
	else
		self.group1:SetActive(false)
		self.group2:SetActive(true)

		if not self.wrapContent2 then
			local wrapContent = self.itemGroup2:GetComponent(typeof(UIWrapContent))
			self.wrapContent2 = FixedWrapContent.new(self.scrollView2, wrapContent, self.rankItem2, RankItem2, self)
		end

		local ids = xyd.tables.activityFairArenaRankTable:getIDs()

		if not self.rankInfo_.scores or #self.rankInfo_.scores < 0 then
			self.rankInfo_.scores = {}
		end

		for i = 1, #ids do
			table.insert(collection, {
				rank = i,
				info = ids[i],
				score = self.rankInfo_.scores[i] or 0
			})
		end

		self.wrapContent2:setInfos(collection, {})
	end
end

function FairArenaRankWindow:updateThree(rankData)
	if not rankData.list then
		rankData.list = {}
	end

	for i = 1, 3 do
		if rankData.list[i] then
			dump(rankData.list[i], "rankData.list[i] ")
			self["showCon" .. i].gameObject:SetActive(true)

			self["labelPlayerName" .. i].text = tostring(rankData.list[i].player_name)
			self["labelDesText" .. i].text = __("SCORE")
			self["serverId" .. i].text = xyd.getServerNumber(rankData.list[i].server_id)
			self["labelCurrentNum" .. i].text = tostring(math.ceil(rankData.list[i].score or 0))

			if rankData.list[i].group then
				xyd.setUISpriteAsync(self["groupIcon" .. i], nil, "arctic_expedition_cell_group_icon_" .. rankData.list[i].group, function ()
				end, nil, )
			end

			if i == 2 or i == 3 then
				while true do
					if self["labelPlayerName" .. i].width > 208 then
						self["labelPlayerName" .. i].fontSize = self["labelPlayerName" .. i].fontSize - 1
					else
						break
					end
				end
			end

			self["nameCon" .. i .. "_UILayout"]:Reposition()
			self["downLevelCon" .. i .. "_UILayout"]:Reposition()

			if not self["personEffect" .. i] then
				self["personEffect" .. i] = import("app.components.SenpaiModel").new(self["personEffectCon" .. i])
			end

			local styles = rankData.list[i].dress_style

			if not styles or #styles == 0 then
				styles = xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")
			end

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			self["showConPlayer" .. i] = rankData.list[i].player_id

			if not self["showCon" .. i .. "addEvent"] then
				self["showCon" .. i .. "addEvent"] = true
				UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
					if self["showConPlayer" .. i] ~= xyd.Global.playerID and rankData.list[i].player_id ~= xyd.Global.playerID then
						xyd.WindowManager.get():openWindow("arena_formation_window", {
							is_robot = false,
							player_id = rankData.list[i].player_id
						})
					end
				end)
			end
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function FairArenaRankWindow:checkHideSelfRank()
	if self.rankInfo_.self_score and self.rankInfo_.self_score > 0 then
		return false
	end

	return true
end

function FairArenaRankWindow:initSelfRank()
	self.selfRankGroup:SetActive(true)

	local levelIcon_ = self.selfRankGroup:ComponentByName("levelIcon_", typeof(UISprite))
	local levelLabel_ = self.selfRankGroup:ComponentByName("levelLabel_", typeof(UILabel))
	local avatarGroup = self.selfRankGroup:NodeByName("avatarGroup").gameObject

	if self.rankInfo_.self_rank < 3 then
		levelIcon_:SetActive(true)
		levelLabel_:SetActive(false)
		xyd.setUISprite(levelIcon_, nil, "rank_icon0" .. self.rankInfo_.self_rank + 1)
	else
		levelIcon_:SetActive(false)
		levelLabel_:SetActive(true)

		levelLabel_.text = self.rankInfo_.self_rank + 1
	end

	self.selfRankGroup:ComponentByName("nameLabel_", typeof(UILabel)).text = xyd.Global.playerName
	self.selfRankGroup:ComponentByName("serverInfo/serverLabel_", typeof(UILabel)).text = xyd.getServerNumber(xyd.models.selfPlayer:getServerID())
	self.selfRankGroup:ComponentByName("scoreTextLabel_", typeof(UILabel)).text = __("FAIR_ARENA_POINT")
	self.selfRankGroup:ComponentByName("scoreLabel_", typeof(UILabel)).text = self.rankInfo_.self_score
	self.pIcon = PlayerIcon.new(avatarGroup)

	self.pIcon:SetLocalScale(0.6403508771929824, 0.6403508771929824, 1)
	self.pIcon:setInfo({
		noClick = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		lev = xyd.models.backpack:getLev(),
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})
end

function RankItem1:ctor(go, parent)
	RankItem1.super.ctor(self, go, parent)
end

function RankItem1:initUI()
	local go = self.go
	self.levelIcon_ = go:ComponentByName("levelIcon_", typeof(UISprite))
	self.levelLabel_ = go:ComponentByName("levelLabel_", typeof(UILabel))
	self.avatarGroup = go:NodeByName("avatarGroup").gameObject
	self.nameLabel_ = go:ComponentByName("nameLabel_", typeof(UILabel))
	self.serverLabel_ = go:ComponentByName("serverInfo/serverLabel_", typeof(UILabel))
	self.scoreTextLabel_ = go:ComponentByName("scoreTextLabel_", typeof(UILabel))
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.scoreTextLabel_.text = __("FAIR_ARENA_POINT")
end

function RankItem1:updateInfo()
	self.info = self.data.info
	self.rank = self.data.rank

	if not self.info or not tonumber(self.info.player_id) then
		self.go:SetActive(false)

		return
	else
		self.go:SetActive(true)
	end

	if self.rank <= 3 then
		self.levelIcon_:SetActive(true)
		self.levelLabel_:SetActive(false)
		xyd.setUISprite(self.levelIcon_, nil, "rank_icon0" .. self.rank)
	else
		self.levelIcon_:SetActive(false)
		self.levelLabel_:SetActive(true)

		self.levelLabel_.text = self.rank
	end

	if not self.pIcon then
		local scroller_panel = nil

		if self.parent and self.parent.scrollView1 then
			scroller_panel = self.parent.scrollView1.gameObject:GetComponent(typeof(UIPanel))
		end

		self.pIcon = PlayerIcon.new(self.avatarGroup, scroller_panel)

		self.pIcon:SetLocalScale(0.6403508771929824, 0.6403508771929824, 1)
	end

	self.pIcon:setInfo({
		noClick = false,
		avatarID = self.info.avatar_id,
		avatar_frame_id = self.info.avatar_frame_id,
		lev = self.info.lev,
		callback = function ()
			if self.info.player_id ~= xyd.Global.playerID then
				xyd.WindowManager.get():openWindow("arena_formation_window", {
					is_robot = false,
					player_id = self.info.player_id
				})
			end
		end
	})

	self.nameLabel_.text = self.info.player_name
	self.serverLabel_.text = xyd.getServerNumber(self.info.server_id)
	self.scoreLabel_.text = self.info.score
end

function RankItem2:ctor(go, parent)
	RankItem2.super.ctor(self, go, parent)
end

function RankItem2:initUI()
	local go = self.go
	self.bg_ = go:ComponentByName("bg_", typeof(UISprite))
	self.rankLabel_ = go:ComponentByName("rankLabel_", typeof(UILabel))
	self.scoreTextLabel_ = go:ComponentByName("scoreTextLabel_", typeof(UILabel))
	self.scoreLabel_ = go:ComponentByName("scoreLabel_", typeof(UILabel))
	self.scoreTextLabel_.text = __("FAIR_ARENA_RANK_SCORE_MAX")
end

function RankItem2:updateInfo()
	self.rank = self.data.rank
	self.info = self.data.info
	self.score = self.data.score or 0
	self.rankLabel_.text = xyd.tables.activityFairArenaRankTable:getRankShow(self.rank)

	if self.rank <= 3 then
		xyd.setUISpriteAsync(self.bg_, nil, "9gongge3" .. self.rank - 1)
	else
		xyd.setUISpriteAsync(self.bg_, nil, "9gongge17")
	end

	if self.score == 0 then
		self.scoreLabel_:SetActive(false)
		self.scoreTextLabel_:SetActive(false)
	else
		self.scoreLabel_:SetActive(true)
		self.scoreTextLabel_:SetActive(true)

		self.scoreLabel_.text = self.score
	end
end

return FairArenaRankWindow
