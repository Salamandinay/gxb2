local BaseWindow = import(".BaseWindow")
local Arena3v3ChoosePlayerWindow = class("Arena3v3ChoosePlayerWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local ArenaChoosePlayerItem = class("ArenaChoosePlayerItem", BaseComponent)
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaChoosePlayerItem:ctor(parentGo, parent)
	self.parent_ = parent

	ArenaChoosePlayerItem.super.ctor(self, parentGo, parent)
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
	self.levelImg = go:ComponentByName("levelImg", typeof(UISprite))
	self.levelImg2 = go:ComponentByName("levelImg2", typeof(UISprite))

	self:createChildren()
end

function ArenaChoosePlayerItem:setInfo(params)
	self.params = params

	if self.parent_.isAs_ then
		self.model_ = xyd.models.arenaAllServerScore
		local rankType = xyd.tables.arenaAllServerRankTable:getRankType(params.score)
		local level = xyd.tables.arenaAllServerRankTable:getRankLevel(params.score, params.rank)

		if level == 21 then
			self.levelImg2.gameObject:SetActive(false)
			xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_5", function ()
				self.levelImg.transform:SetLocalScale(1, 1, 1)
			end, nil, true)
		elseif level == 22 then
			self.levelImg2.gameObject:SetActive(false)
			xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_6", function ()
				self.levelImg.transform:SetLocalScale(1, 1, 1)
			end, nil, true)
		else
			local level_ = math.fmod(level - 1, 5) + 1

			self.levelImg2.gameObject:SetActive(true)
			xyd.setUISpriteAsync(self.levelImg, nil, "as_rank_icon_" .. rankType, function ()
				self.levelImg.transform:SetLocalScale(1.2, 1.2, 1)
			end, nil, true)
			xyd.setUISpriteAsync(self.levelImg2, nil, "as_rank_icon_" .. rankType .. "_" .. level_, function ()
				self.levelImg2.transform:SetLocalScale(1.2, 1.2, 1)
			end, nil, true)
		end

		self.point.transform:X(105)
		self.labelPoint.transform:X(105)

		if params.score < 2000 then
			self.point.text = math.fmod(params.score, 100)
		else
			self.point.text = params.score - 2000
		end
	else
		self.model_ = xyd.models.arena3v3
		self.point.text = params.score
	end

	if params.is_robot == 1 then
		params.lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		params.player_name = xyd.tables.arenaRobotTable:getName(params.player_id)
		params.power = xyd.tables.arenaRobotTable:getPower(params.player_id)
	elseif tonumber(params.player_id) < 10000 then
		local table_id = params.player_id
		params.lev = xyd.tables.arenaAllServerRobotTable:getLev(table_id)
		params.player_name = xyd.tables.arenaAllServerRobotTable:getName(table_id)
		params.power = xyd.tables.arenaAllServerRobotTable:getPower(table_id)
		params.show_id = xyd.tables.arenaAllServerRobotTable:getShowID(table_id)
		params.score = xyd.tables.arenaAllServerRobotTable:getScore(table_id)
		params.server_id = xyd.tables.arenaAllServerRobotTable:getServerID(table_id)
		params.avatar_id = xyd.tables.arenaAllServerRobotTable:getAvatar(table_id)
	end

	self.pIcon:setInfo({
		avatarID = params.avatar_id,
		lev = params.lev,
		avatar_frame_id = params.avatar_frame_id,
		callback = function ()
			if self.parent_.isAs_ then
				xyd.WindowManager.get():openWindow("arena_all_server_formation_window", {
					player_id = self.params.player_id
				})
			else
				xyd.WindowManager.get():openWindow("arena_3v3_formation_window", {
					player_id = self.params.player_id
				})
			end
		end
	})

	self.playerName.text = params.player_name
	self.power.text = params.power
	self.labelPoint.text = __("SCORE")
	local cost = 0
	cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]

	if self.parent_.isAs_ then
		cost = self.model_:getFightCost()[2]
	end

	xyd.setUISpriteAsync(self.btnFightIcon, nil, xyd.tables.itemTable:getIcon(xyd.ItemID.ARENA_TICKET))

	self.btnFightLabel.text = __("FIGHT3")
	self.btnFightBtnNum.text = cost
end

