local BaseWindow = import(".BaseWindow")
local ArenaAllServerRecordsWindow = class("ArenaAllServerRecordsWindow", BaseWindow)
local ArenaAllServerRecordsItem = class("ArenaAllServerRecordsItem", import("app.components.CopyComponent"))
local PlayerIcon = import("app.components.PlayerIcon")

function ArenaAllServerRecordsWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function ArenaAllServerRecordsWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:initList()
	self:register()
end

function ArenaAllServerRecordsWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.labelTitle_ = groupAction:ComponentByName("labelTitle_", typeof(UILabel))
	self.groupNone_ = groupAction:NodeByName("groupNone_").gameObject
	self.labelNoneTips_ = self.groupNone_:ComponentByName("labelNoneTips_", typeof(UILabel))
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.scroller = groupAction:ComponentByName("scroller", typeof(UIScrollView))
	self.itemList_ = self.scroller:ComponentByName("itemList_", typeof(UILayout))
	self.itemNode = groupAction:NodeByName("item").gameObject
end

function ArenaAllServerRecordsWindow:setLayout()
	self.labelTitle_.text = __("BATTLE_RECORD")
	self.labelNoneTips_.text = __("ARENA_ALL_SERVER_TEXT_8")
end

function ArenaAllServerRecordsWindow:initList()
	local data = xyd.models.arenaAllServerNew:getSelfFightRecords()

	if not data or #data <= 0 then
		self.groupNone_:SetActive(true)

		return
	end

	self.groupNone_:SetActive(false)

	for i = 1, #data do
		local go = NGUITools.AddChild(self.itemList_.gameObject, self.itemNode)
		local item = ArenaAllServerRecordsItem.new(go)

		item:setInfo(data[i])
	end

	self.itemList_:Reposition()
end

function ArenaAllServerRecordsItem:ctor(go)
	ArenaAllServerRecordsItem.super.ctor(self, go)

	self.skinName = "ArenaAllServerRecordsItemSkin"
end

function ArenaAllServerRecordsItem:initUI()
	ArenaAllServerRecordsItem.super.initUI(self)

	self.top = self.go:NodeByName("top").gameObject
	self.main = self.go:NodeByName("main").gameObject
	self.labelTips_ = self.top:ComponentByName("labelTips_", typeof(UILabel))
	self.btnVideo_ = self.main:NodeByName("btnVideo_").gameObject
	self.avatarGroup = self.main:NodeByName("avatarGroup").gameObject
	self.labelPlayerName = self.main:ComponentByName("labelPlayerName", typeof(UILabel))
	self.labelGuildName = self.main:ComponentByName("labelGuildName", typeof(UILabel))
	self.imgResult = self.main:ComponentByName("imgResult", typeof(UISprite))
	UIEventListener.Get(self.btnVideo_).onClick = handler(self, self.onRecordTouch)
end

function ArenaAllServerRecordsItem:setInfo(params)
	self.data = params

	if self.data.round_text ~= nil then
		self.currentState = "normal"
		self.labelTips_.text = __("ARENA_ALL_SERVER_ROUND_TEXT_" .. tostring(self.data.round_text))
	else
		self.top:SetActive(false)

		self.currentState = "special"
	end

	local playerInfo = self.data
	self.labelPlayerName.text = playerInfo.player_name

	if playerInfo.guild_name then
		self.labelGuildName.text = playerInfo.guild_name
		self.labelGuildName.color = Color.New2(1549556991)
	else
		self.labelGuildName.text = __("ARENA_ALL_SERVER_TEXT_14")
		self.labelGuildName.color = Color.New2(2290583551.0)
	end

	local playerIcon = PlayerIcon.new(self.avatarGroup)

	playerIcon:setInfo({
		noClick = true,
		avatarID = playerInfo.avatar_id,
		avatar_frame_id = playerInfo.avatar_frame_id
	})

	local resImg = "arena_lose"

	if self.data.is_win == 1 then
		resImg = "arena_win"
	end

	xyd.setUISpriteAsync(self.imgResult, nil, resImg)
end

function ArenaAllServerRecordsItem:onRecordTouch()
	if not self.data or not self.data.record_ids then
		return
	end

	xyd.WindowManager.get():openWindow("arena_3v3_record_detail_window", {
		isAsAfter = true,
		report_ids = self.data.record_ids
	})
end

return ArenaAllServerRecordsWindow
