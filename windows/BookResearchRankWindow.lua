local BaseWindow = import(".BaseWindow")
local BookResearchRankWindow = class("BookResearchRankWindow", BaseWindow)
local CommonTabBar = require("app.common.ui.CommonTabBar")
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local EntranceRankItem = class("EntranceRankItem", import("app.components.CopyComponent"))
local FriendTeamBossAwardItem = class("FriendTeamBossAwardItem", import("app.common.ui.FixedWrapContentItem"))
local NAV_TYPE = {
	AWARD = 2,
	RANK = 1
}

function BookResearchRankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curClickType = NAV_TYPE.RANK

	self:getDataInfo(self.fortId)
end

function BookResearchRankWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)
	self:registerEvent()
	self:initNav()
	self:onTouch(self.curClickType)
end

function BookResearchRankWindow:getUIComponent()
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
	self.rankNone = self.rankNode:NodeByName("rankNone").gameObject
	self.labelNoneTips = self.rankNone:ComponentByName("labelNoneTips", typeof(UILabel))
	self.wrapContent = FixedWrapContent.new(self.rankListScroller_scrollerView, rankListWrapContent, self.activity_sports_rank_item, EntranceRankItem, self)
	self.upgroup = self.rankNode:NodeByName("upgroup").gameObject
	self.upgroup_explainBtn = self.upgroup:NodeByName("explainBtn").gameObject
	self.upgroup_upBgImg = self.upgroup:ComponentByName("upBgImg", typeof(UITexture))
	self.upgroup_upExplainText = self.upgroup:ComponentByName("upExplainText", typeof(UILabel))
	self.upgroup_frameCon = self.upgroup:NodeByName("frameCon").gameObject
	self.playerIcon = PlayerIcon.new(self.upgroup_frameCon)

	self.playerIcon:setScale(0.8770491803278688)

	self.awardNode = groupAction:NodeByName("awardNode").gameObject
	local group = self.awardNode:NodeByName("group").gameObject
	local middleGroup = group:NodeByName("middleGroup").gameObject
	self.leftImage = middleGroup:ComponentByName("leftImage", typeof(UITexture))
	self.rightImage = middleGroup:ComponentByName("rightImage", typeof(UITexture))
	self.labelRank = middleGroup:ComponentByName("labelRank", typeof(UILabel))
	self.labelTopRank = middleGroup:ComponentByName("labelTopRank", typeof(UILabel))
	self.labelNowAward = middleGroup:ComponentByName("labelNowAward", typeof(UILabel))
	self.nowAward = middleGroup:NodeByName("nowAward").gameObject
	self.labelDesc = group:ComponentByName("labelDesc", typeof(UILabel))
	self.navScroller1 = group:ComponentByName("navScroller1", typeof(UIScrollView))
	local wrapContent = self.navScroller2:ComponentByName("awardContainer", typeof(UIWrapContent))
	local iconContainer = self.navScroller2:NodeByName("iconContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.navScroller1, wrapContent, iconContainer, ItemRender, self)
end

function BookResearchRankWindow:getDataInfo(groupId)
	local msg = messages_pb:get_jump_game_rank_list_req()

	xyd.Backend:get():request(xyd.mid.GET_JUMP_GAME_RANK_LIST, msg)
end

function BookResearchRankWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_JUMP_GAME_RANK_LIST, handler(self, function (_, event)
		self.rankData = event.data.list
		self.selfRank = event.data.self_rank

		self:layout()
	end))

	UIEventListener.Get(self.closeBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function BookResearchRankWindow:initNav()
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

	self.tab:setTexts({
		__("BOOK_RESEARCH_TEXT11"),
		__("MAIL_AWAED_TEXT")
	})
end

function BookResearchRankWindow:updateNav(i)
	if self.curClickType == i then
		return
	end

	self.curClickType = i

	self:onTouch(i)
end

function BookResearchRankWindow:layout()
	if self.curClickType == NAV_TYPE.RANK then
		self:initRank()
	elseif self.curClickType == NAV_TYPE.AWARD then
		self:initAward()
	end

	self.winName.text = __("CAMPAIGN_RANK_WINDOW")
	self.labelNoneTips.text = __("ACADEMY_ASSESSMEBT_NO_RANK")
	self.upgroup_upExplainText.text = __("ACADEMY_ASSESSMEBT_RANK_AWARD_TIP")
end

function BookResearchRankWindow:initRank()
	if self.selfRankItem == nil then
		self:refreshSelfRank()
	else
		self:refreshSelfRank(true)
	end

	if self.rankData == nil or #self.rankData == 0 then
		self.rankListScroller:SetActive(false)
		self.rankNone:SetActive(true)

		return
	end

	self.rankListScroller:SetActive(true)
	self.rankNone:SetActive(false)

	local rankDataList = {}

	for i = 1, #self.rankData do
		local data = self.rankData[i].show_detail

		dump(data)

		local rank = i

		if data.rank then
			rank = data.rank
		end

		local params = {
			avatar_id = data.avatar_id,
			frame_id = data.avatar_frame_id,
			level = data.lev,
			player_name = data.player_name,
			server_id = data.server_id,
			player_id = data.player_id,
			point = self.rankData[i].score,
			rank = rank
		}

		if data.avatar_id then
			table.insert(rankDataList, params)
		end
	end

	dump(rankDataList)
	self.wrapContent:setInfos(rankDataList, {})
end

function BookResearchRankWindow:refreshSelfRank(isRefresh)
	local self_item = {
		hide_bg = true,
		avatar_id = xyd.models.selfPlayer:getAvatarID(),
		frame_id = xyd.models.selfPlayer:getAvatarFrameID(),
		level = xyd.models.backpack:getLev(),
		player_name = xyd.models.selfPlayer:getPlayerName(),
		server_id = xyd.models.selfPlayer:getServerID(),
		point = self.selfRank.score,
		rank = self.selfRank.rank,
		player_id = xyd.models.selfPlayer:getPlayerID()
	}

	if not isRefresh then
		local tmp = NGUITools.AddChild(self.playerRankGroup.gameObject, self.activity_sports_rank_item.gameObject)
		local item = EntranceRankItem.new(tmp, self, self_item)
		self.selfRankItem = item
	else
		self.selfRankItem:update(nil, self_item)
	end
end

function BookResearchRankWindow:initAward()
	xyd.setUITextureAsync(self.leftImage, "Textures/friend_team_boss_web/arena_award_bg")
	xyd.setUITextureAsync(self.rightImage, "Textures/friend_team_boss_web/arena_award_bg")
end

function BookResearchRankWindow:onTouch(index)
	if index == NAV_TYPE.RANK then
		self.rankNode:SetActive(true)
		self.awardNode:SetActive(false)
	elseif index == NAV_TYPE.AWARD then
		self.rankNode:SetActive(false)
		self.awardNode:SetActive(true)
	end
end

function EntranceRankItem:ctor(go, parent, params)
	self.go = go

	self:getUIComponent()

	if params then
		self.params = params
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank

		self:update(nil, params)
	end

	self.parent = parent
end

function EntranceRankItem:SetActive(visible)
	self.go:SetActive(visible)
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
	self.labelDesText.text = __("SCORE")
end

function EntranceRankItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	dump(info)

	self.info = info
	local params = info

	self.go:SetActive(true)

	if params then
		self.params = params
		self.hide_bg_ = params.hide_bg
		self.avatar_id_ = tonumber(params.avatar_id)
		self.frame_id_ = tonumber(params.frame_id)
		self.level_ = tonumber(params.level)
		self.player_name_ = params.player_name
		self.server_id_ = tonumber(params.server_id)
		self.point_ = params.point
		self.rank_ = params.rank

		if not self.pIcon then
			self.pIcon = PlayerIcon.new(self.playerIcon)
		end

		self:layout()
	end
end

function EntranceRankItem:layout()
	if tonumber(self.rank_) ~= nil and tonumber(self.rank_) <= 3 and tonumber(self.rank_) > 0 then
		xyd.setUISpriteAsync(self.imgRankIcon, nil, "rank_icon0" .. self.rank_, nil, )
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = tostring(self.rank_)
	end

	if tonumber(self.rank_) == -1 then
		self.labelRank:SetActive(false)
	end

	self.pIcon:setInfo({
		avatarID = self.avatar_id_,
		avatar_frame_id = self.frame_id_,
		lev = self.level_
	})

	self.labelPlayerName.text = self.player_name_
	self.serverId.text = xyd.getServerNumber(self.server_id_)
	self.labelCurrentNum.text = self.point_

	if self.hide_bg_ then
		self.bgImg:SetActive(false)
	end
end

local PngNum = import("app.components.PngNum")

function FriendTeamBossAwardItem:ctor(parentGo)
	FriendTeamBossAwardItem.super.ctor(self, parentGo)
	self:getUIComponent()

	self.numColorMap = {
		"friend_team_boss_brown",
		"friend_team_boss_grey",
		"friend_team_boss_yellow",
		"friend_team_boss_blue"
	}
	self.skinName = "FriendTeamBossAwardItemSkin2"
	self.itemGroupItems = {}
end

function FriendTeamBossAwardItem:getPrefabPath()
	return "Prefabs/Components/friend_team_boss_award_item2"
end

function FriendTeamBossAwardItem:getUIComponent()
	local content = self.go:NodeByName("content").gameObject
	self.numBg = content:ComponentByName("numBg", typeof(UISprite))
	self.numLabelContainer = content:NodeByName("numLabel").gameObject
	self.numLabel = PngNum.new(self.numLabelContainer)
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject

	xyd.setUISpriteAsync(self.numBg, nil, "boss_award_bg_8")
end

function FriendTeamBossAwardItem:update()
	self:setInfo(self.data.id)
end

function FriendTeamBossAwardItem:setInfo(id)
	self.num = id
	local awards = xyd.tables.friendTeamBossAwardTable:getRelegationAward(id)

	for i = 1, #awards do
		if i <= #self.itemGroupItems then
			local item = self.itemGroupItems[i]

			item:setInfo({
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			item:setScale(0.7)
			item:SetActive(true)
		else
			local item = ItemIcon.new(self.itemGroup)

			item:setInfo({
				hideText = true,
				itemID = awards[i][1],
				num = awards[i][2]
			})
			item:setScale(0.7)
			item:SetActive(true)

			self.itemGroupItems[i] = item
		end
	end

	for i = #awards + 1, self.itemGroup.transform.childCount do
		local item = self.itemGroupItems[i]

		item:SetActive(false)
	end

	self:setNum()
end

function FriendTeamBossAwardItem:setNum()
	self.numLabel:setInfo({
		iconName = self.numColorMap[math.floor((self.num - 1) / 10) + 1],
		num = self.num
	})
	xyd.setUISprite(self.numBg, nil, "boss_award_bg_" .. tostring(math.ceil(self.num / 5)))
end

return BookResearchRankWindow
