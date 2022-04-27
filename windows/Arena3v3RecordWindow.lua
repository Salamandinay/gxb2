local BaseWindow = import(".BaseWindow")
local Arena3v3RecordWindow = class("Arena3v3RecordWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local Arena3v3RecordItem = class("Arena3v3RecordItem", BaseComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")
local PlayerIcon = import("app.components.PlayerIcon")

function Arena3v3RecordItem:ctor(parentGo, parent)
	self.parent_ = parent

	Arena3v3RecordItem.super.ctor(self, parentGo)
	self:getUIComponent()
end

function Arena3v3RecordItem:getPrefabPath()
	return "Prefabs/Components/arena_record_item"
end

function Arena3v3RecordItem:getUIComponent()
	local go = self.go
	local pIconContainer = go:NodeByName("pIcon").gameObject
	self.pIcon = PlayerIcon.new(pIconContainer)
	self.playerName = go:ComponentByName("playerName", typeof(UILabel))
	self.time = go:ComponentByName("time", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.fight = go:NodeByName("fight").gameObject
	self.fightLabel = self.fight:ComponentByName("button_label", typeof(UILabel))
	self.fightBtnNum = self.fight:ComponentByName("btn_num", typeof(UILabel))
	self.fightIcon = self.fight:ComponentByName("icon", typeof(UISprite))
	self.loseImage = go:NodeByName("loseImage").gameObject
	self.winImage = go:NodeByName("winImage").gameObject
	self.video = go:NodeByName("video").gameObject

	self:createChildren()
end

function Arena3v3RecordItem:setState(state)
	if state == "win" then
		self.winImage:SetActive(true)
		self.loseImage:SetActive(false)
		self.fight:SetActive(false)

		self.point.color = Color.New2(915996927)
	else
		self.winImage:SetActive(false)
		self.loseImage:SetActive(true)
		self.fight:SetActive(true)

		self.point.color = Color.New2(2751463679.0)
	end

	if self.parent_ and self.parent_.parent.isAsAfter_ then
		self.fight:SetActive(false)
	end

	if self.parent_ and self.parent_.parent.isAs_ then
		local stratTime = xyd.models.arenaAllServerScore:getStartTime()

		if xyd.getServerTime() - stratTime > 19 * xyd.DAY_TIME or xyd.getServerTime() - stratTime < 0 then
			self.fight:SetActive(false)
		end
	end
end

function Arena3v3RecordItem:setInfo(params)
	self.params = params

	if params.is_robot == 1 then
		local avatar = xyd.tables.arenaRobotTable:getAvatar(params.player_id)
		local lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		local name = xyd.tables.arenaRobotTable:getName(params.player_id)

		self.pIcon:setInfo({
			avatarID = avatar,
			lev = lev
		})

		self.playerName.text = name
	elseif tonumber(params.player_id) < 10000 then
		local table_id = params.player_id
		params.lev = xyd.tables.arenaAllServerRobotTable:getLev(table_id)
		params.player_name = xyd.tables.arenaAllServerRobotTable:getName(table_id)
		params.power = xyd.tables.arenaAllServerRobotTable:getPower(table_id)
		params.avatar_id = xyd.tables.arenaAllServerRobotTable:getAvatar(table_id)
		params.show_id = xyd.tables.arenaAllServerRobotTable:getShowID(table_id)
		params.server_id = xyd.tables.arenaAllServerRobotTable:getServerID(table_id)

		self.pIcon:setInfo({
			avatarID = params.avatar_id,
			lev = params.lev,
			callback = function ()
				self:onclickAvatar()
			end
		})

		self.playerName.text = params.player_name
	else
		self.pIcon:setInfo({
			avatarID = params.info_detail.avatar_id,
			lev = params.info_detail.lev,
			avatar_frame_id = params.info_detail.avatar_frame_id,
			callback = function ()
				self:onclickAvatar()
			end
		})

		self.playerName.text = params.info_detail.player_name
	end

	self.time.text = params.time
	local resTime = xyd.getServerTime() - params.time
	local min = resTime / 60
	local hour = min / 60
	local day = hour / 24

	if day >= 1 then
		self.time.text = __("DAY_BEFORE", math.floor(day))
	elseif hour >= 1 then
		self.time.text = __("HOUR_BEFORE", math.floor(hour))
	elseif min >= 1 then
		self.time.text = __("MIN_BEFORE", math.floor(min))
	else
		self.time.text = __("SECOND_BEFORE")
	end

	self.labelPoint.text = __("SCORE")
	local score = params.score > 0 and "+" .. tostring(params.score) or params.score
	self.point.text = score

	if params.is_win == 1 then
		self.currentState = "win"

		self:setState("win")
	else
		self.currentState = "lose"

		self:setState("lose")

		local cost = xyd.models.arena:getFreeTimes() > 0 and 0 or 1

		xyd.setUISpriteAsync(self.fightIcon, nil, xyd.tables.itemTable:getSmallIcon(xyd.ItemID.ARENA_TICKET))

		self.fightLabel.text = __("FIGHT3")
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]

	if self.parent_ and self.parent_.parent.isAs_ then
		cost = xyd.models.arenaAllServerScore:getFightCost()[2]
	end

	self.fightBtnNum.text = cost

	if self.params.isClose then
		self.fight:SetActive(false)

		self.pIcon.callback = nil

		self.pIcon:setTouchEnable(false)
	end
