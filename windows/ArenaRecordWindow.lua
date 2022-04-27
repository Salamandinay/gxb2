local BaseWindow = import(".BaseWindow")
local ArenaRecordWindow = class("ArenaRecordWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local ArenaRecordItem = class("ArenaRecordItem", BaseComponent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")
ArenaRecordWindow.ArenaRecordItem = ArenaRecordItem
ArenaRecordWindow.ItemRender = ItemRender

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaRecordItem.new(go)

	self.item:setDragScrollView(parent.scrollView)
end

function ItemRender:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)
	self.item:setInfo(info, self.parent.renderPanel)
end

function ItemRender:getGameObject()
	return self.go
end

function ArenaRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaRecordSkin"
	self.model_ = xyd.models.arena
end

function ArenaRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:register()
	self.scrollView:SetActive(false)
	self.model_:reqRecord()
end

function ArenaRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.renderPanel = self.scrollView:GetComponent(typeof(UIPanel))
	local wrapContent = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
end

function ArenaRecordWindow:register()
	self.eventProxy_:addEventListener(xyd.event.ARENA_RECORD, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function ArenaRecordWindow:onGetData(event)
	self.scrollView:SetActive(true)

	local data = event.data.records

	if #data == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.wrapContent:setInfos(data)
end

local PlayerIcon = import("app.components.PlayerIcon")

function ArenaRecordItem:ctor(parentGo)
	ArenaRecordItem.super.ctor(self, parentGo)

	self.skinName = "ArenaRecordItemSkin"

	self:getUIComponent()
end

function ArenaRecordItem:getPrefabPath()
	return "Prefabs/Components/arena_record_item"
end

function ArenaRecordItem:getUIComponent()
	local go = self.go
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

function ArenaRecordItem:setState(state)
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
end

function ArenaRecordItem:setInfo(params, renderPanel)
	self.params = params

	if not self.pIcon then
		local pIconContainer = self.go:NodeByName("pIcon").gameObject
		self.pIcon = PlayerIcon.new(pIconContainer, renderPanel)
	end

	if params.is_robot == 1 then
		local avatar = xyd.tables.arenaRobotTable:getAvatar(params.player_id)
		local lev = xyd.tables.arenaRobotTable:getLev(params.player_id)
		local name = xyd.tables.arenaRobotTable:getName(params.player_id)

		self.pIcon:setInfo({
			avatarID = avatar,
			lev = lev
		})

		self.playerName.text = name
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
		self.fightBtnNum.text = cost

		xyd.setUISpriteAsync(self.fightIcon, nil, xyd.tables.itemTable:getSmallIcon(xyd.ItemID.ARENA_TICKET))

		self.fightLabel.text = __("FIGHT3")
	end
end

function ArenaRecordItem:createChildren()
	self:register()
end

function ArenaRecordItem:register()
	UIEventListener.Get(self.video).onClick = function ()
		self:onclickVideo()
	end

	UIEventListener.Get(self.fight).onClick = function ()
		self:onclickFight()
	end
end

function ArenaRecordItem:onclickVideo()
	xyd.models.arena:reqReport(self.params.record_id)
end

function ArenaRecordItem:onclickFight()
	local cost = xyd.models.arena:getFreeTimes() > 0 and 0 or 1

	if cost <= xyd.models.backpack:getItemNumByID(xyd.ItemID.ARENA_TICKET) then
		xyd.WindowManager.get():openWindow("battle_formation_window", {
			showSkip = true,
			is_revenge = 1,
			battleType = xyd.BattleType.ARENA,
			mapType = xyd.MapType.ARENA,
			enemy_id = self.params.player_id,
			skipState = xyd.models.arena:isSkipReport(),
			btnSkipCallback = function (flag)
				xyd.models.arena:setSkipReport(flag)
			end
		})
	else
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.ARENA_TICKET)))
	end
end

function ArenaRecordItem:onclickAvatar()
	xyd.WindowManager.get():openWindow("arena_formation_window", {
		add_friend = false,
		player_id = self.params.player_id,
		is_robot = self.params.is_robot
	})
end

return ArenaRecordWindow
