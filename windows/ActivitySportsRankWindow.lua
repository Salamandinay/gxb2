local BaseWindow = import(".BaseWindow")
local ActivitySportsRankWindow = class("ActivitySportsRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local SportsRankItem = class("SportsRankItem", import("app.components.CopyComponent"))
local ArenaAwardItem = class("ArenaAwardItem", import("app.components.CopyComponent"))
local CountDown = import("app.components.CountDown")
local NAV_TYPE = {
	REWARD = 2,
	RANK = 1
}

function ActivitySportsRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.cur_select_ = 0
	self.rankData = params.rankData
	self.activityData = params.activityData
	self.curMissionType = NAV_TYPE.RANK
	self.timeState = self.activityData:getNowState()
end

function ActivitySportsRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:layout()
	self:onTouch(self.curMissionType)
end

function ActivitySportsRankWindow:getUIComponent()
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
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, SportsRankItem, self)
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
		self["groupIcon" .. i] = self["serverInfo" .. i]:ComponentByName("groupIcon" .. i, typeof(UISprite))
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
	self.winName.text = __("CAMPAIGN_RANK_WINDOW")
end

function ActivitySportsRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST_PLAYER_INFO, function (event)
		xyd.WindowManager.get():openWindow("activity_sports_enemy_window", {
			matchInfo = event.data.match_info,
			title_name = __("ACTIVITY_SPORTS_PLAYER_WINDOW")
		})
	end)
end

function ActivitySportsRankWindow:initNav()
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

function ActivitySportsRankWindow:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:onTouch(i)
end

function ActivitySportsRankWindow:layout()
	self:initRankList()
	self:initAwardLayout()
end

function ActivitySportsRankWindow:initRankList()
	if not self.rankData then
		return
	end

	if self.rankData.rank == -1 then
		self.playerRankGroup:SetActive(false)
	else
		self:initSelfRank()
	end

	self:updateThree()

	self.rankDataList = {}

	if #self.rankData.list >= 4 then
		for i in pairs(self.rankData.list) do
			local data = self.rankData.list[i]
			local rank = i

			if data.rank then
				rank = data.rank
			end

			if data.avatar_id and tonumber(rank) >= 4 then
				local params = {
					avatar_id = data.avatar_id,
					frame_id = data.avatar_frame_id,
					level = data.lev,
					player_name = data.player_name,
					server_id = data.server_id,
					point = data.score,
					rank = rank,
					group = data.group,
					player_id = data.player_id
				}

				if data.avatar_id then
					table.insert(self.rankDataList, params)
				end
			end
		end
	end

	self.wrapContent:setInfos(self.rankDataList, {})
end

function ActivitySportsRankWindow:updateThree()
	for i = 1, 3 do
		if self.rankData.list[i] then
			self["showCon" .. i].gameObject:SetActive(true)

			self["labelPlayerName" .. i].text = tostring(self.rankData.list[i].player_name)
			self["labelDesText" .. i].text = __("SCORE")
			self["serverId" .. i].text = xyd.getServerNumber(self.rankData.list[i].server_id)
			self["labelCurrentNum" .. i].text = tostring(self.rankData.list[i].score)

			if self.rankData.list[i].group then
				xyd.setUISpriteAsync(self["groupIcon" .. i], nil, "img_group" .. self.rankData.list[i].group, function ()
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

			local styles = self.rankData.list[i].dress_style
			styles = styles or xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
				if self.rankData.list[i].player_id ~= xyd.Global.playerID then
					local msg = messages_pb.sports_get_rank_list_player_info_req()
					msg.activity_id = xyd.ActivityID.SPORTS
					msg.rank_player_id = self.rankData.list[i].player_id

					xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST_PLAYER_INFO, msg)
				end
			end)
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivitySportsRankWindow:initSelfRank()
	local selfAwardInfo = xyd.tables.activitySportsRankAward2Table:getRankInfo(self.rankData.rank)

	if self.timeState <= 3 then
		selfAwardInfo = xyd.tables.activitySportsRankAward1Table:getRankInfo(self.rankData.rank, self.rankData.total_num)
	end

	local rankText = selfAwardInfo.rankText

	if self.activityData:getNowState() <= 3 then
		if self.activityData.selfRank and self.activityData.selfRank <= 100 then
			rankText = self.activityData.selfRank
		elseif not self.activityData.selfRank or self.activityData.selfRank <= 0 then
			rankText = " "
		end
	end

	local self_item = {
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		point = self.rankData.score,
		rank = rankText,
		group = self.activityData.detail.arena_info.group,
		player_id = xyd.Global.playerID
	}
	local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
	local item = SportsRankItem.new(tmp, self, self_item)
end

