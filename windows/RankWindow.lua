local BaseWindow = import(".BaseWindow")
local RankWindow = class("RankWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local BaseComponent = import("app.components.BaseComponent")
local PlayerIcon = import("app.components.PlayerIcon")
local RankItem = class("RankItem", BaseComponent)
local RankItemComponent = class("RankItemComponent", BaseComponent)
local CampaignRankItemComponent = class("CampaignRankItemComponent", RankItemComponent)
local TowerRankItemComponent = class("TowerRankItemComponent", RankItemComponent)
local SoulLandRankItemComponent = class("SoulLandRankItemComponent", RankItemComponent)
local DungeonRankItemComponent = class("DungeonRankItemComponent", RankItemComponent)
local FriendRankItemComponent = class("FriendRankItemComponent", RankItemComponent)
local FairyRankItemComponent = class("FairyRankItemComponent", RankItemComponent)
local LimitCallBossRankItemComponent = class("LimitCallBossRankItemComponent", RankItemComponent)
local RANK_ITEM_COMPONENT_LIST = {
	[xyd.MapType.CAMPAIGN] = CampaignRankItemComponent,
	[xyd.MapType.DUNGEON] = DungeonRankItemComponent,
	[xyd.MapType.TOWER] = TowerRankItemComponent,
	[xyd.MapType.FRIEND_RANK] = FriendRankItemComponent,
	[xyd.MapType.ACTIVITY_FAIRT_TALE] = FairyRankItemComponent,
	[xyd.MapType.LIMIT_CALL_BOSS] = LimitCallBossRankItemComponent,
	[xyd.MapType.SOUL_LAND] = SoulLandRankItemComponent
}
local ItemRender = class("ItemRender")

function RankItem:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.rankItem = RANK_ITEM_COMPONENT_LIST[parent.mapType_].new(go, self)

	self.rankItem:setDragScrollView(parent.scrollView)
end

function RankItem:update(index, data)
	if not data then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.rankItem.params = data

	self.rankItem:setInfo(data)
end

function RankItem:getGameObject()
	return self.go
end

function RankWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.BackPackModel = xyd.models.backpack
	self.selfPlayer = xyd.models.selfPlayer
	self.MapModel = xyd.models.map
	self.mapType_ = params.mapType

	if self.mapType_ == xyd.MapType.LIMIT_CALL_BOSS then
		self.MapModel:resetMapRank(xyd.MapType.LIMIT_CALL_BOSS)
	end
end

function RankWindow:playOpenAnimation(callback)
	BaseWindow.playOpenAnimation(self, function ()
		self:layout()
		callback()
	end)
end

function RankWindow:playCloseAnimation(callback)
	BaseWindow.playCloseAnimation(self, callback)
end

function RankWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
end

function RankWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelWinTitle = content:ComponentByName("labelWinTitle", typeof(UILabel))
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.middleGroup = middleGroup
	self.rankListRect = middleGroup:ComponentByName("rankListScroller", typeof(UIRect))
	self.scrollView = middleGroup:ComponentByName("rankListScroller", typeof(UIScrollView))
	self.rankListContainer = self.scrollView:NodeByName("rankListContainer").gameObject
	local wrapContent = self.scrollView:ComponentByName("rankListContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("container").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, RankItem, self)

	self.wrapContent:hideItems()

	self.playerRankGroup = middleGroup:NodeByName("playerRankGroup").gameObject
	self.closeBtn = content:NodeByName("closeBtn").gameObject
end

function RankWindow:layout()
	self.rankInfo_ = self.MapModel:getMapRank(self.mapType_)

	if not self.rankInfo_ or self.mapType_ == xyd.MapType.SOUL_LAND then
		self.MapModel:getRank(self.mapType_)
	else
		self:initRankList()
	end
end

function RankWindow:register()
	RankWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_MAP_RANK, handler(self, self.onMapRank))
	self.eventProxy_:addEventListener(xyd.event.FRIEND_GET_RANK, handler(self, self.onMapRank))
	self.eventProxy_:addEventListener(xyd.event.GET_FAIRY_RANK_LIST, handler(self, self.onMapRank))
	self.eventProxy_:addEventListener(xyd.event.LIMIT_GACHA_BOSS_ACTIVITY_GET_RANK_LIST, handler(self, self.onMapRank))
	self.eventProxy_:addEventListener(xyd.event.GET_SOUL_LAND_MAP_RANK, handler(self, self.onMapRank))
end

function RankWindow:onMapRank(event)
	local data = event.data

	if data.list and #data.list <= 0 then
		return
	end

	self:initRankList()
end

function RankWindow:initRankList()
	self.rankInfo_ = self.MapModel:getMapRank(self.mapType_)

	if not self.rankInfo_ then
		return
	end

	local list = self.rankInfo_.list

	if #list <= 0 then
		return
	end

	self.wrapContent:setInfos(list, {})

	if self:checkHideSelfRank() then
		self.playerRankGroup:SetActive(false)
		self.rankListRect:SetBottomAnchor(self.middleGroup, 0, 2)
	else
		self:initSelfRank()
	end
end

function RankWindow:checkHideSelfRank()
	local flag = false

	if self.mapType_ == xyd.MapType.TOWER or self.mapType_ == xyd.MapType.SOUL_LAND then
		flag = true
	elseif self.mapType_ == xyd.MapType.DUNGEON then
		if self.rankInfo_.score == 0 then
			flag = true
		elseif self.params_.hide_self_rank then
			flag = true
		end
	elseif self.mapType_ == xyd.MapType.FRIEND_RANK then
		if self.rankInfo_.score == 0 then
			flag = true
		end
	elseif self.mapType_ == xyd.MapType.ACTIVITY_FAIRT_TALE then
		local ActivityData = xyd.models.activity:getActivity(xyd.ActivityID.FAIRY_TALE)
		self.rankInfo_.score = ActivityData.detail.score

		if self.rankInfo_.score == 0 then
			flag = true
		end
	elseif self.mapType_ == xyd.MapType.LIMIT_CALL_BOSS then
		if not self.rankInfo_.score then
			flag = true
		elseif self.rankInfo_.rank then
			self.rankInfo_.rank = self.rankInfo_.rank + 1
		end
	end

	return flag
end

function RankWindow:initSelfRank()
	local selfItem = RANK_ITEM_COMPONENT_LIST[self.mapType_].new(self.playerRankGroup:ComponentByName("bgImg3", typeof(UIWidget)).gameObject)
	local selfParams = {
		selfRank = true,
		player_id = xyd.Global.playerID,
		score = self.rankInfo_.score,
		rank = self.rankInfo_.rank,
		player_name = xyd.Global.playerName,
		avatar_id = self.selfPlayer:getAvatarID(),
		lev = self.BackPackModel:getLev(),
		avatar_frame_id = self.selfPlayer:getAvatarFrameID(),
		server_id = self.selfPlayer:getServerID()
	}

	selfItem:setInfo(selfParams)
	selfItem:setBgVisible(false)
end

function RankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.super.ctor(self, parentGo)
end

function RankItemComponent:getPrefabPath()
	return "Prefabs/Components/rank_item"
end

function RankItemComponent:initUI()
	RankItemComponent.super.initUI(self)

	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite))
	local rankGroup = go:NodeByName("rankGroup").gameObject
	self.imgRankIcon = rankGroup:ComponentByName("imgRankIcon", typeof(UISprite))
	self.labelRank = rankGroup:ComponentByName("labelRank", typeof(UILabel))
	self.avatarGroup = go:NodeByName("avatarGroup").gameObject
	self.levelGroup = go:NodeByName("levelGroup").gameObject
	self.labelLevel = self.levelGroup:ComponentByName("labelLevel", typeof(UILabel))
	self.labelPlayerName = go:ComponentByName("labelPlayerName", typeof(UILabel))
	self.groupLevel_ = go:NodeByName("groupLevel_").gameObject
	self.labelDesText = self.groupLevel_:ComponentByName("labelDesText", typeof(UILabel))
	self.labelCurrentNum = self.groupLevel_:ComponentByName("labelCurrentNum", typeof(UILabel))
	self.serverInfo = go:NodeByName("serverInfo").gameObject

	self:setChildren()
