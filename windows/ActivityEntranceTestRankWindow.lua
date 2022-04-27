local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestRankWindow = class("ActivityEntranceTestRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local EntranceRankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local NAV_TYPE = {
	REWARD = 2,
	RANK = 1
}

function ActivityEntranceTestRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.rankData = params.rankData
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.curMissionType = NAV_TYPE.RANK
end

function ActivityEntranceTestRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initNav()
	self:layout()
	self:onTouch(self.curMissionType)
end

function ActivityEntranceTestRankWindow:getUIComponent()
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
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, EntranceRankItem, self)
	self.rankUpgroup = self.rankNode:NodeByName("rankUpgroup").gameObject
	self.rankUpExplainBtn = self.rankUpgroup:NodeByName("rankUpExplainBtn").gameObject
	self.rankUpBgImg = self.rankUpgroup:ComponentByName("rankUpBgImg", typeof(UISprite))
	self.rankUpExplainText = self.rankUpgroup:ComponentByName("rankUpExplainText", typeof(UILabel))
	self.rankUpFrameCon = self.rankUpgroup:NodeByName("rankUpFrameCon").gameObject
	self.rankUpPlayerIcon = PlayerIcon.new(self.rankUpFrameCon)

	self.rankUpPlayerIcon:setScale(0.8770491803278688)

	self.rankUpLevelIcon = self.rankUpgroup:ComponentByName("rankUpLevelIcon", typeof(UISprite))
	self.rankExplainCon = self.rankNode:NodeByName("rankExplainCon").gameObject
	self.rankLabelDesc = self.rankExplainCon:ComponentByName("rankLabelDesc", typeof(UILabel))
	self.rankClock = self.rankExplainCon:ComponentByName("rankClock", typeof(UITexture))
	self.rankDdl1 = self.rankExplainCon:NodeByName("rankDdl1").gameObject
	self.rankDdl2Text = self.rankExplainCon:ComponentByName("rankDdl2Text", typeof(UILabel))
	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	local help_values = {}

	for i = 2, 4 do
		table.insert(help_values, xyd.tables.activityEntranceTestRankTable:getName(i))
		table.insert(help_values, __("WARMUP_ARENA_RANK_INFO_" .. i))
	end

	UIEventListener.Get(self.rankUpExplainBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "WARMUP_ARENA_REACH_RANK_HELP",
			values = help_values
		})
	end)
	self.winName.text = __("CAMPAIGN_RANK_WINDOW")
end

function ActivityEntranceTestRankWindow:initNav()
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

	self.tab:setTexts(xyd.split(__("ACTIVITY_SPORTS_RANK_LABELS"), "|"))
end

function ActivityEntranceTestRankWindow:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:onTouch(i)
end

function ActivityEntranceTestRankWindow:layout()
	self:initRankList()
end

function ActivityEntranceTestRankWindow:initRankList()
	if not self.rankData then
		return
	end

	local level = self.activityData:getLevel()

	if xyd.EntranceTestLevelType.R1 <= level and level <= xyd.EntranceTestLevelType.R3 then
		self.rankUpLevelIcon.gameObject:SetActive(true)
		xyd.setUISpriteAsync(self.rankUpLevelIcon, nil, "entrance_test_level_" .. level + 1, nil, , true)
		self.rankUpFrameCon.gameObject:SetActive(false)

		local textNum = xyd.tables.activityEntranceTestRankTable:getRankPercent(level) * 100
		self.rankUpExplainText.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_2", textNum .. "%")
	else
		self.rankUpExplainText.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_1")

		self.rankUpLevelIcon.gameObject:SetActive(false)
		self.rankUpFrameCon.gameObject:SetActive(true)

		local reseTinfo = {
			avatar_frame_id = xyd.tables.miscTable:split2Cost("activity_warmup_arena_awards", "value", "#")[1]
		}

		self.rankUpPlayerIcon:setInfo(reseTinfo)
	end

	self.summonEffect_ = xyd.Spine.new(self.rankClock.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:play("texiao1", 0)
	end)
	self:updateRankDDL1()

	if self.rankData.rank == -1 then
		self.playerRankGroup:SetActive(false)
	else
		self:initSelfRank()
	end

	self.rankDataList = {}

	for i in pairs(self.rankData.list) do
		local data = self.rankData.list[i]
		local rank = i

		if data.rank then
			rank = data.rank
		end

		local params = {}

		if data.is_robot and data.is_robot == 1 then
			local robotInfo = xyd.tables.activityEntranceTestRobotTable:getAllInfo(data.player_id)
			params = {
				group = 0,
				avatar_id = robotInfo.avatar,
				level = robotInfo.lv,
				player_name = robotInfo.name,
				server_id = robotInfo.server,
				point = data.score,
				rank = rank
			}
		else
			params = {
				group = 0,
				avatar_id = data.avatar_id,
				frame_id = data.avatar_frame_id,
				level = data.lev,
				player_name = data.player_name,
				server_id = data.server_id,
				point = data.score,
				rank = rank
			}
		end

		if params.avatar_id then
			table.insert(self.rankDataList, params)
		end
	end

	self.wrapContent:setInfos(self.rankDataList, {})
