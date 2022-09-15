local BaseWindow = import(".BaseWindow")
local Arena3v3Window = class("Arena3v3Window", BaseWindow)
local Arena3v3 = xyd.models.arena3v3
local SelfPlayer = xyd.models.selfPlayer
local Backpack = xyd.models.backpack
local Slot = xyd.models.slot
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local ResItem = import("app.components.ResItem")
local WindowTop = import("app.components.WindowTop")
local BaseComponent = import("app.components.BaseComponent")
local ItemRender = class("ItemRender")
local ArenaWindowItem = class("ArenaWindowItem", BaseComponent)

function ArenaWindowItem:ctor(parentGo, parentItem)
	self.parentItem = parentItem

	ArenaWindowItem.super.ctor(self, parentGo)
	self:getUIComponent()
end

function ArenaWindowItem:getPrefabPath()
	return "Prefabs/Components/arena_window_item"
end

function ArenaWindowItem:getUIComponent()
	local go = self.go
	self.bg = go:ComponentByName("bg", typeof(UISprite))
	self.imgRank = go:ComponentByName("imgRank", typeof(UISprite))
	self.labelRank = go:ComponentByName("labelRank", typeof(UILabel))
	local pIconContainer = go:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer, self.parentItem.parent.scrollView_uipanel)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.power = go:ComponentByName("power", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))

	self:createChildren()
end

function ArenaWindowItem:setCurrentState(state)
	if state == "arena" then
		self.serverInfo:SetActive(false)
	else
		self.serverInfo:SetActive(true)
	end
end

function ArenaWindowItem:setInfo(params)
	if params.is_robot == 1 then
		params.avatar_id = xyd.tables.arenaRobotTable:getAvatar(params.player_id)
		params.lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		params.player_name = xyd.tables.arenaRobotTable:getName(params.player_id)
		params.power = xyd.tables.arenaRobotTable:getPower(params.player_id)
	end

	if self.params and params.player_id and self.params.player_id and params.player_id == self.params.player_id and params.lev and self.params.lev and params.lev == self.params.lev and params.power and self.params.power and params.power == self.params.power and params.avatar_id and self.params.avatar_id and params.avatar_id == self.params.avatar_id and params.player_name and self.params.player_name and params.player_name == self.params.player_name and params.rank and self.params.rank and params.rank == self.params.rank and params.score and self.params.score and params.score == self.params.score then
		return
	end

	self.params = params

	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id,
		callback = function ()
			if self.params.player_id ~= xyd.Global.playerID then
				if self.currentState == "arena" then
					xyd.WindowManager.get():openWindow("arena_formation_window", {
						player_id = self.params.player_id,
						is_robot = self.params.is_robot
					})
				elseif self.currentState == "arena3v3" and xyd.models.arena3v3:checkOpen() then
					xyd.WindowManager.get():openWindow("arena_3v3_formation_window", {
						player_id = self.params.player_id
					})
				end
			end
		end
	})

	self.playerName.text = params.player_name

	if params.rank > 3 then
		self.imgRank:SetActive(false)
		self.labelRank:SetActive(true)

		self.labelRank.text = params.rank

		xyd.setUISpriteAsync(self.bg, nil, "9gongge17")
	else
		self.imgRank:SetActive(true)
		self.labelRank:SetActive(false)
		xyd.setUISpriteAsync(self.imgRank, nil, "rank_icon0" .. tostring(params.rank))

		local bg = {
			"9gongge30_png",
			"9gongge31_png",
			"9gongge32_png"
		}

		xyd.setUISpriteAsync(self.bg, nil, bg[params.rank])
	end

	self.power.text = params.power
	self.labelPoint.text = __("SCORE")
	self.point.text = params.score
	self.serverId.text = xyd.getServerNumber(params.server_id)

	if params.state then
		self.currentState = params.state
	else
		self.currentState = "arena"
	end

	self:setCurrentState(self.currentState)
end

function ArenaWindowItem:createChildren()
end

function ArenaWindowItem:dataChanged()
	self:setInfo(self.data)
end

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaWindowItem.new(go, self)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.item.data = info

	self.go:SetActive(true)
	self.item:dataChanged()
end

function ItemRender:getGameObject()
	return self.go
end

