local BaseWindow = import(".BaseWindow")
local ArenaTeamChoosePlayerWindow = class("ArenaTeamChoosePlayerWindow", BaseWindow)
local ArenaTeamChoosePlayerItem = class("ArenaTeamChoosePlayerItem", import("app.components.BaseComponent"))
local CountDown = import("app.components.CountDown")
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaTeamChoosePlayerWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.arenaTeam
	self.params = params
end

function ArenaTeamChoosePlayerWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:registerEvent()
	self.model_:reqEnemyList()
	self:layout()
end

function ArenaTeamChoosePlayerWindow:getUIComponent()
	local winTrans = self.window_.transform
	local mainGroup = winTrans:NodeByName("mainGroup").gameObject
	local topGroup = mainGroup:NodeByName("topGroup").gameObject
	self.backBtn = topGroup:NodeByName("backBtn").gameObject
	self.labelTitle = topGroup:ComponentByName("labelTitle", typeof(UILabel))
	local infoGroup = mainGroup:NodeByName("infoGroup").gameObject
	self.powerGroup = infoGroup:NodeByName("powerGroup").gameObject
	self.power = self.powerGroup:ComponentByName("power", typeof(UILabel))
	self.btnSkip = infoGroup:NodeByName("btnSkip").gameObject
	self.btnSkipLabelDisplay = self.btnSkip:ComponentByName("button_label", typeof(UILabel))
	self.selected = self.btnSkip:NodeByName("select").gameObject
	self.btnResetTeam = infoGroup:NodeByName("btnResetTeam").gameObject
	self.btnResetTeamLabelDisplay = self.btnResetTeam:ComponentByName("button_label", typeof(UILabel))
	self.energyGroup = infoGroup:NodeByName("energyGroup").gameObject
	self.energy = self.energyGroup:ComponentByName("energy", typeof(UILabel))
	self.timeGroup = infoGroup:NodeByName("timeGroup").gameObject
	self.recoverTime = self.timeGroup:ComponentByName("recoverTime", typeof(UILabel))
	self.labelTime = self.timeGroup:ComponentByName("labelTime", typeof(UILabel))
	self.countDown = CountDown.new(self.labelTime)
	self.container = infoGroup:NodeByName("container").gameObject
	self.btnRefresh = infoGroup:NodeByName("btnRefresh").gameObject
	self.btnRefreshLabelDisplay = self.btnRefresh:ComponentByName("button_label", typeof(UILabel))
end

