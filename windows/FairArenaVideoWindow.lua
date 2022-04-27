local BaseWindow = import(".BaseWindow")
local FairArenaVideoWindow = class("FairArenaVideoWindow", BaseWindow)
local RecordItem = class("RecordItem", import("app.common.ui.FixedWrapContentItem"))
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local PlayerIcon = import("app.components.PlayerIcon")
local RobotTable = xyd.tables.activityFairArenaRobotTable

function FairArenaVideoWindow:ctor(name, params)
	FairArenaVideoWindow.super.ctor(self, name, params)
end

function FairArenaVideoWindow:initWindow()
	FairArenaVideoWindow.super.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function FairArenaVideoWindow:getUIComponent()
	local winTrans = self.window_:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel_", typeof(UILabel))
	self.closeBtn = winTrans:NodeByName("closeBtn").gameObject
	self.scrollView = winTrans:ComponentByName("videoGroup", typeof(UIScrollView))
	self.itemGroup = winTrans:NodeByName("videoGroup/itemGroup").gameObject
	self.recordItem = winTrans:NodeByName("videoGroup/item").gameObject
	self.NoneGroup = winTrans:NodeByName("NoneGroup").gameObject
	self.labelNoneTips = self.NoneGroup:ComponentByName("labelNoneTips", typeof(UILabel))
end

function FairArenaVideoWindow:initUIComponent()
	self.titleLabel_.text = __("BATTLE_RECORD")
	self.labelNoneTips.text = __("ARENA_NO_RECORD")
	local data = xyd.models.fairArena:getArenaInfo()
	local records = data.cur_history or {}
	local sort_records = {}

	for i = #records, 1, -1 do
		table.insert(sort_records, records[i])
	end

	if #records > 0 then
		local wrapContent = self.itemGroup:GetComponent(typeof(UIWrapContent))
		self.wrapContent = FixedWrapContent.new(self.scrollView, wrapContent, self.recordItem, RecordItem, self)

		self.wrapContent:setInfos(sort_records, {})
	else
		self.NoneGroup:SetActive(true)
	end
end

function FairArenaVideoWindow:register()
	FairArenaVideoWindow.super.register(self)
end

function RecordItem:ctor(go, parent)
	RecordItem.super.ctor(self, go, parent)
end

function RecordItem:initUI()
	local go = self.go
	self.btnVideo_ = go:NodeByName("btnVideo_").gameObject
	self.avatarGroup = go:NodeByName("avatarGroup").gameObject
	self.nameLabel_ = go:ComponentByName("nameLabel_", typeof(UILabel))
	self.timeLabel_ = go:ComponentByName("timeLabel_", typeof(UILabel))
	self.timesLabel_ = go:ComponentByName("timesLabel_", typeof(UILabel))
	self.icon_ = go:ComponentByName("icon_", typeof(UISprite))
	self.pIcon = PlayerIcon.new(self.avatarGroup)
end

function RecordItem:registerEvent()
	UIEventListener.Get(self.btnVideo_).onClick = handler(self, function ()
		xyd.models.fairArena:reqGetReport(self.id, self.enemy_infos)
	end)
end

function RecordItem:updateInfo()
	self.id = self.data.id
	self.is_win = self.data.is_win
	self.time = self.data.time
	self.enemy_infos = self.data.enemy_infos

	if self.is_win == 1 then
		xyd.setUISpriteAsync(self.icon_, nil, "arena_win")
	else
		xyd.setUISpriteAsync(self.icon_, nil, "arena_lose")
	end

	self.timeLabel_.text = xyd.getReceiveTime(self.time)
	self.timesLabel_.text = __("MATCH_NUM", self.id)
	self.is_robot = self.enemy_infos.robot_id

	if self.is_robot then
		self.robot_id = tonumber(self.enemy_infos.robot_id)
	else
		self.player_info = self.enemy_infos.player_info
	end

	if self.is_robot then
		local id = self.robot_id
		self.nameLabel_.text = RobotTable:getName(id)

		self.pIcon:setInfo({
			scale = 0.6759259259259259,
			avatarID = RobotTable:getAvatar(id),
			lev = RobotTable:getLev(id),
			callback = function ()
				self:onClickPIcon()
			end
		})
	else
		self.nameLabel_.text = self.player_info.player_name

		self.pIcon:setInfo({
			scale = 0.6759259259259259,
			avatarID = self.player_info.avatar_id,
			avatar_frame_id = self.player_info.avatar_frame_id,
			lev = self.player_info.lev,
			callback = function ()
				self:onClickPIcon()
			end
		})
	end
end

function RecordItem:onClickPIcon()
	xyd.WindowManager.get():openWindow("fair_arena_enemy_formation_window", {
		is_history = true,
		info = self.enemy_infos
	})
end

return FairArenaVideoWindow
