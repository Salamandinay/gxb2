local ActivitySportsRank2Window = class("ActivitySportsRank2Window", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")
local SportsRankItem = class("SportsRankItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")
local NAV_TYPE = {
	MEDAL = 1,
	SCORE = 2
}
CHOICE_INDEX = NAV_TYPE.MEDAL

function ActivitySportsRank2Window:ctor(name, params)
	ActivitySportsRank2Window.super.ctor(self, name, params)

	self.awardList = {}
	self.rankMedalData = xyd.decodeProtoBuf(params.eventData)
	self.rankScoreData = nil
	self.rankData = {
		self.rankMedalData,
		self.rankScoreData
	}
	self.activityData = params.activityData
	self.timeState = self.activityData:getNowState()
	self.curMissionType = NAV_TYPE.MEDAL
end

function ActivitySportsRank2Window:initWindow()
	self:getUIComponent()
	ActivitySportsRank2Window.super.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:onTouch(self.curMissionType)
end

function ActivitySportsRank2Window:getUIComponent()
	local trans = self.window_.transform
	local groupAction = trans:NodeByName("groupAction").gameObject
	self.winName = groupAction:ComponentByName("e:Group/labelWinTitle", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("e:Group/closeBtn").gameObject
	self.nav = groupAction:NodeByName("e:Group/nav").gameObject
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

function ActivitySportsRank2Window:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST_PLAYER_INFO, function (event)
		xyd.WindowManager.get():openWindow("activity_sports_enemy_window", {
			matchInfo = event.data.match_info,
			title_name = __("ACTIVITY_SPORTS_PLAYER_WINDOW")
		})
	end)
	self.eventProxy_:addEventListener(xyd.event.SPORTS_GET_RANK_LIST, handler(self, self.onGetRankList))
end

function ActivitySportsRank2Window:initNav()
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

	self.tab:setTexts(xyd.split(__("ACTIVITY_SPORTS_PLAYERRANK_TEXT1"), "|"))
end

function ActivitySportsRank2Window:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:onTouch(i)
end

function ActivitySportsRank2Window:initRankList()
	if not self.rankData[self.choiceIndex] then
		return
	end

	if self.rankData[self.choiceIndex].rank == -1 then
		self.playerRankGroup:SetActive(false)
	else
		self:initSelfRank()
	end

	self:updateThree()

	self.rankDataList = {}

	if #self.rankData[self.choiceIndex].list >= 4 then
		for i in pairs(self.rankData[self.choiceIndex].list) do
			local data = self.rankData[self.choiceIndex].list[i]
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
	self.rankListScroller_scrollerView:ResetPosition()
end

function ActivitySportsRank2Window:updateThree()
	if not self.rankData[self.choiceIndex].list then
		self.rankData[self.choiceIndex].list = {}
	end

	for i = 1, 3 do
		if self.rankData[self.choiceIndex].list[i] then
			self["showCon" .. i].gameObject:SetActive(true)

			self["labelPlayerName" .. i].text = tostring(self.rankData[self.choiceIndex].list[i].player_name)

			if self.choiceIndex == NAV_TYPE.MEDAL then
				self["labelDesText" .. i].text = __("ACTIVITY_SPORTS_PLAYERRANK_TEXT2")
			else
				self["labelDesText" .. i].text = __("SCORE")
			end

			self["serverId" .. i].text = xyd.getServerNumber(self.rankData[self.choiceIndex].list[i].server_id)
			self["labelCurrentNum" .. i].text = tostring(self.rankData[self.choiceIndex].list[i].score)

			if self.rankData[self.choiceIndex].list[i].group then
				xyd.setUISpriteAsync(self["groupIcon" .. i], nil, "img_group" .. self.rankData[self.choiceIndex].list[i].group, function ()
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

			local styles = self.rankData[self.choiceIndex].list[i].dress_style
			styles = styles or xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			if not self["showCon" .. i .. "addEvent"] then
				self["showCon" .. i .. "addEvent"] = true
				UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
					if self.rankData[self.choiceIndex].list[i].player_id ~= xyd.Global.playerID then
						local msg = messages_pb.sports_get_rank_list_player_info_req()
						msg.activity_id = xyd.ActivityID.SPORTS
						msg.rank_player_id = self.rankData[self.choiceIndex].list[i].player_id

						xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST_PLAYER_INFO, msg)
					end
				end)
			end
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ActivitySportsRank2Window:initSelfRank()
	local selfAwardInfo = xyd.tables.activitySportsRankAward2Table:getRankInfo(self.rankData[self.choiceIndex].rank)

	if self.timeState <= 3 then
		selfAwardInfo = xyd.tables.activitySportsRankAward1Table:getRankInfo(self.rankData[self.choiceIndex].rank, self.rankData[self.choiceIndex].total_num)
	end

	local rankText = selfAwardInfo.rankText

	if not rankText or rankText and rankText == "0" then
		rankText = "--"
	end

	local self_item_params = {
		is_self = true,
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		point = self.rankData[self.choiceIndex].score or 0,
		rank = rankText,
		group = self.activityData.detail.arena_info.group,
		player_id = xyd.Global.playerID
	}

	if not self.self_item then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
		self.self_item = SportsRankItem.new(tmp, self, self_item_params)
	else
		self.self_item:update(1, self_item_params)
	end
end

function ActivitySportsRank2Window:onTouch(index)
	print("测试asdasd:", index)

	if index == NAV_TYPE.MEDAL then
		self.choiceIndex = index
		CHOICE_INDEX = index

		self:initRankList()
	elseif index == NAV_TYPE.SCORE then
		if not self.rankScoreData then
			local msg = messages_pb.sports_get_rank_list_req()
			msg.activity_id = xyd.ActivityID.SPORTS
			msg.rank_type = xyd.ActivitySportsRankType["GROUP_FIGHT_POINT_" .. self.activityData.detail.arena_info.group]

			xyd.Backend.get():request(xyd.mid.SPORTS_GET_RANK_LIST, msg)
		else
			self.choiceIndex = index
			CHOICE_INDEX = index

			self:initRankList()
		end
	end
end

function ActivitySportsRank2Window:onGetRankList(event)
	if event.data.rank_type == xyd.ActivitySportsRankType["GROUP_FIGHT_POINT_" .. self.activityData.detail.arena_info.group] then
		self.rankScoreData = event.data
		self.choiceIndex = NAV_TYPE.SCORE
		CHOICE_INDEX = NAV_TYPE.SCORE
		self.rankData[NAV_TYPE.SCORE] = xyd.decodeProtoBuf(self.rankScoreData)

		self:initRankList()
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
		self.is_self_ = params.is_self

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
		self.is_self_ = params.is_self

		self:layout()
	end
end

function SportsRankItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and tonumber(self.rank_) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	elseif tonumber(self.rank_) and tonumber(self.rank_) > 0 then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.rank_)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = " "

		if type(self.rank_) == "string" and self.rank_ ~= "" then
			self.imgRankIcon:SetActive(false)
			self.labelRank:SetActive(true)

			self.labelRank.text = self.rank_
		end
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
	end

	if CHOICE_INDEX == NAV_TYPE.MEDAL then
		self.labelDesText.text = __("ACTIVITY_SPORTS_PLAYERRANK_TEXT2")
	else
		self.labelDesText.text = __("SCORE")

		if self.is_self_ then
			self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.SPORTS)

			if self.activityData and self.activityData:getNowState() >= 4 then
				self.imgRankIcon:SetActive(false)
				self.labelRank:SetActive(false)
			end
		end
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

return ActivitySportsRank2Window