end

function RankItemComponent:setChildren()
end

function RankItemComponent:createChildren()
end

function RankItemComponent:setInfo(params)
	if params then
		self.params = params
	end

	if self.params.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.params.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.params.rank

		self.labelRank:SetActive(true)
	end

	self.labelLevel.text = self.params.lev
	self.labelPlayerName.text = self.params.player_name
	self.labelCurrentNum.text = self.params.score

	if not self.playerIcon then
		local scroller_panel = nil

		if self.parent and self.parent.parent and self.parent.parent.scrollView then
			scroller_panel = self.parent.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
		end

		self.playerIcon = PlayerIcon.new(self.avatarGroup, scroller_panel)
	end

	self.playerIcon:setInfo({
		noClick = false,
		avatarID = self.params.avatar_id,
		avatar_frame_id = self.params.avatar_frame_id,
		callback = function ()
			if self.params.player_id ~= xyd.Global.playerID then
				self:clickAvatarFun()
			end
		end
	})
	self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)
	self:createChildren()
end

function RankItemComponent:setBgVisible(status)
	self.bgImg:SetActive(status)
end

function RankItemComponent:clickAvatarFun()
	xyd.WindowManager.get():openWindow("arena_formation_window", {
		is_robot = false,
		player_id = self.params.player_id
	})