function ActivitySportsRankWindow:initAwardLayout()
	self.summonEffect_ = xyd.Spine.new(self.clock.gameObject)

	self.summonEffect_:setInfo("fx_ui_shizhong", function ()
		self.summonEffect_:setRenderTarget(self.clock:GetComponent(typeof(UITexture)), 1)
		self.summonEffect_:play("texiao1", 0)

		local selfAwardInfo = xyd.tables.activitySportsRankAward2Table:getRankInfo(self.rankData.rank)

		if self.timeState <= 3 then
			selfAwardInfo = xyd.tables.activitySportsRankAward1Table:getRankInfo(self.rankData.rank, self.rankData.total_num)
		end

		if selfAwardInfo.rankText == "0" then
			self.labelRank.text = tostring(__("NOW_RANK")) .. " : "
		else
			self.labelRank.text = tostring(__("NOW_RANK")) .. " : " .. tostring(selfAwardInfo.rankText)
		end

		self.labelNowAward.text = __("NOW_AWARD")
		self.labelTopRank.text = tostring(__("TOP_RANK")) .. ":"
		self.labelDesc.text = __("COUNT_DOWN_BY_MAIL")

		self:updateDDL1()
		self:layoutAward(selfAwardInfo)
	end)
end

function ActivitySportsRankWindow:layoutAward(selfAwardInfo)
	NGUITools.DestroyChildren(self.nowAward.transform)
	NGUITools.DestroyChildren(self.awardContainer.transform)

	for i in pairs(selfAwardInfo.award) do
		local item = selfAwardInfo.award[i]
		local icon = xyd.getItemIcon({
			hideText = true,
			isShowSelected = false,
			itemID = item.item_id,
			num = item.item_num,
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.nowAward.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	local a_t = xyd.tables.activitySportsRankAward2Table

	if self.timeState <= 3 then
		a_t = xyd.tables.activitySportsRankAward1Table
	end

	for i in pairs(a_t:getIds()) do
		local awardItem = NGUITools.AddChild(self.awardContainer.gameObject, self.arena_award_item.gameObject)
		local item = ArenaAwardItem.new(awardItem)

		if self.timeState <= 3 then
			item.totalNum = self.rankData.total_num
		end

		item:setInfo(i, "award", a_t)
	end

	self.arena_award_item:SetActive(false)
	self.awardScroller_scrollerView:ResetPosition()
end

function ActivitySportsRankWindow:updateDDL1()
	local endTime = self.activityData:getEndTime() - xyd.getServerTime()
	local daysArr = xyd.tables.miscTable:split2num("activity_sports_time_interval", "value", "|")
	local isHasTime = true

	if self.activityData:getNowState() <= 2 then
		endTime = self.activityData.start_time + daysArr[1] + daysArr[2] - xyd.getServerTime()
	elseif self.activityData:getNowState() <= 4 then
		endTime = self.activityData.start_time + daysArr[1] + daysArr[2] + daysArr[3] + daysArr[4] - xyd.getServerTime()
	else
		self.clock:SetActive(false)
		self.ddl2Text:SetActive(false)
		self.labelDesc:SetActive(false)

		isHasTime = false
	end

	if endTime > 0 and isHasTime then
		self.setCountDownTime = CountDown.new(self.ddl2Text, {
			duration = endTime,
			callback = handler(self, self.timeOver)
		})
	else
		self.ddl2Text.text = "00:00:00"
	end
end

function ActivitySportsRankWindow:timeOver()
	self.ddl2Text.text = "00:00"
end

function ActivitySportsRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK then
		self.rankNode:SetActive(true)
		self.awardNode:SetActive(false)
	elseif index == NAV_TYPE.REWARD then
		self.rankNode:SetActive(false)
		self.awardNode:SetActive(true)
	end
end

function SportsRankItem:ctor(go, parent, params)
	self.go = go

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
		self.player_id_ = params.player_id

		self:layout()
	end
end

function SportsRankItem:getUIComponent()
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
	self.labelDesText.text = __("SCORE")
	self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")
	self.pIcon = PlayerIcon.new(self.playerIcon)

	self.pIcon:AddUIDragScrollView()
end

function SportsRankItem:update(index, info)
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
		self.player_id_ = params.player_id

		self:layout()
	end
end

function SportsRankItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.rank_)
	end

	if self.rank_ and self.rank_ == "0" then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	end

	if self.group_ then
		if self.group_ == 0 then
			self.groupWords:SetActive(false)
			self.groupImg:SetActive(false)
		else
			self.groupWords:SetActive(true)
			self.groupImg:SetActive(true)

			self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")

			xyd.setUISpriteAsync(self.groupImg, nil, "img_group" .. self.group_, nil, )
		end
	else
		self.groupWords:SetActive(false)
		self.groupImg:SetActive(false)
	end

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_,
		callback = function ()
			if self.player_id_ ~= xyd.Global.playerID then
				local msg = messages_pb.sports_get_rank_list_player_info_req()
				msg.activity_id = xyd.ActivityID.SPORTS
				msg.rank_player_id = self.player_id_

				xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST_PLAYER_INFO, msg)
			end
		end
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
	local isPercentage = 0

	if table == xyd.tables.activitySportsRankAward1Table then
		isPercentage = table:getIsPercentage(id)
	end

	if self.totalNum then
		info = table:getRankInfo(nil, self.totalNum, id)
	end

	if not notShowSpecial and tonumber(info.rank) ~= nil and isPercentage ~= "1" and tonumber(info.rank) >= 1 and tonumber(info.rank) <= 3 then
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
			noClickSelected = true,
			hideText = true,
			isShowSelected = false,
			itemID = item.item_id,
			num = item.item_num,
			scale = Vector3(0.7, 0.7, 1),
			uiRoot = self.awardGroup.gameObject,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		icon:AddUIDragScrollView()
	end
end

return ActivitySportsRankWindow
