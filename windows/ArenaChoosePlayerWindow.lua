local BaseWindow = import(".BaseWindow")
local ArenaChoosePlayerWindow = class("ArenaChoosePlayerWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local ArenaChoosePlayerItem = class("ArenaChoosePlayerItem", BaseComponent)
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaChoosePlayerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaChoosePlayerSkin"
	self.model_ = xyd.models.arena
	self.playerItems = {}
end

function ArenaChoosePlayerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:register()
	self.model_:reqEnemyList()
	self:layout()
end

function ArenaChoosePlayerWindow:getUIComponent()
	local content = self.window_.transform:NodeByName("groupAction").gameObject
	local titleGroup = content:NodeByName("titleGroup").gameObject
	self.backBtn = titleGroup:NodeByName("backBtn").gameObject
	self.labelTitle = titleGroup:ComponentByName("labelTitle", typeof(UILabel))
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.labelChoose = middleGroup:ComponentByName("labelChoose", typeof(UILabel))
	local containerGroup = middleGroup:NodeByName("containerGroup").gameObject
	self.container = containerGroup:NodeByName("container").gameObject
	self.containerLayout = self.container:GetComponent(typeof(UILayout))
	self.btnRefresh = middleGroup:NodeByName("btnRefresh").gameObject
	self.btnRefreshLabel = self.btnRefresh:ComponentByName("button_label", typeof(UILabel))
	self.powerGroup = middleGroup:NodeByName("powerGroup").gameObject
	self.labelPower = self.powerGroup:ComponentByName("labelPower", typeof(UILabel))
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
end

function ArenaChoosePlayerWindow:register()
	UIEventListener.Get(self.btnRefresh).onClick = function ()
		self.model_:reqEnemyList()
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_MATCH_INFOS, handler(self, self.onUpdate))
end

function ArenaChoosePlayerWindow:onUpdate(event)
	local data = self.model_:getEnemyList()

	for i = 1, #data do
		local playerItem = self.playerItems[i]

		if playerItem == nil then
			playerItem = ArenaChoosePlayerItem.new(self.container)
			self.playerItems[i] = playerItem
		end

		playerItem:setInfo(data[i])
	end

	self.containerLayout:Reposition()
end

function ArenaChoosePlayerWindow:layout()
	self.labelTitle.text = __("CHOOSE_OPPONENT")
	self.labelChoose.text = __("CHOOSE_OPPONENT_TIPS")
	self.labelPower.text = __("MY_POWER")
	self.power.text = self.params_.power or 0

	xyd.setBgColorType(self.btnRefresh, xyd.ButtonBgColorType.white_btn_70_70)

	self.btnRefreshLabel.text = __("REFRESH")
end

function ArenaChoosePlayerItem:ctor(parentGo)
	ArenaChoosePlayerItem.super.ctor(self, parentGo)

	self.skinName = "ArenaChoosePlayerItemSkin"

	self:getUIComponent()
end

function ArenaChoosePlayerItem:getPrefabPath()
	return "Prefabs/Components/arena_choose_player_item"
end

function ArenaChoosePlayerItem:getUIComponent()
	local go = self.go
	local pIconContainer = go:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.power = go:ComponentByName("power", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.btnFight = go:NodeByName("btnFight").gameObject
	self.btnFightLabel = self.btnFight:ComponentByName("button_label", typeof(UILabel))
	self.btnFightBtnNum = self.btnFight:ComponentByName("btn_num", typeof(UILabel))
	self.btnFightIcon = self.btnFight:ComponentByName("icon", typeof(UISprite))

	self:createChildren()
end

function ArenaChoosePlayerItem:setInfo(params)
	self.params = params

	if self.params.type == "arena3v3" then
		self.model_ = xyd.models.arena3v3
	else
		self.model_ = xyd.models.arena
	end

	if params.is_robot == 1 then
		params.lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		params.player_name = xyd.tables.arenaRobotTable:getName(params.player_id)
		params.power = xyd.tables.arenaRobotTable:getPower(params.player_id)
	end

	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id,
		callback = function ()
			if self.params.type == "arena3v3" then
				xyd.WindowManager.get():openWindow("arena_3v3_formation_window", {
					player_id = self.params.player_id
				})
			else
				xyd.WindowManager.get():openWindow("arena_formation_window", {
					player_id = self.params.player_id,
					is_robot = self.params.is_robot
				})
			end
		end
	})

	self.playerName.text = params.player_name
	self.power.text = params.power
	self.labelPoint.text = __("SCORE")
	self.point.text = params.score
	local cost = 0

	if self.params.type == "arena3v3" then
		cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]
	elseif self.model_:getFreeTimes() > 0 then
		cost = 0
	else
		cost = 1
	end

	xyd.setUISpriteAsync(self.btnFightIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.ARENA_TICKET))

	self.btnFightLabel.text = __("FIGHT3")
	self.btnFightBtnNum.text = cost
end

function ArenaChoosePlayerItem:createChildren()
	UIEventListener.Get(self.btnFight).onClick = function ()
		local cost = 0

		if self.params.type == "arena3v3" then
			cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]
		elseif self.model_:getFreeTimes() > 0 then
			cost = 0
		else
			cost = 1
		end

		if cost <= xyd.models.backpack:getItemNumByID(xyd.ItemID.ARENA_TICKET) then
			if self.params.type == "arena3v3" then
				xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
					showSkip = true,
					battleType = xyd.BattleType.ARENA_3v3,
					formation = self.model_:getDefFormation(),
					mapType = xyd.MapType.ARENA_3v3,
					enemy_id = self.params.player_id,
					skipState = xyd.models.arena3v3:isSkipReport(),
					btnSkipCallback = function (flag)
						xyd.models.arena3v3:setSkipReport(flag)
					end
				})
			else
				xyd.WindowManager.get():openWindow("battle_formation_window", {
					showSkip = true,
					battleType = xyd.BattleType.ARENA,
					mapType = xyd.MapType.ARENA,
					enemy_id = self.params.player_id,
					skipState = xyd.models.arena:isSkipReport(),
					btnSkipCallback = function (flag)
						xyd.models.arena:setSkipReport(flag)
					end
				})
			end
		else
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ARENA_TICKET)))
		end
	end
end

return ArenaChoosePlayerWindow