end

function Arena3v3RecordItem:createChildren()
	self:register()
end

function Arena3v3RecordItem:register()
	UIEventListener.Get(self.video).onClick = function ()
		self:onclickVideo()
	end

	UIEventListener.Get(self.fight).onClick = function ()
		self:onclickFight()
	end
end

function Arena3v3RecordItem:onclickVideo()
	local isAllServer = self.parent_ and self.parent_.parent.isAs_
	local isAsAfter = self.parent_ and self.parent_.parent.isAsAfter_

	xyd.WindowManager:get():openWindow("arena_3v3_record_detail_window", {
		report_ids = self.params.record_ids,
		isAllServer = isAllServer,
		isAsAfter = isAsAfter
	})
end

function Arena3v3RecordItem:onclickFight()
	local cost = xyd.split(xyd.tables.miscTable:getVal("arena_3v3_ticket_cost"), "#")[2]

	if self.parent_ and self.parent_.parent.isAs_ then
		cost = xyd.models.arenaAllServerScore:getFightCost()[2]
	end

	if tonumber(cost) <= xyd.models.backpack:getItemNumByID(xyd.ItemID.ARENA_TICKET) then
		if self.parent_ and self.parent_.parent.isAs_ then
			xyd.WindowManager.get():openWindow("arena_all_server_battle_formation_window", {
				showSkip = true,
				is_revenge = 1,
				battleType = xyd.BattleType.ARENA_ALL_SERVER,
				formation = xyd.models.arenaAllServerScore:getDefFormation(),
				mapType = xyd.MapType.ARENA_3v3,
				enemy_id = self.params.player_id,
				enemy_level = xyd.tables.arenaAllServerRankTable:getRankLevel(self.params.cur_score),
				skipState = xyd.models.arenaAllServerScore:isSkipReport(),
				btnSkipCallback = function (flag)
					xyd.models.arenaAllServerScore:setSkipReport(flag)
				end
			})
		else
			xyd.WindowManager.get():openWindow("arena_3v3_battle_formation_window", {
				showSkip = true,
				is_revenge = 1,
				battleType = xyd.BattleType.ARENA_3v3,
				formation = xyd.models.arena3v3:getDefFormation(),
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

function Arena3v3RecordItem:onclickAvatar()
	if self.parent_ and (self.parent_.parent.isAs_ or self.parent_.parent.isAsAfter_) then
		xyd.WindowManager.get():openWindow("arena_all_server_formation_window", {
			player_id = self.params.player_id,
			is_robot = self.params.is_robot,
			is_as_after = self.parent_.parent.isAsAfter_
		})
	else
		xyd.WindowManager.get():openWindow("arena_3v3_formation_window", {
			add_friend = false,
			player_id = self.params.player_id,
			is_robot = self.params.is_robot
		})
	end
end

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = Arena3v3RecordItem.new(go, self)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)
	self.item:setInfo(info)
end

function ItemRender:getGameObject()
	return self.go
end

function Arena3v3RecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.isAs_ = false

	if params then
		self.isAs_ = params.isAs
		self.isAsAfter_ = params.isAsAfter
	end

	if self.isAs_ then
		self.model_ = xyd.models.arenaAllServerScore
	elseif self.isAsAfter_ then
		self.model_ = xyd.models.arenaAllServerNew
	else
		self.model_ = xyd.models.arena3v3
	end
end

function Arena3v3RecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
end

function Arena3v3RecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:registerEvent()
	self.scrollView:SetActive(false)
	self.model_:reqRecord()
end

function Arena3v3RecordWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.ARENA_3v3_RECORD, handler(self, self.onGetData))
	self.eventProxy_:addEventListener(xyd.event.ARENA_ALL_SERVER_RECORD, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function Arena3v3RecordWindow:onGetData(event)
	self.scrollView:SetActive(true)

	local data = xyd.decodeProtoBuf(event.data)
	local records = data.records or {}

	if not records or #records == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)

		local isClose = false
		local startTime = self.model_:getStartTime() - xyd.getServerTime()

		if startTime > 0 then
			isClose = true
		end

		for i = 1, #records do
			records[i].isClose = isClose
		end
	end

	self.wrapContent:setInfos(records)
end

return Arena3v3RecordWindow
