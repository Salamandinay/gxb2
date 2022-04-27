local ArcticExpeditionRankWindow = class("ArcticExpeditionRankWindow", import(".BaseWindow"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CommonTabBar = require("app.common.ui.CommonTabBar")
local SportsRankItem = class("SportsRankItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")
local NAV_TYPE = {
	MEDAL = 1,
	SCORE = 2
}
CHOICE_INDEX = NAV_TYPE.MEDAL

function ArcticExpeditionRankWindow:ctor(name, params)
	ArcticExpeditionRankWindow.super.ctor(self, name, params)

	self.awardList = {}
	self.activityData_ = xyd.models.activity:getActivity(xyd.ActivityID.ARCTIC_EXPEDITION)
	self.curMissionType = NAV_TYPE.MEDAL
end

function ArcticExpeditionRankWindow:initWindow()
	self:getUIComponent()
	ArcticExpeditionRankWindow.super.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:onTouch(self.curMissionType)
end

function ArcticExpeditionRankWindow:getUIComponent()
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

function ArcticExpeditionRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ARCTIC_EXPEDITION_GET_RANK_LIST, handler(self, self.onGetRankList))
	self.eventProxy_:addEventListener(xyd.event.ARENA_GET_ENEMY_INFO, handler(self, self.onGetInfo))
end

function ArcticExpeditionRankWindow:onGetInfo(event)
	xyd.WindowManager.get():openWindow("arena_formation_window", {
		not_show_mail = true,
		is_robot = false,
		player_id = event.data.player_id,
		server_id = event.data.server_id
	})
end

function ArcticExpeditionRankWindow:initNav()
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

	self.tab:setTexts(xyd.split(__("ARCTIC_EXPEDITION_TEXT_23"), "|"))
end

function ArcticExpeditionRankWindow:updateNav(i)
	if self.curMissionType == i then
		return
	end

	self.curMissionType = i

	self:onTouch(i)
end

function ArcticExpeditionRankWindow:initRankList()
	local rankData = nil

	if self.choiceIndex == 1 then
		rankData = self.activityData_:getRankList(0)
	else
		rankData = self.activityData_:getRankList()
	end

	self:initSelfRank(rankData)
	self:updateThree(rankData)

	self.rankDataList = {}

	if #rankData.list >= 4 then
		for i in pairs(rankData.list) do
			local data = rankData.list[i]
			local rank = i

			if data.rank then
				rank = data.rank
			end

			if data.avatar_id and tonumber(rank) >= 4 then
				local score = data.score or 0
				local params = {
					avatar_id = data.avatar_id,
					frame_id = data.avatar_frame_id,
					level = data.lev,
					player_name = data.player_name,
					server_id = data.server_id,
					score = math.ceil(score),
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

function ArcticExpeditionRankWindow:updateThree(rankData)
	if not rankData.list then
		rankData.list = {}
	end

	for i = 1, 3 do
		if rankData.list[i] then
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
			styles = styles or xyd.tables.miscTable:split2num("robot_dress_unit", "value", "|")

			self["personEffect" .. i]:setModelInfo({
				ids = styles
			})

			self["showConPlayer" .. i] = rankData.list[i].player_id

			if not self["showCon" .. i .. "addEvent"] then
				self["showCon" .. i .. "addEvent"] = true
				UIEventListener.Get(self["showCon" .. i].gameObject).onClick = handler(self, function ()
					if self["showConPlayer" .. i] ~= xyd.Global.playerID then
						xyd.models.arena:reqEnemyInfo(self["showConPlayer" .. i])
					end
				end)
			end
		else
			self["showCon" .. i].gameObject:SetActive(false)
		end
	end
end

function ArcticExpeditionRankWindow:initSelfRank(rankData)
	local selfRank = nil

	if tonumber(rankData.self_rank) then
		selfRank = tonumber(rankData.self_rank) + 1
	else
		selfRank = 0
	end

	local self_item_params = {
		is_self = true,
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		score = math.ceil(self.activityData_:getScore()) or 0,
		rank = selfRank,
		group = self.activityData_:getSelfGroup(),
		player_id = xyd.Global.playerID
	}

	if not self.self_item then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
		self.self_item = SportsRankItem.new(tmp, self, self_item_params)
	else
		self.self_item:update(1, self_item_params)
	end
end

function ArcticExpeditionRankWindow:onTouch(index)
	if index == NAV_TYPE.MEDAL then
		self.choiceIndex = index

		self:initRankList()
	elseif index == NAV_TYPE.SCORE then
		self.choiceIndex = index

		if not self.activityData_:reqRankList() then
			self:initRankList()
		end
	end
end

function ArcticExpeditionRankWindow:onGetRankList(event)
	self:initRankList()
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
		self.score_ = params.score
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
		self.score_ = params.score
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

		if tonumber(self.rank_) > 0 then
			self.labelRank.text = self.rank_
		end
	end

	if self.group_ then
		if self.group_ == 0 then
			self.groupImg:SetActive(false)
		else
			self.groupImg:SetActive(true)
			xyd.setUISpriteAsync(self.groupImg, nil, "arctic_expedition_cell_group_icon_" .. self.group_, nil, )
		end
	end

	self.labelDesText.text = __("SCORE")

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_,
		callback = function ()
			if self.player_id_ ~= xyd.Global.playerID then
				xyd.models.arena:reqEnemyInfo(self.player_id_)
			end
		end
	})

	self.labelPlayerName.text = self.player_name_
	self.serverId.text = xyd.getServerNumber(self.server_id_)

	if self.score_ then
		self.labelCurrentNum.text = self.score_
	else
		self.labelCurrentNum.text = "0"
	end

	if self.hide_bg_ then
		self.bgImg:SetActive(false)
	end
end

return ArcticExpeditionRankWindow
