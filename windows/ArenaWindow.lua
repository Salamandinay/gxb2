local BaseWindow = import(".BaseWindow")
local ArenaWindow = class("ArenaWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local ResItem = import("app.components.ResItem")
local WindowTop = import("app.components.WindowTop")
local BaseComponent = import("app.components.BaseComponent")
local ArenaWindowItem = class("ArenaWindowItem", BaseComponent)
local CountDown = import("app.components.CountDown")
local cjson = require("cjson")
local ItemRender = class("ItemRender")

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

function ArenaWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaWindowSkin"
	self.model_ = xyd.models.arena
	self.currentState = xyd.Global.lang
	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getTexturePath("arena_title_bg"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_operator_bg"))
	table.insert(needLoadRes, xyd.getTexturePath("arena_scene"))
	table.insert(needLoadRes, xyd.getSpritePath("arena_title_" .. tostring(xyd.Global.lang)))
	self:setResourcePaths(needLoadRes)
end

function ArenaWindow:willOpen(params)
	BaseWindow.willOpen(self, params)
end

function ArenaWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initLayout()
	self:onGetArenaInfo()
	self:onGetRankList()
	self:register()
end

function ArenaWindow:getUIComponent()
	local trans = self.window_.transform
	self.anim = trans:GetComponent(typeof(UnityEngine.Animation))
	self.bg_ = trans:ComponentByName("bg_", typeof(UITexture))
	self.mask_bg = trans:NodeByName("mask_bg").gameObject
	local content = trans:NodeByName("content").gameObject
	self.btnHelp = content:NodeByName("btnHelp").gameObject
	self.btnShop = content:NodeByName("btnShop").gameObject
	self.btnNewRank = content:NodeByName("btnNewRank").gameObject
	self.btnNewRankRedPoint = self.btnNewRank:NodeByName("btnNewRankRedPoint").gameObject
	self.shopRed = self.btnShop:NodeByName("shopRed").gameObject
	local titleGroup = content:NodeByName("titleGroup").gameObject
	self.imgBg = titleGroup:ComponentByName("imgBg", typeof(UITexture))
	self.imgBg0 = titleGroup:ComponentByName("imgBg0", typeof(UITexture))
	self.imgTitle = titleGroup:ComponentByName("imgTitle", typeof(UISprite))
	local labelGroup = titleGroup:NodeByName("labelGroup").gameObject
	self.labelGroupUITable = titleGroup:ComponentByName("labelGroup", typeof(UITable))
	self.labelTime = labelGroup:ComponentByName("labelTime", typeof(UILabel))
	self.labelDDL = labelGroup:ComponentByName("labelDDL", typeof(UILabel))
	self.groupRank = content:NodeByName("groupRank").gameObject
	self.scrollView = self.groupRank:ComponentByName("scroller", typeof(UIScrollView))
	self.scrollView_uipanel = self.groupRank:ComponentByName("scroller", typeof(UIPanel))
	local wrapContent = self.scrollView:ComponentByName("rankContainer", typeof(UIWrapContent))
	local iconContainer = self.scrollView:NodeByName("renderContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, iconContainer, ItemRender, self)

	self.wrapContent:hideItems()

	self.groupDetail = content:NodeByName("groupDetail").gameObject
	self.detailBg1 = self.groupDetail:ComponentByName("detailBg1", typeof(UITexture))
	self.detailBg2 = self.groupDetail:ComponentByName("detailBg2", typeof(UITexture))
	local pIconContainer = self.groupDetail:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.labelPower = self.groupDetail:ComponentByName("labelPower", typeof(UILabel))
	local labelRankGroup = self.groupDetail:NodeByName("labelRankGroup").gameObject
	self.labelRank = labelRankGroup:ComponentByName("firstGroup/labelRank", typeof(UILabel))
	self.rank = labelRankGroup:ComponentByName("rank", typeof(UILabel))
	local labelScoreGroup = self.groupDetail:NodeByName("labelScoreGroup").gameObject
	self.labelScore = labelScoreGroup:ComponentByName("firstGroup/labelScore", typeof(UILabel))
	self.score = labelScoreGroup:ComponentByName("score", typeof(UILabel))
	self.res3Container = self.groupDetail:NodeByName("res3").gameObject
	self.btnFight = self.groupDetail:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("button_label", typeof(UILabel))
	self.btnAward = self.groupDetail:NodeByName("btnAward").gameObject
	self.btnAwardLabel = self.btnAward:ComponentByName("button_label", typeof(UILabel))
	self.btnRecord = self.groupDetail:NodeByName("btnRecord").gameObject
	self.btnRecordLabel = self.btnRecord:ComponentByName("button_label", typeof(UILabel))
	self.btnFormation = self.groupDetail:NodeByName("btnFormation").gameObject
	self.btnFormationLabel = self.btnFormation:ComponentByName("button_label", typeof(UILabel))
	self.seasonOpen = self.groupDetail:NodeByName("seasonOpen").gameObject
	self.seasonBg1 = self.seasonOpen:ComponentByName("seasonBg1", typeof(UITexture))
	self.seasonBg2 = self.seasonOpen:ComponentByName("seasonBg2", typeof(UITexture))
	self.seasonLabel = self.seasonOpen:ComponentByName("seasonLabel", typeof(UILabel))
	self.seasonCountDown = self.seasonOpen:ComponentByName("seasonCountDown", typeof(UILabel))
end

function ArenaWindow:initLayout()
	if xyd.models.arena:getIsOld() ~= nil then
		xyd.setUITextureByNameAsync(self.imgBg, "arena_title_bg_new")
		xyd.setUITextureByNameAsync(self.imgBg0, "arena_title_bg_new")
		xyd.setUITextureByNameAsync(self.seasonBg1, "arena_operator_bg")
		xyd.setUITextureByNameAsync(self.seasonBg2, "arena_operator_bg")

		if xyd.Global.lang == "de_de" then
			self.seasonLabel:X(-30)
			self.seasonCountDown:X(-148)
		elseif xyd.Global.lang == "fr_fr" then
			self.seasonLabel:X(-165)
			self.seasonCountDown:X(42)
		elseif xyd.Global.lang == "ja_jp" then
			self.seasonCountDown:X(-105)
		end

		local newArenaRankRed = xyd.db.misc:getValue("new_arena_rank_red")

		if not newArenaRankRed then
			self.btnNewRankRedPoint.gameObject:SetActive(true)
		elseif tonumber(newArenaRankRed) < xyd.models.arena:getDDL() then
			self.btnNewRankRedPoint.gameObject:SetActive(true)
		else
			self.btnNewRankRedPoint.gameObject:SetActive(false)
		end
	else
		xyd.setUITextureByNameAsync(self.imgBg, "arena_title_bg")
		xyd.setUITextureByNameAsync(self.imgBg0, "arena_title_bg")
	end

	xyd.setUITextureByNameAsync(self.detailBg1, "arena_operator_bg")
	xyd.setUITextureByNameAsync(self.detailBg2, "arena_operator_bg")
	xyd.setUISpriteAsync(self.imgTitle, nil, "arena_title_" .. tostring(xyd.Global.lang), nil, false, true)
	xyd.setUITextureByNameAsync(self.bg_, "arena_scene")

	local function resCallBack()
		local exchange_id = xyd.ExchangeItem["_" .. tostring(xyd.ItemID.CRYSTAL) .. "TO" .. tostring(xyd.ItemID.ARENA_TICKET)]

		if exchange_id then
			xyd.WindowManager:get():openWindow("item_purchase_window", {
				exchange_id = exchange_id,
				buyCallback = function ()
					xyd.alertTips(__("PURCHASE_SUCCESS"))
				end
			})
		end
	end

	self.res3 = ResItem.new(self.res3Container)

	self.res3:setInfo({
		tableId = xyd.ItemID.ARENA_TICKET,
		callback = resCallBack
	})
	table.insert(self.resItemList, self.res3)

	local callback = nil
	local lastWindow = self.params_.lastWindow

	function callback()
		xyd.WindowManager.get():closeWindow(self.name_, function ()
			if lastWindow then
				xyd.WindowManager.get():openWindow(lastWindow)
			end
		end)
	end

	self.windowTop = WindowTop.new(self.window_, self.name_, 1, true, callback)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setCanRefresh(false)

	self.labelTime.text = __("REST_TIME")
	local avatar = xyd.models.selfPlayer:getAvatarID()
	local lev = xyd.models.backpack:getLev()

	self.pIcon:setInfo({
		avatarID = avatar,
		lev = lev,
		avatar_frame_id = xyd.models.selfPlayer:getAvatarFrameID()
	})

	self.selfPower = xyd.models.slot:calSelfPower()
	self.labelPower.text = self.selfPower
	self.labelRank.text = __("RANK")
	self.labelScore.text = __("SCORE")

	if xyd.Global.lang == "fr_fr" then
		self.labelRank.fontSize = 13
		self.labelScore.fontSize = 14
	end

	self.btnFightLabel.text = __("FIGHT2")
	self.btnAwardLabel.text = __("AWARD2")
	self.btnRecordLabel.text = __("RECORD")
	self.btnFormationLabel.text = __("DEFFORMATION")

	if xyd.Global.lang == "de_de" then
		self.btnAwardLabel.fontSize = 18
		self.btnRecordLabel.fontSize = 18
		self.btnFormationLabel.fontSize = 18
	end

	xyd.models.redMark:setJointMarkImg({
		xyd.RedMarkType.ARENA_SHOP
	}, self.shopRed)

	if xyd.models.arena:getIsOld() ~= nil then
		self.btnNewRank.gameObject:SetActive(true)
	end
end

function ArenaWindow:onGetArenaInfo()
	local partners = self.model_:getDefFormation()

	if #partners <= 0 then
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			alpha = 0.01,
			battleType = xyd.BattleType.ARENADEF,
			pet = self.model_:getPet(),
			callback = function ()
				xyd.WindowManager.get():closeWindow("arena_window")
			end
		})

		local id = xyd.tables.windowTable:getRecordID("arena_window")
		local str = xyd.db.misc:getValue("imgGuide" .. tostring(xyd.Global.playerID))
		local ids = nil

		if str then
			ids = cjson.decode(str)
		end

		if ids and xyd.arrayIndexOf(ids, id) >= 0 then
			xyd.WindowManager.get():openWindow("arena_tips_window")
		end
	end

	self:updateDDL()
	self:updateRank()
	self:updateScore()
	self:setMask(false)
end

function ArenaWindow:updateRank()
	self.rank.text = self.model_:getRank()
end

function ArenaWindow:updateScore()
	self.score.text = self.model_:getScore()
end

function ArenaWindow:updateDDL()
	local ddl = self.model_:getDDL() - xyd.getServerTime()

	if ddl > 0 then
		local secType = xyd.SecondsStrType.NORMAL
		local hour = ddl / 3600

		if hour > 48 then
			secType = xyd.SecondsStrType.NOMINU
		else
			secType = xyd.SecondsStrType.NORMAL
		end

		self.labelDDL.text = xyd.secondsToString(ddl, secType)
	elseif ddl <= 0 then
		self.labelDDL.text = "00:00:00"

		if not UNITY_EDITOR then
			self:close()

			return
		end
	end

	self.labelGroupUITable:Reposition()

	if xyd.models.arena:getIsOld() ~= nil then
		local newArenaStartTimeLeft = xyd.models.arena:getStartTime() + xyd.models.arena:getNewSeasonOpenTime() - xyd.getServerTime()

		if newArenaStartTimeLeft > 0 and newArenaStartTimeLeft < xyd.models.arena:getNewSeasonOpenTime() then
			self.seasonOpen:SetActive(true)

			self.seasonLabel.text = __("OPEN_AFTER")

			if self.seasonCount then
				return
			end

			if self.seasonCount == nil then
				self.seasonCount = CountDown.new(self.seasonCountDown, {
					duration = math.floor(newArenaStartTimeLeft),
					callback = function ()
						self.seasonOpen:SetActive(false)
					end
				})
			else
				self.seasonCount:setInfo({
					duration = math.floor(newArenaStartTimeLeft),
					callback = function ()
						self.seasonOpen:SetActive(false)
					end
				})
			end
		else
			self.seasonOpen:SetActive(false)
		end
	else
		self.seasonOpen:SetActive(false)
	end
end

function ArenaWindow:onGetRankList()
	local ranklist = self.model_:getRankList()

	for i = 1, #ranklist do
		ranklist[i].rank = i
	end

	self.wrapContent:setInfos(ranklist, {})
end

function ArenaWindow:setMask(flag)
	self.mask_bg:SetActive(flag)
end

function ArenaWindow:refreshWinTop()
	self.windowTop:setCanRefresh(true)
	self.windowTop:refresResItems()
	self.windowTop:setCanRefresh(false)
end

function ArenaWindow:willClose()
	BaseWindow.willClose(self)

	if self.timer_ then
		self.timer_:Stop()

		self.timer_ = nil
	end
end

function ArenaWindow:register()
	BaseWindow.register(self)
	self.eventProxy_:addEventListener(xyd.event.ITEM_EXCHANGE, handler(self, self.refreshWinTop))
	self.eventProxy_:addEventListener(xyd.event.MIDAS_BUY, handler(self, self.refreshWinTop))
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, handler(self, self.refreshWinTop))

	UIEventListener.Get(self.btnHelp).onClick = function ()
		if xyd.models.arena:getIsOld() ~= nil then
			xyd.WindowManager.get():openWindow("help_window", {
				key = "ARENA_NEW_HLEP"
			})
		else
			xyd.WindowManager.get():openWindow("help_window", {
				key = "ARENA_HELP"
			})
		end
	end

	UIEventListener.Get(self.btnNewRank).onClick = function ()
		xyd.models.arena:getArenaNewRankList()

		if self.btnNewRankRedPoint.gameObject.activeSelf then
			xyd.db.misc:setValue({
				key = "new_arena_rank_red",
				value = xyd.models.arena:getDDL()
			})
			self.btnNewRankRedPoint.gameObject:SetActive(false)
		end
	end

	UIEventListener.Get(self.btnFight).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_choose_player_window", {
			power = self.selfPower
		})
	end

	UIEventListener.Get(self.btnAward).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_award_window")
	end

	UIEventListener.Get(self.btnRecord).onClick = function ()
		xyd.WindowManager.get():openWindow("arena_record_window")
	end

	UIEventListener.Get(self.btnFormation).onClick = function ()
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			battleType = xyd.BattleType.ARENADEF,
			formation = self.model_:getDefFormation(),
			pet = self.model_:getPet(),
			mapType = xyd.MapType.ARENA
		})
	end

	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_INFO, handler(self, self.onGetArenaInfo))
	self.eventProxy_:addEventListener(xyd.event.GET_RANK_LIST, handler(self, self.onGetRankList))
	self.eventProxy_:addEventListener(xyd.event.SET_PARTNERS, function ()
		self:updateRank()
		self:updateScore()
	end)

	UIEventListener.Get(self.btnShop).onClick = function ()
		xyd.WindowManager.get():openWindow("shop_window", {
			shopType = xyd.ShopType.SHOP_ARENA
		})
	end

	self.timer_ = Timer.New(function ()
		self:updateDDL()
	end, 1, -1)

	self.timer_:Start()