end

function CampaignRankItemComponent:ctor(parentGO, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGO, parent)
end

function CampaignRankItemComponent:createChildren()
	RankItemComponent.createChildren(self)
end

function CampaignRankItemComponent:setInfo(params)
	RankItemComponent.setInfo(self, params)

	self.labelDesText.text = __("RANK_TEXT01")
	local stageId = tonumber(self.params.score)
	local mapInfo = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN)
	local maxStage = mapInfo.max_stage or 0

	if params.selfRank and maxStage ~= stageId then
		stageId = maxStage
	end

	if stageId == 0 then
		self.labelCurrentNum.text = ""

		return
	end

	local fortId = xyd.tables.stageTable:getFortID(stageId)
	self.labelCurrentNum.text = fortId .. "-" .. xyd.tables.stageTable:getName(stageId)
end

function TowerRankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGo, parent)
end

function TowerRankItemComponent:setChildren()
	RankItemComponent.setChildren(self)
end

function TowerRankItemComponent:setInfo(params)
	RankItemComponent.setInfo(self, params)

	local widget = self.go:GetComponent(typeof(UIWidget))
	widget.width = 624
	self.labelDesText.text = __("RANK_TEXT02")
end

function SoulLandRankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGo, parent)
end

function SoulLandRankItemComponent:setChildren()
	RankItemComponent.setChildren(self)
end

function SoulLandRankItemComponent:setInfo(params)
	RankItemComponent.setInfo(self, params)

	local widget = self.go:GetComponent(typeof(UIWidget))
	widget.width = 624
	self.labelDesText.text = __("SOUL_LAND_TEXT23")
end

function DungeonRankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGo, parent)
end

function DungeonRankItemComponent:setChildren()
end

