local BaseWindow = import(".BaseWindow")
local ActivityEntranceTestFinalRankWindow = class("ActivityEntranceTestFinalRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local EntranceRankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local WindowTop = import("app.components.WindowTop")
local ActivityEntranceTestHelpItems = import("app.components.ActivityEntranceTestHelpItems")
local NAV_TYPE = {
	REWARD = 2,
	RANK = 1
}

function ActivityEntranceTestFinalRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ENTRANCE_TEST)
	self.curMissionType = NAV_TYPE.RANK
	self.activityEntranceTestHelpItems = ActivityEntranceTestHelpItems.new()
end

function ActivityEntranceTestFinalRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:initTopGroup()
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_RANK_LIST, self.openRankWindow, self)
	self.eventProxy_:addEventListener(xyd.event.WARMUP_GET_OTHER_INFO, self.openDetailWindow, self)

	local msg = messages_pb:warmup_get_rank_list_req()
	msg.activity_id = xyd.ActivityID.ENTRANCE_TEST

	xyd.Backend.get():request(xyd.mid.WARMUP_GET_RANK_LIST, msg)
	self:layoutBgInfo()
end

function ActivityEntranceTestFinalRankWindow:openRankWindow(event)
	self.rankData = event.data

	self:initNav()
	self:layout()
	self:onTouch(self.curMissionType)
end

function ActivityEntranceTestFinalRankWindow:openDetailWindow(event)
	xyd.WindowManager.get():openWindow("activity_entrance_test_enemy_window", {
		noBtn = true,
		matchInfo = xyd.decodeProtoBuf(event.data)
	})
end

function ActivityEntranceTestFinalRankWindow:getUIComponent()
	local trans = self.window_.transform
	self.logoNode = trans:NodeByName("logoNode").gameObject
	self.logoNode_widget = trans:ComponentByName("logoNode", typeof(UIWidget))
	self.logo = self.logoNode:ComponentByName("logo", typeof(UISprite))
	self.helpBtn0 = self.logoNode:NodeByName("e:GroupBtn/helpBtn0").gameObject
	local countDownText = self.logoNode:ComponentByName("e:Group/countDownText", typeof(UILabel))
	self.countDownText_label = self.logoNode:ComponentByName("e:Group/countDownText", typeof(UILabel))
	self.endLabel = self.logoNode:ComponentByName("e:Group/endLabel", typeof(UILabel))
	self.countDownText_layout = self.logoNode:ComponentByName("e:Group", typeof(UILayout))
	self.leftNode = trans:NodeByName("leftNode").gameObject
	self.rankWords = self.leftNode:ComponentByName("rankWords", typeof(UILabel))
	self.scoreWords = self.leftNode:ComponentByName("scoreWords", typeof(UILabel))
	self.rankText = self.leftNode:ComponentByName("rankText", typeof(UILabel))
	self.scoreText = self.leftNode:ComponentByName("scoreText", typeof(UILabel))

	self.leftNode:SetActive(false)

	self.countDownText = CountDown.new(countDownText)
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
	self.nowAward_layout = self.upgroup:ComponentByName("nowAward", typeof(UILayout))
	self.awardItem1 = self.upgroup:NodeByName("nowAward/ns1:ItemIcon").gameObject
	self.awardItem2 = self.upgroup:NodeByName("nowAward/ns2:ItemIcon").gameObject
	self.labelDesc = self.awardNode:ComponentByName("labelDesc", typeof(UILabel))
	self.clock = self.awardNode:NodeByName("clock").gameObject
	self.ddl2Text = self.awardNode:ComponentByName("ddl2Text", typeof(UILabel))
	self.awardScroller = self.awardNode:NodeByName("awardScroller").gameObject
	self.awardScroller_scrollerView = self.awardNode:ComponentByName("awardScroller", typeof(UIScrollView))
	self.awardScroller_panel = self.awardNode:ComponentByName("awardScroller", typeof(UIPanel))
	self.awardContainer = self.awardNode:NodeByName("awardScroller/awardContainer").gameObject
	self.awardContainer_grid = self.awardNode:ComponentByName("awardScroller/awardContainer", typeof(UIGrid))
	self.rankNode = groupAction:NodeByName("rankNode").gameObject
	self.activity_sports_rank_item = self.rankNode:NodeByName("activity_sports_rank_item").gameObject
	self.rankListScroller = self.rankNode:NodeByName("rankListScroller").gameObject
	self.rankListScroller_scrollerView = self.rankNode:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListScroller_panel = self.rankNode:ComponentByName("rankListScroller", typeof(UIPanel))
	self.rankListContainer = self.rankNode:NodeByName("rankListScroller/rankListContainer").gameObject
	self.playerRankGroup = self.rankNode:NodeByName("playerRankGroup").gameObject
	local rankListWrapContent = self.rankListScroller:ComponentByName("rankListContainer", typeof(UIWrapContent))
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, EntranceRankItem, self)

	self.wrapContent:setInfos({}, {})

	self.showTitleBg = groupAction:ComponentByName("e:Group/showTitleBg", typeof(UISprite))
	self.showTitleLayoutCon = self.showTitleBg:NodeByName("showTitleLayoutCon").gameObject
	self.showTitleBg_UILayout = self.showTitleLayoutCon:GetComponent(typeof(UILayout))
	self.showNavImgIcon = self.showTitleLayoutCon:ComponentByName("showNavImgIcon", typeof(UISprite))
	self.showNavlabel = self.showTitleLayoutCon:ComponentByName("showNavlabel", typeof(UILabel))
	self.upGroup = self.rankNode:NodeByName("upGroup").gameObject
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
		self["downLevelCon" .. i] = self["showCon" .. i]:NodeByName("downLevelCon" .. i).gameObject
		self["downLevelCon" .. i .. "_UILayout"] = self["showCon" .. i]:ComponentByName("downLevelCon" .. i, typeof(UILayout))
		self["labelDesText" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesText" .. i, typeof(UILabel))
		self["labelDesIcon" .. i] = self["downLevelCon" .. i]:ComponentByName("labelDesIcon" .. i, typeof(UISprite))
		self["labelCurrentNum" .. i] = self["downLevelCon" .. i]:ComponentByName("labelCurrentNum" .. i, typeof(UILabel))
		self["personEffectCon" .. i] = self["showCon" .. i]:NodeByName("personEffectCon" .. i).gameObject
	end

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	UIEventListener.Get(self.helpBtn0.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("img_guide_window", {
			totalPage = 3,
			items = {
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp1,
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp2,
				self.activityEntranceTestHelpItems.ActivityEntranceTestHelp3
			}
		})
	end)
	self.winName.text = __("CAMPAIGN_RANK_WINDOW")

	self.leftNode:Y(443 + 88 * self.scale_num_contrary)
end

function ActivityEntranceTestFinalRankWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.window_, self.name_, 50)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function ActivityEntranceTestFinalRankWindow:initNav()
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