end

function ActivityEntranceTestRankWindow:updateRankDDL1()
	local endTime = self.activityData:getEndTime()
	local durationTime = 0
	local level = self.activityData:getLevel()
	local startTime = self.activityData:startTime()

	if xyd.EntranceTestLevelType.R1 <= level and level <= xyd.EntranceTestLevelType.R3 then
		local serverTime = xyd.getServerTime()

		if startTime <= serverTime and serverTime < startTime + xyd.DAY_TIME * 5 then
			self.rankLabelDesc.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_4")
			endTime = startTime + math.ceil((serverTime - startTime) / xyd.DAY_TIME) * xyd.DAY_TIME
		elseif serverTime >= startTime + xyd.DAY_TIME * 5 and serverTime < startTime + xyd.DAY_TIME * 6 then
			self.rankLabelDesc.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_5")
			endTime = startTime + 6 * xyd.DAY_TIME
		end
	else
		self.rankLabelDesc.text = __("ACTIVITY_ENTRANCE_TEST_RANK_WINDOW_5")
		endTime = startTime + 6 * xyd.DAY_TIME
	end

	durationTime = endTime - xyd.getServerTime()

	if durationTime > 0 then
		self.setRankCountDownTime = CountDown.new(self.rankDdl2Text, {
			duration = durationTime,
			callback = handler(self, self.rankTimeOver)
		})
	else
		self.rankDdl2Text.text = "00:00:00"
	end
end

function ActivityEntranceTestRankWindow:rankTimeOver()
	self.rankDdl2Text.text = "00:00:00"
end

function ActivityEntranceTestRankWindow:initSelfRank()
	local self_item = {
		isSelf = true,
		group = 0,
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		point = self.rankData.score,
		rank = self.rankData.rank
	}
	local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
	local item = EntranceRankItem.new(tmp, self, self_item)
end

function ActivityEntranceTestRankWindow:initAwardLayout()
	self.summonEffect_ = xyd.Spine.new(self.clock.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:setRenderTarget(self.clock:GetComponent(typeof(UITexture)), 1)
		self.summonEffect_:play("texiao1", 0)

		local selfAwardInfo = xyd.tables.activityWarmupArenaAwardTable:getRankInfo(self.rankData.rank, self.rankData.num)

		if self.activityData.detail.score and self.activityData.detail.score ~= 0 then
			self.labelRank.text = tostring(__("NOW_RANK")) .. ": " .. tostring(selfAwardInfo.rankText)
		else
			self.labelRank.text = tostring(__("NOW_RANK")) .. ": " .. "100%"
		end

		self.labelNowAward.text = __("NOW_AWARD")
		self.labelTopRank.text = tostring(__("TOP_RANK")) .. ":"
		self.labelDesc.text = __("BOOK_RESEARCH_TEXT07")

		self:updateDDL1()
		self:layoutAward(selfAwardInfo)
	end)
end

function ActivityEntranceTestRankWindow:layoutAward(selfAwardInfo)
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	if not self.activityData.detail.score or self.activityData.detail.score == 0 then
		selfAwardInfo.award = {}
	end

	for i in pairs(selfAwardInfo.award) do
		local item = selfAwardInfo.award[i]
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			hideText = true,
			isShowSelected = false,
			itemID = item.item_id,
			num = item.item_num,
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.nowAward.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	local a_t = xyd.tables.activityWarmupArenaAwardTable

	for i in pairs(a_t:getIds()) do
		local awardItem = NGUITools.AddChild(self.awardContainer.gameObject, self.arena_award_item.gameObject)
		local item = ArenaAwardItem.new(awardItem)
		item.totalNum = self.rankData.num

		item:setInfo(i, "award", a_t)
	end

	self.arena_award_item:SetActive(false)
end