function Arena3v3Window:ctor(name, params)
	Arena3v3Window.super.ctor(self, name, params)

	self.model_ = Arena3v3
	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getTexturePath("arena3v3_title_bg"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_operator_bg"))

	if xyd.models.arena3v3:getIsOld() ~= nil then
		table.insert(needLoadRes, xyd.getTexturePath("arena_3v3_new_scene"))
		table.insert(needLoadRes, xyd.getTexturePath("arena3v3_title_new_" .. tostring(xyd.Global.lang)))
	else
		table.insert(needLoadRes, xyd.getTexturePath("arena_3v3_scene"))
		table.insert(needLoadRes, xyd.getTexturePath("arena3v3_title_" .. tostring(xyd.Global.lang)))
	end

	self:setResourcePaths(needLoadRes)
end

function Arena3v3Window:getUIComponent()
	local trans = self.window_.transform
	self.bg_ = trans:ComponentByName("bg_", typeof(UITexture))
	self.mask_bg = trans:ComponentByName("mask_bg", typeof(UIWidget))
	self.main = trans:NodeByName("main").gameObject
	self.anim = trans:GetComponent(typeof(UnityEngine.Animation))
	self.top = self.main:NodeByName("top").gameObject
	self.btnShop = self.top:NodeByName("btnShop").gameObject
	self.btnHelp = self.top:NodeByName("btnHelp").gameObject
	self.btnNewRank = self.top:NodeByName("btnNewRank").gameObject
	self.btnNewRankRedPoint = self.btnNewRank:NodeByName("btnNewRankRedPoint").gameObject
	self.imgBg = self.top:ComponentByName("imgBg", typeof(UITexture))
	self.imgBg0 = self.top:ComponentByName("imgBg0", typeof(UITexture))
	self.imgTitle = self.top:ComponentByName("imgTitle", typeof(UITexture))
	self.timeGroup = self.top:NodeByName("timeGroup").gameObject
	self.timeGroupUILayout = self.top:ComponentByName("timeGroup", typeof(UILayout))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelDDL = self.timeGroup:ComponentByName("labelDDL", typeof(UILabel))
	self.groupRank = self.main:NodeByName("groupRank").gameObject
	self.scrollView = self.groupRank:ComponentByName("scrollview", typeof(UIScrollView))
	self.scrollView_uipanel = self.groupRank:ComponentByName("scrollview", typeof(UIPanel))
	local wrapContent = self.scrollView:ComponentByName("rankContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("renderContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)

	self.wrapContent:hideItems()

	self.groupDetail = self.main:NodeByName("groupDetail").gameObject
	self.imgDetailBg01 = self.groupDetail:ComponentByName("imgDetailBg01", typeof(UITexture))
	self.imgDetailBg02 = self.groupDetail:ComponentByName("imgDetailBg02", typeof(UITexture))
	local pIconContainer = self.groupDetail:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.labelPower = self.groupDetail:ComponentByName("labelPower", typeof(UILabel))
	self.labelRank = self.groupDetail:ComponentByName("labelRank", typeof(UILabel))
	self.rank = self.groupDetail:ComponentByName("rank", typeof(UILabel))
	self.labelScore = self.groupDetail:ComponentByName("labelScore", typeof(UILabel))
	self.score = self.groupDetail:ComponentByName("score", typeof(UILabel))
	local resItemContainer = self.groupDetail:NodeByName("res3").gameObject
	self.res3 = ResItem.new(resItemContainer)
	self.btnFight = self.groupDetail:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("btnFightLabel", typeof(UILabel))
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("btnAwardLabel", typeof(UILabel))
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnRecordLabel = self.btnRecord:ComponentByName("btnRecordLabel", typeof(UILabel))
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFormationLabel = self.btnFormation:ComponentByName("btnFormationLabel", typeof(UILabel))
	self.seasonOpen = self.groupDetail:NodeByName("seasonOpen").gameObject
	self.imgSeasonOpen01 = self.seasonOpen:ComponentByName("imgSeasonOpen01", typeof(UITexture))
	self.imgSeasonOpen02 = self.seasonOpen:ComponentByName("imgSeasonOpen02", typeof(UITexture))
	self.seasonLabel = self.seasonOpen:ComponentByName("seasonLabel", typeof(UILabel))
	self.seasonCountDown = self.seasonOpen:ComponentByName("seasonCountDown", typeof(UILabel))

	if xyd.Global.lang == "fr_fr" then
		self.btnRecord:X(250)
		self.btnAward:X(250)
		self.btnFormation:X(250)
	end
end

function Arena3v3Window:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self.model_:reqRankList()
	self:onGetArenaInfo()

	local timer = self:getTimer(function ()
		self:updateDDL()
	end, 1, -1)

	timer:Start()
	self:registerEvent()
end

function Arena3v3Window:initLayout()
	if xyd.models.arena3v3:getIsOld() ~= nil then
		self.imgBg:SetActive(false)
		self.imgBg0:SetActive(false)
		xyd.setUITextureByNameAsync(self.imgBg, "arena_title_bg_new")
		xyd.setUITextureByNameAsync(self.imgBg0, "arena_title_bg_new")
		xyd.setUITextureByNameAsync(self.imgTitle, "arena3v3_title_new_" .. tostring(xyd.Global.lang), true)
		xyd.setUITextureByNameAsync(self.bg_, "arena_3v3_new_scene")
	else
		self.imgBg:SetActive(true)
		self.imgBg0:SetActive(true)
		xyd.setUITextureByNameAsync(self.imgBg, "arena3v3_title_bg")
		xyd.setUITextureByNameAsync(self.imgBg0, "arena3v3_title_bg")
		xyd.setUITextureByNameAsync(self.imgTitle, "arena3v3_title_" .. tostring(xyd.Global.lang), true)
		xyd.setUITextureByNameAsync(self.bg_, "arena_3v3_scene")
	end

	xyd.setUITextureByNameAsync(self.imgDetailBg01, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.imgDetailBg02, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.imgSeasonOpen01, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.imgSeasonOpen02, "arena_operator_bg")
	self.btnShop:SetActive(true)

	self.seasonLabel.text = __("OPEN_AFTER")

	self.res3:setInfo({
		tableId = xyd.ItemID.ARENA_TICKET
	})
	table.insert(self.resItemList, self.res3)

	local callback = nil

	function callback()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 50, true, callback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	if xyd.models.arena3v3:getIsOld() ~= nil then
		local startTime = self.model_:getStartTime() - xyd.getServerTime()

		if startTime < 0 then
			self.btnNewRank.gameObject:SetActive(true)
		end

		local newArenaRankRed = xyd.db.misc:getValue("new_arena_3v3_rank_red")

		if not newArenaRankRed then
			self.btnNewRankRedPoint.gameObject:SetActive(true)
		elseif tonumber(newArenaRankRed) < xyd.models.arena3v3:getDDL() then
			self.btnNewRankRedPoint.gameObject:SetActive(true)
		else
			self.btnNewRankRedPoint.gameObject:SetActive(false)
		end
	end

	self.windowTop:setItem(items)
	self.windowTop:setCanRefresh(false)

	self.labelTime.text = __("REST_TIME")
	local avatar = SelfPlayer:getAvatarID()
	local lev = Backpack:getLev()

	self.pIcon:setInfo({
		avatarID = avatar,
		lev = lev,
		avatar_frame_id = SelfPlayer:getAvatarFrameID()
	})
	self.pIcon:setScale(0.8)

	self.selfPower = Slot:cal3v3Power()
	self.labelPower.text = tostring(self.selfPower)
	self.labelRank.text = __("RANK")
	self.labelScore.text = __("SCORE")

	if xyd.Global.lang == "fr_fr" then
		self.labelScore.fontSize = 14
	end

	if xyd.Global.lang == "de_de" then
		self.imgTitle:SetLocalPosition(22, 0, 0)

		self.btnAwardLabel.fontSize = 18
		self.btnRecordLabel.fontSize = 18
		self.btnFormationLabel.fontSize = 18

		self.seasonLabel:X(-30)
		self.seasonCountDown:X(-148)
	elseif xyd.Global.lang == "fr_fr" then
		self.seasonLabel:X(-165)
		self.seasonCountDown:X(42)
		self.imgTitle:X(0)
	elseif xyd.Global.lang == "ko_kr" then
		self.imgTitle:X(0)
	end

	if xyd.models.arena3v3:getIsOld() ~= nil then
		self.imgTitle:Y(-4)
		self.imgTitle:X(0)
		self.timeGroup:Y(-49)
	end

	self.btnFightLabel.text = __("FIGHT2")
	self.btnAwardLabel.text = __("AWARD2")
	self.btnRecordLabel.text = __("RECORD")
	self.btnFormationLabel.text = __("DEFFORMATION")
end

function Arena3v3Window:willClose()
	Arena3v3Window.super.willClose(self)

	if self.params_.lastWindow then
		xyd.WindowManager.get():openWindow(self.params_.lastWindow, self.params_.lastWindowParams)
	end
end

function Arena3v3Window:onGetArenaInfo()
	local partners = self.model_:getDefFormation()
	local num = 0

	for key, value in pairs(partners) do
		if value then
			num = num + 1
		end
	end

	if num <= 0 and self:checkOpen() then
		xyd.WindowManager:get():openWindow("arena_3v3_battle_formation_window", {
			battleType = xyd.BattleType.ARENA_3v3_DEF,
			mapType = xyd.MapType.ARENA_3v3,
			callback = function ()
				xyd.WindowManager.get():closeWindow("arena_3v3_window")
			end
		})
	end

	self:updateDDL()
	self:updateRank()
	self:updateScore()
	self:setMask(false)
end

function Arena3v3Window:updateRank()
	self.rank.text = tostring(self.model_:getRank())
end

function Arena3v3Window:updateScore()
	self.score.text = tostring(self.model_:getScore())
end

function Arena3v3Window:checkOpen()
	local startTime = self.model_:getStartTime() - xyd.getServerTime()

	return startTime < 0
end

function Arena3v3Window:updateDDL()
	local ddl = self.model_:getDDL() - xyd.getServerTime()

	if ddl <= 0 then
		self.labelDDL.text = "00:00:00"
	else
		self.labelDDL.text = xyd.secondsToString(ddl)
	end

	local startTime = self.model_:getStartTime() - xyd.getServerTime()

	if startTime > 0 then
		self.seasonOpen:SetActive(true)

		self.seasonCountDown.text = xyd.secondsToString(startTime)

		self.labelDDL:SetActive(false)
		self.labelTime:SetActive(false)
		self.btnRecord:SetActive(false)

		if startTime > xyd.TimePeriod.DAY_TIME * (xyd.ARENA_WAIT_TIME.ARENA_3v3 - 1) then
			self.btnRecord:SetActive(true)
		end
	else
		self.seasonOpen:SetActive(false)
		self.labelDDL:SetActive(true)
		self.labelTime:SetActive(true)
		self.btnRecord:SetActive(true)
	end

	self.timeGroupUILayout:Reposition()
end

function Arena3v3Window:onGetRankList()
	local ranklist = self.model_:getRankList()
	local infos = {}

	for i = 1, #ranklist do
		infos[i] = {
			score = ranklist[i].score,
			player_name = ranklist[i].player_name,
			avatar_id = ranklist[i].avatar_id,
			avatar_frame_id = ranklist[i].avatar_frame_id,
			lev = ranklist[i].lev,
			player_id = ranklist[i].player_id,
			power = ranklist[i].power,
			server_id = ranklist[i].server_id,
			rank = i,
			state = "arena3v3"
		}
	end

	self.wrapContent:setInfos(infos, {})
end

function Arena3v3Window:setMask(flag)
	self.mask_bg:SetActive(flag)
end

function Arena3v3Window:refreshWinTop()
	self.windowTop:setCanRefresh(true)
	self.windowTop:refresResItems()
	self.windowTop:setCanRefresh(false)
end

function Arena3v3Window:registerEvent()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.refreshWinTop))
	self.eventProxy_:addEventListener(xyd.event.MIDAS_BUY, handler(self, self.refreshWinTop))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.refreshWinTop))

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ARENA_3V3_HELP"
		})
	end

	UIEventListener.Get(self.btnShop).onClick = function ()
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_ARENA
		})
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_choose_player_window", {
			power = self.selfPower
		})
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_award_window")
	end

	UIEventListener.Get(self.btnRecord).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_record_window")
	end

	UIEventListener.Get(self.btnFormation).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
			battleType = xyd.BattleType.ARENA_3v3_DEF,
			formation = self.model_:getDefFormation(),
			mapType = xyd.MapType.ARENA_3v3
		})
	end

	UIEventListener.Get(self.btnNewRank).onClick = function ()
		xyd.models.arena3v3:getArena3v3NewRankList()

		if self.btnNewRankRedPoint.gameObject.activeSelf then
			xyd.db.misc:setValue({
				key = "new_arena_3v3_rank_red",
				value = xyd.models.arena3v3:getDDL()
			})
			self.btnNewRankRedPoint.gameObject:SetActive(false)
		end
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_3v3_INFO, handler(self, self.onGetArenaInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_RANK_3V3_LIST, handler(self, self.onGetRankList))
	self.eventProxy_:addEventListener(xyd.event.SET_PARTNERS_3v3, function ()
		self:updateRank()
		self:updateScore()
	end)
end

function Arena3v3Window:getWindowTop()
	return self.windowTop
end

return Arena3v3Window