function DungeonRankItemComponent:myRankItem(params)
	if params then
		self.params = params
	end

	if self.params.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.params.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.params.rank

		self.labelRank:SetActive(true)
	end

	self.labelLevel.text = self.params.lev
	self.labelPlayerName.text = self.params.player_name
	self.labelCurrentNum.text = self.params.score

	if not self.playerIcon then
		local scroller_panel = nil

		if self.parent and self.parent.parent and self.parent.parent.scrollView then
			scroller_panel = self.parent.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
		end

		self.playerIcon = PlayerIcon.new(self.avatarGroup, scroller_panel)

		self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)
	end

	self.playerIcon:setInfo({
		noClick = false,
		avatarID = self.params.avatar_id,
		avatar_frame_id = self.params.avatar_frame_id,
		callback = function ()
			if self.params.player_id ~= xyd.Global.playerID then
				self:clickAvatarFun()
			end
		end
	})
	self:createChildren()
end

function DungeonRankItemComponent:setInfo(params)
	DungeonRankItemComponent.myRankItem(self, params)

	local type_ = xyd.tables.dungeonTable:getType(params.score)
	self.labelCurrentNum.text = tonumber(self.params.score) - 100 * (tonumber(type_) - 1)
	self.labelDesText.text = __("DUNGEON_HARD_" .. type_)

	if params.time and not self.timeLabel then
		self.labelPlayerName:Y(12)

		local label = xyd.getLabel({
			s = 18,
			c = 2155905279.0,
			uiRoot = self.go,
			p = UIWidget.Pivot.Left
		})

		label:SetLocalPosition(self.labelPlayerName:X(), -15, 0)

		self.timeLabel = label
	end

	if params.time and self.timeLabel then
		self.timeLabel.text = xyd.getDisplayTime(params.time, xyd.TimestampStrType.DATE)
	end
end

function FriendRankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGo, parent)
end

function FriendRankItemComponent:createChildren()
	RankItemComponent.createChildren(self)

	self.width = 614

	self.groupLevel_:GetComponent(typeof(UIWidget)):SetAnchor(nil)

	self.groupLevel_.transform.localPosition = Vector3(220, 14, 0)
end

function FriendRankItemComponent:setInfo(params)
	RankItemComponent.setInfo(self, params)

	self.labelDesText.text = __("RANK_TEXT03")
	self.labelCurrentNum.color = Color.New2(40928511)
end

function FairyRankItemComponent:ctor(parentGo, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGo, parent)
end

function FairyRankItemComponent:createChildren()
	RankItemComponent.createChildren(self)
end

function FairyRankItemComponent:setInfo(params)
	if params then
		self.params = params
	end

	if not self.params.rank then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	elseif self.params.rank < 1 and self.params.rank > 0 then
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = tostring(math.floor(self.params.rank * 100)) .. "%"

		self.labelRank:SetActive(true)
	elseif self.params.rank >= 1 and self.params.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.params.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.params.rank

		self.labelRank:SetActive(true)
	end

	self.labelLevel.text = self.params.lev
	self.labelPlayerName.text = self.params.player_name
	self.labelCurrentNum.text = self.params.score

	if not self.playerIcon then
		local scroller_panel = nil

		if self.parent and self.parent.parent and self.parent.parent.scrollView then
			scroller_panel = self.parent.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
		end

		self.playerIcon = PlayerIcon.new(self.avatarGroup, scroller_panel)
	end

	self.playerIcon:setInfo({
		avatarID = self.params.avatar_id,
		avatar_frame_id = self.params.avatar_frame_id,
		lev = self.params.lev
	})
	self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)

	local bg_sprite_node = self.playerIcon.go:NodeByName("main_group/lev_group/Sprite").gameObject

	bg_sprite_node:SetActive(true)

	self.labelDesText.text = __("SCORE")

	self.levelGroup:SetActive(false)
	self.serverInfo:SetActive(true)

	self.serverInfo:ComponentByName("serverId", typeof(UILabel)).text = xyd.getServerNumber(params.server_id)

	self.labelPlayerName:SetLocalPosition(-125, 20, 0)

	self.labelCurrentNum.color = Color.New2(6933759)

	UIEventListener.Get(self.playerIcon.go).onClick = function ()
		if self.params.player_id ~= xyd.Global.playerID then
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.params.player_id
			})
		end
	end

	self:createChildren()
end