function ArenaChoosePlayerItem:createChildren()
	UIEventListener.Get(self.btnFight).onClick = function ()
		local cost = 0
		cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]

		if self.parent_.isAs_ then
			cost = self.model_:getFightCost()[2]
		end

		if tonumber(cost) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.ARENA_TICKET) then
			if self.parent_.isAs_ then
				xyd.WindowManager.get():openWindow("arena_all_server_battle_formation_window", {
					showSkip = true,
					battleType = xyd.BattleType.ARENA_ALL_SERVER,
					formation = self.model_:getDefFormation(),
					mapType = xyd.MapType.ARENA_3v3,
					enemy_id = self.params.player_id,
					enemy_level = xyd.tables.arenaAllServerRankTable:getRankLevel(self.params.score),
					skipState = xyd.models.arenaAllServerScore:isSkipReport(),
					btnSkipCallback = function (flag)
						xyd.models.arenaAllServerScore:setSkipReport(flag)
					end
				})
			else
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
			end
		else
			xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ARENA_TICKET)))
		end
	end
end

function Arena3v3ChoosePlayerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	if params then
		self.isAs_ = params.isAs
	end

	if self.isAs_ then
		self.model_ = xyd.models.arenaAllServerScore
	else
		self.model_ = xyd.models.arena3v3
	end

	self.playerItems = {}
end

function Arena3v3ChoosePlayerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self.model_:reqEnemyList()
	self:layout()
end

function Arena3v3ChoosePlayerWindow:getUIComponent()
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

function Arena3v3ChoosePlayerWindow:registerEvent()
	UIEventListener.Get(self.btnRefresh).onClick = function ()
		if self.isAs_ then
			local totalNum = xyd.tables.miscTable:getVal("arena_all_server_refresh_num")
			local refreshNum = self.model_:getCanRefreshNum()

			if not refreshNum or tonumber(totalNum) - refreshNum == 0 then
				xyd.alertTips(__("NEW_ARENA_ALL_SERVER_TEXT_20"))
			else
				self.btnRefresh:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

				self.model_:refreshEnemyList()
			end
		else
			self.model_:reqEnemyList()
		end
	end

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	self.eventProxy_:addEventListener(xyd.event.GET_MATCH_3V3_INFOS, handler(self, self.onUpdate))
	self.eventProxy_:addEventListener(xyd.event.GET_MATCH_ALL_SEVER_INFOS, handler(self, self.onUpdate))
	self.eventProxy_:addEventListener(xyd.event.REFRESH_MATCH_INFOS, handler(self, self.onUpdate))
end

function Arena3v3ChoosePlayerWindow:onUpdate(event)
	print("+++++++++++")

	local data = self.model_:getEnemyList()

	for i = 1, #data do
		local playerItem = self.playerItems[i]

		if playerItem == nil then
			playerItem = ArenaChoosePlayerItem.new(self.container, self)
			self.playerItems[i] = playerItem
		end

		playerItem:setInfo(data[i])
	end

	for index, item in pairs(self.playerItems) do
		if index > #data then
			item:SetActive(false)
		else
			item:SetActive(true)
		end
	end

	self.containerLayout:Reposition()

	if self.isAs_ then
		local totalNum = xyd.tables.miscTable:getVal("arena_all_server_refresh_num")
		self.btnRefreshLabel.text = __("NEW_ARENA_ALL_SERVER_TEXT_12", tonumber(totalNum) - self.model_:getCanRefreshNum())
		self.btnRefresh:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true
	end
end

function Arena3v3ChoosePlayerWindow:layout()
	self.labelTitle.text = __("CHOOSE_OPPONENT")
	self.labelChoose.text = __("CHOOSE_OPPONENT_TIPS")
	self.labelPower.text = __("MY_POWER")
	self.power.text = self.params_.power or 0

	xyd.setBgColorType(self.btnRefresh, xyd.ButtonBgColorType.white_btn_70_70)

	self.btnRefreshLabel.text = __("REFRESH")

	if self.isAs_ then
		local totalNum = xyd.tables.miscTable:getVal("arena_all_server_refresh_num")
		self.btnRefreshLabel.text = __("NEW_ARENA_ALL_SERVER_TEXT_12", tonumber(totalNum) - self.model_:getCanRefreshNum())

		if xyd.Global.lang == "de_de" or xyd.Global.lang == "fr_fr" then
			self.btnRefreshLabel.fontSize = 18
		elseif xyd.Global.lang == "en_en" then
			self.btnRefreshLabel.fontSize = 20
		end
	end
end

return Arena3v3ChoosePlayerWindow