function ArenaTeamChoosePlayerWindow:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnRefresh, self, function ()
		self.model_:reqEnemyList()
	end)
	xyd.setDarkenBtnBehavior(self.backBtn, self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
	xyd.setDarkenBtnBehavior(self.btnResetTeam, self, function ()
		xyd.WindowManager.get():openWindow("arena_team_change_team_window", {})
	end)
	xyd.setDarkenBtnBehavior(self.btnSkip, self, function ()
		local flag = self.selected.activeSelf

		self.selected:SetActive(not flag)
		self.model_:setSkipReport(self.selected.activeSelf)
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_MATCH_INFOS, handler(self, self.onUpdate))
end

function ArenaTeamChoosePlayerWindow:onUpdate(event)
	local data = self.model_:getEnemyList()

	NGUITools.DestroyChildren(self.container.transform)

	for i = 1, #data do
		local playerItem = ArenaTeamChoosePlayerItem.new(self.container, self)

		playerItem:setInfo(data[i])
	end

	self.container:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamChoosePlayerWindow:updateNextTime()
	local lastEnergyTime = self.model_:getEnergyTime()
	local interval = tonumber(xyd.tables.miscTable:getVal("arena_team_energy_cd"))
	local fixEnergy = self:getEnergy()
	local maxEnergy = tonumber(xyd.tables.miscTable:getVal("arena_team_energy_max"))
	fixEnergy = math.min(fixEnergy, maxEnergy)
	self.energy.text = tostring(fixEnergy) .. "/" .. tostring(maxEnergy)
	local nextTime = lastEnergyTime + interval - xyd.getServerTime()

	while nextTime <= 0 do
		nextTime = nextTime + interval
	end

	self.countDown:setInfo({
		duration = nextTime,
		callback = function ()
			self.updateNextTime()
		end
	})

	self.recoverTime.text = __("NEXT_RECOVER_TIME")

	self.timeGroup:GetComponent(typeof(UILayout)):Reposition()
end

function ArenaTeamChoosePlayerWindow:getEnergy()
	local lastEnergyTime = self.model_:getEnergyTime()
	local interval = tonumber(xyd.tables.miscTable:getVal("arena_team_energy_cd"))
	local fixEnergy = self.model_:getEnergy() + math.floor((xyd.getServerTime() - lastEnergyTime) / interval)

	return fixEnergy
end

function ArenaTeamChoosePlayerWindow:layout()
	self.labelTitle.text = __("CHOOSE_OPPONENT")
	self.power.text = self.params.power or 0
	self.btnRefreshLabelDisplay.text = __("REFRESH")
	self.btnResetTeamLabelDisplay.text = __("RESET_TEAM")

	self:updateNextTime()
	self.btnSkip:SetActive(true)

	self.btnSkipLabelDisplay.text = __("SKIP_BATTLE2")

	self.selected:SetActive(self.model_:isSkipReport())
end

function ArenaTeamChoosePlayerItem:ctor(parentGO, parent_)
	ArenaTeamChoosePlayerItem.super.ctor(self, parentGO)

	self.parent_ = parent_

	self:registerEvent()
end

function ArenaTeamChoosePlayerItem:getPrefabPath()
	return "Prefabs/Components/arena_team_choose_player_item"
end

function ArenaTeamChoosePlayerItem:initUI()
	ArenaTeamChoosePlayerItem.super.initUI(self)

	local go = self.go
	local pIconGroup = go:NodeByName("pIconGroup").gameObject

	for i = 1, 3 do
		local group = pIconGroup:NodeByName("pIconGroup" .. tostring(i)).gameObject
		self["pIcon" .. tostring(i)] = PlayerIcon.new(group)
	end

	local playerGroup = go:NodeByName("playerGroup").gameObject
	self.teamName = playerGroup:ComponentByName("teamName", typeof(UILabel))
	self.power = playerGroup:ComponentByName("power", typeof(UILabel))
	local serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverInfo = serverInfo
	self.serverId = serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.touchGroup = go:NodeByName("touchGroup").gameObject
	self.btnFight = go:NodeByName("btnFight").gameObject
	self.btnFightLabelDisplay = self.btnFight:ComponentByName("button_label", typeof(UILabel))
end

function ArenaTeamChoosePlayerItem:setInfo(params)
	self.params = params
	self.model_ = xyd.models.arenaTeam

	for i = 1, 3 do
		local info = {
			noClick = true,
			avatarID = params.players[i].avatar_id,
			lev = params.players[i].lev,
			avatar_frame_id = params.players[i].avatar_frame_id
		}

		self["pIcon" .. tostring(i)]:setInfo(info)

		if params.leader_id == params.players[i].player_id then
			self["pIcon" .. tostring(i)]:setCaptain(true)
		end
	end

	self.teamName.text = params.team_name
	self.power.text = params.power
	self.labelPoint.text = __("SCORE")
	self.point.text = params.score
	self.serverId.text = xyd.getServerNumber(params.server_id)

	self.serverInfo:SetActive(xyd.models.arenaTeam:isShowServerId(params.server_id))

	self.btnFightLabelDisplay.text = __("FIGHT3")
end

function ArenaTeamChoosePlayerItem:registerEvent()
	xyd.setDarkenBtnBehavior(self.btnFight, self, function ()
		print(self.parent_:getEnergy())

		if self.parent_:getEnergy() > 0 then
			xyd.models.arenaTeam:fight(self.params.team_id)
		else
			xyd.alert(xyd.AlertType.TIPS, __("FRIEND_NO_TILI"))
		end
	end)

	UIEventListener.Get(self.touchGroup).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("arena_team_formations_window", {
			player_id = self.params.leader_id
		})
	end)
end

return ArenaTeamChoosePlayerWindow
