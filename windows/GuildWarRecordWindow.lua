local BaseWindow = import(".BaseWindow")
local GuildWarRecordWindow = class("GuildWarRecordWindow", BaseWindow)
local ItemRender = class("ItemRender")
local GuildWarRecordItem = class("GuildWarRecordItem", import("app.components.BaseComponent"))

function ItemRender:ctor(go, parent)
	self.go = go
	self.parent = parent
	self.item = GuildWarRecordItem.new(go)

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

function GuildWarRecordWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.model_ = xyd.models.guildWar
end

function GuildWarRecordWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()

	self.labelTitle.text = __("BATTLE_RECORD")
	self.labelNone.text = __("ARENA_NO_RECORD")

	self:register()
	self.model_:reqRecord()
end

function GuildWarRecordWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("groupAction").gameObject
	self.labelTitle = content:ComponentByName("topGroup/labelTitle", typeof(UILabel))
	self.backBtn = content:NodeByName("backBtn").gameObject
	local middleGroup = content:NodeByName("middleGroup").gameObject
	self.scrollView = middleGroup:ComponentByName("scroller", typeof(UIScrollView))
	local wrapContent = self.scrollView:ComponentByName("container", typeof(UIWrapContent))
	local itemContainer = self.scrollView:NodeByName("itemContainer").gameObject
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.scrollView, wrapContent, itemContainer, ItemRender, self)
	self.groupNone = middleGroup:NodeByName("groupNone").gameObject
	self.labelNone = self.groupNone:ComponentByName("labelNone", typeof(UILabel))
end

function GuildWarRecordWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GUILD_WAR_GET_RECORDS, handler(self, self.onGetData))

	UIEventListener.Get(self.backBtn).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function GuildWarRecordWindow:onGetData(event)
	local data = event.data.records

	if not data or #data == 0 then
		self.groupNone:SetActive(true)
	else
		self.groupNone:SetActive(false)
	end

	self.data_ = data

	self.wrapContent:setInfos(data, {})
end

function GuildWarRecordItem:ctor(go, parent)
	self.parent = parent

	GuildWarRecordItem.super.ctor(self, go)
end

function GuildWarRecordItem:getPrefabPath()
	return "Prefabs/Components/guild_war_record_item"
end

function GuildWarRecordItem:initUI()
	GuildWarRecordItem.super.initUI(self)

	local go = self.go
	self.bgImg = go:ComponentByName("bgImg", typeof(UISprite)).gameObject
	self.guildIcon_ = go:ComponentByName("guildIcon", typeof(UISprite))
	self.guildName_ = go:ComponentByName("guildName", typeof(UILabel))
	self.labelPointTitle_ = go:ComponentByName("pointTitle", typeof(UILabel))
	self.labelPoint_ = go:ComponentByName("point", typeof(UILabel))
	self.serverID_ = go:ComponentByName("serverGroup/label", typeof(UILabel))
	self.imgWin_ = go:NodeByName("imgWin").gameObject
	self.imgLost_ = go:NodeByName("imgLose").gameObject
	self.btnView_ = go:NodeByName("btnVideo").gameObject
	self.labelPointTitle_.text = __("SCORE")
	UIEventListener.Get(self.btnView_).onClick = handler(self, self.onclickVideo)
end

function GuildWarRecordItem:setInfo(info)
	if not info then
		return
	end

	self.guildName_.text = info.b_info.name

	if not self.info_ or self.info_.b_info.flag ~= info.b_info.flag then
		local flag = xyd.tables.guildIconTable:getIcon(info.b_info.flag)

		xyd.setUISpriteAsync(self.guildIcon_, nil, flag)
	end

	self.serverID_.text = xyd.getServerNumber(info.b_info.server_id)
	local score = nil

	if info.score > 0 then
		score = "+" .. info.score
	else
		score = info.score
	end

	self.labelPoint_.text = score

	if info.is_win == 1 then
		self.labelPoint_.color = Color.New2(915996927)
	else
		self.labelPoint_.color = Color.New2(2751463679.0)
	end

	if not self.info_ or self.info_.is_win ~= info.is_win then
		self.imgWin_:SetActive(info.is_win == 1)
		self.imgLost_:SetActive(info.is_win ~= 1)
	end

	self.info_ = info
end

function GuildWarRecordItem:onclickVideo()
	local params = {
		info = self.info_,
		isReport = true
	}

	xyd.WindowManager.get():openWindow("guild_war_record_detail_window", params)
end

return GuildWarRecordWindow