end

function ArenaWindow:playOpenAnimation(callback)
	local pos = self.groupRank.transform.localPosition

	self.groupRank:SetLocalPosition(-720, pos.y, pos.z)

	local action = self:getSequence(function ()
		self:setWndComplete()
	end)

	action:Insert(0, self.groupRank.transform:DOLocalMove(Vector3(50, pos.y, pos.z), 0.3))
	action:Insert(0.3, self.groupRank.transform:DOLocalMove(Vector3(0, pos.y, pos.z), 0.27))

	pos = self.groupDetail.transform.localPosition

	self.groupDetail:SetLocalPosition(-720, pos.y, pos.z)
	action:Insert(0, self.groupDetail.transform:DOLocalMove(Vector3(50, pos.y, pos.z), 0.3))
	action:Insert(0.3, self.groupDetail.transform:DOLocalMove(Vector3(0, pos.y, pos.z), 0.27))
end

function ArenaWindow:getWindowTop()
	return self.windowTop
end

function ArenaWindowItem:ctor(parentGo, parentItem)
	self.parentItem = parentItem

	ArenaWindowItem.super.ctor(self, parentGo)

	self.skinName = "ArenaWindowItemSkin"

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

		if xyd.models.arena:getIsOld() ~= nil then
			if self.params and self.params.is_robot and self.params.is_robot == 1 then
				self.serverInfo:SetActive(false)
			else
				self.serverInfo:SetActive(true)
			end
		end
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
		noClick = false,
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

	if params.server_id then
		self.serverId.text = xyd.getServerNumber(params.server_id)
	end

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

return ArenaWindow