function ActivityEntranceTestRankWindow:updateDDL1()
	local endTime = self.activityData:getEndTime() - xyd.getServerTime() - xyd.DAY_TIME

	if endTime > 0 then
		self.setCountDownTime = CountDown.new(self.ddl2Text, {
			duration = endTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.ddl2Text.text = "00:00:00"
	end
end

function ActivityEntranceTestRankWindow:timeOver()
	self.ddl2Text.text = "00:00"
end

function ActivityEntranceTestRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK then
		self.rankNode:SetActive(true)
		self.awardNode:SetActive(false)
	elseif index == NAV_TYPE.REWARD then
		self.rankNode:SetActive(false)
		self.awardNode:SetActive(true)
	end
end

function EntranceRankItem:ctor(go, parent, params)
	self.go = go
	self.parent = parent

	self:getUIComponent()

	if params then
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank
		self.group_ = tonumber(params.group)
		self.isSelf = params.isSelf

		self:layout()
	end
end

function EntranceRankItem:getUIComponent()
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
	self.levelIcon = self.go:ComponentByName("levelIcon", typeof(UISprite))
	self.labelDesText.text = __("SCORE")
	self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")

	xyd.setUISpriteAsync(self.levelIcon, nil, "entrance_test_level_" .. self.parent.activityData:getLevel(), function ()
		self.levelIcon.gameObject:SetLocalScale(0.51, 0.56, 0)
	end, nil, true)

	self.pIcon = PlayerIcon.new(self.playerIcon)
end

function EntranceRankItem:update(index, info)
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
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank
		self.group_ = tonumber(params.group)
		self.isSelf = params.isSelf

		self:layout()
	end
end

function EntranceRankItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and self.point_ and self.point_ >= 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	elseif self.point_ and self.point_ >= 0 then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		if self.rank_ then
			self.labelRank.text = tostring(self.rank_)

			if self.point_ > 0 and self.isSelf and self.rank_ > 50 and self.parent.activityData:getLevel() < xyd.EntranceTestLevelType.R4 then
				local num = math.floor(self.rank_ / self.parent.rankData.num * 1000) / 1000 * 100

				if num < 0.1 then
					num = 0.1
				end

				if num > 100 then
					num = 100
				end

				self.labelRank.text = tostring(num) .. "%"
			end
		else
			self.labelRank.text = ""
		end
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	end

	if self.point_ and self.point_ == 0 and self.isSelf then
		if self.parent.activityData.detail.partners and #self.parent.activityData.detail.partners > 0 then
			if self.rank_ then
				if self.rank_ > 50 then
					self.labelRank.text = "100%"
				end
			else
				self.labelRank.text = "100%"
			end
		else
			self.imgRankIcon:SetActive(false)
			self.labelRank:SetActive(false)
		end
	end

	if self.group_ == 0 then
		self.groupWords:SetActive(false)
		self.groupImg:SetActive(false)
	else
		self.groupWords:SetActive(true)
		self.groupImg:SetActive(true)

		self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")

		xyd.setUISpriteAsync(self.groupImg, nil, "img_group" .. self.group_, nil, )
	end

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_
	})

	self.labelPlayerName.text = self.player_name_
	self.serverId.text = xyd.getServerNumber(self.server_id_)

	if self.point_ then
		self.labelCurrentNum.text = self.point_
	else
		self.labelCurrentNum.text = "0"
	end

	if self.hide_bg_ then
		self.bgImg:SetActive(false)
	end
end

function ArenaAwardItem:ctor(go)
	self.go = go

	self:getUIComponent()
end

function ArenaAwardItem:getUIComponent()
	self.bg = self.go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = self.go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = self.go:ComponentByName("labelRank", typeof(UILabel))
	self.awardGroup = self.go:NodeByName("awardGroup")
end

function ArenaAwardItem:setInfo(id, colName, table, notShowSpecial)
	table = table or xyd.tables.arenaRankAwardTable
	local info = table:getRankInfo(nil, id)

	if self.totalNum then
		info = table:getRankInfo(nil, self.totalNum, id)
	end

	if not notShowSpecial and tonumber(info.rank) ~= nil and tonumber(info.rank) <= 3 then
		self.imgRank:SetActive(true)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. info.rank, nil, )
		self.labelRank:SetActive(false)
	else
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = info.rankText
	end

	NGUITools.DestroyChildren(self.awardGroup.transform)

	for i in pairs(info[colName]) do
		local item = info[colName][i]
		local icon = xyd.getItemIcon({
			isAddUIDragScrollView = true,
			noClickSelected = true,
			hideText = true,
			isShowSelected = false,
			itemID = item.item_id,
			num = item.item_num,
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.awardGroup.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end
end

return ActivityEntranceTestRankWindow