function ActivityEntranceTestFinalRankWindow:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:onTouch(i)
end

function ActivityEntranceTestFinalRankWindow:layoutBgInfo()
	self.showNavlabel.text = __("ACTIVITY_ENTRANCE_TEST_RANK_SHOW_TEXT")

	self.showTitleBg_UILayout:Reposition()
	xyd.setUISpriteAsync(self.logo, nil, "activity_entrance_test_logo_" .. xyd.Global.lang, nil, , true)
	self:setTimeShow()
end

function ActivityEntranceTestFinalRankWindow:updateRankScore()
	self.rankText.text = ""

	if self.rankData then
		local selfAwardInfo = xyd.tables.activityWarmupArenaAwardTable:getRankInfo(self.rankData.rank, self.rankData.num)
		local rankText = selfAwardInfo.rankText

		if self.activityData.detail.score and self.activityData.detail.score ~= 0 then
			self.rankText.text = rankText
		else
			self.rankText.text = "100%"
		end
	end

	self.scoreText.text = self.activityData.detail.score
end

function ActivityEntranceTestFinalRankWindow:setTimeShow()
	if xyd.Global.lang == "ko_kr" then
		self.endLabel.fontSize = 25
	end

	self.countDownText_label:SetActive(false)

	self.endLabel.text = __("ACTIVITY_END_YET")

	self.countDownText_layout:Reposition()
end

function ActivityEntranceTestFinalRankWindow:layout()
	self:initRankList()
end

function ActivityEntranceTestFinalRankWindow:initRankList()
	if not self.rankData then
		return
	end

	if self.rankData.rank == -1 then
		self.playerRankGroup:SetActive(false)
	else
		self:initSelfRank()
	end

	self.rankDataList = {}

	self:waitForFrame(2, function ()
		self:updateThree()

		for i = 4, #self.rankData.list do
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
					player_id = data.player_id,
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
					player_id = data.player_id,
					rank = rank
				}
			end

			if params.avatar_id then
				table.insert(self.rankDataList, params)
			end
		end

		self.wrapContent:setInfos(self.rankDataList, {})
		self.rankListScroller_scrollerView:ResetPosition()
	end)
end

