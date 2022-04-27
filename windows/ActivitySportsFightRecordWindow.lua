local BaseWindow = import(".BaseWindow")
local ActivitySportsFightRecordWindow = class("ActivitySportsFightRecordWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ArenaRecordWindow = import(".ArenaRecordWindow")
local ItemRenderTest = class("ItemRenderTest", ArenaRecordWindow.ItemRender)
local ActivitySportsArenaRecordItem = class("ActivitySportsArenaRecordItem", ArenaRecordWindow.ArenaRecordItem)
local PlayerIcon = import("app.components.PlayerIcon")

function ItemRenderTest:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ActivitySportsArenaRecordItem.new(go)

	self.item:setDragScrollView(parent.scrollView)
end

function ActivitySportsArenaRecordItem:ctor(parentGo)
	ActivitySportsArenaRecordItem.super.ctor(self, parentGo)
end

function ActivitySportsArenaRecordItem:getPrefabPath()
	return "Prefabs/Components/activity_sports_arena_record_item"
end

function ActivitySportsArenaRecordItem:getUIComponent()
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
	self.serverInfo = go:NodeByName("serverInfo").gameObject
	self.serverId = self.serverInfo:ComponentByName("serverId", typeof(UILabel))
	self.groupWords = go:ComponentByName("groupWords", typeof(UILabel))
	self.groupImg = go:ComponentByName("groupImg", typeof(UISprite))

	self:createChildren()
end

function ActivitySportsArenaRecordItem:setInfo(params)
	self.params = params
	local randomGroup = 7

	while randomGroup ~= self.playerGroup and randomGroup == 7 do
		randomGroup = math.round(math.random() * 6) + 1
	end

	local group = params.group
	group = group or randomGroup
	local serverStr = "S999"

	if params.is_robot == 1 then
		local avatar = xyd.tables.activitySportsRobotTable:getAvatar(params.player_id)
		local lev = xyd.tables.activitySportsRobotTable:getLev(params.player_id)
		local name = xyd.tables.activitySportsRobotTable:getName(params.player_id)

		self.pIcon:setInfo({
			avatarID = avatar,
			lev = lev
		})

		self.playerName.text = __("ACTIVITY_SPORTS_ROBOT_NAME", __("GROUP_" .. group))
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
		serverStr = xyd.getServerNumber(params.info_detail.server_id)
	end

	self.serverId.text = serverStr
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

	self.fight:SetActive(false)
	xyd.setUISpriteAsync(self.groupImg, nil, "img_group" .. group, nil, )

	self.groupWords.text = __("ACTIVITY_SPORTS_GROUP")
end

function ActivitySportsArenaRecordItem:onclickAvatar()
end

function ActivitySportsFightRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.skinName = "ArenaRecordSkin"
	self.model_ = xyd.models.arena
	self.eventData = params.eventData
end

function ActivitySportsFightRecordWindow:initWindow()
	self:getUIComponent()
	BaseWindow.initWindow(self)

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:registerEvent()
	self:onGetData(self.eventData)
end

function ActivitySportsFightRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, itemContainer, ItemRenderTest, self)
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
end

function ActivitySportsFightRecordWindow:registerEvent()
	UIEventListener.Get(self.backBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ActivitySportsFightRecordWindow:onGetData(data)
	local data = data.records

	if #data == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.wrapContent:setInfos(data)
end

return ActivitySportsFightRecordWindow