function LimitCallBossRankItemComponent:ctor(parentGO, parent)
	self.parent = parent

	RankItemComponent.ctor(self, parentGO, parent)
end

function LimitCallBossRankItemComponent:createChildren()
	RankItemComponent.createChildren(self)
end

function LimitCallBossRankItemComponent:setInfo(params)
	if params then
		self.params = params
	end

	if not self.params.rank then
		self.imgRankIcon:SetActive(false)
		self.labelRank:SetActive(false)
	elseif self.params.rank < 1 and self.params.rank > 0 then
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = tostring(math.floor(self.params.rank * 100)) .. "%"

		self.labelRank:SetActive(true)
	elseif self.params.rank >= 1 and self.params.rank <= 3 then
		xyd.setUISprite(self.imgRankIcon, nil, "rank_icon0" .. self.params.rank)
		self.imgRankIcon:SetActive(true)
		self.labelRank:SetActive(false)
	else
		self.imgRankIcon:SetActive(false)

		self.labelRank.text = self.params.rank

		self.labelRank:SetActive(true)
	end

	self.labelLevel.text = self.params.lev
	self.labelPlayerName.text = self.params.player_name
	self.labelCurrentNum.text = self.params.score
	self.serverIdLabel = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.serverIdLabel.text = xyd.getServerNumber(params.server_id)

	if not self.playerIcon then
		local scroller_panel = nil

		if self.parent and self.parent.parent and self.parent.parent.scrollView then
			scroller_panel = self.parent.parent.scrollView.gameObject:GetComponent(typeof(UIPanel))
		end

		self.playerIcon = PlayerIcon.new(self.avatarGroup, scroller_panel)
	end

	self.playerIcon:setInfo({
		avatarID = self.params.avatar_id,
		avatar_frame_id = self.params.avatar_frame_id
	})

	UIEventListener.Get(self.playerIcon.go).onClick = function ()
		if self.params.player_id ~= xyd.Global.playerID then
			xyd.WindowManager.get():openWindow("arena_formation_window", {
				is_robot = false,
				player_id = self.params.player_id
			})
		end
	end

	self:setUIComponent()
	self:createChildren()
end

function LimitCallBossRankItemComponent:setUIComponent()
	self.playerIcon.go:SetLocalScale(0.65, 0.65, 1)

	self.labelDesText.text = __("ACTIVITY_ICE_SECRET_BOSS_TEXT05")

	self.labelDesText:SetLocalPosition(-10, 10, 0)
	self.labelCurrentNum:SetLocalPosition(-10, -30, 0)

	self.labelPlayerName.pivot = UIWidget.Pivot.Center

	self.labelPlayerName:SetLocalPosition(55, 24, 0)

	self.labelPlayerName.color = Color.New2(1701812735)

	self.serverInfo:SetActive(true)
	self.serverInfo:SetLocalPosition(55, -17, 0)

	local serverBg_ = self.serverInfo:ComponentByName("bg_", typeof(UISprite))
	local serverIcon_ = self.serverInfo:ComponentByName("icon_", typeof(UISprite))
	serverBg_.width = 120
	serverBg_.height = 35

	serverIcon_:X(-28)

	self.serverIdLabel.pivot = UIWidget.Pivot.Left

	self.serverIdLabel:X(-8)

	self.serverIdLabel.color = Color.New2(1839202047)
	self.labelCurrentNum.color = Color.New2(6933759)
	self.labelCurrentNum.fontSize = 22

	self.levelGroup:X(-75)
	self.avatarGroup:X(-160)
	xyd.setDarkenBtnBehavior(self.go, self, function ()
		xyd.WindowManager.get():openWindow("limit_call_boss_formation_window", {
			player_id = self.params.player_id,
			player_name = self.params.player_name,
			avatar_frame = self.params.avatar_frame_id,
			avatar_id = self.params.avatar_id,
			server_id = self.params.server_id
		})
	end)
end

return RankWindow