function ActivityEntranceTestFinalRankWindow:updateThree()
	for i = 1, 3 do
		if self.rankData.list[i] then
			self["showCon" .. i].gameObject:SetActive(true)

			if self.rankData.list[i].is_robot and self.rankData.list[i].is_robot == 1 then
				local robotInfo = xyd.tables.activityEntranceTestRobotTable:getAllInfo(self.rankData.list[i].player_id)
				self["labelPlayerName" .. i].text = tostring(robotInfo.name)
				self["upLabelLevel" .. i].text = tostring(robotInfo.lv)
			else
				self["labelPlayerName" .. i].text = tostring(self.rankData.list[i].player_name)
				self["upLabelLevel" .. i].text = tostring(self.rankData.list[i].lev)
			end

			self["labelCurrentNum" .. i].text = tostring(self.rankData.list[i].score)

			if i == 2 or i == 3 then
				while true do
					if self["labelPlayerName" .. i].width > 192 then
						self["labelPlayerName" .. i].fontSize = self["labelPlayerName" .. i].fontSize - 1
					else
						break
					end
				end
			end

			self["nameCon" .. i .. "_UILayout"]:Reposition()
			xyd.setUISpriteAsync(self["labelDesIcon" .. i], nil, "entrance_test_level_" .. xyd.EntranceTestLevelType.R4, function ()
				self["labelDesIcon" .. i].gameObject:SetLocalScale(0.35, 0.36, 0)
				self["downLevelCon" .. i .. "_UILayout"]:Reposition()
			end, nil, true)

			if not self["personEffect" .. i] then
				self["personEffect" .. i] = import("app.components.SenpaiModel").new(self["personEffectCon" .. i])
			end

			local styles = self.rankData.list[i].dress_style
			styles = styles or {}

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
				if self.rankData.list[i].player_id ~= xyd.Global.playerID then
					local msg = messages_pb.warmup_get_other_info_req()
					msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
					msg.other_player_id = self.rankData.list[i].player_id

					xyd.Backend.get():request(xyd.mid.WARMUP_GET_OTHER_INFO, msg)
				end
			end)
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivityEntranceTestFinalRankWindow:initSelfRank()
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

function ActivityEntranceTestFinalRankWindow:initAwardLayout()
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

function ActivityEntranceTestFinalRankWindow:layoutAward(selfAwardInfo)
	self:waitForFrame(2, function ()
		self.allitems = {}

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
			table.insert(self.allitems, item)
		end

		self.arena_award_item:SetActive(false)
		self.awardContainer_grid:Reposition()
		self.nowAward_layout:Reposition()
	end)
end

function ActivityEntranceTestFinalRankWindow:updateDDL1()
	local endTime = self.activityData:getEndTime() - xyd.getServerTime()
	self.setCountDownTime = CountDown.new(self.ddl2Text, {
		duration = endTime,
		callback = handler(self, self.timeOver)
	})
end

function ActivityEntranceTestFinalRankWindow:timeOver()
	self.ddl2Text.text = "00:00"
end

function ActivityEntranceTestFinalRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK then
		self.rankNode:SetActive(true)
		self.awardNode:SetActive(false)
	elseif index == NAV_TYPE.REWARD then
		self.rankNode:SetActive(false)
		self.awardNode:SetActive(true)

		if self.firstResetAwardScroller == nil then
			self.awardScroller_scrollerView:ResetPosition()

			self.firstResetAwardScroller = 1

			self.nowAward_layout:Reposition()

			if self.allitems then
				for i in pairs(self.allitems) do
					self.allitems[i]:layoutReposition()
				end
			end
		end
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

		if not self.point_ then
			self.point_ = 0
		end

		self.rank_ = params.rank
		self.group_ = tonumber(params.group)
		self.player_id_ = tonumber(params.player_id)
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

		if not self.point_ then
			self.point_ = 0
		end

		self.rank_ = params.rank
		self.group_ = tonumber(params.group)
		self.player_id_ = tonumber(params.player_id)
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
		else
			self.labelRank.text = ""
		end
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	end

	if self.isSelf then
		local img_level = self.parent.activityData:getLevel()
		img_level = img_level or 1

		xyd.setUISpriteAsync(self.levelIcon, nil, "entrance_test_level_" .. img_level, function ()
			self.levelIcon.gameObject:SetLocalScale(0.51, 0.56, 0)
		end, nil, true)

		if self.parent.activityData:getLevel() ~= xyd.EntranceTestLevelType.R4 then
			self.imgRankIcon:SetActive(false)
			self.labelRank:SetActive(false)
		end
	else
		xyd.setUISpriteAsync(self.levelIcon, nil, "entrance_test_level_" .. xyd.EntranceTestLevelType.R4, function ()
			self.levelIcon.gameObject:SetLocalScale(0.51, 0.56, 0)
		end, nil, true)
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

	local callback = nil

	if not self.hide_bg_ then
		function callback()
			local msg = messages_pb.warmup_get_other_info_req()
			msg.activity_id = xyd.ActivityID.ENTRANCE_TEST
			msg.other_player_id = self.player_id_

			xyd.Backend.get():request(xyd.mid.WARMUP_GET_OTHER_INFO, msg)
		end
	end

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_,
		callback = callback
	})

	self.labelPlayerName.text = self.player_name_
	self.serverId.text = xyd.getServerNumber(self.server_id_)

	if self.point_ then
		self.labelCurrentNum.text = self.point_

		if self.isSelf then
			local score = self.parent.activityData.detail.score
			score = score or "0"
			self.labelCurrentNum.text = tostring(score)
		end
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
	self.awardGroup_layout = self.go:ComponentByName("awardGroup", typeof(UILayout))
end

function ArenaAwardItem:layoutReposition()
	self.awardGroup_layout:Reposition()
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

	self.awardGroup_layout:Reposition()
end

return ActivityEntranceTestFinalRankWindow
