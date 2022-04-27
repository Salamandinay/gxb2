local BaseWindow = import(".BaseWindow")
local ArenaTeamRecordWindow = class("ArenaTeamRecordWindow", BaseWindow)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local ItemRender = class("ItemRender")
local ArenaTeamRecordItem = class("ArenaTeamRecordItem", import("app.components.BaseComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = ArenaTeamRecordItem.new(go)

	xyd.setDragScrollView(self.item.touchGroup, parent.scrollView)
	self.go:SetActive(false)
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

function ArenaTeamRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.arenaTeam
end

function ArenaTeamRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:registerEvent()
	self.scrollView:SetActive(false)
	self.model_:reqRecord()
end

function ArenaTeamRecordWindow:getUIComponent()
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

function ArenaTeamRecordWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ARENA_TEAM_RECORDS, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn).onClick = handler(self, function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end)
end

function ArenaTeamRecordWindow:onGetData(event)
	self.scrollView:SetActive(true)

	local data = event.data.records

	if not data or #data == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.wrapContent:setInfos(data, {})
end

function ArenaTeamRecordItem:ctor(parentGO)
	ArenaTeamRecordItem.super.ctor(self, parentGO)
	self:getUIComponent()
	self:registerEvent()
end

function ArenaTeamRecordItem:getPrefabPath()
	return "Prefabs/Components/arena_team_record_item"
end

function ArenaTeamRecordItem:getUIComponent()
	local go = self.go
	local pGroup = go:NodeByName("pGroup").gameObject

	for i = 1, 3 do
		local group = pGroup:NodeByName("pIconGroup" .. tostring(i)).gameObject
		self["pIcon" .. tostring(i)] = PlayerIcon.new(group)
	end

	self.teamName = go:ComponentByName("teamName", typeof(UILabel))
	self.time = go:ComponentByName("time", typeof(UILabel))
	self.labelPoint = go:ComponentByName("labelPoint", typeof(UILabel))
	self.point = go:ComponentByName("point", typeof(UILabel))
	self.win = go:NodeByName("win").gameObject
	self.lose = go:NodeByName("lose").gameObject
	self.touchGroup = go:NodeByName("touchGroup").gameObject
	self.video = go:NodeByName("video").gameObject
end

function ArenaTeamRecordItem:setInfo(params)
	self.params = params
	local i = 1

	while i <= 3 do
		local index = i
		local info = params.team_info.player_infos[i]

		self["pIcon" .. tostring(index)]:setInfo({
			avatarID = info.avatar_id,
			lev = info.lev,
			avatar_frame_id = info.avatar_frame_id
		})

		i = i + 1
	end

	self.teamName.text = params.team_info.team_name
	local resTime = xyd:getServerTime() - params.time
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
	local score = tostring(params.score)

	if params.score > 0 then
		score = "+" .. tostring(params.score)
	end

	self.point.text = score

	if params.is_win and params.is_win ~= 0 then
		self.win:SetActive(true)
		self.lose:SetActive(false)

		self.point.color = Color.New2(915996927)
	else
		self.win:SetActive(false)
		self.lose:SetActive(true)

		self.point.color = Color.New2(2751463679.0)
	end
end

function ArenaTeamRecordItem:registerEvent()
	xyd.setDarkenBtnBehavior(self.video, self, self.onclickVideo)

	UIEventListener.Get(self.touchGroup).onClick = handler(self, self.onclickAvatar)
end

function ArenaTeamRecordItem:onclickVideo(e)
	xyd.WindowManager.get():openWindow("arena_team_record_detail_window", {
		report_ids = self.params.record_ids
	})
end

function ArenaTeamRecordItem:onclickAvatar(e)
	if xyd.models.arenaTeam:checkOpen() then
		xyd.WindowManager.get():openWindow("arena_team_formations_window", {
			player_id = self.params.team_info.leader_id
		})
	end
end

return ArenaTeamRecordWindow
